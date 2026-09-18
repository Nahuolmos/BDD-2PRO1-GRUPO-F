# spec: indice_descartado_sobreindexacion

Objetivo: documentar propuesta de IA descartada por sobreindexacion.

Propuesta original de IA (OpenCode / Gemini):
```sql
CREATE INDEX idx_pedido_forma_pago ON pedido(forma_pago);
CREATE INDEX idx_producto_activo ON producto(activo);
CREATE INDEX idx_pedido_cliente_fecha ON pedido(cliente_id, fecha); -- redundante
```

Consulta que supuestamente optimizaría:
```sql
SELECT * FROM pedido WHERE forma_pago = 'EFECTIVO';
SELECT * FROM producto WHERE activo = TRUE;
```

Análisis y motivo de descarte:
- forma_pago es ENUM de 3 valores (EFECTIVO, TARJETA, TRANSFERENCIA) -> cardinalidad = 3, selectividad ~33% cada valor. Un B-tree sobre columna de baja cardinalidad sin condición parcial NO cambia Seq Scan a Index Scan en tabla de 200k, el optimizador prefiere Seq Scan por costo. Medición con EXPLAIN muestra que el índice no se usa (cost mayor que sequential).
- activo es BOOLEAN (2 valores) -> cardinalidad 2, aún peor. El 95%+ de los productos están activos (TRUE), por lo que filtrar activo=TRUE recupera casi toda la tabla. Índice completo sobre (activo) es inútil. Solo un índice PARCIAL WHERE activo=TRUE con columnas adicionales (categoria_id, precio) tendría sentido.
- idx_pedido_cliente_fecha(cliente_id, fecha) es redundante con idx_pedido_cliente_id(cliente_id) existente + idx_pedido_fecha(fecha) propuesto: el primero ya resuelve el JOIN por cliente, el segundo el rango por fecha. Un compuesto cliente+fecha solo ayudaría a la query muy específica "pedidos de un cliente en un rango", frecuencia baja, no justifica costo de mantenimiento en escritura.

Costo de mantenimiento: cada INSERT en pedido (~200k + carga diaria) y producto debe actualizar todos los índices. Medición de escritura (500 INSERT en detalle_pedido) mostró +18% de tiempo con índices redundantes (ver informe_mediciones.md). Principio: no crear índice si no demuestra cambio de plan y mejora.

Decisión: DESCARTADO. Se conserva documentado pero no se incluye en indices.sql.

Criterio aplicado: "un índice siempre ayuda" es falso; se descarta por baja selectividad y redundancia.
