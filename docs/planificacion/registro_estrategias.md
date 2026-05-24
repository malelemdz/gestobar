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


## Bases de Datos Locales (Compatibilidad Android 16KB Pages)

### ❌ Estrategia Fallida: Isar / ObjectBox / SQLite (con dependencias binarias)
Inicialmente consideramos Isar Database para persistencia local. Sin embargo, a partir de 2026 Google Play exige compatibilidad estricta con 16KB memory pages en la arquitectura arm64. Muchas librerías basadas en C/C++ inyectan binarios `.so` precompilados antiguos que fallan catastróficamente o generan graves advertencias de compatibilidad.

### ✅ Estrategia Exitosa: Hive (Puro Dart)
Cambiamos inmediatamente a **Hive**. Al ser una base de datos local Key-Value estructurada 100% en puro Dart, funciona de forma inmaculada sobre páginas de memoria de 16KB sin requerir NDK ni binarios de C++. Esto evita por completo advertencias de Google Play y asegura una estabilidad a futuro.

## Generación de Íconos Adaptativos en Android

### ❌ Estrategia Fallida: flutter_launcher_icons v0.13.1 + Parches de Transparencia
En Android, la versión `0.13.1` aplicaba un auto-cropping muy agresivo eliminando los márgenes transparentes, lo que causaba que el logo se deformara y ampliara. Intentamos inyectar píxeles de 1% de opacidad en las esquinas de la imagen como "anclaje", lo cual resultó ser un parche sucio.

### ✅ Estrategia Exitosa: flutter_launcher_icons v0.14.3+
Se procedió a igualar la dependencia con una aplicación exitosa previa (*Restaurafy*) actualizando a la versión `v0.14.3`. Esta versión moderna respeta nativamente el padding transparente de los iconos adaptativos sin necesidad de alterar los assets con scripts externos, resolviendo la deformación visual de raíz.

---

## 6. Saneamiento de Datos, WS y Tubería de Imágenes (24-05-2026)

### Saneamiento de Base de Datos y Prevención de Duplicados en Tarifas
*   **❌ Estrategia Fallida (Seeding Forzado):** Sembrar tarifas fijas (`General` y `Compañía` con acento) en cada ciclo de arranque del semilla sin verificar tarifas preexistentes. Esto resultó en que el bar tuviera dos tarifas configuradas como "default" simultáneamente en la base de datos, desasociando el bar de su tarifa de compañía original y causando un colapso total (`500 Internal Server Error`) al cargar la pantalla de Ajustes.
*   **✅ Estrategia Exitosa:** 
    1. Desarrollar y ejecutar un script manual Node/pg de saneamiento en caliente para restaurar el bar apuntándolo a su tarifa original `Compania` y marcar `Normal` como el único default.
    2. Optimizar y blindar la lógica en `seed.service.ts` para que se apegue estrictamente a la regla de oro: **nunca sembrar tarifas secundarias**, únicamente la tarifa default `Normal` si el bar carece de ella, realizando búsquedas puramente pasivas para comisiones y compañoneras.
*   **Lección:** En entornos de base de datos relacionales con reglas lógicas estrictas (ej. un único default), el seeding debe ser condicional y de solo lectura si la base de datos ya contiene registros del cliente.

### Tubería y Carga de Imágenes en Flutter
*   **❌ Estrategia Fallida (Rutas Relativas en Mobile):** Almacenar rutas de subida relativas (ej. `/uploads/productos/uuid.webp`) y cargarlas directamente en el dispositivo móvil usando `Image.network(url)`. El framework no sabe a qué host IP pertenece el recurso, resultando en fallos masivos de carga e iconos rotos.
*   **✅ Estrategia Exitosa:** Diseñar un resolvedor dinámico `ApiConstants.resolveImageUrl()` en el frontend. Si la ruta es relativa, automáticamente le concatena el `baseUrl` del servidor NestJS según el entorno operativo de ejecución (ej. detectando `10.0.2.2` en Android Emulator o `localhost` en simuladores de iOS/macOS).
*   **Lección:** Mobile y Web manejan la resolución de IPs locales de manera distinta. Los activos subidos localmente siempre deben ser resueltos con ayudantes sensibles al entorno de red.

### Vista Previa de Carga de Archivos
*   **❌ Estrategia Fallida (Feedback Lento):** Esperar a que la petición multipart de red finalice y devuelva la URL del servidor para recién pintar la imagen en el contenedor. Esto resultaba en una experiencia de usuario lenta y propensa a incertidumbres.
*   **✅ Estrategia Exitosa (Latencia Cero):** Capturar instantáneamente la ruta del archivo local del dispositivo (`_localImagePath`) al seleccionarlo con `ImagePicker` y renderizarlo inmediatamente con `Image.file(File(_localImagePath))` acompañado de una máscara de carga translúcida y un spinner en lo que la red finaliza.
*   **Lección:** Ofrecer feedback visual instantáneo (latencia cero) al usuario mediante previsualizaciones locales hace que la aplicación se sienta sumamente premium y receptiva, aun en condiciones de redes móviles lentas.

### Optimización y Redimensionamiento en Servidor
*   **❌ Estrategia Fallida (Solo Conversión WebP):** Convertir las fotos a formato WebP pero conservar sus dimensiones físicas intactas. Si un usuario subía una foto en 4K (4000x3000px) de varios megabytes, el servidor sufría picos de memoria y el archivo seguía siendo innecesariamente grande.
*   **✅ Estrategia Exitosa (Sharp Resize):** Inyectar `.resize({ width: 800, height: 800, fit: 'inside', withoutEnlargement: true })` en la tubería de compresión de `uploads.service.ts` antes de generar el WebP. Esto estandariza las imágenes a una escala ideal para pantallas móviles y web, reduciendo el peso de almacenamiento a menos del 10% del original sin pérdidas visuales apreciables.
*   **Lección:** El servidor debe actuar como un filtro activo de optimización de recursos, impidiendo que fotos crudas de cámaras modernas degraden el rendimiento del almacenamiento y la transferencia de datos.
