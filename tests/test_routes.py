import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_create_short_url(client: AsyncClient):
    """Teste: Criar uma URL curta com sucesso"""
    payload = {"url": "https://www.google.com"}
    
    response = await client.post("/shorten", json=payload)
    
    assert response.status_code == 201
    data = response.json()
    assert "short_url" in data
    assert data["original_url"] == payload["url"]
    # Verifica se a URL curta contém a Base URL configurada
    assert "http://localhost:8000" in data["short_url"]

@pytest.mark.asyncio
async def test_redirect_url(client: AsyncClient):
    """Teste: Redirecionar uma URL curta existente"""
    # 1. Primeiro criamos a URL
    payload = {"url": "https://python.org"}
    create_response = await client.post("/shorten", json=payload)
    short_url = create_response.json()["short_url"]
    
    # Extrai a chave (ex: http://localhost:8000/1 -> 1)
    short_key = short_url.split("/")[-1]
    
    # 2. Tenta acessar a chave (deve redirecionar)
    # allow_redirects=False para capturar o 301/307 sem seguir automaticamente
    response = await client.get(f"/{short_key}", follow_redirects=False)
    
    assert response.status_code == 301
    assert response.headers["location"] == payload["url"]

@pytest.mark.asyncio
async def test_url_not_found(client: AsyncClient):
    """Teste: Tentar acessar uma chave que não existe"""
    response = await client.get("/chave_inexistente_123")
    
    assert response.status_code == 404
    assert response.json()["detail"] == "URL not found"

@pytest.mark.asyncio
async def test_invalid_url_format(client: AsyncClient):
    """Teste: Enviar um JSON inválido ou URL malformada"""
    payload = {"url": "não-é-uma-url"}
    
    response = await client.post("/shorten", json=payload)
    
    # Pydantic deve barrar (422 Unprocessable Entity)
    assert response.status_code == 422