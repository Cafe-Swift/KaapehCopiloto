# Endpoints para métricas del dashboard técnico

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timedelta

from app.db.database import get_db
from app.schemas.schemas import (
    MetricResponse, MetricsListResponse, DashboardSummary,
    DiagnosisFrequencyResponse
)
from app.crud import crud

router = APIRouter()

@router.get("/", response_model=MetricsListResponse)
def get_all_metrics(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """
    Obtener todas las métricas agregadas.
    
    Este endpoint GET permite al técnico obtener todas las métricas disponibles.
    """
    metrics = crud.get_metrics(db, skip=skip, limit=limit)
    return MetricsListResponse(
        metrics=metrics,
        total_count=len(metrics)
    )

@router.get("/dashboard", response_model=DashboardSummary)
def get_dashboard_summary(
    days: int = 7,
    db: Session = Depends(get_db)
):
    """
    Obtener resumen del dashboard con todas las métricas principales.
    
    Este endpoint GET calcula y retorna:
    - TPP (Tasa de Precisión Percibida)
    - NAS (Nivel de Adopción de Sugerencias)
    - CPM (Confiabilidad Promedio del Modelo)
    - Top 5 problemas más diagnosticados
    """
    # Calcular métricas
    tpp = crud.calculate_tpp(db, days=days)
    nas = crud.calculate_nas(db, days=days)
    cpm = crud.calculate_cpm(db, days=days)
    
    # Obtener top issues
    top_issues = crud.get_top_diagnosis_issues(db, limit=5)
    
    # Contar total de diagnósticos
    total_diagnoses = db.query(crud.AnonymousUsageData).filter(
        crud.AnonymousUsageData.diagnosis_issue.isnot(None)
    ).count()

    return DashboardSummary(
        tpp=round(tpp, 2),
        nas=round(nas, 2),
        cpm=round(cpm, 2),
        total_diagnoses=total_diagnoses,
        top_issues=top_issues,
        period_start=datetime.utcnow() - timedelta(days=days),
        period_end=datetime.utcnow()
    )

@router.get("/tpp", response_model=dict)
def get_tpp_metric(
    days: int = 7,
    db: Session = Depends(get_db)
):
    """
    Obtener solo la métrica TPP (Tasa de Precisión Percibida).

    Endpoint GET específico para recuperar la métrica TPP.
    """
    tpp = crud.calculate_tpp(db, days=days)
    return {
        "metric_type": "TPP",
        "metric_value": round(tpp, 2),
        "description": "Tasa de Precisión Percibida (%)",
        "period_days": days
    }

@router.get("/nas", response_model=dict)
def get_nas_metric(
    days: int = 7,
    db: Session = Depends(get_db)
):
    """
    Obtener solo la métrica NAS (Nivel de Adopción de Sugerencias).

    Endpoint GET específico para recuperar la métrica NAS.
    """
    nas = crud.calculate_nas(db, days=days)
    return {
        "metric_type": "NAS",
        "metric_value": round(nas, 2),
        "description": "Nivel de Adopción de Sugerencias (%)",
        "period_days": days
    }

@router.get("/cpm", response_model=dict)
def get_cpm_metric(
    days: int = 7,
    db: Session = Depends(get_db)
):
    """
    Obtener solo la métrica CPM (Confiabilidad Promedio del Modelo).

    Endpoint GET específico para recuperar la métrica CPM.
    """
    cpm = crud.calculate_cpm(db, days=days)
    return {
        "metric_type": "CPM",
        "metric_value": round(cpm, 2),
        "description": "Confiabilidad Promedio del Modelo (%)",
        "period_days": days
    }

@router.get("/top-issues", response_model=List[DiagnosisFrequencyResponse])
def get_top_issues(
    limit: int = 5,
    db: Session = Depends(get_db)
):
    """
    Obtener los problemas de diagnóstico más frecuentes.

    Endpoint GET para recuperar los problemas más diagnosticados.
    """
    return crud.get_top_diagnosis_issues(db, limit=limit)