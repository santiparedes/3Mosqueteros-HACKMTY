"""
Script para poblar la base de datos PostgreSQL con datos de ejemplo realistas
para el modelo de análisis de crédito.
"""
import psycopg2
import uuid
from datetime import datetime, timedelta
from random import randint, choice, uniform
from db_config import DB_CONFIG

# =============================================================================
# DATOS DE REFERENCIA
# =============================================================================

# Datos originales (mantener)
ORIGINAL_CUSTOMERS = [
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
        "profile": "good",
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
        "profile": "excellent",
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
        "profile": "fair",
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
        "profile": "poor",
        "monthly_salary": 2800,
        "stability_months": 6
    },
    {
        "first_name": "Sofia",
        "last_name": "Lopez",
        "birth_date": "1990-09-10",
        "address": {
            "street_number": "888",
            "street_name": "Madero Ave",
            "city": "Puebla",
            "state": "PUE",
            "zip": "72000"
        },
        "profile": "good",
        "monthly_salary": 5000,
        "stability_months": 18
    }
]

# Datos para generar 100 usuarios adicionales
FIRST_NAMES = [
    "Alejandro", "Andrea", "Diego", "Valentina", "Sebastian", "Camila", "Mateo", "Isabella",
    "Nicolas", "Sofia", "Samuel", "Valeria", "Daniel", "Ximena", "Emiliano", "Regina",
    "Leonardo", "Paola", "Gabriel", "Fernanda", "Adrian", "Daniela", "Javier", "Alejandra",
    "Rodrigo", "Mariana", "Fernando", "Gabriela", "Ricardo", "Natalia", "Eduardo", "Andrea",
    "Roberto", "Monica", "Miguel", "Patricia", "Jose", "Laura", "Francisco", "Carmen",
    "Antonio", "Ana", "Manuel", "Rosa", "David", "Elena", "Carlos", "Isabel", "Rafael", "Maria",
    "Pedro", "Lucia", "Angel", "Beatriz", "Sergio", "Teresa", "Victor", "Claudia", "Raul", "Silvia",
    "Alberto", "Martha", "Enrique", "Guadalupe", "Oscar", "Alicia", "Arturo", "Dolores", "Mario", "Esther",
    "Luis", "Esperanza", "Jorge", "Concepcion", "Hector", "Rosario", "Alfonso", "Pilar", "Ignacio", "Mercedes",
    "Salvador", "Amparo", "Ruben", "Josefina", "Julio", "Consuelo", "Agustin", "Soledad", "Felipe", "Remedios"
]

LAST_NAMES = [
    "Garcia", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Perez", "Sanchez",
    "Ramirez", "Cruz", "Flores", "Gomez", "Diaz", "Reyes", "Morales", "Jimenez", "Ruiz", "Torres",
    "Mendoza", "Vargas", "Castillo", "Romero", "Moreno", "Herrera", "Medina", "Aguilar", "Rivera",
    "Ramos", "Silva", "Castro", "Ortega", "Delgado", "Vega", "Mendez", "Guerrero", "Rojas", "Contreras",
    "Luna", "Espinoza", "Navarro", "Sandoval", "Cortes", "Leal", "Miranda", "Campos", "Vazquez", "Cervantes",
    "Valencia", "Franco", "Cabrera", "Molina", "Herrera", "Ortiz", "Cardenas", "Peña", "Rios", "Estrada",
    "Fuentes", "Vega", "Carrillo", "Salazar", "Montoya", "Ibarra", "Santos", "Robles", "Lara", "Mora",
    "Cervantes", "Valencia", "Franco", "Cabrera", "Molina", "Herrera", "Ortiz", "Cardenas", "Peña", "Rios",
    "Estrada", "Fuentes", "Vega", "Carrillo", "Salazar", "Montoya", "Ibarra", "Santos", "Robles", "Lara"
]

CITIES = [
    {"city": "Mexico City", "state": "MX", "zip": "01000"},
    {"city": "Guadalajara", "state": "JAL", "zip": "44100"},
    {"city": "Monterrey", "state": "NL", "zip": "64000"},
    {"city": "Puebla", "state": "PUE", "zip": "72000"},
    {"city": "Tijuana", "state": "BC", "zip": "22000"},
    {"city": "León", "state": "GTO", "zip": "37000"},
    {"city": "Juárez", "state": "CHH", "zip": "32000"},
    {"city": "Torreón", "state": "COA", "zip": "27000"},
    {"city": "Querétaro", "state": "QRO", "zip": "76000"},
    {"city": "San Luis Potosí", "state": "SLP", "zip": "78000"},
    {"city": "Mérida", "state": "YUC", "zip": "97000"},
    {"city": "Mexicali", "state": "BC", "zip": "21000"},
    {"city": "Aguascalientes", "state": "AGS", "zip": "20000"},
    {"city": "Acapulco", "state": "GRO", "zip": "39300"},
    {"city": "Cancún", "state": "QR", "zip": "77500"}
]

