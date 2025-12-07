import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.pool import StaticPool

from app.main import app
from app.core.database import Base, get_db
from app.api.v1.endpoints import get_write_service

# 1. Configura Banco em Memória (SQLite) para testes
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

engine = create_async_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)

TestingSessionLocal = async_sessionmaker(
    bind=engine, class_=AsyncSession, expire_on_commit=False
)

# 2. Fixture do Banco de Dados
@pytest_asyncio.fixture
async def db_session():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async with TestingSessionLocal() as session:
        yield session
        
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

# 3. Mock do Redis
class MockRedis:
    """Simula o Redis em memória"""
    def __init__(self):
        self.store = {}
    
    async def get(self, key):
        return self.store.get(key)
    
    async def set(self, key, value, ex=None):
        self.store[key] = value
        return True
    
    async def close(self):
        pass

# 4. Mock do Service com Redis Fake
@pytest_asyncio.fixture
async def test_url_service(db_session):
    from app.repositories.url_repository import URLRepository
    from app.services.url_service import URLService
    
    repo = URLRepository(db_session)
    service = URLService(repo)
    service.redis = MockRedis()
    return service

# 5. Cliente HTTP Assíncrono
@pytest_asyncio.fixture
async def client(db_session, test_url_service):
    async def override_get_db():
        yield db_session
    
    async def override_get_service():
        return test_url_service

    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_write_service] = override_get_service

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    
    app.dependency_overrides.clear()