-- TP8 · Consigna 2.c · Después de reimportar la instantánea "después"
-- (el semáforo se corre aparte con: .read movil/semaforo.sql)

-- C2: el cliente acepta el precio nuevo -> se actualiza el borrador y se crea una solicitud nueva
UPDATE item_borrador
SET precio_centavos_visto = (SELECT precio_centavos FROM snapshot_servidor s WHERE s.id = item_borrador.producto_id)
WHERE id_local = 'c2000000-0000-4000-8000-000000000001';

INSERT INTO cola_sync VALUES ('a2000000-0000-4000-8000-000000000002','c2000000-0000-4000-8000-000000000001','PENDIENTE',NULL);