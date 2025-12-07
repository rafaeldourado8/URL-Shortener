import random
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
from app.core.config import settings

# 1. Engine Master (Escrita e Leituras Críticas)
engine_master = create_async_engine(settings.DATABASE_WRITE_URL, echo=False)
SessionMaster = async_sessionmaker(
    bind=engine_master, class_=AsyncSession, expire_on_commit=False, autoflush=False
)

# 2. Engines de Réplica (Apenas Leitura)
engines_read = [
    create_async_engine(url, echo=False) 
    for url in settings.get_read_urls
]
# Se não houver réplicas (dev), usa o master como leitura também
if not engines_read:
    engines_read = [engine_master]

# Base para Models
Base = declarative_base()

# 3. Dependência de Banco de Dados (Padrão/Escrita)
# Injeta uma sessão conectada ao MASTER
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with SessionMaster() as session:
        try:
            yield session
        finally:
            await session.close()

# 4. Dependência de Banco de Dados (Leitura)
# Injeta uma sessão conectada a uma RÉPLICA ALEATÓRIA
async def get_read_db() -> AsyncGenerator[AsyncSession, None]:
    # Seleciona uma engine de leitura aleatoriamente (Load Balancing)
    engine = random.choice(engines_read)
    
    SessionRead = async_sessionmaker(
        bind=engine, class_=AsyncSession, expire_on_commit=False, autoflush=False
    )
    
    async with SessionRead() as session:
        try:
            yield session
        finally:
            await session.close()