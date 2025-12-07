# 🚀 Guia Completo de Deployment

## 📋 Pré-requisitos

- Conta AWS configurada
- Terraform instalado (>= 1.0)
- Docker instalado
- Node.js 18+ instalado
- Conta Vercel (opcional, para deploy do frontend)

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                         CloudFront                           │
│                      (CDN Global)                            │
└────────────────┬────────────────────────────────────────────┘
                 │
         ┌───────┴────────┐
         │                │
    ┌────▼─────┐    ┌────▼─────────┐
    │  Vercel  │    │  S3 Bucket   │
    │ Frontend │    │  (Static)    │
    └──────────┘    └──────────────┘
                           │
                    ┌──────▼──────┐
                    │     ALB     │
                    │ (AWS Load   │
                    │  Balancer)  │
                    └──┬───┬───┬──┘
                       │   │   │
              ┌────────┴┐ ┌┴───┴────────┐
              │  EC2-1  │ │   EC2-2,3   │
              │ Nginx + │ │  Backend    │
              │ Backend │ │  Instances  │
              └────┬────┘ └─────┬───────┘
                   │            │
           ┌───────┴────────────┴────────┐
           │                              │
      ┌────▼─────┐              ┌────────▼──────┐
      │   RDS    │              │ ElastiCache   │
      │ Master   │              │    Redis      │
      │ +        │              │   Cluster     │
      │ 3 Read   │              │               │
      │ Replicas │              │               │
      └──────────┘              └───────────────┘
```

## 🔧 Configuração Inicial

### 1. Clonar o Repositório

```bash
git clone <seu-repositorio>
cd url-shortener
```

### 2. Configurar Secrets do GitHub

No GitHub, vá em **Settings > Secrets and Variables > Actions** e adicione:

#### Para Backend (EC2):
```
AWS_ACCESS_KEY_ID=<sua-access-key>
AWS_SECRET_ACCESS_KEY=<sua-secret-key>
EC2_HOST=<ip-do-ec2>
EC2_USER=ubuntu
EC2_SSH_KEY=<sua-chave-privada-ssh>
DATABASE_WRITE_URL=postgresql+asyncpg://user:pass@master.region.rds.amazonaws.com:5432/db
DATABASE_READ_URLS=postgresql+asyncpg://user:pass@replica1...,postgresql+asyncpg://user:pass@replica2...,postgresql+asyncpg://user:pass@replica3...
REDIS_URL=redis://seu-redis.cache.amazonaws.com:6379/0
BASE_URL=https://seu-dominio.com
```

#### Para Frontend (Vercel):
```
VERCEL_TOKEN=<seu-vercel-token>
VITE_API_URL=https://api.seu-dominio.com
```

#### Para Frontend (S3 + CloudFront):
```
AWS_ACCESS_KEY_ID=<mesma-do-backend>
AWS_SECRET_ACCESS_KEY=<mesma-do-backend>
CLOUDFRONT_DISTRIBUTION_ID=<seu-distribution-id>
VITE_API_URL=https://api.seu-dominio.com
```

### 3. Criar Infraestrutura com Terraform

```bash
cd infrastructure/terraform

# Inicializar Terraform
terraform init

# Planejar mudanças
terraform plan \
  -var="db_password=SuaSenhaSegura123456" \
  -out=tfplan

# Aplicar infraestrutura
terraform apply tfplan
```

Isso criará:
- VPC com subnets públicas e privadas
- RDS PostgreSQL Master + 3 Read Replicas
- ElastiCache Redis Cluster (3 nodes)
- Security Groups
- IAM Roles

### 4. Anotar Outputs do Terraform

```bash
terraform output
```

Copie os endpoints do RDS e Redis para os secrets do GitHub.

## 📦 Deploy do Backend (EC2)

### Opção 1: GitHub Actions (Automático)

1. Faça push para `main`:
```bash
git add .
git commit -m "Deploy backend"
git push origin main
```

2. Acompanhe o deploy em **Actions** no GitHub

### Opção 2: Manual

```bash
# 1. Buildar imagem Docker
cd backend
docker build -t url-shortener-backend .

# 2. Login no ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# 3. Tag e Push
docker tag url-shortener-backend:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/url-shortener-backend:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/url-shortener-backend:latest

# 4. SSH no EC2 e rodar container
ssh -i sua-chave.pem ubuntu@<ec2-ip>

docker pull <account-id>.dkr.ecr.us-east-1.amazonaws.com/url-shortener-backend:latest

docker run -d \
  --name shortener_api \
  --restart unless-stopped \
  -p 8000:8000 \
  -e DATABASE_WRITE_URL="postgresql+asyncpg://..." \
  -e DATABASE_READ_URLS="postgresql+asyncpg://..." \
  -e REDIS_URL="redis://..." \
  -e BASE_URL="https://seu-dominio.com" \
  <account-id>.dkr.ecr.us-east-1.amazonaws.com/url-shortener-backend:latest
