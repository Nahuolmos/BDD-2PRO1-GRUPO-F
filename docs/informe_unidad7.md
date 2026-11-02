# Informe Técnico - Unidad 7: NoSQL y nuevas formas de almacenamiento

**Proyecto:** Food Store  
**Tecnologías:** PostgreSQL (relacional) y MongoDB (documental)  
**Repositorio:** https://github.com/Nahuolmos/BDD-2PRO1-GRUPO-F  
**Autor:** Ignacio Ariza (Grupo F)  
**Fecha:** 2026-10

---

## 1. Modelo Documental y Migración

### 1.1 Colección seleccionada: `pedidos`

Se eligió el subconjunto **pedidos y detalle de pedidos** del esquema relacional de Food Store.

| Tabla PostgreSQL | Uso en MongoDB |
|------------------|----------------|
| `pedido` | `_id`, `pedido_id`, `fecha`, `estado`, `forma_pago` |
| `cliente` | `cliente` embebido (id, nombre, email) |
| `detalle_pedido` | `detalles` embebido como arreglo de líneas |
| `producto` | `producto_id`, `producto_nombre` embebidos en cada detalle |

### 1.2 Esquema del documento

```json
{
  "_id": ObjectId,
  "pedido_id": <int>,
  "fecha": ISODate,
  "estado": "<PENDIENTE|PROCESANDO|ENVIADO|ENTREGADO>",
  "forma_pago": "<EFECTIVO|TARJETA|TRANSFERENCIA>",
  "cliente": { "cliente_id": <int>, "nombre": "<str>", "email": "<str>" },
  "detalles": [
    { "producto_id": <int>, "producto_nombre": "<str>", "cantidad": <int>,
      "precio_unitario": <num>, "subtotal": <num> },
    ...
  ],
  "total": <num>
}
```

**Decisión de diseño:** Se embeben detalles y cliente en un solo documento para evitar joins y tener acceso rápido al pedido completo en una sola lectura.

### 1.3 Reglas de integridad durante la migración

1. **Referencial pedido-cliente:** Cada documento debe tener un `cliente.cliente_id` que corresponda a un cliente existente en PostgreSQL. No se migran pedidos huérfanos.
2. **Consistencia de precios y cantidades:** `precio_unitario` debe coincidir exactamente con el valor en `detalle_pedido` al momento de migrar. `subtotal = cantidad × precio_unitario` siempre.

### 1.4 Justificación de embebido

Se incluyeron dentro del documento: detalles (cantidad, precio, producto) y datos esenciales del cliente (id, nombre, email). **Justificación:** Un pedido se consulta siempre junto con sus líneas y su cliente; embeberlos elimina joins costosos y garantiza lectura atómica del pedido completo. Los precios se almacenan como valores históricos (inmutables) para preservar la integridad aunque el precio del producto cambie después.

---

## 2. Consultas Ejecutadas y Resultados

### 2.1 Consulta a) - Todos los pedidos (identificador y estado)

**MongoDB:**
```javascript
db.pedidos.find(
    {},
    { pedido_id: 1, estado: 1, _id: 0 }
).sort({ pedido_id: 1 });
```

**Resultado esperado:** 5 documentos con `pedido_id` y `estado`.

> [CAPTURA: Resultado de consulta a) en MongoDB]

### 2.2 Consulta b) - Filtrar por estado ENTREGADO

**MongoDB:**
```javascript
db.pedidos.find(
    { estado: "ENTREGADO" },
    { pedido_id: 1, estado: 1, fecha: 1, total: 1, _id: 0 }
).sort({ fecha: -1 });
```

**PostgreSQL equivalente:**
```sql
SELECT p.id AS pedido_id, ... 
FROM pedido p
WHERE CASE ... END = 'ENTREGADO'
ORDER BY p.fecha DESC;
```

> [CAPTURA: Resultado MongoDB y PostgreSQL]

### 2.3 Consulta c) - Pedidos con producto_id 50001

