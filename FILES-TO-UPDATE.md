# 📝 Lista de Arquivos para Criar/Atualizar

## ✅ Arquivos que DEVEM ser substituídos/criados

### Backend

- [x] **backend/app/main.py** - SUBSTITUIR (corrigido engine_master)
- [x] **backend/app/api/v1/endpoints.py** - SUBSTITUIR (corrigido imports)
- [x] **backend/.env.example** - CRIAR (não existia)

### Testes

- [x] **tests/conftest.py** - SUBSTITUIR (corrigido imports e AsyncClient)

### GitHub Actions

- [x] **.github/workflows/deploy-backend-ec2.yml** - CRIAR
- [x] **.github/workflows/deploy-frontend-vercel.yml** - CRIAR
- [x] **.github/workflows/deploy-frontend-s3.yml** - CRIAR

### Nginx

- [x] **nginx/nginx.prod.conf** - SUBSTITUIR (otimizado para produção)

### Infrastructure

- [x] **infrastructure/terraform/main.tf** - CRIAR
- [x] **infrastructure/terraform/variables.tf** - CRIAR

### Docker

- [x] **docker-compose.prod.yml** - SUBSTITUIR (otimizado)

### Scripts

- [x] **scripts/setup-github-secrets.sh** - CRIAR
- [x] **scripts/check-errors.sh** - CRIAR
- [ ] **scripts/post.json** - CRIAR (para testes)

### Documentação

- [x] **README.md** - SUBSTITUIR (completo)
- [x] **DEPLOYMENT.md** - CRIAR
- [x] **ERRORS_FIXED.md** - CRIAR
- [x] **docs/AWS_RDS_SETUP.md** - CRIAR

### Makefile

- [x] **Makefile** - CRIAR

## 📋 Arquivos que ficam INALTERADOS

### Backend (OK, não mexer)
- ✅ backend/app/core/config.py
- ✅ backend/app/core/database.py
- ✅ backend/app/repositories/url_repository.py
- ✅ backend/app/services/url_service.py
- ✅ backend/app/services/bloom_filter.py
- ✅ backend/app/models/url.py
- ✅ backend/app/schemas/url.py
- ✅ backend/requirements.txt
- ✅ backend/Dockerfile
- ✅ backend/alembic.ini
- ✅ backend/alembic/env.py

### Frontend (OK, não mexer)
- ✅ frontend/src/App.jsx
- ✅ frontend/src/components/BackgroundGradient.jsx
- ✅ frontend/src/components/ResultCard.jsx
- ✅ frontend/src/index.css
- ✅ frontend/src/main.jsx
- ✅ frontend/package.json
- ✅ frontend/vite.config.js
- ✅ frontend/tailwind.config.js
- ✅ frontend/Dockerfile

### Testes (OK, não mexer)
- ✅ tests/test_routes.py

### Outros (OK, não mexer)
- ✅ .gitignore
- ✅ docker-compose.yml (desenvolvimento)
- ✅ nginx/nginx.local.conf
- ✅ pyproject.toml

## 🔨 Ações Necessárias

### 1. Substituir Arquivos Críticos

```bash
# Backend
cp backend/app/main.py backend/app/main.py.backup
# Cole o conteúdo corrigido de backend/app/main.py

cp backend/app/api/v1/endpoints.py backend/app/api/v1/endpoints.py.backup
# Cole o conteúdo corrigido de backend/app/api/v1/endpoints.py

# Testes
cp tests/conftest.py tests/conftest.py.backup
# Cole o conteúdo corrigido de tests/conftest.py
```

### 2. Criar Arquivos Novos

```bash
# .env.example
cat > backend/.env.example << 'EOF'
# Cole o conteúdo do artifact backend/.env.example
EOF

# GitHub Actions
mkdir -p .github/workflows
cat > .github/workflows/deploy-backend-ec2.yml << 'EOF'
# Cole o conteúdo do artifact
EOF

cat > .github/workflows/deploy-frontend-vercel.yml << 'EOF'
# Cole o conteúdo do artifact
EOF

cat > .github/workflows/deploy-frontend-s3.yml << 'EOF'
# Cole o conteúdo do artifact
EOF

# Terraform
mkdir -p infrastructure/terraform
cat > infrastructure/terraform/main.tf << 'EOF'
# Cole o conteúdo do artifact
EOF

cat > infrastructure/terraform/variables.tf << 'EOF'
# Cole o conteúdo do artifact
EOF

# Scripts
mkdir -p scripts
cat > scripts/setup-github-secrets.sh << 'EOF'
# Cole o conteúdo do artifact
EOF

cat > scripts/check-errors.sh << 'EOF'
# Cole o conteúdo do artifact
EOF

chmod +x scripts/*.sh

# Documentação
cat > README.md << 'EOF'
# Cole o conteúdo do artifact
EOF

cat > DEPLOYMENT.md << 'EOF'
# Cole o conteúdo do artifact
EOF

cat > ERRORS_FIXED.md << 'EOF'
# Cole o conteúdo do artifact
EOF

mkdir -p docs
cat > docs/AWS_RDS_SETUP.md << 'EOF'
# Cole o conteúdo do artifact
EOF

# Makefile
cat > Makefile << 'EOF'
# Cole o conteúdo do artifact
EOF

# Nginx (backup primeiro)
cp nginx/nginx.prod.conf nginx/nginx.prod.conf.backup
cat > nginx/nginx.prod.conf << 'EOF'
# Cole o conteúdo do artifact
EOF

# Docker Compose Prod (backup primeiro)
cp docker-compose.prod.yml docker-compose.prod.yml.backup
cat > docker-compose.prod.yml << 'EOF'
# Cole o conteúdo do artifact
EOF
```

