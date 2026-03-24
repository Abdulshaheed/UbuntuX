from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey, DateTime, Table
from sqlalchemy.orm import relationship
from database import Base
import datetime

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    name = Column(String)
    hashed_password = Column(String)
    trust_score = Column(Integer, default=75)
    on_time_percentage = Column(Float, default=0.0)
    is_kyc_verified = Column(Boolean, default=False)
    bvn = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    memberships = relationship("CircleMembership", back_populates="user")
    created_circles = relationship("Circle", back_populates="creator")

class Circle(Base):
    __tablename__ = "circles"

    id = Column(String, primary_key=True, index=True)
    name = Column(String)
    contribution_amount = Column(Float)
    max_members = Column(Integer)
    frequency = Column(String)
    is_cross_border_allowed = Column(Boolean, default=False)
    total_pot = Column(Float, default=0.0)
    creator_id = Column(String, ForeignKey("users.id"))

    creator = relationship("User", back_populates="created_circles")
    members = relationship("CircleMembership", back_populates="circle")

class CircleMembership(Base):
    __tablename__ = "circle_memberships"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"))
    circle_id = Column(String, ForeignKey("circles.id"))
    joined_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User", back_populates="memberships")
    circle = relationship("Circle", back_populates="members")

class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"))
    circle_id = Column(String, ForeignKey("circles.id"), nullable=True)
    amount = Column(Float)
    currency = Column(String, default="NGN")
    type = Column(String) # 'contribution', 'payout'
    status = Column(String) # 'pending', 'success', 'failed'
    txn_ref = Column(String, unique=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
