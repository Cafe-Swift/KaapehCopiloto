# modelos SQLAlchemy para PostgreSQL

from sqlalchemy import Column, String, Float, Boolean, DateTime, ForeignKey, Integer, Text 
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.db.database import Base

import uuid

class AggregatedMetrics(Base):
    # Metricas agregadas para el dashboard técnico
    __tablename__ = "agregated_metrics"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    metric_type = Column(String, nullable=False) # TPP, NAS, CPM, FDP
    metric_value = Column(Float, nullable=False)
    period_start = Column(DateTime(timezone=True), server_default=func.now())
    period_end = Column(DateTime(timezone=True), server_default=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    def __repr__(self):
        return f"<AggregatedMetrics(type={self.metric_type}, value={self.metric_value})>"
    
class AnonymousUsageData(Base):
    # Datos de uso anónimo recopilados de los usuarios
    __tablename__ = "anonymous_usage_data"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_role = Column(String, nullable=False)  # Productor o Técnico
    diagnosis_issue = Column(String, nullable=True) # tipo de diagnóstico
    diagnosis_confidence = Column(Float, nullable=True)  # confianza del modelo
    user_feedback_correct = Column(Boolean, nullable=True)  # feedback del usuario
    action_items_completed = Column(Integer, default=0)  # tareas completadas
    action_items_total = Column(Integer, default=0)  # tareas totales
    session_duration = Column(Integer, nullable=True)  # duración en segundos
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    synced_at = Column(DateTime(timezone=True), server_default=func.now())

    def __repr__(self):
        return f"<AnonymousUsageData(role={self.user_role}, issue={self.diagnosis_issue})>"
    
class TechnicianUser(Base):
    # Usuarios técnicos
    __tablename__ = "technician_users"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_name = Column(String, unique=True, nullable=False, index=True)
    full_name = Column(String, nullable=True)
    hashed_password = Column(String, nullable=True)  # para autenticación futura
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_login = Column(DateTime(timezone=True), nullable=True) 

    def __repr__(self):
        return f"<TechnicianUser(name={self.user_name}, full_name={self.full_name})>"
    
class DiagnosisFrequency(Base):
    # Frecuencia de diagnósticos para Focos de Duda Principales (FDP)
    __tablename__ = "diagnosis_frequencies"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    issue_type = Column(String, nullable=False, index=True)  # tipo de diagnóstico
    count = Column(Integer, default=1)  # número de veces diagnosticado
    period_start = Column(DateTime(timezone=True), server_default=func.now())
    period_end = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    def __repr__(self):
        return f"<DiagnosisFrequency(issue={self.issue_type}, count={self.count})>"