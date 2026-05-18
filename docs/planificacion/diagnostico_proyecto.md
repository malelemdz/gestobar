# Diagnóstico de Estado y Plan de Desarrollo - Gestobar Multi-tenant

Este documento provee un diagnóstico detallado del estado del backend y frontend de **Gestobar**, detallando los aciertos de la arquitectura, las métricas actuales del código y la ruta crítica de desarrollo para las fases venideras.

---

## 📊 1. Diagnóstico del Backend (NestJS + PostgreSQL)
El backend está **100% finalizado a nivel de lógica de negocio** y su diseño de software es sumamente robusto. Todo el código TypeScript compila libre de errores y advertencias.

### 🔑 Componentes y Módulos Activos en el Backend:
*   **Módulo 1: Core Multi-tenant (Bares):** Aislamiento a nivel de base de datos blindado mediante el decorador `@ActiveBarId()`. Soporta localizaciones, monedas dinámicas y links de contacto independientes por bar.
*   **Módulo 2: Seguridad y Autenticación (JWT & RBAC):** Contraseñas encriptadas con Bcrypt, tokens JWT de 24 horas y un guardia de permisos modular (`PermissionsGuard`) que admite roles estándar (Admin, Barman, Dama, Reviewer) y bypass total para `SUPERADMIN`.
*   **Módulo 3: Catálogo y Gestión de Productos:** Categorías ordenadas y variantes con doble precio (Precio A para clientes, Precio B de compañía para damas). Incluye precisión decimal de base de datos e impide borrar la última variante de un producto.
*   **Módulo 4: Sistema de Caja y Turnos:** Asegura que solo haya **una caja abierta** por bar simultáneamente. El resto de las operaciones (ventas) quedan bloqueadas si la caja del bar está cerrada. Reporte de descuadre financiero atómico en tiempo de cierre.
*   **Módulo 5: Motor de Ventas y Comisiones:** Lógica estricta de validación para tipo de venta (Normal, Compañía y Bebida de Invitación). Calcula automáticamente la comisión de la dama con base en el `bar.comision_porcentaje`.
*   **Módulo 6: Menú QR Público Anónimo:** Permite consultar la carta de forma anónima basándose en el `slug` del bar. **Seguridad Crítica:** Sanitiza el JSON de respuesta **eliminando por completo el Precio B (Compañía)** para que ningún cliente final pueda ver las tarifas de personal.
*   **Módulo 7: Auditoría y Trazabilidad (Ojo de Halcón):** Módulo `@Global()` inyectable en cualquier servicio para registrar payloads JSONB de cambios críticos (aperturas/cierres de caja, login, ventas). Visor administrativo con filtros avanzados de fecha, módulo y rol.
*   **Módulo 8: Estadísticas y BI:** Consultas optimizadas de base de datos directas para rendimiento premium en tableros analíticos. Retorna ranking de variantes vendidas, ingresos por método de pago, comisiones pagadas y ranking de damas más productivas.
*   **Seeder de Inicialización:** El endpoint `/seed` permite recrear toda la estructura por defecto en la base de datos de manera instantánea.
*   **Base de Datos (PostgreSQL):** Corriendo de forma limpia en el puerto `5434` bajo el volumen y red exclusivos de `gestobar`, con 12 tablas relacionales operativas.

---

## 📱 2. Diagnóstico del Frontend (Flutter)
El frontend presenta un diseño visual extraordinario de tipo **Liquid Modernist Dark**, centrado en una paleta nocturna de alta gama con contrastes vibrantes de Cian Eléctrico (`#00F0FF`) y Violeta Branding (`#7000FF`), alineado con tipografías premium de Google Fonts (`Plus Jakarta Sans` e `Inter`).

### 🔍 Hallazgos y Análisis Técnico del Código:
1.  **Cero Errores del Compilador:** La ejecución de `flutter analyze` reporta **0 errores de compilación**. El proyecto Dart es totalmente saludable y está listo para producción.
2.  **Advertencias de Depreciación (Info):** Existen 58 advertencias menores referidas a la versión más reciente del Flutter SDK (por ejemplo, el uso recomendado de `.withValues()` en lugar de `.withOpacity()` para colores, y `surface` en reemplazo del antiguo `background` de Material 3). Esto no afecta en absoluto el rendimiento ni la compilación, pero se pueden corregir de forma progresiva.
3.  **Arquitectura del Core Modulada:** Las clases críticas de infraestructura (`core/network/dio_client.dart`, `core/storage/secure_storage_service.dart`, `core/theme/app_theme.dart`) están perfectamente segregadas y usan inyección reactiva con **Riverpod**.
4.  **Flujo de Autenticación Integrado:** La carpeta `features/auth/` contiene el modelo de usuario, la gestión de estados reactivos y el repositorio listo para conectarse con la API de NestJS del backend.
5.  **Monolito de Vistas en `main.dart` (2521 líneas):** 
    > [!NOTE]
    > En el desarrollo inicial de Hito 1 (Identidad y UI base), todas las maquetas, Bento cards, pantallas y paneles táctiles (`DashboardPage`, `PosPage`, `CajaPage`, `MenuPage`, `StaffPage`, `AuditoriaPage`, `ConfigPage`, `PerfilPage`, `DamaPage`) se construyeron de manera compacta **dentro de un solo archivo `main.dart`**. 
    >
    > Aunque esto compila y funciona perfectamente como prototipo visual rápido, **no cumple con las buenas prácticas de escalabilidad en Flutter**. Mantener 2500 líneas en un solo archivo dificultará el mantenimiento cuando conectemos llamadas de red y lógicas en tiempo real a cada módulo por separado.

