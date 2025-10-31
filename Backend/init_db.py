# script para inicializar la base de datos con datos de ejemplo

from sqlalchemy.orm import Session
from app.db.database import SessionLocal, engine
from app.models.models import Base, AggregatedMetrics, AnonymousUsageData, TechnicianUser, DiagnosisFrequency
from datetime import datetime, timedelta
import random

def init_db():
    # Inicializar la base de datos con datos de ejemplo
    # Crear todas las tablas
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()

    try: 
        # Verificar si ya hay datos
        existing_data = db.query(AnonymousUsageData).first()
        if existing_data: 
            print("✅ La base de datos ya contiene datos")
            return
        
        print("📊 Inicializando base de datos con datos de ejemplo...")

        # Crear técnico de ejemplo
        technician = TechnicianUser(
            user_name="Juan ",
            full_name="Juan Pérez - Técnico Káapeh",
        )
        db.add(technician)

        # Crear datos de uso anónimos de ejemplo
        issues = ["Roya", "Sano", "Deficiencia de Nitrógeno"]

        for i in range(50):
            days_ago = random.randint(0, 30)
            issue = random.choice(issues)
            confidence = random.uniform(0.75, 0.98)
            feedback_correct = random.choice([True, True, True, False])  # 75% correcto

            usage = AnonymousUsageData( 
                user_role="Productor",
                diagnosis_issue=issue,
                diagnosis_confidence=confidence,
                user_feedback_correct=feedback_correct,
                action_items_completed=random.randint(0, 5),
                action_items_total=random.randint(3, 8),
                session_duration=random.randint(60, 600),
                created_at=datetime.utcnow() - timedelta(days=days_ago)
            )
            db.add(usage)

        # Crear frecuencias de diagnóstico
        for issue in issues:
            count = random.randint(10, 30)
            freq = DiagnosisFrequency(
                issue_type=issue,
                count=count,
                period_start=datetime.utcnow() - timedelta(days=30),
                period_end=datetime.utcnow()
            )
            db.add(freq)

        # Crear métricas agregadas
        metrics_data = [
            {"metric_type": "TPP", "metric_value": 92.5},
            {"metric_type": "NAS", "metric_value": 68.3},
            {"metric_type": "CPM", "metric_value": 87.8}
        ]

        for metric_data in metrics_data:
            metric = AggregatedMetrics(
                metric_type=metric_data["metric_type"],
                metric_value=metric_data["metric_value"],
                period_start=datetime.utcnow() - timedelta(days=7),
                period_end=datetime.utcnow()
            )
            db.add(metric)

        db.commit()
        print ("✅ Base de datos inicializada con datos de ejemplo")

    except Exception as e:
        print(f"❌ Error al inicializar la base de datos: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    init_db()
