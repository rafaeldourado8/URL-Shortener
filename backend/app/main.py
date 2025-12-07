from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.endpoints import router
from app.core.database import engine_master, Base

app = FastAPI(
    title="URL Shortener High-Scale",
    description="Implementação robusta baseada em SOLID e Clean Architecture",
    version="1.0.0"
)

# CORS para o frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Em produção, especifique os domínios permitidos
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup():
    """
    Cria as tabelas no banco de dados (apenas para desenvolvimento).
    Em produção, use Alembic para migrações controladas.
    """
    async with engine_master.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

@app.get("/health")
async def health_check():
    """Endpoint de health check para o Load Balancer"""
    return {"status": "healthy", "service": "url-shortener"}

app.include_router(router)