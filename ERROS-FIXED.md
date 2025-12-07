# 🔧 Corrigindo os Erros Encontrados

## 🐛 Erro 1: Nginx - Sintaxe inválida (CRÍTICO)

### Sintoma:
```
nginx: [emerg] unknown directive "1,10}$" in /etc/nginx/nginx.conf:59
```

### Causa:
Regex sem escape correto no Nginx.

### Solução:

**Arquivo:** `nginx/nginx.local.conf`

**Linha 59 - ANTES (❌ ERRADO):**
```nginx
location ~ ^/[a-zA-Z0-9]{1,10}$ {
```

**Linha 59 - DEPOIS (✅ CORRETO):**
```nginx
location ~ "^/[a-zA-Z0-9]{1,10}$" {
```

**Mudança:** Adicionar aspas duplas ao redor do regex.

---

## 🐛 Erro 2: Backend - Campo DATABASE_URL extra

### Sintoma:
```
pydantic_core._pydantic_core.ValidationError: 1 validation error for Settings
DATABASE_URL
  Extra inputs are not permitted [type=extra_forbidden, input_value='postgresql+asyncpg://...']
```

### Causa:
Pydantic 2.x não permite campos extras por padrão.

### Solução:

**Arquivo:** `backend/app/core/config.py`

**ANTES (❌ ERRADO):**
```python
class Settings(BaseSettings):
    # ... campos ...
    
    class Config:
        env_file = ".env"
        case_sensitive = True
```

**DEPOIS (✅ CORRETO):**
```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    # ... campos ...
    
    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True,
        extra="ignore"  # <-- ADICIONAR ESTA LINHA
    )
```

---

## 🚀 Passos para Corrigir

### Opção 1: Correção Manual (Rápida)

#### Passo 1: Parar containers
```bash
docker-compose down
```

#### Passo 2: Corrigir nginx/nginx.local.conf

Abra o arquivo e na linha ~59, substitua:
```nginx
# ANTES
location ~ ^/[a-zA-Z0-9]{1,10}$ {

# DEPOIS
location ~ "^/[a-zA-Z0-9]{1,10}$" {
```

#### Passo 3: Corrigir backend/app/core/config.py

Substitua a seção `class Config` por:

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "URL Shortener High-Scale"
    BASE_URL: str = "http://localhost:8000"
    REDIS_URL: str
    DATABASE_WRITE_URL: str
    DATABASE_READ_URLS: str 
    
    @property
    def DATABASE_URL(self) -> str:
        return self.DATABASE_WRITE_URL
    
    @property
    def get_read_urls(self) -> List[str]:
        if not self.DATABASE_READ_URLS:
            return []
        return [url.strip() for url in self.DATABASE_READ_URLS.split(',')]
    
    # NOVO: Configuração do Pydantic v2
    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True,
        extra="ignore"  # Ignora campos extras do .env
    )
```

#### Passo 4: Verificar backend/.env

Certifique-se de ter APENAS estas variáveis:

```bash
PROJECT_NAME="URL Shortener High-Scale"
BASE_URL="http://localhost:8000"
REDIS_URL="redis://redis:6379/0"
DATABASE_WRITE_URL="postgresql+asyncpg://user:password@db_master:5432/shortener_db"
DATABASE_READ_URLS="postgresql+asyncpg://user:password@db_replica_1:5432/shortener_db,postgresql+asyncpg://user:password@db_replica_2:5432/shortener_db,postgresql+asyncpg://user:password@db_replica_3:5432/shortener_db"
```

**REMOVA se existir:**
- ❌ `DATABASE_URL=...` (use apenas DATABASE_WRITE_URL)

#### Passo 5: Rebuild e restart
```bash
docker-compose build
docker-compose up -d
```

#### Passo 6: Verificar
```bash
# Ver logs
docker-compose logs -f

# Testar backend
curl http://localhost:8000/health

# Testar frontend
curl http://localhost
```

---

### Opção 2: Usar Script Automático

```bash
chmod +x scripts/quick-fix.sh
./scripts/quick-fix.sh
```

O script irá:
1. ✅ Fazer backup dos arquivos
2. ✅ Verificar .env
3. ⚠️ Avisar quais arquivos precisam correção
4. ✅ Rebuild e restart automático

---

### Opção 3: Substituir Arquivos Completos

Copie os arquivos corrigidos dos artifacts:

1. **nginx/nginx.local.conf** - Use artifact `nginx_local_fixed`
2. **backend/app/core/config.py** - Use artifact `config_fixed`
3. **backend/.env** - Use artifact `env_file_dev`

---

## ✅ Verificação Final

Após as correções, todos os containers devem estar rodando:

```bash
$ docker-compose ps

NAME                    STATUS              PORTS
shortener_api           Up (healthy)        0.0.0.0:8000->8000/tcp
shortener_db_master     Up (healthy)        0.0.0.0:5432->5432/tcp
shortener_db_replica_1  Up                  0.0.0.0:5433->5432/tcp
shortener_db_replica_2  Up                  0.0.0.0:5434->5432/tcp
shortener_db_replica_3  Up                  0.0.0.0:5435->5432/tcp
shortener_frontend      Up                  0.0.0.0:5173->5173/tcp
shortener_nginx         Up                  0.0.0.0:80->80/tcp
shortener_redis         Up (healthy)        0.0.0.0:6379->6379/tcp
```

### Testar API:

```bash
# Health check
curl http://localhost:8000/health
# Resposta: {"status":"healthy","service":"url-shortener"}

# Criar URL curta
curl -X POST http://localhost:8000/shorten \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.google.com"}'
# Resposta: {"short_url":"http://localhost:8000/1","original_url":"https://www.google.com"}

# Testar redirecionamento
curl -I http://localhost:8000/1
# Resposta: HTTP/1.1 301 Moved Permanently
```

### Testar Frontend:

Abra no navegador: http://localhost

---

## 🆘 Se Ainda Houver Erros

### Logs detalhados:

```bash
# Backend
docker-compose logs app

# Nginx
docker-compose logs nginx

# Frontend
docker-compose logs frontend

# Todos
docker-compose logs -f
```

### Reconstruir do zero:

```bash
# Para tudo e limpa volumes
docker-compose down -v

# Remove imagens antigas
docker-compose down --rmi all

# Rebuild completo
docker-compose build --no-cache

# Inicia novamente
docker-compose up -d

# Acompanha logs
docker-compose logs -f
```

### Verificar configuração do Nginx manualmente:

```bash
docker-compose run --rm nginx nginx -t
```

### Entrar no container para debug:

```bash
# Backend
docker-compose exec app bash
python -c "from app.core.config import settings; print(settings)"

# Nginx
docker-compose exec nginx sh
cat /etc/nginx/nginx.conf
```

---

## 📚 Resumo das Mudanças

| Arquivo | Problema | Solução |
|---------|----------|---------|
| `nginx/nginx.local.conf` | Regex sem aspas | Adicionar `"` ao redor do regex |
| `backend/app/core/config.py` | Campo extra não permitido | Adicionar `extra="ignore"` no model_config |
| `backend/.env` | Variável DATABASE_URL duplicada | Remover, usar apenas DATABASE_WRITE_URL |

---

## ✨ Após Correções

Você terá:
- ✅ Nginx funcionando com regex correto
- ✅ Backend conectando no banco
- ✅ Frontend acessível
- ✅ Sistema completo operacional

Acesse:
- **Frontend**: http://localhost
- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health