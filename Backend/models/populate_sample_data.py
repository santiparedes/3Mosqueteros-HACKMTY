"""
Script para poblar la API de Nessie con datos de ejemplo realistas
para el modelo de análisis de crédito.
"""
import requests
import json
from datetime import datetime, timedelta
from random import randint, choice, uniform

API_KEY = "2efca97355951ec13f6acfd0a8806a14"
BASE_URL = "http://api.nessieisreal.com"

# =============================================================================
# DATOS DE REFERENCIA
# =============================================================================

SAMPLE_CUSTOMERS = [
    {
        "first_name": "Maria",
        "last_name": "Garcia",
        "birth_date": "1985-03-15",
        "address": {
            "street_number": "456",
            "street_name": "Reforma Ave",
            "city": "Mexico City",
            "state": "MX",
            "zip": "06600"
        },
        "profile": "good",  # Buen perfil crediticio
        "monthly_salary": 4500,
        "stability_months": 24
    },
    {
        "first_name": "Carlos",
        "last_name": "Rodriguez",
        "birth_date": "1992-07-22",
        "address": {
            "street_number": "789",
            "street_name": "Insurgentes Sur",
            "city": "Mexico City",
            "state": "MX",
            "zip": "03100"
        },
        "profile": "excellent",  # Excelente perfil
        "monthly_salary": 6000,
        "stability_months": 36
    },
    {
        "first_name": "Ana",
        "last_name": "Martinez",
        "birth_date": "1988-11-30",
        "address": {
            "street_number": "321",
            "street_name": "Juarez Ave",
            "city": "Guadalajara",
            "state": "JAL",
            "zip": "44100"
        },
        "profile": "fair",  # Perfil regular
        "monthly_salary": 3200,
        "stability_months": 12
    },
    {
        "first_name": "Luis",
        "last_name": "Hernandez",
        "birth_date": "1995-05-18",
        "address": {
            "street_number": "555",
            "street_name": "Constitucion",
            "city": "Monterrey",
            "state": "NL",
            "zip": "64000"
        },
        "profile": "poor",  # Perfil con riesgo
        "monthly_salary": 2800,
        "stability_months": 6
    }
]

MERCHANT_CATEGORIES = [
    {"id": "merch_supermarket", "category": "Supermarket", "name": "Walmart"},
    {"id": "merch_gas", "category": "Gas Station", "name": "Shell"},
    {"id": "merch_restaurant", "category": "Restaurant", "name": "Starbucks"},
    {"id": "merch_pharmacy", "category": "Pharmacy", "name": "Farmacia Guadalajara"},
    {"id": "merch_clothing", "category": "Clothing", "name": "Zara"},
    {"id": "merch_electronics", "category": "Electronics", "name": "Best Buy"},
    {"id": "merch_entertainment", "category": "Entertainment", "name": "Cinepolis"},
    {"id": "merch_utilities", "category": "Utilities", "name": "CFE"}
]

# =============================================================================
# FUNCIONES AUXILIARES
# =============================================================================

def get_date_string(days_ago):
    """Retorna fecha en formato YYYY-MM-DD hace X días"""
    date = datetime.now() - timedelta(days=days_ago)
    return date.strftime("%Y-%m-%d")

def create_customer(customer_data):
    """Crea un cliente en la API"""
    payload = {
        "first_name": customer_data["first_name"],
        "last_name": customer_data["last_name"],
        "address": customer_data["address"]
    }
    
    # Nota: La API de Nessie no permite agregar date_of_birth al crear clientes
    # Esto es una limitación de la API sandbox
    
    try:
        r = requests.post(
            f"{BASE_URL}/customers?key={API_KEY}",
            headers={"Content-Type": "application/json"},
            json=payload
        )
        if r.status_code in [200, 201]:
            response = r.json()
            if 'objectCreated' in response:
                return response['objectCreated']['_id']
        else:
            print(f"      Error ({r.status_code}): {r.text[:200]}")
    except Exception as e:
        print(f"      Error: {e}")
    return None

def create_checking_account(customer_id, balance):
    """Crea una cuenta checking"""
    payload = {
        "type": "Checking",
        "nickname": "Main Checking",
        "rewards": randint(0, 1000),
        "balance": balance
    }
    
    try:
        r = requests.post(
            f"{BASE_URL}/customers/{customer_id}/accounts?key={API_KEY}",
            headers={"Content-Type": "application/json"},
            json=payload
        )
        if r.status_code in [200, 201]:
            response = r.json()
            if 'objectCreated' in response:
                return response['objectCreated']['_id']
    except Exception as e:
        print(f"      Error: {e}")
    return None

