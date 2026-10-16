# Informe incidente Parte C (simulacro)

## Reconstrucción IA (respuesta completa, solo con el log anonimizado)
Hipótesis: a las 21:14 se aplicó esquema de roles (GRANTs masivos, coherente con despliegue). A las 21:15, 3 login fallidos seguidos para user0001@test.invalid en el mismo segundo (posible fuerza bruta o prueba de credenciales), seguidos de un intento de GRANT admin_datos a app_web que fue denegado (permission denied). Contención propuesta por la IA: bloquear la IP origen, auditar membresías de admin_datos y forzar reset de la contraseña de user0001.

## Contraste IA vs ejecutado
- Acertó: 3 fallidos + escalamiento denegado, orden y causa (sin ADMIN option).
- Omitió: el login exitoso posterior y la lectura masiva SELECT * FROM usuario (el equipo los ejecutó —ver screenshot— pero con log_statement='mod' los SELECT no se loguean, la IA no podía verlos).
- Sin sustento: atribuir origen externo/atacante — el fragmento no trae líneas connection/host, y los 3 intentos en el mismo segundo corresponden al script de prueba, no necesariamente a un ataque distribuido. También leyó los GRANTs de las 21:14 como parte del incidente cuando eran el despliegue de roles.sql.

## Decisión final del equipo (contención, con criterio propio, no auto-ejecutada)
Ante fuerza bruta contenida + lectura masiva + escalamiento fallido: bloquear origen en pg_hba/firewall, auditar membresías (SELECT * FROM pg_auth_members WHERE roleid='admin_datos'::regrole), forzar RESET con fn_resetear_password y revisar GRANTs de Parte A. El escalamiento FALLÓ (permission denied), el diseño resiste; si hubiera tenido éxito, revertir membresía y corregir roles.sql antes de continuar. Decisión del equipo desde evidencia, no acción automática de la IA.
