# spec: vista_pedidos_con_cliente_seguro

Objetivo: simplificar reporte de pedidos con datos del cliente, aplicando criterio de seguridad: exponer cliente sin columna sensible.

Contexto del modelo: en este esquema la tabla es cliente(id, nombre, email, created_at) en lugar de usuario(id, nombre, email, contrasena). La columna sensible es email (dato personal). La vista debe ocultar email para permitir GRANT SELECT sin exponer PII, simulando el requisito "usuario sin contrasena" del PDF.

Definición requerida:
- Tablas base: pedido p JOIN cliente cl ON cl.id = p.cliente_id
- Columnas a exponer: p.id AS pedido_id, p.fecha, p.forma_pago, p.cliente_id, cl.nombre AS cliente_nombre, cl.created_at -- EXCLUIR cl.email
- Filtro: ninguno (todos los pedidos), o opcional p.fecha <= NOW() (ya garantizado por CHECK)
- Seguridad: NO incluir cl.email ni cualquier columna de autenticación. De este modo se puede otorgar SELECT sobre la vista a rol reporting sin dar SELECT sobre cliente.

Criterio de aceptación:
- Equivalencia: SELECT * FROM v_pedidos_con_cliente debe coincidir con query manual (mismas filas, sin email).
  Verificación:
  ```sql
  (SELECT pedido_id, fecha, forma_pago, cliente_id, cliente_nombre FROM v_pedidos_con_cliente)
  EXCEPT
  (SELECT p.id, p.fecha, p.forma_pago, p.cliente_id, cl.nombre FROM pedido p JOIN cliente cl ON cl.id=p.cliente_id)
  -- debe dar 0 filas
  ```
- Intento de SELECT email desde la vista debe fallar (columna no existe) -> demuestra ocultamiento.
- Documentar GRANT ejemplo: GRANT SELECT ON v_pedidos_con_cliente TO rol_reportes;

Uso esperado: reporte de pedidos para atención al cliente, auditoría, sin exponer emails.
