# Backend Káapeh Copiloto - PostgreSQL Setup

## 🗄️ Configuración de PostgreSQL

Este proyecto **requiere PostgreSQL** como base de datos. Sigue estos pasos para configurar todo correctamente.

---

## 📋 Prerequisitos

1. **PostgreSQL 15+** instalado
2. **Python 3.12** (recomendado para compatibilidad)
3. **Homebrew** (para macOS)

---

## 🚀 Instalación Rápida

### Paso 1: Instalar PostgreSQL

```bash
# Instalar PostgreSQL con Homebrew
brew install postgresql@15

# Iniciar el servicio de PostgreSQL
brew services start postgresql@15

# Verificar que está corriendo
pg_isready
```

### Paso 2: Configurar Base de Datos

```bash
# Opción A: Usar el script automático (RECOMENDADO)
cd backend
bash setup_postgres.sh

# Opción B: Configuración manual
psql postgres
```

Si usas la opción B (manual), ejecuta estos comandos SQL:

```sql
-- Crear usuario
CREATE USER kaapeh_user WITH PASSWORD 'kaapeh_pass';

-- Crear base de datos
CREATE DATABASE kaapeh_copiloto_db OWNER kaapeh_user;

-- Dar permisos
GRANT ALL PRIVILEGES ON DATABASE kaapeh_copiloto_db TO kaapeh_user;

-- Verificar
\l
\q
```

### Paso 3: Configurar Python 3.12

```bash
# Verificar versión de Python
python3.12 --version

# Si no está instalado:
brew install python@3.12
```

### Paso 4: Instalar Dependencias Python

```bash
# Desde el directorio backend
cd backend

# Crear entorno virtual con Python 3.12
python3.12 -m venv venv

# Activar entorno virtual
source venv/bin/activate

# Actualizar pip
pip install --upgrade pip

# Instalar dependencias
pip install -r requirements.txt
```

### Paso 5: Inicializar Tablas de Base de Datos

```bash
# Asegúrate de estar en el directorio backend con el venv activado
python init_db.py
```

Deberías ver:
```
🔧 Inicializando base de datos PostgreSQL...
📦 Conectando a: postgresql://kaapeh_user:****@localhost:5432/kaapeh_copiloto_db
✅ Tablas creadas exitosamente:
   - users
   - diagnosis_data
   - aggregated_metrics

🚀 Base de datos lista para usar!
```

### Paso 6: Ejecutar el Backend

```bash
# Con el venv activado
python -m uvicorn app.main:app --reload
```

Deberías ver:
```
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

---

## 🔍 Verificar Instalación

### 1. API Funcionando

Abre en tu navegador:
- **Docs interactivos**: http://127.0.0.1:8000/docs
- **ReDoc**: http://127.0.0.1:8000/redoc
- **Health check**: http://127.0.0.1:8000/api/v1/health

### 2. Base de Datos Conectada

```bash
# Conectarse a la base de datos
psql -U kaapeh_user -d kaapeh_copiloto_db

# Ver tablas creadas
\dt

# Salir
\q
```

---

## 🔧 Configuración Adicional

### Variables de Entorno

El archivo `.env` ya está configurado con valores por defecto:

```env
DATABASE_URL=postgresql://kaapeh_user:kaapeh_pass@localhost:5432/kaapeh_copiloto_db
SECRET_KEY=kaapeh-copiloto-development-secret-key-change-in-production
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

Para producción, **cambia estos valores** por seguridad.

### Conexión desde la App iOS

La app iOS se conecta al backend en:
- **Desarrollo (Simulador)**: `http://127.0.0.1:8000`
- **Desarrollo (Dispositivo físico)**: `http://TU_IP_LOCAL:8000`

Para encontrar tu IP local:
```bash
ipconfig getifaddr en0
```

---

## 📊 Estructura de Base de Datos

### Tabla: `users`
- `id` (UUID, Primary Key)
- `phone_number` (String, Unique)
- `role` (String: "Productor" o "Técnico")
- `hashed_password` (String)
- `created_at` (Timestamp)
- `is_active` (Boolean)

