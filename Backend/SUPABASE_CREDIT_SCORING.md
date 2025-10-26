# 🎯 Credit Scoring con Supabase - Automatización Completa

## 📋 Descripción

Sistema de evaluación crediticia automática que integra el modelo de riesgo LightGBM con la base de datos transaccional en Supabase. El sistema extrae automáticamente el historial financiero de un cliente y genera una oferta de crédito personalizada en tiempo real.

## 🚀 Características

- ✅ **Extracción automática de features** desde Supabase
- ✅ **28 características bancarias avanzadas** calculadas automáticamente
- ✅ **Score PD90** (probabilidad de incumplimiento a 90 días)
- ✅ **Clasificación de riesgo** (Prime/Near Prime/Subprime/High Risk)
- ✅ **Oferta de crédito personalizada** (APR, límite, MSI)
- ✅ **Almacenamiento de resultados** en `credit_risk_profiles`
- ✅ **Validación de calidad de datos**

## 📊 Flujo de Trabajo

```
1. Cliente proporciona account_id
   ↓
2. Sistema extrae historial de Supabase:
   - Depósitos de nómina (12 meses)
   - Compras (6 meses)
   - Deudas pendientes (bills)
   ↓
3. Cálculo de 9 features básicas:
   - age, income_monthly, payroll_streak
   - payroll_variance, spending_monthly
   - spending_var_6m, current_debt
   - dti, utilization
   ↓
4. Modelo calcula 19 features avanzadas:
   - income_stability_score
   - spending_to_income_ratio
   - financial_health_score
   - etc.
   ↓
5. Predicción con LightGBM
   ↓
6. Generación de oferta de crédito
   ↓
7. Almacenamiento en credit_risk_profiles
   ↓
8. Retorno de oferta al cliente
```

## 🔧 Instalación

### 1. Instalar dependencias

```bash
cd Backend
pip install -r requirements.txt
```

Nuevas dependencias agregadas:
- `supabase==2.3.0` - Cliente de Supabase
- `numpy==1.24.3` - Cálculos numéricos
- `joblib==1.3.2` - Carga de modelos
- `scikit-learn==1.3.2` - Preprocesamiento
- `lightgbm==4.1.0` - Modelo de ML

### 2. Configurar variables de entorno

Las credenciales de Supabase ya están configuradas por defecto en el código, pero puedes sobrescribirlas con variables de entorno:

```bash
export SUPABASE_URL="https://aaseaqeolqpjfqkpsuyd.supabase.co"
export SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### 3. Iniciar el servidor

```bash
python main.py
```

El servidor estará disponible en `http://localhost:8000`

## 📡 Endpoints

### 1. Score por Account ID (Principal)

**Endpoint:** `POST /credit/score-by-account/{account_id}`

**Descripción:** Calcula el score crediticio automáticamente desde el account_id de Supabase.

**Ejemplo:**

```bash
curl -X POST "http://localhost:8000/credit/score-by-account/ACC123456"
```

**Respuesta:**

```json
{
  "success": true,
  "offer": {
    "customer_id": "CUST123",
    "pd90_score": 0.156,
    "risk_tier": "Near Prime",
    "credit_limit": 25000.0,
    "apr": 18.5,
    "msi_eligible": true,
    "msi_months": 6,
    "explanation": "Buen perfil crediticio con ingresos estables. Elegible para 6 meses sin intereses."
  },
  "model_version": "Advanced Banking LightGBM v1.0"
}
```

### 2. Ver Features Extraídas (Debug)

**Endpoint:** `GET /credit/account/{account_id}/features`

**Descripción:** Muestra las features extraídas de Supabase sin ejecutar el modelo.

**Ejemplo:**

```bash
curl "http://localhost:8000/credit/account/ACC123456/features"
```

**Respuesta:**

```json
{
  "account_id": "ACC123456",
  "customer_id": "CUST123",
  "features": {
    "age": 32,
    "income_monthly": 15000.0,
    "payroll_streak": 8,
    "payroll_variance": 0.12,
    "spending_monthly": 8500.0,
    "spending_var_6m": 0.18,
    "current_debt": 5000.0,
    "dti": 0.33,
    "utilization": 0.45
  },
  "metadata": {
    "data_quality_score": 0.85,
    "months_of_history": 8,
    "quality_status": "excellent"
  }
}
```

### 3. Score Manual (Existente)

**Endpoint:** `POST /credit/score`

**Descripción:** Calcula el score crediticio con features proporcionadas manualmente.

**Ejemplo:**

```bash
curl -X POST "http://localhost:8000/credit/score" \
  -H "Content-Type: application/json" \
  -d '{
    "age": 32,
    "income_monthly": 15000.0,
    "payroll_streak": 8,
    "payroll_variance": 0.12,
    "spending_monthly": 8500.0,
    "spending_var_6m": 0.18,
    "current_debt": 5000.0,
    "dti": 0.33,
    "utilization": 0.45
  }'
```

## 🗄️ Estructura de Supabase

### Tablas Requeridas

#### 1. `customers`
```sql
- customer_id: VARCHAR PRIMARY KEY
- first_name: VARCHAR
- last_name: VARCHAR
- birth_date: DATE
- profile: VARCHAR (excellent, good, fair, poor)
```

