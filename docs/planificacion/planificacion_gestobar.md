# Roadmap de Implementación: Gestobar

Este documento sirve como guía de desarrollo y checklist de progreso. Los módulos están organizados de forma lógica para el desarrollo, comenzando por el **Backend**.

---

## Módulo 1: Infraestructura y Core Multi-tenant
*Infraestructura base para soportar múltiples bares de forma aislada.*

- [x] **Configuración del Entorno**
  - [x] Inicialización de repositorio GitHub.
  - [x] Configuración de proyecto Node.js con NestJS/TypeScript.
  - [x] Configuración de PostgreSQL local (Docker Compose / OrbStack).
- [ ] **Gestión Global de Bares (SuperAdmin)**
  - [ ] Implementar CRUD de Bares (Solo SuperAdmin).
  - [ ] Campo: Logo (Almacenamiento de URL).
  - [ ] Campo: Nombre comercial.
  - [ ] Campo: Ciudad y Dirección física.
  - [ ] Campo: WhatsApp de contacto.
  - [ ] Campo: Link de Ubicación (Google Maps).
  - [ ] Campos Sociales: Facebook, Instagram, TikTok.
  - [ ] Configuración de Localización: Zona Horaria (IANA) y Moneda (Símbolo e ISO).
  - [ ] Lógica de Activación/Desactivación de Bares (Bloqueo de acceso).

---

## Módulo 2: Seguridad, Usuarios y Roles (RBAC)
*Sistema de autenticación y permisos granulares por cada bar.*

- [ ] **Sistema de Roles por Bar**
  - [ ] Definición de Roles Globales (SuperAdmin, Reviewer).
  - [ ] Funcionalidad para que cada Admin de Bar cree sus propios Roles (Barman, Seguridad, etc.).
  - [ ] Sistema de Permisos asignables a Roles (ej: `ventas.crear`, `reportes.ver`).
- [ ] **Gestión de Usuarios y Perfiles**
  - [ ] Registro detallado de personal (Común para todos los roles):
    - [ ] Foto de perfil.
    - [ ] Nombre y Apellidos.
    - [ ] Número de Identificación (Cédula/DNI).
    - [ ] Nacionalidad.
    - [ ] Número de Celular.
    - [ ] Dirección de domicilio.
  - [ ] Lógica de Multi-propiedad: Un usuario Admin puede estar vinculado a varios bares.
- [ ] **Autenticación**
  - [ ] Implementación de JWT (JSON Web Tokens).
  - [ ] Encriptación de contraseñas con Bcrypt.
  - [ ] Rol de Lectura Especial: Acceso para revisores de Apple/Google (Solo lectura, datos de prueba).

---

## Módulo 3: Catálogo y Gestión de Productos
*Estructura de productos con variantes y doble precio.*

- [x] **Categorización**
  - [x] CRUD de Categorías (Obligatorias, vinculadas a `bar_id`).
  - [x] Soporte para categoría por defecto si no se crean manualmente.
- [x] **Productos y Variantes**
  - [x] CRUD de Productos (Foto, Nombre, Descripción).
  - [x] Lógica de Variantes: Todo producto tiene al menos una variante.
  - [x] Gestión de Variantes (Nombre, Precio A - Normal, Precio B - Compañía).
  - [x] Flag de disponibilidad por variante.

---

## Módulo 4: Sistema de Caja y Turnos
*Control de flujo de dinero y tiempos de operación.*

- [ ] **Gestión de Turnos**
  - [ ] Lógica de Apertura de Caja (Usuario, fecha, monto inicial).
  - [ ] Lógica de Cierre de Caja (Usuario, fecha, monto final).
  - [ ] Soporte para turnos que cruzan la medianoche (ID de Turno único).
- [ ] **Validación de Operación**
  - [ ] Bloqueo de ventas si la caja no está abierta.
  - [ ] Reporte resumido al cierre del turno (Ventas totales, comisiones, métodos de pago).

---

## Módulo 5: Motor de Ventas y Comisiones
*Lógica central del negocio: Venta rápida y pagos a damas.*

- [ ] **Proceso de Venta (Backend)**
  - [ ] Registro de venta atómica (Items, cantidades, precios aplicados).
  - [ ] Validación: Si se usa Precio B, el `dama_id` es obligatorio.
  - [ ] Cálculo automático de comisión (50% del Precio B del cliente).
- [ ] **Lógica de "Invitaciones"**
  - [ ] Si la venta es para la Dama, se aplica Precio A y comisión 0.
- [ ] **Sincronización Real-time**
  - [ ] Integración de WebSockets (Socket.io).
  - [ ] Notificación instantánea a la Dama cuando se registra una comisión a su nombre.

---

## Módulo 6: Menú QR Público
*Acceso informativo para el cliente final.*

- [ ] **API Pública de Menú**
  - [ ] Endpoint para leer datos del bar (Nombre, Logo, Redes, Ubicación).
  - [ ] Endpoint para listar el catálogo de productos y variantes.
  - [ ] Validación de estado: Mostrar "Cerrado" si la Caja no está abierta.
- [ ] **Generación de QR**
  - [ ] Generación automática de link basado en el `slug` del bar.

---

## Módulo 7: Auditoría y Trazabilidad (Ojo de Halcón)
*Seguridad y registro histórico de acciones.*

- [ ] **Sistema de Logs**
  - [ ] Registro de cada acción relevante (Quién, qué, cuándo, rol, módulo).
  - [ ] Guardado de "Payload" (Datos anteriores y nuevos) en formato JSON.
- [ ] **Consultas de Auditoría**
  - [ ] Endpoints con filtros por fecha, usuario, rol y tipo de acción.

---

## Módulo 8: Estadísticas y Business Intelligence
*Visualización de datos para la toma de decisiones.*

- [ ] **Métricas de Rendimiento**
  - [ ] Ingresos totales por periodo/turno.
  - [ ] Cálculo de comisiones totales pagadas.
- [ ] **Rankings y Análisis**
  - [ ] Top 10 productos más vendidos (volumen/dinero).
  - [ ] Bottom de productos (menor rotación).
  - [ ] Ranking de productividad de Damas de compañía.
  - [ ] Análisis de horas pico y comparativa de turnos.

---

## Módulo 9: Frontend (Flutter)
*Interfaz de usuario premium para todos los roles.*

- [ ] **Core App**
  - [ ] Configuración inicial de Flutter Multiplataforma.
  - [ ] Implementación de Modo Oscuro "Premium".
  - [ ] Sistema de Localización (Formateo de moneda y fecha según configuración del bar).
- [ ] **Vistas por Rol**
  - [ ] Dashboard SuperAdmin (Gestión de Bares).
  - [ ] Dashboard Bar Admin (Configuración, Roles, Personal, Estadísticas).
  - [ ] Interfaz de Venta Rápida (Barman).
  - [ ] Dashboard Dama de Compañía (Comisiones en tiempo real).
  - [ ] Vista de Menú QR (PWA Pública).
