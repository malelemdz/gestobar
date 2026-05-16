# Bitácora de Desarrollo - Gestobar Multi-tenant

Este documento registra de forma cronológica y detallada cada componente, estructura y lógica que ha sido implementada en el backend de **Gestobar**. Servirá como referencia técnica absoluta del estado del sistema.

---

## Estado Actual de la Arquitectura
El backend está construido con **NestJS (TypeScript)**, utilizando **TypeORM** para la persistencia de datos sobre una base de datos **PostgreSQL**. La arquitectura está blindada para multi-tenant (SaaS) con aislamiento estricto a nivel de base de datos y validación de contexto en peticiones HTTP.

---

## Historial de Implementaciones

### 1. Inicialización e Infraestructura Base
*   **Creación del Proyecto:** Inicializado esqueleto NestJS limpio en la carpeta `/backend`.
*   **Contenedor de Base de Datos:** Configuración de `docker-compose.yml` en la raíz del proyecto para una instancia aislada de **PostgreSQL 15 (Alpine)**.
*   **Variables de Env:** Creación del archivo `/backend/.env` con credenciales y puertos de conexión.
*   **Ajuste de Puertos (Desarrollo):** Re-mapeo del puerto de PostgreSQL del estándar `5432` al **`5434`** para evitar colisiones con otros servicios activos en el sistema local (OrbStack).
*   **Pipes de Validación:** Activación global de `ValidationPipe` en `main.ts` con opciones `whitelist: true` y `forbidNonWhitelisted: true` para asegurar la integridad de todas las entradas (DTOs).

### 2. Módulo 1: Core Multi-tenant (Bares)
*   **Entidad Bar (`src/bars/entities/bar.entity.ts`):**
    *   Definición de campos de localización: `ciudad`, `timezone`, `moneda_simbolo`, `moneda_iso`.
    *   Campos de contacto y redes: `whatsapp` (único medio telefónico requerido), `link_ubicacion` (Google Maps), `facebook`, `instagram`, `tiktok`.
    *   Aislamiento de acceso: `slug` único e índice para rutas públicas dinámicas (ej: `gestobar.com/menu/slug-del-bar`).
    *   Relación con dueño: `owner_id` (Relación ManyToOne con la entidad `User`).
*   **CRUD de Bares (`src/bars`):**
    *   Controlador con rutas REST estándar protegidas.
    *   Servicio con validaciones para evitar la duplicidad de `slugs`.
    *   DTOs estrictos para creación y actualización.

### 3. Módulo 2: Seguridad y Autenticación (JWT & RBAC)
*   **Entidad Usuario (`src/users/entities/user.entity.ts`):**
    *   Campos detallados de perfil para staff: `foto_url`, `identificacion`, `nacionalidad`, `celular`, `direccion`.
    *   Relación estricta con rol y bar: `rol_id` (obligatorio) y `bar_id` (nullable solo para SuperAdmin).
*   **Entidades de Roles y Permisos (`src/roles`):**
    *   `Role`: Permite roles globales (`bar_id: null`) y personalizados por bar. Relación ManyToMany con `Permission`.
    *   `Permission`: Almacena permisos atómicos de la aplicación (ej: `ventas.registrar`, `caja.gestionar`).
*   **Autenticación JWT (`src/auth`):**
    *   Encriptación de contraseñas mediante **Bcrypt** (10 rondas de salting).
    *   Servicio de Login que genera un token JWT con vigencia de 1 día, codificando `userId`, `username`, `rolId` y `barId` en el payload.
    *   Estrategia `JwtStrategy` para validar y deserializar el payload en cada petición protegida.
*   **PermissionsGuard:** Guardia personalizado que intercepta peticiones HTTP, analiza el decorador `@Permissions(...)` y rechaza la petición con `403 Forbidden` si el rol del usuario no cuenta con los permisos necesarios. **SuperAdmin** tiene bypass automático.

### 4. TenantGuard (Blindaje Multi-tenant)
*   **Lógica de Hierro:**
    *   Verifica que **únicamente** los usuarios con el rol exacto de `SUPERADMIN` puedan realizar peticiones con `bar_id: null` (acceso global a la grilla de bares).
    *   Para cualquier otro rol (Admin, Barman, Dama), si por error de base de datos o API su token no incluye un `bar_id` asignado, el guardia bloquea la petición inmediatamente con un error de acceso no autorizado.

### 5. Sistema de Seeding (`src/seed`)
*   **Seed Automático:** Controlador y servicio creados para inicializar el sistema con un solo clic/comando.
*   **Roles y Permisos Básicos Seedados:**
    *   `SUPERADMIN`: Permisos de `bares.gestionar`, `usuarios.gestionar`, `reportes.ver`.
    *   `ADMIN`: Permisos de gestión de staff, catálogo, cajas y reportes.
    *   `BARMAN`: Permisos de ventas y caja.
    *   `DAMA`: Permiso único para ver sus propias comisiones.
    *   `REVIEWER`: Permiso de solo lectura.

---

## Archivos Clave del Backend
```bash
backend/src/
├── app.module.ts              # Módulo raíz (configura TypeORM y carga módulos)
├── main.ts                    # Punto de entrada (ValidationPipe y configuración global)
├── auth/                      # Autenticación y Guardias
│   ├── auth.service.ts
│   ├── auth.controller.ts
│   ├── strategies/jwt.strategy.ts
│   ├── guards/permissions.guard.ts
│   └── guards/tenant.guard.ts
├── bars/                      # CRUD de Bares (SaaS)
│   ├── entities/bar.entity.ts
│   ├── bars.service.ts
│   └── bars.controller.ts
├── roles/                     # Roles y Permisos (RBAC)
│   ├── entities/role.entity.ts
│   ├── entities/permission.entity.ts
│   └── roles.service.ts
├── users/                     # Gestión de Usuarios y Perfiles
│   ├── entities/user.entity.ts
│   └── users.service.ts
└── seed/                      # Inicializador de Base de Datos
    ├── seed.service.ts
    └── seed.controller.ts
```
