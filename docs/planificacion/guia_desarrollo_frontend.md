# Guía de Desarrollo Frontend (Flutter) - Gestobar POS & SaaS

Esta guía detalla la arquitectura, el diseño de la interfaz de usuario, la navegación adaptativa y la integración con nuestro backend multi-tenant para la aplicación **Flutter nativa (diseñada específicamente para dispositivos móviles y tablets Android / iOS)** de **Gestobar**. 

Este documento sirve como plano de ingeniería para trasladar y relocalizar los diseños HTML interactivos existentes en la carpeta `docs/diseno-front` a un sistema modular y moderno en Flutter.

---

## 🎨 1. Sistema de Diseño Adaptativo y Paleta de Colores

Para responder al entorno del bar y a las preferencias de los administradores, la interfaz implementa un **Doble Tema** (Claro y Oscuro) optimizado para pantallas táctiles de móviles y tablets, mapeando píxel por píxel la configuración estética del bar.

### Paletas de Colores Armonizadas (Extracto HTML de Referencia)

| Elemento | 🌙 Modo Oscuro (Midnight Gold - Default Bar Night) | ☀️ Modo Claro (Golden Slate - Turno de Día) |
| :--- | :--- | :--- |
| **Fondo de la App** | `#181309` (Negro dorado medianoche / `background`) | `#F8F9FA` (Gris slate claro / `background`) |
| **Fondo de Contenedor** | `#241F14` (`surface-container`) | `#EDEEEF` (`surface-container`) |
| **Superficie de Tarjetas (Cards)** | `#2F291E` (`surface-container-high`) | `#FFFFFF` (`surface-container-lowest`) |
| **Bordes y Contornos** | `#504532` (`outline-variant`) | `#D4C5AB` (`outline-variant`) |
| **Color Primario (Accent)** | `#FBBC00` (Oro ámbar brillante / `primary-fixed-dim`) | `#795900` (Ámbar oscuro / `primary`) |
| **Color Secundario** | `#43DDE6` (Cian neón / `secondary`) | `#006A65` (Verde azulado / `secondary`) |
| **Texto Principal** | `#EDE1D0` (Crema cálido / `on-surface`) | `#191C1D` (Carbono oscuro / `on-surface`) |
| **Texto Secundario** | `#D4C5AB` (Gris arena / `on-surface-variant`) | `#504532` (Marrón suave / `on-surface-variant`) |
| **Caja Abierta (Éxito)** | `#10B981` (Verde esmeralda) | `#059669` (Verde oscuro) |
| **Caja Cerrada (Peligro)** | `#EF4444` (Rojo carmesí) | `#DC2626` (Rojo intenso) |

### Sistema Tipográfico (Tipografías y Tamaños)
*   **Fuentes del Sistema**:
    *   `Plus Jakarta Sans` (Google Fonts): Para títulos y encabezados de alta jerarquía, otorgando un carácter distintivo e innovador.
    *   `Inter` (Google Fonts): Para textos descriptivos, etiquetas de botones y números/denominaciones del POS.
*   **Escalas y Pesos en Flutter (`TextStyle`)**:
    *   **`display-lg`**: `48.0` logical pixels (lineHeight `1.16` (`56.0/48.0`), letterSpacing `-0.02`, `FontWeight.w700`) - Usado para montos de dinero principales y totales de caja.
    *   **`headline-lg`**: `32.0` logical pixels (lineHeight `1.25`, letterSpacing `-0.02`, `FontWeight.w700` / `w600`) - Títulos de páginas principales.
    *   **`headline-md`**: `24.0` logical pixels (lineHeight `1.33`, letterSpacing `-0.01`, `FontWeight.w600`) - Títulos de componentes y widgets bento.
    *   **`headline-sm`**: `20.0` logical pixels (lineHeight `1.40`, `FontWeight.w600`) - Nombres de tragos y productos en tarjetas.
    *   **`body-lg`**: `18.0` logical pixels (lineHeight `1.55` (`28.0/18.0`), `FontWeight.w400`) - Texto de cuerpo extendido.
    *   **`body-md`**: `16.0` logical pixels (lineHeight `1.50` (`24.0/16.0`), `FontWeight.w400`) - Textos estándar generales.
    *   **`label-lg`**: `14.0` logical pixels (lineHeight `1.42` (`20.0/14.0`), letterSpacing `0.02`, `FontWeight.w600`) - Botones e indicadores rápidos.
    *   **`label-sm`**: `12.0` logical pixels (lineHeight `1.33` (`16.0/12.0`), letterSpacing `0.04`, `FontWeight.w600`) - Badges de estado e información secundaria.

