from fastapi import FastAPI, HTTPException, Request, Form
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from typing import List, Optional
import random
import currency_converter
import trust_engine
from interswitch_service import InterswitchAPI
from dotenv import load_dotenv
import os

load_dotenv()
app = FastAPI(title="UbuntuX AI Trust Engine")
isw_service = InterswitchAPI()

# --- Models ---

class User(BaseModel):
    id: str
    name: str
    trust_score: int
    on_time_percentage: float = 0.0
    is_kyc_verified: bool = False

class AdashiCircle(BaseModel):
    id: str
    name: str
    contribution_amount: float
    max_members: int
    frequency: str
    member_ids: List[str] = []
    total_pot: float = 0.0
    is_cross_border_allowed: bool = False

# --- Mock Data ---

users = {
    "u1": User(id="u1", name="Abdul", trust_score=85, on_time_percentage=90),
    "u2": User(id="u2", name="Enyata", trust_score=92, on_time_percentage=95),
    "u3": User(id="u3", name="Ubuntu", trust_score=98, on_time_percentage=100),
    "u4": User(id="u4", name="Me (Demo)", trust_score=75, on_time_percentage=80),
}

circles = {
    "c1": AdashiCircle(
        id="c1",
        name="Lagos Techies",
        contribution_amount=50000,
        max_members=5,
        frequency="Monthly",
        member_ids=["u2"],
        total_pot=50000.0
    ),
    "c2": AdashiCircle(
        id="c2",
        name="Cross-Border Explorers",
        contribution_amount=100000,
        max_members=3,
        frequency="Weekly",
        member_ids=["u1", "u3"],
        total_pot=200000.0
    ),
    "c3": AdashiCircle(
        id="c3",
        name="Ubuntu Seedlings",
        contribution_amount=10000,
        max_members=10,
        frequency="Daily",
        member_ids=[],
        total_pot=0.0
    ),
}

# --- Mock History and Real-time Tracking ---

user_history = {
    "u4": {
        "days_late": 1, 
        "total_contributions": 12, 
        "is_xb": False
    }
}

# --- Endpoints ---

@app.get("/circles", response_model=List[AdashiCircle])
async def get_circles():
    return list(circles.values())

@app.get("/circles/{circle_id}", response_model=AdashiCircle)
async def get_circle(circle_id: str):
    if circle_id not in circles:
        raise HTTPException(status_code=404, detail="Circle not found")
    return circles[circle_id]

@app.get("/exchange-rate")
async def get_exchange_rate():
    return {"base": "GBP", "target": "NGN", "rate": currency_converter.get_exchange_rate()}

@app.post("/circles/{circle_id}/join")
async def join_circle(circle_id: str, user_id: str):
    if circle_id not in circles:
        raise HTTPException(status_code=404, detail="Circle not found")
    
    circle = circles[circle_id]
    
    if user_id in circle.member_ids:
        raise HTTPException(status_code=400, detail="User already in circle")
    
    if len(circle.member_ids) >= circle.max_members:
        raise HTTPException(status_code=400, detail="Circle is full")
    
    circle.member_ids.append(user_id)
    return {"message": "Successfully joined circle", "circle": circle}

@app.get("/checkout/{circle_id}", response_class=HTMLResponse)
async def get_checkout(request: Request, circle_id: str, user_id: str, amount: float, currency: str = "NGN"):
    if circle_id not in circles:
        raise HTTPException(status_code=404, detail="Circle not found")
    
    # URL to redirect to after Interswitch processes the payment
    base_url = str(request.base_url).rstrip("/")
    redirect_url = f"{base_url}/webhook/interswitch?circle_id={circle_id}&user_id={user_id}&amount={amount}&currency={currency}"
    
    result = isw_service.get_checkout_form_html(amount, currency, user_id, circle_id, redirect_url)
    return HTMLResponse(content=result["html"], status_code=200)

@app.post("/webhook/interswitch")
async def interswitch_callback(
    request: Request,
    circle_id: str, 
    user_id: str, 
    amount: float, 
    currency: str = "NGN"
):
    form_data = await request.form()
    txn_ref = form_data.get("txn_ref")
    
    if not txn_ref:
        return HTMLResponse(content="<h3>Payment failed or cancelled.</h3>", status_code=400)

    is_valid, data = await isw_service.verify_transaction(txn_ref, amount)
    
    if not is_valid:
        return HTMLResponse(content="<h3>Payment Verification Failed.</h3>", status_code=400)
    
    # Process Success logic
    circle = circles.get(circle_id)
    if circle:
        amount_in_ngn = amount
        if currency == "GBP":
            amount_in_ngn = amount * currency_converter.get_exchange_rate()
        
        circle.total_pot += amount_in_ngn
        
    if user_id in users:
        user = users[user_id]
        user.on_time_percentage = min(100.0, user.on_time_percentage + 0.5)
        
        if user_id not in user_history:
            user_history[user_id] = {"days_late": 0, "total_contributions": 0, "is_xb": False}
        
        user_history[user_id]["total_contributions"] += 1
        if currency == "GBP":
            user_history[user_id]["is_xb"] = True
            
    # Trigger recalculation of Trust Score locally by returning a deep link back to app
    return HTMLResponse(content=f"<h3>Payment Successful!</h3><p>Pot updated. Trans Ref: {txn_ref}</p><script>setTimeout(function() {{ window.location.href='ubuntux://payment-success'; }}, 2000);</script>")

