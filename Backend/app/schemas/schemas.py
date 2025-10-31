# Schemas Pydantic para validacion de request y response

from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List

# metricas 
class MetricBase(BaseModel):
    metric_type: str = Field(..., description="Tipo de métrica (TPP, NAS, CPM, FDP)")
    metric_value: float = Field(..., description="Valor de la métrica")

class MetricResponse(MetricBase):
    id: str
    period_start: datetime
    period_end: datetime
    created_at: datetime

    class Config:
        from_attributes = True

class MetricsListResponse(BaseModel):
    metrics: List[MetricResponse]
    total_count: int

# datos de uso anónimo
class UsageDataCreate(BaseModel):
    user_role: str = Field(..., description="Productor o Técnico")
    diagnosis_issue: Optional[str] = Field(None, description="Roya, Sano, Deficiencia de Nitrógeno")
    diagnosis_confidence: Optional[float] = Field(None, ge=0.0, le=1.0)
    user_feedback_correct: Optional[bool] = None
    action_items_completed: int = Field(default=0, ge=0)
    action_items_total: int = Field(default=0, ge=0)
    session_duration: Optional[int] = Field(None, description="Duración en segundos")

class UsageDataResponse(UsageDataCreate):
    id: str
    created_at: datetime
    synced_at: datetime

    class Config:
        from_attributes = True

class UsageDataBulkCreate(BaseModel):
    usage_data: List[UsageDataCreate]

# diagnostico 
class DiagnosisFrequencyResponse(BaseModel):
    id: str
    issue_type: str
    count: int
    period_start: datetime
    period_end: datetime

    class Config:
        from_attributes = True

# resumen del dashboard
class DashboardSummary(BaseModel):
    tpp: float = Field(..., description="Tasa de Precisión Percibida (%)")
    nas: float = Field(..., description="Nivel de Adopción de Sugerencias (%)")
    cpm: float = Field(..., description="Confiabilidad Promedio del Modelo (%)")
    total_diagnoses: int
    top_issues: List[DiagnosisFrequencyResponse]
    period_start: datetime
    period_end: datetime

# health check
class HealthResponse(BaseModel):
    status: str
    version: str
    timestamp: datetime
    database_connected: bool