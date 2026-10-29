#!/usr/bin/env bash
# Respaldo custom de foodstore. Sin contraseña: usa ~/.pgpass o PGPASSFILE.
# Sale con código != 0 si pg_dump falla. Uso: ./backup_foodstore.sh
set -euo pipefail

PGHOST="${PGHOST:-localhost}"; PGPORT="${PGPORT:-5432}"
PGUSER="${PGUSER:-postgres}";  DB="${DB:-foodstore}"
DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUPS="$DIR/backups"; LOGS="$DIR/logs"
mkdir -p "$BACKUPS" "$LOGS"

TS="$(date +%Y%m%d_%H%M%S)"
OUT="$BACKUPS/${DB}_${TS}.dump"
LOG="$LOGS/backup_${TS}.log"
log() { echo "$(date '+%F %T') $*" | tee -a "$LOG"; }

# Si algo falla, no dejar un dump parcial y registrarlo
trap 'rc=$?; if [ $rc -ne 0 ]; then log "ERROR: respaldo fallido (código $rc)"; rm -f "$OUT.partial" "$OUT.counts"; fi' EXIT

log "INICIO respaldo de $DB en $PGHOST:$PGPORT"

# Conteos previos al respaldo (para compararlos luego en la restauración)
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DB" -X -A -t -F ',' -c \
 "SELECT 'categoria',count(*) FROM categoria UNION ALL SELECT 'cliente',count(*) FROM cliente
  UNION ALL SELECT 'producto',count(*) FROM producto UNION ALL SELECT 'pedido',count(*) FROM pedido
  UNION ALL SELECT 'detalle_pedido',count(*) FROM detalle_pedido" > "$OUT.counts"

pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DB" -Fc -f "$OUT.partial" 2>>"$LOG"

# Verificar que el archivo es legible por pg_restore antes de darlo por bueno
pg_restore --list "$OUT.partial" > /dev/null 2>>"$LOG"
mv "$OUT.partial" "$OUT"

SIZE="$(du -h "$OUT" | cut -f1)"
log "OK archivo=$(basename "$OUT") tamano=$SIZE"
