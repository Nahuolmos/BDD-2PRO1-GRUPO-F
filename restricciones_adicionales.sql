-- =============================================================================
-- RESTRICCIONES ADICIONALES DE INTEGRIDAD - FOOD STORE
-- =============================================================================

-- 1. Regla: Validar formato básico de correo electrónico en clientes
ALTER TABLE cliente
ADD CONSTRAINT chk_cliente_email_formato 
CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- 2. Regla: Evitar pedidos con fechas futuras
ALTER TABLE pedido
ADD CONSTRAINT chk_pedido_fecha_no_futura 
CHECK (fecha <= NOW());