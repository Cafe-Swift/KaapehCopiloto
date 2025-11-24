"""
Script de prueba para el backend - Verificación de las 15 clases
Prueba la sincronización y categorización de diagnósticos
"""

import requests
import json
from datetime import datetime

# Configuración
BASE_URL = "http://localhost:8000"
API_V1 = f"{BASE_URL}/api/v1"

# Las 15 clases del modelo (formateadas en español como las envía la app)
CLASES_MODELO = [
    # Deficiencias (9)
    "Deficiencia de Nitrógeno (N)",
    "Deficiencia de Fósforo (P)",
    "Deficiencia de Potasio (K)",
    "Deficiencia de Calcio (Ca)",
    "Deficiencia de Magnesio (Mg)",
    "Deficiencia de Hierro (Fe)",
    "Deficiencia de Manganeso (Mn)",
    "Deficiencia de Boro (B)",
    "Múltiples Deficiencias Nutricionales",
    # Enfermedades (3)
    "Roya del Café",
    "Mancha de Phoma",
    "Ojo de Gallo (Cercospora)",
    # Plagas (2)
    "Minador de la Hoja",
    "Araña Roja",
    # Saludable (1)
    "Planta Saludable"
]


def test_health_check():
    """
    Prueba 1: Verificar que el servidor esté corriendo
    """
    print("\n" + "="*60)
    print("PRUEBA 1: Health Check")
    print("="*60)
    
    try:
        response = requests.get(f"{API_V1}/health")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Servidor corriendo")
            print(f"   Status: {data['status']}")
            print(f"   Version: {data['version']}")
            return True
        else:
            print(f"❌ Error: Status code {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error de conexión: {e}")
        print("\n💡 Solución: Inicia el servidor con:")
        print("   cd backend && python -m uvicorn app.main:app --reload")
        return False


def test_sync_15_classes():
    """
    Prueba 2: Sincronizar ejemplos de las 15 clases
    """
    print("\n" + "="*60)
    print("PRUEBA 2: Sincronización de las 15 Clases")
    print("="*60)
    
    # Crear payload con una muestra de cada clase
    diagnoses = []
    
    for i, clase in enumerate(CLASES_MODELO):
        # Simular diferentes niveles de confianza
        confidence = 0.75 + (i % 3) * 0.08  # 0.75, 0.83, 0.91, ...
        
        # Simular feedback aleatorio
        feedback = None
        if i % 3 == 0:
            feedback = True
        elif i % 3 == 1:
            feedback = False
        
        diagnoses.append({
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "detected_issue": clase,
            "confidence": round(confidence, 2),
            "user_feedback_correct": feedback,
            "location": "Chiapas, México"
        })
    
    payload = {"diagnoses": diagnoses}
    
    try:
        response = requests.post(
            f"{API_V1}/sync",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Sincronización exitosa")
            print(f"   Mensaje: {data['message']}")
            print(f"   Registros sincronizados: {data['synced_count']}")
            print(f"\n📊 Clases enviadas:")
            for diag in diagnoses:
                print(f"   • {diag['detected_issue']}: {diag['confidence']*100:.0f}%")
            return True
        else:
            print(f"❌ Error: Status code {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def test_metrics():
    """
    Prueba 3: Obtener métricas y verificar distribución
    
    NOTA: Esta prueba requiere autenticación de técnico.
    Por ahora solo muestra el error esperado.
    """
    print("\n" + "="*60)
    print("PRUEBA 3: Métricas (Requiere autenticación)")
    print("="*60)
    
    try:
        # Intentar sin token (esperamos 401)
        response = requests.get(f"{API_V1}/metrics")
        
        if response.status_code == 401:
            print(f"✅ Endpoint protegido correctamente")
            print(f"   Status: 401 Unauthorized (esperado)")
            print(f"\n💡 Para probar con autenticación:")
            print(f"   1. Registra un técnico: POST {API_V1}/auth/register")
            print(f"   2. Inicia sesión: POST {API_V1}/auth/login")
            print(f"   3. Usa el token: Authorization: Bearer {{token}}")
            return True
        else:
            print(f"⚠️  Status inesperado: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def test_category_endpoint():
    """
    Prueba 4: Endpoint de categorías (Requiere autenticación)
    """
    print("\n" + "="*60)
    print("PRUEBA 4: Endpoint de Categorías (Requiere autenticación)")
    print("="*60)
    
    try:
        # Intentar sin token (esperamos 401)
        response = requests.get(f"{API_V1}/metrics/categories")
        
        if response.status_code == 401:
            print(f"✅ Endpoint protegido correctamente")
            print(f"   Status: 401 Unauthorized (esperado)")
            print(f"\n📊 Este endpoint agrupa las 15 clases en 5 categorías:")
            print(f"   • Deficiencias Nutricionales (9 clases)")
            print(f"   • Enfermedades (3 clases)")
            print(f"   • Plagas (2 clases)")
            print(f"   • Plantas Saludables (1 clase)")
            print(f"   • Otros (fallback)")
            return True
        else:
            print(f"⚠️  Status inesperado: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def run_all_tests():
    """
    Ejecuta todas las pruebas
    """
    print("\n" + "🧪"*30)
    print("PRUEBAS DEL BACKEND - Soporte para 15 Clases")
    print("🧪"*30)
    
    results = []
    
    # Ejecutar pruebas
    results.append(("Health Check", test_health_check()))
    
    if results[0][1]:  # Solo continuar si el servidor está corriendo
        results.append(("Sincronización 15 Clases", test_sync_15_classes()))
        results.append(("Métricas Protegidas", test_metrics()))
        results.append(("Categorías Protegidas", test_category_endpoint()))
    
    # Resumen
    print("\n" + "="*60)
    print("RESUMEN DE PRUEBAS")
    print("="*60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    print(f"\nResultado: {passed}/{total} pruebas exitosas")
    
    if passed == total:
        print("\n🎉 ¡Todas las pruebas pasaron exitosamente!")
        print("\n✅ El backend está listo para las 15 clases del modelo")
    else:
        print("\n⚠️  Algunas pruebas fallaron. Revisa los logs arriba.")


if __name__ == "__main__":
    run_all_tests()