STREET_NAMES = [
    "Reforma", "Insurgentes", "Juarez", "Constitucion", "Madero", "Hidalgo", "Morelos", "Zaragoza",
    "Independencia", "Libertad", "Revolucion", "Nacional", "Federal", "Central", "Principal", "Primera",
    "Segunda", "Tercera", "Cuarta", "Quinta", "Universidad", "Tecnologico", "Industrial", "Comercial",
    "Residencial", "Las Flores", "Los Pinos", "El Sol", "La Luna", "San Jose", "San Pedro", "San Juan"
]

def generate_additional_customers(num_customers=100):
    """Genera clientes adicionales aleatorios"""
    customers = []
    
    for i in range(num_customers):
        # Seleccionar datos aleatorios
        first_name = choice(FIRST_NAMES)
        last_name = choice(LAST_NAMES)
        city_info = choice(CITIES)
        street_name = choice(STREET_NAMES)
        
        # Generar fecha de nacimiento (25-65 años)
        birth_year = randint(1959, 1999)
        birth_month = randint(1, 12)
        birth_day = randint(1, 28)
        birth_date = f"{birth_year}-{birth_month:02d}-{birth_day:02d}"
        
        # Generar dirección
        street_number = str(randint(100, 9999))
        
        # Perfil y salario correlacionados
        profile = choice(["excellent", "good", "fair", "poor"])
        salary_ranges = {
            "excellent": (5000, 8000),
            "good": (4000, 6000),
            "fair": (2500, 4000),
            "poor": (1500, 3000)
        }
        monthly_salary = randint(*salary_ranges[profile])
        
        # Estabilidad laboral correlacionada con perfil
        stability_ranges = {
            "excellent": (24, 60),
            "good": (12, 36),
            "fair": (6, 24),
            "poor": (1, 12)
        }
        stability_months = randint(*stability_ranges[profile])
        
        customer = {
            "first_name": first_name,
            "last_name": last_name,
            "birth_date": birth_date,
            "address": {
                "street_number": street_number,
                "street_name": f"{street_name} Ave",
                "city": city_info["city"],
                "state": city_info["state"],
                "zip": city_info["zip"]
            },
            "profile": profile,
            "monthly_salary": monthly_salary,
            "stability_months": stability_months
        }
        
        customers.append(customer)
    
    return customers

# Combinar clientes originales con los nuevos
SAMPLE_CUSTOMERS = ORIGINAL_CUSTOMERS + generate_additional_customers(100)

MERCHANT_CATEGORIES = [
    {"name": "Walmart", "category": "Supermarket"},
    {"name": "Shell", "category": "Gas Station"},
    {"name": "Starbucks", "category": "Restaurant"},
    {"name": "Farmacia Guadalajara", "category": "Pharmacy"},
    {"name": "Zara", "category": "Clothing"},
    {"name": "Best Buy", "category": "Electronics"},
    {"name": "Cinepolis", "category": "Entertainment"},
    {"name": "Soriana", "category": "Supermarket"},
    {"name": "CFE", "category": "Utilities"}
]

def get_conn():
    """Obtiene una conexión a la base de datos"""
    return psycopg2.connect(**DB_CONFIG)

def generate_id():
    """Genera un ID único"""
    return str(uuid.uuid4())[:24]

def get_date_string(days_ago):
    """Retorna fecha hace X días"""
    date = datetime.now() - timedelta(days=days_ago)
    return date.strftime("%Y-%m-%d")

# =============================================================================
# FUNCIONES DE INSERCIÓN
# =============================================================================

def insert_customer(conn, customer_data):
    """Inserta un cliente en la base de datos"""
    customer_id = generate_id()
    
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO customers (
            customer_id, first_name, last_name, birth_date,
            street_number, street_name, city, state, zip, profile
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, (
        customer_id,
        customer_data['first_name'],
        customer_data['last_name'],
        customer_data['birth_date'],
        customer_data['address']['street_number'],
        customer_data['address']['street_name'],
        customer_data['address']['city'],
        customer_data['address']['state'],
        customer_data['address']['zip'],
        customer_data['profile']
    ))
    cur.close()
    
    return customer_id

def insert_account(conn, customer_id, account_type, balance, credit_limit=None):
    """Inserta una cuenta"""
    account_id = generate_id()
    
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO accounts (
            account_id, customer_id, account_type, balance, 
            credit_limit, nickname, rewards
        ) VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, (
        account_id,
        customer_id,
        account_type,
        balance,
        credit_limit,
        f"{account_type} Account",
        randint(0, 1000)
    ))
    cur.close()
    
    return account_id