@app.post("/predict-trust")
async def predict_trust(user_id: str):
    history = user_history.get(user_id, {"days_late": 0, "total_contributions": 0, "is_xb": False})
    circle_count = sum(1 for c in circles.values() if user_id in c.member_ids)
    
    features = [
        history["days_late"],
        history["total_contributions"],
        1 if history["is_xb"] else 0,
        circle_count
    ]
    
    is_kyc_verified = False
    if user_id in users:
        is_kyc_verified = users[user_id].is_kyc_verified
        
    score, risk_level = trust_engine.predict_trust_score(features, is_kyc_verified=is_kyc_verified)
    
    if user_id in users:
        users[user_id].trust_score = score
        
    return {
        "user_id": user_id,
        "trust_score": score,
        "risk_level": risk_level,
        "analysis_factors": {
            "Days Late": f"{features[0]} days (Avg)",
            "Total Contributions": f"{features[1]} payments made",
            "Cross-Border User": "Yes" if features[2] == 1 else "No",
            "Active Circles": f"Member of {features[3]} circles",
            "KYC Verified": "Yes" if is_kyc_verified else "No",
            "Account Age": "6 months (Sentinel baseline)"
        }
    }

@app.post("/users/{user_id}/verify-kyc")
async def verify_kyc(user_id: str, bvn: str):
    if user_id not in users:
        raise HTTPException(status_code=404, detail="User not found")
        
    is_valid, data = await isw_service.validate_identity(user_id, bvn)
    if not is_valid:
        raise HTTPException(status_code=400, detail="KYC Verification Failed. Invalid BVN.")
        
    users[user_id].is_kyc_verified = True
    
    # Trigger score recalculation
    prediction_result = await predict_trust(user_id)
    
    return {
        "status": "Success",
        "message": "Identity Verified via Interswitch KYC API",
        "new_trust_score": prediction_result["trust_score"]
    }

@app.post("/circles/{circle_id}/payout")
async def process_payout(circle_id: str, user_id: str, bank_code: str, account_no: str, target_currency: str = "NGN"):
    if circle_id not in circles:
        raise HTTPException(status_code=404, detail="Circle not found")
        
    circle = circles[circle_id]
    if circle.total_pot <= 0:
        raise HTTPException(status_code=400, detail="Circle pot is empty")
        
    # Cross border simulation logic
    payout_amount = circle.total_pot
    if target_currency == "GBP":
        payout_amount = payout_amount / currency_converter.get_exchange_rate()
        
    is_valid, data = await isw_service.initiate_payout(
        amount=payout_amount, 
        currency=target_currency, 
        bank_code=bank_code, 
        account_no=account_no,
        narration=f"UbuntuX Adashi Payout for {circle.name}"
    )
    
    if is_valid:
        circle.total_pot = 0.0 # reset pot
        return {"status": "Success", "message": "Payout completed!", "data": data}
    else:
        raise HTTPException(status_code=400, detail="Payout Failed")

@app.post("/circles/create")
async def create_circle(
    name: str, 
    contribution_amount: float, 
    max_members: int, 
    frequency: str, 
    creator_id: str,
    allow_xb: bool = False
):
    # AI Gate: Check Creator's Trust Score
    history = user_history.get(creator_id, {"days_late": 0, "total_contributions": 0, "is_xb": False})
    circle_count = sum(1 for c in circles.values() if creator_id in c.member_ids)
    
    features = [
        history["days_late"],
        history["total_contributions"],
        1 if history["is_xb"] else 0,
        circle_count
    ]
    
    score, risk_level = trust_engine.predict_trust_score(features, is_kyc_verified=(creator_id in users and users[creator_id].is_kyc_verified))
    
    if score <= 50:
        raise HTTPException(
            status_code=403, 
            detail=f"Security Gate: Your Trust Score ({score}) is too low to create a circle. Minimum score required: 51. Keep saving to build trust!"
        )

    circle_id = f"c{len(circles) + 1}"
    new_circle = AdashiCircle(
        id=circle_id,
        name=name,
        contribution_amount=contribution_amount,
        max_members=max_members,
        frequency=frequency,
        member_ids=[creator_id],
        is_cross_border_allowed=allow_xb
    )
    
    circles[circle_id] = new_circle
    return {"message": "Circle created successfully!", "circle": new_circle}

@app.get("/users/{user_id}", response_model=User)
async def get_user(user_id: str):
    if user_id not in users:
        return User(id=user_id, name=f"User {user_id}", trust_score=75, on_time_percentage=75.0)
    return users[user_id]

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
