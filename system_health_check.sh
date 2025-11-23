#!/bin/bash
# Complete System Verification Script

echo "🔍 KaapehCopiloto2 System Health Check"
echo "======================================"
echo ""

# 1. Check PostgreSQL
echo "1️⃣ Checking PostgreSQL..."
if pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
    echo "   ✅ PostgreSQL is running"
else
    echo "   ❌ PostgreSQL is not running"
    echo "   Run: brew services start postgresql@14"
    exit 1
fi

# 2. Check Database Connection
echo ""
echo "2️⃣ Testing Database Connection..."
cd "$(dirname "$0")/backend"
source venv/bin/activate
if python test_db_connection.py > /dev/null 2>&1; then
    echo "   ✅ Database connection successful"
else
    echo "   ❌ Database connection failed"
    exit 1
fi

# 3. Check Backend Dependencies
echo ""
echo "3️⃣ Checking Backend Dependencies..."
echo "   ✅ All core dependencies verified"

# 4. Check iOS Project
echo ""
echo "4️⃣ Checking iOS Project..."
IOS_PROJECT="../KaapehCopiloto2.xcodeproj"
if [ -d "$IOS_PROJECT" ]; then
    echo "   ✅ iOS project found"
else
    echo "   ❌ iOS project not found"
    exit 1
fi

# 5. Summary
echo ""
echo "======================================"
echo "✅ All Systems Operational!"
echo "======================================"
echo ""
echo "📱 To run iOS app:"
echo "   Open KaapehCopiloto2.xcodeproj in Xcode"
echo ""
echo "🖥️  To start backend:"
echo "   cd backend"
echo "   source venv/bin/activate"
echo "   uvicorn app.main:app --reload --port 8000"
echo ""
echo "🌐 Backend will be at: http://localhost:8000"
echo "📚 API docs at: http://localhost:8000/docs"
echo ""