def insert_deposits(conn, account_id, monthly_salary, months):
    """Inserta depósitos mensuales (nómina)"""
    cur = conn.cursor()
    created = 0
    
    for i in range(months):
        days_ago = (i * 30) + 15
        amount = monthly_salary + randint(-int(monthly_salary*0.05), int(monthly_salary*0.05))
        
        cur.execute("""
            INSERT INTO deposits (
                account_id, amount, transaction_date, status, description
            ) VALUES (%s, %s, %s, %s, %s)
        """, (
            account_id,
            amount,
            get_date_string(days_ago),
            'completed',
            'Payroll Deposit - Company ABC'
        ))
        created += 1
    
    cur.close()
    return created

def insert_merchants(conn):
    """Inserta merchants si no existen"""
    cur = conn.cursor()
    
    for merchant in MERCHANT_CATEGORIES:
        merchant_id = generate_id()
        
        try:
            cur.execute("""
                INSERT INTO merchants (
                    merchant_id, name, category, 
                    street_number, street_name, city, state, zip
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                merchant_id,
                merchant['name'],
                merchant['category'],
                '100',
                'Main St',
                'Mexico City',
                'MX',
                '01000'
            ))
        except psycopg2.IntegrityError:
            pass  # Ya existe
    
    cur.close()

def get_random_merchant(conn):
    """Obtiene un merchant aleatorio"""
    cur = conn.cursor()
    cur.execute("SELECT merchant_id, category FROM merchants ORDER BY RANDOM() LIMIT 1")
    result = cur.fetchone()
    cur.close()
    return result if result else (None, "other")

def insert_purchases(conn, account_id, profile):
    """Inserta compras"""
    num_purchases = {
        "excellent": randint(15, 25),
        "good": randint(10, 20),
        "fair": randint(8, 15),
        "poor": randint(5, 12)
    }.get(profile, 10)
    
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
    
    cur = conn.cursor()
    created = 0
    
    for i in range(num_purchases):
        merchant_id, category = get_random_merchant(conn)
        if not merchant_id:
            continue
        
        days_ago = randint(1, 90)
        min_amt, max_amt = amount_ranges.get(category, (20, 200))
        amount = round(uniform(min_amt, max_amt), 2)
        
        cur.execute("""
            INSERT INTO purchases (
                account_id, merchant_id, amount, purchase_date, status, description
            ) VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            account_id,
            merchant_id,
            amount,
            get_date_string(days_ago),
            'completed',
            f"Purchase at merchant {category}"
        ))
        created += 1
    
    cur.close()
    return created

