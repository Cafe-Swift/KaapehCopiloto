# Sistema de Traducción Español ↔ Tsotsil

## 📚 Descripción

Este sistema permite cambiar dinámicamente entre Español y Tsotsil en toda la aplicación usando el `KaapehTranslator`.

## 🎯 Características

- ✅ Traducción automática de textos
- ✅ Cambio de idioma en tiempo real
- ✅ Persistencia de preferencia de idioma
- ✅ Búsqueda flexible (exacta, minúsculas, parcial)
- ✅ Integración con SwiftUI mediante `@ObservedObject`

## 📖 Vocabularios

Los vocabularios se encuentran en:
```
KaapehCopiloto2/Translator/KaapehModel/
├── vocab_spanish.json  (Español: ID → Texto)
├── vocab_tsotsil.json  (Tsotsil: ID → Texto)
```

**Formato JSON:**
```json
{
  "0": "Hola",
  "1": "Buenos días",
  "2": "Café"
}
```

## 🚀 Uso Básico

### 1. En cualquier Vista (SwiftUI)

```swift
import SwiftUI

struct MiVista: View {
    @ObservedObject private var translator = KaapehTranslator.shared
    
    var body: some View {
        VStack {
            // Método 1: Usando el traductor directamente
            Text(translator.t("Hola"))
            
            // Método 2: Usando la extensión String
            Text("Buenos días".translated())
            
            // Para botones
            Button(translator.t("Aceptar")) {
                // acción
            }
        }
    }
}
```

### 2. Cambiar el idioma programáticamente

```swift
// Opción 1: Toggle (cambiar entre español/tsotsil)
KaapehTranslator.shared.toggleLanguage()

// Opción 2: Establecer idioma específico
KaapehTranslator.shared.setLanguage("tsz")  // Tsotsil
KaapehTranslator.shared.setLanguage("es")   // Español
```

### 3. Verificar estado actual

```swift
let isTsotsil = KaapehTranslator.shared.isTzotzilActive
print("Idioma actual: \(isTsotsil ? "Tsotsil" : "Español")")
```

## 🎨 Implementación en SettingsView

El cambio de idioma se realiza desde **Ajustes**:

1. Usuario abre `SettingsView`
2. Selecciona "Español 🇲🇽" o "Tsotsil 🏔️"
3. `SettingsViewModel` detecta el cambio en `selectedLanguage`
4. `didSet` llama a `KaapehTranslator.shared.setLanguage(code)`
5. Todas las vistas con `@ObservedObject var translator` se actualizan automáticamente

## 📝 Agregar Nuevas Traducciones

### Paso 1: Agregar al JSON

**vocab_spanish.json:**
```json
{
  "0": "Hola",
  "1": "Buenos días",
  "999": "Nueva frase aquí"  // ← Nuevo
}
```

**vocab_tsotsil.json:**
```json
{
  "0": "Kóx",
  "1": "Li'ike ta ts'ub'al",
  "999": "Traducción en tsotsil aquí"  // ← Nuevo (mismo ID)
}
```

### Paso 2: Usar en la app

```swift
Text(translator.t("Nueva frase aquí"))
```

¡Listo! El traductor automáticamente cargará la nueva traducción.

## 🔍 Cómo Funciona Internamente

1. **Carga (init):**
   - Lee `vocab_spanish.json` → Mapa `[ID: Texto_ES]`
   - Lee `vocab_tsotsil.json` → Mapa `[ID: Texto_TSO]`
   - Cruza por ID → Diccionario final `[Texto_ES: Texto_TSO]`

2. **Traducción (t(_ text:)):**
   - Si `isTzotzilActive == false` → Devuelve texto original
   - Si `isTzotzilActive == true`:
     - Busca traducción exacta
     - Si no, busca en minúsculas
     - Si no, busca coincidencia parcial
     - Si no, devuelve texto original

3. **Cambio de idioma (setLanguage):**
   - Cambia `isTzotzilActive`
   - Llama `objectWillChange.send()` → SwiftUI redibuja todas las vistas que observan el traductor

## ✅ Vistas que YA Usan Traducción

- ✅ `SettingsView.swift`
  - Título "Ajustes"
  - Sección "Accesibilidad"
  - Sección "Idioma"
  - Sección "Cuenta"
  - Toggles y descripciones

- ✅ `ProducerHomeView.swift`
  - Saludo del día
  - "Tu cafetal en tu bolsillo"

## 🎯 Próximos Pasos Recomendados

Para completar la traducción de toda la app:

1. **DiagnosisCameraView**: Botones "Tomar Foto", "Galería"
2. **DiagnosisResultView**: Títulos de secciones, botones
3. **VoiceChatView**: Placeholders, mensajes del sistema
4. **TaskManagementView**: "Tareas", "Completadas", filtros
5. **LoginView**: "Iniciar Sesión", "Crear Cuenta"

### Ejemplo de implementación rápida:

```swift
// En cualquier vista, agregar al inicio:
@ObservedObject private var translator = KaapehTranslator.shared

// Luego, envolver todos los Text/Button con translator.t()
Text(translator.t("Texto original"))
```

## 🐛 Debug y Troubleshooting

### El idioma no cambia:
1. Verificar que la vista tenga `@ObservedObject var translator`
2. Verificar que `vocab_spanish.json` y `vocab_tsotsil.json` estén en el Bundle
3. Ver logs en consola: `📖 Vocabularios cargados. Frases listas: X`

### Traducción no aparece:
1. Verificar que la frase esté en ambos JSON con el mismo ID
2. Probar con `translator.hasTranslation(for: "texto")` → debe devolver `true`
3. Ver advertencia en consola: `⚠️ Traducción no encontrada para: 'texto'`

### Forzar recarga de vocabularios:
```swift
KaapehTranslator.shared.loadVocabularies()
```

## 📊 Estadísticas

- Vocabulario cargado: Ver logs al iniciar app
- Traducciones disponibles: `KaapehTranslator.shared.dictionary.count`
- Estado actual: `KaapehTranslator.shared.isTzotzilActive`

## 🙏 Créditos

Vocabulario desarrollado en colaboración con la comunidad tsotsil de Chiapas, México.

---

**Última actualización:** Diciembre 2025  
**Versión:** 1.0  
**Contacto:** Cafe Swift Team
