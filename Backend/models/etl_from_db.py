"""
Script ETL que extrae datos de PostgreSQL, transforma y genera archivos JSON
para el modelo de análisis de crédito.
"""
import psycopg2
import json
import statistics
from datetime import datetime
from collections import defaultdict
from random import randint
from db_config import DB_CONFIG

# =============================================================================
# FUNCIONES DE EXTRACCIÓN (Extract)
# =============================================================================

def get_conn():
    """Obtiene conexión a la base de datos"""
    return psycopg2.connect(**DB_CONFIG)

def get_all_customers(conn):
    """Obtiene todos los clientes"""
    cur = conn.cursor()
    cur.execute("""
        SELECT customer_id, first_name, last_name, birth_date,
               street_number, street_name, city, state, zip, profile
        FROM customers
        ORDER BY customer_id
    """)
    
    columns = [desc[0] for desc in cur.description]
    customers = []
    
    for row in cur.fetchall():
        customer = dict(zip(columns, row))
        # Convertir date a string
        if customer['birth_date']:
            customer['birth_date'] = customer['birth_date'].strftime('%Y-%m-%d')
        customers.append(customer)
    
    cur.close()
    return customers

def get_customer_accounts(conn, customer_id):
    """Obtiene todas las cuentas de un cliente"""
    cur = conn.cursor()
    cur.execute("""
        SELECT account_id, customer_id, account_type, balance, 
               credit_limit, nickname, rewards
        FROM accounts
        WHERE customer_id = %s
    """, (customer_id,))
    
    columns = [desc[0] for desc in cur.description]
    accounts = []
    
    for row in cur.fetchall():
        account = dict(zip(columns, row))
        # Convertir Decimal a float
        account['balance'] = float(account['balance'])
        if account['credit_limit']:
            account['credit_limit'] = float(account['credit_limit'])
        accounts.append(account)
    
    cur.close()
    return accounts

def get_account_deposits(conn, account_id):
    """Obtiene todos los depósitos de una cuenta"""
    cur = conn.cursor()
    cur.execute("""
        SELECT deposit_id, account_id, amount, transaction_date, 
               status, description, payer_id, medium
        FROM deposits
        WHERE account_id = %s
        ORDER BY transaction_date DESC
    """, (account_id,))
    
    columns = [desc[0] for desc in cur.description]
    deposits = []
    
    for row in cur.fetchall():
        deposit = dict(zip(columns, row))
        deposit['amount'] = float(deposit['amount'])
        if deposit['transaction_date']:
            deposit['transaction_date'] = deposit['transaction_date'].strftime('%Y-%m-%d')
        deposits.append(deposit)
    
    cur.close()
    return deposits

def get_account_purchases(conn, account_id):
    """Obtiene todas las compras de una cuenta con merchant info"""
    cur = conn.cursor()
    cur.execute("""
        SELECT p.purchase_id, p.account_id, p.merchant_id, p.amount,
               p.purchase_date, p.status, p.description, p.medium,
               m.name as merchant_name, m.category as merchant_category
        FROM purchases p
        LEFT JOIN merchants m ON p.merchant_id = m.merchant_id
        WHERE p.account_id = %s
        ORDER BY p.purchase_date DESC
    """, (account_id,))
    
    columns = [desc[0] for desc in cur.description]
    purchases = []
    
    for row in cur.fetchall():
        purchase = dict(zip(columns, row))
        purchase['amount'] = float(purchase['amount'])
        if purchase['purchase_date']:
            purchase['purchase_date'] = purchase['purchase_date'].strftime('%Y-%m-%d')
        purchases.append(purchase)
    
    cur.close()
    return purchases

def get_customer_bills(conn, customer_id):
    """Obtiene todos los bills de un cliente"""
    cur = conn.cursor()
    cur.execute("""
        SELECT bill_id, customer_id, account_id, payee, nickname,
               payment_amount, payment_date, due_date, recurring_date, status
        FROM bills
        WHERE customer_id = %s
        ORDER BY payment_date DESC
    """, (customer_id,))
    
    columns = [desc[0] for desc in cur.description]
    bills = []
    
    for row in cur.fetchall():
        bill = dict(zip(columns, row))
        bill['payment_amount'] = float(bill['payment_amount'])
        if bill['payment_date']:
            bill['payment_date'] = bill['payment_date'].strftime('%Y-%m-%d')
        if bill['due_date']:
            bill['due_date'] = bill['due_date'].strftime('%Y-%m-%d')
        bills.append(bill)
    
    cur.close()
    return bills

