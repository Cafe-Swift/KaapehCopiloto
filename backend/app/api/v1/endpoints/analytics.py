"""
Advanced Analytics Endpoints for Technician Dashboard

Proporciona estadísticas avanzadas:
- Preguntas frecuentes
- Diagnósticos más comunes
- Mapa de calor por ubicación
- Tendencias temporales
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from typing import List, Dict, Optional
from datetime import datetime, timedelta
from app.db.database import get_db
from app.models.models import DiagnosisRecord, User
from app.core.security import get_current_technician
from app.schemas.schemas import UserRead

router = APIRouter()


# ============================================================================
# ENDPOINT 1: Diagnósticos Más Frecuentes
# ============================================================================

@router.get("/frequent-issues")
async def get_frequent_issues(
    limit: int = Query(10, ge=1, le=50, description="Número de resultados"),
    days: Optional[int] = Query(None, ge=1, le=365, description="Últimos N días"),
    db: Session = Depends(get_db),
    current_user: UserRead = Depends(get_current_technician)
):
    """
    Retorna los problemas detectados con mayor frecuencia.
    
    **Respuesta:**
    ```json
    {
        "total_diagnoses": 1250,
        "period": "last_30_days",
        "issues": [
            {
                "issue": "Leaf rust",
                "count": 450,
                "percentage": 36.0,
                "avg_confidence": 0.89
            },
            ...
        ]
    }
    ```
    """
    # Construir query base
    query = db.query(
        DiagnosisRecord.detected_issue,
        func.count(DiagnosisRecord.id).label('count'),
        func.avg(DiagnosisRecord.confidence).label('avg_confidence')
    )
    
    # Filtrar por fecha si se especificó
    if days:
        cutoff_date = datetime.utcnow() - timedelta(days=days)
        query = query.filter(DiagnosisRecord.timestamp >= cutoff_date)
    
    # Agrupar y ordenar
    results = query.group_by(DiagnosisRecord.detected_issue)\
                   .order_by(desc('count'))\
                   .limit(limit)\
                   .all()
    
    # Calcular total
    total_query = db.query(func.count(DiagnosisRecord.id))
    if days:
        total_query = total_query.filter(DiagnosisRecord.timestamp >= cutoff_date)
    total_diagnoses = total_query.scalar()
    
    # Formatear respuesta
    issues = []
    for issue, count, avg_conf in results:
        issues.append({
            "issue": issue,
            "count": count,
            "percentage": round((count / total_diagnoses * 100), 2) if total_diagnoses > 0 else 0,
            "avg_confidence": round(avg_conf, 3) if avg_conf else 0
        })
    
    return {
        "total_diagnoses": total_diagnoses,
        "period": f"last_{days}_days" if days else "all_time",
        "issues": issues
    }


# ============================================================================
# ENDPOINT 2: Mapa de Calor (Ubicaciones)
# ============================================================================

@router.get("/heatmap")
async def get_location_heatmap(
    db: Session = Depends(get_db),
    current_user: UserRead = Depends(get_current_technician)
):
    """
    Retorna distribución de diagnósticos por ubicación para mapa de calor.
    
    **Respuesta:**
    ```json
    {
        "total_locations": 45,
        "locations": [
            {
                "location": "Chiapas, Mexico",
                "diagnoses_count": 320,
                "most_common_issue": "Leaf rust",
                "avg_confidence": 0.87
            },
            ...
        ]
    }
    ```
    """
    # Query por ubicación
    results = db.query(
        DiagnosisRecord.location,
        func.count(DiagnosisRecord.id).label('count'),
        func.avg(DiagnosisRecord.confidence).label('avg_confidence')
    ).filter(
        DiagnosisRecord.location.isnot(None),
        DiagnosisRecord.location != ''
    ).group_by(
        DiagnosisRecord.location
    ).order_by(
        desc('count')
    ).all()
    
    locations = []
    for location, count, avg_conf in results:
        # Obtener el problema más común en esta ubicación
        most_common = db.query(DiagnosisRecord.detected_issue)\
            .filter(DiagnosisRecord.location == location)\
            .group_by(DiagnosisRecord.detected_issue)\
            .order_by(desc(func.count()))\
            .first()
        
        locations.append({
            "location": location,
            "diagnoses_count": count,
            "most_common_issue": most_common[0] if most_common else "Unknown",
            "avg_confidence": round(avg_conf, 3) if avg_conf else 0
        })
    
    return {
        "total_locations": len(locations),
        "locations": locations
    }


# ============================================================================
# ENDPOINT 3: Tendencias Temporales
# ============================================================================

@router.get("/trends")
async def get_temporal_trends(
    days: int = Query(30, ge=7, le=365, description="Período de análisis"),
    interval: str = Query("day", regex="^(day|week|month)$"),
    db: Session = Depends(get_db),
    current_user: UserRead = Depends(get_current_technician)
):
    """
    Retorna tendencias temporales de diagnósticos.
    
    **Respuesta:**
    ```json
    {
        "period": "last_30_days",
        "interval": "day",
        "data_points": [
            {
                "date": "2025-11-01",
                "total_diagnoses": 45,
                "by_category": {
                    "Deficiencias Nutricionales": 20,
                    "Enfermedades": 15,
                    "Plagas": 5,
                    "Planta Saludable": 5
                }
            },
            ...
        ]
    }
    ```
    """
    from app.crud.crud import categorize_issue
    
    cutoff_date = datetime.utcnow() - timedelta(days=days)
    
    # Obtener todos los diagnósticos en el período
    diagnoses = db.query(DiagnosisRecord)\
        .filter(DiagnosisRecord.timestamp >= cutoff_date)\
        .order_by(DiagnosisRecord.timestamp)\
        .all()
    
    # Agrupar por intervalo
    data_points = {}
    
    for diagnosis in diagnoses:
        # Determinar la clave de fecha según el intervalo
        if interval == "day":
            date_key = diagnosis.timestamp.strftime("%Y-%m-%d")
        elif interval == "week":
            # Primera día de la semana
            week_start = diagnosis.timestamp - timedelta(days=diagnosis.timestamp.weekday())
            date_key = week_start.strftime("%Y-%m-%d")
        else:  # month
            date_key = diagnosis.timestamp.strftime("%Y-%m")
        
        # Inicializar si no existe
        if date_key not in data_points:
            data_points[date_key] = {
                "date": date_key,
                "total_diagnoses": 0,
                "by_category": {
                    "Deficiencias Nutricionales": 0,
                    "Enfermedades": 0,
                    "Plagas": 0,
                    "Planta Saludable": 0,
                    "Otros": 0
                }
            }
        
        # Incrementar contadores
        data_points[date_key]["total_diagnoses"] += 1
        category = categorize_issue(diagnosis.detected_issue)
        data_points[date_key]["by_category"][category] += 1
    
    # Convertir a lista ordenada
    sorted_data = sorted(data_points.values(), key=lambda x: x["date"])
    
    return {
        "period": f"last_{days}_days",
        "interval": interval,
        "total_data_points": len(sorted_data),
        "data_points": sorted_data
    }


# ============================================================================
# ENDPOINT 4: Análisis de Feedback
# ============================================================================

@router.get("/feedback-analysis")
async def get_feedback_analysis(
    db: Session = Depends(get_db),
    current_user: UserRead = Depends(get_current_technician)
):
    """
    Analiza el feedback de usuarios sobre diagnósticos.
    
    **Respuesta:**
    ```json
    {
        "total_with_feedback": 450,
        "correct_diagnoses": 410,
        "incorrect_diagnoses": 40,
        "accuracy_rate": 91.11,
        "issues_with_most_errors": [
            {
                "issue": "potassium-K",
                "total": 50,
                "correct": 35,
                "incorrect": 15,
                "accuracy": 70.0
            },
            ...
        ]
    }
    ```
    """
    # Diagnósticos con feedback
    with_feedback = db.query(DiagnosisRecord)\
        .filter(DiagnosisRecord.user_feedback_correct.isnot(None))\
        .all()
    
    total_with_feedback = len(with_feedback)
    correct = sum(1 for d in with_feedback if d.user_feedback_correct)
    incorrect = total_with_feedback - correct
    
    # Análisis por problema
    issue_stats = {}
    for diagnosis in with_feedback:
        issue = diagnosis.detected_issue
        if issue not in issue_stats:
            issue_stats[issue] = {"total": 0, "correct": 0, "incorrect": 0}
        
        issue_stats[issue]["total"] += 1
        if diagnosis.user_feedback_correct:
            issue_stats[issue]["correct"] += 1
        else:
            issue_stats[issue]["incorrect"] += 1
    
    # Calcular accuracy por issue
    issues_analysis = []
    for issue, stats in issue_stats.items():
        accuracy = (stats["correct"] / stats["total"] * 100) if stats["total"] > 0 else 0
        issues_analysis.append({
            "issue": issue,
            "total": stats["total"],
            "correct": stats["correct"],
            "incorrect": stats["incorrect"],
            "accuracy": round(accuracy, 2)
        })
    
    # Ordenar por más errores
    issues_analysis.sort(key=lambda x: x["incorrect"], reverse=True)
    
    return {
        "total_with_feedback": total_with_feedback,
        "correct_diagnoses": correct,
        "incorrect_diagnoses": incorrect,
        "accuracy_rate": round((correct / total_with_feedback * 100), 2) if total_with_feedback > 0 else 0,
        "issues_with_most_errors": issues_analysis[:10]  # Top 10
    }


# ============================================================================
# ENDPOINT 5: Usuarios Más Activos
# ============================================================================

@router.get("/active-users")
async def get_active_users(
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: UserRead = Depends(get_current_technician)
):
    """
    Retorna usuarios con más diagnósticos realizados.
    
    **Respuesta:**
    ```json
    {
        "total_users": 1250,
        "active_users": [
            {
                "user_id": 123,
                "username": "Juan@device-abc",
                "display_name": "Juan",
                "total_diagnoses": 89,
                "last_activity": "2025-11-21T10:30:00",
                "most_common_issue": "Leaf rust"
            },
            ...
        ]
    }
    ```
    """
    # Query de usuarios con conteo de diagnósticos
    user_stats = db.query(
        User.id,
        User.username,
        User.display_name,
        User.last_login_at,
        func.count(DiagnosisRecord.id).label('diagnosis_count')
    ).join(
        DiagnosisRecord, User.id == DiagnosisRecord.user_id
    ).group_by(
        User.id
    ).order_by(
        desc('diagnosis_count')
    ).limit(limit).all()
    
    active_users = []
    for user_id, username, display_name, last_login, count in user_stats:
        # Obtener problema más común del usuario
        most_common = db.query(DiagnosisRecord.detected_issue)\
            .filter(DiagnosisRecord.user_id == user_id)\
            .group_by(DiagnosisRecord.detected_issue)\
            .order_by(desc(func.count()))\
            .first()
        
        active_users.append({
            "user_id": user_id,
            "username": username,
            "display_name": display_name or username.split("@")[0] if "@" in username else username,
            "total_diagnoses": count,
            "last_activity": last_login.isoformat() if last_login else None,
            "most_common_issue": most_common[0] if most_common else "N/A"
        })
    
    # Total de usuarios
    total_users = db.query(func.count(User.id)).scalar()
    
    return {
        "total_users": total_users,
        "showing": len(active_users),
        "active_users": active_users
    }
