#!/bin/bash

echo "================================================================================"
echo "SETUP POSTGRESQL 16 - PROYECTO DE ANÁLISIS DE CRÉDITO"
echo "================================================================================"

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar si Homebrew está instalado
if ! command -v brew &> /dev/null; then
    echo -e "${RED}✗ Homebrew no está instalado${NC}"
    echo "Instala Homebrew desde: https://brew.sh"
    exit 1
fi

echo -e "${GREEN}✓ Homebrew instalado${NC}"

# Verificar PostgreSQL 16
echo ""
echo "Verificando PostgreSQL 16..."
if brew list postgresql@16 &>/dev/null; then
    echo -e "${GREEN}✓ PostgreSQL 16 ya está instalado${NC}"
else
    echo -e "${YELLOW}→ Instalando PostgreSQL 16...${NC}"
    brew install postgresql@16
fi

# Iniciar servicio
echo ""
echo "Iniciando servicio de PostgreSQL 16..."
brew services start postgresql@16
sleep 3

# Verificar si está corriendo
if brew services list | grep "postgresql@16" | grep "started" &>/dev/null; then
    echo -e "${GREEN}✓ PostgreSQL 16 está corriendo${NC}"
else
    echo -e "${RED}✗ PostgreSQL 16 no está corriendo${NC}"
    echo "Intenta manualmente: brew services start postgresql@16"
    exit 1
fi

# Crear usuario postgres si no existe
echo ""
echo "Verificando usuario postgres..."
if psql postgres -c "SELECT 1" &>/dev/null; then
    echo -e "${GREEN}✓ Usuario postgres existe${NC}"
else
    echo -e "${YELLOW}→ Creando usuario postgres...${NC}"
    createuser -s postgres 2>/dev/null || true
fi

# Instalar dependencias Python
echo ""
echo "Instalando dependencias de Python..."
if [ -d "venv" ]; then
    source venv/bin/activate
    echo -e "${YELLOW}→ Instalando psycopg2-binary...${NC}"
    pip install --upgrade pip setuptools wheel
    pip install psycopg2-binary || conda install -y psycopg2
    echo -e "${GREEN}✓ Dependencias instaladas${NC}"
else
    echo -e "${RED}✗ No se encontró venv. Crea uno con: python -m venv venv${NC}"
fi

echo ""
echo "================================================================================"
echo -e "${GREEN}✓ SETUP COMPLETO${NC}"
echo "================================================================================"
echo ""
echo "Próximos pasos:"
echo ""
echo "  1. Crear la base de datos:"
echo "     ${YELLOW}python create_database.py${NC}"
echo ""
echo "  2. Poblar con datos:"
echo "     ${YELLOW}python populate_data_db.py${NC}"
echo ""
echo "  3. Ejecutar ETL:"
echo "     ${YELLOW}python etl_from_db.py${NC}"
echo ""
echo "================================================================================"