#### 2. `accounts`
```sql
- account_id: VARCHAR PRIMARY KEY
- customer_id: VARCHAR REFERENCES customers
- balance: DECIMAL
- credit_limit: DECIMAL
- account_type: VARCHAR
```

#### 3. `deposits`
```sql
- deposit_id: SERIAL PRIMARY KEY
- account_id: VARCHAR REFERENCES accounts
- amount: DECIMAL
- transaction_date: DATE
- status: VARCHAR (completed, pending)
```

#### 4. `purchases`
```sql
- purchase_id: SERIAL PRIMARY KEY
- account_id: VARCHAR REFERENCES accounts
- amount: DECIMAL
- purchase_date: DATE
- status: VARCHAR (completed, pending)
```

#### 5. `bills`
```sql
- bill_id: SERIAL PRIMARY KEY
- account_id: VARCHAR REFERENCES accounts
- payment_amount: DECIMAL
- status: VARCHAR (pending, recurring, completed)
```

#### 6. `credit_risk_profiles` (Resultados)
```sql
- id: SERIAL PRIMARY KEY
- customer_id: VARCHAR
- pd90_score: DECIMAL
- risk_tier: VARCHAR
- credit_limit: DECIMAL
- apr: DECIMAL
- msi_eligible: BOOLEAN
- msi_months: INTEGER
- explanation: TEXT
- created_at: TIMESTAMP DEFAULT NOW()
```

## 🧪 Testing

### 1. Test de extracción de features

```bash
# Ver features de una cuenta
curl "http://localhost:8000/credit/account/ACC123456/features"
```

### 2. Test de scoring completo

```bash
# Ejecutar scoring completo
curl -X POST "http://localhost:8000/credit/score-by-account/ACC123456"
```

### 3. Ver resultados almacenados

Consulta Supabase directamente:

```sql
SELECT * FROM credit_risk_profiles
ORDER BY created_at DESC
LIMIT 10;
```

## 📈 Interpretación de Resultados

### Score PD90

- **0.00 - 0.10**: Riesgo muy bajo (Prime)
- **0.10 - 0.20**: Riesgo bajo (Near Prime)
- **0.20 - 0.35**: Riesgo moderado (Subprime)
- **0.35 - 1.00**: Riesgo alto (High Risk)

### Risk Tiers

| Tier | Score Range | APR | Credit Limit | MSI |
|------|-------------|-----|--------------|-----|
| Prime | 0.00 - 0.10 | 12-15% | $30k - $50k | 12 meses |
| Near Prime | 0.10 - 0.20 | 15-20% | $20k - $30k | 6 meses |
| Subprime | 0.20 - 0.35 | 20-28% | $10k - $20k | 3 meses |
| High Risk | 0.35+ | 28-36% | $5k - $10k | No elegible |

## 🔍 Calidad de Datos

El sistema valida automáticamente la calidad de los datos:

- **Excellent** (0.8+): 3+ meses de historial completo
- **Good** (0.5-0.8): 2-3 meses de historial
- **Fair** (0.3-0.5): 1-2 meses de historial
- **Insufficient** (<0.3): Menos de 1 mes

**Mínimo requerido:** 0.3 (Fair) para generar una oferta.

## 🛠️ Arquitectura

```
Backend/
├── services/
│   ├── __init__.py
│   └── account_feature_aggregator.py  # ⭐ Nuevo servicio
├── routes/
│   └── credit_scoring.py              # ⭐ Actualizado con nuevos endpoints
├── requirements.txt                    # ⭐ Actualizado con supabase
└── main.py                             # FastAPI app
```

## 🚨 Errores Comunes

### 1. Cuenta no encontrada

```json
{
  "detail": "No se encontró la cuenta ACC123456 en Supabase"
}
```

**Solución:** Verificar que el `account_id` existe en la tabla `accounts`.

### 2. Datos insuficientes

```json
{
  "detail": "Datos insuficientes para evaluar (calidad: 20%). Se requiere al menos 3 meses de historial."
}
```

**Solución:** El cliente necesita más historial de transacciones.

### 3. Error de conexión a Supabase

```json
{
  "detail": "Error scoring credit: ..."
}
```

**Solución:** Verificar credenciales de Supabase y conexión a internet.

## 📝 Notas

- Los resultados se almacenan automáticamente en `credit_risk_profiles` para auditoría
- El sistema continúa funcionando aunque falle el almacenamiento en Supabase
- Las credenciales de Supabase están configuradas por defecto pero se pueden sobrescribir con variables de entorno
- El modelo puede funcionar en modo "mock" si no se encuentran los archivos .pkl y .txt

## 🎯 Próximos Pasos

1. ✅ Implementado: Extracción automática de features desde Supabase
2. ✅ Implementado: Endpoint de scoring por account_id
3. ✅ Implementado: Almacenamiento de resultados
4. 🔄 Pendiente: Dashboard de visualización de ofertas
5. 🔄 Pendiente: Notificaciones automáticas al cliente
6. 🔄 Pendiente: Integración con app iOS/Android

## 📞 Soporte

Para más información, consulta:
- Documentación de Supabase: https://supabase.com/docs
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

