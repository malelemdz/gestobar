# Arquitectura y Reglas de Negocio: Refactorización POS y Módulo de Damas

Este documento define la reestructuración completa del sistema de ventas (POS) para soportar configuraciones dinámicas de precios (múltiples tarifas), simplificando drásticamente el proceso de cobro en barra y modularizando la lógica de Damas de Compañía para que sea una característica opcional por bar.

---

## 1. Reglas de Negocio: El Flujo del Ticket (POS)

Para maximizar la velocidad de atención en un entorno ruidoso de bar, el sistema no manejará mesas ni sectores. Todo operará de manera directa sobre el **Carrito / Ticket de Venta** manejado en el estado actual (como se hace actualmente, pero sumando los nuevos requerimientos).

1.  **Agregación Rápida:** El cajero toca las bebidas en el catálogo y se añaden instantáneamente al ticket utilizando el precio de la *Tarifa Normal / Por Defecto*.
2.  **Configuración Global del Ticket (Compañía):** 
    *   Una vez que los ítems están en el ticket, si el cliente está con compañía, el cajero despliega el carrito y **selecciona a la Dama a nivel global del ticket**.
    *   *Efecto Automático:* Todos los ítems del ticket cambian instantáneamente al **Precio de Compañía**.
    *   *Ganancia:* Todo ítem bajo este precio genera una comisión para esa Dama (calculada mediante el porcentaje configurado en el bar).
3.  **Excepciones (Tragos Invitados):**
    *   Dentro de este mismo ticket (que ya está a precio de compañía), el cajero puede marcar tragos específicos como **"Invitación"**. (Ejemplo: El cliente consume 5 cervezas, pero le invita 1 cóctel a la dama).
    *   *Efecto Automático:* El ítem marcado como "Invitación" regresa inmediatamente a la **Tarifa Normal (Precio A)**.
    *   *Ganancia:* La comisión para este ítem específico se reduce a **0%**.
    *   *Registro:* A nivel de auditoría, el sistema guarda que esa bebida fue invitada a esa Dama específica, permitiendo rastrear su productividad.

---

## 2. Configuración del Bar (Módulo Opcional)

No todos los establecimientos operan con personal de compañía. El sistema debe adaptarse a un flujo comercial tradicional si es necesario.

### Parámetros en la Entidad `Bar`
*   `modulo_damas_activo` (Boolean): Define si el sistema activa o no la lógica de compañía. Por defecto es `false`.
*   `tarifa_compania_id` (UUID): Referencia a cuál de las múltiples listas de precios creadas por el admin representa los precios inflados de compañía.
*   `comision_porcentaje` (Decimal): Porcentaje de ganancia de la dama sobre el precio de los productos (Ej: 50.00). *Nota: Este campo ya existe en el backend, pero se integrará a la nueva interfaz visual de configuración.*

### Impacto en la Interfaz (Frontend)
Si `modulo_damas_activo` es **FALSE**:
1.  El POS es un punto de venta tradicional. No hay selectores de damas ni botones de "Invitación" en el carrito.
2.  El panel de "Comisiones en Vivo" y la visualización de productividades desaparecen del menú lateral y de la App.

---

## 3. Modelo de Múltiples Precios (Tarifas)

Para soportar flexibilidad (ej: "Tarifa Normal", "Happy Hour", "VIP", "Compañía"), el catálogo migrará de un esquema estático (`precio_a`, `precio_b`) a uno relacional y escalable.

### Nuevas Entidades y Cambios en Backend
1.  **Entidad `Tarifa` (Price Profile):**
    *   `id` (UUID), `bar_id` (UUID), `nombre` (String), `es_default` (Boolean).
2.  **Entidad `VariantePrecio`:**
    *   Tabla pivote que almacena: `variante_id`, `tarifa_id` y `precio_unitario`.
    *   *Beneficio:* Una variante (Ej: "Botella de Whisky") puede tener precios distintos en N cantidad de tarifas creadas por el administrador.
3.  **Actualización de `DetalleVenta`:**
    *   Se elimina el campo estático `es_precio_b`.
    *   El detalle de venta ahora almacenará explícitamente el `precio_unitario` al momento de la venta, el `tarifa_id` aplicada, si `es_invitacion` (boolean), y el `dama_id` asociado.

---

## 4. Fases de Ejecución

*   **Fase 1 (Backend - Estructura):** Modificar la base de datos (PostgreSQL/TypeORM). Eliminar precio A/B, inyectar el módulo de `Tarifas` y `VariantePrecio`. Actualizar endpoints.
*   **Fase 2 (Backend - Ventas):** Adaptar el motor de cálculo de `VentasService` con lógica estricta de invitaciones vs compañía y validaciones multi-tenant.
*   **Fase 3 (Frontend - Configuración):** Añadir la UI para el admin (`modulo_damas_activo`, `% de comisión`, selección de tarifa).
*   **Fase 4 (Frontend - POS):** Modificar `pos_page.dart` aplicando las mecánicas de herencia en el ticket global y marcadores táctiles de "Invitación".
