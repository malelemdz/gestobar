# Estado Actual del Módulo de Personal y Usuarios (Staff & RBAC)

Este documento detalla el estado actual en el backend (NestJS/PostgreSQL) y en el frontend (Flutter) del módulo de **Gestión de Personal y Control de Acceso (RBAC)** en Gestobar, identificando brechas operativas y de seguridad clave para estructurar el plan de acción de la Fase 2.

---

## 👥 1. Estructura y Modelos de Datos Existentes (Backend)

### A. Entidad Usuario (`User` -> Tabla `usuarios`)
La entidad de usuarios está completamente declarada en `backend/src/users/entities/user.entity.ts` con la siguiente estructura:
*   `id` (UUID, llave primaria).
*   `bar_id` (UUID, nullable, relación `ManyToOne` con `Bar`): Aísla al empleado dentro de su bar sucursal asignado (excepto para `SUPERADMIN`, que es null).
*   `username` (String, único): Nombre de usuario utilizado para el login.
*   `password` (String, oculto por defecto con `select: false`): Contraseña encriptada en Bcrypt.
*   `foto_url` (String, nullable): Enlace a la imagen de perfil (gestionada con el actualizador Sharp WebP).
*   `nombre` y `apellido` (String): Datos de identificación personal.
*   `identificacion` (String, nullable): Documento de identidad (DNI / Cédula).
*   `nacionalidad` (String, nullable).
*   `celular` (String, nullable): WhatsApp o teléfono de contacto.
*   `direccion` (String, nullable): Residencia física.
*   `estado` (Boolean, default: `true`): Permite deshabilitar el acceso al personal sin borrar su historial financiero/ventas.
*   `rol_id` (UUID): Llave foránea que asocia al usuario con un rol.
*   `rol` (Relación `ManyToOne` con la entidad `Role`).
*   `created_at` y `updated_at` (Timestamps).

### B. Entidades de Roles y Permisos (`src/roles/entities/`)
*   **`Role` (Tabla `roles`):** Define roles de sistema. Soporta roles de sucursal (`bar_id` UUID) y roles globales (`bar_id` nulo). Relación `ManyToMany` con `Permission`.
*   **`Permission` (Tabla `permisos`):** Almacena permisos atómicos de la aplicación (ej: `ventas.registrar`, `caja.gestionar`, `bares.gestionar`, `usuarios.gestionar`, `reportes.ver`).

---

## 🔌 2. Endpoints y Lógica de Servicios (Backend)

### A. Controlador de Usuarios (`UsersController` -> `users.controller.ts`)
Actualmente expone los siguientes endpoints en la ruta `/users`:
*   `POST /users`: Registra un nuevo usuario aplicando hashing de contraseña con `bcrypt` (10 rondas de salting).
*   `GET /users`: Recupera todos los usuarios con sus roles asociados.
*   `GET /users/:id`: Obtiene el detalle de un usuario por su UUID.
*   `PATCH /users/:id`: Actualiza campos parciales de un usuario.

### B. Módulo de Roles y Permisos (`src/roles/`)
*   `RolesService` y `RolesController` proveen la lógica básica para listar roles del bar y asignar permisos.
*   El sistema cuenta con un guard de seguridad global **`PermissionsGuard`** que analiza el decorador `@Permissions(...)` y un guard multi-tenant **`TenantGuard`** para aislar el contexto por `bar_id`.

---

## 🚨 3. Diagnóstico de Brechas Operativas y de Seguridad (Crítico)

Tras revisar a fondo el código actual, detectamos brechas de seguridad y de negocio que deben corregirse prioritariamente al implementar la planificación:

1.  **Falta de Aislamiento Multi-tenant en Usuarios (Crítico):**
    *   El endpoint `GET /users` ejecuta un `this.userRepository.find()` global sin filtrar por el `bar_id` del usuario firmante. Un administrador de la Sucursal A podría recuperar la lista de personal de la Sucursal B.
    *   **Solución requerida:** Modificar el endpoint para que extraiga el `bar_id` del token (vía `@ActiveBarId()`) y filtre estrictamente las consultas por sucursal.
2.  **Falta de Protección de Acceso (Guardias):**
    *   El controlador de usuarios (`UsersController`) actualmente **no tiene protectores** de tipo `@UseGuards(JwtAuthGuard, TenantGuard)` ni decoradores de permisos `@Permissions('usuarios.gestionar')`. Cualquier petición anónima de red podría crear, alterar o listar tu personal.
    *   **Solución requerida:** Proteger todo el controlador restringiéndolo únicamente a administradores autorizados.
3.  **Falta de Modificadores en Edición de Contraseñas:**
    *   El endpoint `PATCH /users/:id` no encripta la contraseña si se envía en el body de actualización, lo que guardaría la contraseña en texto plano en la base de datos.
    *   **Solución requerida:** Sanitizar la actualización para encriptar la clave si se envía o crear un endpoint específico `PATCH /users/:id/password` para restablecimientos seguros.

---

## 📱 4. Estado Actual en el Cliente (Frontend)

*   **Página Placeholder (`lib/features/staff/presentation/staff_page.dart`):**
    *   Actualmente es un componente estático básico sin lógica interactiva, sin Riverpod providers, ni repositorios de red.
*   **Vistas Pendientes a Construir:**
    *   **Listado de Personal (Bento Grid / Premium Cards):** Mostrar tarjetas estilizadas de empleados con su estado (Activo/Inactivo), rol asignado (con colores cyber-neón característicos de Gestobar), celular y foto de perfil.
    *   **Modal de Adición/Edición de Empleados:** Formulario detallado con validaciones de campos (Nombre, Apellido, Nombre de usuario único, Contraseña, DNI/Identificación, Nacionalidad, Celular y Selector de Rol dinámico).
    *   **Restablecimiento Rápido de Contraseñas:** Diálogo emergente para administradores que permite setear una nueva contraseña temporal segura para el empleado.
    *   **Conmutador de Estado de Acceso:** Interruptor premium en la tarjeta del empleado para activarlo o desactivarlo en caliente (`estado: true/false`).
