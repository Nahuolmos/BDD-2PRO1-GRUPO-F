# spec: soft_delete_producto_categoria

Objetivo: implementar borrado lógico verificable y demostrar su impacto en consultas e índices (Objetivo 9 TPI).

Tablas afectadas: producto, categoria (las que ya usan `activo` para vigencia). Se agrega columna `eliminado` separada de `activo` para distinguir "no vigente" vs "borrado lógico".

Definición:
- `producto.eliminado BOOLEAN NOT NULL DEFAULT FALSE`
- `categoria.eliminado BOOLEAN NOT NULL DEFAULT FALSE`
- Regla: `eliminado=FALSE` = fila visible para la aplicación. `eliminado=TRUE` = oculta pero conservada para FK y auditoría. No se hace `DELETE` físico.
- Consultas y vistas deben filtrar `WHERE eliminado=FALSE` (además de `activo=TRUE` cuando es catálogo vigente).
- Índice parcial: `CREATE INDEX idx_producto_vigente_no_eliminado ON producto(categoria_id) WHERE eliminado=FALSE AND activo=TRUE` — solo indexa vigentes no borrados, más chico y usado solo cuando la query filtra esas dos columnas.

Criterio de aceptación:
- `ALTER TABLE` agrega columna sin romper PK/FK existentes.
- `SELECT * FROM producto WHERE eliminado=FALSE` excluye borrados; `SELECT * FROM v_productos_vigentes` ya filtra ambos.
- `EXPLAIN` muestra uso de índice parcial cuando la query incluye `WHERE eliminado=FALSE AND activo=TRUE`, y Seq Scan si no filtra.
- Verificación: borrar lógico 1 producto (`UPDATE producto SET eliminado=TRUE WHERE id=1`) y comprobar que desaparece de la vista pero sigue en `SELECT * FROM producto WHERE eliminado=TRUE`.

Impacto documentado: consultas sin `eliminado=FALSE` traen basura; índice parcial reduce tamaño ~40% vs índice total.
