# KaapehCopiloto2 🌱☕

[![iOS](https://img.shields.io/badge/iOS-26.1+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-26+-blue.svg)](https://developer.apple.com/xcode/)
[![Python](https://img.shields.io/badge/Python-3.11+-green.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-teal.svg)](https://fastapi.tiangolo.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📋 Descripción

**KaapehCopiloto2** es una aplicación avanzada de iOS para el diagnóstico asistido por IA de enfermedades en plantas de café. Utiliza tecnologías de vanguardia como **Apple Intelligence**, **RAG (Retrieval-Augmented Generation)**, y **procesamiento de visión en el dispositivo** para proporcionar diagnósticos precisos y recomendaciones de tratamiento a productores de café.

### 🎯 Características Principales

- 🤖 **IA en el Dispositivo**: Utiliza Apple Foundation Models (iOS 26+) para inferencia 100% local
- 🔍 **RAG Avanzado**: Sistema de recuperación aumentada con ObjectBox y embeddings semánticos
- 📸 **Diagnóstico Visual**: Análisis de imágenes de plantas usando CoreML y Vision
- 🗣️ **Interfaz de Voz**: Chat conversacional completo con reconocimiento y síntesis de voz
- 🔐 **Privacidad Total**: Todos los datos y procesamiento permanecen en el dispositivo
- ⚡ **Funcionamiento Offline**: No requiere conexión a Internet para diagnósticos
- ♿ **Accesibilidad Completa**: Soporte completo para VoiceOver, Dynamic Type y Voice Control

---

## 🏗️ Arquitectura del Proyecto

```
KaapehCopiloto2/
├── KaapehCopiloto2/          # 📱 Aplicación iOS (Swift/SwiftUI)
│   ├── App/                  # Punto de entrada y navegación principal
│   ├── Core/                 # Servicios, modelos y lógica de negocio
│   │   ├── Models/           # Modelos de datos (SwiftData, ObjectBox)
│   │   ├── Services/         # Servicios de IA, datos, red, voz
│   │   └── Theme/            # Sistema de diseño y accesibilidad
│   ├── Features/             # Funcionalidades por dominio
│   │   ├── Authentication/   # Login y registro
│   │   ├── Diagnosis/        # Diagnóstico de plantas
│   │   ├── VoiceChat/        # Chat por voz con IA
│   │   └── Producer/         # Pantallas del productor
│   └── Resources/            # Assets y base de conocimiento
│
├── backend/                  # 🐍 API Backend (FastAPI/Python)
│   ├── app/                  # Código de la aplicación
│   │   ├── api/              # Endpoints REST
│   │   ├── core/             # Configuración y seguridad
│   │   ├── crud/             # Operaciones de base de datos
│   │   ├── db/               # Configuración de PostgreSQL
│   │   ├── models/           # Modelos SQLAlchemy
│   │   └── schemas/          # Esquemas Pydantic
│   └── scripts/              # Scripts de migración y setup
│       └── migrations/       # ⭐ 3 migraciones de esquema
│
└── KaapehCopiloto2Tests/     # 🧪 Suite de tests completa
```

---

## 🚀 Inicio Rápido

### Prerrequisitos

#### Para iOS:
- macOS Sequoia 15.1+ (para desarrollo)
- Xcode 26.0+
- Dispositivo con:
  - iPhone: A17 Pro+ o iPhone 16+
  - iPad: M1+ o iPad mini (A17 Pro)
  - Mac: Apple Silicon (M1+)
- iOS 26.1+ instalado
- Apple Intelligence activado en Ajustes

#### Para Backend:
- Python 3.11+
- PostgreSQL 14+
- pip y virtualenv

---

## 📱 Configuración iOS

### 1. Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/KaapehCopiloto2.git
cd KaapehCopiloto2
```

### 2. Abrir en Xcode

```bash
open KaapehCopiloto2.xcodeproj
```

### 3. Configurar Dependencias

El proyecto usa Swift Package Manager. Las dependencias se descargarán automáticamente:

- **ObjectBox-Swift**: Base de datos vectorial para RAG
- Otras dependencias se resolverán al compilar

### 4. Configurar Signing

1. Selecciona el target `KaapehCopiloto2`
2. Ve a **Signing & Capabilities**
3. Selecciona tu equipo de desarrollo
4. Asegúrate de tener los siguientes entitlements:
   - Apple Intelligence
   - Foundation Model Adapter (si usas modelos personalizados)

### 5. Compilar y Ejecutar

```bash
# Compilar
⌘ + B

# Ejecutar en simulador
⌘ + R

# Ejecutar tests
⌘ + U
```

**📖 Documentación completa:** [Ver README de iOS](./KaapehCopiloto2/README.md)

---

## 🐍 Configuración Backend

### 1. Navegar al Directorio Backend

```bash
cd backend
```

### 2. Crear Entorno Virtual

```bash
python3 -m venv venv
source venv/bin/activate  # En macOS/Linux
```

### 3. Instalar Dependencias

```bash
pip install -r requirements.txt
```

### 4. Configurar PostgreSQL

```bash
# Crear base de datos
createdb kaapeh_db

# Ejecutar script de setup
./scripts/setup_postgres.sh
```

### 5. Configurar Variables de Entorno

```bash
cp .env.example .env
# Editar .env con tus credenciales
```

### 6. Inicializar Base de Datos

```bash
python scripts/init_db.py
```

### 7. Ejecutar Migraciones**

El backend incluye **3 migraciones** que agregan campos avanzados a las tablas:

```bash
# Migración 1: Campos de dispositivo (users)
python scripts/migrations/migrate_add_device_fields.py

# Migración 2: Campos de ubicación GPS (diagnosis_records)
python scripts/migrations/migrate_add_location_fields.py

# Migración 3: Campos avanzados de tareas (action_items)
python scripts/migrations/migrate_add_task_fields.py
```

**Campos agregados:**
- `users`: `display_name`, `device_id`
- `diagnosis_records`: `latitude`, `longitude`, `location_name`
- `action_items`: `priority`, `due_date`, `reminder_date`, `category`, `completed_at`

**📖 Guía completa:** [Ver MIGRATIONS_GUIDE.md](./backend/MIGRATIONS_GUIDE.md)

### 8. Ejecutar el Servidor

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

El servidor estará disponible en: `http://localhost:8000`  
Documentación API: `http://localhost:8000/docs`

**📖 Documentación completa:** [Ver README de Backend](./backend/README.md)

---

## 🧪 Ejecutar Tests

### Tests de iOS

```bash
# Todos los tests
xcodebuild test -scheme KaapehCopiloto2 \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Solo tests de un módulo específico
xcodebuild test -scheme KaapehCopiloto2 \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:KaapehCopiloto2Tests/EmbeddingServiceTests
```

### Tests de Backend

```bash
cd backend
pytest tests/ -v
```

---

## 🎨 Tecnologías Utilizadas

### Frontend (iOS)

| Tecnología | Propósito |
|------------|-----------|
| **SwiftUI** | Framework de UI declarativo |
| **Foundation Models** | IA generativa en el dispositivo (iOS 26+) |
| **ObjectBox** | Base de datos vectorial para RAG |
| **NLContextualEmbedding** | Generación de embeddings semánticos |
| **CoreML + Vision** | Análisis de imágenes de plantas |
| **Speech + AVFoundation** | Reconocimiento y síntesis de voz |
| **SwiftData** | Persistencia de datos del usuario |
| **App Intents** | Integración con Siri y Atajos |

### Backend (Python)

| Tecnología | Propósito |
|------------|-----------|
| **FastAPI** | Framework web moderno y rápido |
| **SQLAlchemy** | ORM para PostgreSQL |
| **PostgreSQL** | Base de datos relacional |
| **Pydantic** | Validación de datos y schemas |
| **python-jose** | Autenticación JWT |
| **Uvicorn** | Servidor ASGI de alto rendimiento |

---

## 📊 Arquitectura de IA

### Sistema RAG (Retrieval-Augmented Generation)

```
┌─────────────────────────────────────────────────────┐
│                  Usuario                             │
│             "¿Qué es la roya?"                       │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│           1. RETRIEVE (Recuperación)                 │
│   ┌─────────────────────────────────────────┐      │
│   │  EmbeddingService                        │      │
│   │  - Convierte pregunta → vector (512-dim)│      │
│   └──────────────┬──────────────────────────┘      │
│                  ▼                                   │
│   ┌─────────────────────────────────────────┐      │
│   │  ObjectBox (HNSW Index)                  │      │
│   │  - Búsqueda de similitud coseno          │      │
│   │  - Retorna top-K chunks más relevantes   │      │
│   └──────────────┬──────────────────────────┘      │
└──────────────────┼──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│           2. AUGMENT (Aumento)                       │
│   ┌─────────────────────────────────────────┐      │
│   │  RAGService                              │      │
│   │  - Construye prompt aumentado:           │      │
│   │    "Contexto: [chunks]..."               │      │
│   │    "Pregunta: ¿Qué es la roya?"         │      │
│   └──────────────┬──────────────────────────┘      │
└──────────────────┼──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│           3. GENERATE (Generación)                   │
│   ┌─────────────────────────────────────────┐      │
│   │  FoundationModelsService                 │      │
│   │  - LLM en-dispositivo (~3B params)       │      │
│   │  - Genera respuesta basada en contexto   │      │
│   └──────────────┬──────────────────────────┘      │
└──────────────────┼──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│                  Respuesta                           │
│  "La roya del café es una enfermedad causada por..." │
└─────────────────────────────────────────────────────┘
```

---

## 🗄️ Base de Datos Backend

### Esquema Principal

El backend utiliza **PostgreSQL** con 3 tablas principales:

#### Tabla `users`
- Campos base: `id`, `username`, `email`, `hashed_password`, `role`
- ⭐ **Nuevos (migración)**: `display_name`, `device_id`

#### Tabla `diagnosis_records`
- Campos base: `id`, `user_id`, `detected_issue`, `confidence`, `timestamp`
- ⭐ **Nuevos (migración)**: `latitude`, `longitude`, `location_name`

#### Tabla `action_items`
- Campos base: `id`, `diagnosis_id`, `task_description`, `is_completed`
- ⭐ **Nuevos (migración)**: `priority`, `due_date`, `reminder_date`, `category`, `completed_at`

### Migraciones Disponibles

El proyecto incluye **3 scripts de migración** en `backend/scripts/migrations/`:

1. **migrate_add_device_fields.py**: Agrega identificación de dispositivos
2. **migrate_add_location_fields.py**: Agrega geolocalización GPS
3. **migrate_add_task_fields.py**: Agrega sistema avanzado de tareas

**Total**: 10 campos nuevos en 3 tablas

**Ver documentación completa**: [MIGRATIONS_GUIDE.md](./backend/MIGRATIONS_GUIDE.md)

---

## 🔐 Seguridad y Privacidad

### Principios de Diseño

- ✅ **Procesamiento Local**: Toda la IA se ejecuta en el dispositivo
- ✅ **Sin Tracking**: No se recopilan datos analíticos del usuario
- ✅ **Encriptación**: Base de datos local encriptada
- ✅ **Autenticación JWT**: Backend con tokens seguros
- ✅ **HTTPS Only**: Comunicación encriptada con el servidor
- ✅ **Minimal Data**: Solo se sincronizan datos esenciales

### Permisos de iOS

```xml
<!-- Info.plist -->
<key>NSCameraUsageDescription</key>
<string>Para capturar imágenes de plantas y realizar diagnósticos</string>

<key>NSMicrophoneUsageDescription</key>
<string>Para interactuar por voz con el asistente de IA</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Tu voz se procesa completamente en el dispositivo</string>
```

---

## 📈 Estado del Proyecto

### ✅ Completado

- [x] Arquitectura base de la app
- [x] Sistema RAG completo en-dispositivo
- [x] Integración con Foundation Models
- [x] Base de datos vectorial (ObjectBox)
- [x] Generación de embeddings (NLContextualEmbedding)
- [x] Diagnóstico visual con CoreML
- [x] Interfaz de chat por voz
- [x] Backend API con FastAPI
- [x] Autenticación y autorización
- [x] **Migraciones de base de datos (3 scripts)**
- [x] Sistema de tests completo
- [x] Documentación exhaustiva

### 🚧 En Desarrollo

- [ ] Modelos CoreML personalizados para enfermedades específicas
- [ ] Sincronización en tiempo real con backend
- [ ] Dashboard web para técnicos
- [ ] Soporte multiidioma completo
- [ ] Exportación de reportes PDF

### 🔮 Futuro

- [ ] Apple Watch companion app
- [ ] Widgets de iOS
- [ ] Integración con sensores IoT
- [ ] Análisis predictivo de cosechas
- [ ] Modo colaborativo para comunidades

---

## 🤝 Contribuir

### Configuración para Desarrollo

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Estándares de Código

- **Swift**: Seguir [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- **Python**: Seguir [PEP 8](https://pep8.org/)
- **Tests**: Cobertura mínima del 80%
- **Commits**: Usar [Conventional Commits](https://www.conventionalcommits.org/)

**📖 Guía completa**: [CONTRIBUTING.md](./CONTRIBUTING.md)

---

## 📚 Documentación

### Documentos Principales

- 📱 [README de iOS](./KaapehCopiloto2/README.md) - Guía completa de la app iOS
- 🐍 [README de Backend](./backend/README.md) - Guía completa del API
- 🔄 [Guía de Migraciones](./backend/MIGRATIONS_GUIDE.md) - Migraciones de BD
- 🤝 [Guía de Contribución](./CONTRIBUTING.md) - Cómo contribuir
- 📝 [Changelog](./CHANGELOG.md) - Historial de versiones
- 📊 [Índice de Documentación](./DOCUMENTATION_INDEX.md) - Índice completo

### Recursos Técnicos

- [Guía Completa de RAG](./docs/RAG_GUIDE.md)
- [Testing Guide](./GUIA_TESTING.md)
- [Copilot Instructions](./.github/copilot-instructions.md)
- [Apple Foundation Models Docs](https://developer.apple.com/documentation/FoundationModels)
- [ObjectBox Swift Docs](https://swift.objectbox.io/)

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

---

## 👥 Autores

- **Marco Antonio** - *Desarrollo principal* - [GitHub](https://github.com/maantora)

---

## 🙏 Agradecimientos

- Apple por el framework Foundation Models y la plataforma iOS
- Comunidad de ObjectBox por la excelente base de datos vectorial
- Productores de café de Káapeh por feedback y pruebas beta
- Comunidad open-source de Swift y Python

---

## 📞 Soporte

- 📧 Email: soporte@kaapeh.com
- 🐛 Issues: [GitHub Issues](https://github.com/tu-usuario/KaapehCopiloto2/issues)
- 💬 Discusiones: [GitHub Discussions](https://github.com/tu-usuario/KaapehCopiloto2/discussions)

---

## 🔗 Enlaces Útiles

- [Documentación de Apple Foundation Models](https://developer.apple.com/documentation/FoundationModels)
- [Guía de RAG en iOS](./docs/RAG_GUIDE.md)
- [Guía de Testing](./GUIA_TESTING.md)
- [API Documentation](http://localhost:8000/docs)
- [Changelog](./CHANGELOG.md)

---

**Hecho con ☕ y ❤️ para la comunidad cafetera**
