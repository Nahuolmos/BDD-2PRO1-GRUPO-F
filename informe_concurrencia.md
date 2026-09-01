# Informe de Concurrencia - Laboratorio TPI

## Escenario 1: Espera por bloqueo (Lock Wait)

* **Cómo se reprodujo:**
  * **Sesión A:** 
    ```sql
    BEGIN;
    SELECT * FROM producto WHERE id = 1 FOR UPDATE;
    -- (Transacción mantenida abierta sin hacer commit)
    ```
  * **Sesión B:** 
    ```sql
    BEGIN;
    SELECT * FROM producto WHERE id = 1 FOR UPDATE;
    -- (La sesión queda en espera bloqueada)
    ```
  * **Desenlace:** Al ejecutar `COMMIT;` en la Sesión A, la Sesión B se destrabó automáticamente y completó su ejecución.

* **Explicación técnica:** 
  El modificador `FOR UPDATE` adquiere un bloqueo exclusivo de fila (*RowExclusiveLock* / bloqueo de escritura). La Sesión A retiene el bloqueo al iniciar una transacción activa. Cuando la Sesión B intenta solicitar el mismo bloqueo sobre la misma fila, el motor de PostgreSQL la suspende (la pone en espera) de manera transparente hasta que la transacción propietaria del bloqueo finaliza (`COMMIT` o `ROLLBACK`).

* **Verificación en el motor:** 
  El comportamiento se confirmó de forma exacta en el motor real: la segunda sesión frenó su ejecución hasta recibir la señal de liberación del bloqueo por parte de la primera sesión.

----------------------------------------------------------------------------------------------------------------------------

## Escenario 2: Lectura no repetible (Non-Repeatable Read)

* **Cómo se reprodujo:**
  * **Sesión A:** 
    ```sql
    BEGIN;
    SELECT precio_actual FROM producto WHERE id = 1; -- (Lectura inicial del valor)
    ```
  * **Sesión B:** 
    ```sql
    -- En la otra sesión concurrente:
    UPDATE producto SET precio_actual = 1200.00 WHERE id = 1;
    COMMIT;
    ```
  * **Sesión A (Continuación):** 
    ```sql
    SELECT precio_actual FROM producto WHERE id = 1; -- (Segunda lectura)
    COMMIT;
    ```
  * **Desenlace:** La Sesión A obtuvo dos valores diferentes para la misma fila y la misma columna dentro de su propia transacción.

* **Explicación técnica:** 
  Bajo el nivel de aislamiento estándar de PostgreSQL (*Read Committed*), cada instrucción SQL dentro de una transacción ve una vista de los datos actualizada al inicio de esa instrucción específica. Si otra transacción altera los datos y hace `COMMIT` entre la primera y la segunda lectura, la transacción actual reflejará los cambios de la otra, perdiendo la repetibilidad de la lectura.

* **Verificación en el motor:** 
  Se comprobó la ocurrencia de la anomalía en el motor, confirmando que el aislamiento *Read Committed* no aísla las consultas de lecturas sucesivas frente a transacciones concurrentes ya confirmadas.

----------------------------------------------------------------------------------------------------------------------------

## Escenario 3: Lectura fantasma (Phantom Read / Inserción concurrente)

* **Cómo se reprodujo:**
  * **Sesión A:** 
    ```sql
    BEGIN;
    SELECT COUNT(*) FROM producto WHERE categoria_id = 1; -- (Conteo inicial)
    ```
  * **Sesión B:** 
    ```sql
    -- En la otra sesión concurrente:
    INSERT INTO producto (nombre, precio_actual, stock, activo, categoria_id) 
    VALUES ('Pizza Speciale', 1400.00, 10, TRUE, 1);
    COMMIT;
    ```
  * **Sesión A (Continuación):** 
    ```sql
    SELECT COUNT(*) FROM producto WHERE categoria_id = 1; -- (Segundo conteo)
    COMMIT;
    ```
  * **Desenlace:** El segundo conteo de la Sesión A arrojó una fila más que el primero debido a la inserción y confirmación realizada por la Sesión B.

* **Explicación técnica:** 
  Bajo el nivel de aislamiento por defecto (*Read Committed*), una transacción puede ver la aparición de nuevas filas ("fantasmas") si otra transacción inserta registros que coinciden con el criterio de búsqueda y hace `COMMIT` mientras la primera sigue activa.

* **Verificación en el motor:** 
  Se comprobó que las filas nuevas insertadas externamente alteran los resultados agregados (`COUNT`, `SUM`) o de filtrado en consultas repetidas dentro de la misma transacción.