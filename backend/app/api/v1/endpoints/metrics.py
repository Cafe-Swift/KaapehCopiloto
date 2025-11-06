"""
Metrics endpoints for technician dashboard
"""

from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime
from app.db.database import get_db
from app.schemas.schemas import MetricsResponse
from app.crud import crud
from app.core.security import verify_token

router = APIRouter()


def get_current_user(authorization: Optional[str] = Header(None)):
    """
    Verify technician authentication
    """
    if not authorization:
        raise HTTPException(status_code=401, detail="Not authenticated")
    
    try:
        token = authorization.replace("Bearer ", "")
        payload = verify_token(token)
        if not payload:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        if payload.get("role") != "Técnico":
            raise HTTPException(status_code=403, detail="Not authorized")
        
        return payload
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid authentication")


@router.get("/metrics", response_model=MetricsResponse)
async def get_metrics(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Get aggregated metrics for technician dashboard
    Requires technician authentication
    """
    # Calculate metrics
    tpp = crud.calculate_tpp(db)
    cpm = crud.calculate_cpm(db)
    total_diagnoses = db.query(crud.DiagnosisRecord).count()
    issue_distribution = crud.get_issue_distribution(db)
    
    # Calculate NAS (if action items are tracked)
    nas = None  # TODO: Implement in Sprint 2
    
    return MetricsResponse(
        tpp=tpp,
        cpm=cpm,
        nas=nas,
        total_diagnoses=total_diagnoses,
        issue_distribution=issue_distribution,
        timestamp=datetime.utcnow()
    )
