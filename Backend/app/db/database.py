# configuracion de la base de datos PostgreSQL

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

from app.core.config import settings
# Crear el engine de SQLAlchemy
engine = create_engine(settings.DATABASE_URL, pool_pre_ping=True)

# crear sesionlocal class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# base class para los modelos
Base = declarative_base()

# dependencia para obtener la sesión de la db 
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()