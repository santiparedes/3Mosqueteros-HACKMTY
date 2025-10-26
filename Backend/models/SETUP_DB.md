# Setup PostgreSQL 16 para Proyecto de Crédito

## 📋 Requisitos

- macOS
- PostgreSQL 16
- Python 3.8+

## 🚀 Instalación

### 1. Instalar PostgreSQL 16

```bash
# Instalar PostgreSQL 16 con Homebrew
brew install postgresql@16

# Iniciar el servicio
brew services start postgresql@16

# Verificar que está corriendo
brew services list | grep postgresql
```

### 2. Configurar PostgreSQL

```bash
# Crear usuario postgres (si no existe)
createuser -s postgres

# Opcional: Cambiar contraseña
psql postgres -c "ALTER USER postgres WITH PASSWORD 'postgres';"
```

### 3. Instalar Dependencias de Python

```bash
# Activar el entorno virtual
source venv/bin/activate

# Instalar psycopg2
pip install psycopg2-binary
```

## 🗄️ Crear Base de Datos

### Paso 1: Crear la estructura

```bash
python create_database.py
```

Esto creará:
- Base de datos: `credit_analysis`
- Tablas: `customers`, `accounts`, `deposits`, `merchants`, `purchases`, `bills`
- Índices optimizados

### Paso 2: Poblar con datos

```bash
python populate_data_db.py
```

Esto insertará:
- ✅ 5 clientes con diferentes perfiles (excellent, good, fair, poor)
- ✅ Cuentas checking y de **crédito CON DEUDA REAL**
- ✅ Depósitos mensuales (nómina)
- ✅ Compras en diferentes categorías
- ✅ **Bills pendientes** según el perfil

### Paso 3: Ejecutar ETL

```bash
python etl_from_db.py
```

Esto generará:
- `customer_data_full.json` - Datos completos
- `customer_data_model.json` - Datos listos para el modelo

## 🔧 Comandos Útiles

### Resetear la base de datos

```bash
python create_database.py --reset
```

### Conectarse manualmente a PostgreSQL

```bash
psql -U postgres -d credit_analysis
```

### Ver datos en la base

```sql
-- Ver todos los clientes
SELECT customer_id, first_name, last_name, profile FROM customers;

-- Ver cuentas con deuda
SELECT customer_id, account_type, balance, credit_limit 
FROM accounts 
WHERE balance < 0;

-- Ver bills pendientes
SELECT customer_id, payee, payment_amount, status 
FROM bills 
WHERE status IN ('pending', 'recurring');

-- Estadísticas de deuda por perfil
SELECT 
    c.profile,
    COUNT(*) as num_clientes,
    AVG(a.balance) as promedio_balance,
    SUM(CASE WHEN a.balance < 0 THEN ABS(a.balance) ELSE 0 END) as total_deuda
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
WHERE a.account_type = 'Credit Card'
GROUP BY c.profile;
```

## 📊 Verificación

Para verificar que todo está correcto:

```bash
# Ver resumen de datos
psql -U postgres -d credit_analysis -c "
SELECT 
    'Customers' as table_name, COUNT(*) as count FROM customers
UNION ALL
SELECT 'Accounts', COUNT(*) FROM accounts
UNION ALL
SELECT 'Deposits', COUNT(*) FROM deposits
UNION ALL
SELECT 'Purchases', COUNT(*) FROM purchases
UNION ALL
SELECT 'Bills', COUNT(*) FROM bills;
"
```

## 🐛 Troubleshooting

### Error: "connection refused"

```bash
# Verificar que PostgreSQL está corriendo
brew services list

# Reiniciar el servicio
brew services restart postgresql@16
```

### Error: "role 'postgres' does not exist"

```bash
createuser -s postgres
```

### Error: "database does not exist"

```bash
python create_database.py
```

## 🔐 Configuración

La configuración está en `db_config.py`:

```python
DB_CONFIG = {
    'dbname': 'credit_analysis',
    'user': 'postgres',
    'password': 'postgres',
    'host': 'localhost',
    'port': '5432'
}
```

Puedes modificarla según tu configuración local.

## 📝 Ventajas sobre Nessie API

✅ **Control Total**: Podemos crear cuentas con balance negativo (deuda real)  
✅ **Bills Pendientes**: Podemos marcar bills como 'pending' o 'recurring'  
✅ **Fechas de Vencimiento**: Control completo sobre `due_date` y cálculo de retrasos  
✅ **Sin Limitaciones**: No dependemos de restricciones de API sandbox  
✅ **Performance**: Consultas SQL optimizadas con índices  
✅ **Datos Persistentes**: Los datos permanecen entre ejecuciones  