### 3. Criar arquivo de teste para benchmark

```bash
cat > scripts/post.json << 'EOF'
{
  "url": "https://www.google.com"
}
EOF
```

### 4. Criar estrutura de diretórios

```bash
mkdir -p .github/workflows
mkdir -p infrastructure/terraform
mkdir -p scripts
mkdir -p docs
mkdir -p nginx/ssl
```

## ✅ Verificação Final

Após criar/atualizar todos os arquivos, execute:

```bash
# 1. Verificar estrutura
tree -L 3 -I 'node_modules|__pycache__|.git'

# 2. Verificar erros
./scripts/check-errors.sh

# 3. Testar localmente
make setup
make dev

# 4. Verificar saúde
make health

# 5. Executar testes
make test
```

## 🎯 Ordem de Execução Recomendada

1. **Backup**: Faça backup de todos os arquivos que serão substituídos
2. **Backend crítico**: main.py, endpoints.py, conftest.py
3. **Configuração**: .env.example, Makefile
4. **Scripts**: setup-github-secrets.sh, check-errors.sh
5. **GitHub Actions**: workflows
6. **Infrastructure**: Terraform
7. **Documentação**: README.md, DEPLOYMENT.md
8. **Nginx**: nginx.prod.conf
9. **Docker**: docker-compose.prod.yml

## 🚨 Cuidados Especiais

### Não commitar ao Git:
- ❌ `backend/.env` (apenas .env.example)
- ❌ `*.pem` (chaves SSH)
- ❌ `*.backup` (arquivos de backup)
- ❌ Senhas ou tokens em texto plano

### Commitar ao Git:
- ✅ `.env.example`
- ✅ Todos os workflows do GitHub Actions
- ✅ Todos os arquivos de documentação
- ✅ Makefile
- ✅ Scripts em `scripts/`
- ✅ Terraform em `infrastructure/`

## 📊 Status Final Esperado

```
url-shortener/
├── ✅ .github/workflows/
│   ├── ✅ deploy-backend-ec2.yml
│   ├── ✅ deploy-frontend-vercel.yml
│   └── ✅ deploy-frontend-s3.yml
├── ✅ backend/
│   ├── ✅ .env.example (NOVO)
│   ├── ✅ app/
│   │   ├── ✅ main.py (ATUALIZADO)
│   │   └── ✅ api/v1/endpoints.py (ATUALIZADO)
├── ✅ docs/
│   └── ✅ AWS_RDS_SETUP.md (NOVO)
├── ✅ infrastructure/
│   └── ✅ terraform/
│       ├── ✅ main.tf (NOVO)
│       └── ✅ variables.tf (NOVO)
├── ✅ nginx/
│   └── ✅ nginx.prod.conf (ATUALIZADO)
├── ✅ scripts/
│   ├── ✅ check-errors.sh (NOVO)
│   ├── ✅ post.json (NOVO)
│   └── ✅ setup-github-secrets.sh (NOVO)
├── ✅ tests/
│   └── ✅ conftest.py (ATUALIZADO)
├── ✅ DEPLOYMENT.md (NOVO)
├── ✅ ERRORS_FIXED.md (NOVO)
├── ✅ Makefile (NOVO)
├── ✅ README.md (ATUALIZADO)
└── ✅ docker-compose.prod.yml (ATUALIZADO)
```

## 🎉 Quando Estiver Pronto

```bash
# Verificar tudo
./scripts/check-errors.sh

# Commitar mudanças
git add .
git commit -m "fix: corrigir erros e adicionar CI/CD"
git push origin main

# Assistir deploy
# https://github.com/seu-usuario/url-shortener/actions
```