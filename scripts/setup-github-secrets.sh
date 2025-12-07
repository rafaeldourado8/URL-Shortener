#!/bin/bash

# Script para configurar GitHub Secrets via CLI
# Requer: gh (GitHub CLI) instalado e autenticado

set -e

echo "🔐 Configurando GitHub Secrets..."
echo ""

# Verificar se gh está instalado
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) não encontrado. Instale em: https://cli.github.com/"
    exit 1
fi

# Verificar autenticação
if ! gh auth status &> /dev/null; then
    echo "❌ Não autenticado no GitHub. Execute: gh auth login"
    exit 1
fi

echo "📝 Repositório atual: $(gh repo view --json nameWithOwner -q .nameWithOwner)"
echo ""

# Função helper para adicionar secrets
add_secret() {
    local name=$1
    local value=$2
    
    if [ -z "$value" ]; then
        echo "⚠️  Pulando $name (vazio)"
        return
    fi
    
    echo "$value" | gh secret set "$name"
    echo "✅ Secret adicionado: $name"
}

# AWS Credentials
echo "🔑 AWS Credentials:"
read -p "AWS_ACCESS_KEY_ID: " AWS_ACCESS_KEY_ID
read -sp "AWS_SECRET_ACCESS_KEY: " AWS_SECRET_ACCESS_KEY
echo ""

add_secret "AWS_ACCESS_KEY_ID" "$AWS_ACCESS_KEY_ID"
add_secret "AWS_SECRET_ACCESS_KEY" "$AWS_SECRET_ACCESS_KEY"

# EC2 Configuration
echo ""
echo "🖥️  EC2 Configuration:"
read -p "EC2_HOST (IP ou DNS): " EC2_HOST
read -p "EC2_USER (default: ubuntu): " EC2_USER
EC2_USER=${EC2_USER:-ubuntu}

add_secret "EC2_HOST" "$EC2_HOST"
add_secret "EC2_USER" "$EC2_USER"

echo ""
read -p "Caminho para chave SSH privada (.pem): " SSH_KEY_PATH
if [ -f "$SSH_KEY_PATH" ]; then
    SSH_KEY_CONTENT=$(cat "$SSH_KEY_PATH")
    add_secret "EC2_SSH_KEY" "$SSH_KEY_CONTENT"
else
    echo "⚠️  Arquivo SSH não encontrado: $SSH_KEY_PATH"
fi

# Database URLs (obtidos do Terraform)
echo ""
echo "🗄️  Database Configuration:"
echo "Dica: Execute 'terraform output' na pasta infrastructure/terraform"
echo ""
read -p "DATABASE_WRITE_URL (Master RDS): " DATABASE_WRITE_URL
read -p "DATABASE_READ_URLS (Réplicas, separadas por vírgula): " DATABASE_READ_URLS

add_secret "DATABASE_WRITE_URL" "$DATABASE_WRITE_URL"
add_secret "DATABASE_READ_URLS" "$DATABASE_READ_URLS"

# Redis URL
echo ""
echo "📦 Redis Configuration:"
read -p "REDIS_URL (ElastiCache endpoint): " REDIS_URL
add_secret "REDIS_URL" "$REDIS_URL"

# Base URL
echo ""
echo "🌐 Application Configuration:"
read -p "BASE_URL (ex: https://api.seudominio.com): " BASE_URL
add_secret "BASE_URL" "$BASE_URL"

# Frontend - Vercel (opcional)
echo ""
read -p "Configurar Vercel? (y/n): " SETUP_VERCEL
if [[ $SETUP_VERCEL == "y" || $SETUP_VERCEL == "Y" ]]; then
    echo "🚀 Vercel Configuration:"
    echo "Obtenha token em: https://vercel.com/account/tokens"
    read -sp "VERCEL_TOKEN: " VERCEL_TOKEN
    echo ""
    read -p "VITE_API_URL (Backend URL): " VITE_API_URL
    
    add_secret "VERCEL_TOKEN" "$VERCEL_TOKEN"
    add_secret "VITE_API_URL" "$VITE_API_URL"
fi

# Frontend - CloudFront (opcional)
echo ""
read -p "Configurar CloudFront? (y/n): " SETUP_CLOUDFRONT
if [[ $SETUP_CLOUDFRONT == "y" || $SETUP_CLOUDFRONT == "Y" ]]; then
    echo "☁️  CloudFront Configuration:"
    read -p "CLOUDFRONT_DISTRIBUTION_ID: " CLOUDFRONT_DISTRIBUTION_ID
    
    add_secret "CLOUDFRONT_DISTRIBUTION_ID" "$CLOUDFRONT_DISTRIBUTION_ID"
    
    if [ -z "$VITE_API_URL" ]; then
        read -p "VITE_API_URL (Backend URL): " VITE_API_URL
        add_secret "VITE_API_URL" "$VITE_API_URL"
    fi
fi

echo ""
echo "✨ Configuração concluída!"
echo ""
echo "📋 Próximos passos:"
echo "1. Verifique os secrets em: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/settings/secrets/actions"
echo "2. Execute: git push origin main"
echo "3. Acompanhe o deploy em: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/actions"
echo ""