```

## 🌐 Deploy do Frontend

### Opção 1: Vercel (Recomendado - Mais Fácil)

1. Instale Vercel CLI:
```bash
npm i -g vercel
```

2. Login:
```bash
vercel login
```

3. Deploy:
```bash
cd frontend
vercel --prod
```

Ou configure o GitHub Actions para deploy automático (já incluído).

### Opção 2: S3 + CloudFront

1. Criar bucket S3:
```bash
aws s3 mb s3://url-shortener-frontend --region us-east-1
```

2. Configurar para hosting estático:
```bash
aws s3 website s3://url-shortener-frontend \
  --index-document index.html \
  --error-document index.html
```

3. Criar CloudFront Distribution (via Console ou Terraform)

4. Deploy via GitHub Actions (já configurado) ou manual:
```bash
cd frontend
npm ci
npm run build
aws s3 sync dist/ s3://url-shortener-frontend --delete
aws cloudfront create-invalidation \
  --distribution-id <seu-id> \
  --paths "/*"
```

## 🔄 Configurar Nginx como Load Balancer

No EC2 principal (ou instância separada para Nginx):

```bash
# Instalar Nginx
sudo apt update
sudo apt install nginx -y

# Copiar configuração
sudo cp nginx/nginx.prod.conf /etc/nginx/nginx.conf

# Testar configuração
sudo nginx -t

# Recarregar
sudo systemctl reload nginx

# Habilitar na inicialização
sudo systemctl enable nginx
```

## 🗄️ Executar Migrações do Banco

```bash
# Via SSH no EC2
ssh -i sua-chave.pem ubuntu@<ec2-ip>

# Dentro do container
docker exec -it shortener_api bash

# Rodar migrações
alembic upgrade head
```

## 🧪 Testar Deployment

### Backend:
```bash
# Health check
curl https://api.seu-dominio.com/health

# Criar URL curta
curl -X POST https://api.seu-dominio.com/shorten \
  -H "Content-Type: application/json" \
  -d '{"url": "https://google.com"}'

# Testar redirecionamento
curl -I https://api.seu-dominio.com/<short-key>
```

### Frontend:
```bash
# Acessar no navegador
https://seu-dominio-frontend.vercel.app

# Ou S3/CloudFront
https://<cloudfront-domain>.cloudfront.net
```

## 📊 Monitoramento

### CloudWatch
- RDS: Performance Insights, CPU, Connections
- ElastiCache: Cache Hit Rate, Memory Usage
- EC2: CPU, Network, Disk I/O

### Logs
```bash
# Backend logs
docker logs -f shortener_api

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## 🔒 Segurança

### SSL/TLS
Configure certificado SSL via:
- **AWS Certificate Manager** (para CloudFront/ALB)
- **Let's Encrypt** (para Nginx direto)

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obter certificado
sudo certbot --nginx -d api.seu-dominio.com
```

### Firewall (Security Groups)
- Backend: Porta 8000 apenas da VPC/ALB
- RDS: Porta 5432 apenas da VPC
- Redis: Porta 6379 apenas da VPC
- Nginx: Portas 80, 443 públicas

## 📈 Escalabilidade

### Horizontal Scaling
1. Crie mais instâncias EC2 com a mesma imagem
2. Adicione ao Load Balancer
3. Atualize `nginx.prod.conf`:
```nginx
upstream backend_cluster {
    server app1:8000;
    server app2:8000;
    server app3:8000;
}
```

### Vertical Scaling
- **RDS**: Upgrade instance class (db.t3.medium → db.r6g.large)
- **EC2**: Upgrade instance type (t3.medium → c6g.large)
- **Redis**: Upgrade node type (cache.t3.medium → cache.r6g.large)

## 🆘 Troubleshooting

### Backend não conecta no RDS
```bash
# Verificar security group
aws ec2 describe-security-groups --group-ids <rds-sg-id>

# Testar conexão do EC2
telnet <rds-endpoint> 5432
```

### Frontend não conecta no Backend
```bash
# Verificar CORS no backend
# Verificar VITE_API_URL no .env
# Verificar certificado SSL
```

### Cache não funciona
```bash
# Testar Redis
redis-cli -h <redis-endpoint> ping

# Verificar logs
docker logs shortener_api | grep redis
```

## 🔄 Rollback

### Backend:
```bash
# Via GitHub Actions - Revert commit e push
git revert <commit-hash>
git push origin main

# Manual - Usar tag anterior
docker pull <account-id>.dkr.ecr.us-east-1.amazonaws.com/url-shortener-backend:<tag-anterior>
docker stop shortener_api
docker rm shortener_api
docker run -d ... <tag-anterior>
```

### Frontend:
```bash
# Vercel - Via dashboard ou CLI
vercel rollback <deployment-url>

# S3 - Restaurar versão anterior (se versionamento habilitado)
aws s3api list-object-versions --bucket url-shortener-frontend
```

## 📚 Recursos Adicionais

- [Documentação FastAPI](https://fastapi.tiangolo.com/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Vercel CLI](https://vercel.com/docs/cli)
- [Nginx Load Balancing](https://docs.nginx.com/nginx/admin-guide/load-balancer/)