# Modelo Documental - Food Store (Unidad 7 - NoSQL)

## Colección: `pedidos`

Cada documento representa un **pedido completo** con sus detalles embebidos y datos esenciales del cliente. Se utiliza el patrón de **embebido** para evitar joins y tener acceso rápido a la información completa del pedido en una sola lectura.

### Estructura del documento

```json
{
  "_id": ObjectId,                 // Identificador generado por MongoDB
  "pedido_id": <int>,              // Identificador de origen en PostgreSQL (conservado)
  "fecha": ISODate,                // Fecha del pedido
  "estado": "<string>",            // Estado del pedido (derivado de la fecha en migración)
  "forma_pago": "<string>",        // EFECTIVO, TARJETA o TRANSFERENCIA
  "cliente": {
    "cliente_id": <int>,
    "nombre": "<string>",
    "email": "<string>"
  },
  "detalles": [                    // Arreglo de líneas de pedido (embebido)
    {
      "producto_id": <int>,
      "producto_nombre": "<string>",
      "cantidad": <int>,
      "precio_unitario": <decimal>,
      "subtotal": <decimal>        // cantidad * precio_unitario
    },
    ...
  ],
  "total": <decimal>               // Suma de subtotales (precio histórico del pedido)
}
```

### Tablas de PostgreSQL involucradas

| Tabla PostgreSQL | Uso en el modelo documental |
|------------------|----------------------------|
| `pedido`         | pedido_id, fecha, forma_pago, estado (derivado) |
| `cliente`        | cliente_id, nombre, email (embebido en `cliente`) |
| `detalle_pedido` | detalle_pedido embebido en arreglo `detalles` |
| `producto`       | producto_id, producto_nombre (embebido en cada detalle) |

### Justificación del embebido

- **Detalles embebidos**: Un pedido siempre se consulta junto con sus líneas. Embeberlos evita joins costosos y garantiza atomicidad en la lectura del pedido completo.
- **Cliente embebido**: Los datos esenciales del cliente (id, nombre, email) se incluyen para evitar una segunda consulta al consultar pedidos. No se incluyen datos sensibles ni campos que cambien frecuentemente.
- **Precios históricos**: `precio_unitario` y `subtotal` se almacenan tal cual estaban al momento del pedido (inmutables), preservando la integridad histórica incluso si el precio del producto cambia después.

### Reglas de integridad durante la migración

1. **Integridad referencial de pedido-cliente**: Cada documento de pedido debe tener un `cliente.cliente_id` que corresponda a un cliente existente en PostgreSQL. No se migran pedidos huérfanos.
2. **Integridad de precios y cantidades**: `precio_unitario` en el documento debe coincidir exactamente con el valor en `detalle_pedido` al momento de la migración. `subtotal` debe ser siempre `cantidad * precio_unitario`.