-- Parte B: secuencia de prueba (1 lectura, 1 inserción, 1 actualización, 1 login fallido)
-- 1. Lectura
SELECT * FROM v_productos_vigentes LIMIT 5;
-- 2. Inserción
INSERT INTO pedido (cliente_id, forma_pago, fecha, eliminado) VALUES (20001, 'EFECTIVO', NOW(), FALSE) RETURNING id;
-- 3. Actualización (usar el id devuelto, ej. 3)
-- UPDATE producto SET stock = stock - 1 WHERE id = 50001;
-- 4. Login fallido (debe dar EXCEPTION y quedar en log)
-- SELECT fn_autenticar('nadie@foodstore.test', 'wrongpass');
