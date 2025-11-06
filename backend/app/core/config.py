"""
Application configuration settings
"""

from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """
    Application settings with environment variable support
    """
    # Database Configuration - PostgreSQL
    DATABASE_URL: str = "postgresql://kaapeh_user:kaapeh_pass@localhost:5432/kaapeh_copiloto_db"
    
    # Security
    SECRET_KEY: str = "kaapeh-copiloto-secret-key-change-in-production-2024"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # API Configuration
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Káapeh Copiloto API"
    VERSION: str = "1.0.0"
    
    # CORS
    BACKEND_CORS_ORIGINS: list = ["*"] # Allow all origins for development; restrict in production
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# Create settings instance
settings = Settings()
