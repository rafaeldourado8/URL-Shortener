from typing import List
from pydantic_settings import BaseSettings
from pydantic import AnyHttpUrl, validator

class Settings(BaseSettings):
    PROJECT_NAME: str = "URL Shortener High-Scale"
    BASE_URL: str = "http://localhost:8000"
    
    # Configuração do Redis
    REDIS_URL: str

    # --- NOVO: Configuração de Cluster DB ---
    # URL do Master (Escrita)
    DATABASE_WRITE_URL: str
    
    # URLs das Réplicas (Leitura) - Vem como string separada por vírgula no .env
    DATABASE_READ_URLS: str 

    # Propriedade computada para facilitar uso legacy se necessário
    @property
    def DATABASE_URL(self) -> str:
        return self.DATABASE_WRITE_URL

    # Valida e transforma a string de réplicas em lista
    @property
    def get_read_urls(self) -> List[str]:
        if not self.DATABASE_READ_URLS:
            return []
        return [url.strip() for url in self.DATABASE_READ_URLS.split(',')]

    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()