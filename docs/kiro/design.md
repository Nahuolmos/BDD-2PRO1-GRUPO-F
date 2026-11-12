# Documento de Diseño (Kiro) — Unidad 8: Base Móvil y Sincronización
## Proyecto Food Store · Arquitectura Offline-First con SQLite

---

### 1. Principio Fundamental y Regla de Oro

> **"El móvil propone, el servidor dispone."**  
> La tablet que opera en el food truck carece de conectividad continua. Por diseño, la tablet **únicamente consulta copias locales y genera borradores**. En ningún caso la tablet altera directamente el stock ni los precios del servidor, ni emite ventas confirmadas: el estado `SIMULADO_APROBADO` representa una validación previa de sincronización, nunca una venta consumada en PostgreSQL.

---

### 2. Consigna 1.a — Qué datos viajan a la tablet y quién es la fuente de verdad

#### Tabla de distribución de datos (Columnas de producto y entidades)

| Entidad / Columna | ¿Viaja a la tablet? | Destino en SQLite | Justificación técnica y de seguridad |
| :--- | :---: | :--- | :--- |
| `producto.id` | **SÍ** | `producto_cache.id` | Identificador unívoco necesario para armar los ítems del borrador. |
| `producto.nombre` | **SÍ** | `producto_cache.nombre` | Denominación requerida para que el operador atienda y visualice el menú. |
| `producto.precio_actual` | **SÍ (en centavos)** | `producto_cache.precio_centavos` | Precio de referencia para calcular subtotales estimados en la feria. |
| `producto.stock` | **SÍ** | `producto_cache.stock_visto` | Stock estimado al momento de la última instantánea para alertar faltantes. |
| `producto.activo` | **SÍ (0 o 1)** | `producto_cache.disponible` | Indica si el producto se puede ofrecer al público. |
| `producto.eliminado` | **SÍ (0 o 1)** | `producto_cache.eliminado` | Lápida (*tombstone*) para no mostrar productos dados de baja lógica. |
| `producto.created_at` | **NO** | — | Metadato de auditoría interno de PostgreSQL sin valor operativo en la tablet. |
| `producto.categoria_id` | **NO** | — | Para la venta rápida en feria solo se requiere el nombre y precio del producto. |
| `cliente` (emails, nombres) | **NO** | — | **Privacidad:** No se exponen datos personales de clientes en dispositivos móviles. |
| `usuario` (contraseñas, hashes) | **NO** | — | **Seguridad estricta:** Riesgo crítico ante extravío o robo físico de la tablet. |
| `auditoria_operaciones` | **NO** | — | Los logs de seguridad y auditoría residen exclusivamente en el servidor central. |

#### Fuente de Verdad (*Single Source of Truth*)
La única fuente de verdad es la base de datos central en **PostgreSQL**. La tablet opera exclusivamente con una instantánea desacoplada y de solo lectura (`producto_cache`). Toda transacción iniciada en la tablet es un borrador tentativo que debe ser sometido a las reglas de validación y control de concurrencia del servidor central al recuperar señal.

---

### 3. Modelo de Datos en SQLite (Tablas STRICT)

Se utiliza SQLite 3.37+ con la cláusula `STRICT` y activación explícita de `PRAGMA foreign_keys = ON;`. Los precios se manejan como **enteros en centavos** (`INTEGER`) para erradicar errores de precisión de punto flotante.

```
+---------------------+        +--------------------+
|   producto_cache    |        |  pedido_borrador   |
+---------------------+        +--------------------+
| id (PK)             |<--+    | id_local (PK, UUID)|<---+
| nombre              |   |    | usuario            |    |
| precio_centavos     |   |    | forma_pago         |    |
| stock_visto         |   |    | fecha              |    |
| disponible (0/1)    |   |    +--------------------+    |
| eliminado (0/1)     |   |               |              |
| fecha_copia         |   |               | 1:N          |
+---------------------+   |    +--------------------+    |
                          +----|   item_borrador    |    |
                               +--------------------+    |                  |
                               | id_local (FK)  ----|----+
                               | producto_id (FK) --|
                               | cantidad           |
                               | precio_cent_visto  |
                               +--------------------+
                                          |
                               +--------------------+
                               |     cola_sync      |
                               +--------------------+
                               | solicitud_uuid(PK) |
                               | id_local (FK)      |
                               | estado             |
                               | motivo             |
                               +--------------------+
```

---

### 4. Mecanismo del Semáforo de Sincronización

1. **Exportación de instantánea (PostgreSQL):** La vista `v_snapshot_movil` emite el catálogo vigente a `servidor_snapshot.csv`.
2. **Importación (SQLite):** Se carga en `snapshot_servidor` dentro de la base de la tablet.
3. **Evaluación de solicitudes `PENDIENTE`:**
   * **🔴 RECHAZADO:** Si algún ítem pide un producto inexistente, no disponible (`disponible = 0`), eliminado (`eliminado = 1`) o si `cantidad > stock`.
   * **🟡 CONFLICTO:** Si no hay rechazo pero al menos un ítem difiere en precio (`precio_centavos_visto != precio_centavos`).
   * **🟢 SIMULADO_APROBADO:** Si todos los ítems coinciden exactamente en precio, disponibilidad y stock.