def create_credit_account(customer_id, balance):
    """Crea una cuenta de crédito (balance negativo = deuda)"""
    payload = {
        "type": "Credit Card",
        "nickname": "Credit Card",
        "rewards": randint(0, 500),
        "balance": balance  # Negativo para deuda
    }
    
    try:
        r = requests.post(
            f"{BASE_URL}/customers/{customer_id}/accounts?key={API_KEY}",
            headers={"Content-Type": "application/json"},
            json=payload
        )
        if r.status_code in [200, 201]:
            response = r.json()
            if 'objectCreated' in response:
                return response['objectCreated']['_id']
    except Exception as e:
        print(f"      Error: {e}")
    return None

def create_deposits(account_id, customer_id, monthly_salary, months):
    """Crea depósitos mensuales regulares (nómina)"""
    created = 0
    
    # Crear depósitos mensuales consecutivos
    for i in range(months):
        # Fecha: hace (i+1) meses, día 15 de cada mes
        days_ago = (i * 30) + 15
        
        # Variación pequeña en el salario (±5%)
        amount = monthly_salary + randint(-int(monthly_salary*0.05), int(monthly_salary*0.05))
        
        payload = {
            "medium": "balance",
            "amount": amount,
            "transaction_date": get_date_string(days_ago),
            "status": "completed",
            "description": "Payroll Deposit - Company ABC"
        }
        
        try:
            r = requests.post(
                f"{BASE_URL}/accounts/{account_id}/deposits?key={API_KEY}",
                headers={"Content-Type": "application/json"},
                json=payload
            )
            if r.status_code in [200, 201]:
                created += 1
            elif i == 0:  # Solo mostrar error del primer intento
                print(f"      ⚠ Deposit error ({r.status_code}): {r.text[:200]}")
        except Exception as e:
            if i == 0:
                print(f"      ⚠ Deposit exception: {e}")
    
    return created

def create_merchant(merchant_data):
    """Crea un merchant en la API"""
    payload = {
        "name": merchant_data["name"],
        "category": merchant_data["category"],
        "address": {
            "street_number": "100",
            "street_name": "Main St",
            "city": "Mexico City",
            "state": "MX",
            "zip": "01000"
        },
        "geocode": {
            "lat": 19.4326,
            "lng": -99.1332
        }
    }
    
    try:
        r = requests.post(
            f"{BASE_URL}/merchants?key={API_KEY}",
            headers={"Content-Type": "application/json"},
            json=payload
        )
        if r.status_code in [200, 201]:
            response = r.json()
            if 'objectCreated' in response:
                return response['objectCreated']['_id']
        else:
            # Debug: mostrar error solo una vez
            if not hasattr(create_merchant, 'error_shown'):
                print(f"      ⚠ Merchant error ({r.status_code}): {r.text[:150]}")
                create_merchant.error_shown = True
    except Exception as e:
        if not hasattr(create_merchant, 'error_shown'):
            print(f"      ⚠ Merchant exception: {e}")
            create_merchant.error_shown = True
    return None

def create_purchases(account_id, profile):
    """Crea compras basadas en el perfil del cliente"""
    created = 0
    
    # Número de compras basado en perfil
    num_purchases = {
        "excellent": randint(15, 25),
        "good": randint(10, 20),
        "fair": randint(8, 15),
        "poor": randint(5, 12)
    }.get(profile, 10)
    
    # Crear o usar merchants
    merchant_ids = {}
    
    for i in range(num_purchases):
        merchant = choice(MERCHANT_CATEGORIES)
        
        # Crear merchant si no existe
        if merchant["id"] not in merchant_ids:
            merchant_id = create_merchant(merchant)
            if merchant_id:
                merchant_ids[merchant["id"]] = merchant_id
        
        if merchant["id"] not in merchant_ids:
            continue  # Saltar si no se pudo crear el merchant
        
        days_ago = randint(1, 90)  # Últimos 3 meses
        
        # Monto basado en categoría
        amount_ranges = {
            "Supermarket": (50, 300),
            "Gas Station": (30, 80),
            "Restaurant": (15, 100),
            "Pharmacy": (10, 150),
            "Clothing": (100, 500),
            "Electronics": (200, 1500),
            "Entertainment": (50, 200),
            "Utilities": (100, 500)
        }
        
        min_amt, max_amt = amount_ranges.get(merchant["category"], (20, 200))
        amount = round(uniform(min_amt, max_amt), 2)
        
        payload = {
            "merchant_id": merchant_ids[merchant["id"]],
            "medium": "balance",
            "purchase_date": get_date_string(days_ago),
            "amount": amount,
            "status": "completed",
            "description": f"{merchant['name']} - {merchant['category']}"
        }
        
        try:
            r = requests.post(
                f"{BASE_URL}/accounts/{account_id}/purchases?key={API_KEY}",
                headers={"Content-Type": "application/json"},
                json=payload
            )
            if r.status_code in [200, 201]:
                created += 1
            elif i == 0 and created == 0:  # Solo mostrar error del primer intento
                print(f"      ⚠ Purchase error ({r.status_code}): {r.text[:200]}")
        except Exception as e:
            if i == 0 and created == 0:
                print(f"      ⚠ Purchase exception: {e}")
    
    return created

def create_bills(customer_id, account_id, profile):
    """Crea facturas/bills con historial de pagos"""
    created = 0
    
    # Perfiles de pago
    on_time_rates = {
        "excellent": 1.0,    # 100% a tiempo
        "good": 0.95,        # 95% a tiempo
        "fair": 0.80,        # 80% a tiempo
        "poor": 0.60         # 60% a tiempo
    }
    
    # Porcentaje de bills que quedan pendientes (contribuyen a current_debt)
    pending_rates = {
        "excellent": 0.0,    # Sin bills pendientes
        "good": 0.1,         # 10% pendientes
        "fair": 0.25,        # 25% pendientes
        "poor": 0.4          # 40% pendientes
    }
    
    on_time_rate = on_time_rates.get(profile, 0.8)
    pending_rate = pending_rates.get(profile, 0.2)
    
    # Crear facturas de servicios mensuales
    bill_types = [
        {"payee": "CFE", "nickname": "Electricity", "amount_range": (300, 800)},
        {"payee": "Telmex", "nickname": "Internet", "amount_range": (400, 600)},
        {"payee": "Telcel", "nickname": "Phone", "amount_range": (250, 500)},
        {"payee": "Water Utility", "nickname": "Water", "amount_range": (150, 350)},
        {"payee": "Netflix", "nickname": "Streaming", "amount_range": (150, 250)}
    ]
    
    for bill_type in bill_types:
        # Crear últimas 3-6 facturas
        num_bills = randint(3, 6)
        
        for i in range(num_bills):
            # Fecha de pago: cada mes
            payment_days_ago = (i * 30) + 10
            
            # Día recurrente de vencimiento (fijo para cada tipo de bill)
            recurring_day = 5 + (ord(bill_type["payee"][0]) % 20)  # Entre 5 y 25
            
            # Determinar si este bill está pendiente o completado
            is_pending = uniform(0, 1) < pending_rate and i < 2  # Solo los más recientes pueden estar pendientes
            
            if is_pending:
                # Bill pendiente - contribuye a current_debt
                status = choice(["pending", "recurring"])
                # Fecha de vencimiento futura o reciente
                payment_date_obj = datetime.now() + timedelta(days=randint(-5, 15))
                payment_date = payment_date_obj.strftime("%Y-%m-%d")
            else:
                # Bill completado - determinar si se pagó a tiempo
                paid_on_time = uniform(0, 1) < on_time_rate
                
                if paid_on_time:
                    # Pago entre 1-3 días antes del día recurrente
                    payment_day_of_month = max(1, recurring_day - randint(0, 3))
                else:
                    # Pago 5-15 días después del día recurrente (pago tardío)
                    payment_day_of_month = min(28, recurring_day + randint(5, 15))
                
                status = "completed"
                
                # Ajustar la fecha de pago para que tenga el día correcto
                payment_date_obj = datetime.now() - timedelta(days=payment_days_ago)
                try:
                    payment_date_obj = payment_date_obj.replace(day=payment_day_of_month)
                except:
                    payment_date_obj = payment_date_obj.replace(day=28)
                
                payment_date = payment_date_obj.strftime("%Y-%m-%d")
            
            amount = round(uniform(*bill_type["amount_range"]), 2)
            
            payload = {
                "status": status,
                "payee": bill_type["payee"],
                "nickname": bill_type["nickname"],
                "payment_date": payment_date,
                "recurring_date": recurring_day,  # Día del mes para vencimiento
                "payment_amount": amount
            }
            
            try:
                r = requests.post(
                    f"{BASE_URL}/accounts/{account_id}/bills?key={API_KEY}",
                    headers={"Content-Type": "application/json"},
                    json=payload
                )
                if r.status_code in [200, 201]:
                    created += 1
                elif i == 0 and created == 0:  # Solo mostrar error del primer tipo de bill
                    print(f"      ⚠ Bill error ({r.status_code}): {r.text[:200]}")
            except Exception as e:
                if i == 0 and created == 0:
                    print(f"      ⚠ Bill exception: {e}")
    
    return created

# =============================================================================
# PROCESO PRINCIPAL
# =============================================================================

