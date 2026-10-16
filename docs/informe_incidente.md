# Informe incidente Parte C (simulacro)

## Respuesta IA (TODO: pegar completa tras pasarle el log anonimizado sin contexto)
TODO.

## Contraste IA vs ejecutado (TODO tras respuesta)
- Acertó: ...
- Omitió: ...
- Afirmación sin sustento en log: ...

## Decisión final del equipo (contención, con criterio propio, no auto-ejecutada)
Ante evidencia de fuerza bruta + lectura masiva + escalamiento fallido: bloquear origen en pg_hba/firewall, auditar membresías (SELECT * FROM pg_auth_members), forzar RESET de contraseñas expuestas con fn_resetear_password y revisar GRANTs de Parte A. El escalamiento FALLÓ (permission denied), lo que confirma que el diseño resiste; si hubiera tenido éxito, revertir membresía y corregir roles.sql antes de continuar.
