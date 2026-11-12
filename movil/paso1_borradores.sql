-- TP8 · Consigna 2.c · Borradores armados con el catálogo "antes"
PRAGMA foreign_keys = ON;

-- C2 (la pizza va a subir de precio)
INSERT INTO pedido_borrador VALUES ('c2000000-0000-4000-8000-000000000001','operador_feria_1','EFECTIVO','2026-11-12T13:00:00Z');
INSERT INTO item_borrador SELECT 'c2000000-0000-4000-8000-000000000001', id, 1, precio_centavos FROM producto_cache WHERE nombre='Pizza Muzzarella';
INSERT INTO cola_sync VALUES ('a2000000-0000-4000-8000-000000000001','c2000000-0000-4000-8000-000000000001','PENDIENTE',NULL);

-- C3 (pide 10 Coca; después van a quedar 5)
INSERT INTO pedido_borrador VALUES ('c3000000-0000-4000-8000-000000000001','operador_feria_1','TARJETA','2026-11-12T13:05:00Z');
INSERT INTO item_borrador SELECT 'c3000000-0000-4000-8000-000000000001', id, 10, precio_centavos FROM producto_cache WHERE nombre='Coca Cola 1.5L';
INSERT INTO cola_sync VALUES ('a3000000-0000-4000-8000-000000000001','c3000000-0000-4000-8000-000000000001','PENDIENTE',NULL);

-- C4 (el postre va a ser dado de baja)
INSERT INTO pedido_borrador VALUES ('c4000000-0000-4000-8000-000000000001','operador_feria_1','EFECTIVO','2026-11-12T13:10:00Z');
INSERT INTO item_borrador SELECT 'c4000000-0000-4000-8000-000000000001', id, 1, precio_centavos FROM producto_cache WHERE nombre='Postre Chocotorta';
INSERT INTO cola_sync VALUES ('a4000000-0000-4000-8000-000000000001','c4000000-0000-4000-8000-000000000001','PENDIENTE',NULL);

-- C5 (sin cambios)
INSERT INTO pedido_borrador VALUES ('c5000000-0000-4000-8000-000000000001','operador_feria_1','EFECTIVO','2026-11-12T13:15:00Z');
INSERT INTO item_borrador SELECT 'c5000000-0000-4000-8000-000000000001', id, 2, precio_centavos FROM producto_cache WHERE nombre='Empanada de Carne';
INSERT INTO cola_sync VALUES ('a5000000-0000-4000-8000-000000000001','c5000000-0000-4000-8000-000000000001','PENDIENTE',NULL);

SELECT 'Borradores PENDIENTES' AS paso, solicitud_uuid, estado FROM cola_sync;