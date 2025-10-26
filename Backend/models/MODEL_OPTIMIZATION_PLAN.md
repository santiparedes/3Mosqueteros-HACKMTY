# Plan de Optimización del Modelo

## 🎯 Objetivos

1. **Mejorar balance de clases** - Optimizar SMOTE y class weights para validation/test
2. **Reducir overfitting** - Eliminar features de baja importancia (SHAP < 0.01)
3. **Mejorar generalización** - Reducir gap entre Train (0.935) y Test (0.724)

---

## 📊 Análisis del Estado Actual

### Problema 1: Desbalance Severo en Validation/Test

| Dataset | n_good | n_bad | % good | % bad |
|---------|--------|-------|--------|-------|
| **Train** | 1,380,677 | 1,380,677 | 50.0% | 50.0% ✓ |
| **Validation** | 43,340 | 295,760 | 12.8% | 87.2% ⚠️ |
| **Test** | 42,951 | 296,150 | 12.7% | 87.3% ⚠️ |

**Impacto:**
- El modelo aprende con balance 50/50 pero predice en 12/88
- Esto causa que las probabilidades predichas estén mal calibradas
- Las métricas de precision/recall están sesgadas

**Solución:** Aplicar class weights dinámicos que reflejen el desbalance real

---

### Problema 2: Features de Baja Importancia

| Feature | SHAP Importance | Acción |
|---------|----------------|--------|
| `income_debt_interaction` | 0.0000 | ❌ **ELIMINAR** |
| `spending_monthly` | 0.0016 | ❌ **ELIMINAR** |
| `income_adequacy` | 0.0066 | ❌ **ELIMINAR** |
| `creditworthiness_score` | 0.0077 | ⚠️ **REVISAR** |
| `dti_health_score` | 0.0127 | ⚠️ **REVISAR** |

**Features a mantener (SHAP > 0.01):**
- `payment_consistency` (1.034) ⭐
- `debt_service_ratio` (0.811) ⭐
- `payroll_variance` (0.746) ⭐
- `income_stability_score` (0.398)
- `spending_var_6m` (0.393)
- ... (resto con importancia > 0.01)

**Impacto:**
- 4-5 features añaden ruido sin información útil
- Aumentan complejidad y riesgo de overfitting
- Ralentizan inferencia

**Solución:** Eliminar features con SHAP < 0.01

---

### Problema 3: Overfitting

**Evidencia:**
- Train AUC: 0.935
- Test AUC: 0.724
- **Gap: 0.211** (21.1% de degradación)

**Causas:**
1. Demasiados features (29 features, algunos irrelevantes)
2. SMOTE aplicado solo en train (crea distribución artificial)
3. Posible overfit en features de baja importancia

**Solución:** Combinar feature selection + class weights + regularización

---

## 🛠️ Plan de Implementación

### **Mejora 1: Optimización de Class Balance**

#### Opción A: Class Weights Dinámicos (RECOMENDADO)

**Ventajas:**
- No modifica la distribución original de datos
- Mejor calibración de probabilidades
- Más realista para producción

**Implementación:**

```python
# Calcular class weight basado en distribución real de validation/test
neg_count = y_train.value_counts()[0]  # good
pos_count = y_train.value_counts()[1]  # bad

# Opción 1: Balanceo simple
scale_pos_weight = neg_count / pos_count

# Opción 2: Balanceo suave (menos agresivo)
scale_pos_weight = np.sqrt(neg_count / pos_count)

# Opción 3: Basado en target real de validation
actual_ratio = len(y_valid[y_valid==0]) / len(y_valid[y_valid==1])
scale_pos_weight = actual_ratio
```

**Estrategia:**
1. **Eliminar SMOTE** completamente
2. **Usar class_weight='balanced'** en LightGBM
3. **Ajustar scale_pos_weight** basado en ratio real de validation/test (~7:1)

#### Opción B: SMOTE Mejorado

**Solo si Opción A no funciona:**

```python
# SMOTE con ratio más cercano a realidad
smote = SMOTE(
    sampling_strategy=0.3,  # 30% minority vs 70% majority
    random_state=42,
    k_neighbors=3
)
```

**Comparación:**

| Método | Train Balance | Calibración | Velocidad | Recomendado |
|--------|--------------|-------------|-----------|-------------|
| **Class Weights** | Natural (12/88) | Excelente | Rápido | ✅ SÍ |
| **SMOTE 50/50** | Artificial (50/50) | Pobre | Lento | ❌ NO |
| **SMOTE 30/70** | Semi-artificial | Buena | Medio | ⚠️ Backup |

---

### **Mejora 2: Feature Selection Automática**

#### Estrategia de Eliminación

**Fase 1: Eliminación Agresiva (SHAP < 0.01)**

Features a eliminar:
```python
LOW_IMPORTANCE_FEATURES = [
    'income_debt_interaction',      # 0.0000
    'spending_monthly',              # 0.0016
    'income_adequacy',               # 0.0066
    'creditworthiness_score',        # 0.0077
]
```

**Impacto esperado:**
- Reducción: 29 → 25 features (-13.8%)
- Mejora en generalización
- Reducción de overfitting

**Fase 2: Análisis de Correlación**

Eliminar features redundantes (correlación > 0.9):

```python
# Detectar pares altamente correlacionados
correlation_matrix = df[features].corr()
high_corr_pairs = []

for i in range(len(correlation_matrix.columns)):
    for j in range(i+1, len(correlation_matrix.columns)):
        if abs(correlation_matrix.iloc[i, j]) > 0.9:
            feat1 = correlation_matrix.columns[i]
            feat2 = correlation_matrix.columns[j]

            # Mantener el de mayor SHAP
            if importance[feat1] > importance[feat2]:
                remove_features.append(feat2)
            else:
                remove_features.append(feat1)
```

**Candidatos a revisar:**
- `income_volatility` vs `payroll_variance` (probablemente alta correlación)
- `dti` vs `debt_service_ratio`
- `utilization` vs `credit_utilization_health`

---

## 📋 Implementación Step-by-Step

### **Fase 1: Análisis y Preparación** (Días 1-2)

#### Paso 1.1: Análisis de Correlación
```bash
python analyze_feature_correlations.py
```

**Output esperado:**
- `reports/feature_correlation_matrix.csv`
- `reports/redundant_features.json`
- `plots/correlation_heatmap.png`

#### Paso 1.2: Validación de Features
```bash
python validate_feature_importance.py
```

**Output esperado:**
- Lista de features a eliminar
- Comparación SHAP vs correlación
- Recomendaciones finales

---

### **Fase 2: Implementación de Mejoras** (Días 3-5)

#### Paso 2.1: Crear Script de Optimización

**Archivo:** `optimize_model.py`

**Funcionalidad:**
1. Eliminar features de baja importancia
2. Entrenar con class weights dinámicos
3. Comparar con modelo baseline
4. Generar reporte de mejoras

#### Paso 2.2: Experimentación con Class Weights

**Experimento 1:** Sin SMOTE, class_weight='balanced'
```python
params = {
    'scale_pos_weight': None,  # Auto-calculado por 'balanced'
    'class_weight': 'balanced'
}
```

**Experimento 2:** Sin SMOTE, scale_pos_weight manual
```python
# Ratio real de validation/test ≈ 7:1
params = {
    'scale_pos_weight': 7.0
}
```

**Experimento 3:** SMOTE conservador
```python
smote = SMOTE(sampling_strategy=0.3)  # 30% minority
params = {
    'scale_pos_weight': 1.0
}
```

#### Paso 2.3: Feature Selection Iterativa

**Estrategia:**
1. **Baseline:** Modelo actual (29 features)
2. **Experimento 1:** Eliminar SHAP < 0.01 (25 features)
3. **Experimento 2:** Eliminar SHAP < 0.02 (20 features)
4. **Experimento 3:** Eliminar correlación > 0.9 (15-18 features)

**Métrica de comparación:** Test AUC-ROC

---

### **Fase 3: Validación y Comparación** (Días 6-7)

#### Paso 3.1: Experimentos Combinados

| Experimento | Features | SMOTE | Class Weight | Expected AUC |
|-------------|----------|-------|--------------|--------------|
| **Baseline** | 29 | 50/50 | 1.0 | 0.724 |
| **Exp 1** | 25 | No | balanced | 0.730-0.750 |
| **Exp 2** | 25 | No | 7.0 | 0.730-0.750 |
| **Exp 3** | 20 | No | balanced | 0.735-0.760 |
| **Exp 4** | 20 | 30/70 | 2.3 | 0.730-0.755 |

#### Paso 3.2: Métricas de Validación

Para cada experimento, medir:

```python
metrics = {
    'auc_roc': ...,
    'pr_auc': ...,
    'brier_score': ...,
    'precision': ...,
    'recall': ...,
    'train_test_gap': ...,  # NUEVO: Train AUC - Test AUC
    'calibration_error': ...,  # NUEVO
    'inference_time': ...,  # NUEVO
}
```

**Criterios de éxito:**
- ✅ Test AUC ≥ 0.73 (+0.006)
- ✅ Train-Test gap ≤ 0.15 (-0.06)
- ✅ Brier score ≤ 0.12 (-0.006)
- ✅ Reducción de features ≥ 10%

---

## 🚀 Scripts a Crear

### 1. `analyze_feature_correlations.py`

**Propósito:** Identificar features redundantes

**Output:**
- Matriz de correlación
- Lista de pares correlacionados (> 0.9)
- Recomendaciones de eliminación

---

### 2. `optimize_class_weights.py`

**Propósito:** Encontrar optimal class weight

**Método:**
```python
# Grid search sobre scale_pos_weight
weights_to_test = [1.0, 3.0, 5.0, 7.0, 10.0, 15.0]

for weight in weights_to_test:
    model = train_with_weight(weight)
    auc = evaluate(model, X_valid, y_valid)
    results[weight] = auc

optimal_weight = max(results, key=results.get)
```

