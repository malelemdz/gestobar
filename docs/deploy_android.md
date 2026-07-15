# Guía de Compilación y Despliegue de Android

Esta guía detalla los comandos necesarios para compilar la aplicación móvil de Android (tanto para pruebas en formato APK como para publicación oficial en formato AAB/App Bundle) asegurando la conexión al entorno correspondiente (Stage o Producción).

---

## ⚙️ Configuración de Entornos

Flutter utiliza el parámetro `--dart-define=ENVIRONMENT=<env>` en tiempo de compilación para seleccionar a qué servidor conectarse:

* **Desarrollo Local:** `--dart-define=ENVIRONMENT=development`
* **Pruebas (Stage):** `--dart-define=ENVIRONMENT=stage` (Conecta a `https://api-stg.gestobar.app`)
* **Producción:** `--dart-define=ENVIRONMENT=production` (Conecta a `https://api.gestobar.app`)

> ⚠️ **IMPORTANTE:** Si no incluyes el flag `--dart-define`, la aplicación utilizará la URL de desarrollo local y no podrá conectarse al servidor en la nube.

---

## 🛠️ Comandos de Compilación

Todos los comandos se deben ejecutar desde la carpeta raíz del frontend:

```bash
cd /Volumes/Corsair/macos/Development/gestobar/frontend
```

### 1. Limpieza y preparación
Antes de compilar una nueva versión de producción, es recomendable limpiar la caché para evitar arrastrar recursos antiguos:

```bash
flutter clean
flutter pub get
```

### 2. Generar APK de Pruebas (Producción)
Si quieres generar un instalador directo `.apk` para instalar manualmente en teléfonos de prueba conectados al backend real de producción:

```bash
flutter build apk --release --dart-define=ENVIRONMENT=production
```

* **Archivo generado en:**
  `build/app/outputs/flutter-apk/app-release.apk`

### 3. Generar App Bundle para Google Play (Producción)
Para generar el archivo `.aab` requerido para subir una nueva versión o actualización a la consola de Google Play Store:

```bash
flutter build appbundle --release --dart-define=ENVIRONMENT=production
```

* **Archivo generado en:**
  `build/app/outputs/bundle/release/app-release.aab`

---

## 🔑 Firma de la Aplicación (Keystore)

La compilación automática requiere del archivo de claves configurado localmente en la máquina:
* **Archivo de llaves:** `/Volumes/Corsair/macos/gestobar-release.jks`
* **Alias de firma:** `gestobar`
* **Archivo de variables:** `android/key.properties` (contiene la contraseña e información de la firma)

> ⚠️ **ATENCIÓN:** El archivo `key.properties` y el archivo `.jks` contienen credenciales críticas y bajo ninguna circunstancia deben subirse a repositorios públicos como GitHub.
