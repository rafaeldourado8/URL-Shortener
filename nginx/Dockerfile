# Estágio 1: Build do Frontend (React)
FROM node:18 AS builder
WORKDIR /app

# Copia arquivos de dependência
COPY frontend/package*.json ./
RUN npm install

# Copia o código fonte e faz o build
COPY frontend/ .
# Define a URL da API como vazia para usar o proxy reverso do próprio Nginx (mesmo domínio)
ENV VITE_API_URL=""
RUN npm run build

# Estágio 2: Nginx Servindo os Arquivos
FROM nginx:alpine

# Remove configuração padrão
RUN rm /etc/nginx/conf.d/default.conf

# Copia a configuração personalizada de prod
COPY nginx/nginx.prod.conf /etc/nginx/nginx.conf

# Copia os arquivos estáticos do React (do estágio 1) para a pasta do Nginx
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80