# =============================================================================
# FUNCIONES DE TRANSFORMACIÓN (Transform)
# =============================================================================

def calculate_age(birth_date_str):
    """Calcula la edad a partir de la fecha de nacimiento"""
    if not birth_date_str:
        return randint(25, 65)
    
    try:
        birth_date = datetime.strptime(birth_date_str, "%Y-%m-%d")
        today = datetime.now()
        age = today.year - birth_date.year
        if (today.month, today.day) < (birth_date.month, birth_date.day):
            age -= 1
        return age
    except:
        return randint(25, 65)

def calculate_monthly_income(deposits):
    """
    Calcula ingreso mensual y varianza de nómina
    Retorna: (income_monthly, payroll_variance)
    """
    if not deposits:
        return 0, 0
    
    deposits_by_originator = defaultdict(list)
    
    for deposit in deposits:
        originator = deposit.get('description', '') or deposit.get('payer_id', 'unknown')
        amount = deposit.get('amount', 0)
        deposits_by_originator[originator].append(amount)
    
    if not deposits_by_originator:
        return 0, 0
    
    most_frequent_originator = max(deposits_by_originator.items(), key=lambda x: len(x[1]))
    regular_deposits = most_frequent_originator[1]
    
    if regular_deposits:
        income = statistics.median(regular_deposits)
        if len(regular_deposits) > 1 and income > 0:
            variance = statistics.stdev(regular_deposits) / income
        else:
            variance = 0
        return income, round(variance, 4)
    return 0, 0

def calculate_employment_stability(deposits):
    """Calcula meses consecutivos con depósitos"""
    if not deposits:
        return 0
    
    dates = []
    for deposit in deposits:
        date_str = deposit.get('transaction_date')
        if date_str:
            try:
                date = datetime.strptime(date_str, "%Y-%m-%d")
                dates.append(date)
            except:
                pass
    
    if not dates:
        return 0
    
    dates.sort()
    months_set = set((d.year, d.month) for d in dates)
    return len(months_set)

