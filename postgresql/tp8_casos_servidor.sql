-- TP8 · Consigna 2.c · Cambios en el servidor (copia de pruebas)
-- Correr DESPUÉS de armar los borradores en SQLite (paso 5).

-- C2: sube el precio de la pizza
UPDATE producto SET precio_actual = 1200.00 WHERE nombre = 'Pizza Muzzarella';

-- C3: quedan pocas unidades de Coca (el borrador pide 10)
UPDATE producto SET stock = 5 WHERE nombre = 'Coca Cola 1.5L';

-- C4: baja lógica del postre
UPDATE producto SET eliminado = TRUE, activo = FALSE WHERE nombre = 'Postre Chocotorta';