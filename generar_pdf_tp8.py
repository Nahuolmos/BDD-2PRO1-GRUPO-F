# =============================================================================
# Generador de PDF para Informe Técnico - TP8 (Unidad 8)
# Archivo: generar_pdf_tp8.py
# Motor: Python 3 con fpdf2
# =============================================================================

from fpdf import FPDF
from fpdf.enums import XPos, YPos
import os

class StyledPDF(FPDF):
    def header(self):
        self.set_font('Helvetica', 'B', 8)
        self.set_text_color(100, 110, 120)
        self.cell(0, 6, 'FOOD STORE · TRABAJO PRÁCTICO N.º 8 | UNIDAD 8 (UTN - BDII)', border='B', align='L')
        self.ln(8)

    def footer(self):
        self.set_y(-12)
        self.set_font('Helvetica', 'I', 8)
        self.set_text_color(120, 120, 120)
        self.cell(0, 8, f'Página {self.page_no()} de {{nb}}  —  Grupo F (Ignacio Ariza, Nahuel Olmos, Facundo Cabrera)', align='C')

    def chapter_title(self, title):
        self.set_font('Helvetica', 'B', 12)
        self.set_text_color(24, 43, 73)
        self.cell(0, 7, title, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_draw_color(200, 210, 220)
        self.line(self.get_x(), self.get_y(), self.get_x() + 190, self.get_y())
        self.ln(3)

    def section_title(self, title):
        self.set_font('Helvetica', 'B', 10)
        self.set_text_color(40, 60, 90)
        self.cell(0, 6, title, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(1)

    def body_p(self, text):
        self.set_font('Helvetica', '', 8.5)
        self.set_text_color(30, 30, 30)
        self.multi_cell(0, 4.5, text)
        self.ln(2)

    def code_box(self, code_text):
        self.set_font('Courier', '', 7.5)
        self.set_fill_color(245, 247, 250)
        self.set_draw_color(215, 225, 235)
        self.set_text_color(30, 40, 50)
        self.multi_cell(0, 3.8, code_text, border=1, fill=True)
        self.ln(2)

def build_tp8_pdf():
    pdf = StyledPDF(orientation='P', unit='mm', format='A4')
    pdf.set_margins(12, 12, 12)
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.alias_nb_pages()
    pdf.add_page()

    # Título Principal
    pdf.set_font('Helvetica', 'B', 15)
    pdf.set_text_color(20, 35, 60)
    pdf.cell(0, 8, 'Trabajo Práctico N.º 8: Base Móvil y Cierre de Capa de Datos', align='C', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font('Helvetica', 'I', 9)
    pdf.set_text_color(80, 90, 100)
    pdf.cell(0, 5, 'Food Store en la feria: La base de la tablet y el semáforo de sincronización', align='C', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(2)

    # Cuadro de identificación
    pdf.set_font('Helvetica', '', 8)
    pdf.set_fill_color(240, 244, 248)
    info_text = (
        "Asignatura: Bases de Datos II · Tecnicatura Universitaria en Programación (UTN)\n"
        "Equipo: Grupo F  |  Integrantes: Ignacio Ariza, Nahuel Olmos, Facundo Cabrera\n"
        "Repositorio: https://github.com/Nahuolmos/BDD-2PRO1-GRUPO-F  |  Herramientas: PostgreSQL 16+, SQLite 3.37+, Kiro"
    )
    pdf.multi_cell(0, 4, info_text, border=1, fill=True)
    pdf.ln(3)

    # 1.a Qué datos viajan
    pdf.chapter_title('1. La Base de la Tablet y Distribución de Datos (Consigna 1.a)')
    pdf.body_p(
        "El food truck opera en una feria sin señal de red garantizada. Para brindar servicio continuo se aplica una "
        "arquitectura offline-first en SQLite. Por seguridad física del dispositivo y privacidad de clientes, solo viaja una "
        "proyección de lectura del catálogo. La regla de oro es: 'El móvil propone, el servidor dispone'. PostgreSQL es la única "
        "fuente de verdad (Single Source of Truth) y la tablet nunca altera stock ni precios directamente."
    )

    # Tabla 1.a
    pdf.section_title('Tabla de distribución de columnas (Viajan vs No viajan a la Tablet)')
    with pdf.table(col_widths=(35, 20, 35, 100), borders_layout="ALL") as table:
        row = table.row()
        row.cell('Columna / Entidad')
        row.cell('¿Viaja?')
        row.cell('Destino SQLite')
        row.cell('Justificación Técnica y de Seguridad')
        
        datos = [
            ('producto.id', 'SÍ', 'producto_cache.id', 'ID unívoco para referenciar los ítems del borrador.'),
            ('producto.nombre', 'SÍ', 'producto_cache.nombre', 'Denominación para visualización en pantalla del cajero.'),
            ('producto.precio_actual', 'SÍ', 'producto_cache.precio_centavos', 'Entero en centavos para evitar imprecisión IEEE 754 de REAL.'),
            ('producto.stock', 'SÍ', 'producto_cache.stock_visto', 'Stock estimado de la última copia para alertar faltantes.'),
            ('producto.activo / elim.', 'SÍ', 'disponible / eliminado', 'Banderas 0/1 para catálogo vigente y lápidas (tombstones).'),
            ('cliente (PII)', 'NO', '—', 'Privacidad estricta: No exponer datos de clientes en dispositivos móviles.'),
            ('usuario (contraseñas)', 'NO', '—', 'Seguridad crítica: Proteger credenciales ante extravío/robo de tablet.'),
            ('auditoria_operaciones', 'NO', '—', 'Los registros de auditoría y seguridad residen solo en PostgreSQL.')
        ]
        for col, viaja, dest, just in datos:
            r = table.row()
            r.cell(col)
            r.cell(viaja)
            r.cell(dest)
            r.cell(just)
    pdf.ln(4)

    # 2.c Casos de sincronización y semáforo
    pdf.chapter_title('2. Sincronización y Simulación del Semáforo (Consigna 2.c)')
    pdf.body_p(
        "El semáforo (movil/semaforo.sql) clasifica solicitudes PENDIENTE contra la instantánea del servidor:\n"
        "• Rojo (RECHAZADO): Producto inexistente, baja lógica, no disponible o stock insuficiente.\n"
        "• Amarillo (CONFLICTO): Producto disponible, pero cambió su precio en el catálogo del servidor.\n"
        "• Verde (SIMULADO_APROBADO): Coincidencia total en precio, disponibilidad y stock."
    )

    pdf.section_title('Evidencias de los Casos de Prueba (C2 a C6)')
    casos = [
        ("Caso C2 · Conflicto de precio:",
         "Borrador b_c2 vio Pizza a $1050 (105000 centavos); servidor subió precio a $1200.\n"
         "Resultado: [CONFLICTO] s_c2 -> Variación de precio detectada.\n"
         "Resolución: Cliente acepta precio -> se actualiza borrador a 120000 centavos -> [SIMULADO_APROBADO] s_c2_aceptado."),
        ("Caso C3 · Quiebre de stock en el servidor:",
         "Borrador b_c3 solicita 10 unidades de Pizza Especial (id 4), servidor solo posee 5 en stock.\n"
         "Resultado: [RECHAZADO] s_c3 -> Stock insuficiente en servidor para la cantidad solicitada."),
        ("Caso C4 · Producto dado de baja lógica en el servidor:",
         "Borrador b_c4 solicita Producto 6 (Postre Chocotorta) dado de baja lógica (eliminado=1, disponible=0).\n"
         "Resultado: [RECHAZADO] s_c4 -> Producto dado de baja lógica. Al recargar catálogo no aparece."),
        ("Caso C5 · Solicitud limpia sin cambios:",
         "Borrador b_c5 solicita 2 Empanadas al precio ($150) y stock vigentes.\n"
         "Resultado: [SIMULADO_APROBADO] s_c5 -> Todos los ítems coinciden en disponibilidad, stock y precio."),
        ("Caso C6 · Idempotencia y prevención de duplicación:",
         "Reenvío de solicitud s_c5 con el mismo UUID. Bloqueo exitoso por clave primaria:\n"
         "Resultado: UNIQUE constraint failed: cola_sync.solicitud_uuid. Repetir simulación no reevalúa.")
    ]
    for c_tit, c_desc in casos:
        pdf.set_font('Helvetica', 'B', 8.5)
        pdf.set_text_color(20, 50, 90)
        pdf.cell(0, 4.5, c_tit, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        pdf.code_box(c_desc)

    pdf.section_title('Protección de Idempotencia en Producción y Verificación en PostgreSQL')
    pdf.body_p(
        "• Dónde iría la protección real (Parada 8): En producción se implementa mediante la cabecera HTTP "
        "'Idempotency-Key' validada con Redis o tabla transaccional en PostgreSQL antes de procesar el pago.\n"
        "• Verificación en PostgreSQL: Se ejecutó 'SELECT COUNT(*) FROM pedido' y 'SELECT stock FROM producto'. "
        "La base central permaneció con 0 mutaciones. SIMULADO_APROBADO no es una venta."
    )
    pdf.ln(3)

    # 3.a Mapa de la capa de datos
    pdf.chapter_title('3. Integración y Revisión de la Capa de Datos (Consigna 3)')
    pdf.section_title('3.a Mapa de la Capa de Datos (PostgreSQL, MongoDB y SQLite)')
    with pdf.table(col_widths=(35, 40, 55, 60), borders_layout="ALL") as table:
        row = table.row()
        row.cell('Motor')
        row.cell('Rol Arquitectónico')
        row.cell('Datos Almacenados')
        row.cell('Autoridad (Quién manda)')
        
        m_datos = [
            ('PostgreSQL 16+', 'Core Transaccional (OLTP)', 'Catálogo oficial, clientes, stock, ventas confirmadas, roles, auditoría.', 'Manda sobre el inventario, precios vigentes y ventas reales (Single Source of Truth).'),
            ('MongoDB', 'Almacén Documental (U7)', 'Colección pedidos desnormalizada con objetos y arreglos embebidos.', 'Manda sobre la lectura de comprobantes históricos y precios inmutables.'),
            ('SQLite 3.37+', 'Caché Móvil Offline (U8)', 'producto_cache, pedido_borrador, item_borrador, cola_sync.', 'Manda sobre los borradores en la tablet. No decide stock ni emite ventas.')
        ]
        for m, rol, dat, aut in m_datos:
            r = table.row()
            r.cell(m)
            r.cell(rol)
            r.cell(dat)
            r.cell(aut)
    pdf.ln(3)

    # 3.b Plan de mantenimiento
    pdf.section_title('3.b Plan de Mantenimiento Integral')
    pdf.body_p(
        "1. Respaldo y restauración: PostgreSQL se respalda diariamente con backup_foodstore.sh (formato custom) "
        "y se valida mensualmente con restore_test.sh (RTO: 1,5 s). Las tablets SQLite son efímeras y no se respaldan.\n"
        "2. Restauración de backup viejo: Si PostgreSQL vuelve a un estado anterior, las tablets invalidan su cache "
        "local (producto_cache) forzando la descarga de una nueva instantánea y reevaluando solicitudes encoladas.\n"
        "3. Revisión de conflictos y rechazos: El operador del food truck audita y resuelve conflictos al cierre de turno "
        "(cada 4 h); el administrador central revisa rechazos diariamente para prevenir quiebres de stock."
    )
    pdf.ln(2)

    # 3.c Code Review con IA
    pdf.section_title('3.c Code Review con IA de los Scripts de la Cursada')
    with pdf.table(col_widths=(15, 35, 55, 25, 60), borders_layout="ALL") as table:
        row = table.row()
        row.cell('Unidad')
        row.cell('Script')
        row.cell('Hallazgo Propuesto por IA')
        row.cell('Decisión')
        row.cell('Fundamento Técnico y Comprobación')
        
        revs = [
            ('U5', 'sql/roles.sql', 'GRANT ALL ON ALL TABLES a rol_reportes.', 'CORREGIDO', 'Violaba mínimo privilegio. Se limitó a vistas. Comprobado con permission denied.'),
            ('U6', 'maintenance.sql', 'Ejecutar VACUUM FULL semanal periódico.', 'DESCARTADO', 'Aplica AccessExclusiveLock bloqueando la base. Se mantuvo VACUUM ANALYZE.'),
            ('U8', 'schema_sqlite.sql', 'Usar tipo REAL para precios en SQLite.', 'CORREGIDO', 'Punto flotante IEEE 754 genera desfasajes. Se forzó INTEGER en centavos y STRICT.'),
            ('U4', 'tp_fnbc_control_lote.sql', 'Omitir transacción en migración FNBC.', 'CORREGIDO', 'Se encapsuló en BEGIN/COMMIT con plan de rollback para evitar corrupción.')
        ]
        for u, s, h, d, f in revs:
            r = table.row()
            r.cell(u)
            r.cell(s)
            r.cell(h)
            r.cell(d)
            r.cell(f)

    out_path = os.path.join(os.path.dirname(__file__), "docs", "informe.pdf")
    pdf.output(out_path)
    print(f"PDF generado con éxito: {out_path}")
    print(f"Total de páginas: {pdf.page_no()} (Límite máximo permitido: 6 páginas)")

if __name__ == "__main__":
    build_tp8_pdf()
