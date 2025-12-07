from sqlalchemy import Column, String, BigInteger, DateTime, Integer
from sqlalchemy.sql import func
from app.core.database import Base

class URL(Base):
    __tablename__ = "urls"

    # BigInteger é essencial para suportar "1000 Bilhões" de registros
    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    original_url = Column(String, nullable=False)
    short_key = Column(String(10), unique=True, index=True, nullable=True)
    clicks = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    def __repr__(self):
        return f"<URL(id={self.id}, short_key='{self.short_key}', original_url='{self.original_url}')>"