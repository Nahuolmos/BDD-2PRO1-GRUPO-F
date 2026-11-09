-- =============================================================================
-- TP Unidad 7 - NoSQL y nuevas formas de almacenamiento
-- Script de migración: Extraer 5 pedidos con detalles y clientes en formato JSON
-- Compatible con mongoimport o insertMany() en mongosh
-- =============================================================================

-- Esta consulta SQL transforma los datos relacionales de PostgreSQL 
-- al modelo documental de MongoDB con embebidos (cliente y array de detalles).
SELECT jsonb_pretty(jsonb_build_object(
    'pedido_id', p.id,
    'fecha', to_char(p.fecha, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'estado', COALESCE(p.estado, 'ENTREGADO'),
    'forma_pago', p.forma_pago,
    'cliente', jsonb_build_object(
        'cliente_id', c.id,
        'nombre', c.nombre,
        'email', c.email
    ),
    'detalles', (
        SELECT COALESCE(jsonb_agg(
            jsonb_build_object(
                'producto_id', dp.producto_id,
                'producto_nombre', pr.nombre,
                'cantidad', dp.cantidad,
                'precio_unitario', dp.precio_unitario,
                'subtotal', round(dp.cantidad * dp.precio_unitario::numeric, 2)
            )
            ORDER BY dp.producto_id
        ), '[]'::jsonb)
        FROM detalle_pedido dp
        JOIN producto pr ON pr.id = dp.producto_id
        WHERE dp.pedido_id = p.id
    ),
    'total', round(
        COALESCE((
            SELECT SUM(dp.cantidad * dp.precio_unitario)
            FROM detalle_pedido dp
            WHERE dp.pedido_id = p.id
        ), 0)::numeric, 2)
)) as documento_json
FROM pedido p
JOIN cliente c ON c.id = p.cliente_id
WHERE p.id IN (1, 2, 3, 4, 5)
ORDER BY p.id;
