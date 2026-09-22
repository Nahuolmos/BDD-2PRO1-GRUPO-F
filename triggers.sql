-- =============================================================================
-- TPI — Objetivo 7: Reglas de negocio con triggers
-- Archivo: triggers.sql
-- Motor: PostgreSQL 16+ — PL/pgSQL
-- Spec: specs/spec_triggers.md
-- =============================================================================
-- NOTA: Complementa CHECK/UNIQUE ya en schema.sql. Requiere soft_delete.sql.

-- -------------------------------------------------------------------------
-- Función trigger: validar stock y vigencia antes de insertar detalle
-- Qué hace: impide vender producto sin stock o eliminado/inactivo.
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_validar_stock()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_stock INT;
    v_activo BOOLEAN;
    v_eliminado BOOLEAN;
BEGIN
    SELECT stock, activo, eliminado INTO v_stock, v_activo, v_eliminado
    FROM producto
    WHERE id = NEW.producto_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Producto % no existe', NEW.producto_id;
    END IF;

    IF v_eliminado = TRUE THEN
        RAISE EXCEPTION 'Producto % está eliminado (soft delete)', NEW.producto_id;
    END IF;

    IF v_activo = FALSE THEN
        RAISE EXCEPTION 'Producto % no está vigente (activo=FALSE)', NEW.producto_id;
    END IF;

    IF v_stock < NEW.cantidad THEN
        RAISE EXCEPTION 'Stock insuficiente para producto %: stock %, pedido %', NEW.producto_id, v_stock, NEW.cantidad;
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION fn_validar_stock() IS 'Valida stock/vigencia/soft delete antes de detalle. Spec: spec_triggers.md';

-- Trigger BEFORE INSERT en detalle_pedido
DROP TRIGGER IF EXISTS trg_validar_stock ON detalle_pedido;
CREATE TRIGGER trg_validar_stock
BEFORE INSERT ON detalle_pedido
FOR EACH ROW
EXECUTE FUNCTION fn_validar_stock();

-- -------------------------------------------------------------------------
-- Ejemplo opcional: auditoría con tabla de transición (PostgreSQL 16+)
-- Demuestra REFERENCING OLD TABLE AS (requisito TPI menciona tablas de transición)
-- -------------------------------------------------------------------------
-- Tabla de auditoría simple
CREATE TABLE IF NOT EXISTS auditoria_pedido (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_id BIGINT,
    accion TEXT,
    fecha TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION fn_auditoria_pedido()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO auditoria_pedido (pedido_id, accion)
    VALUES (NEW.id, 'INSERT pedido cliente ' || NEW.cliente_id);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auditoria_pedido ON pedido;
CREATE TRIGGER trg_auditoria_pedido
AFTER INSERT ON pedido
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_pedido();

-- Verificación:
-- INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES (1, 1, 9999, 100); -- debe fallar por stock
-- UPDATE producto SET eliminado=TRUE WHERE id=1; INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES (1, 1, 1, 100); -- debe fallar por eliminado
-- INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES (1, 2, 1, 500); -- debe pasar
-- SELECT * FROM auditoria_pedido; -- debe tener registro tras INSERT en pedido
