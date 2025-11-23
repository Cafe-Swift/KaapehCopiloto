#!/usr/bin/env python3
"""
Script to test database connection before running migrations
"""
import sys
from sqlalchemy import create_engine, text
from app.core.config import settings

def test_connection():
    """Test PostgreSQL connection"""
    print("🔍 Testing database connection...")
    print(f"   Database URL: {settings.DATABASE_URL}")
    
    try:
        engine = create_engine(settings.DATABASE_URL)
        with engine.connect() as conn:
            result = conn.execute(text("SELECT version();"))
            version = result.fetchone()[0]
            print(f"✅ Connection successful!")
            print(f"   PostgreSQL version: {version.split(',')[0]}")
            
            # Check if database exists
            result = conn.execute(text("SELECT current_database();"))
            db_name = result.fetchone()[0]
            print(f"   Connected to database: {db_name}")
            
            return True
    except Exception as e:
        print(f"❌ Connection failed: {str(e)}")
        return False

if __name__ == "__main__":
    success = test_connection()
    sys.exit(0 if success else 1)