**MongoDB:**
```javascript
db.pedidos.find(
    { "detalles.producto_id": 50001 },
    { pedido_id: 1, estado: 1, "detalles.$": 1, total: 1, _id: 0 }
);
```

**PostgreSQL equivalente:**
```sql
SELECT DISTINCT p.id AS pedido_id, ...
FROM pedido p
JOIN detalle_pedido dp ON dp.pedido_id = p.id
WHERE dp.producto_id = 50001
ORDER BY p.id;
```

> [CAPTURA: Resultado MongoDB y PostgreSQL]

### 2.4 Consulta d) - Pedidos con total > 5000

**MongoDB:**
```javascript
db.pedidos.find(
    { total: { $gt: 5000 } },
    { pedido_id: 1, estado: 1, total: 1, "cliente.nombre": 1, _id: 0 }
).sort({ total: -1 });
```

**Justificación del umbral (5000):** Es un monto significativo que filtra pedidos de mayor valor, permitiendo identificar compras al por mayor o clientes VIP. Con 5 pedidos migrados es esperable que al menos uno supere este umbral para demostrar la consulta.

---

## 3. Tabla de Verificación (MongoDB vs PostgreSQL)

| Consulta | Cantidad en PostgreSQL | Cantidad en MongoDB | ¿Coinciden los IDs? |
|----------|----------------------|-------------------|---------------------|
| Estado ENTREGADO | ____ | ____ | Sí / No |
| Producto 50001 | ____ | ____ | Sí / No |

> **Instrucción:** Ejecutar ambas consultas, completar la tabla y adjuntar capturas. Si hay diferencia, revisar que el estado derivado en MongoDB coincida con la lógica de PostgreSQL.

---

## 4. Contraste de Recomendaciones de IA

### 4.1 Consulta a la IA
Se consultó a una herramienta de IA sobre el almacenamiento y consulta de pedidos de Food Store, mencionando:
- Modelo actual relacional (PostgreSQL)
- Acceso frecuente a pedidos completos (cliente + detalles)
- Necesidad de conservar coherencia de cantidades y precios históricos

### 4.2 Afirmaciones de la IA y contraste con evidencia

| Afirmación de la IA | ¿Correcta? | Evidencia / Corrección |
|---------------------|------------|------------------------|
| "MongoDB es siempre más rápido para consultas de pedidos completos" | Parcialmente | Correcto para lectura de un pedido completo (un documento vs 3 joins), pero PostgreSQL con índices es rápido para búsquedas específicas por producto o fecha. |
| "MongoDB no requiere esquema, por lo que es mejor para datos que cambian" | Incorrecto / Matizado | Aunque es flexible, Food Store necesita consistencia de precios históricos y cantidades. Un esquema sin validación puede permitir datos inconsistentes. |
| "NoSQL elimina la necesidad de normalización" | Incorrecto | La normalización sigue siendo relevante para evitar redundancia de datos de cliente/producto si se usan colecciones separadas. El embebido es una decisión de diseño, no eliminación de normalización. |

### 4.3 Conclusión (máximo 200 palabras)

Para el subconjunto de pedidos de Food Store, **conviene combinar tecnologías**. PostgreSQL mantiene la integridad transacional y referencial del sistema operativo (ventas, clientes, productos), mientras que MongoDB es ideal para el subconjunto de pedidos donde se necesita acceso rápido y frecuente al pedido completo con sus detalles embebidos. Dos criterios técnicos fundamentan esta decisión: (1) **lectura unificada**: un solo documento en MongoDB devuelve pedido + cliente + detalles, evitando 3 joins en PostgreSQL; y (2) **consistencia histórica**: los precios y cantidades se almacenan inmutables dentro del documento, protegiendo la facturación histórica de cambios posteriores en el catálogo de productos. PostgreSQL seguiría siendo el motor maestro para transacciones de escritura y reglas de negocio complejas, y MongoDB se usaría como almacén de lectura optimizada para consultas de pedidos.