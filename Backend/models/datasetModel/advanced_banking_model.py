"""
FASE 5 MEJORADA - MODELO BANCARIO AVANZADO
==========================================

Modelo mejorado para hackathon bancario con Capital One's Nessie API.
Incluye features avanzados, predicción PD90, y generación de ofertas dinámicas.
"""
import pandas as pd
import numpy as np
import lightgbm as lgb
import shap
import matplotlib.pyplot as plt
import seaborn as sns
import joblib
import json
from datetime import datetime, timedelta
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import roc_auc_score, average_precision_score, brier_score_loss
from sklearn.calibration import CalibratedClassifierCV
from imblearn.over_sampling import SMOTE
import warnings
warnings.filterwarnings('ignore')

class BankingRiskModel:
    """
    Modelo bancario avanzado para predicción de riesgo crediticio
    """
    
    def __init__(self):
        self.model = None
        self.scaler = StandardScaler()
        self.feature_encoder = LabelEncoder()
        self.feature_names = []
        self.pd90_threshold = 0.3  # Umbral para PD90
        
    def load_and_enhance_data(self):
        """
        Carga datos y crea features bancarios avanzados
        """
        print("=" * 80)
        print("🚀 MODELO BANCARIO AVANZADO - CARGA Y ENHANCEMENT DE DATOS")
        print("=" * 80)
        
        # Crear directorios
        import os
        os.makedirs('models', exist_ok=True)
        os.makedirs('reports', exist_ok=True)
        os.makedirs('plots', exist_ok=True)
        
        # Cargar datasets mejorados
        print("\n1. Cargando datasets mejorados...")
        try:
            train_df = pd.read_csv('dataset_train_improved.csv')
            valid_df = pd.read_csv('dataset_validation_improved.csv')
            test_df = pd.read_csv('dataset_test_improved.csv')
            print(f"   ✓ Train: {len(train_df)} registros")
            print(f"   ✓ Validation: {len(valid_df)} registros")
            print(f"   ✓ Test: {len(test_df)} registros")
        except FileNotFoundError as e:
            print(f"   ✗ Error cargando archivos CSV: {e}")
            return None, None, None, None, None, None
        
        # Combinar todos los datos para crear features avanzados
        all_data = pd.concat([train_df, valid_df, test_df], ignore_index=True)
        
        # Crear features bancarios avanzados
        print("\n2. Creando features bancarios avanzados...")
        enhanced_data = self.create_banking_features(all_data)
        
        # Separar de nuevo por split temporal
        train_enhanced = enhanced_data[enhanced_data['split'] == 'train'].copy()
        valid_enhanced = enhanced_data[enhanced_data['split'] == 'validation'].copy()
        test_enhanced = enhanced_data[enhanced_data['split'] == 'test'].copy()
        
        print(f"   ✓ Features creados: {len(enhanced_data.columns)}")
        print(f"   ✓ Train enhanced: {len(train_enhanced)} registros")
        print(f"   ✓ Validation enhanced: {len(valid_enhanced)} registros")
        print(f"   ✓ Test enhanced: {len(test_enhanced)} registros")
        
        return train_enhanced, valid_enhanced, test_enhanced, enhanced_data
    
    def create_banking_features(self, df):
        """
        Crea features bancarios avanzados para el modelo
        """
        df = df.copy()
        
        # 1. INCOME STABILITY FEATURES
        print("   Creando Income Stability features...")
        df['income_stability_score'] = self.calculate_income_stability(df)
        df['income_trend_6m'] = self.calculate_income_trend(df)
        df['income_volatility'] = df['payroll_variance']  # Ya existe
        
        # 2. SPENDING BEHAVIOR FEATURES
        print("   Creando Spending Behavior features...")
        df['spending_stability'] = 1 / (1 + df['spending_var_6m'].clip(lower=0, upper=100))  # Inverso de varianza
        df['spending_to_income_ratio'] = df['spending_monthly'] / df['income_monthly'].clip(lower=1)  # Avoid division by zero
        df['savings_rate'] = (df['income_monthly'] - df['spending_monthly']) / df['income_monthly'].clip(lower=1)
        df['savings_rate'] = df['savings_rate'].clip(0, 1)  # Limitar entre 0 y 1
        
        # 3. DEBT MANAGEMENT FEATURES
        print("   Creando Debt Management features...")
        df['debt_service_ratio'] = df['current_debt'] / df['income_monthly'].clip(lower=1)  # Avoid division by zero
        df['credit_utilization_health'] = 1 - df['utilization']  # Inverso de utilización
        df['dti_health_score'] = 1 - df['dti']  # Inverso de DTI
        
        # 4. PAYMENT BEHAVIOR FEATURES
        print("   Creando Payment Behavior features...")
        df['payment_consistency'] = df['payroll_streak'] / 12  # Normalizar a años
        # Simular late_payment_risk basado en payroll_streak (menos streak = más riesgo)
        df['late_payment_risk'] = 1 / (1 + df['payroll_streak'] / 12)  # Riesgo inverso al streak
        
        # 5. DEMOGRAPHIC RISK FEATURES
        print("   Creando Demographic Risk features...")
        df['age_risk_factor'] = self.calculate_age_risk(df['age'])
        df['income_adequacy'] = df['income_monthly'] / 3000  # Normalizar por salario mínimo
        df['income_adequacy'] = df['income_adequacy'].clip(lower=0, upper=100)  # Clip to reasonable range
        
        # 6. COMPOSITE RISK SCORES
        print("   Creando Composite Risk Scores...")
        df['financial_health_score'] = self.calculate_financial_health_score(df)
        df['creditworthiness_score'] = self.calculate_creditworthiness_score(df)
        
        # 7. INTERACTION FEATURES
        print("   Creando Interaction Features...")
        df['income_debt_interaction'] = df['income_monthly'] * df['dti']
        df['age_income_interaction'] = df['age'] * df['income_monthly']
        df['stability_utilization_interaction'] = df['spending_stability'] * df['utilization']
        
        # 8. CATEGORICAL FEATURES (si existen)
        if 'zone' in df.columns:
            print("   Codificando features categóricos...")
            df['zone_encoded'] = self.feature_encoder.fit_transform(df['zone'].fillna('Unknown'))
        
        return df
    
    def calculate_income_stability(self, df):
        """Calcula estabilidad de ingresos"""
        # Para datos sintéticos, usar payroll_variance como proxy
        stability = 1 / (1 + df['payroll_variance'])
        # Replace infinities
        stability = np.where(np.isfinite(stability), stability, 0.5)
        return stability
    
    def calculate_income_trend(self, df):
        """Calcula tendencia de ingresos (simulado)"""
        # Para datos sintéticos, crear tendencia basada en edad y estabilidad
        trend = (df['age'] - 25) / 40 * df['payroll_streak'] / 12
        return trend
    
    def calculate_age_risk(self, age):
        """Calcula factor de riesgo por edad"""
        # Curva en U: jóvenes y mayores tienen más riesgo
        optimal_age = 35
        age_numeric = pd.to_numeric(age, errors='coerce').fillna(35)  # Ensure numeric
        risk = np.abs(age_numeric - optimal_age) / optimal_age  # optimal_age is always > 0
        return risk.clip(lower=0, upper=2)  # Clip to reasonable range
    
    def calculate_financial_health_score(self, df):
        """Calcula score compuesto de salud financiera"""
        # Combinar múltiples métricas
        health_score = (
            df['income_stability_score'] * 0.25 +
            df['spending_stability'] * 0.20 +
            df['savings_rate'] * 0.20 +
            df['credit_utilization_health'] * 0.15 +
            df['payment_consistency'] * 0.10 +
            (1 - df['age_risk_factor']) * 0.10
        )
        return health_score
    
    def calculate_creditworthiness_score(self, df):
        """Calcula score de creditworthiness"""
        # Score específico para creditworthiness
        credit_score = (
            df['financial_health_score'] * 0.40 +
            df['dti_health_score'] * 0.25 +
            df['credit_utilization_health'] * 0.20 +
            df['payment_consistency'] * 0.15
        )
        return credit_score
    
    def prepare_model_data(self, train_df, valid_df, test_df):
        """
        Prepara datos para el modelo
        """
        print("\n3. Preparando datos para el modelo...")
        
        # Seleccionar features para el modelo
        feature_cols = [
            # Features originales
            'age', 'income_monthly', 'payroll_streak', 'payroll_variance',
            'spending_monthly', 'spending_var_6m', 'current_debt', 'dti', 'utilization',
            
            # Features bancarios avanzados
            'income_stability_score', 'income_trend_6m', 'income_volatility',
            'spending_stability', 'spending_to_income_ratio', 'savings_rate',
            'debt_service_ratio', 'credit_utilization_health', 'dti_health_score',
            'payment_consistency', 'late_payment_risk', 'age_risk_factor',
            'income_adequacy', 'financial_health_score', 'creditworthiness_score',
            'income_debt_interaction', 'age_income_interaction', 'stability_utilization_interaction'
        ]
        
        # Agregar zone si existe
        if 'zone_encoded' in train_df.columns:
            feature_cols.append('zone_encoded')
        
        # Filtrar features que existen
        available_features = [col for col in feature_cols if col in train_df.columns]
        self.feature_names = available_features
        
        print(f"   ✓ Features seleccionados: {len(available_features)}")
        print(f"   ✓ Features: {available_features}")
        
        # Separar features y target
        X_train = train_df[available_features]
        y_train = train_df['label']
        X_valid = valid_df[available_features]
        y_valid = valid_df['label']
        X_test = test_df[available_features]
        y_test = test_df['label']
        
        # Manejar valores faltantes y infinitos
        print("\n4. Manejando valores faltantes e infinitos...")
        for col in available_features:
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
                    # Si toda la columna es NaN, usar 0
                    X_train[col] = X_train[col].fillna(0)
                    X_valid[col] = X_valid[col].fillna(0)
                    X_test[col] = X_test[col].fillna(0)
        
        # Aplicar SMOTE si es necesario
        print("\n5. Aplicando balanceo de clases...")
        if y_train.sum() / len(y_train) < 0.3:
            smote = SMOTE(random_state=42)
            X_train, y_train = smote.fit_resample(X_train, y_train)
            print(f"   ✓ SMOTE aplicado. Nuevo balance: {y_train.value_counts().to_dict()}")
        else:
            print("   ✓ Balance adecuado, SMOTE no necesario")
        
        # Normalizar features
        print("\n6. Normalizando features...")
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_valid_scaled = self.scaler.transform(X_valid)
        X_test_scaled = self.scaler.transform(X_test)
        
        X_train = pd.DataFrame(X_train_scaled, columns=available_features, index=X_train.index)
        X_valid = pd.DataFrame(X_valid_scaled, columns=available_features, index=X_valid.index)
        X_test = pd.DataFrame(X_test_scaled, columns=available_features, index=X_test.index)
        
        print("   ✓ Features normalizados")
        
        return X_train, y_train, X_valid, y_valid, X_test, y_test
    
    def train_advanced_model(self, X_train, y_train, X_valid, y_valid):
        """
        Entrena modelo LightGBM avanzado
        """
        print("\n7. Entrenando modelo LightGBM avanzado...")
        
        # Calcular scale_pos_weight
        neg_count = y_train.value_counts()[0]
        pos_count = y_train.value_counts()[1]
        scale_pos_weight = neg_count / pos_count if pos_count > 0 else 1
        
        print(f"   Class distribution: Bad={pos_count}, Good={neg_count}")
        print(f"   Scale pos weight: {scale_pos_weight:.3f}")
        
        # Hiperparámetros optimizados para modelo bancario (MEJORADOS para reducir overfitting)
        params = {
            'objective': 'binary',
            'metric': 'auc',
            'boosting_type': 'gbdt',
            'num_leaves': 15,  # Reducido para evitar overfitting (era 31)
            'learning_rate': 0.05,
            'n_estimators': 3000,
            'subsample': 0.8,
            'subsample_freq': 5,
            'colsample_bytree': 0.8,
            'min_child_samples': 20,  # Aumentado para mayor regularización (era 10)
            'min_child_weight': 0.01,  # Aumentado para mayor regularización (era 0.001)
            'reg_alpha': 0.5,  # Aumentada regularización L1 (era 0.1)
            'reg_lambda': 0.5,  # Aumentada regularización L2 (era 0.1)
            'random_state': 42,
            'verbose': -1,
            'scale_pos_weight': scale_pos_weight,
            'feature_fraction': 0.8,
            'bagging_fraction': 0.8,
            'bagging_freq': 5,
            'max_depth': 5,  # Reducido para evitar overfitting (era 8)
            'min_split_gain': 0.0
        }
        
        print("   Hiperparámetros configurados:")
        for k, v in params.items():
            print(f"     {k}: {v}")
        
        # Callbacks para early stopping (más agresivo para evitar overfitting)
        callbacks = [
            lgb.early_stopping(stopping_rounds=50, verbose=True),  # Reducido de 100 para parar antes
            lgb.log_evaluation(period=25)  # Log más frecuente
        ]
        
        # Entrenar modelo
        print("\n   Iniciando entrenamiento...")
        self.model = lgb.LGBMClassifier(**params)
        self.model.fit(
            X_train, y_train,
            eval_set=[(X_train, y_train), (X_valid, y_valid)],
            eval_names=['train', 'valid'],
            eval_metric='auc',
            callbacks=callbacks
        )
        
        print(f"\n   ✓ Entrenamiento completado")
        print(f"   ✓ Mejor iteración: {self.model.best_iteration_}")
        print(f"   ✓ Mejor score: {self.model.best_score_['valid']['auc']:.4f}")
        
        return self.model
    
    def generate_credit_offers(self, X_test, y_test):
        """
        Genera ofertas de crédito dinámicas basadas en el modelo
        """
        print("\n8. Generando ofertas de crédito dinámicas...")
        
        # Obtener probabilidades de default
        y_proba = self.model.predict_proba(X_test)[:, 1]  # Probabilidad de ser "bad"
        pd90_scores = y_proba  # PD90 = Probabilidad de Default a 90 días
        
        offers = []
        
        for i, (pd90, actual_label) in enumerate(zip(pd90_scores, y_test)):
            # Determinar tier de riesgo
            if pd90 < 0.1:
                risk_tier = "Prime"
                apr_base = 0.12  # 12% APR
                credit_limit_multiplier = 3.0
                msi_eligible = True
            elif pd90 < 0.2:
                risk_tier = "Near Prime"
                apr_base = 0.18  # 18% APR
                credit_limit_multiplier = 2.0
                msi_eligible = True
            elif pd90 < 0.3:
                risk_tier = "Subprime"
                apr_base = 0.24  # 24% APR
                credit_limit_multiplier = 1.5
                msi_eligible = False
            else:
                risk_tier = "High Risk"
                apr_base = 0.30  # 30% APR
                credit_limit_multiplier = 1.0
                msi_eligible = False
            
            # Calcular límite de crédito (basado en ingresos mensuales)
            # Asumir ingresos mensuales promedio para el ejemplo
            monthly_income = 4000  # Valor promedio
            credit_limit = monthly_income * credit_limit_multiplier
            
            # Generar explicación
            explanation = self.generate_explanation(X_test.iloc[i], pd90, risk_tier)
            
            offer = {
                'customer_id': f'customer_{i}',
                'pd90_score': float(pd90),
                'risk_tier': risk_tier,
                'credit_limit': float(credit_limit),
                'apr': apr_base,
                'msi_eligible': msi_eligible,
                'msi_months': 12 if msi_eligible else 0,
                'explanation': explanation,
                'actual_label': int(actual_label)
            }
            
            offers.append(offer)
        
        print(f"   ✓ {len(offers)} ofertas generadas")
        
        # Guardar ofertas
        with open('reports/credit_offers.json', 'w') as f:
            json.dump(offers, f, indent=2)
        
        print("   ✓ Ofertas guardadas en: reports/credit_offers.json")
        
        return offers
    
    def generate_explanation(self, features, pd90, risk_tier):
        """
        Genera explicación de la decisión crediticia
        """
        explanations = []
        
        # Obtener valores de features más importantes
        feature_values = dict(zip(self.feature_names, features))
        
        # Explicaciones basadas en features más importantes
        if 'dti' in feature_values:
            dti = feature_values['dti']
            if dti > 0.4:
                explanations.append("High debt-to-income ratio increases risk")
            elif dti < 0.2:
                explanations.append("Low debt-to-income ratio reduces risk")
        
        if 'utilization' in feature_values:
            util = feature_values['utilization']
            if util > 0.8:
                explanations.append("High credit utilization increases risk")
            elif util < 0.3:
                explanations.append("Low credit utilization reduces risk")
        
        if 'financial_health_score' in feature_values:
            health = feature_values['financial_health_score']
            if health > 0.7:
                explanations.append("Strong financial health reduces risk")
            elif health < 0.3:
                explanations.append("Weak financial health increases risk")
        
        if 'savings_rate' in feature_values:
            savings = feature_values['savings_rate']
            if savings > 0.2:
                explanations.append("Good savings rate reduces risk")
            elif savings < 0.05:
                explanations.append("Low savings rate increases risk")
        
        # Agregar explicación del tier
        explanations.append(f"Risk tier: {risk_tier} (PD90: {pd90:.3f})")
        
        return "; ".join(explanations)
    
    def find_optimal_threshold(self, X_valid, y_valid):
        """
        Encuentra el threshold óptimo para maximizar F1-score
        """
        from sklearn.metrics import f1_score
        
        # Obtener probabilidades
        y_proba = self.model.predict_proba(X_valid)[:, 1]
        
        # Probar diferentes thresholds
        thresholds = np.arange(0.1, 0.9, 0.05)
        best_threshold = 0.5
        best_f1 = 0
        
        for threshold in thresholds:
            y_pred = (y_proba >= threshold).astype(int)
            f1 = f1_score(y_valid, y_pred, zero_division=0)
            if f1 > best_f1:
                best_f1 = f1
                best_threshold = threshold
        
        print(f"\n   Optimal threshold: {best_threshold:.3f} (F1: {best_f1:.3f})")
        return best_threshold
    
    def evaluate_model(self, X_train, y_train, X_valid, y_valid, X_test, y_test):
        """
        Evalúa el modelo y genera métricas
        """
        print("\n9. Evaluando modelo...")
        
        # Encontrar threshold óptimo en validation set
        optimal_threshold = self.find_optimal_threshold(X_valid, y_valid)
        
        datasets = {
            'Train': (X_train, y_train),
            'Validation': (X_valid, y_valid),
            'Test': (X_test, y_test)
        }
        
        results = {}
        
        for name, (X, y) in datasets.items():
            y_proba = self.model.predict_proba(X)[:, 1]
            # Usar threshold óptimo en vez de 0.5
            y_pred = (y_proba >= optimal_threshold).astype(int)
            
            metrics = {
                'auc_roc': float(roc_auc_score(y, y_proba)),
                'pr_auc': float(average_precision_score(y, y_proba)),
                'brier_score': float(brier_score_loss(y, y_proba)),
                'accuracy': float((y_pred == y).mean()),
                'precision': float((y_pred[y == 1] == 1).mean()) if (y == 1).sum() > 0 else 0.0,
                'recall': float((y_pred[y == 1] == 1).sum() / (y == 1).sum()) if (y == 1).sum() > 0 else 0.0,
                'n_samples': int(len(y)),
                'n_good': int((y == 1).sum()),
                'n_bad': int((y == 0).sum())
            }
            
            results[name] = metrics
            print(f"   {name}: AUC={metrics['auc_roc']:.3f}, Acc={metrics['accuracy']:.3f}, Precision={metrics['precision']:.3f}, Recall={metrics['recall']:.3f}")
        
        # Guardar resultados con threshold óptimo
        results['optimal_threshold'] = float(optimal_threshold)
        with open('reports/advanced_model_performance.json', 'w') as f:
            json.dump(results, f, indent=2)
        
        print("   ✓ Métricas guardadas en: reports/advanced_model_performance.json")
        
        return results
    
    def generate_shap_explanations(self, X_test, y_test):
        """
        Genera explicaciones SHAP avanzadas
        """
        print("\n10. Generando explicaciones SHAP avanzadas...")
        
        # Crear explainer
        explainer = shap.TreeExplainer(self.model)
        
        # Calcular SHAP values
        shap_values = explainer.shap_values(X_test)
        
        if isinstance(shap_values, list):
            shap_values_class1 = shap_values[1]
            expected_value = explainer.expected_value[1]
        else:
            shap_values_class1 = shap_values
            expected_value = explainer.expected_value
        
        # Generar gráficos
        plt.figure(figsize=(12, 8))
        shap.summary_plot(shap_values_class1, X_test, feature_names=self.feature_names, show=False)
        plt.title('Advanced Banking Model - SHAP Summary', fontsize=14, fontweight='bold')
        plt.tight_layout()
        plt.savefig('plots/advanced_shap_summary.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        # Feature importance
        feature_importance = np.abs(shap_values_class1).mean(0)
        importance_df = pd.DataFrame({
            'feature': self.feature_names,
            'importance': feature_importance
        }).sort_values('importance', ascending=False)
        
        plt.figure(figsize=(10, 8))
        plt.barh(importance_df['feature'], importance_df['importance'])
        plt.xlabel('Mean |SHAP Value|', fontsize=12)
        plt.title('Advanced Banking Model - Feature Importance', fontsize=14, fontweight='bold')
        plt.tight_layout()
        plt.savefig('plots/advanced_feature_importance.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        # Guardar importancia
        importance_df.to_csv('reports/advanced_feature_importance.csv', index=False)
        
        print("   ✓ Gráficos SHAP generados")
        print("   ✓ Feature importance guardado")
        
        return shap_values_class1, expected_value
    
    def calibrate_model(self, X_valid, y_valid, X_test, y_test):
        """
        Calibra las probabilidades del modelo para mejorar Brier Score
        """
        from sklearn.calibration import CalibratedClassifierCV, calibration_curve
        
        print("\n10b. Calibrando probabilidades...")
        
        # Usar el modelo directamente (ya está entrenado)
        # Probar Isotonic
        try:
            calibrated_iso = CalibratedClassifierCV(
                self.model, method='isotonic', cv='prefit'
            )
            calibrated_iso.fit(X_valid, y_valid)
            
            # Evaluar Isotonic
            y_proba_iso = calibrated_iso.predict_proba(X_test)[:, 1]
            brier_iso = float(brier_score_loss(y_test, y_proba_iso))
            print(f"   Isotonic Brier: {brier_iso:.4f}")
        except Exception as e:
            print(f"   Isotonic failed: {e}")
            calibrated_iso = None
            brier_iso = None
        
        # Probar Sigmoid
        try:
            calibrated_sig = CalibratedClassifierCV(
                self.model, method='sigmoid', cv='prefit'
            )
            calibrated_sig.fit(X_valid, y_valid)
            
            # Evaluar Sigmoid
            y_proba_sig = calibrated_sig.predict_proba(X_test)[:, 1]
            brier_sig = float(brier_score_loss(y_test, y_proba_sig))
            print(f"   Sigmoid Brier: {brier_sig:.4f}")
        except Exception as e:
            print(f"   Sigmoid failed: {e}")
            calibrated_sig = None
            brier_sig = None
        
        # Baseline sin calibrar
        y_proba_raw = self.model.predict_proba(X_test)[:, 1]
        brier_raw = float(brier_score_loss(y_test, y_proba_raw))
        
        # Seleccionar mejor método
        best_method = "raw"
        best_brier = brier_raw
        best_calibrated = None
        
        if brier_iso is not None and brier_iso < best_brier:
            best_method = "isotonic"
            best_brier = brier_iso
            best_calibrated = calibrated_iso
            joblib.dump(calibrated_iso, 'models/model_calibrated_isotonic.pkl')
            print(f"   ✓ Mejor método: Isotonic (Brier: {brier_iso:.4f})")
        
        if brier_sig is not None and brier_sig < best_brier:
            best_method = "sigmoid"
            best_brier = brier_sig
            best_calibrated = calibrated_sig
            joblib.dump(calibrated_sig, 'models/model_calibrated_sigmoid.pkl')
            print(f"   ✓ Mejor método: Sigmoid (Brier: {brier_sig:.4f})")
        
        if best_method == "raw":
            print(f"   ✓ Mejor método: Raw (sin calibrar, Brier: {brier_raw:.4f})")
        
        # Guardar resultados
        calibration_results = {
            'raw_brier': float(brier_raw),
            'isotonic_brier': float(brier_iso) if brier_iso is not None else None,
            'sigmoid_brier': float(brier_sig) if brier_sig is not None else None,
            'best_method': best_method,
            'best_brier': float(best_brier)
        }
        
        with open('reports/calibration_results.json', 'w') as f:
            json.dump(calibration_results, f, indent=2)
        
        print("   ✓ Resultados de calibración guardados")
        
        return best_calibrated, best_method
    
    def save_model(self):
        """
        Guarda el modelo entrenado
        """
        print("\n11. Guardando modelo avanzado...")
        
        # Crear directorios
        import os
        os.makedirs('models', exist_ok=True)
        os.makedirs('reports', exist_ok=True)
        os.makedirs('plots', exist_ok=True)
        
        # Also create at the start of the script
        if hasattr(self, '_dirs_created') and not self._dirs_created:
            self._dirs_created = True
        
        # Guardar modelo
        self.model.booster_.save_model('models/advanced_banking_model.txt')
        joblib.dump(self.scaler, 'models/advanced_scaler.pkl')
        
        # Guardar metadata
        metadata = {
            'model_type': 'Advanced Banking LightGBM',
            'features': self.feature_names,
            'feature_count': len(self.feature_names),
            'pd90_threshold': self.pd90_threshold,
            'training_date': datetime.now().isoformat(),
            'description': 'Advanced banking model with enhanced features for credit risk prediction'
        }
        
        with open('models/advanced_model_metadata.json', 'w') as f:
            json.dump(metadata, f, indent=2)
        
        print("   ✓ Modelo guardado en: models/advanced_banking_model.txt")
        print("   ✓ Scaler guardado en: models/advanced_scaler.pkl")
        print("   ✓ Metadata guardado en: models/advanced_model_metadata.json")

def main():
    """
    Función principal para entrenar el modelo bancario avanzado
    """
    print("🚀 INICIANDO MODELO BANCARIO AVANZADO")
    print("=" * 80)
    
    # Crear instancia del modelo
    banking_model = BankingRiskModel()
    
    # Cargar y mejorar datos
    train_df, valid_df, test_df, all_data = banking_model.load_and_enhance_data()
    
    if train_df is None:
        print("❌ Error cargando datos. Terminando.")
        return
    
    # Preparar datos para el modelo
    X_train, y_train, X_valid, y_valid, X_test, y_test = banking_model.prepare_model_data(
        train_df, valid_df, test_df
    )
    
    # Entrenar modelo
    banking_model.train_advanced_model(X_train, y_train, X_valid, y_valid)
    
    # Evaluar modelo
    results = banking_model.evaluate_model(X_train, y_train, X_valid, y_valid, X_test, y_test)
    
    # Calibrar modelo (MEJORA NUEVA)
    banking_model.calibrate_model(X_valid, y_valid, X_test, y_test)
    
    # Generar ofertas de crédito
    offers = banking_model.generate_credit_offers(X_test, y_test)
    
    # Generar explicaciones SHAP
    shap_values, expected_value = banking_model.generate_shap_explanations(X_test, y_test)
    
    # Guardar modelo
    banking_model.save_model()
    
    print("\n" + "=" * 80)
    print("✅ MODELO BANCARIO AVANZADO COMPLETADO")
    print("=" * 80)
    print("\n📊 RESUMEN DE RESULTADOS:")
    print(f"   Features utilizados: {len(banking_model.feature_names)}")
    print(f"   Ofertas generadas: {len(offers)}")
    print(f"   Test AUC-ROC: {results['Test']['auc_roc']:.3f}")
    print(f"   Test Accuracy: {results['Test']['accuracy']:.3f}")
    
    print("\n📁 ARCHIVOS GENERADOS:")
    print("   🤖 models/advanced_banking_model.txt - Modelo entrenado")
    print("   🤖 models/advanced_scaler.pkl - Scaler")
    print("   📊 reports/advanced_model_performance.json - Métricas")
    print("   📊 reports/credit_offers.json - Ofertas de crédito")
    print("   📊 reports/advanced_feature_importance.csv - Importancia")
    print("   📈 plots/advanced_shap_summary.png - SHAP Summary")
    print("   📈 plots/advanced_feature_importance.png - Feature Importance")

if __name__ == "__main__":
    main()
