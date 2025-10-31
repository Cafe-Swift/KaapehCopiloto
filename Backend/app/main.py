# Aplicación principal FastAPI para Káapeh Copiloto Backend

from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from datetime import datetime

from app.core.config import settings
from app.db.database import get_db, engine, Base
from app.api.v1.endpoints import metrics, sync
from app.schemas.schemas import HealthResponse 

# Crear las tablas en la base de datos
Base.metadata.create_all(bind=engine)

# Inicializar la aplicación FastAPI
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="API backend para Káapeh Copiloto - Sistema de diagnóstico agrícola con IA",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configurar CORS para permitir conexiones desde la app iOS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especificar dominios exactos
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Incluir routers de los endpoints
app.include_router(
    metrics.router,
    prefix=f"{settings.API_V1_PREFIX}/metrics",
    tags=["Métricas"]
)

app.include_router(
    sync.router,
    prefix=f"{settings.API_V1_PREFIX}/sync",
    tags=["Sincronización"]
)

@app.get("/", response_model=dict)
async def root():
    """
    Endpoint raíz de bienvenida
    """
    return {
        "message": "Káapeh Copiloto API",
        "version": settings.VERSION,
        "docs": "/docs",
        "status": "online"
    }

@app.get("/health", response_model=HealthResponse, tags= ["Sistema"])
async def health_check(db: Session = Depends(get_db)):
    """
    Health check endpoint para verificar el estado del servicio.

    Verifica: 
    - Estado del servidor
    - Conexión a la base de datos
    """
    database_connected = False

    try:
        # Intentar hacer una query simple para verificar la conexion 
        db.execute("SELECT 1")
        database_connected = True
    except Exception as e:
        print(f"Database connection error: {e}")

    return HealthResponse(
        status="healthy" if database_connected else "degraded",
        version=settings.VERSION,
        timestamp=datetime.utcnow(),
        database_connected=database_connected
    )

@app.on_event("startup")
async def startup_event():
    """
    Evento ejecutado al iniciar la aplicación.
    """

    print(f"🚀 {settings.PROJECT_NAME} v{settings.VERSION} iniciado")
    print(f"📚 Documentación disponible en: /docs")

@app.on_event("shutdown")
async def shutdown_event():
    """
    Evento ejecutado al apagar la aplicación.
    """
    print(f"👋 {settings.PROJECT_NAME} detenido")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )