import requests
from datetime import datetime
from collections import defaultdict
import statistics
from typing import Dict, List, Any

API_KEY = "2efca97355951ec13f6acfd0a8806a14"
BASE_URL = "http://api.nessieisreal.com"

# =============================================================================
# FUNCIONES DE EXTRACCIÓN (API CALLS)
# =============================================================================

def get_customers():
    """Obtiene todos los clientes"""
    r = requests.get(f"{BASE_URL}/customers?key={API_KEY}")
    r.raise_for_status()
    return r.json()

def get_accounts(customer_id):
    """Obtiene todas las cuentas de un cliente"""
    r = requests.get(f"{BASE_URL}/customers/{customer_id}/accounts?key={API_KEY}")
    r.raise_for_status()
    return r.json()

def get_deposits(account_id):
    """Obtiene todos los depósitos de una cuenta"""
    r = requests.get(f"{BASE_URL}/accounts/{account_id}/deposits?key={API_KEY}")
    r.raise_for_status()
    return r.json()

def get_bills(customer_id):
    """Obtiene todas las facturas/pagos de un cliente"""
    r = requests.get(f"{BASE_URL}/customers/{customer_id}/bills?key={API_KEY}")
    r.raise_for_status()
    return r.json()

def get_purchases(account_id):
    """Obtiene todas las compras de una cuenta"""
    r = requests.get(f"{BASE_URL}/accounts/{account_id}/purchases?key={API_KEY}")
    r.raise_for_status()
    return r.json()

# =============================================================================
# FUNCIONES DE TRANSFORMACIÓN
# =============================================================================

def calculate_age(birth_date_str):
    """
    Calcula la edad a partir de la fecha de nacimiento
    Formatos esperados: YYYY-MM-DD o timestamp
    Si no hay birth_date, genera una edad aleatoria razonable
    """
    try:
        if not birth_date_str:
            # Generar edad aleatoria entre 25 y 65 años
            from random import randint
            return randint(25, 65)
        birth_date = datetime.strptime(birth_date_str, "%Y-%m-%d")
        today = datetime.now()
        age = today.year - birth_date.year - ((today.month, today.day) < (birth_date.month, birth_date.day))
        return age
    except:
        # Si hay error, generar edad aleatoria
        from random import randint
        return randint(25, 65)

def calculate_monthly_income(deposits):
    """
    Calcula el ingreso mensual basado en depósitos regulares (nómina)
    Identifica depósitos recurrentes y calcula la mediana
    Retorna: (income_monthly, payroll_variance)
    """
    if not deposits:
        return 0, 0
    
    # Agrupar depósitos por originador para identificar nóminas
    deposits_by_originator = defaultdict(list)
    
    for deposit in deposits:
        originator = deposit.get('description', '') or deposit.get('payer_id', 'unknown')
        amount = deposit.get('amount', 0)
        deposits_by_originator[originator].append(amount)
    
    # Identificar el originador más frecuente (probablemente nómina)
    if not deposits_by_originator:
        return 0, 0
    
    most_frequent_originator = max(deposits_by_originator.items(), key=lambda x: len(x[1]))
    regular_deposits = most_frequent_originator[1]
    
    # Calcular mediana de depósitos regulares
    if regular_deposits:
        income = statistics.median(regular_deposits)
        # Calcular varianza (coeficiente de variación)
        if len(regular_deposits) > 1 and income > 0:
            variance = statistics.stdev(regular_deposits) / income
        else:
            variance = 0
        return income, round(variance, 4)
    return 0, 0

def calculate_payment_history(bills):
    """
    Calcula el porcentaje de pagos a tiempo y el máximo de días de retraso
    Retorna: (on_time_rate, max_days_late)
    """
    if not bills:
        return None, 0
    
    on_time_count = 0
    total_paid = 0
    max_days_late = 0
    
    for bill in bills:
        status = bill.get('status', '').lower()
        paid_date_str = bill.get('payment_date')
        due_date_str = bill.get('due_date')
        recurring_date = bill.get('recurring_date')
        
        if status in ['completed', 'paid', 'executed']:
            total_paid += 1
            
            # Opción 1: Si tiene due_date explícito
            if paid_date_str and due_date_str:
                try:
                    paid_date = datetime.strptime(paid_date_str, "%Y-%m-%d")
                    due_date = datetime.strptime(due_date_str, "%Y-%m-%d")
                    
                    days_diff = (paid_date - due_date).days
                    if days_diff > 0:
                        max_days_late = max(max_days_late, days_diff)
                    else:
                        on_time_count += 1
                except:
                    pass
            # Opción 2: Usar recurring_date como día de vencimiento
            elif paid_date_str and recurring_date:
                try:
                    paid_date = datetime.strptime(paid_date_str, "%Y-%m-%d")
                    # Vencimiento = día recurring_date del mes de pago
                    days_late = max(0, paid_date.day - recurring_date - 3)  # 3 días de gracia
                    
                    if days_late > 0:
                        max_days_late = max(max_days_late, days_late)
                    else:
                        on_time_count += 1
                except:
                    on_time_count += 1
            else:
                on_time_count += 1
    
    if total_paid == 0:
        return None, 0
    
    on_time_rate = (on_time_count / total_paid)
    return round(on_time_rate, 4), max_days_late

def calculate_debt_and_utilization(accounts, bills, monthly_income):
    """
    Calcula deuda actual, DTI y utilization
    Usa balances de cuentas y bills pendientes
    Retorna: (current_debt, dti, utilization)
    """
    total_debt = 0
    credit_used = 0
    credit_limit = 0
    
    # Analizar todas las cuentas
    for account in accounts:
        account_type = account.get('type', '').lower()
        balance = account.get('balance', 0)
        
        # Cuentas de crédito
        if 'credit' in account_type or account_type == 'credit card':
            # Balance negativo = deuda
            if balance < 0:
                debt_amount = abs(balance)
                total_debt += debt_amount
                credit_used += debt_amount
                # Estimar límite de crédito: asumiendo 80% utilization si está en deuda
                # Si tiene $1000 de deuda, límite estimado = $1000 / 0.8 = $1250
                estimated_limit = debt_amount / 0.8
                credit_limit += estimated_limit
            else:
                # Balance positivo en cuenta de crédito = crédito disponible
                # El límite es el balance disponible más lo ya usado
                credit_limit += balance
        
        # Préstamos y otras deudas
        elif balance < 0 and account_type in ['loan', 'mortgage', 'auto loan']:
            total_debt += abs(balance)
    
    # Sumar bills pendientes como deuda corriente
    pending_bills = 0
    for bill in bills:
        status = bill.get('status', '').lower()
        if status in ['pending', 'unpaid', 'recurring']:
            amount = bill.get('payment_amount', 0)
            pending_bills += amount
    
    total_debt += pending_bills
    
    # Calcular DTI (debt-to-income ratio)
    # DTI = deuda total mensual / ingreso mensual
    dti = (total_debt / monthly_income) if monthly_income > 0 else 0
    
    # Calcular utilization (crédito usado / límite total de crédito)
    # Solo considera cuentas de crédito, no préstamos
    utilization = (credit_used / credit_limit) if credit_limit > 0 else 0
    
    return round(total_debt, 2), round(dti, 4), round(utilization, 4)

def calculate_employment_stability(deposits):
    """
    Calcula la estabilidad laboral basada en meses consecutivos con depósitos regulares
    """
    if not deposits:
        return 0
    
    # Extraer meses únicos con depósitos
    months_with_deposits = set()
    
    for deposit in deposits:
        date_str = deposit.get('transaction_date') or deposit.get('date')
        if date_str:
            try:
                date = datetime.strptime(date_str, "%Y-%m-%d")
                month_key = f"{date.year}-{date.month:02d}"
                months_with_deposits.add(month_key)
            except:
                pass
    
    # Ordenar meses y contar consecutivos
    if not months_with_deposits:
        return 0
    
    sorted_months = sorted(list(months_with_deposits))
    consecutive_months = 1
    max_consecutive = 1
    
    for i in range(1, len(sorted_months)):
        prev_year, prev_month = map(int, sorted_months[i-1].split('-'))
        curr_year, curr_month = map(int, sorted_months[i].split('-'))
        
        # Verificar si son meses consecutivos
        if (curr_year == prev_year and curr_month == prev_month + 1) or \
           (curr_year == prev_year + 1 and prev_month == 12 and curr_month == 1):
            consecutive_months += 1
            max_consecutive = max(max_consecutive, consecutive_months)
        else:
            consecutive_months = 1
    
    return max_consecutive

def calculate_spending_behavior(purchases):
    """
    Analiza el comportamiento de gasto agrupado por categoría
    Calcula gasto mensual total y variabilidad (últimos 6 meses)
    Retorna gasto promedio, variabilidad y categorías principales
    """
    if not purchases:
        return {
            'average_spending': 0,
            'spending_variability': 0,
            'top_categories': [],
            'spending_by_month': []
        }
    
    # Agrupar por categoría
    spending_by_category = defaultdict(list)
    spending_by_month = defaultdict(float)
    
    for purchase in purchases:
        merchant = purchase.get('merchant', {})
        category = merchant.get('category', 'other') if isinstance(merchant, dict) else 'other'
        amount = purchase.get('amount', 0)
        
        # Categoría
        spending_by_category[category].append(amount)
        
        # Por mes para calcular variabilidad
        purchase_date_str = purchase.get('purchase_date')
        if purchase_date_str:
            try:
                purchase_date = datetime.strptime(purchase_date_str, "%Y-%m-%d")
                month_key = f"{purchase_date.year}-{purchase_date.month:02d}"
                spending_by_month[month_key] += amount
            except:
                pass
    
    # Calcular gasto total
    total_spending = sum(p.get('amount', 0) for p in purchases)
    
    # Calcular gasto mensual promedio (últimos 6 meses o todos los disponibles)
    if spending_by_month:
        monthly_amounts = list(spending_by_month.values())
        avg_monthly_spending = statistics.mean(monthly_amounts)
        # Variabilidad como desviación estándar de gastos mensuales
        spending_var = statistics.stdev(monthly_amounts) if len(monthly_amounts) > 1 else 0
    else:
        # Si no hay información mensual, usar promedio simple
        avg_monthly_spending = total_spending / max(1, len(purchases) / 30)  # Aproximar por días
        spending_var = 0
    
    # Top 3 categorías por gasto total
    category_totals = {cat: sum(amounts) for cat, amounts in spending_by_category.items()}
    top_categories = sorted(category_totals.items(), key=lambda x: x[1], reverse=True)[:3]
    
    return {
        'average_spending': round(avg_monthly_spending, 2),
        'spending_variability': round(spending_var, 2),
        'top_categories': [{'category': cat, 'total': round(total, 2)} for cat, total in top_categories],
        'spending_by_month': dict(spending_by_month)
    }

def calculate_credit_score_proxy(on_time_rate, dti, stability_months):
    """
    Calcula un score proxy de buró de crédito
    Basado en: historial de pagos, DTI y estabilidad laboral
    Escala: 300-850 (similar a FICO)
    """
    score = 300  # Base mínima
    
    # Historial de pagos (35% del score) - hasta 297 puntos
    if on_time_rate is not None:
        score += (on_time_rate / 100) * 297
    
    # Ratio deuda/ingreso (30% del score) - hasta 255 puntos
    if dti is not None:
        if dti <= 0.2:
            score += 255
        elif dti <= 0.36:
            score += 255 * (1 - (dti - 0.2) / 0.16)
        else:
            score += max(0, 255 * (1 - (dti - 0.36) / 0.64))
    
    # Estabilidad laboral (35% del score) - hasta 298 puntos
    # Asumimos que 24+ meses es excelente
    stability_score = min(stability_months / 24, 1.0) * 298
    score += stability_score
    
    return round(min(score, 850), 0)

def get_geographic_risk(address):
    """
    Asocia dirección con índice de riesgo geográfico
    (Implementación simplificada - en producción usar datos reales)
    """
    # Por ahora retorna la dirección/ZIP para análisis posterior
    if not address:
        return None
    
    zip_code = address.get('zip', '') or address.get('zipcode', '')
    state = address.get('state', '')
    
    return {
        'zip_code': zip_code,
        'state': state,
        'full_address': address
    }

def calculate_label(on_time_rate, max_days_late, dti):
    """
    Etiquetado temprano: Clasifica cliente como good (1) o bad (0)
    
    Criterios para label=1 (buen cliente):
    - on_time_rate >= 0.7 (70% de pagos a tiempo)
    - max_days_late <= 10 (máximo 10 días de retraso)
    - dti < 0.5 (deuda/ingreso menor a 50%)
    
    Retorna: 1 (good) o 0 (bad o insuficiente data)
    """
    # Si no hay suficiente información, etiquetar como "insuficiente"
    if on_time_rate is None or on_time_rate == 0:
        return 0  # Sin historial = riesgoso
    
    # Criterios combinados
    is_good_payer = on_time_rate >= 0.7
    is_low_delay = max_days_late <= 10
    is_manageable_debt = dti < 0.5
    
    # Label = 1 solo si cumple TODOS los criterios
    if is_good_payer and is_low_delay and is_manageable_debt:
        return 1
    else:
        return 0

# =============================================================================
# FLUJO PRINCIPAL ETL
# =============================================================================

