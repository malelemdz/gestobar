# Diseño de Base de Datos: Gestobar (PostgreSQL)

Este esquema soporta un modelo SaaS Multi-Tenant con aislamiento total de datos por bar.

## 1. Esquema de Tablas

### 1.1 `bares` (Tenants)
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID (PK) | |
| `nombre` | VARCHAR(100) | |
| `ciudad` | VARCHAR(100) | |
| `direccion` | TEXT | |
| `timezone` | VARCHAR(50) | Ej: 'America/La_Paz'. |
| `moneda_simbolo`| VARCHAR(10) | Ej: 'Bs'. |
| `moneda_iso` | VARCHAR(10) | Ej: 'BOB'. |
| `logo_url` | TEXT | |
| `whatsapp` | VARCHAR(20) | |
| `link_ubicacion` | TEXT | Google Maps Link. |
| `facebook` | VARCHAR(100) | |
| `instagram` | VARCHAR(100) | |
| `tiktok` | VARCHAR(100) | |
| `slug` | VARCHAR(50) | Para URL del menú QR (único). |
| `estado` | BOOLEAN | TRUE: Activo, FALSE: Suspendido. |
| `owner_id` | UUID (FK) | Admin dueño del bar. |
| `created_at` | TIMESTAMP | |

### 1.2 `roles`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID (PK) | |
| `bar_id` | UUID (FK, NULL)| NULL para roles del sistema global. |
| `nombre` | VARCHAR(50) | Ej: 'Barman', 'Dama'. |

### 1.3 `permisos`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID (PK) | |
| `nombre` | VARCHAR(100) | Ej: 'ventas.crear'. |

### 1.4 `rol_permisos`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `rol_id` | UUID (FK) | |
| `permiso_id` | UUID (FK) | |

### 1.5 `usuarios`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID (PK) | |
| `bar_id` | UUID (FK, NULL)| |
| `rol_id` | UUID (FK) | |
| `username` | VARCHAR(50) | Único. |
| `password` | TEXT | Hash. |
| `foto_url` | TEXT | |
| `nombre` | VARCHAR(100) | |
| `apellido` | VARCHAR(100) | |
| `identificacion`| VARCHAR(50) | |
| `nacionalidad` | VARCHAR(50) | |
| `celular` | VARCHAR(20) | |
| `direccion` | TEXT | Domicilio. |
| `estado` | BOOLEAN | Activo/Inactivo. |

### 1.6 `categorias`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID (PK) | |
| `bar_id` | UUID (FK) | |
| `nombre` | VARCHAR(50) | |
| `orden` | INT | |

### 1.7 `productos`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID (PK) | |
| `bar_id` | UUID (FK) | |
| `categoria_id`| UUID (FK) | |
| `foto_url` | TEXT | |
| `nombre` | VARCHAR(100) | |
| `descripcion` | TEXT | |

### 1.8 `variantes`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID (PK) | |
| `producto_id` | UUID (FK) | |
| `nombre` | VARCHAR(100) | Ej: 'Normal', 'Fresa'. |
| `precio_a` | DECIMAL(12,2) | |
| `precio_b` | DECIMAL(12,2) | |
| `disponible` | BOOLEAN | |

### 1.9 `cajas` (Turnos)
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID (PK) | |
| `bar_id` | UUID (FK) | |
| `apertura_usuario_id`| UUID (FK) | |
| `cierre_usuario_id` | UUID (FK, NULL)| |
| `fecha_apertura` | TIMESTAMP | |
| `fecha_cierre` | TIMESTAMP (NULL)| |
| `monto_inicial` | DECIMAL(12,2) | |
| `monto_final` | DECIMAL(12,2) | |
| `estado` | ENUM | 'ABIERTA', 'CERRADA'. |

### 1.10 `ventas`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID (PK) | |
| `bar_id` | UUID (FK) | |
| `caja_id` | UUID (FK) | |
| `usuario_id` | UUID (FK) | |
| `total` | DECIMAL(12,2) | |
| `metodo_pago`| VARCHAR(20) | |
| `fecha` | TIMESTAMP | |

### 1.11 `detalle_ventas`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID (PK) | |
| `venta_id` | UUID (FK) | |
| `variante_id` | UUID (FK) | |
| `cantidad` | INT | |
| `precio_unitario`| DECIMAL(12,2) | Cobrado (A o B). |
| `es_precio_b` | BOOLEAN | |
| `dama_id` | UUID (FK, NULL)| |
| `comision_dama` | DECIMAL(12,2) | 50% de precio si es B. |

### 1.12 `auditoria` (Logs)
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | UUID (PK) | |
| `bar_id` | UUID (FK) | |
| `usuario_id` | UUID (FK) | |
| `rol_nombre` | VARCHAR(50) | |
| `accion` | VARCHAR(100) | |
| `modulo` | VARCHAR(50) | |
| `detalles` | JSONB | Valores antes/después. |
| `ip_address` | VARCHAR(45) | |
| `fecha` | TIMESTAMP | |

---

## 2. Consideraciones Técnicas
- **Precisión Numérica:** Se usa `DECIMAL(12,2)` para soportar monedas de altas denominaciones (como CLP) sin perder precisión.
- **Seguridad Realtime:** Los WebSockets deben validar el `bar_id` en cada mensaje para evitar filtración de datos entre bares.
- **Aislamiento:** Todas las queries deben filtrar por `bar_id`.
