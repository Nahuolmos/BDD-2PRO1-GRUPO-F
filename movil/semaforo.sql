-- =============================================================================
-- TRABAJO PRÁCTICO N.º 8 - FOOD STORE EN LA FERIA
-- Archivo: movil/semaforo.sql
-- Motor: SQLite 3.37+
-- Propósito: Implementación del Semáforo de Sincronización (Consigna 2.b)
-- =============================================================================

-- Regla de oro:
-- "El móvil propone, el servidor dispone."
-- Solo se evalúan solicitudes en estado 'PENDIENTE'.
-- Repetir la ejecución no reevalúa solicitudes ya resueltas (idempotencia).

WITH evaluacion AS (
    SELECT 
        c.solicitud_uuid,
        -- Determinación del Estado (Semáforo)
        CASE
            -- 1. ROJO: RECHAZADO (producto no existe, eliminado, no disponible o falta de stock)
            WHEN SUM(CASE WHEN s.id IS NULL THEN 1 ELSE 0 END) > 0 
                THEN 'RECHAZADO'
            WHEN SUM(CASE WHEN s.eliminado = 1 THEN 1 ELSE 0 END) > 0 
                THEN 'RECHAZADO'
            WHEN SUM(CASE WHEN s.disponible = 0 THEN 1 ELSE 0 END) > 0 
                THEN 'RECHAZADO'
            WHEN SUM(CASE WHEN i.cantidad > s.stock THEN 1 ELSE 0 END) > 0 
                THEN 'RECHAZADO'
                
            -- 2. AMARILLO: CONFLICTO (no hay rojo, pero hubo variación en el precio del catálogo)
            WHEN SUM(CASE WHEN i.precio_centavos_visto <> s.precio_centavos THEN 1 ELSE 0 END) > 0 
                THEN 'CONFLICTO'
                
            -- 3. VERDE: SIMULADO_APROBADO (precio y stock coinciden con la instantánea)
            ELSE 'SIMULADO_APROBADO'
        END AS nuevo_estado,
        
        -- Detalle descriptivo del motivo
        CASE
            WHEN SUM(CASE WHEN s.id IS NULL THEN 1 ELSE 0 END) > 0 
                THEN 'RECHAZADO: Producto inexistente en el catálogo del servidor'
            WHEN SUM(CASE WHEN s.eliminado = 1 THEN 1 ELSE 0 END) > 0 
                THEN 'RECHAZADO: Producto dado de baja lógica en el servidor'
            WHEN SUM(CASE WHEN s.disponible = 0 THEN 1 ELSE 0 END) > 0 
                THEN 'RECHAZADO: Producto no disponible temporalmente para venta'
            WHEN SUM(CASE WHEN i.cantidad > s.stock THEN 1 ELSE 0 END) > 0 
                THEN 'RECHAZADO: Stock insuficiente en servidor para la cantidad solicitada'
            WHEN SUM(CASE WHEN i.precio_centavos_visto <> s.precio_centavos THEN 1 ELSE 0 END) > 0 
                THEN 'CONFLICTO: El precio unitario cambió en el servidor respecto al visto en la tablet'
            ELSE 'SIMULADO_APROBADO: Todos los ítems coinciden en disponibilidad, stock y precio'
        END AS nuevo_motivo
    FROM cola_sync c
    JOIN item_borrador i ON i.id_local = c.id_local
    LEFT JOIN snapshot_servidor s ON s.id = i.producto_id
    WHERE c.estado = 'PENDIENTE'
    GROUP BY c.solicitud_uuid
)
UPDATE cola_sync
SET 
    estado = (SELECT nuevo_estado FROM evaluacion WHERE evaluacion.solicitud_uuid = cola_sync.solicitud_uuid),
    motivo = (SELECT nuevo_motivo FROM evaluacion WHERE evaluacion.solicitud_uuid = cola_sync.solicitud_uuid)
WHERE solicitud_uuid IN (SELECT solicitud_uuid FROM evaluacion);

-- Consulta de verificación de resultados
SELECT 
    solicitud_uuid, 
    id_local, 
    estado, 
    motivo 
FROM cola_sync;
