-- =============================================================================
-- TP Unidad 7 - NoSQL y nuevas formas de almacenamiento
-- Script de migración: Extraer 5 pedidos con detalles y clientes en formato JSON
-- Listo para importar en MongoDB con mongoimport o insertMany()
-- =============================================================================

-- Seleccionamos 5 pedidos existentes (los primeros 5 por id)
-- Cada fila produce un documento JSON listo para MongoDB
SELECT jsonb_build_object(
    'pedido_id', p.id,
    'fecha', to_char(p.fecha, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
    'estado', CASE
        WHEN p.fecha < NOW() - INTERVAL '6 months' THEN 'ENTREGADO'
        WHEN p.fecha < NOW() - INTERVAL '3 months' THEN 'ENVIADO'
        WHEN p.fecha < NOW() - INTERVAL '1 month' THEN 'PROCESANDO'
        ELSE 'PENDIENTE'
    END,
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
) as documento_json
FROM pedido p
JOIN cliente c ON c.id = p.cliente_id
WHERE p.id IN (
    SELECT id FROM pedido ORDER BY id LIMIT 5
)
ORDER BY p.id;

-- Nota: El resultado de esta consulta son 5 filas, cada una con un JSON.
-- Copiar cada JSON y pegar en un archivo JSON array para mongoimport,
-- o usar directamente en mongosh con insertMany().
-- Ejemplo de uso en mongosh:
-- db.pedidos.insertMany([ <JSON1>, <JSON2>, ... ])