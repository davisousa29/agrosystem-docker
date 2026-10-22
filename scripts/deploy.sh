#!/usr/bin/env bash
# Atualiza a produção do Colchete com o código mais recente do GitHub.
# Uso, no servidor:  /srv/colchete/colchete-system/scripts/deploy.sh
set -euo pipefail

ROOT="/srv/colchete"
SYSTEM="$ROOT/colchete-system"
BACKEND="$ROOT/colchete-backend"
COMPOSE=(docker compose --env-file "$BACKEND/.env" -f "$SYSTEM/docker-compose.prod.yml")

log() { echo "[$(date -u +%FT%TZ)] $*"; }
trap 'log "ERRO: o deploy parou na etapa acima. A produção pode estar parcialmente atualizada."' ERR

log "1/7 Baixando o código"
git -C "$SYSTEM" pull --ff-only
git -C "$BACKEND" pull --ff-only

log "2/7 Backup do banco antes de qualquer mudança"
"$SYSTEM/scripts/backup-db.sh"

log "3/7 Construindo as imagens"
"${COMPOSE[@]}" build --pull

log "4/7 Recriando os containers"
"${COMPOSE[@]}" up -d --remove-orphans

log "5/7 Aplicando as migrações"
"${COMPOSE[@]}" exec -T -u www-data backend php artisan migrate --force

log "6/7 Recriando os caches e reiniciando a fila"
"${COMPOSE[@]}" exec -T -u www-data backend php artisan optimize
"${COMPOSE[@]}" exec -T -u www-data backend php artisan queue:restart

log "7/7 Removendo imagens antigas"
docker image prune -f > /dev/null

"${COMPOSE[@]}" ps
log "Deploy concluído"