# Trabajo Práctico Integrador (TPI) · Segunda Entrega
## Proyecto «Food Store» — Resumen Ejecutivo de la Capa de Datos (Unidades 4 a 8)

* **Asignatura:** Bases de Datos II · Tecnicatura Universitaria en Programación (UTN)
* **Equipo:** Grupo F
* **Integrantes:** Ignacio Ariza, Nahuel Olmos, Facundo Cabrera
* **Repositorio Oficial:** [https://github.com/Nahuolmos/BDD-2PRO1-GRUPO-F](https://github.com/Nahuolmos/BDD-2PRO1-GRUPO-F)
* **Motores Implementados:** PostgreSQL 16+ (Relacional OLTP), MongoDB (Documental NoSQL) y SQLite 3.37+ (Móvil Offline)
* **Fecha de Entrega:** Noviembre 2026

---

## 1. Elementos Implementados por Unidad (Unidades 4 a 8)

### Unidad 4 · Normalización Avanzada y Redundancia
* **Refactorización a FNBC (`tp_fnbc_control_lote.sql`):** Descomposición de dependencias funcionales anómalas en el módulo de lotes y vencimientos, garantizando que todo determinante sea una superclave sin pérdida de información ni dependencias.
* **Desnormalización Controlada (`tp_desnormalizacion_top_categorias.sql`):** Agregación persistida y optimización para reportes analíticos de alta concurrencia, protegida mediante salvaguardas y disparadores de actualización.
* **Borrado Lógico (*Soft Delete* en `soft_delete.sql`):** Incorporación de la columna `eliminado` con índices parciales B-Tree en `producto` y `categoria`, separando la vigencia comercial de la persistencia histórica.

### Unidad 5 · Administración y Seguridad
* **Matriz de Roles y Privilegios (`sql/roles.sql`):** Implementación estricta del principio de mínimo privilegio con 6 roles (`rol_admin_datos`, `rol_operador`, `rol_reportes`, `rol_auditor`, etc.). El rol de reportes accede exclusivamente a vistas sin exposición de PII ni hashes de contraseñas.
* **Auditoría de Accesos y Operaciones (`sql/auditoria_test.sql`):** Configuración de `log_statement = 'mod'` para registrar modificaciones y accesos no autorizados sin saturar el almacenamiento en disco.

### Unidad 6 · Mantenimiento y Continuidad Operativa
* **Plan de Mantenimiento Automatizado (`backup_foodstore.sh` y `maintenance.sql`):** Respaldo diario en formato custom (`pg_dump -F c`), rutinas de actualización de estadísticas (`ANALYZE`) y limpieza de tuplas muertas sin bloqueo concurrente (`VACUUM ANALYZE`).
* **Verificación de Salud (`health_check.sql`):** Monitoreo de conexiones activas, transacciones abiertas y volumen de tablas en disco.

### Unidad 7 · NoSQL y Nuevas Formas de Almacenamiento
* **Modelo Documental (`mongodb/`):** Colección unificada `pedidos` con documentos BSON que embeben la cabecera, datos esenciales del cliente y un arreglo de subdocumentos con los ítems y precios históricos inmutables.
* **Migración y Consultas (`consultas_mongodb.js` y `consultas_postgresql.sql`):** Migración con `insertMany()` y validación cruzada con paridad 100% en identificadores y subtotales.

### Unidad 8 · Bases de Datos Móviles e Integración
* **Base Local en la Tablet (`movil/schema_sqlite.sql`):** SQLite 3.37+ en modo `STRICT`, claves foráneas activas y precios en enteros de centavos (`INTEGER`).
* **Sincronización Asíncrona con Semáforo (`movil/semaforo.sql`):** Detección automática de quiebres de stock y bajas lógicas (🔴 `RECHAZADO`), desfasajes de precio (🟡 `CONFLICTO`) y solicitudes validadas (🟢 `SIMULADO_APROBADO`), asegurando idempotencia mediante clave primaria UUID.

---

## 2. Metodología de Pruebas y Evidencias de Funcionamiento

| Unidad | Mecanismo de Prueba Aplicado | Caso / Escenario Simulado | Evidencia de Resultado |
| :---: | :--- | :--- | :--- |
| **U4** | **Transacciones Reversibles** | Migración de datos dentro de bloques `BEGIN ... ROLLBACK` y plan de reversión. | Migración validada con `EXCEPT = 0` filas y reversibilidad demostrada. |
| **U5** | **Simulacro de Acceso Indebido** | Intento de escalamiento de privilegios y lectura masiva desde `rol_reportes`. | Bloqueo exitoso (`permission denied`), trazabilidad reconstruida en log de auditoría. |
| **U6** | **Simulacro de Desastre Contra Reloj** | Destrucción de base y restauración completa desde el último archivo `.dump`. | **RTO observado: 1,5 segundos.** Integridad 100% verificada (`detalles_invalidos = 0`). |
| **U7** | **Verificación Cruzada Bimodal** | Comparación de consultas analíticas (estado ENTREGADO y producto 1). | **Paridad 1:1 absoluta:** Mismos 3 IDs recuperados en ambos motores (`[1, 2, 4]` y `[1, 3, 4]`). |
| **U8** | **Casos de Conflicto de Sincronización** | Simulación de casos C2 a C6 (cambio de precios, falta de stock, baja lógica, reenvío). | Semáforo clasificó con exactitud. Idempotencia bloqueó duplicados por PK. **PostgreSQL intacto.** |

---

## 3. Decisiones de Diseño Clave y Justificación Técnica

1. **Refactorización FNBC vs Desnormalización Controlada (U4):**  
   Se llevó el catálogo transaccional a la Forma Normal de Boyce-Codd para evitar anomalías de inserción y borrado. Paralelamente, se aplicó desnormalización controlada exclusivamente en la tabla de categorías top para reportes analíticos, blindada con triggers de consistencia.
2. **Defensa en Profundidad y Mínimo Privilegio (U5):**  
   Se prohibió el uso del superusuario en la aplicación. Ningún rol de reportería tiene acceso de lectura a contraseñas hasheadas ni datos de contacto sensibles, mitigando riesgos de fuga de información.
3. **Persistencia Políglota / Arquitectura Híbrida (U7):**  
   PostgreSQL actúa como el núcleo transaccional ACID de inventario y facturación real. MongoDB se utiliza como almacén de lectura optimizada para comprobantes completos, eliminando 3 JOINs costosos en lecturas masivas frecuentes.
4. **Regla de Oro en Móvil: "El móvil propone, el servidor dispone" (U8):**  
   La tablet nunca decrementa stock ni confirma ventas reales en PostgreSQL. Opera con una instantánea desacoplada y enteros en centavos, resolviendo discrepancias mediante el semáforo al reconectarse.

---

## 4. Gobernanza del Uso de Inteligencia Artificial (Bitácora y DUIA)

* **Protocolo de IA aplicado:** Ningún script propuesto por IA se aceptó sin lectura crítica, validación de sintaxis y ejecución controlada en entornos de laboratorio aislados.
* **Casos de Descarte y Corrección Humana Más Significativos:**
  * **U5 (`roles.sql`):** La IA propuso `GRANT ALL` a `rol_reportes`. **Corregido:** Se limitó a `GRANT SELECT` en vistas para no violar mínimo privilegio.
  * **U6 (`maintenance.sql`):** La IA propuso `VACUUM FULL;` periódico. **Descartado con fundamento:** Se rechazó debido a que adquiere un bloqueo exclusivo total (`AccessExclusiveLock`) que congela la base en producción.
  * **U8 (`schema_sqlite.sql`):** La IA propuso usar `REAL` para moneda. **Corregido:** Se forzó el uso de `INTEGER` en centavos para eliminar errores de redondeo IEEE 754.
