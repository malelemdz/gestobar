# Registro de Estrategias y Decisiones Técnicas

Este documento registra las estrategias adoptadas, los problemas encontrados, las soluciones aplicadas y, sobre todo, las **estrategias fallidas** para evitar repetir errores en el futuro.

---

## 1. Infraestructura y Base de Datos
### Conflicto de Puerto PostgreSQL
*   **Problema:** El puerto estándar `5432` estaba ocupado por otro contenedor (`proyector_db`).
*   **Estrategia Fallida:** Intentar reiniciar el contenedor sin cambiar el puerto (el contenedor quedaba en estado `Created` pero no `Running`).
*   **Solución:** Cambiar el mapeo de puertos en `docker-compose.yml` y `.env` a **`5434:5432`**.
*   **Lección:** Siempre verificar `docker ps` antes de asumir que un puerto está libre.

---

## 2. Desarrollo del Backend (NestJS)
### Generación Automática de Recursos
*   **Problema:** El comando `npx nest g resource <name>` entraba en modo interactivo y bloqueaba la ejecución en el entorno del asistente.
*   **Estrategia Fallida:** Intentar enviar inputs mediante `send_command_input` a un proceso interactivo complejo (falló por desincronización).
*   **Solución:** Crear las carpetas y archivos (`module`, `service`, `controller`, `entities`) manualmente o mediante comandos `mkdir` y `write_to_file`. Esto da más control y evita bloqueos.
*   **Lección:** En este entorno, la creación manual de archivos es más fiable que los generadores interactivos de CLI.

### Errores de Tipado en TypeORM (Null vs Undefined)
*   **Problema:** TypeScript lanzaba errores al intentar asignar `null` a campos definidos como `string` en las entidades, a pesar de que la DB permitía nulos.
*   **Solución:** Definir explícitamente los campos opcionales en las entidades como `string | null` y usar el operador `IsNull()` de TypeORM en las consultas `where`.
*   **Lección:** La paridad de tipos entre TypeScript y la base de datos debe ser explícita para evitar errores de compilación en NestJS.

---

## 3. Seguridad Multi-tenant
### Validación de Contexto para SuperAdmin
*   **Problema:** Riesgo de que un usuario con `bar_id: null` por error obtenga acceso global.
*   **Estrategia Descartada:** Confiar solo en el `bar_id` nulo para identificar al SuperAdmin.
*   **Estrategia Adoptada:** Implementar un **`TenantGuard`** que valida doblemente: el Rol debe ser exactamente `SUPERADMIN` Y solo él puede tener `bar_id: null`. Cualquier otro rol con bar nulo es rechazado inmediatamente.
*   **Decisión de Diseño:** El SuperAdmin usará un header `x-bar-id` para cambiar de contexto entre bares sin necesidad de re-autenticarse.

---

## 4. Gestión de Versiones
### Estructura de Ramas
*   **Estrategia:** Se definió `main` como rama estable y **`stage`** como la rama de desarrollo por defecto.
*   **Procedimiento:** Todos los avances se commitean en `stage`. Solo se pasará a `main` tras validaciones mayores del usuario.
