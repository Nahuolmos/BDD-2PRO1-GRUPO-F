# Verificación equivalencia Parte D (real, 2026-10-15)

Anon: SELECT rol, mes_alta, COUNT(*) FROM usuario_anon GROUP BY 1,2 ORDER BY 1,2;
```
   rol    | mes_alta | count
----------+----------+-------
 reportes | 2026-10  |     1
 soporte  | 2026-10  |     1
(2 rows)
```
Real: SELECT rol, to_char(date_trunc('month',created_at),'YYYY-MM'), COUNT(*) FROM usuario WHERE eliminado=FALSE GROUP BY 1,2 ORDER BY 1,2;
```
   rol    | to_char | count
----------+---------+-------
 reportes | 2026-10 |     1
 soporte  | 2026-10 |     1
(2 rows)
```
Equivalencia: mismos conteos y agrupamientos (EXCEPT ambos sentidos = 0 filas).

Nunca sale a la IA sin anonimizar: mails y nombres reales, contrasena_hash y cualquier identificador directo de usuario/cliente; solo agregados o sintéticos userNNN@anon.invalid.
