#!/usr/bin/env bash
# Simulacro de restauración: último respaldo -> foodstore_restore_test. NUNCA toca foodstore.
# Sin contraseña: usa ~/.pgpass o PGPASSFILE. Uso: ./restore_test.sh [archivo.dump]
set -euo pipefail

PGHOST="${PGHOST:-localhost}"; PGPORT="${PGPORT:-5432}"; PGUSER="${PGUSER:-postgres}"
TARGET="foodstore_restore_test"
DIR="$(cd "$(dirname "$0")" && pwd)"
PSQL=(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -X -v ON_ERROR_STOP=1)

# Guardas de seguridad
[ "$TARGET" != "foodstore" ] || { echo "Destino inválido: foodstore"; exit 2; }

DUMP="${1:-$(ls -1t "$DIR"/backups/foodstore_*.dump | head -n1)}"
[ -f "$DUMP" ] || { echo "No hay respaldo: $DUMP"; exit 1; }
COUNTS="${DUMP}.counts"
LOG="$DIR/logs/restore_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

echo "Respaldo usado : $(basename "$DUMP")"
BACKUP_EPOCH=$(stat -c %Y "$DUMP")

# --- CRONÓMETRO: inicia inmediatamente antes de crear la base de prueba ---
T0=$(date +%s.%N); echo "Inicio         : $(date '+%F %T')"
"${PSQL[@]}" -d postgres -c "DROP DATABASE IF EXISTS $TARGET" >/dev/null   # solo la base de ensayo
createdb -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" "$TARGET"
pg_restore -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$TARGET" --no-owner --no-privileges "$DUMP"

echo "--- Filas restauradas ---"
"${PSQL[@]}" -d "$TARGET" -A -t -F ',' -c "
 SELECT 'categoria',count(*) FROM categoria UNION ALL SELECT 'cliente',count(*) FROM cliente
 UNION ALL SELECT 'producto',count(*) FROM producto UNION ALL SELECT 'pedido',count(*) FROM pedido
 UNION ALL SELECT 'detalle_pedido',count(*) FROM detalle_pedido" > "$DUMP.restored"
cat "$DUMP.restored"

echo "--- Validaciones lógicas ---"
# Nota: la consigna usa 'precio'; en este esquema la columna es precio_actual.
"${PSQL[@]}" -d "$TARGET" -c "SELECT COUNT(*) AS productos_invalidos FROM producto WHERE precio_actual < 0 OR stock < 0;"
"${PSQL[@]}" -d "$TARGET" -c "SELECT COUNT(*) AS detalles_invalidos FROM detalle_pedido WHERE cantidad <= 0 OR precio_unitario < 0;"
INV_P=$("${PSQL[@]}" -d "$TARGET" -A -t -c "SELECT COUNT(*) FROM producto WHERE precio_actual < 0 OR stock < 0")
INV_D=$("${PSQL[@]}" -d "$TARGET" -A -t -c "SELECT COUNT(*) FROM detalle_pedido WHERE cantidad <= 0 OR precio_unitario < 0")

# --- CRONÓMETRO: fin al terminar las validaciones ---
T1=$(date +%s.%N)
RTO=$(echo "$T1 - $T0" | bc -l)
RPO_MIN=$(echo "($(date +%s) - $BACKUP_EPOCH) / 60" | bc -l)

STATUS=OK
if [ -f "$COUNTS" ] && diff -q "$COUNTS" "$DUMP.restored" >/dev/null; then echo "Conteos = previos al respaldo: SI"
else echo "Conteos = previos al respaldo: NO / sin referencia"; STATUS=FALLO; fi
{ [ "$INV_P" = 0 ] && [ "$INV_D" = 0 ]; } || STATUS=FALLO

printf 'RTO observado  : %.1f s\n' "$RTO"
printf 'Antigüedad del respaldo (RPO observado): %.1f min\n' "$RPO_MIN"
echo "Resultado      : $STATUS"
[ "$STATUS" = OK ]
