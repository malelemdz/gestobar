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

### 6. Módulo 3: Catálogo y Gestión de Productos
*   **Entidad Categoría (`src/categories/entities/category.entity.ts`):**
    *   Campos: `id` (UUID), `bar_id` (relación ManyToOne con Bar) y `orden` (para control de posicionamiento visual).
*   **Entidades Producto y Variante (`src/products/entities/`):**
    *   `Product`: Vinculado a su Bar y Categoría, con campos para `foto_url`, `nombre`, `descripcion` y relación OneToMany con Variantes (cascade habilitado).
    *   `Variant`: Vinculado a Producto, con soporte para doble precio (`precio_a` para clientes normales y `precio_b` para damas/compañía), y el flag de disponibilidad `disponible`.
    *   **Precisión de Precios:** Configurado TypeORM con tipo `decimal` (12, 2) y un transformador numérico para parsear las lecturas de base de datos directamente a tipo `number` de TypeScript, evitando el string por defecto de pg.
*   **Validaciones y Reglas de Negocio:**
    *   **Creación Árbol:** Para crear un producto es obligatorio mandar al menos una variante (`ArrayMinSize(1)`).
    *   **Categoría por Defecto:** Si no se especifica `categoria_id` al crear un producto, el sistema busca o crea automáticamente una categoría por defecto llamada "General".
    *   **Lógica de Eliminación de Variantes:** Se implementó una restricción de negocio en `removeVariant` que impide borrar la última variante de un producto (siempre debe quedar al menos una).
*   **Decorador `@ActiveBarId()`:**
    *   Facilita la extracción del ID del bar activo del payload JWT.
    *   **Seguridad:** Un usuario regular tiene vetada la manipulación de cabeceras; se extrae su bar del JWT. En cambio, si el rol es `SUPERADMIN`, se le permite mandar el header `x-bar-id` para actuar en el contexto de cualquier bar sin necesidad de re-autenticarse.

### 7. Módulo 4: Sistema de Caja y Turnos
*   **Entidad Caja (`src/cajas/entities/caja.entity.ts`):**
    *   Campos: `id` (UUID), `bar_id` (relación ManyToOne con Bar), `apertura_usuario_id`, `cierre_usuario_id` (nullable), `fecha_apertura` (TIMESTAMP), `fecha_cierre` (TIMESTAMP, nullable), `monto_inicial`, `monto_final` (nullable) y `estado` (Enum 'ABIERTA' | 'CERRADA').
*   **Validaciones y Restricciones Operativas:**
    *   **Aislamiento y Concurrencia:** Solo se permite **una caja abierta** por bar simultáneamente. Si se intenta abrir otra, arroja `BadRequestException`.
    *   **Operatividad obligatoria:** Ventas futuras consultarán `getActiveCaja` para verificar si hay una caja abierta; en caso de que esté cerrada, las ventas serán bloqueadas.
*   **Reporte de Cierre con Cierre Atómico:**
    *   Al cerrar la caja, el sistema calcula de forma dinámica: ventas totales, comisiones acumuladas por damas, desglose por métodos de pago y diferencia financiera (`monto_final - balance_esperado`).
    *   **Tolerancia a Fallos:** En el cálculo se inyecta una consulta dinámica a través del `DataSource` de TypeORM dentro de un bloque `try-catch`, asegurando que el Módulo 4 funcione autónomamente y compile perfectamente aun antes de crear las entidades de ventas del Módulo 5.
*   **Decorador `@ActiveUserId()` y `@ActiveBarId()`:**
    *   Se implementó el decorador en `src/auth/decorators/active-user-id.decorator.ts` para extraer con facilidad y total seguridad el ID del usuario actual firmante desde el payload JWT (empleado para registrar a los responsables de apertura y cierre de caja).

### 8. Módulo 5: Motor de Ventas y Comisiones
*   **Entidades Venta y Detalle (`src/ventas/entities/`):**
    *   `Venta`: Registra el `total`, `metodo_pago`, `fecha`, y está vinculada a `bar_id`, `caja_id` (del turno activo) y `usuario_id` (cajero). Relación OneToMany cascada con detalles.
    *   `DetalleVenta`: Almacena variantes individuales vendidas, cantidades, `precio_unitario`, flag de `es_precio_b`, relación opcional con la Dama (`dama_id`), comisión calculada `comision_dama` y flag `es_invitacion`.
