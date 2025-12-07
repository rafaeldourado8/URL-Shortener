from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.models.url import URL

class URLRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, original_url: str) -> URL:
        # Apenas cria o registro para obter o ID (estratégia de ID incremental)
        # Em arquitetura distribuída (Zookeeper), o ID viria de fora.
        db_url = URL(original_url=original_url)
        self.db.add(db_url)
        await self.db.commit()
        await self.db.refresh(db_url)
        return db_url

    async def update_short_key(self, url_id: int, short_key: str):
        query = select(URL).where(URL.id == url_id)
        result = await self.db.execute(query)
        db_url = result.scalar_one_or_none()
        if db_url:
            db_url.short_key = short_key
            await self.db.commit()
            await self.db.refresh(db_url)
        return db_url

    async def get_by_key(self, short_key: str) -> URL:
        query = select(URL).where(URL.short_key == short_key)
        result = await self.db.execute(query)
        return result.scalar_one_or_none()