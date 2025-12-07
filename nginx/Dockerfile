FROM nginx:alpine

# Remove a config padrão
RUN rm /etc/nginx/conf.d/default.conf

# AQUI ESTÁ O TRUQUE:
# Copiamos especificamente a versão de PROD para ser a oficial desta imagem
COPY nginx.prod.conf /etc/nginx/nginx.conf

EXPOSE 80