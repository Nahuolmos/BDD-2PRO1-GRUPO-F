# Food Store · Proyecto Integrador de Base de Datos II
## Capa de Datos Completa: PostgreSQL 16+ (OLTP) · MongoDB (Documental) · SQLite (Móvil Offline)

* **Asignatura:** Bases de Datos II — Tecnicatura Universitaria en Programación (UTN)
* **Equipo de Trabajo:** Grupo F
* **Integrantes:** Ignacio Ariza, Nahuel Olmos, Facundo Cabrera
* **Repositorio:** [https://github.com/Nahuolmos/BDD-2PRO1-GRUPO-F](https://github.com/Nahuolmos/BDD-2PRO1-GRUPO-F)

---

### 1. Estructura del Repositorio

```
BDD-2PRO1-GRUPO-F/
├── README.md                          # Guía de reproducción integral y ensayo de defensa
├── movil/                             # Unidad 8: Base de la tablet y sincronización
│   ├── schema_sqlite.sql              # Esquema DDL en SQLite (modo STRICT, foreign keys)
│   ├── pruebas_sqlite.sql             # Pruebas locales (transacciones, C1 catálogo, C7 restricciones)
│   ├── semaforo.sql                   # Algoritmo de sincronización y semáforo de conflictos
│   ├── servidor_snapshot.csv          # Instantánea exportada del servidor
│   ├── simulador.py                   # Simulador ejecutable de los casos C2 a C6
│   └── foodstore_movil.db             # Base SQLite generada
├── mongodb/                           # Unidad 7: NoSQL Documental
│   ├── modelo_documental.md           # Diseño de la colección 'pedidos' y justificación de embebido
│   ├── migrar_pedidos.sql             # Transformación SQL a JSON para MongoDB
│   ├── migrar_pedidos.js              # Script insertMany() para mongosh
│   ├── consultas_mongodb.js           # Consultas a, b, c, d en mongosh
│   └── datos_pedidos.json             # Dataset de 5 pedidos autocontenidos
├── postgresql/                        # Scripts relacionales de verificación
│   └── consultas_postgresql.sql       # Consultas b y c equivalentes para verificación cruzada
├── sql/                               # Scripts relacionales de Unidades 4, 5 y 6
│   ├── roles.sql                      # Roles y permisos (mínimo privilegio - U5)
│   ├── simulacro_incidente.sql        # Simulacro de escalamiento y auditoría (U5)
│   ├── u7_datos_prueba.sql            # Semilla de datos de 5 pedidos para paridad 1:1
│   └── ...
├── backup_foodstore.sh                # Script de respaldo automatizado (U6)
├── restore_test.sh                    # Script de restauración cronometrada (U6)
├── health_check.sql                   # Monitoreo de salud de base de datos (U6)
├── maintenance.sql                    # Mantenimiento rutinario (VACUUM ANALYZE) (U6)
└── docs/                              # Informes técnicos, Kiro specs y bitácoras
    ├── informe_unidad7.md             # Informe técnico Unidad 7 (NoSQL)
    ├── informe_unidad8.md             # Informe técnico Unidad 8 (TP8 Móvil y Semáforo)
    ├── informe_u6.md                  # Informe de incidente y RTO/RPO Unidad 6
    ├── bitacora_ia.md                 # Bitácora formal de uso de IA (U8)
    ├── DUIA.md                        # Declaración formal obligatoria de uso de IA
    └── kiro/                          # Especificaciones de ingeniería en Kiro
        ├── requirements.md            # Requisitos EARS ligados a casos de prueba
        ├── design.md                  # Documento de diseño arquitectónico
        └── tasks.md                   # Plan de tareas de implementación
```

---

### 2. Orden de Reproducción desde Cero

Para recrear y verificar todo el ecosistema de datos de Food Store en una máquina limpia:

#### Paso 1: Levantar la Base Relacional Central (PostgreSQL 16+)
```bash
# 1. Crear la base de datos
createdb -U postgres food_store

# 2. Cargar esquema base, normalización y datos iniciales
psql -U postgres -d food_store -f schema.sql
psql -U postgres -d food_store -f data.sql
psql -U postgres -d food_store -f soft_delete.sql

# 3. Cargar seguridad, auditoría y datos de paridad
psql -U postgres -d food_store -f sql/roles.sql
psql -U postgres -d food_store -f sql/u7_datos_prueba.sql
```

#### Paso 2: Recrear y Consultar la Base Documental (MongoDB)
```bash
# Importar los 5 pedidos con datos embebidos
mongosh food_store mongodb/migrar_pedidos.js

# Ejecutar las 4 consultas documentales y verificar salidas
mongosh food_store mongodb/consultas_mongodb.js
```

#### Paso 3: Recrear y Probar la Base Móvil Offline (SQLite 3.37+)
```bash
# 1. Crear el esquema STRICT y correr pruebas unitarias locales (C1 y C7)
sqlite3 movil/foodstore_movil.db < movil/schema_sqlite.sql
sqlite3 movil/foodstore_movil.db < movil/pruebas_sqlite.sql

# 2. Ejecutar la simulación completa de sincronización y semáforo (C2 a C6)
python movil/simulador.py
```

---

### 3. Guía para el Ensayo de Defensa (10 minutos)

* **Eje 1 · El Mapa de la Capa de Datos (3 min):**  
  Presentar la coexistencia de los tres motores: **PostgreSQL** como *Single Source of Truth* que custodia el stock y confirma ventas; **MongoDB** como almacén desnormalizado que acelera la lectura atómica de comprobantes; y **SQLite** como cliente *offline-first* que opera en modo STRICT con centavos enteros.
* **Eje 2 · Caso en Vivo del Semáforo (4 min):**  
  Demostrar en vivo el simulador (`python movil/simulador.py` o ejecución SQL). Mostrar cómo el caso **C2** detecta el `CONFLICTO` de precio sin romper el catálogo del servidor, y cómo la idempotencia de **C6** bloquea duplicados mediante clave primaria.
* **Eje 3 · Un Hallazgo Significativo de la IA (3 min):**  
  Explicar el descarte fundamentado de `VACUUM FULL` sugerido por la IA en la Unidad 6 (por bloqueo exclusivo total), o la corrección de tipo `REAL` a `INTEGER` en la Unidad 8 para erradicar errores de precisión de punto flotante en la moneda.
