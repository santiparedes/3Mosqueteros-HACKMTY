"""
Account Feature Aggregator Service - Supabase Version
Extrae datos de Supabase PostgreSQL y calcula las features necesarias para el modelo de credit scoring
"""

from supabase import create_client, Client
from typing import Dict, Optional, List
from datetime import datetime, timedelta
import numpy as np
from pydantic import BaseModel
import os

# Configuración de Supabase (desde variables de entorno o AppConfig)
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://aaseaqeolqpjfqkpsuyd.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFhc2VhcWVvbHFwamZxa3BzdXlkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NDIyNDgsImV4cCI6MjA3NTExODI0OH0.FKekZn3VVS1I7FFQFFlwUZ2sTMp50d1X7G3sxFac3ug")

class AccountFeatures(BaseModel):
    """Modelo para las features calculadas"""
    # Basic features (9)
    age: int
    income_monthly: float
    payroll_streak: int
    payroll_variance: float
    spending_monthly: float
    spending_var_6m: float
    current_debt: float
    dti: float
    utilization: float

    # Metadata
    account_id: str
    customer_id: str
    data_quality_score: float
    months_of_history: int

class AccountFeatureAggregator:
    """
    Servicio para agregar datos históricos de transacciones desde Supabase y calcular features
    """

    def __init__(self, supabase_url: str = None, supabase_key: str = None):
        self.supabase_url = supabase_url or SUPABASE_URL
        self.supabase_key = supabase_key or SUPABASE_KEY
        self.client: Client = None

    def connect(self):
        """Conecta a Supabase"""
        if not self.client:
            self.client = create_client(self.supabase_url, self.supabase_key)
        return self.client

    def __enter__(self):
        self.connect()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        # Supabase client no necesita cierre explícito
        pass

    def get_customer_and_account_data(self, account_id: str) -> Optional[Dict]:
        """
        Extrae datos básicos del cliente y cuenta desde Supabase

        Returns:
            {
                'customer_id': str,
                'account_id': str,
                'birth_date': date,
                'age': int,
                'balance': float,
                'credit_limit': float,
                'profile': str
            }
        """
        try:
            # Query para obtener cuenta con customer info
            response = self.client.table('accounts') \
                .select('*, customers!inner(customer_id, birth_date, profile)') \
                .eq('account_id', account_id) \
                .execute()
            
            if not response.data or len(response.data) == 0:
                return None
            
            account = response.data[0]
            customer = account['customers']
            
            # Calcular edad
            if customer.get('birth_date'):
                birth_date = datetime.fromisoformat(customer['birth_date'].replace('Z', '+00:00'))
                age = (datetime.now() - birth_date).days // 365
            else:
                age = 30  # Default
            
            return {
                'customer_id': customer['customer_id'],
                'account_id': account['account_id'],
                'birth_date': customer.get('birth_date'),
                'age': age,
                'balance': float(account.get('balance', 0) or 0),
                'credit_limit': float(account.get('credit_limit', 0) or 0),
                'profile': customer.get('profile', 'unknown')
            }
        except Exception as e:
            print(f"Error getting account data: {str(e)}")
            return None

    def get_deposit_history(self, account_id: str, months: int = 12) -> List[Dict]:
        """
        Extrae historial de depósitos (nómina) desde Supabase

        Returns:
            Lista de depósitos mensuales con estadísticas
        """
        try:
            # Calcular fecha límite
            cutoff_date = (datetime.now() - timedelta(days=months * 30)).isoformat()
            
            # Query para obtener depósitos
            response = self.client.table('deposits') \
                .select('transaction_date, amount') \
                .eq('account_id', account_id) \
                .eq('status', 'completed') \
                .gte('transaction_date', cutoff_date) \
                .execute()
            
            if not response.data:
                return []
            
            # Agrupar por mes manualmente
            monthly_deposits = {}
            for deposit in response.data:
                date = datetime.fromisoformat(deposit['transaction_date'].replace('Z', '+00:00'))
                month_key = date.strftime('%Y-%m')
                
                if month_key not in monthly_deposits:
                    monthly_deposits[month_key] = []
                monthly_deposits[month_key].append(float(deposit['amount']))
            
            # Calcular estadísticas por mes
            result = []
            for month, amounts in monthly_deposits.items():
                result.append({
                    'month': datetime.strptime(month, '%Y-%m'),
                    'deposit_count': len(amounts),
                    'avg_deposit': np.mean(amounts),
                    'stddev_deposit': np.std(amounts) if len(amounts) > 1 else 0,
                    'total_deposit': np.sum(amounts)
                })
            
            # Ordenar por mes descendente
            result.sort(key=lambda x: x['month'], reverse=True)
            return result
            
        except Exception as e:
            print(f"Error getting deposit history: {str(e)}")
            return []

    def get_spending_history(self, account_id: str, months: int = 6) -> List[Dict]:
        """
        Extrae historial de gastos (compras) desde Supabase

        Returns:
            Lista de gastos mensuales con estadísticas
        """
        try:
            cutoff_date = (datetime.now() - timedelta(days=months * 30)).isoformat()
            
            response = self.client.table('purchases') \
                .select('purchase_date, amount') \
                .eq('account_id', account_id) \
                .eq('status', 'completed') \
                .gte('purchase_date', cutoff_date) \
                .execute()
            
            if not response.data:
                return []
            
            # Agrupar por mes
            monthly_spending = {}
            for purchase in response.data:
                date = datetime.fromisoformat(purchase['purchase_date'].replace('Z', '+00:00'))
                month_key = date.strftime('%Y-%m')
                
                if month_key not in monthly_spending:
                    monthly_spending[month_key] = []
                monthly_spending[month_key].append(float(purchase['amount']))
            
            # Calcular estadísticas
            result = []
            for month, amounts in monthly_spending.items():
                result.append({
                    'month': datetime.strptime(month, '%Y-%m'),
                    'purchase_count': len(amounts),
                    'total_spending': np.sum(amounts),
                    'avg_purchase': np.mean(amounts),
                    'stddev_spending': np.std(amounts) if len(amounts) > 1 else 0
                })
            
            result.sort(key=lambda x: x['month'], reverse=True)
            return result
            
        except Exception as e:
            print(f"Error getting spending history: {str(e)}")
            return []

    def get_pending_debt(self, account_id: str) -> float:
        """
        Calcula deuda pendiente total desde Supabase (bills + balance negativo)

        Returns:
            Total de deuda pendiente
        """
        try:
            # Obtener bills pendientes
            response = self.client.table('bills') \
                .select('payment_amount') \
                .eq('account_id', account_id) \
                .in_('status', ['pending', 'recurring']) \
                .execute()
            
            bills_debt = sum(float(bill['payment_amount']) for bill in response.data) if response.data else 0.0
            
            # Obtener balance de la cuenta
            account_response = self.client.table('accounts') \
                .select('balance') \
                .eq('account_id', account_id) \
                .execute()
            
            if account_response.data:
                balance = float(account_response.data[0].get('balance', 0))
                balance_debt = abs(min(balance, 0))  # Solo si es negativo
                return bills_debt + balance_debt
            
            return bills_debt
            
        except Exception as e:
            print(f"Error getting pending debt: {str(e)}")
            return 0.0

    def calculate_payroll_streak(self, deposit_history: List[Dict]) -> int:
        """Calcula cuántos meses consecutivos ha tenido depósitos"""
        if not deposit_history:
            return 0

        streak = 0
        expected_month = datetime.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)

        for deposit in deposit_history:
            month = deposit['month'].replace(day=1, hour=0, minute=0, second=0, microsecond=0)

            if month == expected_month:
                streak += 1
                expected_month = expected_month - timedelta(days=1)
                expected_month = expected_month.replace(day=1)
            else:
                break

        return streak

    def calculate_coefficient_of_variation(self, values: List[float]) -> float:
        """Calcula el coeficiente de variación (CV = stddev / mean)"""
        if not values or len(values) < 2:
            return 0.0

        mean = np.mean(values)
        if mean == 0:
            return 0.0

        stddev = np.std(values)
        return float(stddev / mean)

    def aggregate_features(self, account_id: str) -> Optional[AccountFeatures]:
        """
        Agrega todas las features necesarias para el modelo desde Supabase

        Args:
            account_id: ID de la cuenta a analizar

        Returns:
            AccountFeatures con todas las features calculadas o None si no hay datos
        """
        try:
            # 1. Datos básicos del cliente y cuenta
            account_data = self.get_customer_and_account_data(account_id)
            if not account_data:
                print(f"No se encontró cuenta con ID: {account_id}")
                return None

            # 2. Historial de depósitos (12 meses)
            deposit_history = self.get_deposit_history(account_id, months=12)

            # 3. Historial de gastos (6 meses)
            spending_history = self.get_spending_history(account_id, months=6)

            # 4. Deuda pendiente
            pending_debt = self.get_pending_debt(account_id)

            # ========================================
            # CALCULAR LAS 9 FEATURES BÁSICAS
            # ========================================

            # FEATURE 1: AGE
            age = int(account_data['age'])

            # FEATURE 2: INCOME_MONTHLY
            if deposit_history:
                monthly_deposits = [float(d['avg_deposit']) for d in deposit_history if d['avg_deposit']]
                income_monthly = np.mean(monthly_deposits) if monthly_deposits else 0.0
            else:
                income_monthly = 0.0

            # FEATURE 3: PAYROLL_STREAK
            payroll_streak = self.calculate_payroll_streak(deposit_history)

            # FEATURE 4: PAYROLL_VARIANCE
            if deposit_history and len(deposit_history) >= 2:
                monthly_deposits = [float(d['avg_deposit']) for d in deposit_history if d['avg_deposit']]
                payroll_variance = self.calculate_coefficient_of_variation(monthly_deposits)
            else:
                payroll_variance = 0.0

            # FEATURE 5: SPENDING_MONTHLY
            if spending_history:
                monthly_spending = [float(s['total_spending']) for s in spending_history if s['total_spending']]
                spending_monthly = np.mean(monthly_spending) if monthly_spending else 0.0
            else:
                spending_monthly = 0.0

            # FEATURE 6: SPENDING_VAR_6M
            if spending_history and len(spending_history) >= 2:
                monthly_spending = [float(s['total_spending']) for s in spending_history if s['total_spending']]
                spending_var_6m = self.calculate_coefficient_of_variation(monthly_spending)
            else:
                spending_var_6m = 0.0

            # FEATURE 7: CURRENT_DEBT
            current_debt = float(pending_debt)

            # FEATURE 8: DTI (Debt-to-Income Ratio)
            if income_monthly > 0:
                dti = current_debt / income_monthly
            else:
                dti = 0.0

            # FEATURE 9: UTILIZATION (Credit Card Utilization)
            credit_limit = float(account_data.get('credit_limit', 0) or 0)
            balance = float(account_data.get('balance', 0) or 0)

            if credit_limit > 0:
                used_credit = max(0, credit_limit - balance)
                utilization = used_credit / credit_limit
            else:
                utilization = 0.0

            # ========================================
            # CALCULAR CALIDAD DE DATOS
            # ========================================

            data_quality_factors = [
                1.0 if len(deposit_history) >= 3 else len(deposit_history) / 3,
                1.0 if len(spending_history) >= 3 else len(spending_history) / 3,
                1.0 if 18 <= age <= 100 else 0.5,
                1.0 if income_monthly > 0 else 0.0,
                1.0 if credit_limit > 0 else 0.5
            ]
            data_quality_score = np.mean(data_quality_factors)
            months_of_history = max(len(deposit_history), len(spending_history))

            return AccountFeatures(
                age=age,
                income_monthly=income_monthly,
                payroll_streak=payroll_streak,
                payroll_variance=payroll_variance,
                spending_monthly=spending_monthly,
                spending_var_6m=spending_var_6m,
                current_debt=current_debt,
                dti=dti,
                utilization=utilization,
                account_id=account_id,
                customer_id=account_data['customer_id'],
                data_quality_score=data_quality_score,
                months_of_history=months_of_history
            )

        except Exception as e:
            print(f"Error agregando features para account {account_id}: {str(e)}")
            import traceback
            traceback.print_exc()
            return None


def get_account_features(account_id: str) -> Optional[AccountFeatures]:
    """Función de utilidad para obtener features de una cuenta"""
    with AccountFeatureAggregator() as aggregator:
        return aggregator.aggregate_features(account_id)

