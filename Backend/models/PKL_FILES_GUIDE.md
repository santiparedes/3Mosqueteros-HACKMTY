# 📦 GUÍA: ARCHIVOS .PKL Y MODELOS

## 🎯 ¿QUÉ SON LOS ARCHIVOS .PKL?

Los archivos `.pkl` son **Scalers** (normalizadores de features):
- Se usan para normalizar los datos antes del entrenamiento
- Se generan **automáticamente** durante el entrenamiento
- Son **pequeños** (~2 KB cada uno)

Los archivos `.txt` son **Modelos** entrenados:
- Son los modelos LightGBM entrenados
- Se generan **automáticamente** durante el entrenamiento
- Son **medianos** (~30-50 KB cada uno)

---

## ✅ ¿DEBES COPIARLOS?

### ❌ NO es necesario copiarlos (opcional)

**¿Por qué?** Porque se generan automáticamente cuando entrenas el modelo.

### ✅ CUANDO SÍ debes copiarlos:

Solo si quieres **usar modelos ya entrenados** en tu proyecto nuevo:

```bash
# Opción A: COPIAR modelos entrenados (si existen)
cp datasetModel/models/*.txt mi-proyecto/models/
cp datasetModel/models/*.pkl mi-proyecto/models/

# Opción B: ENTRENAR NUEVOS MODELOS (recomendado)
python train_from_loan_dataset.py --dataset mi_datos.csv
```

---

## 🔄 FLUJO DE TRABAJO

### Si COPIASTES los modelos:
```bash
# Usa el modelo ya entrenado
python predict.py --model models/advanced_banking_model.txt
```

### Si NO copiastes los modelos (recomendado):
```bash
# 1. Instalar dependencias
pip install -r requirements.txt

# 2. Entrenar nuevo modelo (genera automáticamente .txt y .pkl)
python train_from_loan_dataset.py --dataset mi_datos.csv

# 3. Los archivos .txt y .pkl se crean automáticamente en models/
```

---

## 📁 ARCHIVOS EN datasetModel/models/

### Modelos (.txt):
- `advanced_banking_model.txt` - Modelo principal (30-50 KB)
- `model_Exp1_25features_balanced.txt` - Experimento 1
- `model_Exp2_25features_real_ratio.txt` - Experimento 2
- `model_Exp3_20features_balanced.txt` - Experimento 3

### Scalers (.pkl):
- `advanced_scaler.pkl` - Scaler del modelo principal (~2 KB)
- `scaler_Exp1_25features_balanced.pkl` - Scaler Exp1 (~2 KB)
- `scaler_Exp2_25features_real_ratio.pkl` - Scaler Exp2 (~2 KB)
- `scaler_Exp3_20features_balanced.pkl` - Scaler Exp3 (~2 KB)

### Otros:
- `advanced_model_metadata.json` - Metadatos del modelo

---

## 🎯 RECOMENDACIÓN

### Para proyecto nuevo:
**NO copies** los `.txt` y `.pkl` - Entrena el modelo con tus datos.

### Para usar modelo existente:
**SÍ copia** los `.txt` y `.pkl` - Ya están entrenados y listos.

---

## 📋 LISTA ACTUALIZADA

### Obligatorios (sin modelos):
```
✅ loan_feature_engineering.py
✅ advanced_banking_model.py
✅ train_from_loan_dataset.py
✅ requirements.txt
✅ Tu dataset CSV
```

### Opcionales (si copias modelos entrenados):
```
⚠️ models/advanced_banking_model.txt (si quieres usar modelo existente)
⚠️ models/advanced_scaler.pkl (si quieres usar modelo existente)
```

---

**Resumen**: Los `.pkl` se generan automáticamente. Solo cópialos si quieres usar un modelo ya entrenado.
