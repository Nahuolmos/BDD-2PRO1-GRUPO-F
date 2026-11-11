# SPEC_U6 — Mantenimiento, respaldo y recuperación (Food Store)

**Motor:** PostgreSQL 16+ · **Base:** `foodstore` · **Base de ensayo:** `foodstore_restore_test`

## Qué se automatiza, frecuencia y condición de éxito
| Tarea | Script | Frecuencia | Terminó bien si… |
|---|---|---|---|
| Respaldo | `backup_foodstore.sh` | Diaria | Existe `backups/foodstore_AAAAMMDD_HHMMSS.dump`, `pg_restore --list` lo lee, el log dice `OK` y el código de salida es 0. |
| Chequeo de salud | `health_check.sql` | Diaria | Corre sin error en PG16+ y no hay sesiones `idle in transaction` ni consultas > 5 min. |
| Revisión de mantenimiento | `maintenance.sql` | Semanal | Se revisó el estado de tuplas muertas/autovacuum/estadísticas y solo se ejecutó VACUUM/ANALYZE donde la observación lo justifica. |
| Restauración de prueba | `restore_test.sh` | Semanal | Filas = las previas al respaldo, `productos_invalidos = 0`, `detalles_invalidos = 0`. |

## Objetivos del laboratorio
- **RPO previsto: 24 h** (respaldo diario). **RTO previsto: 15 min** (restauración + validaciones).

## Reglas de seguridad
1. Nada de contraseñas en scripts ni repo: se usa `~/.pgpass` (modo 600) o `PGPASSFILE`.
2. `foodstore` nunca se elimina ni se reemplaza: la restauración va solo a `foodstore_restore_test`, y el script se niega a operar si el destino es `foodstore`.
3. Respaldo en formato custom (`-Fc`), escrito a un `.partial` y renombrado solo si `pg_dump` y la verificación salen bien (no quedan dumps a medias).
4. `VACUUM FULL` no se usa como mantenimiento periódico (bloquea la tabla con `ACCESS EXCLUSIVE`).
5. El `.dump` y los logs no se versionan (`.gitignore`).

## Uso de OpenCode
Genera la primera versión de los scripts a partir de este archivo; cada comando se revisa y se prueba a mano antes de aceptarlo (ver `informe_u6`).