**Output:**
- Gráfico de AUC vs class_weight
- Optimal weight value
- Comparación con SMOTE

---

### 3. `feature_selection_pipeline.py`

**Propósito:** Selección automática de features

**Método:**
```python
# Recursive Feature Elimination con SHAP
features_ranked = shap_importance.sort_values(ascending=False)
feature_sets = []

# Probar con diferentes thresholds
for threshold in [0.001, 0.005, 0.01, 0.02, 0.05]:
    selected = features_ranked[features_ranked > threshold]
    feature_sets.append(selected.index.tolist())

# Entrenar modelo con cada feature set
for features in feature_sets:
    model = train_with_features(features)
    results[len(features)] = evaluate(model)
```

**Output:**
- Curva de AUC vs número de features
- Optimal feature set
- Feature importance final

---

### 4. `model_optimizer.py` (SCRIPT PRINCIPAL)

**Propósito:** Pipeline completo de optimización

**Workflow:**
```python
# 1. Cargar datos
train, valid, test = load_data()

# 2. Analizar correlaciones
redundant = find_redundant_features(train)

# 3. Eliminar low SHAP
low_importance = [f for f in features if shap[f] < 0.01]
features = [f for f in features if f not in low_importance]

# 4. Optimizar class weights
optimal_weight = find_optimal_weight(train, valid)

# 5. Entrenar modelo optimizado
model = train_optimized_model(
    features=features,
    scale_pos_weight=optimal_weight,
    use_smote=False
)

# 6. Evaluar y comparar
compare_with_baseline(model, baseline_model)

# 7. Guardar resultados
save_optimization_report()
```

---

### 5. `compare_models.py`

**Propósito:** Comparación lado a lado

**Output:**
```
================================================================================
MODEL COMPARISON REPORT
================================================================================

BASELINE MODEL:
  Features: 29
  SMOTE: Yes (50/50)
  Class Weight: 1.0
  Test AUC: 0.7236
  Train-Test Gap: 0.2117

OPTIMIZED MODEL:
  Features: 22
  SMOTE: No
  Class Weight: 7.0 (balanced)
  Test AUC: 0.7458 (+0.0222)
  Train-Test Gap: 0.1534 (-0.0583)

IMPROVEMENTS:
  ✅ AUC improved by +2.22%
  ✅ Overfitting reduced by -27.5%
  ✅ Features reduced by -24.1%
  ✅ Inference time: -18%
```

---

## 📊 Expected Results

### Mejora Esperada

| Métrica | Baseline | Target | Mejora |
|---------|----------|--------|--------|
| **Test AUC** | 0.7236 | 0.7450+ | +2.9% |
| **Train-Test Gap** | 0.2117 | 0.1500 | -29.1% |
| **Brier Score** | 0.1260 | 0.1150 | -8.7% |
| **Features** | 29 | 20-22 | -24-31% |
| **Training Time** | 100% | 80% | -20% |

### Riesgos y Mitigación

| Riesgo | Probabilidad | Mitigación |
|--------|-------------|------------|
| AUC no mejora | Media | Probar múltiples configuraciones |
| Overfitting persiste | Baja | Aumentar regularización (L1/L2) |
| Features importantes eliminadas | Baja | Usar threshold conservador (0.01) |
| Class weights subóptimos | Media | Grid search exhaustivo |

---

## ⏱️ Timeline

| Fase | Duración | Entregables |
|------|----------|-------------|
| **1. Análisis** | 1-2 días | Scripts de análisis, reportes |
| **2. Implementación** | 2-3 días | Scripts de optimización |
| **3. Experimentación** | 2-3 días | Resultados de experimentos |
| **4. Validación** | 1 día | Reporte final, modelo optimizado |
| **Total** | **6-9 días** | Modelo mejorado en producción |

---

## 🎯 Success Criteria

✅ **Criterios Mínimos:**
1. Test AUC ≥ 0.730 (+0.6%)
2. Train-Test gap ≤ 0.180 (-15%)
3. Features reducidos en ≥ 10%

✅ **Criterios Óptimos:**
1. Test AUC ≥ 0.745 (+3%)
2. Train-Test gap ≤ 0.150 (-30%)
3. Features reducidos en ≥ 20%
4. Brier score ≤ 0.115 (-9%)

---

## 🔄 Iteración Continua

Después de implementación inicial:

**Monitoreo:**
- Track AUC en producción
- Detectar feature drift
- Alertas si AUC < threshold

**Re-entrenamiento:**
- Mensual: Re-train con nuevos datos
- Trimestral: Re-evaluar feature importance
- Anual: Re-diseñar features si necesario

---

## 📝 Next Steps

1. **Hoy:** Revisar y aprobar plan
2. **Día 1:** Crear scripts de análisis
3. **Día 2:** Ejecutar análisis, generar reportes
4. **Día 3-5:** Implementar optimizaciones
5. **Día 6-7:** Validar y comparar resultados
6. **Día 8:** Deploy modelo optimizado

---

**¿Listo para empezar? Puedo crear los scripts de optimización ahora mismo.**
