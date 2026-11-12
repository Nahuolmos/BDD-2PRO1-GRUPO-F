-- TP8 · Consigna 2.a · Vista de instantánea para la tablet (ejecutar en foodstore_tp8)

CREATE OR REPLACE VIEW v_snapshot_movil AS
SELECT
    id,
    nombre,
    ROUND(precio_actual * 100)::int                              AS precio_centavos,
    stock,
    CASE WHEN activo    THEN 1 ELSE 0 END                        AS disponible,
    CASE WHEN eliminado THEN 1 ELSE 0 END                        AS eliminado,
    to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS fecha_snapshot
FROM producto;

-- Producto de prueba para el caso C4 (solo en la copia)
INSERT INTO producto (nombre, precio_actual, stock, activo, categoria_id)
VALUES ('Postre Chocotorta', 400.00, 10, TRUE, 1);

-- Anotá el id que devuelve (lo vas a usar en los \copy)
SELECT id, nombre FROM producto WHERE nombre = 'Postre Chocotorta';