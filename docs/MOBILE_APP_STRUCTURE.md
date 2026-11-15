# Organización de INKLU: aplicación móvil

## Decisión de producto

La aplicación principal de INKLU es Flutter/Dart y vive en `flutter_app/`. No se debe confundir el prototipo HTML/JavaScript anterior con la app móvil.

## Componentes que se conservan

- `flutter_app/`: código fuente Flutter, recursos, pruebas y configuración Android.
- `backend/`: API, autenticación, modelos, servicios y acceso a MongoDB.
- `email-relay/`: integración auxiliar de correo.
- `assets/`: identidad visual y recursos compartidos.
- `docs/`, `PILOT_READINESS.md`: documentación y preparación del piloto.
- `reset-password.html` y `verify-email.html`: páginas mínimas requeridas por los enlaces de correo del backend.

## Prototipo web archivado

Los archivos originales `index.html`, `app.js`, `app-v2.js`, `styles.css`, `web-fix.js`, `package.json` y `capacitor.config.json` se mueven a `legacy_web/`. Se preservan para consulta; no son el punto de entrada ni el mecanismo de compilación de la aplicación móvil.

## Publicación web auxiliar

El workflow `.github/workflows/pages.yml` prepara un directorio temporal `site/` con solo las dos páginas de autenticación y un índice informativo. No publica el prototipo web archivado. Los enlaces del backend a `/reset-password.html` y `/verify-email.html` permanecen compatibles.

## Validaciones recomendadas

1. Ejecutar `flutter pub get`, `flutter analyze` y `flutter test` desde `flutter_app/`.
2. Ejecutar `npm test` desde `backend/`.
3. Comprobar en un entorno de prueba el envío de enlaces de verificación y recuperación.
4. Confirmar que GitHub Pages sirve ambas páginas de autenticación.
5. Confirmar que el APK se genera mediante el workflow Android.
