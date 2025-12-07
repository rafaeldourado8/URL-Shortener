import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.pool import StaticPool

from app.main import app
from app.core.database import Base, get_db
from app.services.url_service import URLService
from app.repositories.url_repository import URLRepository

# 1. Configura Banco em Memória (SQLite) para testes
# check_same_thread=False é necessário para SQLite com asyncio
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

engine = create_async_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool, # Mantém dados em memória entre requests
)

TestingSessionLocal = async_sessionmaker(
    bind=engine, class_=AsyncSession, expire_on_commit=False
)

# 2. Fixture do Banco de Dados
@pytest_asyncio.fixture
async def db_session():
    # Cria as tabelas
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async with TestingSessionLocal() as session:
        yield session
        
    # Limpa as tabelas após o teste
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

# 3. Mock do Redis e BloomFilter
# Criamos um Service falso ou mockamos os métodos que usam Redis
class MockRedis:
    """Simula o Redis em memória (Dicionário)"""
    def __init__(self):
        self.store = {}
    
    async def get(self, key):
        return self.store.get(key)
    
    async def set(self, key, value, ex=None):
        self.store[key] = value
        return True

class MockBloomFilter:
    """Simula Bloom Filter sempre retornando False (não existe)"""
    async def exists(self, item):
        return False
    
    async def add(self, item):
        pass

# 4. Override da Dependência do Service
# Injetamos o Service com o Mock do Redis para não depender de infra externa
def get_test_url_service(db: AsyncSession):
    repo = URLRepository(db)
    service = URLService(repo)
    # Substitui componentes reais por Mocks
    service.redis = MockRedis()
    service.bloom_filter = MockBloomFilter()
    return service

# 5. Cliente HTTP Assíncrono (O "Navegador" dos testes)
@pytest_asyncio.fixture
async def client(db_session):
    # Override: Sempre que a API pedir 'get_db', entrega o SQLite
    async def override_get_db():
        yield db_session

    # Override: Sempre que pedir o Service, entrega o Service com Mock Redis
    def override_get_service():
        return get_test_url_service(db_session)

    app.dependency_overrides[get_db] = override_get_db
    # Precisamos importar a dependencia original do endpoint para sobrescrever
    from app.api.v1.endpoints import get_url_service
    app.dependency_overrides[get_url_service] = override_get_service

    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac
    
    # Limpa overrides
    app.dependency_overrides.clear()