"""
Sync endpoints for data synchronization
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.schemas.schemas import SyncPayload, SyncResponse
from app.models.models import DiagnosisRecord

router = APIRouter()


@router.post("/sync", response_model=SyncResponse)
async def sync_diagnoses(payload: SyncPayload, db: Session = Depends(get_db)):
    """
    Sync anonymized diagnosis data from mobile app
    """
    synced_count = 0
    
    for diagnosis_data in payload.diagnoses:
        # Create anonymous diagnosis record
        db_diagnosis = DiagnosisRecord(
            user_id=None,  # Anonymous for privacy
            timestamp=diagnosis_data.timestamp,
            detected_issue=diagnosis_data.detected_issue,
            confidence=diagnosis_data.confidence,
            user_feedback_correct=diagnosis_data.user_feedback_correct,
            location=diagnosis_data.location
        )
        db.add(db_diagnosis)
        synced_count += 1
    
    db.commit()
    
    return SyncResponse(
        message="Data synced successfully",
        synced_count=synced_count
    )
