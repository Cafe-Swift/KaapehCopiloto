"""
Migration script: Add priority, due_date, reminder_date, category, and completed_at to action_items
"""

import sys
import os
from pathlib import Path

# Añadir el directorio raíz al path (backend/)
# El script está en backend/scripts/migrations/
project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from sqlalchemy import text
from app.db.database import engine
from app.models.models import ActionItem


def migrate():
    """
    Add new columns to action_items table
    """
    print("🔄 Starting migration: Add priority and date fields to action_items...")
    
    with engine.connect() as conn:
        try:
            # Verificar si las columnas ya existen
            result = conn.execute(text("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = 'action_items'
                AND column_name IN ('priority', 'due_date', 'reminder_date', 'category', 'completed_at')
            """))
            
            existing_columns = [row[0] for row in result]
            
            # Agregar columna priority si no existe
            if 'priority' not in existing_columns:
                conn.execute(text("""
                    ALTER TABLE action_items 
                    ADD COLUMN priority VARCHAR DEFAULT 'Media' NOT NULL
                """))
                print("✅ Added column: priority")
            else:
                print("ℹ️  Column 'priority' already exists")
            
            # Agregar columna due_date si no existe
            if 'due_date' not in existing_columns:
                conn.execute(text("""
                    ALTER TABLE action_items 
                    ADD COLUMN due_date TIMESTAMP
                """))
                print("✅ Added column: due_date")
            else:
                print("ℹ️  Column 'due_date' already exists")
            
            # Agregar columna reminder_date si no existe
            if 'reminder_date' not in existing_columns:
                conn.execute(text("""
                    ALTER TABLE action_items 
                    ADD COLUMN reminder_date TIMESTAMP
                """))
                print("✅ Added column: reminder_date")
            else:
                print("ℹ️  Column 'reminder_date' already exists")
            
            # Agregar columna category si no existe
            if 'category' not in existing_columns:
                conn.execute(text("""
                    ALTER TABLE action_items 
                    ADD COLUMN category VARCHAR
                """))
                print("✅ Added column: category")
            else:
                print("ℹ️  Column 'category' already exists")
            
            # Agregar columna completed_at si no existe
            if 'completed_at' not in existing_columns:
                conn.execute(text("""
                    ALTER TABLE action_items 
                    ADD COLUMN completed_at TIMESTAMP
                """))
                print("✅ Added column: completed_at")
            else:
                print("ℹ️  Column 'completed_at' already exists")
            
            conn.commit()
            print("✅ Migration completed successfully!")
            
        except Exception as e:
            conn.rollback()
            print(f"❌ Migration failed: {e}")
            raise


if __name__ == "__main__":
    migrate()
