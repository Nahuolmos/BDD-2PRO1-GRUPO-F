# spec: transacciones_concurrencia

Objetivo: cumplir Objetivo 8 TPI (transacciones: atomicidad, COMMIT/ROLLBACK, niveles de aislamiento y concurrencia).

Qué se necesita:
- Ejemplo de atomicidad: transacción que inserta pedido + detalles y hace ROLLBACK si falla trigger/stock
- Ejemplo de COMMIT exitoso
- Ejemplo de niveles de aislamiento: READ COMMITTED vs REPEATABLE READ con 2 sesiones concurrentes (anomalía lectura no repetible / phantom)

Criterio: scripts verificables con BEGIN/COMMIT/ROLLBACK y comentarios de qué debe pasar en cada sesión.

Nota: se complementa con `informe_concurrencia.md` existente, pero aquí va el .sql ejecutable.
