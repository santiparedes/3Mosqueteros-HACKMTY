"""
Configuración de la base de datos PostgreSQL
"""

DB_CONFIG = {
    'dbname': 'credit_analysis',
    'user': 'postgres',
    'password': 'postgres',
    'host': 'localhost',
    'port': '5432'
}

# Para conectar:
# import psycopg2
# from db_config import DB_CONFIG
# conn = psycopg2.connect(**DB_CONFIG)

