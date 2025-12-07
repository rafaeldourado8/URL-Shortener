import hashlib
import math
from redis.asyncio import Redis

class BloomFilter:
    def __init__(self, redis_client: Redis, item_count: int = 1000000000, fp_prob: float = 0.01):
        """
        Inicializa o Bloom Filter apoiado no Redis.
        
        :param redis_client: Cliente Redis async
        :param item_count: Número estimado de itens (n) - Default 1 Bilião
        :param fp_prob: Probabilidade de falso positivo desejada (p) - Default 1%
        """
        self.redis = redis_client
        self.item_count = item_count
        self.fp_prob = fp_prob
        
        # Cálculos ótimos para m (tamanho do bit array) e k (número de hashes)
        self.size = self.get_size(item_count, fp_prob)
        self.hash_count = self.get_hash_count(self.size, item_count)
        
        # Nome da chave no Redis
        self.redis_key = "filter:url_bloom"

    def get_size(self, n: int, p: float) -> int:
        """Calcula o tamanho ótimo do bit array (m)"""
        m = -(n * math.log(p)) / (math.log(2) ** 2)
        return int(m)

    def get_hash_count(self, m: int, n: int) -> int:
        """Calcula o número ótimo de funções de hash (k)"""
        k = (m / n) * math.log(2)
        return int(k)

    def _get_hashes(self, item: str):
        """
        Gera 'k' posições de hash usando Double Hashing para performance.
        hash(i) = (h1 + i * h2) % m
        """
        # Hashing duplo usando libs padrão (rápido e sem deps externas)
        encoded = item.encode('utf-8')
        h1 = int(hashlib.sha256(encoded).hexdigest(), 16)
        h2 = int(hashlib.md5(encoded).hexdigest(), 16)
        
        for i in range(self.hash_count):
            yield (h1 + i * h2) % self.size

    async def add(self, item: str):
        """Adiciona um item ao filtro"""
        async with self.redis.pipeline() as pipe:
            for position in self._get_hashes(item):
                pipe.setbit(self.redis_key, position, 1)
            await pipe.execute()

    async def exists(self, item: str) -> bool:
        """
        Verifica se um item PODE existir.
        Retorna True: Pode existir (pequena chance de falso positivo)
        Retorna False: Com certeza NÃO existe
        """
        # Verifica todos os bits. Se algum for 0, o item não existe.
        for position in self._get_hashes(item):
            bit = await self.redis.getbit(self.redis_key, position)
            if not bit:
                return False
        return True