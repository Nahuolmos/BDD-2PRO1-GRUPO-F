-- Parte A: roles mínimo privilegio (spec: docs/kiro_roles_spec/).
-- Requiere sql/00_usuario_base.sql aplicado.
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_app_lectura') THEN CREATE ROLE rol_app_lectura NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_app_escritura') THEN CREATE ROLE rol_app_escritura NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_soporte') THEN CREATE ROLE rol_soporte NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_reportes') THEN CREATE ROLE rol_reportes NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_web') THEN CREATE ROLE app_web LOGIN PASSWORD 'AppWeb123' IN ROLE rol_app_escritura; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_datos') THEN CREATE ROLE admin_datos LOGIN PASSWORD 'Admin123'; END IF;
END $$;

-- Lectura: solo catálogo y vistas públicas
GRANT SELECT ON producto, categoria TO rol_app_lectura;
GRANT SELECT ON v_productos_vigentes TO rol_app_lectura, rol_reportes;

-- Escritura: opera pedidos + funciones, hereda lectura vía membresía
GRANT rol_app_lectura TO rol_app_escritura;
GRANT SELECT, INSERT, UPDATE ON pedido, detalle_pedido TO rol_app_escritura;
GRANT EXECUTE ON FUNCTION fn_total_pedido(BIGINT) TO rol_app_escritura;

-- Soporte: ve pedidos pero de usuario solo columnas no sensibles (sin contrasena_hash)
GRANT SELECT ON pedido TO rol_soporte;
GRANT SELECT (id, nombre, mail, rol) ON usuario TO rol_soporte;

-- Reportes: solo vistas, nada de tablas base con PII
GRANT SELECT ON v_pedidos_con_cliente, v_detalle_pedido_con_producto, mv_ventas_dia_categoria TO rol_reportes;

-- Admin: amplio pero sin SUPERUSER; nunca GRANT ALL ON ALL genérico
GRANT ALL ON ALL TABLES IN SCHEMA public TO admin_datos;

-- Futuras tablas heredan solo lectura (nada de escritura automática)
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO rol_app_lectura, rol_reportes;

-- Verificación (pegar salida en docs/):
-- \du
-- SELECT grantee, table_name, privilege_type FROM information_schema.role_table_grants
-- WHERE grantee IN ('rol_app_lectura','rol_app_escritura','rol_soporte','rol_reportes') ORDER BY 1,2,3;
