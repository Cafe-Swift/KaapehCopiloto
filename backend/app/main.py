"""
Main FastAPI application
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime

from app.core.config import settings
from app.db.database import init_db
from app.api.v1.endpoints import auth, sync, metrics
from app.schemas.schemas import HealthResponse

# Initialize FastAPI app
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="API Backend for Kaapeh Copiloto - Sprint 1"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["Authentication"])
app.include_router(sync.router, prefix=f"{settings.API_V1_STR}", tags=["Sync"])
app.include_router(metrics.router, prefix=f"{settings.API_V1_STR}", tags=["Metrics"])


@app.on_event("startup")
async def startup_event():
    """
    Initialize database on startup
    """
    init_db()
    print(f"🚀 {settings.PROJECT_NAME} v{settings.VERSION} started")
    print(f"📚 Documentation available at http://localhost:8000/docs")


@app.get("/", tags=["Root"])
async def root():
    """
    Root endpoint
    """
    return {
        "message": "Kaapeh Copiloto API",
        "version": settings.VERSION,
        "docs": "/docs"
    }


@app.get(f"{settings.API_V1_STR}/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    """
    Health check endpoint
    """
    return HealthResponse(
        status="healthy",
        version=settings.VERSION,
        timestamp=datetime.utcnow()
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
