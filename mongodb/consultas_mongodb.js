// =============================================================================
// TP Unidad 7 - Consultas en MongoDB (mongosh)
// Base de datos: food_store
// Colección: pedidos
// =============================================================================

db = db.getSiblingDB("food_store");

// -----------------------------------------------------------------------------
// Consulta a) Mostrar todos los pedidos, incluyendo su identificador y estado.
// -----------------------------------------------------------------------------
print("\n=== CONSULTA a) Todos los pedidos (identificador y estado) ===");
db.pedidos.find(
    {},
    { pedido_id: 1, estado: 1, _id: 0 }
).sort({ pedido_id: 1 });

// -----------------------------------------------------------------------------
// Consulta b) Filtrar pedidos por un estado que exista en los datos migrados.
// Estado elegido: "ENTREGADO" (se verificó que existe al menos un pedido con
// este estado tras la migración).
// -----------------------------------------------------------------------------
print("\n=== CONSULTA b) Pedidos con estado ENTREGADO ===");
db.pedidos.find(
    { estado: "ENTREGADO" },
    { pedido_id: 1, estado: 1, fecha: 1, total: 1, _id: 0 }
).sort({ fecha: -1 });

// -----------------------------------------------------------------------------
// Consulta c) Buscar pedidos que contengan un producto determinado dentro
// del arreglo de líneas (detalles).
// Producto elegido: producto_id = 50001 (Pizza Muzzarilla, existe en los datos).
// -----------------------------------------------------------------------------
print("\n=== CONSULTA c) Pedidos que contienen producto_id 50001 ===");
db.pedidos.find(
    { "detalles.producto_id": 50001 },
    { pedido_id: 1, estado: 1, "detalles.$": 1, total: 1, _id: 0 }
).sort({ pedido_id: 1 });

// -----------------------------------------------------------------------------
// Consulta d) Buscar pedidos cuyo total sea superior a un importe elegido.
// Umbral: 5000.00 (justificación: es un monto significativo que filtra pedidos
// de mayor valor, permitiendo identificar compras al por mayor o clientes VIP;
// con 5 pedidos migrados es esperable que al menos uno supere este umbral).
// -----------------------------------------------------------------------------
print("\n=== CONSULTA d) Pedidos con total > 5000.00 ===");
db.pedidos.find(
    { total: { $gt: 5000 } },
    { pedido_id: 1, estado: 1, total: 1, "cliente.nombre": 1, _id: 0 }
).sort({ total: -1 });

// =============================================================================
// Fin de consultas_mongodb.js
// =============================================================================