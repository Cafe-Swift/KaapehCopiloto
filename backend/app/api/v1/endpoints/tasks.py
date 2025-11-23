"""
API endpoints for Task (ActionItem) management
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timedelta

from app.db.database import get_db
from app.models.models import ActionItem, DiagnosisRecord, User
from app.schemas.schemas import (
    ActionItemCreate,
    ActionItemUpdate,
    ActionItemResponse,
    ActionItemStats
)

router = APIRouter(
    prefix="/tasks",
    tags=["Tasks"]
)


# MARK: - CRUD Operations

@router.post("/", response_model=ActionItemResponse)
def create_task(
    task: ActionItemCreate,
    db: Session = Depends(get_db)
):
    """
    Create a new task (action item)
    """
    # Verificar que el diagnóstico existe
    diagnosis = db.query(DiagnosisRecord).filter(DiagnosisRecord.id == task.diagnosis_id).first()
    if not diagnosis:
        raise HTTPException(status_code=404, detail="Diagnosis not found")
    
    # Crear la tarea
    db_task = ActionItem(
        diagnosis_id=task.diagnosis_id,
        description_text=task.description_text,
        priority=task.priority,
        category=task.category,
        due_date=task.due_date,
        reminder_date=task.reminder_date
    )
    
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    
    return db_task


@router.get("/{task_id}", response_model=ActionItemResponse)
def get_task(
    task_id: int,
    db: Session = Depends(get_db)
):
    """
    Get a specific task by ID
    """
    task = db.query(ActionItem).filter(ActionItem.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    return task


@router.get("/user/{user_id}", response_model=List[ActionItemResponse])
def get_user_tasks(
    user_id: int,
    completed: bool = None,
    priority: str = None,
    category: str = None,
    db: Session = Depends(get_db)
):
    """
    Get all tasks for a specific user with optional filters
    
    Query parameters:
    - completed: Filter by completion status (true/false)
    - priority: Filter by priority (Baja, Media, Alta, Urgente)
    - category: Filter by category (tratamiento, prevención, monitoreo)
    """
    # Verificar que el usuario existe
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Query base: tareas del usuario a través de diagnósticos
    query = db.query(ActionItem).join(DiagnosisRecord).filter(DiagnosisRecord.user_id == user_id)
    
    # Aplicar filtros opcionales
    if completed is not None:
        query = query.filter(ActionItem.is_completed == completed)
    
    if priority:
        query = query.filter(ActionItem.priority == priority)
    
    if category:
        query = query.filter(ActionItem.category == category)
    
    # Ordenar por fecha de creación (más recientes primero)
    query = query.order_by(ActionItem.created_at.desc())
    
    tasks = query.all()
    return tasks


@router.put("/{task_id}", response_model=ActionItemResponse)
def update_task(
    task_id: int,
    task_update: ActionItemUpdate,
    db: Session = Depends(get_db)
):
    """
    Update an existing task
    """
    db_task = db.query(ActionItem).filter(ActionItem.id == task_id).first()
    if not db_task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    # Actualizar solo los campos proporcionados
    update_data = task_update.model_dump(exclude_unset=True)
    
    # Si se marca como completada, establecer completed_at
    if update_data.get("is_completed") and not db_task.is_completed:
        update_data["completed_at"] = datetime.utcnow()
    
    # Si se desmarca como completada, limpiar completed_at
    if update_data.get("is_completed") == False:
        update_data["completed_at"] = None
    
    for key, value in update_data.items():
        setattr(db_task, key, value)
    
    db.commit()
    db.refresh(db_task)
    
    return db_task


@router.delete("/{task_id}")
def delete_task(
    task_id: int,
    db: Session = Depends(get_db)
):
    """
    Delete a task
    """
    db_task = db.query(ActionItem).filter(ActionItem.id == task_id).first()
    if not db_task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    db.delete(db_task)
    db.commit()
    
    return {"message": "Task deleted successfully", "task_id": task_id}


# MARK: - Batch Operations

@router.post("/batch/toggle")
def toggle_multiple_tasks(
    task_ids: List[int],
    db: Session = Depends(get_db)
):
    """
    Toggle completion status for multiple tasks
    """
    tasks = db.query(ActionItem).filter(ActionItem.id.in_(task_ids)).all()
    
    if not tasks:
        raise HTTPException(status_code=404, detail="No tasks found with provided IDs")
    
    for task in tasks:
        task.is_completed = not task.is_completed
        task.completed_at = datetime.utcnow() if task.is_completed else None
    
    db.commit()
    
    return {
        "message": f"Toggled {len(tasks)} tasks",
        "task_ids": task_ids
    }


@router.delete("/batch/completed")
def delete_completed_tasks(
    user_id: int,
    db: Session = Depends(get_db)
):
    """
    Delete all completed tasks for a user
    """
    deleted = db.query(ActionItem).join(DiagnosisRecord).filter(
        DiagnosisRecord.user_id == user_id,
        ActionItem.is_completed == True
    ).delete(synchronize_session=False)
    
    db.commit()
    
    return {
        "message": f"Deleted {deleted} completed tasks",
        "deleted_count": deleted
    }


# MARK: - Statistics & Analytics

@router.get("/user/{user_id}/stats", response_model=ActionItemStats)
def get_user_task_stats(
    user_id: int,
    db: Session = Depends(get_db)
):
    """
    Get comprehensive task statistics for a user
    """
    # Verificar usuario
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Obtener todas las tareas del usuario
    tasks = db.query(ActionItem).join(DiagnosisRecord).filter(
        DiagnosisRecord.user_id == user_id
    ).all()
    
    if not tasks:
        return ActionItemStats(
            total=0,
            completed=0,
            pending=0,
            overdue=0,
            due_soon=0,
            by_priority={},
            by_category={},
            completion_rate=0.0
        )
    
    # Calcular estadísticas
    total = len(tasks)
    completed = sum(1 for t in tasks if t.is_completed)
    pending = total - completed
    
    # Tareas vencidas y próximas a vencer
    now = datetime.utcnow()
    day_from_now = now + timedelta(days=1)
    
    overdue = sum(
        1 for t in tasks 
        if not t.is_completed and t.due_date and t.due_date < now
    )
    
    due_soon = sum(
        1 for t in tasks 
        if not t.is_completed and t.due_date 
        and now < t.due_date < day_from_now
    )
    
    # Agrupar por prioridad
    by_priority = {}
    for task in tasks:
        priority = task.priority or "Media"
        by_priority[priority] = by_priority.get(priority, 0) + 1
    
    # Agrupar por categoría
    by_category = {}
    for task in tasks:
        if task.category:
            by_category[task.category] = by_category.get(task.category, 0) + 1
    
    # Calcular tasa de completado
    completion_rate = (completed / total * 100) if total > 0 else 0.0
    
    return ActionItemStats(
        total=total,
        completed=completed,
        pending=pending,
        overdue=overdue,
        due_soon=due_soon,
        by_priority=by_priority,
        by_category=by_category,
        completion_rate=round(completion_rate, 2)
    )


# MARK: - Sync Endpoints

@router.post("/sync")
def sync_tasks(
    tasks_data: List[ActionItemCreate],
    db: Session = Depends(get_db)
):
    """
    Bulk sync tasks from mobile app
    
    This endpoint creates or updates multiple tasks in a single request
    """
    created_tasks = []
    
    for task_data in tasks_data:
        # Verificar si el diagnóstico existe
        diagnosis = db.query(DiagnosisRecord).filter(
            DiagnosisRecord.id == task_data.diagnosis_id
        ).first()
        
        if not diagnosis:
            continue  # Skip tareas con diagnóstico inválido
        
        # Crear la tarea
        db_task = ActionItem(
            diagnosis_id=task_data.diagnosis_id,
            description_text=task_data.description_text,
            priority=task_data.priority,
            category=task_data.category,
            due_date=task_data.due_date,
            reminder_date=task_data.reminder_date
        )
        
        db.add(db_task)
        created_tasks.append(db_task)
    
    db.commit()
    
    return {
        "message": "Tasks synced successfully",
        "synced_count": len(created_tasks),
        "tasks": [ActionItemResponse.model_validate(task) for task in created_tasks]
    }