### Tabla: `diagnosis_data`
- `id` (UUID, Primary Key)
- `user_id` (UUID, Foreign Key)
- `timestamp` (Timestamp)
- `detected_issue` (String)
- `confidence` (Float)
- `user_feedback_correct` (Boolean, nullable)
- `latitude` (Float, nullable)
- `longitude` (Float, nullable)

### Tabla: `aggregated_metrics`
- `id` (UUID, Primary Key)
- `metric_date` (Date)
- `total_diagnoses` (Integer)
- `tpp_percentage` (Float)
- `cpm_average` (Float)
- `roya_count` (Integer)
- `nitrogen_deficiency_count` (Integer)
- `healthy_count` (Integer)
- `updated_at` (Timestamp)

---

## 🐛 Solución de Problemas

### Error: "psql: command not found"

PostgreSQL no está instalado o no está en el PATH:
```bash
brew install postgresql@15
brew link postgresql@15
```

### Error: "could not connect to server"

El servicio PostgreSQL no está corriendo:
```bash
brew services start postgresql@15
# o
pg_ctl -D /usr/local/var/postgresql@15 start
```

### Error: "psycopg2 installation failed"

Usar Python 3.12 en lugar de 3.14:
```bash
# Eliminar venv existente
rm -rf venv

# Crear nuevo con Python 3.12
python3.12 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Error: "FATAL: password authentication failed"

Verificar credenciales en `.env` y recrear usuario:
```bash
psql postgres
DROP USER IF EXISTS kaapeh_user;
CREATE USER kaapeh_user WITH PASSWORD 'kaapeh_pass';
GRANT ALL PRIVILEGES ON DATABASE kaapeh_copiloto_db TO kaapeh_user;
```

### Error: "relation does not exist"

Las tablas no fueron creadas:
```bash
python init_db.py
```

---

## 🧹 Comandos Útiles

### Reiniciar Base de Datos Completa

```bash
# Opción 1: Usar el script
bash setup_postgres.sh

# Opción 2: Manual
psql postgres << EOF
DROP DATABASE IF EXISTS kaapeh_copiloto_db;
CREATE DATABASE kaapeh_copiloto_db OWNER kaapeh_user;
GRANT ALL PRIVILEGES ON DATABASE kaapeh_copiloto_db TO kaapeh_user;
EOF

# Recrear tablas
python init_db.py
```

### Ver Logs de PostgreSQL

```bash
tail -f /usr/local/var/log/postgresql@15.log
```

### Backup de Base de Datos

```bash
pg_dump -U kaapeh_user kaapeh_copiloto_db > backup.sql
```

### Restaurar Backup

```bash
psql -U kaapeh_user kaapeh_copiloto_db < backup.sql
```

---

## 📚 Recursos Adicionales

- [Documentación PostgreSQL](https://www.postgresql.org/docs/)
- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [SQLAlchemy ORM](https://docs.sqlalchemy.org/)
- [psycopg2 Docs](https://www.psycopg.org/docs/)

---

## ✅ Checklist de Configuración

- [ ] PostgreSQL 15+ instalado
- [ ] Servicio PostgreSQL corriendo
- [ ] Base de datos `kaapeh_copiloto_db` creada
- [ ] Usuario `kaapeh_user` creado con permisos
- [ ] Python 3.12 instalado
- [ ] Entorno virtual creado y activado
- [ ] Dependencias instaladas (`pip install -r requirements.txt`)
- [ ] Tablas de base de datos inicializadas (`python init_db.py`)
- [ ] Backend ejecutándose sin errores
- [ ] Docs API accesibles en http://127.0.0.1:8000/docs

---

## 🎯 Próximos Pasos

Una vez configurado el backend:

1. **Abrir Xcode** y ejecutar la app iOS
2. **Registrar usuario** en la app
3. **Verificar** que los datos se guarden en PostgreSQL:
   ```bash
   psql -U kaapeh_user -d kaapeh_copiloto_db
   SELECT * FROM users;
   ```
4. **Probar endpoints** desde la app iOS

---

**¡Listo! Tu backend con PostgreSQL está configurado correctamente.** 🚀
