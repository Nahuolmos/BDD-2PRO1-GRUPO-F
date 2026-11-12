-- TP8 · Consigna 2.c · Verificación final: PostgreSQL no cambió por culpa de la tablet
SELECT
  (SELECT COUNT(*) FROM pedido)                                    AS pedidos,
  (SELECT COUNT(*) FROM detalle_pedido)                            AS detalles,
  (SELECT stock FROM producto WHERE nombre = 'Pizza Muzzarella')   AS stock_pizza,
  (SELECT stock FROM producto WHERE nombre = 'Coca Cola 1.5L')     AS stock_coca,
  (SELECT stock FROM producto WHERE nombre = 'Empanada de Carne')  AS stock_empanada;