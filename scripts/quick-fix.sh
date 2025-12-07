#!/bin/bash

# Script de correção rápida dos erros encontrados

set -e

echo "🔧 Aplicando correções rápidas..."
echo ""

# 1. Parar containers com erro
echo "🛑 Parando containers..."
docker-compose down 2>/dev/null || true
echo "✅ Containers parados"
echo ""

# 2. Criar backup do nginx.local.conf
if [ -f "nginx/nginx.local.conf" ]; then
    echo "💾 Backup: nginx/nginx.local.conf -> nginx/nginx.local.conf.backup"
    cp nginx/nginx.local.conf nginx/nginx.local.conf.backup
fi

# 3. Criar backup do config.py
if [ -f "backend/app/core/config.py" ]; then
    echo "💾 Backup: backend/app/core/config.py -> backend/app/core/config.py.backup"
    cp backend/app/core/config.py backend/app/core/config.py.backup
fi

echo ""
echo "📋 Arquivos que precisam ser atualizados:"
echo ""
echo "1️⃣  nginx/nginx.local.conf"
echo "   Problema: Regex inválido na linha 59"
echo "   Solução: Use aspas duplas no regex"
echo ""
echo "2️⃣  backend/app/core/config.py"
echo "   Problema: Pydantic não aceita campo extra DATABASE_URL"
echo "   Solução: Adicionar extra='ignore' no model_config"
echo ""
echo "3️⃣  backend/.env"
echo "   Certifique-se de ter apenas estas variáveis:"
echo "   - PROJECT_NAME"
echo "   - BASE_URL"
echo "   - REDIS_URL"
echo "   - DATABASE_WRITE_URL"
echo "   - DATABASE_READ_URLS"
echo ""

# Verificar se .env existe
if [ ! -f "backend/.env" ]; then
    echo "⚠️  backend/.env não existe!"
    echo "   Criando do .env.example..."
    
    if [ -f "backend/.env.example" ]; then
        cp backend/.env.example backend/.env
        echo "✅ backend/.env criado"
    else
        echo "❌ backend/.env.example também não existe!"
        echo ""
        echo "Crie backend/.env com este conteúdo:"
        echo "-----------------------------------"
        cat << 'EOF'
PROJECT_NAME="URL Shortener High-Scale"
BASE_URL="http://localhost:8000"
REDIS_URL="redis://redis:6379/0"
DATABASE_WRITE_URL="postgresql+asyncpg://user:password@db_master:5432/shortener_db"
DATABASE_READ_URLS="postgresql+asyncpg://user:password@db_replica_1:5432/shortener_db,postgresql+asyncpg://user:password@db_replica_2:5432/shortener_db,postgresql+asyncpg://user:password@db_replica_3:5432/shortener_db"
EOF
        echo "-----------------------------------"
        exit 1
    fi
fi

echo ""
echo "🎯 AÇÃO NECESSÁRIA:"
echo ""
echo "Você precisa SUBSTITUIR os seguintes arquivos com as versões corrigidas:"
echo ""
echo "Arquivo 1: nginx/nginx.local.conf"
echo "  Linha 59 atual:   location ~ ^/[a-zA-Z0-9]{1,10}$ {"
echo "  Linha 59 correta: location ~ \"^/[a-zA-Z0-9]{1,10}$\" {"
echo "                              ↑ adicionar aspas duplas ↑"
echo ""
echo "Arquivo 2: backend/app/core/config.py"
echo "  Adicione após a classe Settings:"
echo "  model_config = SettingsConfigDict("
echo "      env_file=\".env\","
echo "      case_sensitive=True,"
echo "      extra=\"ignore\"  # <-- ADICIONAR ESTA LINHA"
echo "  )"
echo ""
echo "Ou copie os arquivos corrigidos dos artifacts que te enviei!"
echo ""

read -p "Arquivos corrigidos? Pressione Enter para continuar ou Ctrl+C para sair..."

echo ""
echo "🧹 Limpando containers e volumes antigos..."
docker-compose down -v 2>/dev/null || true

echo ""
echo "🏗️  Reconstruindo imagens..."
docker-compose build

echo ""
echo "🚀 Iniciando containers..."
docker-compose up -d

echo ""
echo "⏳ Aguardando containers iniciarem (15 segundos)..."
sleep 15

echo ""
echo "🏥 Verificando saúde dos serviços..."
echo ""

# Verificar Backend
if curl -f http://localhost:8000/health 2>/dev/null; then
    echo "✅ Backend: OK"
else
    echo "❌ Backend: FALHOU"
    echo "   Logs: docker-compose logs app"
fi

# Verificar Frontend
if curl -f http://localhost 2>/dev/null; then
    echo "✅ Frontend: OK"
else
    echo "❌ Frontend: FALHOU"
    echo "   Logs: docker-compose logs frontend"
fi

# Verificar Nginx
if docker-compose ps nginx | grep -q "Up"; then
    echo "✅ Nginx: OK"
else
    echo "❌ Nginx: FALHOU"
    echo "   Logs: docker-compose logs nginx"
fi

echo ""
echo "📊 Status dos containers:"
docker-compose ps

echo ""
echo "✨ Correções aplicadas!"
echo ""
echo "📋 Próximos passos:"
echo "1. Se algum serviço falhou, veja os logs: docker-compose logs <serviço>"
echo "2. Acesse o frontend: http://localhost"
echo "3. Teste a API: http://localhost:8000/docs"
echo ""