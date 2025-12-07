# 🔗 URL Shortener - High-Scale Architecture

[![Deploy Backend](https://github.com/seu-usuario/url-shortener/actions/workflows/deploy-backend-ec2.yml/badge.svg)](https://github.com/seu-usuario/url-shortener/actions/workflows/deploy-backend-ec2.yml)
[![Deploy Frontend](https://github.com/seu-usuario/url-shortener/actions/workflows/deploy-frontend-vercel.yml/badge.svg)](https://github.com/seu-usuario/url-shortener/actions/workflows/deploy-frontend-vercel.yml)

Sistema de encurtamento de URLs com arquitetura escalável, preparado para lidar com **bilhões de URLs** e **milhões de requisições por dia**.

## 🚀 Features

- ⚡ **Alta Performance**: Redis Caching + PostgreSQL Read Replicas
- 📊 **Escalável**: Suporta 1000+ Bilhões de URLs
- 🔒 **Seguro**: Criptografia, rate limiting, CORS configurável
- 🌐 **Global**: Deploy multi-região com CDN (CloudFront/Vercel)
- 🔄 **Load Balancing**: Nginx com algoritmo least_conn
- 📈 **Monitoramento**: CloudWatch, Performance Insights
- 🧪 **Testado**: Cobertura de testes com pytest
- 🤖 **CI/CD**: GitHub Actions para deploy automático

## 🏗️ Arquitetura

```
Frontend (React + Vite)
    ↓
Vercel/CloudFront (CDN)
    ↓
Nginx (Load Balancer)
    ↓
Backend API (FastAPI) - N Instâncias
    ↓
├── Redis (Cache) - ElastiCache Cluster
└── PostgreSQL (RDS)
    ├── Master (Escrita)
    └── 3x Read Replicas (Leitura)
```

## 🛠️ Stack Tecnológica

### Backend
- **Framework**: FastAPI 0.100+
- **Database**: PostgreSQL 15 (AWS RDS)
- **Cache**: Redis 7 (AWS ElastiCache)
- **ORM**: SQLAlchemy 2.0 (Async)
- **Migration**: Alembic
- **Testing**: Pytest + Pytest-asyncio

### Frontend
- **Framework**: React 18
- **Build Tool**: Vite 4
- **Styling**: TailwindCSS 3
- **Animations**: Framer Motion
- **HTTP Client**: Axios
- **Icons**: Lucide React

### Infrastructure
- **IaC**: Terraform
- **Container**: Docker + Docker Compose
- **Reverse Proxy**: Nginx
- **Cloud Provider**: AWS
- **CI/CD**: GitHub Actions
- **Monitoring**: CloudWatch

## 📋 Pré-requisitos

- Docker & Docker Compose
- Node.js 18+
- Python 3.11+
- Terraform (para deploy AWS)
- Conta AWS
- GitHub CLI (opcional)

## 🚀 Quick Start

### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/url-shortener.git
cd url-shortener
```

### 2. Configure variáveis de ambiente

```bash
cp backend/.env.example backend/.env
# Edite backend/.env com suas configurações
```

### 3. Inicie o ambiente de desenvolvimento

```bash
docker-compose up -d
```

### 4. Acesse as aplicações

- **Frontend**: http://localhost
- **Backend API**: http://localhost/docs
- **Health Check**: http://localhost/health

## 🧪 Executar Testes

```bash
# Backend
cd backend
pytest -v

# Frontend
cd frontend
npm test
```

## 🔍 Verificar Erros

```bash
chmod +x scripts/check-errors.sh
./scripts/check-errors.sh
```

## 📦 Deploy em Produção

### Opção 1: Deploy Automático (GitHub Actions)

1. Configure secrets no GitHub (veja [DEPLOYMENT.md](DEPLOYMENT.md))
2. Push para branch `main`:

```bash
git add .
git commit -m "Deploy production"
git push origin main
```

3. Acompanhe em: `https://github.com/seu-usuario/url-shortener/actions`

### Opção 2: Deploy Manual

Veja instruções completas em [DEPLOYMENT.md](DEPLOYMENT.md)

## 🏗️ Criar Infraestrutura AWS

```bash
cd infrastructure/terraform

# Inicializar
terraform init

# Planejar
terraform plan -var="db_password=SuaSenhaSegura123" -out=tfplan

# Aplicar
terraform apply tfplan

# Ver outputs (endpoints RDS, Redis)
terraform output
```

## 🔧 Comandos Úteis

```bash
# Desenvolvimento Local
docker-compose up -d              # Iniciar todos os serviços
docker-compose down               # Parar todos os serviços
docker-compose logs -f backend    # Ver logs do backend
docker-compose logs -f frontend   # Ver logs do frontend

# Backend
cd backend
alembic revision --autogenerate -m "descrição"  # Criar migration
alembic upgrade head                             # Executar migrations
pytest -v                                        # Rodar testes
uvicorn app.main:app --reload                    # Dev server

# Frontend
cd frontend
npm install           # Instalar dependências
npm run dev          # Dev server
npm run build        # Build produção
npm run preview      # Preview do build

# Terraform
cd infrastructure/terraform
terraform fmt        # Formatar arquivos
terraform validate   # Validar configuração
terraform plan       # Ver mudanças planejadas
terraform apply      # Aplicar mudanças
terraform destroy    # Destruir recursos (CUIDADO!)

# GitHub Secrets
chmod +x scripts/setup-github-secrets.sh
./scripts/setup-github-secrets.sh
```

## 📊 Monitoramento

### Métricas Principais

#### Backend
- **Latência P50/P95/P99**: < 50ms / < 100ms / < 200ms
- **Taxa de Erro**: < 0.1%
- **Throughput**: > 10k req/s

#### Cache (Redis)
- **Hit Rate**: > 95%
- **Latência**: < 5ms

#### Database (PostgreSQL)
- **Connections**: < 80% do max_connections
- **Replication Lag**: < 100ms

### Dashboards

- **CloudWatch**: Console AWS > CloudWatch > Dashboards
- **RDS Performance Insights**: Console AWS > RDS > Performance Insights
- **Nginx Logs**: `ssh ec2 && tail -f /var/log/nginx/access.log`

## 🔒 Segurança

- ✅ HTTPS/TLS em todas as conexões
- ✅ Secrets gerenciados via GitHub Secrets / AWS Secrets Manager
- ✅ Security Groups restritivos (least privilege)
- ✅ Rate Limiting (100 req/s por IP)
- ✅ CORS configurável
- ✅ SQL Injection protection (ORM)
- ✅ XSS protection (headers)

## 📈 Performance

### Benchmarks

```bash
# Criar URL (Write)
ab -n 10000 -c 100 -p post.json -T application/json http://localhost/shorten

# Redirecionar (Read - cached)
ab -n 100000 -c 1000 http://localhost/abc123
```

### Resultados Esperados (t3.medium)

- **Write**: 2,000 req/s
- **Read (cached)**: 50,000 req/s
- **Read (uncached)**: 5,000 req/s

## 🐛 Troubleshooting

### Backend não inicia

```bash
docker-compose logs backend
# Verificar DATABASE_URL e REDIS_URL no .env
```

### Frontend não conecta no backend

```bash
# Verificar VITE_API_URL no .env
# Verificar CORS no backend (main.py)
```

### Migrações do Alembic falhando

```bash
docker-compose exec app alembic downgrade -1
docker-compose exec app alembic upgrade head
```

### Redis connection refused

```bash
docker-compose ps redis
docker-compose restart redis
```

## 📚 Documentação

- [Guia de Deploy](DEPLOYMENT.md)
- [API Docs](http://localhost/docs) - Swagger UI
- [Arquitetura Detalhada](docs/ARCHITECTURE.md) (TODO)
- [Contributing Guide](CONTRIBUTING.md) (TODO)

## 🤝 Contribuindo

1. Fork o projeto
2. Crie sua feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👤 Autor

**Rafael Dourado**
- Email: rafaeldouradoc7@gmail.com
- GitHub: [@seu-usuario](https://github.com/seu-usuario)

## 🙏 Agradecimentos

- [FastAPI](https://fastapi.tiangolo.com/)
- [React](https://react.dev/)
- [AWS](https://aws.amazon.com/)
- [Vercel](https://vercel.com/)

---

⭐ Se este projeto foi útil, considere dar uma estrela!

📧 Dúvidas? Abra uma [issue](https://github.com/seu-usuario/url-shortener/issues)