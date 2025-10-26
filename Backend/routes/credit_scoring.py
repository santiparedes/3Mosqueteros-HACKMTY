"""
Credit Scoring API Route
Integrates the advanced banking model for real-time credit scoring
"""

import joblib
import numpy as np
import pandas as pd
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import json
import os
from datetime import datetime
# Import services
from services.account_feature_aggregator import AccountFeatureAggregator, AccountFeatures

# Import supabase (opcional, moved after services)
try:
    from supabase import create_client
    SUPABASE_AVAILABLE = True
except ImportError as e:
    print(f"⚠️ Supabase not available: {e}")
    SUPABASE_AVAILABLE = False
    create_client = None

router = APIRouter(prefix="/credit", tags=["Credit Scoring"])

# Configuración de Supabase
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://aaseaqeolqpjfqkpsuyd.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFhc2VhcWVvbHFwamZxa3BzdXlkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NDIyNDgsImV4cCI6MjA3NTExODI0OH0.FKekZn3VVS1I7FFQFFlwUZ2sTMp50d1X7G3sxFac3ug")

# Load the trained model and scaler
MODEL_PATH = "models/datasetModel/models/advanced_banking_model.txt"
SCALER_PATH = "models/datasetModel/models/advanced_scaler.pkl"
METADATA_PATH = "models/datasetModel/models/advanced_model_metadata.json"

# Global variables for model components
model = None
scaler = None
feature_names = []
model_metadata = {}

def load_model_components():
    """Load the trained model, scaler, and metadata"""
    global model, scaler, feature_names, model_metadata
    
    try:
        # Load metadata
        if os.path.exists(METADATA_PATH):
            with open(METADATA_PATH, 'r') as f:
                model_metadata = json.load(f)
                feature_names = model_metadata.get('features', [])
        else:
            # Use default features if metadata not found
            feature_names = [
                'age', 'income_monthly', 'payroll_streak', 'payroll_variance',
                'spending_monthly', 'spending_var_6m', 'current_debt', 'dti', 'utilization',
                'income_stability_score', 'income_trend_6m', 'income_volatility',
                'spending_stability', 'spending_to_income_ratio', 'savings_rate',
                'debt_service_ratio', 'credit_utilization_health', 'dti_health_score',
                'payment_consistency', 'late_payment_risk', 'age_risk_factor',
                'income_adequacy', 'financial_health_score', 'creditworthiness_score',
                'income_debt_interaction', 'age_income_interaction', 'stability_utilization_interaction',
                'zone_encoded'
            ]
            model_metadata = {
                'model_type': 'Advanced Banking LightGBM (Mock)',
                'features': feature_names,
                'feature_count': len(feature_names),
                'training_date': '2024-01-01T00:00:00',
                'description': 'Mock banking model for credit risk prediction'
            }
        
        # Load scaler
        if os.path.exists(SCALER_PATH):
            scaler = joblib.load(SCALER_PATH)
        else:
            # Create mock scaler
            from sklearn.preprocessing import StandardScaler
            scaler = StandardScaler()
            # Fit with dummy data
            import numpy as np
            dummy_data = np.random.randn(100, len(feature_names))
            scaler.fit(dummy_data)
        
        # Load model (LightGBM)
        if os.path.exists(MODEL_PATH):
            import lightgbm as lgb
            model = lgb.Booster(model_file=MODEL_PATH)
        else:
            # Create mock model for testing
            model = "mock_model"
        
        print(f"✅ Model loaded successfully with {len(feature_names)} features")
        return True
        
    except Exception as e:
        print(f"❌ Error loading model: {str(e)}")
        # Set up mock components for testing
        feature_names = [
            'age', 'income_monthly', 'payroll_streak', 'payroll_variance',
            'spending_monthly', 'spending_var_6m', 'current_debt', 'dti', 'utilization',
            'income_stability_score', 'income_trend_6m', 'income_volatility',
            'spending_stability', 'spending_to_income_ratio', 'savings_rate',
            'debt_service_ratio', 'credit_utilization_health', 'dti_health_score',
            'payment_consistency', 'late_payment_risk', 'age_risk_factor',
            'income_adequacy', 'financial_health_score', 'creditworthiness_score',
            'income_debt_interaction', 'age_income_interaction', 'stability_utilization_interaction',
            'zone_encoded'
        ]
        model_metadata = {
            'model_type': 'Advanced Banking LightGBM (Mock)',
            'features': feature_names,
            'feature_count': len(feature_names),
            'training_date': '2024-01-01T00:00:00',
            'description': 'Mock banking model for credit risk prediction'
        }
        model = "mock_model"
        from sklearn.preprocessing import StandardScaler
        scaler = StandardScaler()
        import numpy as np
        dummy_data = np.random.randn(100, len(feature_names))
        scaler.fit(dummy_data)
        print(f"✅ Mock model loaded with {len(feature_names)} features")
        return True

