import bcrypt
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
import os

# Secret key to sign JWT
SECRET_KEY = os.getenv("SECRET_KEY", "b30dc409f5831518b5770df3bed2a926a8d8745582f182c038448882ca6c98c1")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7 # 7 days

def verify_password(plain_password: str, hashed_password: str):
    try:
        return bcrypt.checkpw(
            plain_password.encode('utf-8'), 
            hashed_password.encode('utf-8')
        )
    except Exception:
        return False

def get_password_hash(password: str):
    # bcrypt.hashpw returns bytes, so we decode it for storage as string
    hashed_bytes = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    return hashed_bytes.decode('utf-8')

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        # Default to 15 mins for security if not specified, 
        # but the caller usually handles this or uses the default above.
        expire = datetime.utcnow() + timedelta(minutes=60*24) 
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt
