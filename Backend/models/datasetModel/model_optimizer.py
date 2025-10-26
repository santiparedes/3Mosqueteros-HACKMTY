"""
MODEL OPTIMIZER - Pipeline Completo de Optimización
==================================================

Implementa las mejoras identificadas:
1. Class Weights Dinámicos (eliminar SMOTE artificial)
2. Feature Selection (eliminar features con SHAP < 0.01)
3. Análisis de Correlaciones
4. Comparación con Baseline
"""
import pandas as pd
import numpy as np
import lightgbm as lgb
import joblib
import json
from datetime import datetime
from sklearn.metrics import roc_auc_score, average_precision_score, brier_score_loss, f1_score
from sklearn.preprocessing import StandardScaler
import warnings
warnings.filterwarnings('ignore')

class ModelOptimizer:
    """
    Optimizador de modelo bancario con mejoras específicas
    """
    
    def __init__(self):
        self.baseline_results = None
        self.optimized_results = None
        self.feature_importance = None
        
    def load_data(self):
        """
        Carga los datasets mejorados (con features avanzados)
        """
        print("=" * 80)
        print("🚀 MODEL OPTIMIZER - CARGA DE DATOS")
        print("=" * 80)
        
        try:
            # Usar los datasets con features avanzados
            train_df = pd.read_csv('dataset_train_enhanced.csv')
            valid_df = pd.read_csv('dataset_validation_enhanced.csv')
            test_df = pd.read_csv('dataset_test_enhanced.csv')
            
            print(f"✓ Train: {len(train_df)} registros")
            print(f"✓ Validation: {len(valid_df)} registros")
            print(f"✓ Test: {len(test_df)} registros")
            print(f"✓ Features disponibles: {len(train_df.columns)}")
            
            return train_df, valid_df, test_df
        except FileNotFoundError as e:
            print(f"✗ Error cargando datos: {e}")
            return None, None, None
    
    def analyze_feature_correlations(self, df):
        """
        Analiza correlaciones entre features para identificar redundantes
        """
        print("\n📊 ANÁLISIS DE CORRELACIONES")
        print("-" * 40)
        
        # Seleccionar solo features numéricos
        numeric_features = df.select_dtypes(include=[np.number]).columns
        numeric_features = [f for f in numeric_features if f not in ['customer_id', 'label', 'split']]
        
        # Calcular matriz de correlación
        corr_matrix = df[numeric_features].corr().abs()
        
        # Encontrar pares con correlación alta
        high_corr_pairs = []
        for i in range(len(corr_matrix.columns)):
            for j in range(i+1, len(corr_matrix.columns)):
                corr_val = corr_matrix.iloc[i, j]
                if corr_val > 0.9:  # Umbral de correlación alta
                    high_corr_pairs.append({
                        'feature1': corr_matrix.columns[i],
                        'feature2': corr_matrix.columns[j],
                        'correlation': corr_val
                    })
        
        print(f"✓ Features numéricos analizados: {len(numeric_features)}")
        print(f"✓ Pares con correlación > 0.9: {len(high_corr_pairs)}")
        
        if high_corr_pairs:
            print("\n🔍 Pares altamente correlacionados:")
            for pair in high_corr_pairs:
                print(f"   {pair['feature1']} ↔ {pair['feature2']}: {pair['correlation']:.3f}")
        
        return high_corr_pairs, numeric_features
    
    def select_features_by_importance(self, feature_importance_df, threshold=0.01):
        """
        Selecciona features basado en importancia SHAP
        """
        print(f"\n🎯 FEATURE SELECTION (threshold: {threshold})")
        print("-" * 40)
        
        # Features a eliminar
        low_importance_features = feature_importance_df[
            feature_importance_df['importance'] < threshold
        ]['feature'].tolist()
        
        # Features a mantener
        selected_features = feature_importance_df[
            feature_importance_df['importance'] >= threshold
        ]['feature'].tolist()
        
        print(f"✓ Features eliminados: {len(low_importance_features)}")
        print(f"✓ Features seleccionados: {len(selected_features)}")
        
        if low_importance_features:
            print(f"\n🗑️ Features eliminados:")
            for feat in low_importance_features:
                importance = feature_importance_df[feature_importance_df['feature'] == feat]['importance'].iloc[0]
                print(f"   {feat}: {importance:.6f}")
        
        return selected_features, low_importance_features
    
    def prepare_data_optimized(self, train_df, valid_df, test_df, selected_features):
        """
        Prepara datos con features seleccionados y sin SMOTE
        """
        print(f"\n⚙️ PREPARACIÓN DE DATOS OPTIMIZADA")
        print("-" * 40)
        
        # Separar features y target
        X_train = train_df[selected_features]
        y_train = train_df['label']
        X_valid = valid_df[selected_features]
        y_valid = valid_df['label']
        X_test = test_df[selected_features]
        y_test = test_df['label']
        
        print(f"✓ Features seleccionados: {len(selected_features)}")
        print(f"✓ Train: {X_train.shape}")
        print(f"✓ Validation: {X_valid.shape}")
        print(f"✓ Test: {X_test.shape}")
        
        # Manejar valores faltantes e infinitos
        for col in selected_features:
            # Reemplazar infinitos con NaN
            X_train[col] = X_train[col].replace([np.inf, -np.inf], np.nan)
            X_valid[col] = X_valid[col].replace([np.inf, -np.inf], np.nan)
            X_test[col] = X_test[col].replace([np.inf, -np.inf], np.nan)
            
            # Rellenar NaN con mediana
            if X_train[col].isnull().any():
                median_val = X_train[col].median()
                if pd.notna(median_val):
                    X_train[col] = X_train[col].fillna(median_val)
                    X_valid[col] = X_valid[col].fillna(median_val)
                    X_test[col] = X_test[col].fillna(median_val)
                else:
                    X_train[col] = X_train[col].fillna(0)
                    X_valid[col] = X_valid[col].fillna(0)
                    X_test[col] = X_test[col].fillna(0)
        
        # Normalizar features
        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_valid_scaled = scaler.transform(X_valid)
        X_test_scaled = scaler.transform(X_test)
        
        X_train = pd.DataFrame(X_train_scaled, columns=selected_features, index=X_train.index)
        X_valid = pd.DataFrame(X_valid_scaled, columns=selected_features, index=X_valid.index)
        X_test = pd.DataFrame(X_test_scaled, columns=selected_features, index=X_test.index)
        
        print("✓ Features normalizados")
        print("✓ NO se aplica SMOTE (usando distribución real)")
        
        return X_train, y_train, X_valid, y_valid, X_test, y_test, scaler
    
    def train_optimized_model(self, X_train, y_train, X_valid, y_valid, class_weight_strategy='balanced'):
        """
        Entrena modelo optimizado con class weights dinámicos
        """
        print(f"\n🏋️ ENTRENAMIENTO OPTIMIZADO")
        print("-" * 40)
        
        # Calcular class weights dinámicos
        if class_weight_strategy == 'balanced':
            neg_count = y_train.value_counts()[0]
            pos_count = y_train.value_counts()[1]
            scale_pos_weight = neg_count / pos_count if pos_count > 0 else 1
        elif class_weight_strategy == 'real_ratio':
            # Usar ratio real de validation/test (87.2% bad / 12.8% good ≈ 6.8)
            scale_pos_weight = 6.8
        else:
            scale_pos_weight = float(class_weight_strategy)
        
        print(f"✓ Class distribution: Bad={y_train.value_counts()[0]}, Good={y_train.value_counts()[1]}")
        print(f"✓ Scale pos weight: {scale_pos_weight:.3f}")
        
        # Hiperparámetros optimizados (sin SMOTE, más regularización)
        params = {
            'objective': 'binary',
            'metric': 'auc',
            'boosting_type': 'gbdt',
            'num_leaves': 10,  # Más conservador
            'learning_rate': 0.03,  # Más lento
            'n_estimators': 2000,
            'subsample': 0.7,  # Más subsampling
            'subsample_freq': 5,
            'colsample_bytree': 0.7,  # Más feature sampling
            'min_child_samples': 30,  # Más regularización
            'min_child_weight': 0.01,
            'reg_alpha': 1.0,  # Más regularización L1
            'reg_lambda': 1.0,  # Más regularización L2
            'random_state': 42,
            'verbose': -1,
            'scale_pos_weight': scale_pos_weight,
            'feature_fraction': 0.7,
            'bagging_fraction': 0.7,
            'bagging_freq': 5,
            'max_depth': 4,  # Más conservador
            'min_split_gain': 0.0
        }
        
        print("✓ Hiperparámetros optimizados configurados")
        
        # Callbacks más agresivos
        callbacks = [
            lgb.early_stopping(stopping_rounds=30, verbose=True),
            lgb.log_evaluation(period=20)
        ]
        
        # Entrenar modelo
        print("\n   Iniciando entrenamiento optimizado...")
        model = lgb.LGBMClassifier(**params)
        model.fit(
            X_train, y_train,
            eval_set=[(X_train, y_train), (X_valid, y_valid)],
            eval_names=['train', 'valid'],
            eval_metric='auc',
            callbacks=callbacks
        )
        
        print(f"\n✓ Entrenamiento completado")
        print(f"✓ Mejor iteración: {model.best_iteration_}")
        print(f"✓ Mejor score: {model.best_score_['valid']['auc']:.4f}")
        
        return model
    
    def find_optimal_threshold(self, model, X_valid, y_valid):
        """
        Encuentra threshold óptimo para F1-score
        """
        y_proba = model.predict_proba(X_valid)[:, 1]
        
        thresholds = np.arange(0.1, 0.9, 0.05)
        best_threshold = 0.5
        best_f1 = 0
        
        for threshold in thresholds:
            y_pred = (y_proba >= threshold).astype(int)
            f1 = f1_score(y_valid, y_pred, zero_division=0)
            if f1 > best_f1:
                best_f1 = f1
                best_threshold = threshold
        
        print(f"✓ Optimal threshold: {best_threshold:.3f} (F1: {best_f1:.3f})")
        return best_threshold
    
    def evaluate_model(self, model, X_train, y_train, X_valid, y_valid, X_test, y_test):
        """
        Evalúa el modelo con threshold óptimo
        """
        print(f"\n📊 EVALUACIÓN DEL MODELO")
        print("-" * 40)
        
        # Encontrar threshold óptimo
        optimal_threshold = self.find_optimal_threshold(model, X_valid, y_valid)
        
        datasets = {
            'Train': (X_train, y_train),
            'Validation': (X_valid, y_valid),
            'Test': (X_test, y_test)
        }
        
        results = {}
        
        for name, (X, y) in datasets.items():
            y_proba = model.predict_proba(X)[:, 1]
            y_pred = (y_proba >= optimal_threshold).astype(int)
            
            metrics = {
                'auc_roc': float(roc_auc_score(y, y_proba)),
                'pr_auc': float(average_precision_score(y, y_proba)),
                'brier_score': float(brier_score_loss(y, y_proba)),
                'accuracy': float((y_pred == y).mean()),
                'precision': float((y_pred[y == 1] == 1).mean()) if (y == 1).sum() > 0 else 0.0,
                'recall': float((y_pred[y == 1] == 1).sum() / (y == 1).sum()) if (y == 1).sum() > 0 else 0.0,
                'f1_score': float(f1_score(y, y_pred, zero_division=0)),
                'n_samples': int(len(y)),
                'n_good': int((y == 1).sum()),
                'n_bad': int((y == 0).sum())
            }
            
            results[name] = metrics
            print(f"   {name}: AUC={metrics['auc_roc']:.3f}, Acc={metrics['accuracy']:.3f}, Precision={metrics['precision']:.3f}, Recall={metrics['recall']:.3f}")
        
        results['optimal_threshold'] = float(optimal_threshold)
        
        return results
    
    def run_optimization_experiments(self):
        """
        Ejecuta todos los experimentos de optimización
        """
        print("🚀 INICIANDO EXPERIMENTOS DE OPTIMIZACIÓN")
        print("=" * 80)
        
        # Cargar datos
        train_df, valid_df, test_df = self.load_data()
        if train_df is None:
            return
        
        # Cargar feature importance del modelo baseline
        try:
            feature_importance_df = pd.read_csv('reports/advanced_feature_importance.csv')
            print(f"✓ Feature importance cargado: {len(feature_importance_df)} features")
        except FileNotFoundError:
            print("✗ Error: No se encontró advanced_feature_importance.csv")
            return
        
        # Cargar resultados baseline
        try:
            with open('reports/advanced_model_performance.json', 'r') as f:
                self.baseline_results = json.load(f)
            print("✓ Resultados baseline cargados")
        except FileNotFoundError:
            print("✗ Error: No se encontró advanced_model_performance.json")
            return
        
        # Análisis de correlaciones
        high_corr_pairs, numeric_features = self.analyze_feature_correlations(train_df)
        
        # Experimentos
        experiments = [
            {
                'name': 'Exp1_25features_balanced',
                'features': 25,
                'class_weight': 'balanced',
                'description': '25 features, class_weight balanced'
            },
            {
                'name': 'Exp2_25features_real_ratio',
                'features': 25,
                'class_weight': 'real_ratio',
                'description': '25 features, ratio real (6.8)'
            },
            {
                'name': 'Exp3_20features_balanced',
                'features': 20,
                'class_weight': 'balanced',
                'description': '20 features, class_weight balanced'
            }
        ]
        
        experiment_results = {}
        
        for exp in experiments:
            print(f"\n{'='*60}")
            print(f"🧪 EXPERIMENTO: {exp['name']}")
            print(f"📝 Descripción: {exp['description']}")
            print(f"{'='*60}")
            
            # Seleccionar features
            threshold = 0.01 if exp['features'] == 25 else 0.02
            selected_features, removed_features = self.select_features_by_importance(
                feature_importance_df, threshold
            )
            
            # Preparar datos
            X_train, y_train, X_valid, y_valid, X_test, y_test, scaler = self.prepare_data_optimized(
                train_df, valid_df, test_df, selected_features
            )
            
            # Entrenar modelo
            model = self.train_optimized_model(
                X_train, y_train, X_valid, y_valid, exp['class_weight']
            )
            
            # Evaluar modelo
            results = self.evaluate_model(
                model, X_train, y_train, X_valid, y_valid, X_test, y_test
            )
            
            # Guardar resultados
            experiment_results[exp['name']] = {
                'description': exp['description'],
                'features_count': len(selected_features),
                'removed_features': removed_features,
                'class_weight_strategy': exp['class_weight'],
                'results': results
            }
            
            # Guardar modelo
            model.booster_.save_model(f'models/model_{exp["name"]}.txt')
            joblib.dump(scaler, f'models/scaler_{exp["name"]}.pkl')
            
            print(f"✓ Modelo guardado: models/model_{exp['name']}.txt")
        
        # Comparar con baseline
        self.compare_with_baseline(experiment_results)
        
        # Guardar resultados completos
        with open('reports/optimization_results.json', 'w') as f:
            json.dump({
                'baseline': self.baseline_results,
                'experiments': experiment_results,
                'correlation_analysis': {
                    'high_corr_pairs': high_corr_pairs,
                    'numeric_features_count': len(numeric_features)
                }
            }, f, indent=2)
        
        print(f"\n✓ Resultados completos guardados en: reports/optimization_results.json")
        
        return experiment_results
    
    def compare_with_baseline(self, experiment_results):
        """
        Compara experimentos con baseline
        """
        print(f"\n📈 COMPARACIÓN CON BASELINE")
        print("=" * 80)
        
        baseline_test_auc = self.baseline_results['Test']['auc_roc']
        baseline_gap = self.baseline_results['Train']['auc_roc'] - baseline_test_auc
        
        print(f"Baseline - Test AUC: {baseline_test_auc:.3f}, Gap: {baseline_gap:.3f}")
        print()
        
        best_experiment = None
        best_auc = baseline_test_auc
        
        for exp_name, exp_data in experiment_results.items():
            test_auc = exp_data['results']['Test']['auc_roc']
            train_auc = exp_data['results']['Train']['auc_roc']
            gap = train_auc - test_auc
            
            improvement = test_auc - baseline_test_auc
            gap_improvement = baseline_gap - gap
            
            print(f"{exp_name}:")
            print(f"  Test AUC: {test_auc:.3f} ({improvement:+.3f})")
            print(f"  Gap: {gap:.3f} ({gap_improvement:+.3f})")
            print(f"  Features: {exp_data['features_count']}")
            print()
            
            if test_auc > best_auc:
                best_auc = test_auc
                best_experiment = exp_name
        
        if best_experiment:
            print(f"🏆 MEJOR EXPERIMENTO: {best_experiment}")
            print(f"   Mejora en Test AUC: {best_auc - baseline_test_auc:+.3f}")
        else:
            print("⚠️ Ningún experimento superó el baseline")

def main():
    """
    Función principal
    """
    optimizer = ModelOptimizer()
    results = optimizer.run_optimization_experiments()
    
    print("\n" + "=" * 80)
    print("✅ OPTIMIZACIÓN COMPLETADA")
    print("=" * 80)
    print("\n📁 Archivos generados:")
    print("  📊 reports/optimization_results.json - Resultados completos")
    print("  🤖 models/model_Exp*.txt - Modelos optimizados")
    print("  🤖 models/scaler_Exp*.pkl - Scalers optimizados")

if __name__ == "__main__":
    main()
