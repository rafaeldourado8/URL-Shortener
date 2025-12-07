#!/bin/bash

# Script para verificar erros comuns no projeto

set -e

echo "🔍 Verificando erros no projeto URL Shortener..."
echo ""

ERRORS=0

# Verificar se está na raiz do projeto
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Execute este script da raiz do projeto"
    exit 1
fi

# 1. Verificar arquivos essenciais
echo "📁 Verificando estrutura de arquivos..."
REQUIRED_FILES=(
    "backend/app/main.py"
    "backend/app/core/config.py"
    "backend/app/core/database.py"
    "backend/requirements.txt"
    "backend/Dockerfile"
    "backend/.env.example"
    "frontend/package.json"
    "frontend/Dockerfile"
    "frontend/src/App.jsx"
    "docker-compose.yml"
    "nginx/nginx.prod.conf"
    ".github/workflows/deploy-backend-ec2.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Arquivo faltando: $file"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ $file"
    fi
done

echo ""

# 2. Verificar sintaxe Python
echo "🐍 Verificando sintaxe Python..."
if command -v python3 &> /dev/null; then
    PYTHON_FILES=$(find backend -name "*.py" -not -path "*/\.*" -not -path "*/alembic/*")
    for file in $PYTHON_FILES; do
        if python3 -m py_compile "$file" 2>/dev/null; then
            echo "✅ $file"
        else
            echo "❌ Erro de sintaxe em: $file"
            ERRORS=$((ERRORS + 1))
        fi
    done
else
    echo "⚠️  Python3 não encontrado, pulando verificação de sintaxe"
fi

echo ""

# 3. Verificar imports Python
echo "📦 Verificando imports críticos..."
cd backend

if [ -f ".env" ]; then
    source .env
fi

CRITICAL_IMPORTS=(
    "fastapi"
    "sqlalchemy"
    "redis"
    "pydantic"
    "asyncpg"
)

for package in "${CRITICAL_IMPORTS[@]}"; do
    if python3 -c "import $package" 2>/dev/null; then
        echo "✅ $package instalado"
    else
        echo "❌ $package NÃO instalado. Execute: pip install -r requirements.txt"
        ERRORS=$((ERRORS + 1))
    fi
done

cd ..

echo ""

# 4. Verificar configuração do Docker
echo "🐳 Verificando Docker..."
if command -v docker &> /dev/null; then
    echo "✅ Docker instalado"
    
    # Verificar sintaxe dos Dockerfiles
    if docker build --help &> /dev/null; then
        # Teste de build sem executar
        docker build -t test-backend:latest -f backend/Dockerfile backend --dry-run 2>/dev/null && echo "✅ backend/Dockerfile OK" || echo "⚠️  backend/Dockerfile pode ter problemas"
        docker build -t test-frontend:latest -f frontend/Dockerfile frontend --dry-run 2>/dev/null && echo "✅ frontend/Dockerfile OK" || echo "⚠️  frontend/Dockerfile pode ter problemas"
    fi
else
    echo "⚠️  Docker não encontrado"
fi

echo ""

# 5. Verificar Nginx config
echo "⚙️  Verificando configuração Nginx..."
if command -v nginx &> /dev/null; then
    nginx -t -c nginx/nginx.prod.conf 2>/dev/null && echo "✅ nginx.prod.conf OK" || echo "❌ nginx.prod.conf com erros"
else
    echo "⚠️  Nginx não instalado localmente (OK se for testar no container)"
fi

echo ""

# 6. Verificar .env
echo "🔐 Verificando variáveis de ambiente..."
if [ -f "backend/.env" ]; then
    echo "✅ backend/.env existe"
    
    # Verificar variáveis críticas
    REQUIRED_VARS=(
        "DATABASE_WRITE_URL"
        "DATABASE_READ_URLS"
        "REDIS_URL"
        "BASE_URL"
    )
    
    for var in "${REQUIRED_VARS[@]}"; do
        if grep -q "^$var=" backend/.env; then
            echo "✅ $var configurado"
        else
            echo "❌ $var NÃO configurado em .env"
            ERRORS=$((ERRORS + 1))
        fi
    done
else
    echo "⚠️  backend/.env não existe. Copie de .env.example"
    echo "   cp backend/.env.example backend/.env"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# 7. Verificar dependências frontend
echo "📦 Verificando dependências Frontend..."
if [ -f "frontend/package-lock.json" ]; then
    echo "✅ package-lock.json existe"
    
    if command -v node &> /dev/null; then
        echo "✅ Node.js instalado: $(node --version)"
        
        cd frontend
        if [ ! -d "node_modules" ]; then
            echo "⚠️  node_modules não encontrado. Execute: npm install"
        else
            echo "✅ node_modules existe"
        fi
        cd ..
    else
        echo "⚠️  Node.js não encontrado"
    fi
else
    echo "❌ package-lock.json não encontrado"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# 8. Verificar GitHub Actions
echo "🔄 Verificando GitHub Actions..."
GHA_FILES=(
    ".github/workflows/deploy-backend-ec2.yml"
    ".github/workflows/deploy-frontend-vercel.yml"
    ".github/workflows/deploy-frontend-s3.yml"
)

for file in "${GHA_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
        
        # Verificar sintaxe YAML básica
        if command -v python3 &> /dev/null; then
            python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null && echo "   ✅ YAML válido" || echo "   ❌ YAML inválido"
        fi
    else
        echo "❌ $file não encontrado"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""

# 9. Verificar Terraform
echo "🏗️  Verificando Terraform..."
if [ -d "infrastructure/terraform" ]; then
    echo "✅ Pasta infrastructure/terraform existe"
    
    if command -v terraform &> /dev/null; then
        echo "✅ Terraform instalado: $(terraform version | head -n1)"
        
        cd infrastructure/terraform
        terraform fmt -check &> /dev/null && echo "✅ Terraform formatado" || echo "⚠️  Execute: terraform fmt"
        terraform validate &> /dev/null && echo "✅ Terraform válido" || echo "⚠️  Execute: terraform init && terraform validate"
        cd ../..
    else
        echo "⚠️  Terraform não instalado"
    fi
else
    echo "❌ Pasta infrastructure/terraform não encontrada"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -eq 0 ]; then
    echo "✨ Nenhum erro crítico encontrado!"
    echo ""
    echo "📋 Próximos passos:"
    echo "1. Configure variáveis: cp backend/.env.example backend/.env"
    echo "2. Inicie localmente: docker-compose up -d"
    echo "3. Teste: curl http://localhost/health"
    echo "4. Deploy: git push origin main"
else
    echo "❌ Encontrados $ERRORS erros. Corrija antes de prosseguir."
    exit 1
fi