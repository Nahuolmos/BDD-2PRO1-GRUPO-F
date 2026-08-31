# Protocolo de Seguridad - Proyecto Integrador

Este documento define el protocolo obligatorio de tres pasos (`Copia`, `Transacción` y `Respaldo`) que se debe aplicar de manera estricta antes de ejecutar cualquier script o modificación sobre la base de datos del proyecto, garantizando la integridad de los datos de trabajo.

---

## 1. Copia (Entorno de Trabajo Aislado)
* **Regla:** Nunca se ejecuta ningún script de prueba, migración o restricción sobre bases de datos de producción o datos reales de terceros.
* **Procedimiento:** Se trabaja exclusivamente sobre una base de datos de desarrollo/copia local creada a partir de la plantilla base del proyecto.
* **Comando de creación:**
  ```sql
  -- Comando en PostgreSQL para crear la copia de trabajo
  CREATE DATABASE copia_trabajo WITH TEMPLATE plantilla_base;