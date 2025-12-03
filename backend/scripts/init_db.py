"""
Script para inicializar la base de datos PostgreSQL
Crea todas las tablas necesarias para Kaapeh Copiloto
"""

import sys
from pathlib import Path

# Agregar el directorio raíz al path (backend/)
# El script está en backend/scripts/
project_root = Path(__file__).resolve().parent.parent
sys.path.append(str(project_root))

from app.db.database import engine, Base, init_db
from app.models.models import User, DiagnosisRecord, AccessibilityConfig, ActionItem, AggregatedMetrics
from app.core.config import settings

def initialize_database():
    """
    Inicializa la base de datos creando todas las tablas
    """
    print("🔧 Inicializando base de datos PostgreSQL...")
    print(f"📦 Conectando a: {settings.DATABASE_URL.replace('kaapeh_pass', '****')}")
    
    try:
        # Verificar conexión
        connection = engine.connect()
        connection.close()
        print("✅ Conexión exitosa a PostgreSQL")
        
        # Crear todas las tablas
        Base.metadata.create_all(bind=engine)
        print("✅ Tablas creadas exitosamente:")
        print("   - users")
        print("   - accessibility_configs")
        print("   - diagnosis_records")
        print("   - action_items")
        print("   - aggregated_metrics")
        print("\n🚀 Base de datos PostgreSQL lista para usar!")
        
        return True
        
    except Exception as e:
        print(f"❌ Error al inicializar la base de datos: {e}")
        print("\n🔧 Solución de problemas:")
        print("1. Verifica que PostgreSQL esté corriendo:")
        print("   brew services start postgresql@15")
        print("2. Verifica que la base de datos exista:")
        print("   psql -U kaapeh_user -d kaapeh_copiloto_db")
        print("3. Si no existe, ejecuta:")
        print("   bash setup_postgres.sh")
        return False


if __name__ == "__main__":
    success = initialize_database()
    sys.exit(0 if success else 1)
