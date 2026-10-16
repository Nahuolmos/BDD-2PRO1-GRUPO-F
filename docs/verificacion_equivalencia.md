# Verificación equivalencia Parte D (TODO: pegar ambas salidas)

Anon: SELECT rol, mes_alta, COUNT(*) FROM usuario_anon GROUP BY 1,2 ORDER BY 1,2;
Real: SELECT rol, to_char(date_trunc('month',created_at),'YYYY-MM'), COUNT(*) FROM usuario WHERE eliminado=FALSE GROUP BY 1,2 ORDER BY 1,2;
TODO: pegar ambos resultados lado a lado + EXCEPT = 0 filas.

Nunca sale a la IA sin anonimizar: mails y nombres reales, contrasena_hash y cualquier identificador directo de usuario/cliente; solo agregados o sintéticos userNNN@anon.invalid.
