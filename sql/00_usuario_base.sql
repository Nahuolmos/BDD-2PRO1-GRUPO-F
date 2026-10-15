-- Reconstrucción mínima Clase 1/2 (no existía en repo: solo había cliente en schema.sql:49).
-- Crea usuario + fn_autenticar + fn_resetear_password para desbloquear Partes A/C/D.
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE IF NOT EXISTS usuario (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre TEXT NOT NULL,
    mail TEXT NOT NULL UNIQUE,
    contrasena_hash TEXT NOT NULL,
    rol TEXT NOT NULL DEFAULT 'cliente',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    eliminado BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE OR REPLACE FUNCTION fn_autenticar(p_mail TEXT, p_pass TEXT)
RETURNS BIGINT LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
    SELECT id INTO v_id FROM usuario
    WHERE mail = p_mail AND contrasena_hash = crypt(p_pass, contrasena_hash)
      AND eliminado = FALSE;
    IF NOT FOUND THEN RAISE EXCEPTION 'login fallido para %', p_mail; END IF;
    RETURN v_id;
END; $$;

CREATE OR REPLACE FUNCTION fn_resetear_password(p_user_id BIGINT, p_new_hash TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE usuario SET contrasena_hash = p_new_hash WHERE id = p_user_id;
END; $$;

-- Semilla mínima (sintética, para logs sin exponer reales)
INSERT INTO usuario (nombre, mail, contrasena_hash, rol) VALUES
 ('Soporte Uno', 'soporte1@foodstore.test', crypt('Soporte123', gen_salt('bf')), 'soporte'),
 ('Reportes Uno', 'reportes1@foodstore.test', crypt('Reportes123', gen_salt('bf')), 'reportes')
ON CONFLICT (mail) DO NOTHING;
