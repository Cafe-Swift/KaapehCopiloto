#!/bin/bash
# Script para inicializar la base de datos con el entorno virtual correcto

echo "🔧 Inicializando base de datos PostgreSQL para Káapeh Copiloto..."
echo ""

# Obtener el directorio del script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar que existe el entorno virtual
if [ ! -d "venv" ]; then
    echo -e "${RED}❌ No se encontró el entorno virtual 'venv'${NC}"
    echo -e "${YELLOW}Ejecuta primero:${NC}"
    echo "  python3.12 -m venv venv"
    echo "  source venv/bin/activate"
    echo "  pip install -r requirements.txt"
    exit 1
fi

# Activar entorno virtual
echo -e "${YELLOW}📦 Activando entorno virtual...${NC}"
source venv/bin/activate

# Verificar que SQLAlchemy está instalado
if ! python -c "import sqlalchemy" 2>/dev/null; then
    echo -e "${RED}❌ SQLAlchemy no está instalado en el entorno virtual${NC}"
    echo -e "${YELLOW}Instalando dependencias...${NC}"
    pip install -r requirements.txt
fi

# Verificar PostgreSQL
echo -e "${YELLOW}🔍 Verificando PostgreSQL...${NC}"
if ! pg_isready &> /dev/null; then
    echo -e "${RED}❌ PostgreSQL no está corriendo${NC}"
    echo -e "${YELLOW}Iniciando PostgreSQL...${NC}"
    brew services start postgresql@15 || brew services start postgresql
    sleep 3
    
    if ! pg_isready &> /dev/null; then
        echo -e "${RED}❌ No se pudo iniciar PostgreSQL${NC}"
        echo -e "${YELLOW}Instala PostgreSQL con: brew install postgresql@15${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ PostgreSQL está corriendo${NC}"
echo ""

# Verificar que la base de datos existe
echo -e "${YELLOW}🔍 Verificando base de datos...${NC}"
if ! psql -U kaapeh_user -d kaapeh_copiloto_db -c '\q' 2>/dev/null; then
    echo -e "${YELLOW}⚠️  La base de datos no existe. Ejecutando setup...${NC}"
    bash setup_postgres.sh
fi

echo ""
echo -e "${GREEN}🚀 Ejecutando script de inicialización...${NC}"
echo ""

# Ejecutar el script de Python con el entorno virtual
python init_db.py

exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Inicialización completada exitosamente${NC}"
else
    echo ""
    echo -e "${RED}❌ Error en la inicialización (código: $exit_code)${NC}"
fi

exit $exit_code
