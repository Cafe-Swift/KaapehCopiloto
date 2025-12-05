# Guía de Migraciones - Backend KaapehCopiloto2

## 📋 Resumen

Este documento detalla todas las migraciones disponibles en el proyecto y cómo ejecutarlas.

---

## 🗂️ Migraciones Disponibles

### 1. migrate_add_device_fields.py ✅

**Tabla afectada**: `users`

**Campos agregados**:
- `display_name` (VARCHAR) - Nombre para mostrar del usuario
- `device_id` (VARCHAR) - Identificador único del dispositivo iOS

**Cuándo ejecutar**: Después de la instalación inicial de la base de datos

**Comando**:
```bash
python scripts/migrations/migrate_add_device_fields.py
```

**Salida esperada**:
```
🔄 Iniciando migración...
📊 Columnas existentes: ['id', 'username', 'email', ...]
➕ Agregando columna 'display_name'...
✅ Columna 'display_name' agregada
➕ Agregando columna 'device_id'...
✅ Columna 'device_id' agregada
✅ Migración completada exitosamente
```

---

### 2. migrate_add_location_fields.py 🗺️

**Tabla afectada**: `diagnosis_records`

**Campos agregados**:
- `latitude` (FLOAT) - Latitud GPS del diagnóstico
- `longitude` (FLOAT) - Longitud GPS del diagnóstico
- `location_name` (VARCHAR) - Nombre legible de la ubicación

**Cuándo ejecutar**: Cuando se implementa geolocalización en diagnósticos

**Comando**:
```bash
python scripts/migrations/migrate_add_location_fields.py
```

**Salida esperada**:
```
Conectando a la base de datos...
✅ Conexión exitosa
📊 Columnas existentes: []
🔄 Iniciando migración...
➕ Agregando columna 'latitude'...
➕ Agregando columna 'longitude'...
➕ Agregando columna 'location_name'...
✅ Migración completada exitosamente
```

---

### 3. migrate_add_task_fields.py 📝

**Tabla afectada**: `action_items`

**Campos agregados**:
- `priority` (VARCHAR) - Prioridad: Alta, Media, Baja (DEFAULT: 'Media')
- `due_date` (TIMESTAMP) - Fecha límite de la tarea
- `reminder_date` (TIMESTAMP) - Fecha de recordatorio
- `category` (VARCHAR) - Categoría de la tarea
- `completed_at` (TIMESTAMP) - Fecha de completado

**Cuándo ejecutar**: Cuando se implementan tareas avanzadas con prioridades

**Comando**:
```bash
python scripts/migrations/migrate_add_task_fields.py
```

**Salida esperada**:
```
🔄 Starting migration: Add priority and date fields to action_items...
✅ Added column: priority
✅ Added column: due_date
✅ Added column: reminder_date
✅ Added column: category
✅ Added column: completed_at
✅ Migración completada exitosamente
```

---

## 🚀 Ejecutar Todas las Migraciones

### Método 1: Manual (Recomendado para primera vez)

```bash
# Desde el directorio backend/
cd backend

# Activar entorno virtual
source venv/bin/activate

# Ejecutar en orden
python scripts/migrations/migrate_add_device_fields.py
python scripts/migrations/migrate_add_location_fields.py
python scripts/migrations/migrate_add_task_fields.py
```

### Método 2: Script Automatizado

Crea un archivo `scripts/run_all_migrations.sh`:

```bash
#!/bin/bash
# scripts/run_all_migrations.sh

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Ejecutando todas las migraciones de KaapehCopiloto2"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -d "scripts/migrations" ]; then
    echo "❌ Error: Debes ejecutar este script desde el directorio backend/"
    exit 1
fi

# Verificar que el entorno virtual está activado
if [ -z "$VIRTUAL_ENV" ]; then
    echo "⚠️  Advertencia: El entorno virtual no está activado"
    echo "   Ejecuta: source venv/bin/activate"
    exit 1
fi

# Migración 1: Device Fields
echo "1️⃣  Ejecutando: migrate_add_device_fields.py"
echo "─────────────────────────────────────────────────"
python scripts/migrations/migrate_add_device_fields.py
if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Error en migrate_add_device_fields.py"
    exit 1
fi
echo ""

# Migración 2: Location Fields
echo "2️⃣  Ejecutando: migrate_add_location_fields.py"
echo "─────────────────────────────────────────────────"
python scripts/migrations/migrate_add_location_fields.py
if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Error en migrate_add_location_fields.py"
    exit 1
fi
echo ""

# Migración 3: Task Fields
echo "3️⃣  Ejecutando: migrate_add_task_fields.py"
echo "─────────────────────────────────────────────────"
python scripts/migrations/migrate_add_task_fields.py
if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Error en migrate_add_task_fields.py"
    exit 1
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Todas las migraciones completadas exitosamente"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

Hacerlo ejecutable y correr:

```bash
chmod +x scripts/run_all_migrations.sh
./scripts/run_all_migrations.sh
```

---

## 🔍 Verificar Migraciones

### Método 1: PostgreSQL CLI

```bash
# Conectar a la base de datos
psql -U kaapeh_user -d kaapeh_db

# Ver estructura de users
\d users

# Ver estructura de diagnosis_records
\d diagnosis_records

# Ver estructura de action_items
\d action_items

# Salir
\q
```

### Método 2: SQL Queries

```sql
-- Verificar columnas de users
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Verificar columnas de diagnosis_records
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'diagnosis_records'
ORDER BY ordinal_position;

