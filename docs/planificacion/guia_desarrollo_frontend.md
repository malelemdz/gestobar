# Guía de Desarrollo Frontend (Flutter) - Gestobar POS & SaaS

Esta guía detalla la arquitectura, el diseño de la interfaz de usuario, la navegación por roles y la integración con nuestro backend multi-tenant para la aplicación Flutter de **Gestobar**. 

Dado que el backend y el frontend madurarán juntos, este documento sirve como plano de ingeniería inicial para guiar el desarrollo incremental del cliente móvil y PWA.

---

## 🎨 1. Sistema de Diseño y Estética Premium

Para un entorno nocturno y dinámico como un bar, la interfaz debe sentirse sumamente premium, viva y táctil.

### Paleta de Colores (Aesthetic Dark Mode)
*   **Fondo de la App (`Background`)**: `#0F0C1B` (Negro medianoche con un sutil matiz violeta).
*   **Superficies (`Cards/Modals`)**: `#17132B` (Violeta oscuro traslúcido, estilo glassmorphism).
*   **Color Primario (`Accent`)**: `#FFB800` (Oro ámbar vibrante para botones de acción principal, dinero y comisiones).
*   **Color Secundario**: `#A855F7` (Púrpura neón para detalles de entretenimiento, damas e invitaciones).
*   **Alertas / Estados**:
    *   *Éxito / Caja Abierta*: `#10B981` (Verde esmeralda).
    *   *Peligro / Caja Cerrada*: `#EF4444` (Rojo carmesí).
    *   *Advertencia / Descuadre*: `#F59E0B` (Naranja ámbar).

### Tipografía y Componentes Táctiles
*   **Fuente Principal**: `Outfit` o `Space Grotesk` (Google Fonts) para un estilo moderno, audaz y geométrico.
*   **Micro-animaciones**: Utilización de transiciones fluidas de escala al hacer clic en productos, y partículas animadas cuando una Dama recibe una comisión en tiempo real.
*   **Teclado Numérico Tactil (POS & Billeteo)**: Botones grandes y redondos con feedback háptico en dispositivos móviles para minimizar errores humanos del cajero.

---

## 🏗️ 2. Arquitectura de Software en Flutter

Recomendamos utilizar una arquitectura limpia dividida por características (**Feature-First Architecture**), gestionada reactivamente mediante **Riverpod (con Generación de Código)** para un excelente manejo de estados y flujos en tiempo real (WebSockets).

### Estructura de Carpetas

```bash
lib/
├── core/
│   ├── constants/         # URLs de API, claves de almacenamiento local
│   ├── theme/             # Paleta de colores, estilos de texto, inputs
│   ├── network/           # Cliente HTTP (Dio) con interceptores multi-tenant (JWT + Bar-ID)
│   ├── websocket/         # Cliente WebSockets (socket_io_client) y StreamProviders
│   ├── storage/           # Almacenamiento seguro de credenciales (Flutter Secure Storage)
│   └── utils/             # Formateadores de moneda, helpers de dispositivos
├── features/
│   ├── auth/              # Login, Splash Screen, Selección de Bar (Tenant)
│   ├── menu_publico/      # Visualizador de Menú QR (Público, sin login, optimizado para Web)
│   ├── caja/              # Terminal POS, Apertura/Cierre de Caja, Billeteo
│   ├── damas/             # Panel en tiempo real de Comisiones e Invitaciones (Móvil)
│   └── admin/             # Dashboards de BI, Gestión de Usuarios, Productos y Auditoría
└── main.dart
```

---

## 👥 3. Flujos de Pantalla y Navegación por Roles

La aplicación de Flutter cargará dinámicamente el panel de inicio correspondiente según el rol decodificado en el payload del JWT tras el login exitoso.

```
                  +-----------------------+
                  |   Pantalla de Login   |
                  +-----------+-----------+
                              | (JWT Decoded)
                              v
                  +-----------+-----------+
                  |  Enrutador por Rol    |
                  +-----+-----+-----+-----+
                        |     |     |
      +-----------------+     |     +-----------------+
      | (CLIENTE / QR)        | (CAJERO)              | (DAMA)
      v                       v                       v
+-----+---------------+ +-----+---------------+ +-----+---------------+
|  Menú QR Público    | |   Terminal POS      | | Panel Real-Time de  |
|  (Web/PWA)          | |   y Turnos de Caja  | | Comisiones (Móvil)  |
+---------------------+ +---------------------+ +---------------------+
                                                      ^
                                                      | (ADMIN / SUPERADMIN)
                                                      v
                                                +-----+---------------+
                                                |  Estadísticas BI,   |
                                                |  Users & Auditoría  |
                                                +---------------------+
```

---

## 📱 4. Mapeo de Módulos (Backend ➡️ Frontend)

### 📌 Módulo A: El Menú QR Público (`/menu/:slug`)
*   **Objetivo**: PWA ultra-ligera y responsive para clientes de la mesa del bar.
*   **Rutas Backend Consumidas**: `GET /menu/:slug/productos` y `GET /menu/:slug/bar-info`.
*   **Características Clave**:
    *   **Cero Login**: Acceso inmediato al escanear el QR.
    *   **Sanitización Absoluta**: Oculta por completo el precio de compañía (`precio_b`), mostrando únicamente el `precio_a` como el precio general del producto.
    *   **Diseño Visual**: Tarjetas visuales de tragos y botellas, filtros por categorías con desplazamiento horizontal fluido.