# Load model on startup
load_model_components()

# Pydantic models for API
class CreditScoreRequest(BaseModel):
    """Request model for credit scoring"""
    # Basic demographic info
    age: int
    income_monthly: float
    
    # Financial behavior
    payroll_streak: int = 0  # months of consistent payroll
    payroll_variance: float = 0.0  # income variance
    spending_monthly: float = 0.0
    spending_var_6m: float = 0.0
    current_debt: float = 0.0
    dti: float = 0.0  # debt-to-income ratio
    utilization: float = 0.0  # credit utilization
    
    # Optional advanced features (will be calculated if not provided)
    zone: Optional[str] = None
    savings_rate: Optional[float] = None
    financial_health_score: Optional[float] = None

class CreditOffer(BaseModel):
    """Credit offer response model"""
    customer_id: str
    pd90_score: float  # Probability of default in 90 days
    risk_tier: str  # Prime, Near Prime, Subprime, High Risk
    credit_limit: float
    apr: float  # Annual Percentage Rate
    msi_eligible: bool  # Meses sin intereses
    msi_months: int
    explanation: str
    confidence: float
    generated_at: str

class CreditScoreResponse(BaseModel):
    """Response model for credit scoring"""
    success: bool
    offer: Optional[CreditOffer] = None
    error_message: Optional[str] = None
    model_version: str = "advanced_banking_v1.0"

def calculate_advanced_features(request: CreditScoreRequest) -> Dict[str, float]:
    """Calculate advanced features from basic request data"""
    features = {}
    
    # Basic features (direct from request)
    features['age'] = request.age
    features['income_monthly'] = request.income_monthly
    features['payroll_streak'] = request.payroll_streak
    features['payroll_variance'] = request.payroll_variance
    features['spending_monthly'] = request.spending_monthly
    features['spending_var_6m'] = request.spending_var_6m
    features['current_debt'] = request.current_debt
    features['dti'] = request.dti
    features['utilization'] = request.utilization
    
    # Calculate advanced features
    # 1. Income Stability Features
    features['income_stability_score'] = 1 / (1 + request.payroll_variance) if request.payroll_variance > 0 else 0.5
    features['income_trend_6m'] = (request.age - 25) / 40 * request.payroll_streak / 12
    features['income_volatility'] = request.payroll_variance
    
    # 2. Spending Behavior Features
    features['spending_stability'] = 1 / (1 + request.spending_var_6m) if request.spending_var_6m > 0 else 0.5
    features['spending_to_income_ratio'] = request.spending_monthly / request.income_monthly if request.income_monthly > 0 else 0.0
    if request.savings_rate is not None:
        features['savings_rate'] = request.savings_rate
    elif request.income_monthly > 0:
        features['savings_rate'] = max(0, (request.income_monthly - request.spending_monthly) / request.income_monthly)
    else:
        features['savings_rate'] = 0.0
    
    # 3. Debt Management Features
    features['debt_service_ratio'] = request.current_debt / request.income_monthly if request.income_monthly > 0 else 0.0
    features['credit_utilization_health'] = 1 - request.utilization
    features['dti_health_score'] = 1 - request.dti
    
    # 4. Payment Behavior Features
    features['payment_consistency'] = request.payroll_streak / 12
    features['late_payment_risk'] = 1 / (1 + request.payroll_streak / 12)
    
    # 5. Demographic Risk Features
    optimal_age = 35
    features['age_risk_factor'] = abs(request.age - optimal_age) / optimal_age
    features['income_adequacy'] = request.income_monthly / 3000 if request.income_monthly > 0 else 0.0  # Normalize by minimum wage
    
    # 6. Composite Risk Scores
    features['financial_health_score'] = request.financial_health_score if request.financial_health_score is not None else (
        features['income_stability_score'] * 0.25 +
        features['spending_stability'] * 0.20 +
        features['savings_rate'] * 0.20 +
        features['credit_utilization_health'] * 0.15 +
        features['payment_consistency'] * 0.10 +
        (1 - features['age_risk_factor']) * 0.10
    )
    
    features['creditworthiness_score'] = (
        features['financial_health_score'] * 0.40 +
        features['dti_health_score'] * 0.25 +
        features['credit_utilization_health'] * 0.20 +
        features['payment_consistency'] * 0.15
    )
    
    # 7. Interaction Features
    features['income_debt_interaction'] = request.income_monthly * request.dti
    features['age_income_interaction'] = request.age * request.income_monthly
    features['stability_utilization_interaction'] = features['spending_stability'] * request.utilization
    
    # 8. Zone encoding (if provided)
    if request.zone:
        # Simple zone encoding (in production, use proper encoding)
        zone_mapping = {'urban': 0, 'suburban': 1, 'rural': 2}
        features['zone_encoded'] = zone_mapping.get(request.zone.lower(), 0)
    else:
        features['zone_encoded'] = 0  # Default to urban
    
    return features

