import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
import random

# Features: [days_late, total_contributions, is_cross_border (0/1), circle_count]
# Target: [0: High Risk, 1: Medium Risk, 2: Low Risk]

def generate_synthetic_data(n=100):
    data = []
    for _ in range(n):
        days_late = random.randint(0, 30)
        total_contributions = random.randint(1, 50)
        is_cross_border = random.choice([0, 1])
        circle_count = random.randint(1, 5)
        
        # Logic for 'Good' vs 'Bad' saver baseline
        if days_late <= 2 and total_contributions >= 10:
            risk = 2 # Low Risk
        elif days_late <= 7:
            risk = 1 # Medium Risk
        else:
            risk = 0 # High Risk
            
        data.append([days_late, total_contributions, is_cross_border, circle_count, risk])
    
    return pd.DataFrame(data, columns=['days_late', 'total_contributions', 'is_cross_border', 'circle_count', 'risk'])

# Initialize and train the model
df = generate_synthetic_data(200)
X = df.drop('risk', axis=1)
y = df['risk']

model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X, y)

def predict_trust_score(user_data, is_kyc_verified=False):
    """
    user_data: list [days_late, total_contributions, is_cross_border, circle_count]
    Returns: (score, risk_level)
    """
    prediction = model.predict([user_data])[0]
    probabilities = model.predict_proba([user_data])[0]
    
    # Map prediction to risk level string
    risk_map = {0: "High", 1: "Medium", 2: "Low"}
    risk_level = risk_map[prediction]
    
    # Calculate a score based on probabilities
    # Adjusted weights to be more generous for democratic finance
    score = int((probabilities[2] * 100) + (probabilities[1] * 75) + (probabilities[0] * 40))
    
    # Base penalty for brand new users - but don't be too harsh
    if user_data[1] == 0: # 0 contributions
        score = max(45, score - 15) # Start at a decent baseline
        
    if is_kyc_verified:
        score = min(100, score + 35) # Significant Identity Boost
        
    return score, risk_level

def get_user_features(user_id):
    # Mock feature extraction based on user ID
    # In a real app, this would query the DB for history
    random.seed(user_id)
    days_late = random.randint(0, 15)
    total_contributions = random.randint(5, 40)
    is_xb = 1 if "xb" in user_id.lower() else 0
    circles = random.randint(1, 3)
    return [days_late, total_contributions, is_xb, circles]
