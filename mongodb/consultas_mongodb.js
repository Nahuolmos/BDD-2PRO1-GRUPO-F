// =============================================================================
// TP UNIDAD 7: NoSQL y nuevas formas de almacenamiento | Food Store
// Archivo: mongodb/consultas_mongodb.js
// Motor: MongoDB (mongosh)
// Base de datos: food_store
// Colección: pedidos
// =============================================================================

// Conexión o cambio a la base de datos de Food Store
db = db.getSiblingDB("food_store");

print("=====================================================================");
print("          EJECUCIÓN DE CONSULTAS MONGODB - UNIDAD 7 (CONSIGNA 4)     ");
print("=====================================================================\n");

// -----------------------------------------------------------------------------
// Consulta a) Mostrar todos los pedidos, incluyendo su identificador y estado.
// Proyección: pedido_id y estado (excluyendo el _id interno de Mongo para lectura clara).
// -----------------------------------------------------------------------------
print("--- [CONSULTA a] Todos los pedidos (identificador y estado) ---");
db.pedidos.find(
    {},
    { pedido_id: 1, estado: 1, _id: 0 }
).sort({ pedido_id: 1 }).forEach(doc => {
    printjson(doc);
});

// -----------------------------------------------------------------------------
// Consulta b) Filtrar pedidos por un estado que exista en los datos migrados.
// Estado seleccionado: "ENTREGADO"
// -----------------------------------------------------------------------------
print("\n--- [CONSULTA b] Pedidos con estado 'ENTREGADO' ---");
db.pedidos.find(
    { estado: "ENTREGADO" },
    { pedido_id: 1, estado: 1, fecha: 1, total: 1, _id: 0 }
).sort({ pedido_id: 1 }).forEach(doc => {
    printjson(doc);
});

// -----------------------------------------------------------------------------
// Consulta c) Buscar pedidos que contengan un producto determinado dentro
// del arreglo de líneas (detalles).
// Producto seleccionado: producto_id = 1 ("Pizza Muzzarella")
// Uso del operador de proyección $ para retornar únicamente la línea coincidente.
// -----------------------------------------------------------------------------
print("\n--- [CONSULTA c] Pedidos que contienen el producto_id = 1 (Pizza Muzzarella) ---");
db.pedidos.find(
    { "detalles.producto_id": 1 },
    { pedido_id: 1, estado: 1, "detalles.$": 1, total: 1, _id: 0 }
).sort({ pedido_id: 1 }).forEach(doc => {
    printjson(doc);
});

// -----------------------------------------------------------------------------
// Consulta d) Buscar pedidos cuyo total sea superior a un importe elegido y justificar el umbral.
// Umbral seleccionado: total > 5000.00
// Justificación técnica: Permite aislar compras de volumen elevado o pedidos
// corporativos / eventos, diferenciándolos del consumo minorista promedio ($1000 - $3000).
// -----------------------------------------------------------------------------
print("\n--- [CONSULTA d] Pedidos cuyo total es mayor a $5.000,00 ---");
db.pedidos.find(
    { total: { $gt: 5000 } },
    { pedido_id: 1, estado: 1, total: 1, "cliente.nombre": 1, _id: 0 }
).sort({ total: -1 }).forEach(doc => {
    printjson(doc);
});

print("\n=====================================================================");
print("                    FIN DE CONSULTAS MONGODB                         ");
print("=====================================================================");
