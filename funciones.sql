-- =============================================================================
-- TPI — Objetivo 6: Funciones y procedimientos PL/pgSQL
-- Archivo: funciones.sql
-- Motor: PostgreSQL 16+ — Lenguaje: PL/pgSQL
-- Spec: specs/spec_funciones_procedimientos.md
-- =============================================================================
-- NOTA: Requiere soft_delete.sql aplicado (columna eliminado). Usa JSONB como
-- exige el TPI y se invoca con CALL para procedimientos.

-- -------------------------------------------------------------------------
-- Función: fn_total_pedido — retorna el total de un pedido
-- Qué hace: suma cantidad*precio_unitario de detalle_pedido para un pedido_id.
-- Por qué función: se puede usar en SELECT, WHERE, vistas. Ej: SELECT fn_total_pedido(1);
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_total_pedido(p_pedido_id BIGINT)
RETURNS NUMERIC(12,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC(12,2);
BEGIN
    -- Suma con COALESCE para retornar 0 si no hay detalles
    SELECT COALESCE(SUM(cantidad * precio_unitario), 0) INTO v_total
    FROM detalle_pedido
    WHERE pedido_id = p_pedido_id;

    RETURN v_total;
END;
$$;

COMMENT ON FUNCTION fn_total_pedido(BIGINT) IS 'Total de un pedido (suma detalle). Spec: spec_funciones_procedimientos.md';

-- Verificación:
-- SELECT fn_total_pedido(1) AS total_funcion;
-- SELECT SUM(cantidad*precio_unitario) FROM detalle_pedido WHERE pedido_id=1; -- debe coincidir
-- (SELECT fn_total_pedido(1) EXCEPT SELECT SUM(cantidad*precio_unitario) FROM detalle_pedido WHERE pedido_id=1) = 0 filas

-- -------------------------------------------------------------------------
-- Procedimiento: pr_crear_pedido — crea pedido con items JSONB
-- Qué hace: en una transacción, inserta un pedido y sus detalles desde un JSONB.
-- Por qué procedimiento: hace DML (INSERT) y se invoca con CALL, no con SELECT.
-- Usa JSONB como exige TPI: p_items = '[{"producto_id":1,"cantidad":2}, ...]'
-- Respeta soft delete y activo: rechaza productos eliminados o inactivos.
-- -------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE pr_crear_pedido(
    p_cliente_id BIGINT,
    p_items JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_pedido_id BIGINT;
    v_item JSONB;
    v_producto_id BIGINT;
    v_cantidad INT;
    v_precio NUMERIC(10,2);
BEGIN
    -- Validar cliente existe y no eliminado (si cliente tuviera eliminado, filtrar)
    IF NOT EXISTS (SELECT 1 FROM cliente WHERE id = p_cliente_id) THEN
        RAISE EXCEPTION 'Cliente % no existe', p_cliente_id;
    END IF;

    -- Validar JSONB es array
    IF jsonb_typeof(p_items) != 'array' THEN
        RAISE EXCEPTION 'p_items debe ser JSONB array, recibido %', jsonb_typeof(p_items);
    END IF;

    -- Crear pedido cabecera
    INSERT INTO pedido (cliente_id, forma_pago, fecha)
    VALUES (p_cliente_id, 'EFECTIVO', NOW())
    RETURNING id INTO v_pedido_id;

    -- Recorrer cada item del JSONB
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_producto_id := (v_item->>'producto_id')::BIGINT;
        v_cantidad    := (v_item->>'cantidad')::INT;

        IF v_cantidad IS NULL OR v_cantidad <= 0 THEN
            RAISE EXCEPTION 'Cantidad inválida para producto %', v_producto_id;
        END IF;

        -- Obtener precio_actual y validar vigencia y no eliminado
        SELECT precio_actual INTO v_precio
        FROM producto
        WHERE id = v_producto_id
          AND activo = TRUE
          AND eliminado = FALSE;

        IF v_precio IS NULL THEN
            RAISE EXCEPTION 'Producto % no existe, inactivo o eliminado', v_producto_id;
        END IF;

        -- Insertar detalle con precio histórico
        INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario)
        VALUES (v_pedido_id, v_producto_id, v_cantidad, v_precio);
    END LOOP;

    -- Si todo OK, la transacción del CALL hace COMMIT implícito si no hay error
    RAISE NOTICE 'Pedido % creado con % items', v_pedido_id, jsonb_array_length(p_items);
END;
$$;

COMMENT ON PROCEDURE pr_crear_pedido(BIGINT, JSONB) IS 'Crea pedido + detalles desde JSONB array. Invocar con CALL. Spec: spec_funciones_procedimientos.md';

-- Ejemplo de uso:
-- CALL pr_crear_pedido(1, '[{"producto_id":2,"cantidad":3},{"producto_id":3,"cantidad":1}]'::jsonb);
-- SELECT * FROM pedido ORDER BY id DESC LIMIT 1;
-- SELECT fn_total_pedido(currval('pedido_id_seq')); -- o SELECT fn_total_pedido((SELECT max(id) FROM pedido));
-- Verificación soft delete: UPDATE producto SET eliminado=TRUE WHERE id=2; CALL pr_crear_pedido(1, '[{"producto_id":2,"cantidad":1}]'::jsonb); -- debe fallar con RAISE EXCEPTION

-- Prueba de equivalencia para función:
-- SELECT fn_total_pedido(1) = (SELECT SUM(cantidad*precio_unitario) FROM detalle_pedido WHERE pedido_id=1);
