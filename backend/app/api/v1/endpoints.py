from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import RedirectResponse
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db, get_read_db
from app.repositories.url_repository import URLRepository
from app.services.url_service import URLService
from app.schemas.url import URLCreate, URLResponse

router = APIRouter()

# -----------------------------------------------------------------------------
# Dependency Injection Factories
# -----------------------------------------------------------------------------

async def get_write_service(db: AsyncSession = Depends(get_db)) -> URLService:
    """
    Fornece uma instância de URLService conectada ao banco MASTER (Escrita).
    Usado para operações que alteram dados (POST, PUT, DELETE).
    """
    repo = URLRepository(db)
    return URLService(repo)

async def get_read_service(db: AsyncSession = Depends(get_read_db)) -> URLService:
    """
    Fornece uma instância de URLService conectada a uma RÉPLICA (Leitura).
    Usado para operações de apenas leitura (GET).
    O Load Balancing entre as réplicas acontece dentro de 'get_read_db'.
    """
    repo = URLRepository(db)
    return URLService(repo)

# -----------------------------------------------------------------------------
# Endpoints
# -----------------------------------------------------------------------------

@router.post(
    "/shorten", 
    response_model=URLResponse, 
    status_code=status.HTTP_201_CREATED
)
async def shorten_url(
    item: URLCreate, 
    service: URLService = Depends(get_write_service)
):
    """
    Cria uma nova URL encurtada.
    
    Fluxo:
    1. Recebe a URL longa.
    2. Verifica Bloom Filter (opcional).
    3. Persiste no Banco MASTER (Write).
    4. Atualiza Cache (Redis).
    5. Retorna URL curta.
    """
    try:
        short_url = await service.shorten_url(str(item.url))
        return URLResponse(short_url=short_url, original_url=str(item.url))
    except Exception as e:
        # Em produção, logar o erro real aqui
        print(f"Error shortening URL: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail="Erro ao processar a solicitação."
        )

@router.get("/{short_key}")
async def redirect_to_url(
    short_key: str, 
    service: URLService = Depends(get_read_service)
):
    """
    Redireciona para a URL original.
    
    Fluxo:
    1. Verifica Cache (Redis). Se achar, retorna imediatamente (rápido).
    2. Se não achar (Cache Miss), consulta uma RÉPLICA de Banco de Dados (Read).
    3. Se achar no banco, popula o Cache e redireciona.
    4. Se não achar em lugar nenhum, 404.
    """
    original_url = await service.get_original_url(short_key)
    
    if original_url:
        # Status 301 (Moved Permanently) é melhor para SEO e cache de navegador
        # Status 302/307 (Temporary) é melhor se você quiser trackear cliques sempre no backend
        return RedirectResponse(url=original_url, status_code=301)
    
    raise HTTPException(status_code=404, detail="URL not found")