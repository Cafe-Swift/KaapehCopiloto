#!/bin/bash
# Script para configurar PostgreSQL para Kaapeh Copiloto
# Ejecutar con: bash setup_postgres.sh

echo "🔧 Configurando PostgreSQL para Kaapeh Copiloto..."

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar si PostgreSQL está instalado
if ! command -v psql &> /dev/null; then
    echo -e "${RED}❌ PostgreSQL no está instalado.${NC}"
    echo -e "${YELLOW}Por favor instala PostgreSQL con:${NC}"
    echo "  brew install postgresql@15"
    echo "  brew services start postgresql@15"
    exit 1
fi

echo -e "${GREEN}✅ PostgreSQL encontrado${NC}"

# Verificar si el servicio está corriendo
if ! pg_isready &> /dev/null; then
    echo -e "${YELLOW}⚠️  PostgreSQL no está corriendo. Intentando iniciar...${NC}"
    brew services start postgresql@15 || brew services start postgresql
    sleep 3
fi

# Crear usuario y base de datos
echo -e "${YELLOW}📦 Creando base de datos y usuario...${NC}"

psql postgres << EOF
-- Eliminar si existe (para desarrollo)
DROP DATABASE IF EXISTS kaapeh_copiloto_db;
DROP USER IF EXISTS kaapeh_user;

-- Crear usuario
CREATE USER kaapeh_user WITH PASSWORD 'kaapeh_pass';

-- Crear base de datos
CREATE DATABASE kaapeh_copiloto_db OWNER kaapeh_user;

-- Dar permisos
GRANT ALL PRIVILEGES ON DATABASE kaapeh_copiloto_db TO kaapeh_user;

-- Confirmar
\l
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Base de datos 'kaapeh_copiloto_db' creada exitosamente${NC}"
    echo -e "${GREEN}✅ Usuario 'kaapeh_user' creado exitosamente${NC}"
    echo ""
    echo -e "${YELLOW}📝 Información de conexión:${NC}"
    echo "  Host: localhost"
    echo "  Puerto: 5432"
    echo "  Base de datos: kaapeh_copiloto_db"
    echo "  Usuario: kaapeh_user"
    echo "  Contraseña: kaapeh_pass"
    echo ""
    echo -e "${GREEN}🚀 Ahora puedes ejecutar el backend con:${NC}"
    echo "  cd backend"
    echo "  python3.12 -m venv venv"
    echo "  source venv/bin/activate"
    echo "  pip install -r requirements.txt"
    echo "  python -m uvicorn app.main:app --reload"
else
    echo -e "${RED}❌ Error al crear la base de datos${NC}"
    exit 1
fi
