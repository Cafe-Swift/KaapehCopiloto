# Backend API - KaapehCopiloto2 🐍

[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-teal.svg)](https://fastapi.tiangolo.com/)
[![Python](https://img.shields.io/badge/Python-3.11+-green.svg)](https://www.python.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue.svg)](https://www.postgresql.org/)
[![SQLAlchemy](https://img.shields.io/badge/SQLAlchemy-2.0+-red.svg)](https://www.sqlalchemy.org/)

## 📋 Descripción

Backend API RESTful para la aplicación KaapehCopiloto2. Proporciona autenticación, sincronización de datos, gestión de usuarios y endpoints para métricas y reportes.

---

## 🏗️ Arquitectura

```
backend/
├── app/
│   ├── main.py                 # Punto de entrada FastAPI
│   ├── api/
│   │   └── v1/
│   │       ├── auth.py         # Endpoints de autenticación
│   │       ├── diagnosis.py    # Endpoints de diagnósticos
│   │       ├── sync.py         # Sincronización de datos
│   │       └── metrics.py      # Métricas y reportes
│   ├── core/
│   │   ├── config.py           # Configuración de la app
│   │   └── security.py         # JWT y seguridad
│   ├── crud/
│   │   └── crud.py             # Operaciones CRUD
│   ├── db/
│   │   └── database.py         # Configuración de PostgreSQL
│   ├── models/
│   │   └── models.py           # Modelos SQLAlchemy
│   └── schemas/
│       └── schemas.py          # Esquemas Pydantic
├── scripts/
│   ├── init_db.py              # Inicialización de base de datos
│   ├── setup_postgres.sh       # Setup automático de PostgreSQL
│   └── migrations/             # Migraciones de esquema
├── tests/
│   └── test_*.py               # Suite de tests
├── requirements.txt            # Dependencias Python
├── .env.example                # Template de variables de entorno
└── README.md                   # Este archivo
```

---

## 🚀 Inicio Rápido

### Prerrequisitos

- **Python** 3.11 o superior
- **PostgreSQL** 14 o superior
- **pip** y **virtualenv**
- **macOS** o **Linux** (recomendado para desarrollo)

### 1. Instalación

#### a) Clonar y Navegar

```bash
cd backend
```

#### b) Crear Entorno Virtual

```bash
python3 -m venv venv
source venv/bin/activate  # En macOS/Linux
# o
.\venv\Scripts\activate  # En Windows
```

#### c) Instalar Dependencias

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

---

### 2. Configuración de PostgreSQL

#### Opción A: Setup Automático (Recomendado)

```bash
chmod +x scripts/setup_postgres.sh
./scripts/setup_postgres.sh
```

Este script:
- ✅ Verifica instalación de PostgreSQL
- ✅ Crea la base de datos `kaapeh_db`
- ✅ Crea el usuario `kaapeh_user`
- ✅ Configura permisos

#### Opción B: Setup Manual

```bash
# Iniciar PostgreSQL
brew services start postgresql@14  # macOS con Homebrew

# Conectar a PostgreSQL
psql postgres

# Ejecutar comandos SQL
CREATE DATABASE kaapeh_db;
CREATE USER kaapeh_user WITH PASSWORD 'tu_password_seguro';
ALTER ROLE kaapeh_user SET client_encoding TO 'utf8';
ALTER ROLE kaapeh_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE kaapeh_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE kaapeh_db TO kaapeh_user;
\q
```

---

### 3. Configuración de Variables de Entorno

```bash
# Copiar el template
cp .env.example .env

# Editar con tus credenciales
nano .env  # o vim, code, etc.
```

#### Contenido de `.env`:

```bash
# Database
DATABASE_URL=postgresql://kaapeh_user:tu_password@localhost/kaapeh_db

# Security
SECRET_KEY=tu_clave_secreta_muy_larga_y_aleatoria_aqui
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# API
API_V1_STR=/api/v1
PROJECT_NAME=KaapehCopiloto2 Backend

# CORS
BACKEND_CORS_ORIGINS=["http://localhost:3000","http://localhost:8000"]

# Environment
ENVIRONMENT=development
DEBUG=True
```

#### 🔐 Generar SECRET_KEY Seguro:

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

---

### 4. Inicializar Base de Datos

```bash
python scripts/init_db.py
```

Este script:
- ✅ Crea todas las tablas
- ✅ Verifica la conexión
- ✅ Crea datos de prueba (opcional)

---

### 5. Ejecutar el Servidor

#### Modo Desarrollo (con hot-reload):

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### Modo Producción:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

**🎉 El servidor estará disponible en:**
- API: http://localhost:8000
- Docs interactiva: http://localhost:8000/docs
- Docs alternativa: http://localhost:8000/redoc

---

## 📚 Documentación de la API

### Autenticación

#### POST `/api/v1/auth/register`
Registrar un nuevo usuario.

**Request Body:**
```json
{
  "username": "productor1",
  "email": "productor@example.com",
  "password": "password123",
  "role": "Productor"
}
```

**Response:**
```json
{
  "id": 1,
  "username": "productor1",
  "email": "productor@example.com",
  "role": "Productor",
  "created_at": "2025-12-05T10:30:00Z"
}
```

---

#### POST `/api/v1/auth/login`
Iniciar sesión y obtener token JWT.

**Request Body:**
```json
{
  "username": "productor1",
  "password": "password123"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "username": "productor1",
    "role": "Productor"
  }
}
```

---

### Diagnósticos

#### POST `/api/v1/sync`
Sincronizar diagnósticos desde el dispositivo.

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "diagnoses": [
    {
      "id": "uuid-local",
      "detected_issue": "Roya del café",
      "confidence": 0.92,
      "timestamp": "2025-12-05T10:30:00Z",
      "image_data": null,
      "user_feedback_correct": true
    }
  ]
}
```

**Response:**
```json
{
  "synced_count": 1,
  "failed_count": 0,
  "message": "Diagnósticos sincronizados exitosamente"
}
```

---

#### GET `/api/v1/diagnosis/history`
Obtener historial de diagnósticos del usuario.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` (optional): Número máximo de resultados (default: 50)
- `offset` (optional): Offset para paginación (default: 0)

**Response:**
```json
{
  "total": 150,
  "items": [
    {
      "id": 1,
      "detected_issue": "Roya del café",
      "confidence": 0.92,
      "timestamp": "2025-12-05T10:30:00Z",
      "user_feedback_correct": true
    }
  ]
}
```

---

### Métricas (Solo Técnicos)

#### GET `/api/v1/metrics`
Obtener métricas agregadas del sistema.

**Headers:**
```
Authorization: Bearer <token_tecnico>
```

**Response:**
```json
{
  "total_diagnoses": 1523,
  "tpp": 0.87,
  "cpm": 0.89,
  "issues_distribution": {
    "Roya del café": 543,
    "Broca del café": 321,
    "Deficiencia de nitrógeno": 289
  },
  "period": "last_30_days"
}
```

---

## 🗄️ Esquema de Base de Datos

### Tabla: `users`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | INTEGER | Primary Key |
| `username` | VARCHAR(50) | Único, no nulo |
| `email` | VARCHAR(100) | Único, no nulo |
| `hashed_password` | VARCHAR(255) | Hash bcrypt |
| `role` | VARCHAR(20) | "Productor" o "Técnico" |
| `created_at` | TIMESTAMP | Fecha de creación |
| `is_active` | BOOLEAN | Usuario activo |

### Tabla: `diagnoses`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | INTEGER | Primary Key |
| `user_id` | INTEGER | Foreign Key → users |
| `detected_issue` | VARCHAR(255) | Enfermedad detectada |
| `confidence` | FLOAT | Nivel de confianza (0-1) |
| `timestamp` | TIMESTAMP | Fecha del diagnóstico |
| `image_path` | VARCHAR(500) | Path de la imagen (opcional) |
| `user_feedback_correct` | BOOLEAN | Feedback del usuario |
| `location_lat` | FLOAT | Latitud (opcional) |
| `location_lon` | FLOAT | Longitud (opcional) |
| `is_synced` | BOOLEAN | Estado de sincronización |

### Tabla: `action_items`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | INTEGER | Primary Key |
| `diagnosis_id` | INTEGER | Foreign Key → diagnoses |
| `task_description` | TEXT | Descripción de la tarea |
| `is_completed` | BOOLEAN | Estado de la tarea |
| `due_date` | DATE | Fecha límite (opcional) |

---

## 🧪 Tests

### Ejecutar Tests

```bash
# Instalar dependencias de testing
pip install pytest pytest-asyncio httpx

# Ejecutar todos los tests
pytest

# Con cobertura
pytest --cov=app tests/

# Tests específicos
pytest tests/test_auth.py -v

# Con output detallado
pytest -vv
```

### Estructura de Tests

```
tests/
├── test_auth.py          # Tests de autenticación
├── test_diagnosis.py     # Tests de diagnósticos
├── test_sync.py          # Tests de sincronización
├── test_metrics.py       # Tests de métricas
└── conftest.py           # Fixtures compartidos
```

---

## 🔧 Migraciones de Base de Datos

### Crear una Nueva Migración

```bash
# 1. Crear archivo de migración
cd scripts/migrations
touch migrate_add_new_field.py

# 2. Implementar la migración
# Ver ejemplos en: scripts/migrations/migrate_add_*.py

# 3. Ejecutar la migración
python scripts/migrations/migrate_add_new_field.py
```

### Ejemplo de Migración:

```python
# scripts/migrations/migrate_add_new_field.py
from app.db.database import engine
from sqlalchemy import text

def upgrade():
    with engine.connect() as conn:
        conn.execute(text("""
            ALTER TABLE diagnoses 
            ADD COLUMN severity VARCHAR(20) DEFAULT 'medium'
        """))
        conn.commit()
    print("✅ Migration applied successfully")

def downgrade():
    with engine.connect() as conn:
        conn.execute(text("""
            ALTER TABLE diagnoses 
            DROP COLUMN severity
        """))
        conn.commit()
    print("✅ Migration rolled back successfully")

if __name__ == "__main__":
    upgrade()
```

---

## 🐳 Docker (Opcional)

### Crear Dockerfile:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Docker Compose:

```yaml
version: '3.8'

services:
  db:
    image: postgres:14
    environment:
      POSTGRES_DB: kaapeh_db
      POSTGRES_USER: kaapeh_user
      POSTGRES_PASSWORD: your_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  api:
    build: .
    ports:
      - "8000:8000"
    depends_on:
      - db
    environment:
      DATABASE_URL: postgresql://kaapeh_user:your_password@db/kaapeh_db

volumes:
  postgres_data:
```

### Ejecutar con Docker:

```bash
docker-compose up -d
```

---

## 🚀 Despliegue a Producción

### Checklist Pre-Despliegue

- [ ] Cambiar `DEBUG=False` en `.env`
- [ ] Usar `SECRET_KEY` fuerte y único
- [ ] Configurar HTTPS/SSL
- [ ] Configurar CORS correctamente
- [ ] Usar PostgreSQL en servidor dedicado
- [ ] Configurar backups automáticos
- [ ] Implementar rate limiting
- [ ] Configurar logging a archivo
- [ ] Usar gunicorn o uvicorn con múltiples workers

### Ejemplo de Despliegue (Ubuntu):

```bash
# 1. Instalar dependencias del sistema
sudo apt update
sudo apt install python3.11 python3-pip postgresql nginx

# 2. Configurar PostgreSQL
sudo -u postgres psql < scripts/setup_database.sql

# 3. Clonar y configurar
git clone <repo>
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 4. Configurar systemd service
sudo nano /etc/systemd/system/kaapeh-api.service

# 5. Iniciar servicio
sudo systemctl start kaapeh-api
sudo systemctl enable kaapeh-api

# 6. Configurar Nginx como reverse proxy
sudo nano /etc/nginx/sites-available/kaapeh-api
sudo ln -s /etc/nginx/sites-available/kaapeh-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## 🔐 Seguridad

### Mejores Prácticas Implementadas

✅ **Passwords**: Hash con bcrypt (12 rounds)  
✅ **JWT**: Tokens con expiración configurable  
✅ **SQL Injection**: Protección vía SQLAlchemy ORM  
✅ **CORS**: Configurado solo para orígenes permitidos  
✅ **Rate Limiting**: Implementado en endpoints críticos  
✅ **HTTPS**: Requerido en producción  
✅ **Secrets**: Variables de entorno, nunca en código  

### Auditoría de Seguridad

```bash
# Escanear dependencias vulnerables
pip install safety
safety check

# Análisis estático de código
pip install bandit
bandit -r app/
```

---

## 📊 Monitoreo y Logging

### Configurar Logging

```python
# app/main.py
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('app.log'),
        logging.StreamHandler()
    ]
)
```

### Métricas con Prometheus (Opcional):

```bash
pip install prometheus-fastapi-instrumentator
```

---

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una rama (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Estándares de Código

- Seguir **PEP 8**
- Usar **type hints**
- Documentar funciones con **docstrings**
- Tests con cobertura > 80%
- Usar **Black** para formateo

```bash
# Formatear código
black app/

# Linting
flake8 app/

# Type checking
mypy app/
```

---

## 📞 Soporte

- 🐛 Issues: [GitHub Issues](https://github.com/tu-usuario/KaapehCopiloto2/issues)
- 📧 Email: backend@kaapeh.com

---

## 📄 Licencia

MIT License - Ver [LICENSE](../LICENSE)

---

**🐍 Backend construido con FastAPI y ❤️**
