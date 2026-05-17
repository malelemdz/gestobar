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

---

## 5. Diseño y Frontend (Liquid Modernist)
### Reforma Completa del Diseño y Simplificación Tipográfica
*   **Problema:** Inicialmente se planteó un sistema de triple capa tipográfica que inyectaba `JetBrains Mono` para datos técnicos, códigos y badges realtime. Al implementarse en pantallas móviles, el exceso de familias de fuentes sobrecargaba visualmente la interfaz y dispersaba la identidad de marca.
*   **Estrategia Fallida:** Intentar mantener tres familias tipográficas en una app móvil táctil de pantalla reducida.
*   **Estrategia Adoptada:** **Extirpar por completo JetBrains Mono de la aplicación**. Toda la interfaz se unifica bajo dos familias de Google Fonts: **Plus Jakarta Sans** (títulos, logo, botones cápsula, importes principales y badges de estado activo) e **Inter** (cuerpo de texto, leyendas, metadatos y campos de formulario).
*   **Lección:** En UI móvil de alta gama, menos es más. Reducir la paleta tipográfica a un sistema estricto de dos fuentes aumenta drásticamente la elegibilidad, consistencia de marca y elegancia.

### Estructura de AppBar y Espaciado de Sidebar en Móvil
*   **Problema:** Interfaces móviles iniciales saturadas, con appbars sobredimensionadas (80px), elementos desalineados en el eje vertical central y sidebar sin adecuada holgura ("respiro visual") ante dynamic islands o muescas de notch.
*   **Estrategia Adoptada:** 
    1. Ajustar el AppBar móvil a la altura estándar nativa de `56.0` con centrado vertical absoluto (horizontal baseline de 28px) para icono guía y avatar reducido a 32px, eliminando el chip redundante de caja abierta.
    2. Expandir el padding superior del encabezado lateral a `80.0` y el inferior a `36.0` con `18.0` de separación entre logo y textos, ofreciendo una respiración premium y elegante.
    3. Reubicar el nombre del bar activo directamente debajo del logo e incorporar el botón de tipo cápsula cian sólido únicamente para "Cerrar Sesión", retirando opciones secundarias repetitivas.
*   **Lección:** Un diseño premium se apoya en la calibración matemática y la holgura en los márgenes de respiro. El espacio vacío es un elemento de diseño activo.