def populate_all_data():
    """Pobla la API con todos los datos de ejemplo"""
    print("=" * 80)
    print("POBLANDO API DE NESSIE CON DATOS DE EJEMPLO")
    print("=" * 80)
    
    total_customers = 0
    total_accounts = 0
    total_deposits = 0
    total_purchases = 0
    total_bills = 0
    
    # Metadata para deuda simulada (la API no permite crear bills pending ni credit con balance negativo)
    debt_metadata = {}
    
    for idx, customer_data in enumerate(SAMPLE_CUSTOMERS, 1):
        print(f"\n[{idx}/{len(SAMPLE_CUSTOMERS)}] Procesando: {customer_data['first_name']} {customer_data['last_name']}")
        print(f"   Perfil: {customer_data['profile'].upper()}")
        
        # 1. Crear cliente
        print(f"   → Creando cliente...")
        customer_id = create_customer(customer_data)
        if not customer_id:
            print(f"   ✗ Error creando cliente")
            continue
        
        print(f"   ✓ Cliente creado: {customer_id}")
        total_customers += 1
        
        # Guardar metadata de deuda simulada (la API no permite crear deuda real)
        credit_debt = abs(credit_debt_levels.get(customer_data["profile"], -2000))
        pending_bills = randint(1, 3) * uniform(300, 600)  # 1-3 bills pendientes
        
        debt_metadata[customer_id] = {
            "profile": customer_data["profile"],
            "simulated_credit_debt": round(credit_debt, 2),
            "simulated_pending_bills": round(pending_bills, 2),
            "total_simulated_debt": round(credit_debt + pending_bills, 2)
        }
        
        # 2. Crear cuenta checking
        print(f"   → Creando cuenta checking...")
        checking_balance = randint(2000, 10000)
        checking_account_id = create_checking_account(customer_id, checking_balance)
        if not checking_account_id:
            print(f"   ✗ Error creando cuenta checking")
            continue
        
        print(f"   ✓ Cuenta checking creada: ${checking_balance}")
        total_accounts += 1
        
        # 3. Crear cuenta de crédito (con deuda según perfil)
        print(f"   → Creando cuenta de crédito...")
        # Definir nivel de deuda según perfil (balance negativo = deuda)
        credit_debt_levels = {
            "excellent": randint(-800, -200),      # Poca deuda
            "good": randint(-1500, -800),          # Deuda moderada
            "fair": randint(-3000, -1500),         # Deuda significativa
            "poor": randint(-5000, -3000)          # Alta deuda
        }
        credit_balance = credit_debt_levels.get(customer_data["profile"], -2000)
        credit_account_id = create_credit_account(customer_id, credit_balance)
        if credit_account_id:
            print(f"   ✓ Cuenta de crédito creada: Balance ${credit_balance} (deuda: ${abs(credit_balance)})")
            total_accounts += 1
        else:
            print(f"   ⚠ No se pudo crear cuenta de crédito")
        
        # 4. Crear depósitos (nómina)
        print(f"   → Creando depósitos mensuales...")
        deposits_created = create_deposits(
            checking_account_id,
            customer_id,
            customer_data["monthly_salary"],
            customer_data["stability_months"]
        )
        print(f"   ✓ {deposits_created} depósitos creados (${customer_data['monthly_salary']}/mes x {customer_data['stability_months']} meses)")
        total_deposits += deposits_created
        
        # 5. Crear compras
        print(f"   → Creando compras...")
        purchases_created = create_purchases(checking_account_id, customer_data["profile"])
        print(f"   ✓ {purchases_created} compras creadas")
        total_purchases += purchases_created
        
        # 6. Crear bills
        print(f"   → Creando bills...")
        bills_created = create_bills(customer_id, checking_account_id, customer_data["profile"])
        print(f"   ✓ {bills_created} bills creados")
        total_bills += bills_created
    
    # Resumen final
    print("\n" + "=" * 80)
    print("RESUMEN DE DATOS CREADOS")
    print("=" * 80)
    print(f"  Clientes:   {total_customers}")
    print(f"  Cuentas:    {total_accounts}")
    print(f"  Depósitos:  {total_deposits}")
    print(f"  Compras:    {total_purchases}")
    print(f"  Bills:      {total_bills}")
    print("=" * 80)
    
    # Guardar metadata de deuda simulada
    if debt_metadata:
        import json
        with open("debt_metadata.json", "w") as f:
            json.dump(debt_metadata, f, indent=2)
        print(f"\n✓ Metadata de deuda guardada en: debt_metadata.json")
        print(f"  (La API Nessie no permite crear deuda real, pero el ETL la simulará)")
    
    print("\n✓ Datos poblados exitosamente!")
    print("  Ahora ejecuta: python etl_customer_data.py")
    print("=" * 80)

if __name__ == "__main__":
    populate_all_data()

