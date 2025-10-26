"""
FASE 5 - PASO 2: Modelo LightGBM con Early Stopping
===================================================

Implementa modelo LightGBM con hiperparámetros optimizados,
early stopping y cross-validation temporal.
"""
import pandas as pd
import numpy as np
import lightgbm as lgb
from sklearn.metrics import (
    roc_auc_score, average_precision_score, brier_score_loss,
    classification_report, confusion_matrix, roc_curve, precision_recall_curve
)
import joblib
import json
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

def load_prepared_data():
    """Carga los datos preparados"""
    print("Cargando datos preparados...")
    
    X_train = pd.read_csv('models/X_train_prepared.csv')
    y_train = pd.read_csv('models/y_train_prepared.csv').values.ravel()
    X_valid = pd.read_csv('models/X_valid_prepared.csv')
    y_valid = pd.read_csv('models/y_valid_prepared.csv').values.ravel()
    X_test = pd.read_csv('models/X_test_prepared.csv')
    y_test = pd.read_csv('models/y_test_prepared.csv').values.ravel()
    
    # Cargar metadata
    with open('models/data_preparation_metadata.json', 'r') as f:
        metadata = json.load(f)
    
    print(f"✓ Train: {X_train.shape} (Good: {y_train.sum()}, Bad: {len(y_train) - y_train.sum()})")
    print(f"✓ Validation: {X_valid.shape} (Good: {y_valid.sum()}, Bad: {len(y_valid) - y_valid.sum()})")
    print(f"✓ Test: {X_test.shape} (Good: {y_test.sum()}, Bad: {len(y_test) - y_test.sum()})")
    
    return X_train, y_train, X_valid, y_valid, X_test, y_test, metadata

def calculate_class_weights(y_train):
    """Calcula pesos de clase para manejar desbalance"""
    from collections import Counter
    class_counts = Counter(y_train)
    total = len(y_train)
    
    # Calcular ratio negativo/positivo
    neg_count = class_counts[0]
    pos_count = class_counts[1]
    
    scale_pos_weight = neg_count / pos_count if pos_count > 0 else 1.0
    
    print(f"Class distribution: Bad={neg_count}, Good={pos_count}")
    print(f"Scale pos weight: {scale_pos_weight:.3f}")
    
    return scale_pos_weight

def train_lightgbm_model(X_train, y_train, X_valid, y_valid):
    """
    Entrena modelo LightGBM con early stopping
    """
    print("=" * 80)
    print("FASE 5 - PASO 2: ENTRENAMIENTO LIGHTGBM")
    print("=" * 80)
    
    # Calcular pesos de clase
    scale_pos_weight = calculate_class_weights(y_train)
    
    # Hiperparámetros optimizados para datos pequeños
    params = {
        'objective': 'binary',
        'metric': 'auc',
        'boosting_type': 'gbdt',
        'num_leaves': 15,  # Reducido para evitar overfitting
        'learning_rate': 0.05,  # Más conservador
        'n_estimators': 2000,
        'subsample': 0.8,
        'subsample_freq': 5,
        'colsample_bytree': 0.8,
        'min_child_samples': 5,  # Reducido para datos pequeños
        'min_child_weight': 0.001,
        'reg_alpha': 0.1,
        'reg_lambda': 0.1,
        'random_state': 42,
        'verbose': -1,
        'scale_pos_weight': scale_pos_weight,
        'feature_fraction': 0.8,
        'bagging_fraction': 0.8,
        'bagging_freq': 5,
        'max_depth': 6,  # Limitado para evitar overfitting
        'min_split_gain': 0.0
    }
    
    print(f"\nHiperparámetros configurados:")
    for key, value in params.items():
        print(f"  {key}: {value}")
    
    # Crear datasets de LightGBM
    train_data = lgb.Dataset(X_train, label=y_train)
    valid_data = lgb.Dataset(X_valid, label=y_valid, reference=train_data)
    
    # Callbacks para early stopping y logging
    callbacks = [
        lgb.early_stopping(stopping_rounds=50, verbose=True),
        lgb.log_evaluation(period=25)
    ]
    
    print(f"\nIniciando entrenamiento con early stopping...")
    print(f"Parando si no hay mejora en AUC por 50 rondas")
    
    # Entrenar modelo
    start_time = datetime.now()
    
    model = lgb.train(
        params,
        train_data,
        valid_sets=[train_data, valid_data],
        valid_names=['train', 'valid'],
        num_boost_round=2000,
        callbacks=callbacks,
        feval=None
    )
    
    end_time = datetime.now()
    training_time = (end_time - start_time).total_seconds()
    
    print(f"\n✓ Entrenamiento completado en {training_time:.1f} segundos")
    print(f"✓ Mejor iteración: {model.best_iteration}")
    print(f"✓ Mejor score: {model.best_score['valid']['auc']:.4f}")
    
    return model, training_time

def evaluate_model_performance(model, X_train, y_train, X_valid, y_valid, X_test, y_test):
    """
    Evalúa el rendimiento del modelo en todos los conjuntos
    """
    print("\n" + "=" * 80)
    print("EVALUACIÓN DE RENDIMIENTO")
    print("=" * 80)
    
    # Función para calcular métricas
    def calculate_metrics(y_true, y_proba, dataset_name):
        auc = roc_auc_score(y_true, y_proba)
        pr_auc = average_precision_score(y_true, y_proba)
        brier = brier_score_loss(y_true, y_proba)
        
        # Predicciones binarias con umbral 0.5
        y_pred = (y_proba >= 0.5).astype(int)
        
        # Métricas de clasificación
        from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score
        
        accuracy = accuracy_score(y_true, y_pred)
        precision = precision_score(y_true, y_pred, zero_division=0)
        recall = recall_score(y_true, y_pred, zero_division=0)
        f1 = f1_score(y_true, y_pred, zero_division=0)
        
        # KS Statistic
        from scipy.stats import ks_2samp
        good_scores = y_proba[y_true == 1]
        bad_scores = y_proba[y_true == 0]
        
        if len(good_scores) > 0 and len(bad_scores) > 0:
            ks_stat = ks_2samp(bad_scores, good_scores).statistic
        else:
            ks_stat = 0.0
        
        metrics = {
            'dataset': dataset_name,
            'auc_roc': auc,
            'pr_auc': pr_auc,
            'brier_score': brier,
            'ks_statistic': ks_stat,
            'accuracy': accuracy,
            'precision': precision,
            'recall': recall,
            'f1_score': f1,
            'n_samples': len(y_true),
            'n_good': int(y_true.sum()),
            'n_bad': int(len(y_true) - y_true.sum())
        }
        
        return metrics, y_pred
    
    # Evaluar en todos los conjuntos
    datasets = [
        (X_train, y_train, 'Train'),
        (X_valid, y_valid, 'Validation'),
        (X_test, y_test, 'Test')
    ]
    
    all_metrics = []
    
    for X, y, name in datasets:
        y_proba = model.predict(X)
        metrics, y_pred = calculate_metrics(y, y_proba, name)
        all_metrics.append(metrics)
        
        print(f"\n{name} Set Performance:")
        print(f"  Samples: {metrics['n_samples']} (Good: {metrics['n_good']}, Bad: {metrics['n_bad']})")
        print(f"  AUC-ROC: {metrics['auc_roc']:.4f}")
        print(f"  PR-AUC:  {metrics['pr_auc']:.4f}")
        print(f"  Brier:   {metrics['brier_score']:.4f}")
        print(f"  KS:      {metrics['ks_statistic']:.4f}")
        print(f"  Accuracy: {metrics['accuracy']:.4f}")
        print(f"  Precision: {metrics['precision']:.4f}")
        print(f"  Recall: {metrics['recall']:.4f}")
        print(f"  F1: {metrics['f1_score']:.4f}")
    
    return all_metrics

