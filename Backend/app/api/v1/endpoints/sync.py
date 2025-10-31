# Endpoints para sincronización de datos desde la app iOS

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.database import get_db
from app.schemas.schemas import UsageDataCreate, UsageDataResponse, UsageDataBulkCreate
from app.crud import crud

router = APIRouter()

@router.post("/", response_model=UsageDataResponse, status_code=status.HTTP_201_CREATED)
def sync_single_usage_data(
    usage_data: UsageDataCreate,
    db: Session = Depends(get_db)
):
    """
    Sincronizar un registro de uso anónimo desde la app.
    
    Endpoint POST para que la app envíe datos de uso individuales.
    """
    # Crear el registro
    db_usage = crud.create_usage_data(db, usage_data)
    
    # Si hay diagnóstico, incrementar el contador
    if usage_data.diagnosis_issue:
        crud.increment_diagnosis_count(db, usage_data.diagnosis_issue)
    
    return db_usage

@router.post("/bulk", response_model=List[UsageDataResponse], status_code=status.HTTP_201_CREATED)
def sync_bulk_usage_data(
    bulk_data: UsageDataBulkCreate,
    db: Session = Depends(get_db)
):
    """
    Sincronizar múltiples registros de uso en una sola petición.
    
    Endpoint POST para sincronización en lote desde la app.
    """
    # Crear todos los registros
    db_usage_list = crud.create_bulk_usage_data(db, bulk_data.usage_data)
    
    # Incrementar contadores de diagnósticos
    for usage in bulk_data.usage_data:
        if usage.diagnosis_issue:
            crud.increment_diagnosis_count(db, usage.diagnosis_issue)
    
    return db_usage_list

@router.get("/history", response_model=List[UsageDataResponse])
def get_usage_history(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """
    Obtener el historial de datos de uso sincronizados.
    
    Endpoint GET para que la app recupere registros previos.
    """
    return crud.get_usage_data(db, skip=skip, limit=limit)