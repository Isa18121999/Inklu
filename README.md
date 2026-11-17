# INKLU — Aplicación móvil Flutter

INKLU es una aplicación móvil para conectar a personas con discapacidad que buscan oportunidades laborales con empresas comprometidas con la inclusión.

> **Producto principal:** aplicación móvil Flutter/Dart. Este repositorio no mantiene una aplicación web de candidatos/empresas como producto.

## Arquitectura

- **Aplicación móvil:** `flutter_app/` (Flutter y Dart).
- **API:** `backend/` (Node.js, Express, MongoDB/Mongoose y autenticación).
- **Correo:** `email-relay/` (servicios auxiliares de correo).
- **Recursos visuales:** `assets/` y `flutter_app/assets/`.
- **Automatización:** `.github/workflows/` (análisis, pruebas y compilación Android).
- **Documentación:** `docs/` y `PILOT_READINESS.md`.

Las páginas `reset-password.html` y `verify-email.html` son páginas auxiliares de autenticación abiertas desde los enlaces enviados por correo. **No son una versión web de INKLU** y se conservan porque el backend las utiliza. GitHub Pages publica únicamente estas dos páginas auxiliares y una página informativa mínima.

## Estructura principal

```text
Inklu/
├── .github/workflows/       # CI y compilación APK
├── assets/                  # Recursos compartidos
├── backend/                 # API y persistencia
├── docs/                    # Documentación técnica
├── email-relay/             # Servicio auxiliar de correo
├── flutter_app/             # Aplicación móvil Flutter
│   ├── android/
│   ├── assets/
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
├── reset-password.html      # Página auxiliar de autenticación
├── verify-email.html        # Página auxiliar de autenticación
├── render.yaml              # Despliegue del backend
├── PILOT_READINESS.md
└── README.md
```

## Requisitos

- Flutter 3.x y Dart 3.x.
- Android SDK para compilar Android.
- Node.js 20 o superior y npm para el backend.
- Una instancia MongoDB.

## Ejecutar la aplicación móvil

Desde la raíz:

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
flutter run
```

Para generar un APK de producción:

```bash
flutter build apk --release
```

El APK queda en `flutter_app/build/app/outputs/flutter-apk/app-release.apk`.

## Ejecutar el backend

```bash
cd backend
npm install
```

Crea un archivo local `.env` a partir de `.env.example` y completa las variables en tu entorno seguro. No subas `.env`, contraseñas, tokens, claves privadas ni credenciales al repositorio.

```bash
npm start
```

Para desarrollo:

```bash
npm run dev
```

El backend se despliega mediante Render y utiliza variables de entorno como `MONGODB_URI` y `JWT_SECRET`. Consulta `backend/.env.example` y la documentación antes de configurar el servicio.

## Páginas auxiliares de autenticación

- `reset-password.html`: formulario web para completar la recuperación de contraseña.
- `verify-email.html`: pantalla web que valida el enlace de verificación de correo.

El backend construye enlaces hacia estas páginas. Por eso se mantienen como HTML estático aunque la experiencia principal sea exclusivamente móvil. El workflow `.github/workflows/pages.yml` publica solo estas páginas y un índice informativo.

## Seguridad

- Mantén los secretos únicamente en variables de entorno del proveedor.
- Usa `.env.example` como plantilla, nunca como almacén de credenciales.
- No subas keystores, archivos de firma, tokens, claves API ni datos reales de usuarios.
- Revisa los permisos y los registros antes de desplegar.

## CI/CD

Los workflows de `.github/workflows/` automatizan validaciones del backend y tareas de Flutter/Android. Los APK generados se publican como artefactos de GitHub Actions.

## Estado

INKLU se encuentra en desarrollo como MVP móvil. Consulta `PILOT_READINESS.md` y `docs/` para el estado de preparación, seguridad, accesibilidad y pruebas del piloto.

---

© 2026 INKLU. Todos los derechos reservados.