def process_customer(customer, simulated_debt=None):
    """
    Procesa un cliente individual y extrae todas sus variables
    Retorna formato unificado para el modelo
    
    Args:
        customer: Datos del cliente de la API
        simulated_debt: Dict con deuda simulada (opcional) debido a limitaciones API
    """
    customer_id = customer.get('_id')
    print(f"Procesando cliente: {customer_id}")
    
    if simulated_debt is None:
        simulated_debt = {}
    
    # Variable 1: Edad
    birth_date = customer.get('date_of_birth') or customer.get('birth_date')
    age = calculate_age(birth_date)
    
    # Variable 8: Zona/demografía
    address = customer.get('address')
    zone = address.get('city') if address else 'Unknown'
    
    # Obtener cuentas del cliente
    try:
        accounts = get_accounts(customer_id)
    except Exception as e:
        print(f"  Error obteniendo cuentas: {e}")
        accounts = []
    
    # Obtener bills del cliente
    try:
        bills = get_bills(customer_id)
    except Exception as e:
        print(f"  Error obteniendo bills: {e}")
        bills = []
    
    # Procesar cada cuenta para obtener depósitos y compras
    all_deposits = []
    all_purchases = []
    
    for account in accounts:
        account_id = account.get('_id')
        
        # Obtener depósitos
        try:
            deposits = get_deposits(account_id)
            all_deposits.extend(deposits)
        except Exception as e:
            print(f"  Error obteniendo depósitos de cuenta {account_id}: {e}")
        
        # Obtener compras
        try:
            purchases = get_purchases(account_id)
            all_purchases.extend(purchases)
        except Exception as e:
            print(f"  Error obteniendo compras de cuenta {account_id}: {e}")
    
    # Calcular variables
    income_monthly, payroll_variance = calculate_monthly_income(all_deposits)
    payroll_streak = calculate_employment_stability(all_deposits)
    spending_behavior = calculate_spending_behavior(all_purchases)
    on_time_rate, max_days_late = calculate_payment_history(bills)
    current_debt, dti, utilization = calculate_debt_and_utilization(accounts, bills, income_monthly)
    
    # Aplicar deuda simulada si existe (debido a limitaciones de API Nessie)
    if simulated_debt and income_monthly > 0:
        simulated_total = simulated_debt.get('total_simulated_debt', 0)
        if simulated_total > 0:
            current_debt += simulated_total
            dti = round(current_debt / income_monthly, 4) if income_monthly > 0 else 0
            # Utilization simulada basada en deuda de crédito
            credit_debt = simulated_debt.get('simulated_credit_debt', 0)
            if credit_debt > 0:
                estimated_limit = credit_debt / 0.8  # Asumiendo 80% utilization
                utilization = round(credit_debt / estimated_limit, 4)
    
    # Calcular label (etiquetado temprano)
    label = calculate_label(on_time_rate, max_days_late, dti)
    
    # Construir documento completo (con raw_data)
    full_data = {
        "user_id": customer_id,
        "name": customer.get('first_name', '') + ' ' + customer.get('last_name', ''),
        "age": age,
        "zone": zone,
        "address": customer.get('address'),
        "income_monthly": round(income_monthly, 2),
        "payroll_streak": payroll_streak,
        "payroll_variance": payroll_variance,
        "spending_monthly": spending_behavior.get('average_spending', 0),
        "spending_var_6m": spending_behavior.get('spending_variability', 0),
        "spending_top_categories": spending_behavior.get('top_categories', []),
        "on_time_rate": on_time_rate if on_time_rate is not None else 0,
        "max_days_late": max_days_late,
        "current_debt": current_debt,
        "dti": dti,
        "utilization": utilization,
        "label": label,
        "raw_data": {
            "accounts": accounts,
            "deposits": all_deposits,
            "purchases": all_purchases,
            "bills": bills
        }
    }
    
    # Construir documento para modelo (solo variables necesarias + label)
    model_data = {
        "user_id": customer_id,
        "age": age,
        "zone": zone,
        "income_monthly": round(income_monthly, 2),
        "payroll_streak": payroll_streak,
        "payroll_variance": payroll_variance,
        "spending_monthly": spending_behavior.get('average_spending', 0),
        "spending_var_6m": spending_behavior.get('spending_variability', 0),
        "on_time_rate": on_time_rate if on_time_rate is not None else 0,
        "max_days_late": max_days_late,
        "current_debt": current_debt,
        "dti": dti,
        "utilization": utilization,
        "label": label
    }
    
    return full_data, model_data

