FROM caddy:2-alpine

# Pasta public do Laravel (index.php, favicon, robots.txt): o Caddy precisa dela
# para decidir o que é arquivo estático e o que vai para o PHP
COPY --from=backend public /var/www/html/public

COPY Caddyfile /etc/caddy/Caddyfile