### Espaciados y Grid Layout
*   **`xs`**: `4.0` px | **`base`**: `8.0` px | **`sm`**: `12.0` px | **`margin-mobile` / `gutter`**: `16.0` px.
*   **`md`**: `24.0` px | **`lg`**: `40.0` px | **`xl`**: `64.0` px.
*   **Área de Toque Mínima (Touch Target)**: Mínimo `48.0` px de altura/anchura para asegurar operatividad táctil impecable en barras oscuras y con movimiento continuo.

---

## 🏗️ 2. Arquitectura de Software en Flutter

Recomendamos utilizar una arquitectura limpia dividida por características (**Feature-First Architecture**), gestionada reactivamente mediante **Riverpod (con Generación de Código)** para un excelente manejo de estados y flujos en tiempo real (WebSockets).

### Estructura de Carpetas

```bash
lib/
├── core/
│   ├── constants/         # URLs de API, claves de almacenamiento local
│   ├── theme/             # Doble tema (DarkTheme/LightTheme), inputs y bordes
│   ├── network/           # Cliente HTTP (Dio) con interceptores de Tenant (Bar-ID + JWT)
│   ├── websocket/         # Cliente WebSockets (socket_io_client) y StreamProviders
│   ├── storage/           # Almacenamiento seguro de credenciales (Flutter Secure Storage)
│   └── utils/             # Helpers de dispositivos, formatos de moneda local
├── features/
│   ├── auth/              # Login, Splash Screen, Selección de Bar (Tenant)
│   ├── menu_publico/      # Visualizador de Menú QR (Público, sin login, optimizado para Web)
│   ├── caja/              # Terminal POS, Apertura/Cierre de Caja, Billeteo
│   ├── damas/             # Panel en tiempo real de Comisiones e Invitaciones (Móvil)
│   └── admin/             # Dashboards de BI, Gestión de Usuarios, Productos y Auditoría
└── main.dart
```

---

## 🗺️ 3. Estrategia de Navegación Adaptativa (Sidebar vs. Bottom AppBar)

Para maximizar la experiencia táctil, la navegación se reestructura dinámicamente según el tamaño de la pantalla (Móvil vs. Tablet/Escritorio) y la cantidad de opciones del rol, mapeando directamente las interfaces HTML del folder `docs/diseno-front`.

```
                  +---------------------------+
                  |     Pantalla de Login     |
                  +-------------+-------------+
                                | (JWT Decoded)
                                v
                  +-------------+-------------+
                  |    Enrutador de Layout    |
                  +------+-------------+------+
                         |             |
        (Pantalla < 600px - Móvil)     (Pantalla >= 600px - Tablet/PC)
                         v             v
        +-----------------------+     +-----------------------+
        |   Layout Móvil        |     |   Layout Tablet/PC    |
        |   - Pocas Opciones:   |     |   - Sidebar Fijo      |
        |     Bottom Navigation |     |     Colapsable Izq.   |
        |   - Muchas Opciones:  |     |   - Panel Multicolumna|
        |     Drawer Lateral    |     |     Sincronizado      |
        +-----------------------+     +-----------------------+
```

### Reglas de Implementación en Flutter

1.  **Móvil (Mobile - Teléfono)**:
    *   **Pocas Opciones (≤ 4 ítems, ej: Rol Dama o Cliente QR)**: Implementar un **Bottom Navigation Bar** minimalista con efecto glassmorphic translúcido.
    *   **Muchas Opciones (Cajeros o Administradores)**: Evitar saturar la barra inferior. En su lugar, se implementará un **Drawer Lateral Colapsable** para navegación general y **Bottom Sheets Contextuales** emergentes para acciones rápidas (ej. seleccionar métodos de pago o buscar damas).
2.  **Tablet & Escritorio (Tablet/Large Screens - ≥ 600px)**:
    *   La navegación muta automáticamente a una **Sidebar Lateral Fija Colapsable** en el lado izquierdo.
    *   Esto permite aprovechar el espacio horizontal, mostrando la navegación a la izquierda y el espacio de trabajo principal a la derecha, en concordancia directa con los mockups del folder `_tablet` (ej. `punto_de_venta_tablet` o `administracion_de_usuarios_tablet`).
    *   Se utilizará el widget `NavigationRail` de Flutter o un custom widget sidebar responsive basado en `LayoutBuilder`.

---

## 📱 4. Reubicación del Diseño HTML (`docs/diseno-front` ➡️ Flutter)

Cada carpeta de diseño HTML tiene un mapeo de correspondencia directa en Flutter, aplicando adaptabilidad móvil y tablet:

### 📌 A. Módulo Menú QR Público (`gesti_n_de_men` y `_tablet`)
*   **Página HTML de Referencia**: `docs/diseno-front/gesti_n_de_men/`
*   **Mapeo Flutter**: PWA optimizada para navegadores móviles.
*   **Adaptabilidad**:
    *   *Móvil*: Tarjetas de producto en grid vertical de 1 columna con scrolling vertical fluido.
    *   *Tablet*: Grid de productos de 2 o 3 columnas con sidebar derecho de visualización de información del bar.
    *   **Seguridad**: El frontend lee la respuesta sanitizada del backend para asegurar que el `precio_b` (damas) no exista en la carta del cliente.

### 📌 B. Terminal POS, Billeteo y Turnos (`caja_y_turno` y `punto_de_venta_con_fotos_mobile` / `_tablet`)
*   **Páginas HTML de Referencia**: `caja_y_turno/`, `caja_y_turno_modo_claro/`, `punto_de_venta_con_fotos_mobile/` y `punto_de_venta_tablet/` (claro/oscuro).
*   **Mapeo Flutter**: Panel del Cajero POS.
*   **Estrategia de Pantalla Dividida (Split Screen en Tablet)**:
    *   *Móvil*: Pantallas secuenciales. Pantalla 1: Grilla de productos. Al seleccionar productos y dar "Pagar", navega a la Pantalla 2 (Carrito y selección de Dama / Invitación).
    *   *Tablet*: **Una sola vista unificada (Split Screen)**. La mitad izquierda muestra la grilla interactiva de botellas/bebidas categorizadas; la mitad derecha muestra el carrito de venta con botones táctiles para asignar la Dama (`dama_id`) y seleccionar el método de pago instantáneo.
*   **Billeteo (Cash Count)**: Teclado táctil adaptado para ingresar cantidades físicas de billetes de forma rápida en la apertura y cierre de caja.

### 📌 C. Panel Real-Time de Damas
*   **Mapeo Flutter**: Pantalla de consulta de ingresos para damas (diseño móvil premium).
*   **Métrica Principal**: Gran indicador luminoso en la parte superior con el saldo acumulado de comisiones de la noche.
*   **WebSockets**: Escucha en tiempo real. Cuando el backend emite `comision_notificar`, Flutter reproduce un sonido sutil, activa una micro-vibración y despliega un banner pop-up animado con la copa o botella invitada.

### 📌 D. Panel Admin, Gestión de Usuarios y BI (`administraci_n_de_usuarios` y `_tablet`)
*   **Páginas HTML de Referencia**: `administraci_n_de_usuarios/` y `administraci_n_de_usuarios_tablet/`.
*   **Mapeo Flutter**: Consola administrativa.
*   **Adaptabilidad**:
    *   *Móvil*: Listados colapsables con tarjetas de usuarios.
    *   *Tablet*: Tabla interactiva con ordenación, barra de búsqueda en cabecera y panel derecho flotante de detalles y edición rápida al seleccionar una fila.
    *   **Gráficos**: Uso de librerías nativas (`fl_chart`) para renderizar gráficos de líneas de ingresos y círculos de métodos de pago en modo claro u oscuro según la preferencia del administrador.

---

## ⚡ 5. Estrategia de Conectividad y Resiliencia (Offline First)

Dado que las redes en locales nocturnos pueden ser inestables, el frontend en Flutter implementará:

1.  **Caché Local Segura (Hive / Sembast)**: La carta de productos y categorías se cacheará localmente. El menú QR se cargará instantáneamente aunque la red fluctúe, sincronizándose en segundo plano.
2.  **Reconexión Automática WebSockets**: El cliente de socket_io_client configurará un sistema de reconexión exponencial para asegurar que las Damas vuelvan a escuchar notificaciones en tiempo real al recuperar cobertura.
3.  **Cola de Peticiones en Espera**: Si el cajero registra una venta en un micro-corte de red, la app mostrará un spinner con timeout amigable en lugar de crashear, reintentando la transacción de forma segura.

---

## 🚀 6. Siguientes Pasos de Implementación Frontend

Para avanzar de forma ágil y coordinada, dividiremos el frontend en fases incrementales de desarrollo:

*   [ ] **Fase 1: Core, Temas y Auth**: Configuración del cliente Dio, interceptor de Tenant, almacenamiento seguro (Credenciales), y definición del Doble Tema (Claro/Oscuro) en Flutter.
*   [ ] **Fase 2: Menú QR Público**: PWA responsive optimizada para móvil y tablet (Sanitizada).
*   [ ] **Fase 3: Terminal POS e Inyección de Cajas (Layout Adaptativo)**: Layout de Split Screen para tablets e interactivo secuencial para móvil. Flujo de arqueo y billeteo.
*   [ ] **Fase 4: Panel Real-Time Damas**: Integración de WebSockets, banners de comisiones e invitaciones en tiempo real con micro-vibración y sonidos.
*   [ ] **Fase 5: Dashboard BI & Auditoría**: Integración de gráficos interactivos adaptados a claro/oscuro y visor Ojo de Halcón.

