"""
Script de migración para agregar device_id y display_name a la tabla users

Ejecutar después de actualizar los modelos:
    python backend/migrate_add_device_fields.py
"""

import sys
from pathlib import Path

# Agregar el directorio app al path
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

from sqlalchemy import text
from app.db.database import engine, SessionLocal
from app.models.models import Base


def migrate():
    """
    Agrega las columnas display_name y device_id a users table
    """
    print("🔄 Iniciando migración...")
    
    db = SessionLocal()
    
    try:
        # Verificar si las columnas ya existen
        result = db.execute(text("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name='users'
        """))
        
        existing_columns = [row[0] for row in result]
        print(f"📊 Columnas existentes: {existing_columns}")
        
        # Agregar display_name si no existe
        if 'display_name' not in existing_columns:
            print("➕ Agregando columna 'display_name'...")
            db.execute(text("ALTER TABLE users ADD COLUMN display_name VARCHAR"))
            print("✅ Columna 'display_name' agregada")
        else:
            print("ℹ️  Columna 'display_name' ya existe")
        
        # Agregar device_id si no existe
        if 'device_id' not in existing_columns:
            print("➕ Agregando columna 'device_id'...")
            db.execute(text("ALTER TABLE users ADD COLUMN device_id VARCHAR"))
            db.execute(text("CREATE INDEX idx_users_device_id ON users(device_id)"))
            print("✅ Columna 'device_id' agregada con índice")
        else:
            print("ℹ️  Columna 'device_id' ya existe")
        
        # Migrar datos existentes: extraer display_name de username
        print("🔄 Migrando datos existentes...")
        db.execute(text("""
            UPDATE users 
            SET display_name = CASE 
                WHEN username LIKE '%@%' THEN SUBSTRING(username FROM 1 FOR POSITION('@' IN username) - 1)
                ELSE username 
            END
            WHERE display_name IS NULL
        """))
        
        db.commit()
        print("✅ Migración completada exitosamente")
        
    except Exception as e:
        print(f"❌ Error durante la migración: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    migrate()