*   **Validaciones y Flujos de Negocio de Ventas:**
    *   **Bloqueo de Ventas:** Si la caja de ese bar no está en estado `ABIERTA`, la transacción se rechaza de inmediato.
    *   **Regla de Precios y Comisiones:**
        *   *Normal:* Se cobra `Precio A` y comisión de Dama es 0.
        *   *Compañía (Precio B):* Se cobra `Precio B` y es mandatorio enviar un `dama_id`.
        *   *Invitaciones:* Se cobra `Precio A` a la cuenta del cliente, la comisión es 0, y es obligatorio mandar `dama_id` para auditar a quién se le dio la bebida.
*   **Comisión Configurable por Bar:**
    *   Añadida la columna `comision_porcentaje` en la entidad `Bar` (con valor por defecto de 50.00% y rango de 0% a 100%).
    *   Al calcular comisiones en tiempo de venta, el sistema consulta dinámicamente el valor actual `bar.comision_porcentaje` y calcula la comisión exacta: `precio_b * (bar.comision_porcentaje / 100)`.
*   **Sincronización Real-time por WebSockets (`ventas.gateway.ts`):**
    *   Integrado **socket.io** mediante `@nestjs/websockets`.
    *   **Canales Privados de Damas:** Al conectarse, una Dama se suscribe a su propio canal privado (`suscribir_dama` uniendo el socket a la sala del `damaId`).
    *   **Notificación Instantánea:** En el momento exacto en que se graba la venta atómica, el gateway emite de forma asíncrona notificaciones privadas a los canales de las Damas involucradas informando detalles de su nueva comisión o bebida invitada.

### 9. Módulo 6: Menú QR Público
*   **Diseño de API Pública (`src/menu/`):**
    *   **Totalmente Anónimo:** Rutas y controladores configurados fuera de guardias de autenticación global, permitiendo acceso directo y de alta velocidad por clientes del bar mediante el código QR.
    *   **Búsqueda por Slug:** El endpoint `/menu/:slug` resuelve la información de marca (Nombre, Logo, Redes, Whatsapp, etc.) basándose en el parámetro público `slug`.
*   **Validación de Estatus de Operación ("Cerrado"):**
    *   Retorna de manera dinámica la bandera `abierto: boolean`. Si no existe un turno de caja activo en estado `ABIERTA` para ese bar, se retorna `abierto: false`. Esto permite al frontend advertir a los clientes que la barra se encuentra temporalmente cerrada para pedidos.
*   **Sanitización Absoluta de Precios de Compañía (Precio B):**
    *   El endpoint `/menu/:slug/productos` devuelve la carta organizada en categorías de ordenación estructurada.
    *   **Seguridad de Datos:** Las variantes de cada producto se mapean y sanitizan minuciosamente para:
        1. Excluir variantes no disponibles (`v.disponible === false`).
        2. **Eliminar por completo el `precio_b` (Precio de Compañía/Damas) del JSON de respuesta pública**, renombrando el atributo `precio_a` a simplemente `precio`. Esto imposibilita filtraciones de precios internos hacia el cliente general.
*   **Generación de Enlaces QR Dinámicos:**
    *   El servicio lee la variable de configuración `FRONTEND_URL` para construir de manera dinámica y exacta la URL final del menú basada en el slug único (`${frontendUrl}/menu/${bar.slug}`).

### 10. Módulo 7: Auditoría y Trazabilidad (Ojo de Halcón)
*   **Entidad de Auditoría (`src/auditoria/entities/auditoria.entity.ts`):**
    *   Registra de forma blindada: `bar_id`, `usuario_id`, `rol_nombre`, `accion` (ej. `APERTURA`, `CIERRE`, `REGISTRAR_VENTA`), `modulo`, `detalles` (objeto JSONB con datos de payload anteriores y nuevos) e `ip_address` (nullable).
*   **Globalización y Despliegue de Inyección:**
    *   Configurado el módulo con el decorador `@Global()` en `src/auditoria/auditoria.module.ts`, permitiendo a cualquier servicio del backend registrar logs de forma asíncrona inyectando `AuditoriaService` sin acoplamientos complejos de imports.
*   **Registro de Auditoría Automatizado:**
    *   **Cajas:** Registra automáticamente aperturas de caja (con `monto_inicial`) y cierres (con `monto_final`, totales, comisiones y descuadres).
    *   **Ventas:** Registra de forma atómica cada checkout realizado (ID de venta, montos cobrados, métodos de pago y cantidad de ítems).
