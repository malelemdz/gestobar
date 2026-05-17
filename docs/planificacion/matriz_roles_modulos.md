# Matriz de Control de Acceso y Módulos: Gestobar

Este documento establece la arquitectura de permisos y la matriz de roles y accesos (RBAC - Role-Based Access Control) del sistema Gestobar, asegurando la separación de responsabilidades y el aislamiento estricto de los datos multi-tenant.

---

## 👥 1. Definición de Roles del Sistema

| Rol | Alcance (Scope) | Descripción Operativa |
| :--- | :--- | :--- |
| **PÚBLICO** | Sin Autenticación | Clientes finales del bar que escanean el código QR en la mesa. |
| **DAMA (Hostess / Relaciones Públicas)** | Sucursal Específica | Personal del bar que recibe comisiones por consumos pagados con "Precio B" (Compañía). |
| **BARMAN / CAJERO** | Sucursal Específica | Personal operativo encargado de cobrar, despachar bebidas, y controlar el flujo diario de caja de su turno. |
| **REVIEWER / AUDITOR** | Global o Sucursal | Rol de solo lectura para contadores externos, auditores o revisores de tiendas de aplicaciones. |
| **ADMIN / PROPIETARIO (Bar Owner)** | Sucursal(es) Específica(s) | Dueño de uno o varios bares. Control total de precios, inventarios, personal y finanzas de sus sucursales. |
| **SUPERADMIN (SaaS Owner)** | Plataforma Global | Administrador general de la infraestructura SaaS. Gestiona la creación de bares, planes de suscripción y soporte técnico. |

---

## 🏗️ 2. Módulos Funcionales del Ecosistema

1. **Módulo 1: Autenticación y Selección de Bar (SaaS Entrypoint)**
   * Registro e ingreso al sistema. Selección en caliente de la sucursal activa para usuarios con multi-propiedad (dueños).
2. **Módulo 2: Punto de Venta Táctil (Tactile POS)**
   * Grilla de productos con filtros rápidos, gestión del carrito, aplicación de doble precio (Precio A / Precio B) y selección del personal de compañía (Dama) para la asignación de comisión.
3. **Módulo 3: Control de Caja & Billeteo (Cashier Shifts)**
   * Proceso estricto de apertura y cierre de turnos mediante calculadora de arqueo físico (billeteo manual de billetes/monedas) con reporte automático de descuadres (sobrantes y faltantes).
4. **Módulo 4: Panel de Comisiones en Tiempo Real (Hostess Portal)**
   * Interfaz móvil para que las damas consulten en tiempo real sus ganancias acumuladas del turno activo, metas alcanzadas e historial de invitaciones.
5. **Módulo 5: Gestión de Inventarios y Compras (Backoffice Inventory)**
   * Control de stock mínimo, registro de mermas, actualización de existencias y costos unitarios de bebidas e insumos.
6. **Módulo 6: Gestión de Personal y Roles (Staffing)**
   * Creación de perfiles de empleados, asignación de roles operativos, registro de DNI/Celular y restablecimiento de contraseñas.
7. **Módulo 7: Dashboard BI & Estadísticas Gerenciales (BI & Metrics)**
   * Reportes de ingresos consolidados, márgenes de ganancia neta, rankings de productos más vendidos y rendimientos históricos de turnos.
8. **Módulo 8: Auditoría Ojo de Halcón (System Auditing)**
   * Trazabilidad absoluta de operaciones. Registro de IP, dispositivo y payload JSON (datos anteriores vs. nuevos) de todas las transacciones financieras y de seguridad.
9. **Módulo 9: Catálogo QR Público (Public QR Menu)**
   * PWA informativa sin login para clientes. Muestra bebidas y variantes con Precio A. Se oculta el Precio B de compañía para proteger la privacidad del negocio.

---

## 🔐 3. Matriz de Control de Acceso (Access Matrix)

* **L/E**: Lectura y Escritura (Control Total).
* **L**: Solo Lectura (Visualización/Auditoría).
* **-**: Sin Acceso.

| Módulo / Funcionalidad | PÚBLICO | DAMA | BARMAN / CAJERO | REVIEWER / AUDITOR | ADMIN / PROPIETARIO | SUPERADMIN (SaaS) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **1. Auth & Selección de Bar** | - | L | L | L | **L/E** | **L/E** |
| **2. Punto de Venta (POS)** | - | - | **L/E** | - | **L/E** | **L** (Soporte) |
| **3. Caja y Turnos (Billeteo)**| - | - | **L/E** | L | **L/E** | **L** (Soporte) |
| **4. Panel de Comisiones RT**  | - | L (Propias) | - | - | L (Ver todas) | - |
| **5. Gestión de Inventarios**   | - | - | L (Consumos) | L | **L/E** | - |
| **6. Gestión de Personal**      | - | - | - | - | **L/E** | **L/E** (Global) |
| **7. Dashboard BI & Métricas**  | - | - | - | L | **L/E** | **L/E** (Global) |
| **8. Auditoría & Logs**        | - | - | - | L | L (Solo su bar) | **L/E** (Global) |
| **9. Menú QR Público**          | L | - | L (Ver QR) | - | **L/E** | **L/E** |

---

## ⚙️ 4. Reglas Críticas de Negocio por Rol

### 🚨 1. Privacidad del "Precio B" (Compañía)
* El **PÚBLICO** (clientes escaneando el código QR) **bajo ninguna circunstancia** puede ver o deducir la existencia del *Precio B* ni comisiones asociadas en el Menú QR Público. Solo se renderiza el catálogo con *Precio A*.
* La **DAMA** en su panel personal solo puede ver la comisión que ha ganado por su trabajo (`monto_comision`), **nunca** el precio de costo del producto ni el margen neto de ganancia del bar.

### 💰 2. Seguridad Financiera (Billeteo)
* El **BARMAN / CAJERO** no puede registrar ventas si el turno de caja no ha sido formalmente **Abierto** en el Módulo 3.
* Durante la apertura y cierre de caja, el sistema exige ingresar las cantidades físicas por denominación (ej. *5 billetes de 100 Bs, 10 de 50 Bs, etc.*). El sistema calcula el total teórico automáticamente y expone cualquier descuadre al administrador.

### 🛡️ 3. Aislamiento Multi-tenant
* El **ADMIN / PROPIETARIO** tiene control total de su base de datos, pero está estrictamente restringido a ver o alterar datos de su `bar_id` asignado.
* El **SUPERADMIN** no interfiere con la operación diaria del POS de un bar, pero tiene la capacidad de bloquear el acceso a un bar por falta de pago o consultar logs agregados del sistema para auditorías de rendimiento global del SaaS.
