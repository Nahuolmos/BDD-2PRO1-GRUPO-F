-- =============================================================================
-- TRABAJO PRÁCTICO N.º 8 - FOOD STORE EN LA FERIA
-- Archivo: movil/schema_sqlite.sql
-- Motor: SQLite 3.37+
-- Propósito: Esquema DDL para la tablet (modo STRICT y claves foráneas activas)
-- =============================================================================

PRAGMA foreign_keys = ON;

-- 1. Limpieza preventiva
DROP TABLE IF EXISTS cola_sync;
DROP TABLE IF EXISTS item_borrador;
DROP TABLE IF EXISTS pedido_borrador;
DROP TABLE IF EXISTS producto_cache;
DROP TABLE IF EXISTS snapshot_servidor;

-- 2. Tabla: producto_cache
-- Copia local del catálogo descargado del servidor para operar sin conexión.
-- Precios expresados estrictamente en centavos (enteros) para evitar errores IEEE 754.
CREATE TABLE producto_cache (
    id INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL,
    precio_centavos INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock_visto INTEGER NOT NULL CHECK (stock_visto >= 0),
    disponible INTEGER NOT NULL CHECK (disponible IN (0, 1)),
    eliminado INTEGER NOT NULL CHECK (eliminado IN (0, 1)),
    fecha_copia TEXT NOT NULL
) STRICT;

-- 3. Tabla: pedido_borrador
-- Cabecera del pedido tentativo armado por el operador en el food truck.
CREATE TABLE pedido_borrador (
    id_local TEXT PRIMARY KEY, -- UUID v4 generado localmente
    usuario TEXT NOT NULL,
    forma_pago TEXT NOT NULL CHECK (forma_pago IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA')),
    fecha TEXT NOT NULL
) STRICT;

-- 4. Tabla: item_borrador
-- Detalle de productos solicitados en el borrador.
CREATE TABLE item_borrador (
    id_local TEXT NOT NULL,
    producto_id INTEGER NOT NULL,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_centavos_visto INTEGER NOT NULL CHECK (precio_centavos_visto >= 0),
    PRIMARY KEY (id_local, producto_id),
    FOREIGN KEY (id_local) REFERENCES pedido_borrador(id_local) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES producto_cache(id)
) STRICT;

-- 5. Tabla: cola_sync
-- Registro de sincronización de cada borrador hacia el servidor.
CREATE TABLE cola_sync (
    solicitud_uuid TEXT PRIMARY KEY, -- UUID de la transacción de sincronización
    id_local TEXT NOT NULL,
    estado TEXT NOT NULL CHECK (estado IN ('PENDIENTE', 'CONFLICTO', 'RECHAZADO', 'SIMULADO_APROBADO')),
    motivo TEXT,
    FOREIGN KEY (id_local) REFERENCES pedido_borrador(id_local) ON DELETE CASCADE
) STRICT;

-- 6. Tabla auxiliar: snapshot_servidor
-- Tabla receptora de la instantánea exportada desde PostgreSQL (v_snapshot_movil).
CREATE TABLE snapshot_servidor (
    id INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL,
    precio_centavos INTEGER NOT NULL,
    stock INTEGER NOT NULL,
    disponible INTEGER NOT NULL,
    eliminado INTEGER NOT NULL,
    fecha_snapshot TEXT NOT NULL
) STRICT;
