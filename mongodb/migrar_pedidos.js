// =============================================================================
// TP Unidad 7 - Migración e inserción de 5 pedidos en MongoDB (mongosh)
// Base de datos: food_store
// Colección: pedidos
// =============================================================================

db = db.getSiblingDB("food_store");

// 1. Limpieza preventiva de la colección
db.pedidos.drop();

// 2. Inserción de los 5 pedidos con datos embebidos (insertMany)
const resultado = db.pedidos.insertMany([
  {
    pedido_id: 1,
    fecha: ISODate("2026-03-15T19:30:00Z"),
    estado: "ENTREGADO",
    forma_pago: "EFECTIVO",
    cliente: {
      cliente_id: 1,
      nombre: "Juan Pérez",
      email: "juan.perez@email.com"
    },
    detalles: [
      {
        producto_id: 1,
        producto_nombre: "Pizza Muzzarella",
        cantidad: 2,
        precio_unitario: 1000.00,
        subtotal: 2000.00
      },
      {
        producto_id: 3,
        producto_nombre: "Coca Cola 1.5L",
        cantidad: 2,
        precio_unitario: 450.00,
        subtotal: 900.00
      }
    ],
    total: 2900.00
  },
  {
    pedido_id: 2,
    fecha: ISODate("2026-04-20T21:00:00Z"),
    estado: "ENTREGADO",
    forma_pago: "TARJETA",
    cliente: {
      cliente_id: 2,
      nombre: "María Gómez",
      email: "maria.gomez@email.com"
    },
    detalles: [
      {
        producto_id: 2,
        producto_nombre: "Empanada de Carne",
        cantidad: 12,
        precio_unitario: 150.00,
        subtotal: 1800.00
      }
    ],
    total: 1800.00
  },
  {
    pedido_id: 3,
    fecha: ISODate("2026-08-10T13:15:00Z"),
    estado: "ENVIADO",
    forma_pago: "TRANSFERENCIA",
    cliente: {
      cliente_id: 3,
      nombre: "Carlos López",
      email: "carlos.lopez@email.com"
    },
    detalles: [
      {
        producto_id: 1,
        producto_nombre: "Pizza Muzzarella",
        cantidad: 3,
        precio_unitario: 1050.00,
        subtotal: 3150.00
      },
      {
        producto_id: 3,
        producto_nombre: "Coca Cola 1.5L",
        cantidad: 3,
        precio_unitario: 500.00,
        subtotal: 1500.00
      }
    ],
    total: 4650.00
  },
  {
    pedido_id: 4,
    fecha: ISODate("2026-10-05T20:45:00Z"),
    estado: "ENTREGADO",
    forma_pago: "TARJETA",
    cliente: {
      cliente_id: 1,
      nombre: "Juan Pérez",
      email: "juan.perez@email.com"
    },
    detalles: [
      {
        producto_id: 1,
        producto_nombre: "Pizza Muzzarella",
        cantidad: 4,
        precio_unitario: 1100.00,
        subtotal: 4400.00
      },
      {
        producto_id: 2,
        producto_nombre: "Empanada de Carne",
        cantidad: 12,
        precio_unitario: 160.00,
        subtotal: 1920.00
      }
    ],
    total: 6320.00
  },
  {
    pedido_id: 5,
    fecha: ISODate("2026-11-02T21:30:00Z"),
    estado: "PENDIENTE",
    forma_pago: "EFECTIVO",
    cliente: {
      cliente_id: 2,
      nombre: "María Gómez",
      email: "maria.gomez@email.com"
    },
    detalles: [
      {
        producto_id: 2,
        producto_nombre: "Empanada de Carne",
        cantidad: 6,
        precio_unitario: 160.00,
        subtotal: 960.00
      },
      {
        producto_id: 3,
        producto_nombre: "Coca Cola 1.5L",
        cantidad: 1,
        precio_unitario: 500.00,
        subtotal: 500.00
      }
    ],
    total: 1460.00
  }
]);

print(`Inserción finalizada con éxito.`);
print(`Documentos insertados: ${resultado.insertedCount}`);
print(`Colección 'pedidos' ahora cuenta con ${db.pedidos.countDocuments()} registros.`);
