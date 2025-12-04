"""
Migration script: Add GPS location fields to diagnosis_records table
"""

import psycopg2
from psycopg2 import sql
import os
from dotenv import load_dotenv

load_dotenv()

def migrate_add_location_fields():
    """
    Add latitude, longitude, and location_name columns to diagnosis_records table
    """
    # Database connection parameters
    db_params = {
        'dbname': os.getenv('DATABASE_NAME', 'kaapeh_db'),
        'user': os.getenv('DATABASE_USER', 'kaapeh_user'),
        'password': os.getenv('DATABASE_PASSWORD', 'kaapeh_password'),
        'host': os.getenv('DATABASE_HOST', 'localhost'),
        'port': os.getenv('DATABASE_PORT', '5432')
    }
    
    conn = None
    cursor = None
    
    try:
        # Connect to database
        print("Conectando a la base de datos...")
        conn = psycopg2.connect(**db_params)
        cursor = conn.cursor()
        
        print("✅ Conexión exitosa")
        
        # Check if columns already exist
        cursor.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name='diagnosis_records' 
            AND column_name IN ('latitude', 'longitude', 'location_name');
        """)
        existing_columns = [row[0] for row in cursor.fetchall()]
        
        if len(existing_columns) == 3:
            print("⚠️  Las columnas de ubicación ya existen. No se requiere migración.")
            return
        
        print(f"📊 Columnas existentes: {existing_columns}")
        print("🔄 Iniciando migración...")
        
        # Add latitude column
        if 'latitude' not in existing_columns:
            print("  → Agregando columna 'latitude'...")
            cursor.execute("""
                ALTER TABLE diagnosis_records 
                ADD COLUMN latitude DOUBLE PRECISION;
            """)
            print("  ✅ Columna 'latitude' agregada")
        
        # Add longitude column
        if 'longitude' not in existing_columns:
            print("  → Agregando columna 'longitude'...")
            cursor.execute("""
                ALTER TABLE diagnosis_records 
                ADD COLUMN longitude DOUBLE PRECISION;
            """)
            print("  ✅ Columna 'longitude' agregada")
        
        # Add location_name column
        if 'location_name' not in existing_columns:
            print("  → Agregando columna 'location_name'...")
            cursor.execute("""
                ALTER TABLE diagnosis_records 
                ADD COLUMN location_name VARCHAR(255);
            """)
            print("  ✅ Columna 'location_name' agregada")
        
        # Create indexes for better query performance
        print("  → Creando índices...")
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_diagnosis_latitude 
            ON diagnosis_records(latitude);
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_diagnosis_longitude 
            ON diagnosis_records(longitude);
        """)
        print("  ✅ Índices creados")
        
        # Commit changes
        conn.commit()
        print("\n🎉 ¡Migración completada exitosamente!")
        
        # Show current schema
        cursor.execute("""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_name = 'diagnosis_records'
            ORDER BY ordinal_position;
        """)
        
        print("\n📋 Esquema actualizado de diagnosis_records:")
        print("-" * 60)
        for row in cursor.fetchall():
            nullable = "NULL" if row[2] == 'YES' else "NOT NULL"
            print(f"  {row[0]:30} {row[1]:20} {nullable}")
        print("-" * 60)
        
    except psycopg2.Error as e:
        print(f"\n❌ Error de base de datos: {e}")
        if conn:
            conn.rollback()
        raise
        
    except Exception as e:
        print(f"\n❌ Error inesperado: {e}")
        if conn:
            conn.rollback()
        raise
        
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
            print("\n🔌 Conexión cerrada")


if __name__ == "__main__":
    print("=" * 60)
    print("  MIGRACIÓN: Agregar campos de ubicación GPS")
    print("=" * 60)
    print()
    
    try:
        migrate_add_location_fields()
        print("\n✅ Script completado sin errores")
        
    except Exception as e:
        print(f"\n💥 El script falló: {e}")
        exit(1)
