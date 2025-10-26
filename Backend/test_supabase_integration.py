#!/usr/bin/env python3
"""
Script de prueba para la integración de Supabase con Credit Scoring
"""

import requests
import json
from datetime import datetime

# Configuración
BASE_URL = "http://localhost:8004"
TEST_ACCOUNT_ID = "ACC123456"  # Cambiar por un account_id real de tu Supabase

def print_section(title):
    """Imprime un título de sección"""
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}\n")

def test_health_check():
    """Test 1: Verificar que el servicio esté corriendo"""
    print_section("TEST 1: Health Check")
    
    try:
        response = requests.get(f"{BASE_URL}/credit/health")
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            print("✅ Servicio de credit scoring está corriendo")
            return True
        else:
            print("❌ Servicio no responde correctamente")
            return False
    except Exception as e:
        print(f"❌ Error conectando al servicio: {str(e)}")
        return False

def test_extract_features(account_id):
    """Test 2: Extraer features de Supabase"""
    print_section(f"TEST 2: Extraer Features de {account_id}")
    
    try:
        response = requests.get(f"{BASE_URL}/credit/account/{account_id}/features")
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Features extraídas exitosamente")
            print(f"\nAccount ID: {data['account_id']}")
            print(f"Customer ID: {data['customer_id']}")
            print(f"\nFeatures Básicas:")
            for key, value in data['features'].items():
                print(f"  - {key}: {value}")
            print(f"\nMetadata:")
            print(f"  - Calidad de datos: {data['metadata']['data_quality_score']:.2%}")
            print(f"  - Meses de historial: {data['metadata']['months_of_history']}")
            print(f"  - Estado: {data['metadata']['quality_status']}")
            return True
        elif response.status_code == 404:
            print(f"❌ Cuenta no encontrada: {response.json()['detail']}")
            return False
        else:
            print(f"❌ Error: {response.json()['detail']}")
            return False
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False

def test_credit_scoring(account_id):
    """Test 3: Scoring crediticio completo"""
    print_section(f"TEST 3: Credit Scoring Completo - {account_id}")
    
    try:
        response = requests.post(f"{BASE_URL}/credit/score-by-account/{account_id}")
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            offer = data['offer']
            
            print(f"✅ Score calculado exitosamente")
            print(f"\n{'─'*60}")
            print(f"  OFERTA DE CRÉDITO")
            print(f"{'─'*60}")
            print(f"  Cliente: {offer['customer_id']}")
            print(f"  Score PD90: {offer['pd90_score']:.3f}")
            print(f"  Tier de Riesgo: {offer['risk_tier']}")
            print(f"  Límite de Crédito: ${offer['credit_limit']:,.2f}")
            print(f"  APR: {offer['apr']:.1f}%")
            print(f"  MSI Elegible: {'Sí' if offer['msi_eligible'] else 'No'}")
            if offer['msi_eligible']:
                print(f"  MSI Meses: {offer['msi_months']}")
            print(f"\n  Explicación:")
            print(f"  {offer['explanation']}")
            print(f"{'─'*60}")
            print(f"\n  Modelo: {data['model_version']}")
            
            return True
        elif response.status_code == 404:
            print(f"❌ Cuenta no encontrada: {response.json()['detail']}")
            return False
        elif response.status_code == 400:
            print(f"❌ Datos insuficientes: {response.json()['detail']}")
            return False
        else:
            print(f"❌ Error: {response.json()['detail']}")
            return False
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False

def test_manual_scoring():
    """Test 4: Scoring manual (modo tradicional)"""
    print_section("TEST 4: Credit Scoring Manual")
    
    payload = {
        "age": 32,
        "income_monthly": 15000.0,
        "payroll_streak": 8,
        "payroll_variance": 0.12,
        "spending_monthly": 8500.0,
        "spending_var_6m": 0.18,
        "current_debt": 5000.0,
        "dti": 0.33,
        "utilization": 0.45
    }
    
    try:
        response = requests.post(f"{BASE_URL}/credit/score", json=payload)
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            offer = data['offer']
            
            print(f"✅ Score calculado exitosamente (modo manual)")
            print(f"\nOferta:")
            print(f"  - Score PD90: {offer['pd90_score']:.3f}")
            print(f"  - Tier: {offer['risk_tier']}")
            print(f"  - Límite: ${offer['credit_limit']:,.2f}")
            print(f"  - APR: {offer['apr']:.1f}%")
            return True
        else:
            print(f"❌ Error: {response.json()['detail']}")
            return False
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False

def main():
    """Ejecutar todos los tests"""
    print("\n" + "="*60)
    print("  SUITE DE PRUEBAS - SUPABASE CREDIT SCORING")
    print("="*60)
    print(f"  Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"  Base URL: {BASE_URL}")
    print(f"  Test Account: {TEST_ACCOUNT_ID}")
    print("="*60)
    
    results = []
    
    # Test 1: Health Check
    results.append(("Health Check", test_health_check()))
    
    # Test 2: Extraer Features
    results.append(("Extraer Features", test_extract_features(TEST_ACCOUNT_ID)))
    
    # Test 3: Credit Scoring Completo
    results.append(("Credit Scoring Completo", test_credit_scoring(TEST_ACCOUNT_ID)))
    
    # Test 4: Scoring Manual
    results.append(("Scoring Manual", test_manual_scoring()))
    
    # Resumen
    print_section("RESUMEN DE PRUEBAS")
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    print(f"\n{'─'*60}")
    print(f"  Total: {passed}/{total} pruebas pasaron")
    print(f"{'─'*60}\n")
    
    if passed == total:
        print("🎉 ¡Todas las pruebas pasaron exitosamente!")
        return 0
    else:
        print(f"⚠️  {total - passed} prueba(s) fallaron")
        return 1

if __name__ == "__main__":
    import sys
    sys.exit(main())