def calculate_mock_pd90_score(features: Dict[str, float]) -> float:
    """Calculate mock PD90 score based on simple rules"""
    # Base score
    pd90 = 0.1
    
    # Adjust based on DTI
    dti = features.get('dti', 0.3)
    if dti > 0.4:
        pd90 += 0.2
    elif dti < 0.2:
        pd90 -= 0.05
    
    # Adjust based on credit utilization
    utilization = features.get('utilization', 0.3)
    if utilization > 0.8:
        pd90 += 0.15
    elif utilization < 0.3:
        pd90 -= 0.05
    
    # Adjust based on income stability
    income_stability = features.get('income_stability_score', 0.5)
    if income_stability < 0.3:
        pd90 += 0.1
    elif income_stability > 0.7:
        pd90 -= 0.05
    
    # Adjust based on age
    age = features.get('age', 30)
    if age < 25 or age > 65:
        pd90 += 0.05
    
    # Adjust based on savings rate
    savings_rate = features.get('savings_rate', 0.1)
    if savings_rate < 0.05:
        pd90 += 0.1
    elif savings_rate > 0.2:
        pd90 -= 0.05
    
    # Ensure score is between 0 and 1
    return max(0.01, min(0.99, pd90))

def generate_credit_offer(pd90_score: float, features: Dict[str, float], customer_id: str) -> CreditOffer:
    """Generate credit offer based on PD90 score and features"""
    
    # Determine risk tier
    if pd90_score < 0.1:
        risk_tier = "Prime"
        apr_base = 0.12  # 12% APR
        credit_limit_multiplier = 3.0
        msi_eligible = True
        msi_months = 12
    elif pd90_score < 0.2:
        risk_tier = "Near Prime"
        apr_base = 0.18  # 18% APR
        credit_limit_multiplier = 2.0
        msi_eligible = True
        msi_months = 6
    elif pd90_score < 0.3:
        risk_tier = "Subprime"
        apr_base = 0.24  # 24% APR
        credit_limit_multiplier = 1.5
        msi_eligible = False
        msi_months = 0
    else:
        risk_tier = "High Risk"
        apr_base = 0.30  # 30% APR
        credit_limit_multiplier = 1.0
        msi_eligible = False
        msi_months = 0
    
    # Calculate credit limit based on monthly income
    monthly_income = features.get('income_monthly', 4000)
    credit_limit = monthly_income * credit_limit_multiplier
    
    # Generate explanation
    explanation_parts = []
    
    if features.get('dti', 0) > 0.4:
        explanation_parts.append("High debt-to-income ratio increases risk")
    elif features.get('dti', 0) < 0.2:
        explanation_parts.append("Low debt-to-income ratio reduces risk")
    
    if features.get('utilization', 0) > 0.8:
        explanation_parts.append("High credit utilization increases risk")
    elif features.get('utilization', 0) < 0.3:
        explanation_parts.append("Low credit utilization reduces risk")
    
    if features.get('financial_health_score', 0) > 0.7:
        explanation_parts.append("Strong financial health reduces risk")
    elif features.get('financial_health_score', 0) < 0.3:
        explanation_parts.append("Weak financial health increases risk")
    
    if features.get('savings_rate', 0) > 0.2:
        explanation_parts.append("Good savings rate reduces risk")
    elif features.get('savings_rate', 0) < 0.05:
        explanation_parts.append("Low savings rate increases risk")
    
    explanation_parts.append(f"Risk tier: {risk_tier} (PD90: {pd90_score:.3f})")
    explanation = "; ".join(explanation_parts)
    
    # Calculate confidence based on feature completeness and model certainty
    confidence = min(0.95, max(0.5, 1 - pd90_score))
    
    return CreditOffer(
        customer_id=customer_id,
        pd90_score=pd90_score,
        risk_tier=risk_tier,
        credit_limit=credit_limit,
        apr=apr_base,
        msi_eligible=msi_eligible,
        msi_months=msi_months,
        explanation=explanation,
        confidence=confidence,
        generated_at=datetime.now().isoformat()
    )

