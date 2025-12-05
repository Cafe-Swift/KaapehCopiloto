# KaapehCopiloto2 - Aplicación iOS 📱

[![iOS](https://img.shields.io/badge/iOS-26.1+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-26+-blue.svg)](https://developer.apple.com/xcode/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-6.0-blue.svg)](https://developer.apple.com/xcode/swiftui/)

## 📋 Descripción

Aplicación iOS de vanguardia que utiliza **Apple Intelligence** y **RAG (Retrieval-Augmented Generation)** para proporcionar diagnósticos asistidos por IA de enfermedades en plantas de café. Todo el procesamiento ocurre **100% en el dispositivo**, garantizando privacidad total y funcionamiento offline.

---

## 🎯 Características Principales

### 🤖 IA en el Dispositivo
- **Foundation Models** (iOS 26+): LLM de ~3B parámetros corriendo localmente
- **RAG Avanzado**: Sistema de recuperación aumentada con búsqueda semántica
- **ObjectBox**: Base de datos vectorial con índice HNSW para búsquedas en milisegundos
- **NLContextualEmbedding**: Generación de embeddings de 512 dimensiones

### 📸 Diagnóstico Visual
- **CoreML + Vision**: Análisis de imágenes de plantas
- **Clasificación Multi-Clase**: Detección de múltiples enfermedades
- **Confianza Calibrada**: Scores de confianza precisos para cada diagnóstico

### 🗣️ Interfaz de Voz
- **Speech Framework (iOS 26+)**: Reconocimiento de voz en el dispositivo
- **AVFoundation**: Síntesis de voz natural con voces personales
- **Chat Conversacional**: Bucle completo de voz con detección de silencio

### ♿ Accesibilidad Total
- **VoiceOver**: Soporte completo para usuarios con discapacidad visual
- **Dynamic Type**: Texto adaptable a preferencias del usuario
- **Voice Control**: Control total de la app por voz
- **High Contrast**: Modo de alto contraste

### 🔐 Privacidad y Seguridad
- **Procesamiento Local**: 100% de datos permanecen en el dispositivo
- **SwiftData Encriptada**: Base de datos local protegida
- **Sin Tracking**: Cero analíticas o telemetría
- **Apple Intelligence**: Procesamiento confidencial garantizado por Apple

---

## 🏗️ Arquitectura de la App

```
KaapehCopiloto2/
├── App/                              # 🚀 Capa de Aplicación
│   ├── KaapehCopiloto2App.swift     # Entry point, configuración global
│   ├── RootView.swift               # Máquina de estados de navegación
│   ├── MainView.swift               # Router basado en roles
│   ├── ContentView.swift            # Vista principal
│   └── AppViewModel.swift           # Estado global de la app
│
├── Core/                             # 🧠 Capa del Núcleo
│   ├── Models/                      # Modelos de datos
│   │   ├── Domain/                  # Entidades de negocio
│   │   │   ├── UserProfile.swift   # @Model (SwiftData)
│   │   │   ├── DiagnosisRecord.swift
│   │   │   └── AccessibilityConfig.swift
│   │   ├── RAG/                     # Modelos para RAG
│   │   │   ├── DocumentChunk.swift # ObjectBox entity
│   │   │   └── KnowledgeDocument.swift
│   │   ├── Vision/                  # Modelos de visión
│   │   │   └── PlantClassification.swift
│   │   └── Voice/                   # Modelos de voz
│   │       └── VoiceChatState.swift
│   │
│   ├── Services/                    # Servicios de negocio
│   │   ├── AI/                      # Servicios de IA
│   │   │   ├── EmbeddingService.swift        # NLContextualEmbedding
│   │   │   ├── FoundationModelsService.swift # Apple LLM
│   │   │   └── RAGService.swift              # Orquestador RAG
│   │   ├── Data/                    # Persistencia
│   │   │   ├── SwiftDataService.swift        # SwiftData manager
│   │   │   └── VectorDatabaseService.swift   # ObjectBox manager
│   │   ├── Vision/                  # Análisis de imágenes
│   │   │   └── PlantVisionService.swift
│   │   ├── Voice/                   # Servicios de voz
│   │   │   ├── ModernSpeechManager.swift     # STT (iOS 26+)
│   │   │   └── TextToSpeechManager.swift     # TTS
│   │   ├── Network/                 # Backend sync
│   │   │   ├── NetworkService.swift
│   │   │   └── BackgroundSyncService.swift
│   │   └── System/
│   │       └── PermissionManager.swift
│   │
│   └── Theme/                       # Sistema de diseño
│       ├── AppTheme.swift           # Tokens de diseño
│       ├── AccessibilityManager.swift
│       └── LiquidGlassComponents.swift
│
├── Features/                         # 🎨 Capa de Funcionalidades
│   ├── Authentication/              # Login y registro
│   │   ├── LoginView.swift
│   │   └── AuthenticationViewModel.swift
│   ├── Onboarding/                  # Configuración inicial
│   │   └── OnboardingView.swift
│   ├── Producer/                    # Pantallas del productor
│   │   ├── ProducerHomeView.swift
│   │   ├── DiagnosisCameraView.swift
│   │   └── DiagnosisResultView.swift
│   ├── Technician/                  # Pantallas del técnico
│   │   └── TechnicianDashboardView.swift
│   ├── VoiceChat/                   # Chat por voz
│   │   ├── VoiceChatView.swift
│   │   └── VoiceChatViewModel.swift
│   └── AppIntents/                  # Integración con Siri
│       ├── DiagnosePlantIntent.swift
│       └── StartVoiceChatIntent.swift
│
├── Resources/                        # 📦 Recursos
│   ├── Assets.xcassets/             # Imágenes, colores, iconos
│   ├── KnowledgeBase/               # Base de conocimiento para RAG
│   └── Model/                       # Modelos CoreML
│       └── coffeeProblems.mlmodel
│
└── Info.plist                        # Configuración de la app
```

---

## 🚀 Configuración e Instalación

### Prerrequisitos

#### Hardware Mínimo:
- **iPhone**: iPhone 15 Pro o iPhone 16+ (requiere A17 Pro o A18)
- **iPad**: iPad con M1+ o iPad mini con A17 Pro
- **Mac**: Mac con Apple Silicon (M1+)

#### Software:
- **macOS**: Sequoia 15.1 o superior (para desarrollo)
- **Xcode**: 26.0 o superior
- **iOS**: 26.1 o superior (en el dispositivo de prueba)
- **Apple Intelligence**: Activado en Ajustes del dispositivo

### 1. Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/KaapehCopiloto2.git
cd KaapehCopiloto2
```

### 2. Abrir el Proyecto

```bash
open KaapehCopiloto2.xcodeproj
```

### 3. Configurar Dependencias

El proyecto usa **Swift Package Manager**. Las dependencias se resolverán automáticamente:

- **ObjectBox-Swift** (4.0+): Base de datos vectorial
  - Repository: `https://github.com/objectbox/objectbox-swift`
  - Version: 4.0.0 o superior

Si las dependencias no se descargan automáticamente:
1. Ve a **File > Packages > Resolve Package Versions**
2. Espera a que Xcode descargue los paquetes

### 4. Configurar Signing & Capabilities

1. Selecciona el target **KaapehCopiloto2**
2. Ve a **Signing & Capabilities**
3. Selecciona tu **equipo de desarrollo**
4. Asegúrate de que los siguientes capabilities estén habilitados:

#### Capabilities Requeridos:

| Capability | Propósito |
|------------|-----------|
| **Apple Intelligence** | Acceso a Foundation Models |
| **Camera** | Captura de imágenes de plantas |
| **Microphone** | Entrada de voz |
| **Speech Recognition** | Transcripción de voz |
| **Background Modes** | Sincronización en segundo plano |

#### Info.plist Requerido:

```xml
<key>NSCameraUsageDescription</key>
<string>Para capturar imágenes de plantas y realizar diagnósticos</string>

<key>NSMicrophoneUsageDescription</key>
<string>Para capturar tu voz en el modo de chat conversacional</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Tu voz se procesa completamente en el dispositivo para transcribir tus mensajes</string>
```

### 5. Compilar y Ejecutar

```bash
# Compilar (⌘ + B)
xcodebuild -scheme KaapehCopiloto2 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Ejecutar (⌘ + R)
# O usar el botón "Run" en Xcode
```

---

## 🧪 Ejecutar Tests

### Todos los Tests

```bash
# Compilar para testing
⌘ + Shift + U

# O desde terminal:
xcodebuild test -scheme KaapehCopiloto2 \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Tests Específicos

```bash
# Solo tests de Embedding
xcodebuild test -scheme KaapehCopiloto2 \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:KaapehCopiloto2Tests/EmbeddingServiceTests

# Solo tests de RAG
xcodebuild test -scheme KaapehCopiloto2 \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:KaapehCopiloto2Tests/RAGServiceTests
```

### Suite de Tests Disponibles

| Suite de Tests | Descripción | Tests |
|----------------|-------------|-------|
| **EmbeddingServiceTests** | Tests de generación de embeddings | 13 tests |
| **RAGServiceTests** | Tests del pipeline RAG completo | 8 tests |
| **SwiftDataServiceTests** | Tests de persistencia | 10 tests |
| **AuthenticationViewModelTests** | Tests de autenticación | 5 tests |
| **DiagnosisFlowTests** | Tests de flujo de diagnóstico | 7 tests |
| **SystemHealthTests** | Tests de salud del sistema | 4 tests |

**Total**: ~50 tests con cobertura > 80%

---

## 🎨 Arquitectura RAG Detallada

### Flujo Completo del Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│  1. INGESTA (Build-time o Runtime)                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Documentos de texto (PDFs, markdown, etc.)          │   │
│  └────────────────────┬────────────────────────────────┘   │
│                       ▼                                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Chunking: Dividir en párrafos/secciones             │   │
│  └────────────────────┬────────────────────────────────┘   │
│                       ▼                                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ EmbeddingService.generateEmbedding()                 │   │
│  │ → NLContextualEmbedding                              │   │
│  │ → Output: [Float] (512 dimensiones)                 │   │
│  └────────────────────┬────────────────────────────────┘   │
│                       ▼                                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ VectorDatabaseService.add()                          │   │
│  │ → ObjectBox con índice HNSW                          │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  2. QUERY-TIME (Cuando el usuario pregunta)                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Usuario: "¿Qué es la roya del café?"                │   │
│  └────────────────────┬────────────────────────────────┘   │
│                       ▼                                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ RETRIEVE (RAGService.retrieveRelevantDocuments)     │   │
│  │ 1. Convertir pregunta → vector                       │   │
│  │ 2. VectorDatabaseService.search()                    │   │
│  │ 3. Búsqueda HNSW (similitud coseno)                 │   │
│  │ 4. Retornar top-K chunks (k=3-5)                     │   │
│  └────────────────────┬────────────────────────────────┘   │
│                       ▼                                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ AUGMENT (RAGService.buildAugmentedPrompt)           │   │
│  │ Construir prompt:                                    │   │
│  │   "Contexto: [chunk1, chunk2, chunk3]"              │   │
│  │   "Pregunta: ¿Qué es la roya del café?"            │   │
│  │   "REGLAS: Usa SOLO el contexto..."                 │   │
│  └────────────────────┬────────────────────────────────┘   │
│                       ▼                                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ GENERATE (FoundationModelsService.generateResponse) │   │
│  │ 1. SystemLanguageModel.default                       │   │
│  │ 2. LanguageModelSession.respond()                    │   │
│  │ 3. @Generable output (type-safe)                     │   │
│  └────────────────────┬────────────────────────────────┘   │
│                       ▼                                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Respuesta: "La roya del café es una enfermedad..."  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Optimizaciones Clave

#### 1. Pre-computación de Embeddings
```swift
// ✅ CORRECTO: Pre-computar en build-time
let precomputedVectors = loadPrecomputedEmbeddings()
vectorDB.add(chunks: precomputedVectors)  // ~500KB

// ❌ INCORRECTO: Computar en runtime
for doc in documents {
    let vector = await embeddingService.generate(doc)  // ⚠️ Muy lento
}
```

#### 2. Índice HNSW de ObjectBox
```swift
// objectbox: entity
class DocumentChunk {
    var id: Id = 0
    var text: String = ""
    
    // ⚡ Índice HNSW para búsqueda O(log n)
    // objectbox:hnswIndex: dimensions=512, distanceType="cosine"
    var vector: [Float]?
}
```

#### 3. Salida Estructurada con @Generable
```swift
@Generable
struct RAGResponse {
    @Guide("Respuesta basada solo en el contexto")
    var answer: String
    
    @Guide("Fuentes citadas del contexto")
    var sources: [String]
    
    @Guide("Nivel de confianza (0.0-1.0)")
    var confidence: Double
}
```

---

## 🗣️ Sistema de Voz Conversacional

### Arquitectura del Bucle de Voz

```
┌─────────────────────────────────────────────────────────┐
│               VoiceChatViewModel                         │
│                 (Orquestador)                            │
└────────┬────────────────────────────────────────────┬───┘
         │                                             │
         ▼                                             ▼
┌─────────────────────┐                    ┌─────────────────────┐
│ ModernSpeechManager │                    │ TextToSpeechManager │
│  (STT - Ears)       │                    │  (TTS - Mouth)      │
└────────┬────────────┘                    └────────┬────────────┘
         │                                           │
         │ 1. User speaks                            │
         │    "¿Qué es la roya?"                     │
         ▼                                           │
┌─────────────────────────────────────┐             │
│ SpeechAnalyzer                       │             │
│ + SpeechTranscriber                  │             │
│ → Transcripción en tiempo real       │             │
└────────┬────────────────────────────┘             │
         │                                           │
         │ 2. Silence detected (1.5s timer)          │
         │    Transcript: "¿Qué es la roya?"        │
         ▼                                           │
┌─────────────────────────────────────┐             │
│ RAGService.answer()                  │             │
│ → Retrieve + Augment + Generate      │             │
└────────┬────────────────────────────┘             │
         │                                           │
         │ 3. Response text:                         │
         │    "La roya del café es..."               │
         │                                           │
         └───────────────────────────────────────────┤
                                                     │
                                                     ▼
                                        ┌─────────────────────────┐
                                        │ AVSpeechSynthesizer     │
                                        │ → Speak response        │
                                        └────────┬────────────────┘
                                                 │
                                                 │ 4. didFinish callback
                                                 ▼
                                        ┌─────────────────────────┐
                                        │ Loop back to LISTENING  │
                                        │ (Continuous mode)       │
                                        └─────────────────────────┘
```

### Estados de la Conversación

```swift
enum VoiceChatState {
    case idle           // Modo de voz desactivado
    case listening      // Micrófono activo, esperando entrada
    case processingResponse  // Ejecutando RAG pipeline
    case speaking       // TTS reproduciendo respuesta
}
```

---

## ♿ Guía de Accesibilidad

### VoiceOver

```swift
Button("Diagnose") { /* action */ }
    .accessibilityLabel("Diagnosticar planta")
    .accessibilityHint("Toca dos veces para iniciar el diagnóstico")
    .accessibilityValue(isAnalyzing ? "Analizando" : "Listo")
```

### Voice Control

```swift
Button { /* action */ } label: {
    Image(systemName: "mic.fill")
}
.accessibilityLabel("Iniciar chat por voz")
.accessibilityInputLabels(["Voz", "Hablar", "Micrófono"])
```

### Dynamic Type

```swift
Text("Título")
    .font(.custom("SF Pro", size: accessibilityManager.titleFontSize))
    .dynamicTypeSize(...accessibilitySize)
```

---

## 🔧 Configuración Avanzada

### Modelos CoreML Personalizados

1. Entrenar modelo con Create ML o Python
2. Exportar a `.mlmodel`
3. Agregar a `Resources/Model/`
4. Importar en el proyecto
5. Usar con `Vision` framework

```swift
let model = try VNCoreMLModel(for: CoffeeDiseaseClassifier().model)
let request = VNCoreMLRequest(model: model)
// ...proceso de análisis
```

### Adaptadores LoRA Personalizados

Para crear un modelo "experto" en café:

1. Obtener entitlement de Apple
2. Descargar toolkit de entrenamiento
3. Preparar dataset (prompt-respuesta)
4. Entrenar adaptador
5. Exportar como `.fmadapter`
6. Desplegar vía Background Assets

```swift
let adapter = try SystemLanguageModel.Adapter(name: "CoffeeExpert")
let expertModel = SystemLanguageModel(adapter: adapter)
```

---

## 📊 Métricas y Performance

### Benchmarks Típicos

| Operación | Tiempo | Notas |
|-----------|--------|-------|
| Embedding (512-dim) | ~50ms | NLContextualEmbedding |
| Vector search (HNSW) | <10ms | ObjectBox en 10K vectores |
| LLM generation (50 tokens) | ~1.5s | Foundation Models on-device |
| Image classification | ~200ms | CoreML en A17 Pro |
| STT transcription | Real-time | Speech framework |
| TTS synthesis | Real-time | AVFoundation |

---

## 🐛 Troubleshooting

### Problema: "Foundation Models not available"

**Causa**: Apple Intelligence no activado o dispositivo incompatible.

**Solución**:
1. Verifica hardware: iPhone 15 Pro+, iPad M1+, o Mac M1+
2. Ve a Ajustes > Apple Intelligence
3. Activa Apple Intelligence
4. Reinicia la app

### Problema: "Embedding assets not available"

**Causa**: Modelo NLContextualEmbedding no descargado.

**Solución**:
```swift
if let embedding = NLContextualEmbedding(language:.spanish) {
    if !embedding.hasAvailableAssets {
        try await embedding.requestAssets()
    }
}
```

### Problema: Tests fallan con "Expectation failed"

**Causa**: Tests que usan `guard` para skip condicional.

**Solución**: Usar `if` simple en lugar de `guard`:
```swift
// ✅ CORRECTO
if !service.isReady { return }

// ❌ INCORRECTO (crea expectativa implícita)
guard service.isReady else { return }
```

---

## 📚 Recursos Adicionales

- [Guía Completa de RAG](../docs/RAG_GUIDE.md)
- [Testing Guide](../GUIA_TESTING.md)
- [Copilot Instructions](../.github/copilot-instructions.md)
- [Apple Foundation Models Docs](https://developer.apple.com/documentation/FoundationModels)
- [ObjectBox Swift Docs](https://swift.objectbox.io/)

---

## 🤝 Contribuir

Ver [CONTRIBUTING.md](../CONTRIBUTING.md) para guías de contribución.

---

## 📄 Licencia

MIT License - Ver [LICENSE](../LICENSE)

---

**📱 Aplicación iOS construida con SwiftUI y Apple Intelligence**