*   **Decorador `@ActiveUser()` y Clase `UserPayload`:**
    *   Se creó `@ActiveUser()` en `src/auth/decorators/active-user.decorator.ts` para extraer con facilidad y total seguridad el payload completo del usuario (ID, Rol, Email) desde el token JWT.
    *   **Compatibilidad TypeScript (TS1272):** Definida la clase `UserPayload` para resolver limpiamente las dependencias de reflexión de metadatos de TypeScript bajo la bandera `emitDecoratorMetadata`.
*   **API Segura con Filtros Dinámicos:**
    *   El endpoint `GET /auditoria` (protegido bajo el permiso `@Permissions('reportes.ver')`) ofrece un visor de logs multi-tenant que permite filtrar dinámicamente por usuario, rol, acción, módulo y rango de fechas (ISO) mediante operadores nativos de TypeORM como `Between`, `MoreThanOrEqual` y `LessThanOrEqual`.

### 11. Módulo 8: Estadísticas y Business Intelligence (BI)
*   **Diseño de Estadísticas Centralizadas (`src/estadisticas/`):**
    *   **Resumen General (`/estadisticas/resumen`):** Devuelve agregados de ingresos totales, comisiones totales, ingreso neto estimado (`ingresos_totales - comisiones_pagadas`), cantidad de transacciones y un desglose pormenorizado del volumen y cantidad por método de pago (tarjeta, efectivo, QR, transferencia, etc.) filtrado por rangos de fechas (con un inteligente default de los últimos 30 días).
    *   **Ranking de Productos (`/estadisticas/ranking-productos`):** Agrega las ventas en el rango de fechas para listar variantes, productos y categorías más demandadas con volumen vendido y dinero total recaudado.
    *   **Productividad de Damas (`/estadisticas/ranking-damas`):** Muestra el ranking de efectividad del personal de compañía, detallando comisiones acumuladas, cantidad de invitaciones recibidas y turnos/servicios de compañía prestados en el periodo de tiempo analizado.
*   **Reportes Detallados de Turnos de Caja (`/estadisticas/caja/:id`):**
    *   Genera un reporte analítico exhaustivo para auditoría de un turno específico, cruzando el saldo inicial y final físico registrado con el balance computado automáticamente (Ventas registradas menos comisiones pagadas), exponiendo la diferencia exacta (descuadre de caja) y el desglose de ingresos por método de pago.
*   **Rendimiento en Base de Datos:**
    *   Implementado con consultas SQL directas y parametrizadas sobre el `DataSource` de TypeORM, optimizando al máximo los tiempos de procesamiento y respuesta en base de datos PostgreSQL, blindado con total aislamiento por `bar_id` (multi-tenant).

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
│   ├── guards/jwt-auth.guard.ts
│   ├── guards/permissions.guard.ts
│   ├── guards/tenant.guard.ts
│   ├── decorators/active-bar-id.decorator.ts
│   ├── decorators/active-user-id.decorator.ts
│   └── decorators/active-user.decorator.ts
├── bars/                      # CRUD de Bares (SaaS)
│   ├── entities/bar.entity.ts
│   ├── bars.service.ts
│   └── bars.controller.ts
├── categories/                # Módulo de Categorías (Módulo 3)
│   ├── entities/category.entity.ts
│   ├── categories.service.ts
│   └── categories.controller.ts
├── products/                  # Módulo de Productos y Variantes (Módulo 3)
│   ├── entities/product.entity.ts
│   ├── entities/variant.entity.ts
│   ├── products.service.ts
│   └── products.controller.ts
├── cajas/                     # Módulo de Cajas y Turnos (Módulo 4)
│   ├── entities/caja.entity.ts
│   ├── cajas.service.ts
│   └── cajas.controller.ts
├── ventas/                    # Módulo de Ventas y Comisiones (Módulo 5)
│   ├── entities/venta.entity.ts
│   ├── entities/detalle-venta.entity.ts
│   ├── dto/create-venta.dto.ts
│   ├── ventas.service.ts
│   ├── ventas.controller.ts
│   └── ventas.gateway.ts
├── menu/                      # Menú QR Público (Módulo 6 - Solo Backend)
│   ├── menu.service.ts
│   ├── menu.controller.ts
│   └── menu.module.ts
├── auditoria/                 # Auditoría y Trazabilidad (Módulo 7)
│   ├── entities/auditoria.entity.ts
│   ├── dto/query-auditoria.dto.ts
│   ├── auditoria.service.ts
│   └── auditoria.controller.ts
├── estadisticas/              # Estadísticas y Business Intelligence (Módulo 8)
│   ├── dto/rango-fechas.dto.ts
│   ├── estadisticas.service.ts
│   ├── estadisticas.controller.ts
│   └── estadisticas.module.ts
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
