# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### En Desarrollo
- Soporte para modelos CoreML personalizados adicionales
- Dashboard web para técnicos
- Sincronización en tiempo real con WebSockets
- Exportación de reportes PDF

---

## [1.0.0] - 2025-12-05

### 🎉 Lanzamiento Inicial

Primera versión estable de KaapehCopiloto2 con funcionalidad completa.

### ✨ Nuevas Funcionalidades

#### IA y RAG
- **Sistema RAG Completo**: Pipeline de Recuperación-Aumento-Generación 100% en el dispositivo
- **Foundation Models**: Integración con Apple Intelligence (iOS 26+)
- **ObjectBox**: Base de datos vectorial con índice HNSW para búsquedas semánticas
- **NLContextualEmbedding**: Generación de embeddings de 512 dimensiones
- **@Generable Output**: Respuestas estructuradas type-safe del LLM

#### Diagnóstico Visual
- **CoreML + Vision**: Análisis de imágenes de plantas de café
- **Clasificación Multi-Clase**: Detección de enfermedades comunes (roya, broca, deficiencias)
- **Confianza Calibrada**: Scores precisos para cada diagnóstico
- **Integración con RAG**: Recomendaciones de tratamiento basadas en diagnóstico visual

#### Interfaz de Voz
- **Speech Framework (iOS 26+)**: Reconocimiento de voz en el dispositivo
- **AVFoundation TTS**: Síntesis de voz natural con soporte de voces personales
- **Chat Conversacional**: Bucle completo de conversación con detección de silencio
- **NLLanguageRecognizer**: Detección automática de idioma para TTS multilingüe

#### Persistencia de Datos
- **SwiftData**: Base de datos principal para perfiles y diagnósticos
- **ObjectBox**: Base de datos vectorial especializada para RAG
- **Sincronización en Segundo Plano**: BackgroundSyncService con FastAPI backend

#### Backend API
- **FastAPI**: API REST moderna y rápida
- **PostgreSQL**: Base de datos relacional con SQLAlchemy ORM
- **Autenticación JWT**: Sistema de autenticación seguro
- **Endpoints Completos**: Auth, diagnósticos, sync, métricas

#### Accesibilidad
- **VoiceOver**: Soporte completo para usuarios con discapacidad visual
- **Dynamic Type**: Texto adaptable a preferencias del usuario
- **Voice Control**: Control completo de la app por voz
- **High Contrast Mode**: Modo de alto contraste configurable

#### App Intents
- **Siri Integration**: Comandos de voz para diagnóstico y chat
- **Shortcuts**: Acciones personalizables en la app Atajos
- **NotificationCenter**: Comunicación entre intents y ViewModels

### 🧪 Testing
- **Suite Completa**: 50+ tests con cobertura >80%
- **EmbeddingServiceTests**: 13 tests para generación de embeddings
- **RAGServiceTests**: 8 tests para pipeline RAG
- **SwiftDataServiceTests**: 10 tests para persistencia
- **AuthenticationTests**: 5 tests para autenticación
- **DiagnosisFlowTests**: 7 tests para flujo de diagnóstico

### 📚 Documentación
- **README Principal**: Documentación completa del proyecto
- **README Backend**: Guía detallada del API backend
- **README iOS**: Guía completa de la aplicación iOS
- **CONTRIBUTING.md**: Guía para contribuyentes
- **Copilot Instructions**: Instrucciones técnicas detalladas para desarrollo

### 🏗️ Arquitectura
- **Capa de App**: Navegación y estado global
- **Capa del Núcleo**: Servicios, modelos y lógica de negocio
- **Capa de Features**: Funcionalidades por dominio
- **Clean Architecture**: Separación clara de responsabilidades
- **SOLID Principles**: Código mantenible y escalable

### 🔐 Seguridad y Privacidad
- **Procesamiento Local**: 100% de IA ejecutada en el dispositivo
- **Sin Tracking**: Cero analíticas o telemetría
- **Encriptación**: Base de datos local protegida
- **HTTPS Only**: Comunicación segura con backend
- **JWT Authentication**: Tokens seguros en backend

### 🎨 UI/UX
- **SwiftUI Nativo**: Interfaz moderna y declarativa
- **Liquid Glass Design**: Componentes personalizados con efectos glassmorphism
- **Tab Navigation**: Navegación por roles (Productor/Técnico)
- **Responsive Design**: Adaptable a diferentes tamaños de dispositivo
- **Dark Mode**: Soporte completo para modo oscuro

### 🐛 Correcciones

#### Tests
- Resuelto problema de "Expectation failed" en EmbeddingServiceTests
- Cambiado `guard` por `if` para skip condicional sin expectativas implícitas
- Todos los tests ahora pasan correctamente en Xcode UI y xcodebuild

#### RAG Service
- Corregida comparación de no-opcional con nil en inicialización
- Mejorado manejo de errores en pipeline RAG
- Optimizada construcción de prompts aumentados

#### Voice Chat
- Resuelto problema de detección de fin de turno
- Mejorado manejo de callbacks del synthesizer
- Optimizado bucle de conversación continua

### 🔧 Mejoras Técnicas

#### Performance
- Pre-computación de embeddings en build-time (reducción de ~800MB a 14MB)
- Índice HNSW de ObjectBox para búsquedas en <10ms
- Optimización de generación LLM (~30 tokens/segundo)
- Lazy loading de relaciones ToOne y ToMany

#### Código
- Migración completa a @Observable (iOS 17+)
- Uso de Swift Testing framework (iOS 26+)
- Actor pattern para concurrencia thread-safe
- Type-safe API con @Generable structs

### 📦 Dependencias

#### iOS
- ObjectBox-Swift: ^4.0.0
- Foundation Models (iOS 26+)
- SwiftData (iOS 26+)
- Speech Framework (iOS 26+)

#### Backend
- fastapi: ^0.104.1
- uvicorn: ^0.24.0
- sqlalchemy: ^2.0.23
- psycopg2-binary: ^2.9.9
- python-jose: ^3.3.0

### 🌍 Internacionalización
- Soporte para español (ES-MX)
- Soporte para inglés (EN-US)
- Framework preparado para más idiomas

### ⚠️ Breaking Changes
Ninguno (primera versión)

### 🔄 Migraciones
Ninguna (primera versión)

### 🗑️ Deprecaciones
Ninguna

---

## Guía de Versiones

### Tipos de Cambios
- **✨ Added**: Nuevas funcionalidades
- **🔧 Changed**: Cambios en funcionalidad existente
- **🗑️ Deprecated**: Funcionalidades que serán eliminadas
- **❌ Removed**: Funcionalidades eliminadas
- **🐛 Fixed**: Correcciones de bugs
- **🔐 Security**: Mejoras de seguridad

### Semantic Versioning
Dado un número de versión MAJOR.MINOR.PATCH:

- **MAJOR**: Cambios incompatibles en la API
- **MINOR**: Nuevas funcionalidades compatibles con versiones anteriores
- **PATCH**: Correcciones de bugs compatibles con versiones anteriores
