# Informe post-incidente — Unidad 6: respaldo y recuperación

Food Store · PostgreSQL 16.15 · Grupo F · Simulacro sobre entorno de laboratorio (horas del servidor, UTC)

## 1. Respaldo utilizado

`foodstore_20261029_224320.dump` — generado el 29/10/2026 a las 22:43:20 con `backup_foodstore.sh` (formato custom, 4,5 MB / 4.641.362 bytes). Log: `logs/backup_20261029_224320.log` → `OK`, código de salida 0.

## 2. RPO y RTO: previstos vs. observados

| | Previsto (SPEC_U6) | Observado |
|---|---|---|
| **RTO** — tiempo hasta tener datos utilizables | 15 min | **1,5 s** (de antes de `createdb` hasta el fin de las validaciones) |
| **RPO** — datos que se pueden perder | 24 h (respaldo diario) | Antigüedad del respaldo al simular: **0,3 min** |

El RPO observado es optimista a propósito: el respaldo se tomó segundos antes del ensayo. El RPO real de la política es el intervalo entre respaldos: ante una falla justo antes del siguiente respaldo se pierden hasta 24 h de pedidos. El RTO de 1,5 s corresponde a ~53 MB; crece con el tamaño de la base y no es extrapolable a producción.

## 3. Resultado de las validaciones (en `foodstore_restore_test`)

| Tabla | categoria | cliente | producto | pedido | detalle_pedido |
|---|---|---|---|---|---|
| Antes del respaldo | 3 | 20.003 | 50.003 | 200.003 | 200.007 |
| Restaurado | 3 | 20.003 | 50.003 | 200.003 | 200.007 |

Conteos idénticos. `productos_invalidos = 0` y `detalles_invalidos = 0`. `foodstore` no se modificó durante el simulacro (200.003 pedidos antes y después).

## 4. Mantenimiento y monitoreo (evidencia)

- `health_check.sql`: base de 53 MB, 1 conexión, 0 consultas largas ni transacciones abiertas.
- `maintenance.sql`, estado natural: solo `ANALYZE categoria` (nunca analizada). Con actividad simulada (UPDATE sobre 20.001 filas de `producto`, 28,6 % de tuplas muertas): `VACUUM (ANALYZE) producto`, que dejó 0 muertas; las otras tablas no se tocaron. No se usa `VACUUM FULL`.

## 5. Problemas reales encontrados

- **Defecto propio del script:** un respaldo fallido (base inexistente) dejaba un `.counts` huérfano. Se corrigió en el `trap` y se repitió la prueba.
- **Validación de la consigna:** usa `producto.precio`, pero la columna es `precio_actual`; la consulta fallaría. Se adaptó.
- **Repositorio:** `schema.sql` no carga de una sola vez (el poblado masivo exige las categorías de `data.sql` → violación de FK). Se cargó en orden schema (DDL) → `data.sql` → poblado → `soft_delete.sql`.

## 6. Mejora propuesta

Copiar cada `.dump` a otro equipo o almacenamiento (y conservar solo los últimos 7) apenas termina el respaldo: hoy el dump está en el mismo disco que la base, así que un fallo de disco perdería ambos. Además, programar el script (cron / Programador de tareas) y alertar si el código de salida ≠ 0.

## 7. Asistencia de IA y verificación

El borrador de `SPEC_U6.md`, los scripts y este informe fue asistido por IA a partir de la consigna. Antes de aceptarlo se ejecutó todo: prueba negativa del respaldo (código de salida 2), respaldo real, `pg_restore --list`, comparación de conteos, validaciones lógicas, y lectura de cada comando (sin contraseñas: se usa `~/.pgpass`). Se corrigió el defecto del script y se adaptó la validación, según 5.
