"""
SQLAlchemy database models
"""

from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base


class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    role = Column(String, nullable=False, default="Productor")
    preferred_language = Column(String, default="es")
    created_at = Column(DateTime, default=datetime.utcnow)
    last_login_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    diagnoses = relationship("DiagnosisRecord", back_populates="user", cascade="all, delete-orphan")
    accessibility_config = relationship("AccessibilityConfig", back_populates="user", uselist=False, cascade="all, delete-orphan")


class AccessibilityConfig(Base):
    __tablename__ = "accessibility_configs"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    large_text_enabled = Column(Boolean, default=False)
    high_contrast_enabled = Column(Boolean, default=False)
    voice_interaction_preferred = Column(Boolean, default=False)
    onboarding_completed = Column(Boolean, default=False)
    
    # Relationships
    user = relationship("User", back_populates="accessibility_config")


class DiagnosisRecord(Base):
    __tablename__ = "diagnosis_records"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    detected_issue = Column(String, nullable=False)
    confidence = Column(Float, nullable=False)
    user_feedback_correct = Column(Boolean, nullable=True)
    user_corrected_issue = Column(String, nullable=True)
    ai_explanation = Column(String, nullable=True)
    location = Column(String, nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="diagnoses")
    action_items = relationship("ActionItem", back_populates="diagnosis", cascade="all, delete-orphan")


class ActionItem(Base):
    __tablename__ = "action_items"
    
    id = Column(Integer, primary_key=True, index=True)
    diagnosis_id = Column(Integer, ForeignKey("diagnosis_records.id"))
    description_text = Column(String, nullable=False)
    is_completed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    diagnosis = relationship("DiagnosisRecord", back_populates="action_items")


class AggregatedMetrics(Base):
    __tablename__ = "aggregated_metrics"
    
    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    tpp = Column(Float)
    cpm = Column(Float)
    nas = Column(Float, nullable=True)
    total_diagnoses = Column(Integer)
    issue_distribution = Column(JSON)
