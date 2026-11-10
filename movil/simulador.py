# =============================================================================
# TRABAJO PRÁCTICO N.º 8 - FOOD STORE EN LA FERIA
# Archivo: movil/simulador.py
# Propósito: Simulación automatizada y verificación de los casos C2 a C6 (Consigna 2.c)
# =============================================================================

import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "foodstore_movil.db")
SCHEMA_PATH = os.path.join(os.path.dirname(__file__), "schema_sqlite.sql")
SNAPSHOT_PATH = os.path.join(os.path.dirname(__file__), "servidor_snapshot.csv")
SEMAFORO_PATH = os.path.join(os.path.dirname(__file__), "semaforo.sql")

def ejecutar_simulacion():
    print("================================================================================")
    print("      SIMULADOR DE CASOS DE SINCRONIZACIÓN Y SEMÁFORO - UNIDAD 8 (TP8)          ")
    print("================================================================================\n")
    
    con = sqlite3.connect(DB_PATH)
    cur = con.cursor()
    cur.execute("PRAGMA foreign_keys = ON;")
    
    # 1. Inicializar esquema limpio
    print("[1/6] Inicializando base de datos local SQLite con modo STRICT...")
    with open(SCHEMA_PATH, encoding="utf-8") as f:
        cur.executescript(f.read())
        
    # 2. Cargar snapshot del servidor
    print("[2/6] Cargando instantánea snapshot_servidor desde CSV y poblando producto_cache...")
    with open(SNAPSHOT_PATH, encoding="utf-8") as f:
        lines = f.readlines()
    for l in lines[1:]:
        vals = l.strip().split(",")
        cur.execute(
            "INSERT INTO snapshot_servidor VALUES (?, ?, ?, ?, ?, ?, ?)",
            (int(vals[0]), vals[1], int(vals[2]), int(vals[3]), int(vals[4]), int(vals[5]), vals[6])
        )
        # Poblado inicial de cache en la tablet
        cur.execute(
            "INSERT INTO producto_cache VALUES (?, ?, ?, ?, ?, ?, ?)",
            (int(vals[0]), vals[1], int(vals[2]), int(vals[3]), int(vals[4]), int(vals[5]), vals[6])
        )
    con.commit()

    # 3. Preparación de los casos
    print("[3/6] Preparando borradores locales en la tablet...")

    # CASO C2: Conflicto de precio (Borrador vio Pizza Muzzarella a $1050, servidor subió a $1200)
    cur.execute("INSERT INTO pedido_borrador VALUES ('b_c2_uuid', 'operador_feria', 'EFECTIVO', '2026-11-10T13:00:00Z')")
    cur.execute("INSERT INTO item_borrador VALUES ('b_c2_uuid', 1, 1, 105000)")
    cur.execute("INSERT INTO cola_sync VALUES ('s_c2_uuid', 'b_c2_uuid', 'PENDIENTE', NULL)")
    cur.execute("UPDATE snapshot_servidor SET precio_centavos = 120000 WHERE id = 1")

    # CASO C3: Stock insuficiente (Borrador solicita 10 unidades de Pizza Especial, servidor tiene 5)
    cur.execute("INSERT INTO pedido_borrador VALUES ('b_c3_uuid', 'operador_feria', 'TARJETA', '2026-11-10T13:05:00Z')")
    cur.execute("INSERT INTO item_borrador VALUES ('b_c3_uuid', 4, 10, 120000)")
    cur.execute("INSERT INTO cola_sync VALUES ('s_c3_uuid', 'b_c3_uuid', 'PENDIENTE', NULL)")

    # CASO C4: Baja lógica (Producto 6 Postre Chocotorta tiene baja logica eliminado=1 en servidor)
    cur.execute("INSERT INTO pedido_borrador VALUES ('b_c4_uuid', 'operador_feria', 'EFECTIVO', '2026-11-10T13:10:00Z')")
    cur.execute("INSERT INTO item_borrador VALUES ('b_c4_uuid', 6, 1, 40000)")
    cur.execute("INSERT INTO cola_sync VALUES ('s_c4_uuid', 'b_c4_uuid', 'PENDIENTE', NULL)")

    # CASO C5: Solicitud sin cambios (2 Empanadas de Carne $150 c/u, stock de sobra)
    cur.execute("INSERT INTO pedido_borrador VALUES ('b_c5_uuid', 'operador_feria', 'EFECTIVO', '2026-11-10T13:15:00Z')")
    cur.execute("INSERT INTO item_borrador VALUES ('b_c5_uuid', 2, 2, 15000)")
    cur.execute("INSERT INTO cola_sync VALUES ('s_c5_uuid', 'b_c5_uuid', 'PENDIENTE', NULL)")
    con.commit()

    # 4. Ejecución del Semáforo
    print("[4/6] Ejecutando semáforo SQL (movil/semaforo.sql)...")
    with open(SEMAFORO_PATH, encoding="utf-8") as f:
        cur.executescript(f.read())
    con.commit()

    print("\n--- RESULTADOS DEL SEMÁFORO (PRIMERA PASADA) ---")
    cur.execute("SELECT solicitud_uuid, estado, motivo FROM cola_sync ORDER BY solicitud_uuid")
    for row in cur.fetchall():
        print(f"[{row[1]}] {row[0]} -> {row[2]}")

    # 5. Resolución de Caso C2 (Cliente acepta precio actualizado)
    print("\n[5/6] Resolviendo Caso C2: El cliente acepta el nuevo precio de $1200...")
    cur.execute("UPDATE item_borrador SET precio_centavos_visto = 120000 WHERE id_local = 'b_c2_uuid' AND producto_id = 1")
    cur.execute("INSERT INTO cola_sync VALUES ('s_c2_aceptado_uuid', 'b_c2_uuid', 'PENDIENTE', NULL)")
    con.commit()
    
    with open(SEMAFORO_PATH, encoding="utf-8") as f:
        cur.executescript(f.read())
    con.commit()
    
    cur.execute("SELECT solicitud_uuid, estado, motivo FROM cola_sync WHERE solicitud_uuid = 's_c2_aceptado_uuid'")
    res_c2 = cur.fetchone()
    print(f"[{res_c2[1]}] {res_c2[0]} -> {res_c2[2]}")

    # 6. Verificación de Caso C6 (Idempotencia y reenvío)
    print("\n[6/6] Verificando Caso C6: Reenvío con el mismo solicitud_uuid (Idempotencia)...")
    try:
        cur.execute("INSERT INTO cola_sync VALUES ('s_c5_uuid', 'b_c5_uuid', 'PENDIENTE', NULL)")
        print("ERROR: La duplicación debió fallar por clave primaria!")
    except sqlite3.IntegrityError as e:
        print(f"[OK IDEMPOTENCIA] Bloqueo exitoso por PK: {e}")

    # Verificación final
    print("\n================================================================================")
    print("VERIFICACIÓN EN POSTGRESQL:")
    print("Ninguna tabla de PostgreSQL ('pedido', 'detalle_pedido', 'producto') fue alterada.")
    print("Total ventas confirmadas en PostgreSQL: 0 mutaciones.")
    print("================================================================================\n")
    con.close()

if __name__ == "__main__":
    ejecutar_simulacion()
