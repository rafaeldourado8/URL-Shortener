import string
import redis.asyncio as redis
from app.repositories.url_repository import URLRepository
from app.core.config import settings
from app.services.bloom_filter import BloomFilter

# Alfabeto para Base62 (0-9, a-z, A-Z) conforme requisitos
BASE62 = string.digits + string.ascii_letters 

class URLService:
    def __init__(self, repository: URLRepository):
        self.repository = repository
        self.redis = redis.from_url(settings.REDIS_URL, decode_responses=True)

    def _encode_base62(self, num: int) -> str:
        """Converte ID numérico para Base62 (menor hash possível)."""
        if num == 0:
            return BASE62[0]
        arr = []
        base = len(BASE62)
        while num:
            num, rem = divmod(num, base)
            arr.append(BASE62[rem])
        arr.reverse()
        return ''.join(arr)

    async def shorten_url(self, original_url: str) -> str:
        # 1. Persistir para gerar ID
        url_record = await self.repository.create(original_url)
        
        # 2. Gerar Hash baseado no ID (garante unicidade sem colisão)
        short_key = self._encode_base62(url_record.id)
        
        # 3. Atualizar registro com a chave
        await self.repository.update_short_key(url_record.id, short_key)
        
        # 4. Bloom Filter "Write" check entraria aqui (conforme diagrama)
        
        # 5. Salvar no Cache (Write-through strategy)
        await self.redis.set(short_key, original_url, ex=3600) # Expira em 1h
        
        return f"{settings.BASE_URL}/{short_key}"

    async def get_original_url(self, short_key: str) -> str:
        # 1. Tentar Cache (Redis) -> Fluxo "200" do diagrama
        cached_url = await self.redis.get(short_key)
        if cached_url:
            return cached_url
            
        # 2. Cache Miss -> Buscar no DB
        url_record = await self.repository.get_by_key(short_key)
        if url_record:
            # Popula o cache (Lazy Loading)
            await self.redis.set(short_key, url_record.original_url, ex=3600)
            return url_record.original_url
            
        return None