def run_etl():
    """
    Ejecuta el proceso ETL completo para todos los clientes
    """
    print("=" * 80)
    print("INICIANDO PROCESO ETL")
    print("=" * 80)
    
    # Cargar metadata de deuda simulada (si existe)
    debt_metadata = {}
    try:
        import os
        if os.path.exists("debt_metadata.json"):
            with open("debt_metadata.json", "r") as f:
                debt_metadata = json.load(f)
            print(f"\n✓ Metadata de deuda cargada para {len(debt_metadata)} clientes")
            print(f"  (Simulando deuda debido a limitaciones de API Nessie)")
    except:
        pass
    
    # Paso 1: Obtener todos los clientes
    print("\nPaso 1: Obteniendo clientes...")
    try:
        customers = get_customers()
        print(f"  ✓ {len(customers)} clientes obtenidos")
    except Exception as e:
        print(f"  ✗ Error obteniendo clientes: {e}")
        return [], []
    
    # Paso 2-4: Procesar cada cliente
    print("\nPaso 2-4: Procesando datos de cada cliente...")
    full_customers = []
    model_customers = []
    
    for i, customer in enumerate(customers, 1):
        print(f"\n[{i}/{len(customers)}]", end=" ")
        try:
            # Pasar metadata de deuda si existe
            customer_id = customer.get('_id')
            simulated_debt = debt_metadata.get(customer_id, {})
            
            full_data, model_data = process_customer(customer, simulated_debt)
            full_customers.append(full_data)
            model_customers.append(model_data)
        except Exception as e:
            print(f"  ✗ Error procesando cliente: {e}")
            continue
    
    print("\n" + "=" * 80)
    print(f"PROCESO ETL COMPLETADO: {len(full_customers)} clientes procesados")
    print("=" * 80)
    
    return full_customers, model_customers

def print_summary(customers_data):
    """
    Imprime un resumen de los datos procesados en el nuevo formato
    """
    print("\n" + "=" * 80)
    print("RESUMEN DE DATOS PROCESADOS (Formato Unificado)")
    print("=" * 80)
    
    for i, customer in enumerate(customers_data[:5], 1):  # Mostrar primeros 5
        print(f"\n--- Cliente {i}: {customer['user_id'][:12]}... ---")
        print(f"  Edad: {customer['age']} años")
        print(f"  Zona: {customer['zone']}")
        print(f"  Ingreso mensual: ${customer['income_monthly']:,.2f}")
        print(f"  Racha de nómina: {customer['payroll_streak']} meses")
        print(f"  Varianza de nómina: {customer['payroll_variance']:.4f}")
        print(f"  Gasto mensual: ${customer['spending_monthly']:,.2f}")
        print(f"  Varianza gasto (6m): {customer['spending_var_6m']:.4f}")
        print(f"  Tasa pagos a tiempo: {customer['on_time_rate']:.2%}")
        print(f"  Máx días de retraso: {customer['max_days_late']}")
        print(f"  Deuda actual: ${customer['current_debt']:,.2f}")
        print(f"  DTI (Debt-to-Income): {customer['dti']:.4f}")
        print(f"  Utilización de crédito: {customer['utilization']:.2%}")
        print(f"  Label: {'✓ GOOD (1)' if customer['label'] == 1 else '✗ BAD (0)'}")
    
    if len(customers_data) > 5:
        print(f"\n... y {len(customers_data) - 5} clientes más")
    
    # Estadísticas de labels
    total_good = sum(1 for c in customers_data if c['label'] == 1)
    total_bad = sum(1 for c in customers_data if c['label'] == 0)
    
    print("\n" + "=" * 80)
    print("DISTRIBUCIÓN DE LABELS")
    print("=" * 80)
    print(f"  ✓ GOOD (label=1): {total_good} clientes ({total_good/len(customers_data)*100:.1f}%)")
    print(f"  ✗ BAD  (label=0): {total_bad} clientes ({total_bad/len(customers_data)*100:.1f}%)")

# =============================================================================
# EJECUCIÓN
# =============================================================================

if __name__ == "__main__":
    # Ejecutar ETL
    full_customers, model_customers = run_etl()
    
    # Mostrar resumen (usando datos del modelo)
    if model_customers:
        print_summary(model_customers)
        
        # Guardar archivo completo (con raw_data)
        import json
        full_output = "customer_data_full.json"
        with open(full_output, 'w', encoding='utf-8') as f:
            json.dump(full_customers, f, indent=2, ensure_ascii=False)
        print(f"\n✓ Datos completos guardados en: {full_output}")
        print(f"  - Contiene: raw_data, name, address, top_categories y todas las variables")
        
        # Guardar archivo para modelo (solo variables necesarias)
        model_output = "customer_data_model.json"
        with open(model_output, 'w', encoding='utf-8') as f:
            json.dump(model_customers, f, indent=2, ensure_ascii=False)
        print(f"\n✓ Datos para modelo guardados en: {model_output}")
        print(f"  - Contiene: Solo las 13 variables necesarias para el modelo")

