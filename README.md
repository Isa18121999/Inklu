<div align="center">

# INKLU 🦋

**Tecnología para conectar talento, oportunidades e inclusión.**

</div>

Plataforma digital orientada a facilitar la conexión entre personas con discapacidad que buscan oportunidades laborales y empresas comprometidas con la inclusión.

## Estructura

- `backend/`: API Node.js, Express y MongoDB/Mongoose.
- `flutter_app/`: aplicación móvil Flutter.
- `docs/`: documentación funcional, técnica y de accesibilidad.
- `.github/workflows/`: automatizaciones de GitHub Actions.
- `email-relay/`: integración auxiliar de correo.
- Archivos de la interfaz web en la raíz.

## Inicio rápido

### Backend

```bash
cd backend
npm install
cp .env.example .env
npm start
```

Configura `MONGODB_URI`, `JWT_SECRET` y los demás valores requeridos en tu `.env` local o en el proveedor de despliegue. Nunca subas credenciales reales.

### Aplicación Flutter

```bash
cd flutter_app
flutter pub get
flutter run
```

Consulta `docs/PILOTO_INKLU.md` y `PILOT_READINESS.md` para criterios de preparación, accesibilidad y pruebas.

## Seguridad

Los secretos deben mantenerse en variables de entorno privadas. El archivo `backend/.env.example` contiene únicamente valores de ejemplo; no es una configuración operativa.

## Licencia y uso

© 2026 INKLU. Todos los derechos reservados. El código, diseño, identidad visual y documentación pertenecen a INKLU. No se autoriza su reutilización o distribución sin permiso escrito.
