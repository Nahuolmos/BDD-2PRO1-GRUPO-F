# Declaración de Uso de IA (DUIA) - Trabajo Práctico Integrador

* **Proyecto:** Food Store (Base de Datos II - UTN)
* **Alumno:** Facundo Cabrera
* **Herramientas de IA utilizadas:** Kiro / OpenCode / Asistente de IA (Gemini)

---

## Detalle de Intervención por Etapas

| **Parte 0: Protocolo de Seguridad** | Generación de la plantilla base en Markdown para el archivo `protocolo_seguridad.md`. | Se revisaron y adaptaron los comandos de respaldo (`pg_dump`) al entorno local. |


| **Parte 1: Restricciones de Integridad** | Propuesta de la expresión regular compatible con PostgreSQL (`~*`) y las sentencias `ALTER TABLE`. | Se ejecutó el script en el motor SQL y se validó el comportamiento mediante pruebas transaccionales de rechazo. |


| **Parte 2: Concurrencia y Anomalías** | Simular y documentar escenarios de bloqueos y lecturas concurrentes con dos sesiones. | Estructuración del archivo `informe_concurrencia.md` con las explicaciones técnicas de los niveles de aislamiento. | Se abrieron dos pestañas independientes en el cliente SQL, se reprodujeron los escenarios reales y se contrastó la salida del motor. |