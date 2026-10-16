-- Parte C: simulacro acceso indebido (solo contra food_store local).
-- Requiere sql/00_usuario_base.sql y sql/roles.sql aplicados.
-- Secuencia: 3 fallidos -> 1 éxito -> lectura masiva -> intento escalamiento (debe FALLAR).
-- Fallidos (cada uno deja ERROR login fallido en log)
SELECT fn_autenticar('soporte1@foodstore.test', 'wrong1');
SELECT fn_autenticar('soporte1@foodstore.test', 'wrong2');
SELECT fn_autenticar('soporte1@foodstore.test', 'wrong3');
-- Éxito
SELECT fn_autenticar('soporte1@foodstore.test', 'Soporte123');
-- Lectura masiva usuario
SELECT * FROM usuario;
-- Escalamiento: rol bajo (reportes) intenta darse admin_datos -> debe dar permission denied
SET ROLE rol_reportes;
GRANT admin_datos TO app_web;
RESET ROLE;
-- Verificación: si el GRANT anterior NO falla, es hallazgo (defecto Parte A, corregir antes de seguir).
