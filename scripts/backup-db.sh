#!/usr/bin/env bash
# Backup diário do banco de produção do Colchete.
# 1. Gera um dump do PostgreSQL (formato custom: já comprimido, restaurado com pg_restore)
# 2. Envia criptografado ao Cloudflare R2 (remoto "r2crypt" do rclone)
# 3. Apaga as cópias antigas: 7 dias no servidor, 30 dias no R2
set -euo pipefail

BACKUP_DIR="/srv/colchete/backups"
REMOTE="r2crypt:"
LOCAL_DAYS=7
REMOTE_DAYS=30

STAMP="$(date -u +%Y-%m-%d_%H%M)"
FILE="$BACKUP_DIR/colchete_${STAMP}.dump"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

# Se qualquer passo falhar, não deixa um arquivo pela metade para trás
trap 'rm -f "$FILE"; echo "[$(date -u +%FT%TZ)] ERRO: backup falhou" >&2' ERR

echo "[$(date -u +%FT%TZ)] Iniciando backup: $FILE"

docker exec colchete_postgres sh -c \
  'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom --no-owner' > "$FILE"

# Dump vazio indica falha silenciosa
if [ ! -s "$FILE" ]; then
  echo "[$(date -u +%FT%TZ)] ERRO: dump vazio" >&2
  rm -f "$FILE"
  exit 1
fi
chmod 600 "$FILE"

rclone copy "$FILE" "$REMOTE" --no-traverse

# Rotação
find "$BACKUP_DIR" -name 'colchete_*.dump' -mtime +"$LOCAL_DAYS" -delete
rclone delete "$REMOTE" --min-age "${REMOTE_DAYS}d"

echo "[$(date -u +%FT%TZ)] Backup concluído ($(du -h "$FILE" | cut -f1))"