def calculate_payment_history(bills):
    """
    Calcula tasa de pagos a tiempo y máximo de días de retraso
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
        
        if status in ['completed', 'paid', 'executed']:
            total_paid += 1
            
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
                    on_time_count += 1
            else:
                on_time_count += 1
    
    if total_paid == 0:
        return None, 0
    
    on_time_rate = (on_time_count / total_paid)
    return round(on_time_rate, 4), max_days_late

def calculate_debt_and_utilization(accounts, bills, monthly_income):
    """
    Calcula deuda actual, DTI y utilization usando cuentas de crédito y bills pendientes
    Retorna: (current_debt, dti, utilization)
    """
    total_debt = 0
    credit_used = 0
    credit_limit = 0
    
    for account in accounts:
        account_type = account.get('account_type', '').lower()
        balance = account.get('balance', 0)
        limit = account.get('credit_limit', 0)
        
        # Cuentas de crédito con balance negativo = deuda
        if 'credit' in account_type:
            if balance < 0:
                debt_amount = abs(balance)
                total_debt += debt_amount
                credit_used += debt_amount
            
            # Usar límite de crédito real de la BD
            if limit and limit > 0:
                credit_limit += limit
        
        # Préstamos
        elif balance < 0 and account_type in ['loan', 'mortgage', 'auto loan']:
            total_debt += abs(balance)
    
    # Sumar bills pendientes
    for bill in bills:
        status = bill.get('status', '').lower()
        if status in ['pending', 'unpaid', 'recurring']:
            amount = bill.get('payment_amount', 0)
            total_debt += amount
    
    # Calcular DTI y utilization
    dti = (total_debt / monthly_income) if monthly_income > 0 else 0
    utilization = (credit_used / credit_limit) if credit_limit > 0 else 0
    
    return round(total_debt, 2), round(dti, 4), round(utilization, 4)

def calculate_spending_behavior(purchases):
    """
    Analiza comportamiento de gasto por categoría
    Retorna: dict con average_spending, spending_variability, top_categories, spending_by_month
    """
    if not purchases:
        return {
            'average_spending': 0,
            'spending_variability': 0,
            'top_categories': [],
            'spending_by_month': []
        }
    
    spending_by_category = defaultdict(list)
    spending_by_month = defaultdict(float)
    
    for purchase in purchases:
        category = purchase.get('merchant_category', 'other')
        amount = purchase.get('amount', 0)
        
        spending_by_category[category].append(amount)
        
        purchase_date_str = purchase.get('purchase_date')
        if purchase_date_str:
            try:
                purchase_date = datetime.strptime(purchase_date_str, "%Y-%m-%d")
                month_key = f"{purchase_date.year}-{purchase_date.month:02d}"
                spending_by_month[month_key] += amount
            except:
                pass
    
    total_spending = sum(p.get('amount', 0) for p in purchases)
    
    if spending_by_month:
        monthly_amounts = list(spending_by_month.values())
        avg_monthly_spending = statistics.mean(monthly_amounts)
        spending_var = statistics.stdev(monthly_amounts) if len(monthly_amounts) > 1 else 0
    else:
        avg_monthly_spending = total_spending / max(1, len(purchases) / 30)
        spending_var = 0
    
    category_totals = {cat: sum(amounts) for cat, amounts in spending_by_category.items()}
    top_categories = sorted(category_totals.items(), key=lambda x: x[1], reverse=True)[:3]
    
    return {
        'average_spending': round(avg_monthly_spending, 2),
        'spending_variability': round(spending_var, 2),
        'top_categories': [{'category': cat, 'total': round(total, 2)} for cat, total in top_categories],
        'spending_by_month': dict(spending_by_month)
    }

def calculate_label(on_time_rate, max_days_late, dti):
    """
    Etiquetado: 1 = buen cliente, 0 = mal cliente
    """
    if on_time_rate is None or on_time_rate == 0:
        return 0
    
    is_good_payer = on_time_rate >= 0.7
    is_low_delay = max_days_late <= 10
    is_manageable_debt = dti < 0.5
    
    if is_good_payer and is_low_delay and is_manageable_debt:
        return 1
    else:
        return 0

# =============================================================================
# PROCESO ETL PRINCIPAL
# =============================================================================

def process_customer(conn, customer):
    """Procesa un cliente y extrae todas sus variables"""
    customer_id = customer['customer_id']
    print(f"Procesando cliente: {customer_id}")
    
    # Variable 1: Edad
    age = calculate_age(customer.get('birth_date'))
    
    # Variable 8: Zona
    zone = customer.get('city', 'Unknown')
    
    # Obtener datos relacionados
    accounts = get_customer_accounts(conn, customer_id)
    bills = get_customer_bills(conn, customer_id)
    
    # Obtener depósitos y compras de todas las cuentas
    all_deposits = []
    all_purchases = []
    
    for account in accounts:
        account_id = account['account_id']
        deposits = get_account_deposits(conn, account_id)
        purchases = get_account_purchases(conn, account_id)
        all_deposits.extend(deposits)
        all_purchases.extend(purchases)
    
    # Calcular variables
    income_monthly, payroll_variance = calculate_monthly_income(all_deposits)
    payroll_streak = calculate_employment_stability(all_deposits)
    spending_behavior = calculate_spending_behavior(all_purchases)
    on_time_rate, max_days_late = calculate_payment_history(bills)
    current_debt, dti, utilization = calculate_debt_and_utilization(accounts, bills, income_monthly)
    
    # Calcular label
    label = calculate_label(on_time_rate, max_days_late, dti)
    
    # Documento completo (con raw_data)
    full_data = {
        "user_id": customer_id,
        "name": f"{customer.get('first_name', '')} {customer.get('last_name', '')}",
        "age": age,
        "zone": zone,
        "address": {
            "street_number": customer.get('street_number'),
            "street_name": customer.get('street_name'),
            "city": customer.get('city'),
            "state": customer.get('state'),
            "zip": customer.get('zip')
        },
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
    
    # Documento para modelo (solo variables necesarias)
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
    """Ejecuta el proceso ETL completo desde PostgreSQL"""
    print("=" * 80)
    print("INICIANDO PROCESO ETL DESDE POSTGRESQL 16")
    print("=" * 80)
    
    try:
        conn = get_conn()
        print(f"\n✓ Conectado a PostgreSQL: {DB_CONFIG['dbname']}")
    except Exception as e:
        print(f"\n✗ Error conectando a PostgreSQL: {e}")
        print("\nAsegúrate de:")
        print("  1. PostgreSQL 16 está corriendo: brew services start postgresql@16")
        print("  2. La base de datos existe: python create_database.py")
        print("  3. Hay datos: python populate_data_db.py")
        return [], []
    
    # Paso 1: Obtener todos los clientes
    print("\nPaso 1: Obteniendo clientes...")
    try:
        customers = get_all_customers(conn)
        print(f"  ✓ {len(customers)} clientes obtenidos")
    except Exception as e:
        print(f"  ✗ Error obteniendo clientes: {e}")
        conn.close()
        return [], []
    
    # Paso 2-4: Procesar cada cliente
    print("\nPaso 2-4: Procesando datos de cada cliente...")
    full_customers = []
    model_customers = []
    
    for i, customer in enumerate(customers, 1):
        print(f"\n[{i}/{len(customers)}]", end=" ")
        try:
            full_data, model_data = process_customer(conn, customer)
            full_customers.append(full_data)
            model_customers.append(model_data)
        except Exception as e:
            print(f"  ✗ Error procesando cliente: {e}")
            continue
    
    conn.close()
    
    print("\n" + "=" * 80)
    print(f"PROCESO ETL COMPLETADO: {len(full_customers)} clientes procesados")
    print("=" * 80)
    
    return full_customers, model_customers

def print_summary(model_customers):
    """Imprime resumen de los datos procesados"""
    if not model_customers:
        return
    
    print("\n" + "=" * 80)
    print("RESUMEN DE DATOS PROCESADOS")
    print("=" * 80)
    
    total = len(model_customers)
    with_income = [c for c in model_customers if c['income_monthly'] > 0]
    with_debt = [c for c in model_customers if c['current_debt'] > 0]
    good_clients = [c for c in model_customers if c['label'] == 1]
    bad_clients = [c for c in model_customers if c['label'] == 0]
    
    print(f"\n📊 Total de clientes: {total}")
    print(f"   - Con ingresos > $0: {len(with_income)} ({len(with_income)/total*100:.1f}%)")
    print(f"   - Con deuda > $0: {len(with_debt)} ({len(with_debt)/total*100:.1f}%)")
    print(f"   - Label GOOD (1): {len(good_clients)} ({len(good_clients)/total*100:.1f}%)")
    print(f"   - Label BAD (0): {len(bad_clients)} ({len(bad_clients)/total*100:.1f}%)")
    
    if with_income:
        incomes = [c['income_monthly'] for c in with_income]
        print(f"\n💰 Estadísticas de Ingresos:")
        print(f"   - Promedio: ${sum(incomes)/len(incomes):,.2f}")
        print(f"   - Min: ${min(incomes):,.2f}")
        print(f"   - Max: ${max(incomes):,.2f}")
    
    if with_debt:
        debts = [c['current_debt'] for c in with_debt]
        dtis = [c['dti'] for c in with_debt]
        utils = [c['utilization'] for c in with_debt if c['utilization'] > 0]
        
        print(f"\n💳 Estadísticas de Deuda:")
        print(f"   - Deuda promedio: ${sum(debts)/len(debts):,.2f}")
        print(f"   - DTI promedio: {sum(dtis)/len(dtis):.4f}")
        if utils:
            print(f"   - Utilization promedio: {sum(utils)/len(utils):.4f}")
    
    print("\n" + "=" * 80)

if __name__ == "__main__":
    # Ejecutar ETL
    full_customers, model_customers = run_etl()
    
    if model_customers:
        print_summary(model_customers)
        
        # Guardar archivos
        full_output = "customer_data_full.json"
        with open(full_output, 'w', encoding='utf-8') as f:
            json.dump(full_customers, f, indent=2, ensure_ascii=False)
        print(f"\n✓ Datos completos guardados en: {full_output}")
        
        model_output = "customer_data_model.json"
        with open(model_output, 'w', encoding='utf-8') as f:
            json.dump(model_customers, f, indent=2, ensure_ascii=False)
        print(f"✓ Datos para modelo guardados en: {model_output}")
        print("\n" + "=" * 80)

