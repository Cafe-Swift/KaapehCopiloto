"""
CRUD operations for database models
"""

from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional, Dict
from datetime import datetime

from app.models.models import User, DiagnosisRecord, AccessibilityConfig, ActionItem
from app.schemas.schemas import UserCreate


# ==================== USER OPERATIONS ====================

def get_user_by_username(db: Session, username: str) -> Optional[User]:
    """
    Get user by username
    """
    return db.query(User).filter(User.username == username).first()


def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
    """
    Get user by ID
    """
    return db.query(User).filter(User.id == user_id).first()


def create_user(db: Session, user: UserCreate) -> User:
    """
    Create new user
    """
    db_user = User(
        username=user.username,
        role=user.role,
        preferred_language=user.preferred_language,
        created_at=datetime.utcnow(),
        last_login_at=datetime.utcnow()
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def update_user_last_login(db: Session, user: User) -> User:
    """
    Update user's last login timestamp
    """
    user.last_login_at = datetime.utcnow()
    db.commit()
    db.refresh(user)
    return user


# ==================== DIAGNOSIS OPERATIONS ====================

def create_diagnosis(db: Session, user_id: Optional[int], diagnosis_data: dict) -> DiagnosisRecord:
    """
    Create new diagnosis record
    """
    db_diagnosis = DiagnosisRecord(
        user_id=user_id,
        timestamp=diagnosis_data.get("timestamp", datetime.utcnow()),
        detected_issue=diagnosis_data["detected_issue"],
        confidence=diagnosis_data["confidence"],
        user_feedback_correct=diagnosis_data.get("user_feedback_correct"),
        location=diagnosis_data.get("location")
    )
    db.add(db_diagnosis)
    db.commit()
    db.refresh(db_diagnosis)
    return db_diagnosis


def get_user_diagnoses(db: Session, user_id: int, limit: int = 100) -> list[DiagnosisRecord]:
    """
    Get user's diagnosis history
    """
    return db.query(DiagnosisRecord)\
        .filter(DiagnosisRecord.user_id == user_id)\
        .order_by(DiagnosisRecord.timestamp.desc())\
        .limit(limit)\
        .all()


# ==================== METRICS CALCULATIONS ====================

def calculate_tpp(db: Session) -> float:
    """
    Calculate Tasa de Precisión Percibida (TPP)
    Percentage of diagnoses where user feedback was positive
    """
    total = db.query(DiagnosisRecord)\
        .filter(DiagnosisRecord.user_feedback_correct.isnot(None))\
        .count()
    
    if total == 0:
        return 0.0
    
    correct = db.query(DiagnosisRecord)\
        .filter(DiagnosisRecord.user_feedback_correct == True)\
        .count()
    
    return round((correct / total) * 100, 2)


def calculate_cpm(db: Session) -> float:
    """
    Calculate Confiabilidad Promedio del Modelo (CPM)
    Average confidence of all diagnoses
    """
    avg_confidence = db.query(func.avg(DiagnosisRecord.confidence))\
        .scalar()
    
    if avg_confidence is None:
        return 0.0
    
    return round(float(avg_confidence) * 100, 2)


def get_issue_distribution(db: Session) -> Dict[str, int]:
    """
    Get distribution of detected issues
    """
    results = db.query(
        DiagnosisRecord.detected_issue,
        func.count(DiagnosisRecord.id)
    ).group_by(DiagnosisRecord.detected_issue).all()
    
    return {issue: count for issue, count in results}


def calculate_nas(db: Session) -> Optional[float]:
    """
    Calculate Nivel de Adopción de Sugerencias (NAS)
    Percentage of suggested actions that were completed
    """
    total_actions = db.query(ActionItem).count()
    
    if total_actions == 0:
        return None
    
    completed_actions = db.query(ActionItem)\
        .filter(ActionItem.is_completed == True)\
        .count()
    
    return round((completed_actions / total_actions) * 100, 2)


# ==================== ACCESSIBILITY CONFIG OPERATIONS ====================

def get_or_create_accessibility_config(db: Session, user_id: int) -> AccessibilityConfig:
    """
    Get or create accessibility configuration for user
    """
    config = db.query(AccessibilityConfig)\
        .filter(AccessibilityConfig.user_id == user_id)\
        .first()
    
    if not config:
        config = AccessibilityConfig(user_id=user_id)
        db.add(config)
        db.commit()
        db.refresh(config)
    
    return config


def update_accessibility_config(db: Session, user_id: int, config_data: dict) -> AccessibilityConfig:
    """
    Update accessibility configuration
    """
    config = get_or_create_accessibility_config(db, user_id)
    
    for key, value in config_data.items():
        if hasattr(config, key):
            setattr(config, key, value)
    
    db.commit()
    db.refresh(config)
    return config


# ==================== ACTION ITEM OPERATIONS ====================

def create_action_item(db: Session, diagnosis_id: int, description: str) -> ActionItem:
    """
    Create action item for a diagnosis
    """
    action = ActionItem(
        diagnosis_id=diagnosis_id,
        description_text=description,
        is_completed=False
    )
    db.add(action)
    db.commit()
    db.refresh(action)
    return action


def update_action_item_status(db: Session, action_id: int, is_completed: bool) -> ActionItem:
    """
    Update action item completion status
    """
    action = db.query(ActionItem).filter(ActionItem.id == action_id).first()
    if action:
        action.is_completed = is_completed
        db.commit()
        db.refresh(action)
    return action