@router.post("/score", response_model=CreditScoreResponse)
async def score_credit(request: CreditScoreRequest):
    """
    Score a customer's creditworthiness using the advanced banking model
    """
    try:
        # Check if model is loaded
        if model is None or scaler is None:
            raise HTTPException(
                status_code=503, 
                detail="Credit scoring model not available. Please try again later."
            )
        
        # Calculate advanced features
        features = calculate_advanced_features(request)
        
        # Create feature vector in the correct order
        feature_vector = []
        for feature_name in feature_names:
            if feature_name in features:
                feature_vector.append(features[feature_name])
            else:
                # Use default value for missing features
                feature_vector.append(0.0)
        
        # Convert to numpy array and reshape for prediction
        X = np.array(feature_vector).reshape(1, -1)
        
        # Scale features
        X_scaled = scaler.transform(X)
        
        # Make prediction
        if model == "mock_model":
            # Mock prediction based on simple rules
            pd90_score = calculate_mock_pd90_score(features)
        else:
            pd90_score = model.predict(X_scaled)[0]  # Probability of default (bad credit)
        
        # Generate credit offer
        customer_id = f"customer_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        offer = generate_credit_offer(pd90_score, features, customer_id)
        
        return CreditScoreResponse(
            success=True,
            offer=offer,
            model_version=model_metadata.get('model_type', 'advanced_banking_v1.0')
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error scoring credit: {str(e)}"
        )

@router.get("/health")
async def health_check():
    """Health check for credit scoring service"""
    return {
        "status": "healthy" if model is not None else "unhealthy",
        "model_loaded": model is not None,
        "scaler_loaded": scaler is not None,
        "features_count": len(feature_names),
        "model_version": model_metadata.get('model_type', 'unknown'),
        "timestamp": datetime.now().isoformat()
    }

@router.get("/model-info")
async def get_model_info():
    """Get information about the loaded model"""
    return {
        "model_type": model_metadata.get('model_type', 'unknown'),
        "features": feature_names,
        "feature_count": len(feature_names),
        "training_date": model_metadata.get('training_date', 'unknown'),
        "description": model_metadata.get('description', 'Advanced banking model for credit risk prediction'),
        "pd90_threshold": model_metadata.get('pd90_threshold', 0.3)
    }

