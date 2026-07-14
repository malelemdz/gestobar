# Instalar Gestobar en iPhone

> Asegúrate de que el iPhone esté conectado por USB y desbloqueado antes de correr cualquier comando.
> Todos los comandos se ejecutan desde la carpeta `frontend/`.

```bash
cd /Volumes/Corsair/macos/Development/gestobar/frontend
```

---

## 📱 Stage (backend de pruebas)

Conecta al backend `https://api-stg.gestobar.app`

```bash
flutter run --release \
  -d 00008130-001859693A52001C \
  --dart-define=ENVIRONMENT=stage
```

---

## 🚀 Producción (backend real)

Conecta al backend `https://api.gestobar.app`

```bash
flutter run --release \
  -d 00008130-001859693A52001C \
  --dart-define=ENVIRONMENT=production
```

---

## 📦 Compilar App Bundle para Google Play

```bash
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=production
```

Archivo generado en:
```
build/app/outputs/bundle/release/app-release.aab
```

---

## 🔑 Keystore (firma Android)

- **Archivo:** `/Volumes/Corsair/macos/gestobar-release.jks`
- **Alias:** `gestobar`
- **Config:** `android/key.properties`

> ⚠️ Nunca subas `key.properties` ni el archivo `.jks` al repositorio.
