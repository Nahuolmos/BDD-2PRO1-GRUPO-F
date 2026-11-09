# Trabajo Práctico · Unidad 7: NoSQL y nuevas formas de almacenamiento
## Food Store: Modelo Documental, Consultas y Evaluación Comparativa con PostgreSQL

* **Asignatura:** Bases de Datos II — Tecnicatura Universitaria en Programación (UTN)
* **Equipo de Trabajo:** Grupo F
* **Integrantes:** Ignacio Ariza, Nahuel Olmos, Facundo Cabrera
* **Repositorio de Trabajo:** [https://github.com/Nahuolmos/BDD-2PRO1-GRUPO-F](https://github.com/Nahuolmos/BDD-2PRO1-GRUPO-F)
* **Fecha:** Noviembre 2026

---

## 1. Modelo Documental y Migración (Parte 1)

### 1.1 Identificación del subconjunto relacional en PostgreSQL (Consigna 1)
Se seleccionó el subconjunto **pedidos y detalle de pedidos** del modelo relacional original de Food Store. Las tablas y claves intervinientes son:

| Tabla PostgreSQL | Clave Primaria (PK) | Claves Foráneas (FK) | Rol en el modelo relacional |
| :--- | :--- | :--- | :--- |
| `pedido` | `id` | `cliente_id` $\rightarrow$ `cliente(id)` | Cabecera del pedido, fecha, estado y forma de pago. |
| `cliente` | `id` | — | Datos del cliente (nombre, email). |
| `detalle_pedido` | `(pedido_id, producto_id)` | `pedido_id` $\rightarrow$ `pedido(id)`<br>`producto_id` $\rightarrow$ `producto(id)` | Líneas de pedido con cantidad y precio unitario histórico. |
| `producto` | `id` | `categoria_id` $\rightarrow$ `categoria(id)` | Catálogo de artículos con precio actual y stock. |

### 1.2 Esquema documental propuesto: Colección `pedidos` (Consigna 1)
En MongoDB se modeló una colección unificada denominada `pedidos`. Se aplicó el patrón de **embebido** (*embedded documents*) para optimizar el acceso completo al comprobante en una única operación:

```json
{
  "_id": ObjectId("672f..."),
  "pedido_id": 1,                      // ID numérico de origen en PostgreSQL (conservado)
  "fecha": ISODate("2026-03-15T19:30:00Z"),
  "estado": "ENTREGADO",               // 'PENDIENTE' | 'ENVIADO' | 'ENTREGADO'
  "forma_pago": "EFECTIVO",            // 'EFECTIVO' | 'TARJETA' | 'TRANSFERENCIA'
  "cliente": {                         // Objeto embebido (datos esenciales)
    "cliente_id": 1,                   // ID conservado de PostgreSQL
    "nombre": "Juan Pérez",
    "email": "juan.perez@email.com"
  },
  "detalles": [                        // Arreglo de subdocumentos (líneas de pedido)
    {
      "producto_id": 1,                // ID conservado de PostgreSQL
      "producto_nombre": "Pizza Muzzarella",
      "cantidad": 2,
      "precio_unitario": 1000.00,      // Precio histórico pactado
      "subtotal": 2000.00              // cantidad * precio_unitario
    },
    {
      "producto_id": 3,
      "producto_nombre": "Coca Cola 1.5L",
      "cantidad": 2,
      "precio_unitario": 450.00,
      "subtotal": 900.00
    }
  ],
  "total": 2900.00                     // Sumatoria histórica de subtotales
}
```

* **Campos principales:** `pedido_id`, `fecha`, `estado`, `forma_pago`, `total`.
* **Objetos y arreglos embebidos:** `cliente` (subdocumento) y `detalles` (arreglo de subdocumentos).
* **Identificadores conservados:** `pedido_id`, `cliente.cliente_id` y `detalles.producto_id`.

### 1.3 Procedencia de los datos y migración con `insertMany()` (Consigna 2)
Siguiendo el alcance sugerido de la consigna ante bases con datos acotados, se incorporaron **cinco pedidos de prueba autocontenidos y coherentes con las reglas del dominio** (registrados en `sql/u7_datos_prueba.sql` y `mongodb/datos_pedidos.json`). La migración se implementó mediante `db.pedidos.insertMany([...])` en el script [`mongodb/migrar_pedidos.js`](file:///c:/Users/Ignacio/Documents/GitHub/BDD-2PRO1-GRUPO-F/mongodb/migrar_pedidos.js):

```javascript
db = db.getSiblingDB("food_store");
db.pedidos.drop();
const res = db.pedidos.insertMany([ /* 5 documentos con líneas y clientes */ ]);
print(`Documentos insertados: ${res.insertedCount}`);
```

### 1.4 Reglas de integridad conservadas y justificación del embebido (Consigna 3)

1. **Reglas de integridad preservadas:**
   * **Integridad aritmética e inmutabilidad económica:** En cada subdocumento de detalle se verifica estrictamente que $\text{subtotal} = \text{cantidad} \times \text{precio\_unitario}$ y que $\text{total} = \sum \text{subtotal}_i$. Se congelan los precios de venta históricos sin recalcular contra el catálogo actual.
   * **Integridad referencial y completitud:** Ningún pedido puede migrarse sin un cliente asociado válido (`cliente_id` y datos no nulos) ni con líneas huérfanas. Se conservan unívocamente las claves foráneas de origen como campos de referencia.

2. **Justificación técnica del embebido:**
   * **Acceso atómico en lectura:** La lectura más crítica y frecuente de Food Store es recuperar el pedido completo con su comprador y productos. En PostgreSQL esto exige 3 `JOINs` entre 4 tablas; en MongoDB, un solo documento devuelve toda la jerarquía en $O(1)$.
   * **Protección ante mutaciones del catálogo:** Embeber `producto_nombre` y `precio_unitario` garantiza que futuros aumentos de precios o bajas lógicas de artículos no modifiquen retroactivamente compras ya cerradas.
   * **Baja cardinalidad (1:N acotada):** Un pedido gastronómico rara vez supera 20 ítems, manteniéndose a órdenes de magnitud del límite BSON de 16 MB.

---

## 2. Consultas y Verificación Cruzada (Parte 2)

### 2.1 Ejecución de consultas en MongoDB (Consigna 4)
Ejecutadas a través del script [`mongodb/consultas_mongodb.js`](file:///c:/Users/Ignacio/Documents/GitHub/BDD-2PRO1-GRUPO-F/mongodb/consultas_mongodb.js):

#### Consulta a) Mostrar todos los pedidos (identificador y estado)
```javascript
db.pedidos.find({}, { pedido_id: 1, estado: 1, _id: 0 }).sort({ pedido_id: 1 });
```
*Salida de consola:*
```json
{ "pedido_id": 1, "estado": "ENTREGADO" }
{ "pedido_id": 2, "estado": "ENTREGADO" }
{ "pedido_id": 3, "estado": "ENVIADO" }
{ "pedido_id": 4, "estado": "ENTREGADO" }
{ "pedido_id": 5, "estado": "PENDIENTE" }
```

#### Consulta b) Filtrar pedidos por estado existente (`ENTREGADO`)
```javascript
db.pedidos.find(
    { estado: "ENTREGADO" },
    { pedido_id: 1, estado: 1, fecha: 1, total: 1, _id: 0 }
).sort({ pedido_id: 1 });
```
*Salida de consola:*
```json
{ "pedido_id": 1, "estado": "ENTREGADO", "fecha": ISODate("2026-03-15T19:30:00Z"), "total": 2900 }
{ "pedido_id": 2, "estado": "ENTREGADO", "fecha": ISODate("2026-04-20T21:00:00Z"), "total": 1800 }
{ "pedido_id": 4, "estado": "ENTREGADO", "fecha": ISODate("2026-10-05T20:45:00Z"), "total": 6320 }
```

#### Consulta c) Buscar pedidos con producto determinado (`producto_id: 1`, Pizza Muzzarella)
```javascript
db.pedidos.find(
    { "detalles.producto_id": 1 },
    { pedido_id: 1, estado: 1, "detalles.$": 1, total: 1, _id: 0 }
).sort({ pedido_id: 1 });
```
*Salida de consola:*
```json
{ "pedido_id": 1, "estado": "ENTREGADO", "detalles": [{ "producto_id": 1, "producto_nombre": "Pizza Muzzarella", "cantidad": 2, "precio_unitario": 1000, "subtotal": 2000 }], "total": 2900 }
{ "pedido_id": 3, "estado": "ENVIADO",   "detalles": [{ "producto_id": 1, "producto_nombre": "Pizza Muzzarella", "cantidad": 3, "precio_unitario": 1050, "subtotal": 3150 }], "total": 4650 }
{ "pedido_id": 4, "estado": "ENTREGADO", "detalles": [{ "producto_id": 1, "producto_nombre": "Pizza Muzzarella", "cantidad": 4, "precio_unitario": 1100, "subtotal": 4400 }], "total": 6320 }
```

#### Consulta d) Buscar pedidos con total superior a importe elegido (`total > 5000`)
```javascript
db.pedidos.find(
    { total: { $gt: 5000 } },
    { pedido_id: 1, estado: 1, total: 1, "cliente.nombre": 1, _id: 0 }
).sort({ total: -1 });
```
*Justificación del umbral ($5.000,00):* El consumo promedio de Food Store oscila entre $1.400 y $3.000 (pedidos individuales o en pareja). El umbral de $5.000 permite identificar pedidos de mayor envergadura (reuniones familiares, eventos o cuentas corporativas) para segmentación y promociones VIP.
*Salida de consola:*
```json
{ "pedido_id": 4, "estado": "ENTREGADO", "cliente": { "nombre": "Juan Pérez" }, "total": 6320 }
```

---

### 2.2 Consultas equivalentes en PostgreSQL (Consigna 5)
Implementadas en [`postgresql/consultas_postgresql.sql`](file:///c:/Users/Ignacio/Documents/GitHub/BDD-2PRO1-GRUPO-F/postgresql/consultas_postgresql.sql):

```sql
-- Equivalente Consulta b)
SELECT p.id AS pedido_id, p.estado, to_char(p.fecha, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS fecha,
       round(SUM(dp.cantidad * dp.precio_unitario)::numeric, 2) AS total
FROM pedido p JOIN detalle_pedido dp ON dp.pedido_id = p.id
WHERE p.estado = 'ENTREGADO' AND p.id IN (1,2,3,4,5)
GROUP BY p.id, p.estado, p.fecha ORDER BY p.id;

-- Equivalente Consulta c)
SELECT p.id AS pedido_id, p.estado, dp.producto_id, pr.nombre AS producto_nombre,
       dp.cantidad, dp.precio_unitario, round((dp.cantidad * dp.precio_unitario)::numeric, 2) AS subtotal
FROM pedido p JOIN detalle_pedido dp ON dp.pedido_id = p.id
JOIN producto pr ON pr.id = dp.producto_id
WHERE dp.producto_id = 1 AND p.id IN (1,2,3,4,5) ORDER BY p.id;
```

### 2.3 Tabla de verificación y equivalencia cruzada (Consigna 5)

| Consulta | Cantidad en PostgreSQL | Cantidad en MongoDB | ¿Coinciden los IDs? | IDs recuperados |
| :--- | :---: | :---: | :---: | :--- |
| **Estado seleccionado (`ENTREGADO`)** | **3** | **3** | **Sí** | `[1, 2, 4]` |
| **Producto seleccionado (`producto_id: 1`)** | **3** | **3** | **Sí** | `[1, 3, 4]` |

**Análisis de diferencias y correcciones:**
* No existieron discrepancias en los resultados gracias a la rigurosidad en la definición de claves conservadas (`pedido_id`, `producto_id`) y la inmutabilidad de importes.
* En PostgreSQL, la consulta por producto requirió `JOIN detalle_pedido` y `JOIN producto`, mientras que en MongoDB se resolvió navegando el arreglo embebido mediante la notación de punto `"detalles.producto_id"` y el operador de proyección posicional `$`.

---

## 3. Evaluación de la Tecnología e IA (Parte 3)

### 3.1 Consulta formulada a la herramienta de IA (Consigna 6)
> *"En el sistema Food Store tenemos un modelo relacional en PostgreSQL donde los pedidos se gestionan a través de las tablas `pedido`, `detalle_pedido`, `cliente` y `producto`. El caso de uso predominante es el acceso frecuente y de lectura masiva a pedidos completos (cabecera, cliente y líneas). Asimismo, es crítico conservar la coherencia de cantidades y precios históricos al momento de la venta frente a futuros cambios del catálogo. ¿Conviene migrar este subconjunto a MongoDB o mantenerlo en PostgreSQL? Compara ambos motores considerando rendimiento de lectura, integridad de precios y complejidad del modelo."*

**Resumen de la respuesta de la IA:**
1. Sostuvo que *MongoDB siempre supera en rendimiento de lectura a PostgreSQL debido a que elimina los JOINs al embeber los datos en un solo documento, mientras que en PostgreSQL los JOINs siempre causan degradación a gran escala*.
2. Afirmó que *MongoDB, al carecer de esquema rígido (schemaless), no permite garantizar que el subtotal y el total coincidan con el cálculo de cantidad por precio unitario, obligando a delegar toda la integridad matemática en la capa de aplicación*.
3. Recomendó un enfoque híbrido pero minimizó los mecanismos de control de integridad de MongoDB.

---

### 3.2 Contraste de afirmaciones con documentación técnica oficial (Consigna 7)

#### Afirmación 1 de la IA:
> *"MongoDB siempre supera en rendimiento de lectura a PostgreSQL debido a la eliminación de JOINs al embeber datos."*

* **Contraste con Documentación Técnica:**
  * **MongoDB Docs (*Data Modeling: Embedded Data Models*):** Documenta que el modelo embebido minimiza las operaciones de I/O al concentrar datos relacionados en una única lectura de bloque.
  * **PostgreSQL Docs (*Index Scans & Performance Optimization*):** Documenta que mediante índices B-Tree en claves foráneas y el mecanismo de memoria compartida (*shared buffers*), PostgreSQL ejecuta consultas con `JOIN` sobre claves indexadas en tiempos sub-milisegundo.
* **Evaluación crítica:** **Parcialmente verdadera.** Para lecturas directas por ID de pedido completo, MongoDB es superior al evitar la reconstrucción de la estructura relacional. Sin embargo, para consultas que filtran por elementos anidados (como buscar qué pedidos contienen determinado producto), MongoDB requiere índices multikey sobre el arreglo (`detalles.producto_id`), aumentando el consumo de memoria en la caché de WiredTiger; en ese escenario, PostgreSQL con índices estándar y `Index Scan` resulta sumamente competitivo.

#### Afirmación 2 de la IA:
> *"MongoDB, al ser schemaless, no puede garantizar la coherencia de cantidades y precios históricos a nivel de base de datos."*

* **Contraste con Documentación Técnica:**
  * **MongoDB Docs (*Collection Management: Schema Validation & $jsonSchema*):** La documentación oficial desmiente la afirmación. MongoDB provee validación de esquemas robusta a nivel de colección utilizando `$jsonSchema` y el operador de expresiones `$expr`. Con estas herramientas es posible definir validaciones matemáticas obligatorias (`$eq: ["$subtotal", { $multiply: ["$cantidad", "$precio_unitario"] }]`), impidiendo la inserción de datos inconsistentes.
  * A nivel de diseño, almacenar los precios como valores numéricos inmutables en el subdocumento desacopla el pedido de las variaciones del catálogo sin requerir triggers complejos como en el modelo relacional.
* **Evaluación crítica:** **Falsa / Desactualizada.** MongoDB no es meramente *schemaless*; cuenta con mecanismos formales de validación declarativa que garantizan la integridad de importes sin depender exclusivamente del código de la aplicación.

---

### 3.3 Conclusión Técnica (Consigna 7 — Máximo 200 palabras)

Para el subconjunto de pedidos de Food Store, la estrategia óptima es una **arquitectura híbrida (persistencia políglota)**. PostgreSQL debe conservarse como motor transaccional primario (*Single Source of Truth*) para gestionar la creación de pedidos, el control estricto de concurrencia y la actualización atómica del stock mediante transacciones ACID multientidad. Por su parte, MongoDB es ideal como almacén de lectura desnormalizado para la consulta de pedidos históricos y visualización de comprobantes completos. Dos criterios técnicos fundamentan esta decisión: (1) **rendimiento de lectura unificada**: el modelo embebido en MongoDB consolida cliente, cabecera y líneas en un único documento BSON, eliminando 3 JOINs relacionales y optimizando la tasa de aciertos en caché; y (2) **inmutabilidad histórica**: encapsular `precio_unitario` y `producto_nombre` congela la fotografía económica de la venta, garantizando que cambios futuros del catálogo no alteren la facturación previa. PostgreSQL asegura integridad en escritura, y MongoDB maximiza la escalabilidad en lectura. *(147 palabras)*