### 📌 Módulo B: Terminal POS y Flujo de Cajas (`/cajas` y `/ventas`)
*   **Objetivo**: El centro de control operativo del cajero del bar.
*   **Rutas Backend Consumidas**: `GET /cajas/estado`, `POST /cajas/apertura`, `POST /cajas/cierre`, `POST /ventas`.
*   **Pantallas del Flujo**:
    1.  **Pantalla de Control de Turno**:
        *   Muestra el estado de la caja ("Abierta" o "Cerrada").
        *   *Apertura*: Calculadora táctil de denominación de billetes para registrar el `monto_inicial`.
        *   *Cierre*: Formulario de arqueo físico. Al cerrar, despliega en tiempo real la comparativa de ingresos por método de pago y el **descuadre / diferencia monetaria** exacta antes de confirmar.
    2.  **Parrilla de Ventas (POS)**:
        *   Grilla de productos categorizados. Al tocar una botella/trago, se despliega una modal rápida para elegir la **Variante** ("Copa", "Botella", "Media Botella").
        *   **Selector de Tipo de Venta**:
            *   *Venta Normal*: Botón estándar de checkout.
            *   *Compañía (Precio B)*: Selector de Dama de compañía obligatorio (`dama_id`). Calcula automáticamente la comisión correspondiente parametrizada en el bar.
            *   *Invitación*: Selector de Dama obligatorio. Establece precio en A y comisión en 0 de forma blindada.
        *   **Método de Pago**: Botones rápidos (Efectivo, Tarjeta, QR, Transferencia).

### 📌 Módulo C: Panel en Tiempo Real para Damas
*   **Objetivo**: Aplicación móvil para que el personal de entretenimiento consulte sus ingresos al instante sin tener que interrumpir al cajero.
*   **Rutas Backend Consumidas**: `GET /ventas/comisiones`.
*   **Canal WebSockets (Socket.IO)**: Escucha el evento `comision_notificar` canalizado al ID de la dama activa.
*   **Características Clave**:
    *   **Notificación Push / Pop-up In-App**: *"¡Te han invitado una copa de Tequila!"* o *"¡Has ganado 50 USD de comisión!"*.
    *   **Historial de Comisiones**: Tarjetas interactivas que detallan la hora, el producto vendido, el tipo (comisión o invitación) y la moneda local configurada.
    *   **Contador Acumulado**: Indicador gigante y brillante en la parte superior con el saldo total ganado durante el turno actual de la caja.

### 📌 Módulo D: Consola de Administración y Business Intelligence
*   **Objetivo**: Tablero gerencial para el dueño del bar o administradores generales.
*   **Rutas Backend Consumidas**: `GET /estadisticas/resumen`, `GET /estadisticas/ranking-productos`, `GET /estadisticas/ranking-damas`, `GET /estadisticas/caja/:id`, `GET /auditoria`.
*   **Características Clave**:
    *   **Filtro de Calendario**: Selector interactivo de rangos de fechas (últimos 7 días, este mes, personalizado).
    *   **Métricas BI Visuales**: Gráficos circulares de métodos de pago y de ingresos vs comisiones pagadas.
    *   **Monitoreo Ojo de Halcón**: Visor de logs con barra de búsqueda rápida y filtros por usuario, rol y acción. Permite verificar las IP de conexión y el tipo de dispositivo de cada cajero (ej. *"Cajero 1 abrió caja desde Chrome en Windows en IP 192.168.1.100"*).

---

## ⚡ 5. Estrategia de Conectividad y Resiliencia (Offline First)

Dado que las redes en locales nocturnos pueden ser inestables, el frontend en Flutter implementará:

1.  **Caché Local Segura (Hive / Sembast)**: La carta de productos y categorías se cacheará localmente. El menú QR se cargará instantáneamente aunque la red fluctúe, sincronizándose en segundo plano.
2.  **Reconexión Automática WebSockets**: El cliente de socket_io_client configurará un sistema de reconexión exponencial para asegurar que las Damas vuelvan a escuchar notificaciones en tiempo real al recuperar cobertura.
3.  **Cola de Peticiones en Espera**: Si el cajero registra una venta en un micro-corte de red, la app mostrará un spinner con timeout amigable en lugar de crashear, reintentando la transacción de forma segura.

---

## 🚀 6. Siguientes Pasos de Implementación Frontend

Para avanzar de forma ágil y coordinada, dividiremos el frontend en fases incrementales de desarrollo:

*   [ ] **Fase 1: Core & Auth**: Configuración del cliente Dio, interceptores de Tenant, Splash Screen, almacenamiento seguro y pantalla de login.
*   [ ] **Fase 2: Menú QR Público**: PWA optimizada para navegador móvil que consuma la carta digital sanitizada.
*   [ ] **Fase 3: Terminal POS e Inyección de Cajas**: Pantalla de apertura/cierre de turnos y grilla interactiva de registro de ventas con selector de Damas.
*   [ ] **Fase 4: Panel Real-Time Damas**: Integración de WebSockets para notificaciones y visor de comisiones acumuladas.
*   [ ] **Fase 5: Dashboard BI & Auditoría**: Gráficos interactivos de analíticas de negocio y visor de logs del Módulo de Auditoría.
