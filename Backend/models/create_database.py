"""
Script para crear la base de datos PostgreSQL con el esquema completo
"""
import psycopg2
from psycopg2 import sql

# Configuración de la base de datos
DB_CONFIG = {
    'dbname': 'credit_analysis',
    'user': 'postgres',
    'password': 'postgres',
    'host': 'localhost',
    'port': '5432'
}

def create_database():
    """Crea la base de datos si no existe"""
    try:
        # Conectar a la base de datos por defecto para crear la nueva
        conn = psycopg2.connect(
            dbname='postgres',
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password'],
            host=DB_CONFIG['host'],
            port=DB_CONFIG['port']
        )
        conn.autocommit = True
        cur = conn.cursor()
        
        # Verificar si existe
        cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (DB_CONFIG['dbname'],))
        exists = cur.fetchone()
        
        if not exists:
            cur.execute(sql.SQL("CREATE DATABASE {}").format(
                sql.Identifier(DB_CONFIG['dbname'])
            ))
            print(f"✓ Base de datos '{DB_CONFIG['dbname']}' creada")
        else:
            print(f"✓ Base de datos '{DB_CONFIG['dbname']}' ya existe")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error creando base de datos: {e}")
        raise

def create_schema():
    """Crea el esquema de tablas"""
    
    schema_sql = """
    -- Tabla de clientes
    CREATE TABLE IF NOT EXISTS customers (
        customer_id VARCHAR(50) PRIMARY KEY,
        first_name VARCHAR(100),
        last_name VARCHAR(100),
        birth_date DATE,
        street_number VARCHAR(20),
        street_name VARCHAR(200),
        city VARCHAR(100),
        state VARCHAR(50),
        zip VARCHAR(20),
        profile VARCHAR(20),  -- excellent, good, fair, poor
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabla de cuentas
    CREATE TABLE IF NOT EXISTS accounts (
        account_id VARCHAR(50) PRIMARY KEY,
        customer_id VARCHAR(50) REFERENCES customers(customer_id) ON DELETE CASCADE,
        account_type VARCHAR(50),  -- Checking, Savings, Credit Card, Loan
        balance DECIMAL(12, 2),
        credit_limit DECIMAL(12, 2),  -- Solo para cuentas de crédito
        nickname VARCHAR(100),
        rewards INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabla de depósitos (nómina)
    CREATE TABLE IF NOT EXISTS deposits (
        deposit_id SERIAL PRIMARY KEY,
        account_id VARCHAR(50) REFERENCES accounts(account_id) ON DELETE CASCADE,
        amount DECIMAL(12, 2),
        transaction_date DATE,
        status VARCHAR(20) DEFAULT 'completed',
        description TEXT,
        payer_id VARCHAR(50),
        medium VARCHAR(20) DEFAULT 'balance',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabla de merchants
    CREATE TABLE IF NOT EXISTS merchants (
        merchant_id VARCHAR(50) PRIMARY KEY,
        name VARCHAR(200),
        category VARCHAR(100),
        street_number VARCHAR(20),
        street_name VARCHAR(200),
        city VARCHAR(100),
        state VARCHAR(50),
        zip VARCHAR(20),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabla de compras
    CREATE TABLE IF NOT EXISTS purchases (
        purchase_id SERIAL PRIMARY KEY,
        account_id VARCHAR(50) REFERENCES accounts(account_id) ON DELETE CASCADE,
        merchant_id VARCHAR(50) REFERENCES merchants(merchant_id),
        amount DECIMAL(12, 2),
        purchase_date DATE,
        status VARCHAR(20) DEFAULT 'completed',
        description TEXT,
        medium VARCHAR(20) DEFAULT 'balance',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabla de bills/facturas
    CREATE TABLE IF NOT EXISTS bills (
        bill_id SERIAL PRIMARY KEY,
        customer_id VARCHAR(50) REFERENCES customers(customer_id) ON DELETE CASCADE,
        account_id VARCHAR(50) REFERENCES accounts(account_id) ON DELETE CASCADE,
        payee VARCHAR(200),
        nickname VARCHAR(100),
        payment_amount DECIMAL(12, 2),
        payment_date DATE,
        due_date DATE,
        recurring_date INTEGER,  -- Día del mes (1-28)
        status VARCHAR(20),  -- pending, completed, recurring
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Índices para mejorar performance
    CREATE INDEX IF NOT EXISTS idx_accounts_customer ON accounts(customer_id);
    CREATE INDEX IF NOT EXISTS idx_deposits_account ON deposits(account_id);
    CREATE INDEX IF NOT EXISTS idx_purchases_account ON purchases(account_id);
    CREATE INDEX IF NOT EXISTS idx_bills_customer ON bills(customer_id);
    CREATE INDEX IF NOT EXISTS idx_bills_account ON bills(account_id);
    CREATE INDEX IF NOT EXISTS idx_deposits_date ON deposits(transaction_date);
    CREATE INDEX IF NOT EXISTS idx_purchases_date ON purchases(purchase_date);
    CREATE INDEX IF NOT EXISTS idx_bills_status ON bills(status);
    """
    
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        
        # Ejecutar el schema
        cur.execute(schema_sql)
        conn.commit()
        
        print("✓ Esquema de tablas creado exitosamente")
        print("\nTablas creadas:")
        print("  - customers")
        print("  - accounts")
        print("  - deposits")
        print("  - merchants")
        print("  - purchases")
        print("  - bills")
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"Error creando esquema: {e}")
        raise

def drop_all_tables():
    """Elimina todas las tablas (útil para resetear)"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        
        cur.execute("""
            DROP TABLE IF EXISTS bills CASCADE;
            DROP TABLE IF EXISTS purchases CASCADE;
            DROP TABLE IF EXISTS deposits CASCADE;
            DROP TABLE IF EXISTS merchants CASCADE;
            DROP TABLE IF EXISTS accounts CASCADE;
            DROP TABLE IF EXISTS customers CASCADE;
        """)
        
        conn.commit()
        print("✓ Todas las tablas eliminadas")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error eliminando tablas: {e}")
        raise

if __name__ == "__main__":
    print("=" * 80)
    print("CONFIGURACIÓN DE BASE DE DATOS POSTGRESQL 16")
    print("=" * 80)
    
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "--reset":
        print("\n⚠️  MODO RESET: Eliminando todas las tablas...")
        try:
            drop_all_tables()
        except:
            pass  # La BD puede no existir aún
    
    print("\n1. Creando base de datos...")
    create_database()
    
    print("\n2. Creando esquema de tablas...")
    create_schema()
    
    print("\n" + "=" * 80)
    print("✓ BASE DE DATOS LISTA (PostgreSQL 16)")
    print("=" * 80)
    print(f"\nConexión:")
    print(f"  Host: {DB_CONFIG['host']}:{DB_CONFIG['port']}")
    print(f"  Database: {DB_CONFIG['dbname']}")
    print(f"  User: {DB_CONFIG['user']}")
    print("\nPara resetear la base de datos:")
    print("  python create_database.py --reset")
    print("\nAsegúrate de tener PostgreSQL 16 instalado:")
    print("  brew install postgresql@16")
    print("  brew services start postgresql@16")

