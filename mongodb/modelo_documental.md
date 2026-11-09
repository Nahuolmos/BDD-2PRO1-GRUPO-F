# Modelo Documental - Food Store (Unidad 7 - NoSQL)

## 1. Identificación del subconjunto relacional en PostgreSQL (Consigna 1)

El subconjunto seleccionado corresponde a la gestión de **pedidos y detalle de pedidos** de Food Store, involucrando las siguientes tablas del modelo relacional:

| Tabla PostgreSQL | Clave Primaria (PK) | Claves Foráneas (FK) | Rol en el modelo relacional |
|------------------|---------------------|----------------------|-----------------------------|
| `pedido` | `id` | `cliente_id` -> `cliente(id)` | Cabecera del pedido, fecha, forma de pago y estado. |
| `cliente` | `id` | - | Datos del comprador (nombre, email). |
| `detalle_pedido` | `(pedido_id, producto_id)` | `pedido_id` -> `pedido(id)`<br>`producto_id` -> `producto(id)` | Tabla asociativa con cantidad y precio unitario histórico. |
| `producto` | `id` | `categoria_id` -> `categoria(id)` | Catálogo de productos disponibles. |

---

## 2. Esquema de la Colección Documental: `pedidos`

En MongoDB, la unidad de consulta principal es el pedido completo. Por ende, se define una única colección `pedidos` que desnormaliza la jerarquía mediante objetos y arreglos embebidos (*embedding*).

### 2.1 Estructura del documento propuesto

```json
{
  "_id": ObjectId("..."),              // Identificador único nativo generado por MongoDB
  "pedido_id": 1,                      // Identificador numérico de origen en PostgreSQL (conservado)
  "fecha": ISODate("2026-03-15T19:30:00Z"), // Fecha y hora del pedido
  "estado": "ENTREGADO",               // Estado del ciclo de vida ('PENDIENTE', 'ENVIADO', 'ENTREGADO')
  "forma_pago": "EFECTIVO",            // Forma de pago ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA')
  "cliente": {                         // Objeto embebido con datos esenciales del cliente
    "cliente_id": 1,                   // Identificador conservado del cliente en PostgreSQL
    "nombre": "Juan Pérez",            // Nombre del cliente al momento de la compra
    "email": "juan.perez@email.com"    // Email de contacto
  },
  "detalles": [                        // Arreglo de subdocumentos embebidos (líneas de pedido)
    {
      "producto_id": 1,                // Identificador conservado del producto en PostgreSQL
      "producto_nombre": "Pizza Muzzarella", // Denominación histórica del producto
      "cantidad": 2,                   // Cantidad solicitada (entero > 0)
      "precio_unitario": 1000.00,      // Precio pactado al momento de la venta
      "subtotal": 2000.00              // Importe de la línea (cantidad * precio_unitario)
    },
    {
      "producto_id": 3,
      "producto_nombre": "Coca Cola 1.5L",
      "cantidad": 2,
      "precio_unitario": 450.00,
      "subtotal": 900.00
    }
  ],
  "total": 2900.00                     // Monto total del pedido (suma de subtotales)
}
```

### 2.2 Componentes del modelo
* **Campos principales:** `pedido_id`, `fecha`, `estado`, `forma_pago`, `total`.
* **Objetos embebidos:** `cliente` (almacena `cliente_id`, `nombre`, `email`).
* **Arreglos embebidos:** `detalles` (lista de subdocumentos con cada ítem ordenado).
* **Identificadores conservados:** `pedido_id` (PK original de `pedido`), `cliente.cliente_id` (PK original de `cliente`) y `detalles.producto_id` (PK original de `producto`).

---

## 3. Justificación de Diseño y Embebido (Consigna 3)

### ¿Por qué embeber en lugar de usar colecciones separadas?
1. **Acceso atómico y eliminación de JOINs:** En el dominio de Food Store, la lectura más frecuente consiste en visualizar el comprobante o resumen completo del pedido (quién lo compró, qué ítems contiene y el total facturado). En PostgreSQL esto exige un JOIN entre 4 tablas (`pedido`, `cliente`, `detalle_pedido`, `producto`). En MongoDB, un único documento embebido satisface toda la vista en una operación de lectura $O(1)$ por clave o índice.
2. **Inmutabilidad y consistencia de precios históricos:** Los precios de los productos en el catálogo cambian con el tiempo (por inflación o promociones). Embeber `producto_nombre` y `precio_unitario` dentro del detalle congela la fotografía histórica de la transacción, garantizando que futuras modificaciones en la colección de productos no alteren retroactivamente el monto facturado ni la descripción del artículo adquirido.
3. **Cardinalidad acotada (1:N pequeña):** Un pedido en un local gastronómico rara vez supera las 10 a 20 líneas de detalle. El límite de 16 MB por documento en BSON de MongoDB está extremadamente lejos de alcanzarse, haciendo del patrón embebido la alternativa idónea sin riesgo de sobrecarga de memoria.

---

## 4. Reglas de Integridad a Conservar Durante la Migración (Consigna 3)

1. **Integridad de cálculo e inmutabilidad económica:**
   * En cada línea de detalle, se debe cumplir estrictamente: $\text{subtotal} = \text{cantidad} \times \text{precio\_unitario}$.
   * El atributo `total` del pedido debe ser idéntico a la sumatoria de los subtotales: $\text{total} = \sum \text{subtotal}_i$.
   * Los valores deben respetar los importes históricos registrados en la base relacional, sin recalcularlos con el `precio_actual` del catálogo vigente.
2. **Integridad referencial y unicidad de entidades:**
   * Ningún documento de pedido puede migrarse sin un cliente asociado válido (`cliente.cliente_id` y datos no nulos).
   * Se deben preservar unívocamente los identificadores de origen (`pedido_id`, `cliente.cliente_id`, `producto_id`), evitando duplicidad de pedidos o líneas huérfanas en el arreglo.
