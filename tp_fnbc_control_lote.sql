-- =============================================================================
-- TP Unidad 4 Parte 1: FNBC control_lote_almacen
-- Motor: PostgreSQL 16+
-- Spec: specs/spec_fnbc_control_lote.md
-- =============================================================================
-- NOTA repo: este repo usa cliente (schema.sql:49), no usuario. Se crea stub
-- usuario(id) solo para este TP para respetar REFERENCES usuario(id) de la
-- consigna. lote/deposito tampoco existen en el esquema, se crean IF NOT EXISTS.

-- -------------------------------------------------------------------------
-- 0. Limpieza idempotente (orden por dependencias)
-- -------------------------------------------------------------------------
DROP VIEW IF EXISTS v_control_lote_almacen;
DROP TABLE IF EXISTS control_lote;
DROP TABLE IF EXISTS responsable_deposito;
DROP TABLE IF EXISTS control_lote_almacen;

-- Maestras mínimas autocontenidas (consigna las asume existentes)
CREATE TABLE IF NOT EXISTS lote (
    id BIGINT PRIMARY KEY
);
CREATE TABLE IF NOT EXISTS deposito (
    id BIGINT PRIMARY KEY
);
CREATE TABLE IF NOT EXISTS usuario (
    id BIGINT PRIMARY KEY
);

-- -------------------------------------------------------------------------
-- 1. Esquema original + instancia de ejemplo (consigna §4.1)
-- DF1: {lote_id, deposito_id} -> responsable_control_id (PK)
-- DF2: responsable_control_id -> deposito_id (dato maestro personal)
-- -------------------------------------------------------------------------
CREATE TABLE control_lote_almacen (
    lote_id BIGINT NOT NULL REFERENCES lote(id),
    deposito_id BIGINT NOT NULL REFERENCES deposito(id),
    responsable_control_id BIGINT NOT NULL REFERENCES usuario(id),
    PRIMARY KEY (lote_id, deposito_id)
);

-- Maestras para la instancia
INSERT INTO lote (id) VALUES (501), (502), (503)
ON CONFLICT (id) DO NOTHING;
INSERT INTO deposito (id) VALUES (30), (31)
ON CONFLICT (id) DO NOTHING;
INSERT INTO usuario (id) VALUES (801), (802)
ON CONFLICT (id) DO NOTHING;

INSERT INTO control_lote_almacen VALUES
 (501, 30, 801),
 (502, 30, 801),
 (503, 31, 802);

-- -------------------------------------------------------------------------
-- 2. Descomposición sin pérdida (algoritmo Heath sobre DF violatoria R->D)
-- R1: responsable_deposito(R, D) — PK(R) captura R->D
-- R2: control_lote(L, R) — PK(L,R), clave candidata alternativa de (b)
-- -------------------------------------------------------------------------
CREATE TABLE responsable_deposito (
    responsable_control_id BIGINT NOT NULL REFERENCES usuario(id),
    deposito_id BIGINT NOT NULL REFERENCES deposito(id),
    PRIMARY KEY (responsable_control_id)
);

CREATE TABLE control_lote (
    lote_id BIGINT NOT NULL REFERENCES lote(id),
    responsable_control_id BIGINT NOT NULL REFERENCES responsable_deposito(responsable_control_id),
    PRIMARY KEY (lote_id, responsable_control_id)
);

-- -------------------------------------------------------------------------
-- 3. Vista de compatibilidad (reunión natural sobre atributo común)
-- -------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_control_lote_almacen AS
SELECT
    cl.lote_id,
    rd.deposito_id,
    cl.responsable_control_id
FROM control_lote cl
JOIN responsable_deposito rd
  ON cl.responsable_control_id = rd.responsable_control_id;

-- -------------------------------------------------------------------------
-- 4. Migración desde la instancia original (genérica, sin hardcodear)
-- -------------------------------------------------------------------------
INSERT INTO responsable_deposito (responsable_control_id, deposito_id)
SELECT DISTINCT responsable_control_id, deposito_id
FROM control_lote_almacen
ON CONFLICT (responsable_control_id) DO NOTHING;

INSERT INTO control_lote (lote_id, responsable_control_id)
SELECT lote_id, responsable_control_id
FROM control_lote_almacen
ON CONFLICT (lote_id, responsable_control_id) DO NOTHING;

-- -------------------------------------------------------------------------
-- 5. Verificación: la vista debe devolver exactamente la instancia original
-- -------------------------------------------------------------------------
-- SELECT * FROM v_control_lote_almacen ORDER BY lote_id;
-- Esperado: (501,30,801), (502,30,801), (503,31,802) — 3 tuplas, sin espurias.
-- (SELECT lote_id, deposito_id, responsable_control_id FROM v_control_lote_almacen
--  EXCEPT SELECT lote_id, deposito_id, responsable_control_id FROM control_lote_almacen)
-- UNION ALL
-- (SELECT lote_id, deposito_id, responsable_control_id FROM control_lote_almacen
--  EXCEPT SELECT lote_id, deposito_id, responsable_control_id FROM v_control_lote_almacen);
-- Resultado esperado: 0 filas.
-- Justificación sin pérdida (Heath): el atributo común responsable_control_id es
-- PK (superclave) en R1 responsable_deposito, luego R1 JOIN R2 es sin pérdida.
