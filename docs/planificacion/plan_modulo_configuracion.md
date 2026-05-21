# Plan de Desarrollo: Módulo de Configuración Global (Tenant)

La Configuración del Bar es el módulo fundacional del proyecto. Las variables definidas aquí (como la Moneda, la Zona Horaria y las Reglas de Negocio) determinan el comportamiento de todos los demás módulos (POS, Caja y Menú QR).

---

## 1. Estado Actual (Diagnóstico)
*   **Backend:** La base de datos ya cuenta con la entidad `Bar` estructurada con casi todos los campos requeridos (`nombre`, `timezone`, `moneda_simbolo`, `facebook`, `whatsapp`, etc.).
*   **Frontend:** El archivo `config_page.dart` es actualmente un *placeholder* (pantalla vacía con un ícono). No existe UI ni conexión con la API para editar estos datos.

---

## 2. Objetivos del Desarrollo

### Backend (Actualización de API)
1.  **Nuevas Variables de Negocio:** Actualizar la entidad `Bar` para incluir los campos del nuevo módulo de damas (`modulo_damas_activo`, `comision_porcentaje`, `tarifa_compania_id`).
2.  **Endpoint de Actualización:** Asegurar que el endpoint `PATCH /bars/:id` permita recibir de manera segura actualizaciones de todos estos campos desde el cliente (con validaciones estrictas de DTO).
3.  **Gestión del Logo:** Permitir que el logo del bar pueda ser actualizado.

### Frontend (Panel de Configuración `config_page.dart`)
Se diseñará un panel "Liquid Modernist" dividido en tarjetas (Bento Cards) agrupando las configuraciones lógicamente.

*   **Sección 1: Identidad Visual**
    *   Nombre del Bar.
    *   URL del Logo / Foto de Perfil.
*   **Sección 2: Localización y Formatos (¡Crítico!)**
    *   Zona Horaria (Timezone IANA, ej. `America/Santiago`).
    *   Símbolo de Moneda (ej. `$`, `€`, `S/`).
    *   Código ISO Moneda (ej. `USD`, `CLP`, `PEN`).
*   **Sección 3: Contacto y Presencia Pública (Menú QR)**
    *   WhatsApp de Reservas.
    *   Link de Google Maps.
    *   Redes Sociales (Instagram, TikTok, Facebook).
*   **Sección 4: Reglas de Negocio (Módulo de Damas)**
*   **Sección 5: Horarios de Atención**
    *   Configuración independiente para cada día de la semana (Lunes a Domingo).
    *   Toggle para indicar si el bar abre o cierra ese día.
    *   Selectores de hora de apertura y cierre (permitiendo cierres en la madrugada del día siguiente).
*   **Sección 6: Sistema de Almacenamiento (Subidas)**
    *   Módulo de backend con `sharp` para interceptar imágenes de perfil, logos y productos.
    *   Compresión automática a formato `.webp` de alta eficiencia (calidad 80%).
    *   Almacenamiento persistente en disco (carpeta `/uploads`) diseñado para uso con volúmenes físicos en Docker/Coolify.
*   **Medidas de Seguridad Adicionales**
    *   Zonas críticas (Zona Horaria y Moneda) utilizarán *Dropdowns*.
    *   Modificar Zona Horaria o Moneda exigirá una doble confirmación tecleando "CONFIRMAR".

---

## 3. Flujo de Trabajo (Tareas)

1.  **Fase 1 (Backend - Storage & Core):** Inyectar los campos del Módulo de Damas en la DB (`Bar.entity.ts`). Crear el `UploadsModule` con `multer` y `sharp` para procesar imágenes.
2.  **Fase 2 (Frontend - Providers):** Crear el repositorio y *Riverpod provider* en Flutter para consumir el estado del Bar actual (usando el `barId` encriptado en el token de sesión). Añadir `image_picker` a dependencias.
3.  **Fase 3 (Frontend - UI Mobile-First):** Construir la interfaz de formularios reactivos (`config_page.dart`) segmentada en Bento Cards. 
    *   Implementar diseño adaptativo estricto para *Horarios* y evitar *Overflow*.
    *   Añadir marcas de agua `https://` en links.
    *   Crear selector de imágenes conectado al `UploadsModule`.
4.  **Fase 4 (Integración y Pruebas):** Guardar configuraciones y verificar que se reflejen de forma global en la aplicación. Subir un logo desde dispositivo móvil y confirmar su compresión a `.webp`.
