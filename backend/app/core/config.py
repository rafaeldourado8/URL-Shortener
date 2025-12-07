from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "URL Shortener High-Scale"
    BASE_URL: str = "http://localhost:8000"
    
    # Configuração do Redis
    REDIS_URL: str
    
    # --- Database Configuration ---
    # URL do Master (Escrita)
    DATABASE_WRITE_URL: str
    
    # URLs das Réplicas (Leitura) - String separada por vírgula
    DATABASE_READ_URLS: str 
    
    # Propriedade computada para compatibilidade legacy
    @property
    def DATABASE_URL(self) -> str:
        """Alias para DATABASE_WRITE_URL (compatibilidade)"""
        return self.DATABASE_WRITE_URL
    
    # Valida e transforma a string de réplicas em lista
    @property
    def get_read_urls(self) -> List[str]:
        """Retorna lista de URLs de réplicas"""
        if not self.DATABASE_READ_URLS:
            return []
        return [url.strip() for url in self.DATABASE_READ_URLS.split(',')]
    
    # Configuração do Pydantic v2
    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True,
        extra="ignore"  # IMPORTANTE: Ignora campos extras do .env
    )

settings = Settings()