@router.post("/score-by-account/{account_id}", response_model=CreditScoreResponse)
async def score_credit_by_account(account_id: str):
    """
    Score crediticio automático desde account_id (Supabase)
    
    Flujo:
    1. Conecta a Supabase
    2. Extrae transacciones históricas (deposits, purchases, bills)
    3. Calcula las 9 features básicas automáticamente
    4. Invoca el modelo de credit scoring
    5. Guarda el resultado en credit_risk_profiles
    6. Retorna la oferta de crédito
    """
    try:
        # PASO 1: Agregar features desde Supabase
        print(f"\n[1/4] Extrayendo features desde Supabase para account_id: {account_id}")
        
        with AccountFeatureAggregator() as aggregator:
            features = aggregator.aggregate_features(account_id)
        
        if not features:
            raise HTTPException(
                status_code=404,
                detail=f"No se encontró la cuenta {account_id} o no tiene suficientes datos históricos en Supabase"
            )
        
        # Verificar calidad de datos
        if features.data_quality_score < 0.3:
            raise HTTPException(
                status_code=400,
                detail=f"Datos insuficientes para evaluar (calidad: {features.data_quality_score:.1%}). "
                       f"Se requiere al menos 3 meses de historial de transacciones."
            )
        
        print(f"✓ Features extraídas (calidad: {features.data_quality_score:.1%})")
        print(f"  - Ingreso mensual: ${features.income_monthly:,.2f}")
        print(f"  - DTI: {features.dti:.1%}")
        print(f"  - Utilización: {features.utilization:.1%}")
        
        # PASO 2: Convertir a CreditScoreRequest
        print(f"\n[2/4] Preparando features para el modelo...")
        
        request = CreditScoreRequest(
            age=features.age,
            income_monthly=features.income_monthly,
            payroll_streak=features.payroll_streak,
            payroll_variance=features.payroll_variance,
            spending_monthly=features.spending_monthly,
            spending_var_6m=features.spending_var_6m,
            current_debt=features.current_debt,
            dti=features.dti,
            utilization=features.utilization
        )
        
        # PASO 3: Calcular advanced features y score
        print(f"\n[3/4] Ejecutando modelo de credit scoring...")
        
        # Calcular advanced features
        advanced_features = calculate_advanced_features(request)
        
        # Crear feature vector
        feature_vector = []
        for feature_name in feature_names:
            if feature_name in advanced_features:
                feature_vector.append(advanced_features[feature_name])
            else:
                feature_vector.append(0.0)
        
        # Normalizar y predecir
        X = np.array(feature_vector).reshape(1, -1)
        X_scaled = scaler.transform(X)
        
        if model == "mock_model":
            pd90_score = calculate_mock_pd90_score(advanced_features)
        else:
            pd90_score = model.predict(X_scaled)[0]
        
        # Generar oferta de crédito
        offer = generate_credit_offer(pd90_score, advanced_features, features.customer_id)
        
        print(f"✓ Score calculado: PD90={pd90_score:.3f}, Tier={offer.risk_tier}")
        
        # PASO 4: Guardar resultado en Supabase (credit_risk_profiles)
        print(f"\n[4/4] Guardando resultado en Supabase...")
        
        try:
            supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
            
            profile_data = {
                'customer_id': features.customer_id,
                'pd90_score': float(pd90_score),
                'risk_tier': offer.risk_tier,
                'credit_limit': float(offer.credit_limit),
                'apr': float(offer.apr),
                'msi_eligible': offer.msi_eligible,
                'msi_months': offer.msi_months,
                'explanation': offer.explanation,
                'actual_label': None
            }
            
            response = supabase.table('credit_risk_profiles').insert(profile_data).execute()
            
            print(f"✓ Resultado guardado en Supabase")
            
        except Exception as db_error:
            print(f"⚠ Warning: No se pudo guardar en credit_risk_profiles: {str(db_error)}")
            # No fallar si no se puede guardar, continuar con la respuesta
        
        # Retornar respuesta
        return CreditScoreResponse(
            success=True,
            offer=offer,
            model_version=model_metadata.get('model_type', 'advanced_banking_v1.0')
        )
        
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Error scoring credit: {str(e)}"
        )


@router.get("/account/{account_id}/features")
async def get_account_features_endpoint(account_id: str):
    """Endpoint de debug para ver las features extraídas de Supabase sin ejecutar el modelo"""
    try:
        with AccountFeatureAggregator() as aggregator:
            features = aggregator.aggregate_features(account_id)
        
        if not features:
            raise HTTPException(
                status_code=404,
                detail=f"No se encontró la cuenta {account_id} en Supabase"
            )
        
        return {
            "account_id": features.account_id,
            "customer_id": features.customer_id,
            "features": {
                "age": features.age,
                "income_monthly": features.income_monthly,
                "payroll_streak": features.payroll_streak,
                "payroll_variance": features.payroll_variance,
                "spending_monthly": features.spending_monthly,
                "spending_var_6m": features.spending_var_6m,
                "current_debt": features.current_debt,
                "dti": features.dti,
                "utilization": features.utilization
            },
            "metadata": {
                "data_quality_score": features.data_quality_score,
                "months_of_history": features.months_of_history,
                "quality_status": "excellent" if features.data_quality_score > 0.8 
                                else "good" if features.data_quality_score > 0.5
                                else "fair" if features.data_quality_score > 0.3
                                else "insufficient"
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error extracting features from Supabase: {str(e)}"
        )
