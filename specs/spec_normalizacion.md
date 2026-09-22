# spec: normalizacion_3FN_BCNF

Objetivo: justificar que el modelo Food Store está en 3FN/BCNF (Objetivo 3 TPI).

Tablas a analizar: categoria, producto, cliente, pedido, detalle_pedido (post soft delete).

Criterio: listar dependencias funcionales (DFs), verificar 1FN (atómicos), 2FN (sin dependencia parcial de clave), 3FN (sin transitiva), BCNF (todo determinante es superclave). Documentar en `normalizacion.md`.

Nota: agregar columna `eliminado` no rompe FN porque `id → eliminado` y no crea transitiva.