def insert_bills(conn, customer_id, account_id, profile):
    """Inserta bills con diferentes estados según el perfil"""
    
    on_time_rates = {
        "excellent": 1.0,
        "good": 0.95,
        "fair": 0.80,
        "poor": 0.60
    }
    
    pending_rates = {
        "excellent": 0.0,
        "good": 0.1,
        "fair": 0.25,
        "poor": 0.4
    }
    
    on_time_rate = on_time_rates.get(profile, 0.8)
    pending_rate = pending_rates.get(profile, 0.2)
    
    bill_types = [
        {"payee": "CFE", "nickname": "Electricity", "amount_range": (300, 800)},
        {"payee": "Telmex", "nickname": "Internet", "amount_range": (400, 600)},
        {"payee": "Telcel", "nickname": "Phone", "amount_range": (250, 500)},
        {"payee": "Water Utility", "nickname": "Water", "amount_range": (150, 350)},
        {"payee": "Netflix", "nickname": "Streaming", "amount_range": (150, 250)}
    ]
    
    cur = conn.cursor()
    created = 0
    
    for bill_type in bill_types:
        num_bills = randint(3, 6)
        
        for i in range(num_bills):
            payment_days_ago = (i * 30) + 10
            recurring_day = 5 + (ord(bill_type["payee"][0]) % 20)
            amount = round(uniform(*bill_type["amount_range"]), 2)
            
            # Determinar si está pendiente
            is_pending = uniform(0, 1) < pending_rate and i < 2
            
            if is_pending:
                status = choice(["pending", "recurring"])
                payment_date_obj = datetime.now() + timedelta(days=randint(-5, 15))
                payment_date = payment_date_obj.strftime("%Y-%m-%d")
                due_date = (datetime.now() + timedelta(days=randint(1, 10))).strftime("%Y-%m-%d")
            else:
                paid_on_time = uniform(0, 1) < on_time_rate
                
                if paid_on_time:
                    payment_day_of_month = max(1, recurring_day - randint(0, 3))
                    due_date_day = recurring_day
                else:
                    payment_day_of_month = min(28, recurring_day + randint(5, 15))
                    due_date_day = recurring_day
                
                status = "completed"
                
                payment_date_obj = datetime.now() - timedelta(days=payment_days_ago)
                due_date_obj = datetime.now() - timedelta(days=payment_days_ago)
                
                try:
                    payment_date_obj = payment_date_obj.replace(day=payment_day_of_month)
                    due_date_obj = due_date_obj.replace(day=due_date_day)
                except:
                    payment_date_obj = payment_date_obj.replace(day=28)
                    due_date_obj = due_date_obj.replace(day=15)
                
                payment_date = payment_date_obj.strftime("%Y-%m-%d")
                due_date = due_date_obj.strftime("%Y-%m-%d")
            
            cur.execute("""
                INSERT INTO bills (
                    customer_id, account_id, payee, nickname, 
                    payment_amount, payment_date, due_date, recurring_date, status
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                customer_id,
                account_id,
                bill_type["payee"],
                bill_type["nickname"],
                amount,
                payment_date,
                due_date,
                recurring_day,
                status
            ))
            created += 1
    
    cur.close()
    return created

# =============================================================================
# PROCESO PRINCIPAL
# =============================================================================

def populate_database():
    """Pobla la base de datos con todos los datos de ejemplo"""
    print("=" * 80)
    print("POBLANDO BASE DE DATOS POSTGRESQL 16")
    print("=" * 80)
    
    conn = get_conn()
    conn.autocommit = False
    
    try:
        # Insertar merchants primero
        print("\n→ Insertando merchants...")
        insert_merchants(conn)
        conn.commit()
        print("  ✓ Merchants creados")
        
        total_customers = 0
        total_accounts = 0
        total_deposits = 0
        total_purchases = 0
        total_bills = 0
        
        for idx, customer_data in enumerate(SAMPLE_CUSTOMERS, 1):
            print(f"\n[{idx}/{len(SAMPLE_CUSTOMERS)}] Procesando: {customer_data['first_name']} {customer_data['last_name']}")
            print(f"   Perfil: {customer_data['profile'].upper()}")
            
            # 1. Insertar cliente
            print(f"   → Creando cliente...")
            customer_id = insert_customer(conn, customer_data)
            total_customers += 1
            print(f"   ✓ Cliente creado: {customer_id}")
            
            # 2. Crear cuenta checking
            print(f"   → Creando cuenta checking...")
            checking_balance = randint(2000, 10000)
            checking_account_id = insert_account(conn, customer_id, "Checking", checking_balance)
            total_accounts += 1
            print(f"   ✓ Cuenta checking creada: ${checking_balance}")
            
            # 3. Crear cuenta de crédito CON DEUDA
            print(f"   → Creando cuenta de crédito con deuda...")
            credit_debt_levels = {
                "excellent": -randint(200, 800),
                "good": -randint(800, 1500),
                "fair": -randint(1500, 3000),
                "poor": -randint(3000, 5000)
            }
            credit_balance = credit_debt_levels.get(customer_data["profile"], -2000)
            credit_limit_value = abs(credit_balance) / 0.75  # Límite basado en utilización del 75%
            
            credit_account_id = insert_account(
                conn, customer_id, "Credit Card", credit_balance, credit_limit_value
            )
            total_accounts += 1
            print(f"   ✓ Cuenta de crédito creada: Balance ${credit_balance} (deuda: ${abs(credit_balance)})")
            print(f"     Límite de crédito: ${credit_limit_value:.2f}")
            
            # 4. Crear depósitos
            print(f"   → Creando depósitos mensuales...")
            deposits_created = insert_deposits(
                conn,
                checking_account_id,
                customer_data["monthly_salary"],
                customer_data["stability_months"]
            )
            total_deposits += deposits_created
            print(f"   ✓ {deposits_created} depósitos creados")
            
            # 5. Crear compras
            print(f"   → Creando compras...")
            purchases_created = insert_purchases(conn, checking_account_id, customer_data["profile"])
            total_purchases += purchases_created
            print(f"   ✓ {purchases_created} compras creadas")
            
            # 6. Crear bills (incluyendo pendientes)
            print(f"   → Creando bills...")
            bills_created = insert_bills(conn, customer_id, checking_account_id, customer_data["profile"])
            total_bills += bills_created
            print(f"   ✓ {bills_created} bills creados")
            
            # Commit después de cada cliente
            conn.commit()
        
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
        print("\n✓ Datos poblados exitosamente en PostgreSQL!")
        print("  Ahora ejecuta: python etl_from_db.py")
        print("=" * 80)
        
    except Exception as e:
        conn.rollback()
        print(f"\n✗ Error: {e}")
        raise
    finally:
        conn.close()

if __name__ == "__main__":
    populate_database()