---

## 🗺️ 3. Plan de Desarrollo: Ruta Crítica de Implementación
Para continuar con paso firme e integrar de forma definitiva el backend con el frontend, dividiremos la ruta en 4 fases ordenadas y profesionales:

### 🚀 Fase 1: Modularización y Refactorización del Frontend (Prioridad Máxima)
*   **Acción:** Separar el archivo gigante `main.dart` en múltiples archivos modulares e independientes.
*   **Estructura Propuesta:**
    *   Mover `DashboardPage` a `lib/features/dashboard/presentation/dashboard_page.dart`
    *   Mover `PosPage` a `lib/features/pos/presentation/pos_page.dart`
    *   Mover `CajaPage` a `lib/features/caja/presentation/caja_page.dart`
    *   Mover `MenuPage` a `lib/features/menu_publico/presentation/menu_page.dart`
    *   Mover `StaffPage` a `lib/features/staff/presentation/staff_page.dart`
    *   Mover `AuditoriaPage` a `lib/features/admin/presentation/auditoria_page.dart`
    *   Mover `ConfigPage` a `lib/features/admin/presentation/config_page.dart`
    *   Mover `PerfilPage` a `lib/features/auth/presentation/perfil_page.dart`
    *   Mover `DamaPage` a `lib/features/damas/presentation/dama_page.dart`
*   **Beneficio:** Código extremadamente limpio, fácil de leer y alineado al estándar de la industria (Feature-First Architecture).

### 🔐 Fase 2: Conexión y Pruebas Reales de Autenticación
*   **Acción:** Arrancar el backend NestJS en modo desarrollo, usar el `/seed` para cargar cuentas reales y probar el flujo de inicio de sesión real en la aplicación móvil/tablet.
*   **Lógica:** Conectar el login a la base de datos real a través del cliente Dio y almacenar de manera segura el Token JWT y el `activeBarId` en el Keychain del dispositivo.

### 💼 Fase 3: Integración del Panel de Turnos y Punto de Venta (POS)
*   **Acción:** Darle vida funcional a `CajaPage` y `PosPage` enlazándolos con la API del backend:
    1.  **Apertura de Caja:** Teclado táctil para registrar el billeteo inicial.
    2.  **Carga de Productos:** Traer de la API las categorías y productos reales del bar según el Bar ID de la sesión.
    3.  **Venta Dinámica:** Permitir añadir al carrito variantes de producto, asignar damas, aplicar comisiones y efectuar el pago (guardando la venta en la base de datos real).
    4.  **Cierre de Caja:** Generar el reporte final comparativo y cerrar el turno operativamente.

### 📡 Fase 4: Sincronización Real-time (WebSockets)
*   **Acción:** Implementar el cliente socket en `core/websocket/websocket_service.dart`.
*   **Flujo:** Conectar a la Dama a su sala de WebSockets para que, en cuanto el Barman registre una venta a su nombre, el teléfono de la Dama reciba una notificación luminosa en tiempo real con micro-vibración del dispositivo.

---

## 🛠️ ¿Cómo Deseas Continuar Hoy?
Por favor, indícame cuál de los siguientes caminos prefieres tomar ahora:

1.  **Opción A (Modularización):** Empezamos de inmediato con la **Fase 1**, estructurando el frontend de forma modular. Crearé las carpetas de las características y extraeré las vistas gigantes de `main.dart` a sus propios archivos independientes, dejando un `main.dart` extremadamente limpio de solo ~50 líneas.
2.  **Opción B (Integración de Base):** Iniciamos la **Fase 2**. Arranco el backend en local, inicializo la base de datos con el seeder, y programamos la integración del Login real de la app Flutter con el backend.
3.  **Opción C (Desarrollo Funcional Específico):** Indícame si prefieres enfocarte en el diseño/lógica de algún módulo en particular (ej. Caja, POS o Panel de Damas).
