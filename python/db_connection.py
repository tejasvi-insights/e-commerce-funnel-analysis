from sqlalchemy import create_engine

def get_engine():
    username = "postgres"
    password = "12345678"
    host = "localhost"
    port = "5432"
    database = "ecommerce_funnel"
    return create_engine(f"postgresql+psycopg2://{username}:{password}@{host}:{port}/{database}")