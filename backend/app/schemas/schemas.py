"""
Pydantic schemas for request/response validation
"""

from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, Dict, List


# User Schemas
class UserBase(BaseModel):
    username: str = Field(..., description="User's username (formato: nombre@device-id)")
    role: str = Field(default="Productor", description="User role: Productor or Técnico")
    preferred_language: str = Field(default="es", description="Preferred language code")


class UserCreate(UserBase):
    display_name: Optional[str] = Field(None, description="Nombre visible sin device_id")
    device_id: Optional[str] = Field(None, description="Identificador único del dispositivo")


class UserResponse(UserBase):
    id: int
    created_at: datetime
    last_login_at: datetime
    
    class Config:
        from_attributes = True


class UserRead(UserResponse):
    """Schema for reading user data with authentication"""
    pass


# Authentication Schemas
class LoginRequest(BaseModel):
    username: str = Field(..., description="Username for authentication")


class AuthResponse(BaseModel):
    user_id: int
    token: Optional[str] = None
    role: str
    message: str


# Diagnosis Schemas
class DiagnosisCreate(BaseModel):
    detected_issue: str = Field(..., description="Detected issue name")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Model confidence (0-1)")
    location: Optional[str] = None


class DiagnosisFeedback(BaseModel):
    is_correct: bool = Field(..., description="Whether diagnosis was correct")
    corrected_issue: Optional[str] = None


class DiagnosisResponse(BaseModel):
    id: int
    timestamp: datetime
    detected_issue: str
    confidence: float
    user_feedback_correct: Optional[bool]
    user_corrected_issue: Optional[str]
    
    class Config:
        from_attributes = True


# Sync Schemas
class DiagnosisSyncData(BaseModel):
    timestamp: datetime
    detected_issue: str
    confidence: float
    user_feedback_correct: Optional[bool] = None
    location: Optional[str] = None


class SyncPayload(BaseModel):
    diagnoses: List[DiagnosisSyncData]


class SyncResponse(BaseModel):
    message: str
    synced_count: int


# Metrics Schemas
class MetricsResponse(BaseModel):
    tpp: float = Field(..., description="Tasa de Precisión Percibida (%)")
    cpm: float = Field(..., description="Confiabilidad Promedio del Modelo (%)")
    nas: Optional[float] = Field(None, description="Nivel de Adopción de Sugerencias (%)")
    total_diagnoses: int
    issue_distribution: Dict[str, int]
    timestamp: datetime


# Category Distribution Schema
class CategoryDistributionResponse(BaseModel):
    """
    Distribución de diagnósticos agrupados por categoría
    
    Categorías:
    - Deficiencias Nutricionales
    - Enfermedades
    - Plagas
    - Plantas Saludables
    - Otros
    """
    categories: Dict[str, int] = Field(..., description="Conteo de diagnósticos por categoría")
    total_diagnoses: int = Field(..., description="Total de diagnósticos")
    timestamp: datetime = Field(..., description="Timestamp de la consulta")


# Health Check Schema
class HealthResponse(BaseModel):
    status: str
    version: str
    timestamp: datetime
