# 🚀 Quick Start - Supabase Credit Scoring

## Instalación Rápida (5 minutos)

### 1. Instalar dependencias

```bash
cd Backend
pip install -r requirements.txt
```

### 2. Iniciar servidor

```bash
python main.py
```

El servidor estará en: `http://localhost:8004`

### 3. Probar la integración

```bash
# Reemplaza ACC123456 con un account_id real de tu Supabase
curl -X POST "http://localhost:8004/credit/score-by-account/ACC123456"
```

O ejecuta el script de pruebas:

```bash
python test_supabase_integration.py
```

## 📊 Endpoints Principales

### 1. Score Automático (desde Supabase)

```bash
POST /credit/score-by-account/{account_id}
```

**Ejemplo:**
```bash
curl -X POST "http://localhost:8004/credit/score-by-account/ACC123456"
```

### 2. Ver Features Extraídas

```bash
GET /credit/account/{account_id}/features
```

**Ejemplo:**
```bash
curl "http://localhost:8004/credit/account/ACC123456/features"
```

### 3. Score Manual (sin Supabase)

```bash
POST /credit/score
```

**Ejemplo:**
```bash
curl -X POST "http://localhost:8004/credit/score" \
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

## 📖 Documentación Completa

Para más detalles, consulta:
- [SUPABASE_CREDIT_SCORING.md](./SUPABASE_CREDIT_SCORING.md) - Documentación completa
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 🔧 Configuración de Supabase

Las credenciales ya están configuradas por defecto. Si necesitas cambiarlas:

```bash
export SUPABASE_URL="tu-url-de-supabase"
export SUPABASE_KEY="tu-key-de-supabase"
```

## ✅ Verificación Rápida

```bash
# 1. Verificar que el servidor esté corriendo
curl http://localhost:8004/credit/health

# 2. Ver información del modelo
curl http://localhost:8004/credit/model-info

# 3. Probar con un account_id
curl -X POST "http://localhost:8004/credit/score-by-account/ACC123456"
```

## 🎯 Respuesta Ejemplo

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
    "explanation": "Buen perfil crediticio con ingresos estables."
  },
  "model_version": "Advanced Banking LightGBM v1.0"
}
```

## ⚠️ Troubleshooting

### Error: Cuenta no encontrada
- Verifica que el `account_id` existe en Supabase
- Usa el endpoint `/credit/account/{account_id}/features` para debug

### Error: Datos insuficientes
- El cliente necesita al menos 3 meses de historial de transacciones
- Verifica que hay datos en las tablas `deposits`, `purchases` y `bills`

### Error: Conexión a Supabase
- Verifica las credenciales de Supabase
- Verifica que tienes conexión a internet

## 📞 Soporte

Para más ayuda:
- Documentación completa: [SUPABASE_CREDIT_SCORING.md](./SUPABASE_CREDIT_SCORING.md)
- API Docs: http://localhost:8000/docs

