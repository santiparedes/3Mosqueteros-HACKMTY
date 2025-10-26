# ✅ Migración Completa: Nessie API → PostgreSQL 16

## 🎯 Problema Resuelto

La API de Nessie tiene limitaciones críticas:
- ❌ No permite cuentas de crédito con balance negativo (deuda real)
- ❌ No permite bills en estado "pending" 
- ❌ No permite especificar `due_date` en bills
- ❌ Difícil calcular `current_debt`, `dti` y `utilization` correctamente

## ✅ Solución: Base de Datos PostgreSQL 16

Control total sobre todos los datos con esquema completo y flexible.

---

## 📂 Archivos Creados

### 1. Configuración y Setup

| Archivo | Descripción |
|---------|-------------|
| `db_config.py` | Configuración de conexión a PostgreSQL |
| `create_database.py` | Crea la base de datos y esquema completo |
| `setup_postgresql.sh` | Script bash para instalación automática |
| `SETUP_DB.md` | Documentación completa de setup |

### 2. Poblado de Datos

| Archivo | Descripción |
|---------|-------------|
| `populate_data_db.py` | **REEMPLAZO de `populate_sample_data.py`** - Inserta datos en PostgreSQL con deuda real y bills pendientes |

### 3. ETL

| Archivo | Descripción |
|---------|-------------|
| `etl_from_db.py` | **REEMPLAZO de `etl_customer_data.py`** - Lee de PostgreSQL y genera los mismos archivos JSON |

### 4. Dependencias

| Archivo | Cambios |
|---------|---------|
| `requirements.txt` | Agregado: `psycopg2-binary>=2.9.0` |

---

## 🗄️ Esquema de Base de Datos

### Tablas Creadas

```
customers
├── customer_id (PK)
├── first_name, last_name
├── birth_date
├── street_number, street_name, city, state, zip
└── profile (excellent, good, fair, poor)

accounts
├── account_id (PK)
├── customer_id (FK)
├── account_type (Checking, Credit Card, Loan, etc.)
├── balance (puede ser NEGATIVO para deuda)
├── credit_limit (para calcular utilization)
└── nickname, rewards

deposits
├── deposit_id (PK)
├── account_id (FK)
├── amount
├── transaction_date
└── description, status, payer_id

merchants
├── merchant_id (PK)
├── name, category
└── address completa

purchases
├── purchase_id (PK)
├── account_id (FK)
├── merchant_id (FK)
├── amount, purchase_date
└── status, description

bills
├── bill_id (PK)
├── customer_id (FK)
├── account_id (FK)
├── payee, nickname
├── payment_amount
├── payment_date, due_date (ambos disponibles!)
├── recurring_date
└── status (pending, completed, recurring)
```

---

## 🚀 Flujo de Uso

### Setup Inicial (Una vez)

```bash
# Opción A: Script automático
./setup_postgresql.sh

# Opción B: Manual
brew install postgresql@16
brew services start postgresql@16
source venv/bin/activate
pip install psycopg2-binary
```

### Crear Base de Datos

```bash
python create_database.py
```

Crea:
- Base de datos `credit_analysis`
- 6 tablas con relaciones
- Índices optimizados

### Poblar con Datos

```bash
python populate_data_db.py
```

Inserta:
- ✅ 5 clientes con perfiles variados
- ✅ Cuentas checking Y de crédito **CON DEUDA REAL**
- ✅ Depósitos mensuales (nómina)
- ✅ Compras con merchants
- ✅ **Bills pendientes** según perfil

### Ejecutar ETL

```bash
python etl_from_db.py
```

Genera los mismos archivos:
- `customer_data_full.json` - Datos completos con raw_data
- `customer_data_model.json` - 14 variables listas para ML

---

## 📊 Ventajas de PostgreSQL

| Característica | Nessie API | PostgreSQL 16 |
|----------------|------------|---------------|
| Deuda en cuentas | ❌ No permite balance negativo | ✅ Balance negativo = deuda |
| Bills pendientes | ❌ Solo "completed" | ✅ pending, recurring, completed |
| Due dates | ❌ No soportado | ✅ Campo `due_date` real |
| Credit limits | ❌ No disponible | ✅ Campo `credit_limit` |
| Control total | ❌ API sandbox | ✅ Control completo |
| Performance | ❌ Llamadas HTTP | ✅ Consultas SQL optimizadas |
| Datos persistentes | ❌ Sandbox temporal | ✅ Permanentes |
| Cálculo DTI | ❌ Difícil | ✅ Preciso |
| Cálculo Utilization | ❌ Imposible | ✅ Preciso |

---

## 🔍 Verificación de Datos

### Ver clientes con deuda

```sql
SELECT 
    c.customer_id, 
    c.first_name, 
    c.last_name, 
    c.profile,
    a.account_type, 
    a.balance as deuda,
    a.credit_limit
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
WHERE a.balance < 0;
```

### Ver bills pendientes

```sql
SELECT 
    c.first_name,
    c.last_name,
    b.payee,
    b.payment_amount,
    b.due_date,
    b.status
FROM customers c
JOIN bills b ON c.customer_id = b.customer_id
WHERE b.status IN ('pending', 'recurring')
ORDER BY b.due_date;
```

### Estadísticas por perfil

```sql
SELECT 
    c.profile,
    COUNT(DISTINCT c.customer_id) as num_clientes,
    AVG(CASE WHEN a.balance < 0 THEN ABS(a.balance) ELSE 0 END) as deuda_promedio,
    COUNT(CASE WHEN b.status IN ('pending','recurring') THEN 1 END) as bills_pendientes
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN bills b ON c.customer_id = b.customer_id
GROUP BY c.profile
ORDER BY c.profile;
```

---

## 📝 Archivos Antiguos (Pueden Eliminarse)

Estos archivos fueron reemplazados por la versión PostgreSQL:

- ~~`populate_sample_data.py`~~ → Usar `populate_data_db.py`
- ~~`etl_customer_data.py`~~ → Usar `etl_from_db.py`
- ~~`debt_metadata.json`~~ → Ya no necesario

**No eliminar todavía** hasta verificar que todo funciona correctamente.

---

## ✅ Checklist de Migración

- [x] Crear esquema de base de datos
- [x] Script de población con deuda real
- [x] Script ETL que lee de PostgreSQL
- [x] Documentación completa
- [x] Script de setup automático
- [ ] **Instalar PostgreSQL 16** (usuario)
- [ ] **Ejecutar `create_database.py`** (usuario)
- [ ] **Ejecutar `populate_data_db.py`** (usuario)
- [ ] **Ejecutar `etl_from_db.py`** (usuario)
- [ ] Verificar que los JSON generados tienen `current_debt > 0`

---

## 🎉 Resultado Final

Después de ejecutar todo:

```bash
✓ Base de datos PostgreSQL 16 funcionando
✓ 5 clientes con datos completos
✓ Cuentas de crédito CON DEUDA REAL
✓ Bills pendientes según perfil
✓ customer_data_model.json con current_debt > 0
✓ DTI y utilization calculados correctamente
```

**¡Ya no más limitaciones de API sandbox!** 🚀

