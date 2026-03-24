from fastapi import FastAPI, HTTPException, Request, Form, Depends, status
from fastapi.responses import HTMLResponse
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, EmailStr
from typing import List, Optional
import random
import uuid
import datetime
from sqlalchemy.orm import Session
from jose import JWTError, jwt

import currency_converter
import trust_engine
from interswitch_service import InterswitchAPI
from dotenv import load_dotenv
import os

from database import engine, get_db, Base
import models
import auth

load_dotenv()

# Create database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="UbuntuX AI Trust Engine")
isw_service = InterswitchAPI()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# --- Pydantic Models ---

class UserBase(BaseModel):
    email: EmailStr
    name: str

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: str
    trust_score: int
    on_time_percentage: float
    is_kyc_verified: bool
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    id: Optional[str] = None

class AdashiCircleBase(BaseModel):
    name: str
    contribution_amount: float
    max_members: int
    frequency: str
    is_cross_border_allowed: bool = False

class AdashiCircleCreate(AdashiCircleBase):
    pass

class AdashiCircleResponse(AdashiCircleBase):
    id: str
    total_pot: float
    creator_id: str
    member_ids: List[str] = []
    
    class Config:
        from_attributes = True

# --- Auth Dependencies ---

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, auth.SECRET_KEY, algorithms=[auth.ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
        token_data = TokenData(id=user_id)
    except JWTError:
        raise credentials_exception
    user = db.query(models.User).filter(models.User.id == token_data.id).first()
    if user is None:
        raise credentials_exception
    return user

# --- Auth Endpoints ---

@app.post("/register", response_model=UserResponse)
def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    user_id = f"u{uuid.uuid4().hex[:6]}"
    hashed_password = auth.get_password_hash(user.password)
    
    new_user = models.User(
        id=user_id,
        email=user.email,
        name=user.name,
        hashed_password=hashed_password
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.post("/token", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = auth.create_access_token(data={"sub": user.id})
    return {"access_token": access_token, "token_type": "bearer"}

# --- Endpoints ---

@app.get("/circles", response_model=List[AdashiCircleResponse])
async def get_circles(db: Session = Depends(get_db)):
    db_circles = db.query(models.Circle).all()
    results = []
    for c in db_circles:
        member_ids = [m.user_id for m in c.members]
        results.append(AdashiCircleResponse(
            id=c.id,
            name=c.name,
            contribution_amount=c.contribution_amount,
            max_members=c.max_members,
            frequency=c.frequency,
            is_cross_border_allowed=c.is_cross_border_allowed,
            total_pot=c.total_pot,
            creator_id=c.creator_id,
            member_ids=member_ids
        ))
    return results

@app.get("/circles/{circle_id}", response_model=AdashiCircleResponse)
async def get_circle(circle_id: str, db: Session = Depends(get_db)):
    c = db.query(models.Circle).filter(models.Circle.id == circle_id).first()
    if not c:
        raise HTTPException(status_code=404, detail="Circle not found")
    
    member_ids = [m.user_id for m in c.members]
    return AdashiCircleResponse(
        id=c.id,
        name=c.name,
        contribution_amount=c.contribution_amount,
        max_members=c.max_members,
        frequency=c.frequency,
        is_cross_border_allowed=c.is_cross_border_allowed,
        total_pot=c.total_pot,
        creator_id=c.creator_id,
        member_ids=member_ids
    )

@app.get("/exchange-rate")
async def get_exchange_rate():
    return {"base": "GBP", "target": "NGN", "rate": currency_converter.get_exchange_rate()}

@app.post("/circles/{circle_id}/join")
async def join_circle(circle_id: str, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    circle = db.query(models.Circle).filter(models.Circle.id == circle_id).first()
    if not circle:
        raise HTTPException(status_code=404, detail="Circle not found")
    
    # Check if already a member
    existing_membership = db.query(models.CircleMembership).filter(
        models.CircleMembership.circle_id == circle_id,
        models.CircleMembership.user_id == current_user.id
    ).first()
    
    if existing_membership:
        raise HTTPException(status_code=400, detail="User already in circle")
    
    if len(circle.members) >= circle.max_members:
        raise HTTPException(status_code=400, detail="Circle is full")
    
    new_membership = models.CircleMembership(user_id=current_user.id, circle_id=circle_id)
    db.add(new_membership)
    db.commit()
    
    return {"message": "Successfully joined circle"}

@app.get("/checkout/{circle_id}", response_class=HTMLResponse)
async def get_checkout(
    request: Request, 
    circle_id: str, 
    amount: float, 
    currency: str = "NGN",
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    circle = db.query(models.Circle).filter(models.Circle.id == circle_id).first()
    if not circle:
        raise HTTPException(status_code=404, detail="Circle not found")
    
    # URL to redirect to after Interswitch processes the payment
    base_url = str(request.base_url).rstrip("/")
    redirect_url = f"{base_url}/webhook/interswitch?circle_id={circle_id}&user_id={current_user.id}&amount={amount}&currency={currency}"
    
    result = isw_service.get_checkout_form_html(amount, currency, current_user.id, circle_id, redirect_url)
    return HTMLResponse(content=result["html"], status_code=200)

@app.post("/webhook/interswitch")
async def interswitch_callback(
    request: Request,
    circle_id: str, 
    user_id: str, 
    amount: float, 
    currency: str = "NGN",
    db: Session = Depends(get_db)
):
    form_data = await request.form()
    txn_ref = form_data.get("txn_ref")
    
    if not txn_ref:
        return HTMLResponse(content="<h3>Payment failed or cancelled.</h3>", status_code=400)

    is_valid, data = await isw_service.verify_transaction(txn_ref, amount)
    
    if not is_valid:
        return HTMLResponse(content="<h3>Payment Verification Failed.</h3>", status_code=400)
    
    # Process Success logic
    circle = db.query(models.Circle).filter(models.Circle.id == circle_id).first()
    user = db.query(models.User).filter(models.User.id == user_id).first()
    
    if circle and user:
        amount_in_ngn = amount
        if currency == "GBP":
            amount_in_ngn = amount * currency_converter.get_exchange_rate()
        
        circle.total_pot += amount_in_ngn
        
        # Update user metrics
        user.on_time_percentage = min(100.0, user.on_time_percentage + 0.5)
        
        # Record Transaction
        txn = models.Transaction(
            id=f"txn_{uuid.uuid4().hex[:8]}",
            user_id=user_id,
            circle_id=circle_id,
            amount=amount,
            currency=currency,
            type="contribution",
            status="success",
            txn_ref=txn_ref
        )
        db.add(txn)
        db.commit()
        
        # Recalculate Trust Score
        await predict_trust_internal(user_id, db)
            
    # Trigger recalculation of Trust Score locally by returning a deep link back to app
    return HTMLResponse(content=f"<h3>Payment Successful!</h3><p>Pot updated. Trans Ref: {txn_ref}</p><script>setTimeout(function() {{ window.location.href='ubuntux://payment-success'; }}, 2000);</script>")

async def predict_trust_internal(user_id: str, db: Session):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return {"trust_score": 75, "risk_level": "Medium"}
        
    # Fetch real history from transactions
    contributions = db.query(models.Transaction).filter(
        models.Transaction.user_id == user_id,
        models.Transaction.type == "contribution",
        models.Transaction.status == "success"
    ).all()
    
    # Check for cross-border transactions
    is_xb = any(t.currency != "NGN" for t in contributions)
    
    # Active circles
    circle_count = db.query(models.CircleMembership).filter(models.CircleMembership.user_id == user_id).count()
    
    # For now, simulate days_late or use a default if not tracked yet
    days_late = 0 
    
    features = [
        days_late,
        len(contributions),
        1 if is_xb else 0,
        circle_count
    ]
    
    score, risk_level = trust_engine.predict_trust_score(features, is_kyc_verified=user.is_kyc_verified)
    
    # Update user score in DB
    user.trust_score = score
    db.commit()
    
    return {
        "user_id": user_id,
        "trust_score": score,
        "risk_level": risk_level,
        "analysis_factors": {
            "Days Late": f"{features[0]} days (Avg)",
            "Total Contributions": f"{features[1]} payments made",
            "Cross-Border User": "Yes" if features[2] == 1 else "No",
            "Active Circles": f"Member of {features[3]} circles",
            "KYC Verified": "Yes" if user.is_kyc_verified else "No",
            "Account Age": "6 months (Sentinel baseline)"
        }
    }

@app.post("/predict-trust")
async def predict_trust(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    return await predict_trust_internal(current_user.id, db)

@app.post("/users/verify-kyc")
async def verify_kyc(bvn: str, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    is_valid, data = await isw_service.validate_identity(current_user.id, bvn)
    if not is_valid:
        raise HTTPException(status_code=400, detail="KYC Verification Failed. Invalid BVN.")
        
    current_user.is_kyc_verified = True
    current_user.bvn = bvn
    db.commit()
    
    # Trigger score recalculation
    prediction_result = await predict_trust_internal(current_user.id, db)
    
    return {
        "status": "Success",
        "message": "Identity Verified via Interswitch KYC API",
        "new_trust_score": prediction_result["trust_score"]
    }

@app.post("/circles/{circle_id}/payout")
async def process_payout(
    circle_id: str, 
    bank_code: str, 
    account_no: str, 
    target_currency: str = "NGN",
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    circle = db.query(models.Circle).filter(models.Circle.id == circle_id).first()
    if not circle:
        raise HTTPException(status_code=404, detail="Circle not found")
        
    if circle.creator_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the circle creator can initiate payout")
        
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
        # Record Transaction
        txn = models.Transaction(
            id=f"txn_{uuid.uuid4().hex[:8]}",
            user_id=current_user.id,
            circle_id=circle_id,
            amount=payout_amount,
            currency=target_currency,
            type="payout",
            status="success",
            txn_ref=data.get("transactionRef", f"REF_{uuid.uuid4().hex[:6]}")
        )
        db.add(txn)
        circle.total_pot = 0.0 # reset pot
        db.commit()
        return {"status": "Success", "message": "Payout completed!", "data": data}
    else:
        raise HTTPException(status_code=400, detail="Payout Failed")

@app.post("/circles/create", response_model=AdashiCircleResponse)
async def create_circle(
    circle_data: AdashiCircleCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # AI Gate: Check Creator's Trust Score
    prediction_result = await predict_trust_internal(current_user.id, db)
    score = prediction_result["trust_score"]
    
    if score <= 50:
        raise HTTPException(
            status_code=403, 
            detail=f"Security Gate: Your Trust Score ({score}) is too low to create a circle. Minimum score required: 51."
        )

    circle_id = f"c{uuid.uuid4().hex[:6]}"
    new_circle = models.Circle(
        id=circle_id,
        name=circle_data.name,
        contribution_amount=circle_data.contribution_amount,
        max_members=circle_data.max_members,
        frequency=circle_data.frequency,
        is_cross_border_allowed=circle_data.is_cross_border_allowed,
        creator_id=current_user.id
    )
    
    db.add(new_circle)
    db.commit()
    
    # Auto-join creator
    new_membership = models.CircleMembership(user_id=current_user.id, circle_id=circle_id)
    db.add(new_membership)
    db.commit()
    
    db.refresh(new_circle)
    
    member_ids = [m.user_id for m in new_circle.members]
    return AdashiCircleResponse(
        id=new_circle.id,
        name=new_circle.name,
        contribution_amount=new_circle.contribution_amount,
        max_members=new_circle.max_members,
        frequency=new_circle.frequency,
        is_cross_border_allowed=new_circle.is_cross_border_allowed,
        total_pot=new_circle.total_pot,
        creator_id=new_circle.creator_id,
        member_ids=member_ids
    )

@app.get("/users/me", response_model=UserResponse)
async def get_me(current_user: models.User = Depends(get_current_user)):
    return current_user

@app.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: str, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
