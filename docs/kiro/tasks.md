# Plan de Tareas (Kiro) — Unidad 8: Base Móvil y Sincronización

---

### Lista de Tareas para la Implementación

- [x] **TASK-01: Esquema DDL en SQLite (`movil/schema_sqlite.sql`)**
  - Activar `PRAGMA foreign_keys = ON;`.
  - Crear tablas `producto_cache`, `pedido_borrador`, `item_borrador` y `cola_sync` con tipado `STRICT`.
  - Configurar restricciones `CHECK` para enteros no negativos en precios/cantidades, booleanos discretos (0/1), formas de pago permitidas y estados de sincronización.

- [x] **TASK-02: Pruebas locales en la Tablet (`movil/pruebas_sqlite.sql`)**
  - Probar creación de borrador en bloque atómico con `BEGIN ... COMMIT`.
  - Probar anulación de borrador con `ROLLBACK`.
  - Validar Caso C1: consulta offline del catálogo y cálculo de subtotales.
  - Validar Caso C7: violación de integridad (`cantidad = 0` y `producto_id` inexistente).

- [x] **TASK-03: Exportación de Instantánea del Servidor (`servidor_snapshot.csv`)**
  - Definir la vista `v_snapshot_movil` en PostgreSQL con columnas necesarias y conversión a centavos enteros.
  - Generar el archivo CSV `movil/servidor_snapshot.csv`.
  - Crear tabla transitoria `snapshot_servidor` en SQLite para recibir la importación.

- [x] **TASK-04: Algoritmo del Semáforo (`movil/semaforo.sql`)**
  - Desarrollar la consulta SQL de evaluación de solicitudes en estado `PENDIENTE`.
  - Evaluar quiebres de stock, bajas lógicas y productos faltantes $\rightarrow$ `RECHAZADO`.
  - Evaluar diferencias de precio $\rightarrow$ `CONFLICTO`.
  - Evaluar coincidencia total $\rightarrow$ `SIMULADO_APROBADO`.

- [x] **TASK-05: Ejecución y Evidencia de Casos de Sincronización**
  - Simular Caso C2: Conflicto de precio $\rightarrow$ aceptación de nuevo precio $\rightarrow$ aprobación.
  - Simular Caso C3: Quiebre de stock $\rightarrow$ `RECHAZADO`.
  - Simular Caso C4: Baja lógica de producto $\rightarrow$ `RECHAZADO`.
  - Simular Caso C5: Solicitud idéntica $\rightarrow$ `SIMULADO_APROBADO`.
  - Simular Caso C6: Reenvío con mismo UUID $\rightarrow$ rechazo por PK e idempotencia.
  - Comprobar que PostgreSQL no sufrió ninguna mutación de stock ni pedidos.

- [x] **TASK-06: Integración y Cierre de Capa de Datos**
  - Redactar mapa comparativo de los tres motores (PostgreSQL, MongoDB, SQLite).
  - Redactar adición al plan de mantenimiento (manejo de tablets ante restauración de backups).
  - Ejecutar Code Review con IA sobre los scripts de la cursada, documentando al menos 3 hallazgos desarrollados y 1 descarte fundamentado.

- [x] **TASK-07: Informe Técnico, Bitácora y DUIA**
  - Elaborar el informe final en formato markdown (`docs/informe_unidad8.md`) y compilar PDF.
  - Completar `docs/bitacora_ia.md` y `docs/DUIA.md`.
