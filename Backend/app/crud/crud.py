# Operaciones CRUD para la base de datos

from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from datetime import datetime, timedelta
from typing import List, Optional

from app.models.models import AggregatedMetrics, AnonymousUsageData, DiagnosisFrequency, TechnicianUser
from app.schemas.schemas import UsageDataCreate, MetricBase


# metricas agregadas
def get_metrics(db: Session, skip: int = 0, limit: int = 100) -> List[AggregatedMetrics]:
    """Obtener todas las métricas agregadas"""
    return db.query(AggregatedMetrics).offset(skip).limit(limit).all()


def get_metric_by_type(db: Session, metric_type: str) -> Optional[AggregatedMetrics]:
    """Obtener métrica específica por tipo"""
    return db.query(AggregatedMetrics).filter(
        AggregatedMetrics.metric_type == metric_type
    ).order_by(AggregatedMetrics.created_at.desc()).first()


def create_metric(db: Session, metric: MetricBase) -> AggregatedMetrics:
    """Crear nueva métrica agregada"""
    db_metric = AggregatedMetrics(
        metric_type=metric.metric_type,
        metric_value=metric.metric_value,
        period_start=datetime.utcnow() - timedelta(days=7),
        period_end=datetime.utcnow()
    )
    db.add(db_metric)
    db.commit()
    db.refresh(db_metric)
    return db_metric


# datos de uso anónimo
def create_usage_data(db: Session, usage: UsageDataCreate) -> AnonymousUsageData:
    """Crear nuevo registro de uso anónimo"""
    db_usage = AnonymousUsageData(**usage.model_dump())
    db.add(db_usage)
    db.commit()
    db.refresh(db_usage)
    return db_usage


def create_bulk_usage_data(db: Session, usage_list: List[UsageDataCreate]) -> List[AnonymousUsageData]:
    """Crear múltiples registros de uso"""
    db_usage_list = [AnonymousUsageData(**usage.model_dump()) for usage in usage_list]
    db.add_all(db_usage_list)
    db.commit()
    return db_usage_list


def get_usage_data(db: Session, skip: int = 0, limit: int = 100) -> List[AnonymousUsageData]:
    """Obtener datos de uso"""
    return db.query(AnonymousUsageData).offset(skip).limit(limit).all()


# frecuencias de diagnóstico
def get_top_diagnosis_issues(db: Session, limit: int = 5) -> List[DiagnosisFrequency]:
    """Obtener los diagnósticos más frecuentes"""
    return db.query(DiagnosisFrequency).order_by(
        DiagnosisFrequency.count.desc()
    ).limit(limit).all()


def increment_diagnosis_count(db: Session, issue_type: str) -> DiagnosisFrequency:
    """Incrementar contador de diagnóstico"""
    existing = db.query(DiagnosisFrequency).filter(
        DiagnosisFrequency.issue_type == issue_type
    ).first()
    
    if existing:
        existing.count += 1
        existing.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(existing)
        return existing
    else:
        new_freq = DiagnosisFrequency(
            issue_type=issue_type,
            count=1,
            period_start=datetime.utcnow() - timedelta(days=30),
            period_end=datetime.utcnow()
        )
        db.add(new_freq)
        db.commit()
        db.refresh(new_freq)
        return new_freq


# cálculo de métricas
def calculate_tpp(db: Session, days: int = 7) -> float:
    """Calcular Tasa de Precisión Percibida (TPP)"""
    start_date = datetime.utcnow() - timedelta(days=days)
    
    total_feedback = db.query(AnonymousUsageData).filter(
        and_(
            AnonymousUsageData.user_feedback_correct.isnot(None),
            AnonymousUsageData.created_at >= start_date
        )
    ).count()
    
    if total_feedback == 0:
        return 0.0
    
    correct_feedback = db.query(AnonymousUsageData).filter(
        and_(
            AnonymousUsageData.user_feedback_correct == True,
            AnonymousUsageData.created_at >= start_date
        )
    ).count()
    
    return (correct_feedback / total_feedback) * 100


def calculate_nas(db: Session, days: int = 7) -> float:
    """Calcular Nivel de Adopción de Sugerencias (NAS)"""
    start_date = datetime.utcnow() - timedelta(days=days)
    
    result = db.query(
        func.sum(AnonymousUsageData.action_items_completed).label('completed'),
        func.sum(AnonymousUsageData.action_items_total).label('total')
    ).filter(
        AnonymousUsageData.created_at >= start_date
    ).first()
    
    if not result or not result.total or result.total == 0:
        return 0.0
    
    return (result.completed / result.total) * 100


def calculate_cpm(db: Session, days: int = 7) -> float:
    """Calcular Confiabilidad Promedio del Modelo (CPM)"""
    start_date = datetime.utcnow() - timedelta(days=days)
    
    avg_confidence = db.query(
        func.avg(AnonymousUsageData.diagnosis_confidence)
    ).filter(
        and_(
            AnonymousUsageData.diagnosis_confidence.isnot(None),
            AnonymousUsageData.created_at >= start_date
        )
    ).scalar()
    
    return (avg_confidence * 100) if avg_confidence else 0.0


# técnicos
def get_technician_by_phone(db: Session, phone_number: str) -> Optional[TechnicianUser]:
    """Obtener técnico por número de teléfono"""
    return db.query(TechnicianUser).filter(
        TechnicianUser.phone_number == phone_number
    ).first()


def create_technician(db: Session, phone_number: str, full_name: str = None) -> TechnicianUser:
    """Crear nuevo técnico"""
    db_tech = TechnicianUser(
        phone_number=phone_number,
        full_name=full_name
    )
    db.add(db_tech)
    db.commit()
    db.refresh(db_tech)
    return db_tech
