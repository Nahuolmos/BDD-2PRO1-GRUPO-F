-- Parte D: usuario_anon determinista (nada de PII real sale a la IA).
-- Misma granularidad por (rol, mes) que usuario, valores sintéticos.
DROP TABLE IF EXISTS usuario_anon;
CREATE TABLE usuario_anon (
    id BIGINT PRIMARY KEY,
    nombre_anon TEXT NOT NULL,
    mail_anon TEXT NOT NULL,
    rol TEXT NOT NULL,
    mes_alta TEXT NOT NULL
);
INSERT INTO usuario_anon (id, nombre_anon, mail_anon, rol, mes_alta)
SELECT id,
       'Anon ' || id,
       'user' || id || '@anon.invalid',
       rol,
       to_char(date_trunc('month', created_at), 'YYYY-MM')
FROM usuario WHERE eliminado = FALSE;

-- Agregación sobre anon (pedida a OpenCode)
-- SELECT rol, mes_alta, COUNT(*) FROM usuario_anon GROUP BY rol, mes_alta ORDER BY 1,2;
-- Equivalente sobre real:
-- SELECT rol, to_char(date_trunc('month', created_at),'YYYY-MM') AS mes_alta, COUNT(*) FROM usuario WHERE eliminado=FALSE GROUP BY rol, mes_alta ORDER BY 1,2;
-- Equivalencia (0 filas = coinciden):
-- (SELECT rol, mes_alta, COUNT(*) FROM usuario_anon GROUP BY 1,2
--  EXCEPT SELECT rol, to_char(date_trunc('month', created_at),'YYYY-MM'), COUNT(*) FROM usuario WHERE eliminado=FALSE GROUP BY 1,2)
-- UNION ALL
-- (SELECT rol, to_char(date_trunc('month', created_at),'YYYY-MM'), COUNT(*) FROM usuario WHERE eliminado=FALSE GROUP BY 1,2
--  EXCEPT SELECT rol, mes_alta, COUNT(*) FROM usuario_anon GROUP BY 1,2);
