# Especificación de Requisitos (Kiro) — Unidad 8: Base Móvil y Sincronización
## Proyecto Food Store · Móvil en la feria

Los requisitos siguen la notación formal **EARS** (Easy Approach to Requirements Syntax) y están vinculados a sus respectivos casos de prueba de verificación.

---

### Requisitos Funcionales en Notación EARS

* **REQ-01 (Detección de Conflicto de Precios — Event-driven):**  
  **WHEN** el precio actual en centavos del servidor (`s.precio_centavos`) es distinto del precio visto registrado en el borrador (`i.precio_centavos_visto`),  
  **THE SYSTEM SHALL** marcar el estado de la solicitud en `cola_sync` como `'CONFLICTO'` con el detalle de la variación de importe.  
  *Caso de prueba:* **C2**.

* **REQ-02 (Rechazo por Quiebre de Stock — Unwanted behavior):**  
  **IF** la cantidad solicitada de cualquier producto en el borrador (`i.cantidad`) supera el stock disponible en el servidor (`s.stock`),  
  **THEN THE SYSTEM SHALL** marcar el estado de la solicitud en `cola_sync` como `'RECHAZADO'` con el motivo `'Stock insuficiente'`.  
  *Caso de prueba:* **C3**.

* **REQ-03 (Rechazo por Producto Inexistente o Dado de Baja — Unwanted behavior):**  
  **IF** un ítem del borrador referencia a un producto que no existe en el servidor, no está disponible (`s.disponible = 0` o `'f'`) o fue dado de baja lógica (`s.eliminado = 1` o `'t'`),  
  **THEN THE SYSTEM SHALL** marcar el estado de la solicitud en `cola_sync` como `'RECHAZADO'` indicando el motivo correspondiente.  
  *Caso de prueba:* **C4**.

* **REQ-04 (Aprobación Simulada de Solicitud Válida — State-driven):**  
  **WHILE** una solicitud se encuentra en estado `'PENDIENTE'`, si todos sus ítems existen, están disponibles, no fueron eliminados, cuentan con stock suficiente y coinciden en precio,  
  **THE SYSTEM SHALL** actualizar el estado de la solicitud a `'SIMULADO_APROBADO'`.  
  *Caso de prueba:* **C5**.

* **REQ-05 (Idempotencia y Unicidad de Solicitudes — Unwanted behavior):**  
  **IF** se intenta insertar o procesar nuevamente una solicitud con un `solicitud_uuid` ya existente en `cola_sync`,  
  **THEN THE SYSTEM SHALL** rechazar la inserción por violación de clave primaria e impedir la reevaluación repetida de la transacción.  
  *Caso de prueba:* **C6**.

* **REQ-06 (Consulta Offline de Catálogo — Ubiquitous):**  
  **THE SYSTEM SHALL** permitir la lectura completa del catálogo de productos disponibles y el cálculo local de subtotales desde la caché SQLite sin requerir conexión de red con el servidor PostgreSQL.  
  *Caso de prueba:* **C1**.

* **REQ-07 (Integridad Restrictiva en la Tablet — Unwanted behavior):**  
  **IF** se intenta registrar un ítem con cantidad menor o igual a cero (`cantidad <= 0`) o con un `producto_id` no registrado en `producto_cache`,  
  **THEN THE SYSTEM SHALL** abortar la operación por violación de restricción `CHECK` o clave foránea `FOREIGN KEY`.  
  *Caso de prueba:* **C7**.