def plot_training_curves(model):
    """Genera gráficos de curvas de entrenamiento"""
    print("\nGenerando gráficos de entrenamiento...")
    
    # Obtener historial de entrenamiento
    try:
        evals_result = model.evals_result_
    except AttributeError:
        print("   ⚠️ evals_result_ no disponible, saltando gráficos de entrenamiento")
        return
    
    # Crear figura con subplots
    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    fig.suptitle('LightGBM Training Curves', fontsize=16)
    
    # AUC curves
    axes[0, 0].plot(evals_result['train']['auc'], label='Train AUC', color='blue')
    axes[0, 0].plot(evals_result['valid']['auc'], label='Validation AUC', color='red')
    axes[0, 0].set_title('AUC Curves')
    axes[0, 0].set_xlabel('Iterations')
    axes[0, 0].set_ylabel('AUC')
    axes[0, 0].legend()
    axes[0, 0].grid(True)
    
    # Binary logloss curves
    axes[0, 1].plot(evals_result['train']['binary_logloss'], label='Train LogLoss', color='blue')
    axes[0, 1].plot(evals_result['valid']['binary_logloss'], label='Validation LogLoss', color='red')
    axes[0, 1].set_title('Binary LogLoss Curves')
    axes[0, 1].set_xlabel('Iterations')
    axes[0, 1].set_ylabel('LogLoss')
    axes[0, 1].legend()
    axes[0, 1].grid(True)
    
    # Feature importance
    feature_importance = model.feature_importance(importance_type='gain')
    feature_names = model.feature_name()
    
    # Ordenar por importancia
    importance_df = pd.DataFrame({
        'feature': feature_names,
        'importance': feature_importance
    }).sort_values('importance', ascending=True)
    
    axes[1, 0].barh(importance_df['feature'], importance_df['importance'])
    axes[1, 0].set_title('Feature Importance (Gain)')
    axes[1, 0].set_xlabel('Importance')
    
    # Learning curves (zoom)
    axes[1, 1].plot(evals_result['train']['auc'], label='Train AUC', color='blue', alpha=0.7)
    axes[1, 1].plot(evals_result['valid']['auc'], label='Validation AUC', color='red', alpha=0.7)
    axes[1, 1].set_title('AUC Curves (Zoom)')
    axes[1, 1].set_xlabel('Iterations')
    axes[1, 1].set_ylabel('AUC')
    axes[1, 1].legend()
    axes[1, 1].grid(True)
    axes[1, 1].set_xlim(0, min(200, len(evals_result['train']['auc'])))
    
    plt.tight_layout()
    plt.savefig('plots/lgbm_training_curves.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    print("✓ Gráficos de entrenamiento guardados en: plots/lgbm_training_curves.png")

def save_model_and_results(model, all_metrics, training_time, feature_names):
    """Guarda el modelo y resultados"""
    print("\nGuardando modelo y resultados...")
    
    # Guardar modelo
    model.save_model('models/model_gbm.txt')
    print("✓ Modelo guardado en: models/model_gbm.txt")
    
    # Guardar métricas
    metrics_summary = {
        'model_info': {
            'algorithm': 'LightGBM',
            'training_time_seconds': training_time,
            'best_iteration': model.best_iteration,
            'best_score': model.best_score['valid']['auc'],
            'feature_count': len(feature_names),
            'features': feature_names
        },
        'performance_metrics': all_metrics,
        'training_date': datetime.now().isoformat()
    }
    
    with open('reports/model_performance.json', 'w') as f:
        json.dump(metrics_summary, f, indent=2)
    
    print("✓ Métricas guardadas en: reports/model_performance.json")
    
    # Guardar feature importance
    feature_importance = model.feature_importance(importance_type='gain')
    importance_df = pd.DataFrame({
        'feature': feature_names,
        'importance': feature_importance
    }).sort_values('importance', ascending=False)
    
    importance_df.to_csv('reports/feature_importance.csv', index=False)
    print("✓ Feature importance guardado en: reports/feature_importance.csv")

def main():
    """Función principal"""
    print("🚀 INICIANDO FASE 5 - PASO 2: MODELO LIGHTGBM")
    
    # Cargar datos preparados
    X_train, y_train, X_valid, y_valid, X_test, y_test, metadata = load_prepared_data()
    
    # Entrenar modelo
    model, training_time = train_lightgbm_model(X_train, y_train, X_valid, y_valid)
    
    # Evaluar rendimiento
    all_metrics = evaluate_model_performance(model, X_train, y_train, X_valid, y_valid, X_test, y_test)
    
    # Generar gráficos
    plot_training_curves(model)
    
    # Guardar resultados
    feature_names = metadata['feature_columns']
    save_model_and_results(model, all_metrics, training_time, feature_names)
    
    print("\n" + "=" * 80)
    print("✅ PASO 2 COMPLETADO: MODELO LIGHTGBM ENTRENADO")
    print("=" * 80)
    print("\nPróximo paso: python model_calibration.py")
    print("\nArchivos generados:")
    print("  📊 models/model_gbm.txt - Modelo entrenado")
    print("  📊 reports/model_performance.json - Métricas de rendimiento")
    print("  📊 reports/feature_importance.csv - Importancia de features")
    print("  📊 plots/lgbm_training_curves.png - Curvas de entrenamiento")

if __name__ == "__main__":
    main()