-- Verificar columnas de action_items
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'action_items'
ORDER BY ordinal_position;
```

### Método 3: Script Python

```python
# scripts/verify_migrations.py
"""
Verifica que todas las migraciones se hayan ejecutado correctamente
"""
from sqlalchemy import text
from app.db.database import engine

def verify_migrations():
    """Verifica todas las columnas agregadas por migraciones"""
    
    print("🔍 Verificando migraciones...")
    print("")
    
    with engine.connect() as conn:
        # Verificar users
        print("1️⃣  Tabla: users")
        result = conn.execute(text("""
            SELECT column_name FROM information_schema.columns 
            WHERE table_name = 'users' 
            AND column_name IN ('display_name', 'device_id')
        """))
        users_cols = [row[0] for row in result]
        print(f"   ✓ display_name: {'✅' if 'display_name' in users_cols else '❌'}")
        print(f"   ✓ device_id: {'✅' if 'device_id' in users_cols else '❌'}")
        print("")
        
        # Verificar diagnosis_records
        print("2️⃣  Tabla: diagnosis_records")
        result = conn.execute(text("""
            SELECT column_name FROM information_schema.columns 
            WHERE table_name = 'diagnosis_records' 
            AND column_name IN ('latitude', 'longitude', 'location_name')
        """))
        diagnosis_cols = [row[0] for row in result]
        print(f"   ✓ latitude: {'✅' if 'latitude' in diagnosis_cols else '❌'}")
        print(f"   ✓ longitude: {'✅' if 'longitude' in diagnosis_cols else '❌'}")
        print(f"   ✓ location_name: {'✅' if 'location_name' in diagnosis_cols else '❌'}")
        print("")
        
        # Verificar action_items
        print("3️⃣  Tabla: action_items")
        result = conn.execute(text("""
            SELECT column_name FROM information_schema.columns 
            WHERE table_name = 'action_items' 
            AND column_name IN ('priority', 'due_date', 'reminder_date', 'category', 'completed_at')
        """))
        action_cols = [row[0] for row in result]
        print(f"   ✓ priority: {'✅' if 'priority' in action_cols else '❌'}")
        print(f"   ✓ due_date: {'✅' if 'due_date' in action_cols else '❌'}")
        print(f"   ✓ reminder_date: {'✅' if 'reminder_date' in action_cols else '❌'}")
        print(f"   ✓ category: {'✅' if 'category' in action_cols else '❌'}")
        print(f"   ✓ completed_at: {'✅' if 'completed_at' in action_cols else '❌'}")
        print("")
        
        # Resumen
        total_expected = 10
        total_found = len(users_cols) + len(diagnosis_cols) + len(action_cols)
        
        if total_found == total_expected:
            print("✅ Todas las migraciones están aplicadas correctamente")
        else:
            print(f"⚠️  Faltan migraciones: {total_expected - total_found}/{total_expected} columnas encontradas")

if __name__ == "__main__":
    verify_migrations()
```

Ejecutar:

```bash
python scripts/verify_migrations.py
```

---

## 🔄 Rollback de Migraciones

Si necesitas revertir las migraciones:

### rollback_device_fields.py

```python
# scripts/migrations/rollback_device_fields.py
from sqlalchemy import text
from app.db.database import engine

def rollback():
    """Remueve campos de dispositivo de users"""
    print("🔄 Revirtiendo migración device_fields...")
    
    with engine.connect() as conn:
        try:
            conn.execute(text("ALTER TABLE users DROP COLUMN IF EXISTS display_name"))
            conn.execute(text("ALTER TABLE users DROP COLUMN IF EXISTS device_id"))
            conn.commit()
            print("✅ Rollback completado")
        except Exception as e:
            conn.rollback()
            print(f"❌ Error: {e}")

if __name__ == "__main__":
    rollback()
```

---

## 📝 Checklist de Instalación

Para una instalación nueva del backend:

- [ ] Instalar PostgreSQL
- [ ] Crear base de datos (`kaapeh_db`)
- [ ] Crear usuario (`kaapeh_user`)
- [ ] Configurar `.env` con credenciales
- [ ] Instalar dependencias Python (`pip install -r requirements.txt`)
- [ ] Ejecutar `python scripts/init_db.py` (crea tablas base)
- [ ] Ejecutar migración 1: `migrate_add_device_fields.py`
- [ ] Ejecutar migración 2: `migrate_add_location_fields.py`
- [ ] Ejecutar migración 3: `migrate_add_task_fields.py`
- [ ] Verificar migraciones (`python scripts/verify_migrations.py`)
- [ ] Iniciar servidor (`uvicorn app.main:app --reload`)

---

## 🆘 Troubleshooting

### Error: "relation does not exist"

**Causa**: Las tablas base no existen.

**Solución**:
```bash
python scripts/init_db.py
```

### Error: "column already exists"

**Causa**: La migración ya fue ejecutada.

**Solución**: No es un error, la migración detecta esto y se salta. Output mostrará: `ℹ️ Column 'X' already exists`

### Error: "could not connect to server"

**Causa**: PostgreSQL no está corriendo.

**Solución**:
```bash
# macOS
brew services start postgresql@14

# Linux
sudo systemctl start postgresql
```

### Error: "permission denied"

**Causa**: El usuario no tiene permisos en la base de datos.

**Solución**:
```sql
GRANT ALL PRIVILEGES ON DATABASE kaapeh_db TO kaapeh_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO kaapeh_user;
```

---

**Última actualización**: 5 de diciembre de 2025
