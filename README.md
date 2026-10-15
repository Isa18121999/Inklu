# 🦋 INKLU

**Preparación del piloto:** consulta [`docs/PILOTO_INKLU.md`](docs/PILOTO_INKLU.md) para los criterios de seguridad, accesibilidad y pruebas manuales de extremo a extremo.

### Plataforma digital para la inclusión laboral de personas con discapacidad

INKLU es una startup tecnológica orientada a facilitar la conexión entre **personas con discapacidad que buscan oportunidades laborales** y **empresas comprometidas con la inclusión laboral**.

La plataforma busca reducir las barreras de acceso al empleo mediante una experiencia digital accesible, permitiendo a los candidatos crear su perfil profesional y encontrar oportunidades laborales, mientras que las empresas pueden registrar sus organizaciones y publicar ofertas inclusivas.

---

## 🎯 Objetivo

Desarrollar una plataforma tecnológica que contribuya a la inclusión laboral mediante:

- 👩‍💻 Registro de candidatos.
- 🏢 Registro de empresas.
- ♿ Identificación mediante número de CONADIS.
- 📄 Registro y selección de CV.
- 💼 Visualización de ofertas laborales.
- 📌 Postulación a oportunidades de empleo.
- 🔎 Recomendación de oportunidades según el perfil.
- 📊 Paneles diferenciados para candidatos y empresas.
- 🌐 Comunicación entre aplicación móvil y API.
- 🔐 Gestión de contraseñas; recuperación y verificación por correo pendientes de activar para el piloto.
- ♿ Información sobre accesibilidad de las ofertas.
- 🔔 Notificaciones y seguimiento de postulaciones.
- ⭐ Guardado de ofertas y recomendaciones según el CV.

---

## ✨ Características principales

### 👤 Candidatos

El candidato puede:

- Crear una cuenta.
- Registrar sus datos personales.
- Registrar su número de CONADIS.
- Seleccionar su fecha de nacimiento.
- Registrar teléfono y dirección.
- Cargar su CV.
- Consultar ofertas laborales.
- Revisar recomendaciones.
- Gestionar sus postulaciones.
- Consultar su perfil.

El registro está dividido en:

1. **Crear cuenta**
2. **Información personal**
3. **Perfil profesional**

El número de CONADIS es un dato obligatorio durante el registro.

### 🏢 Empresas

Las empresas pueden:

- Crear una cuenta empresarial.
- Registrar su RUC.
- Seleccionar el sector empresarial.
- Indicar el tamaño de la empresa.
- Registrar dirección.
- Registrar sitio web.
- Añadir una descripción de la organización.
- Crear ofertas laborales.
- Gestionar sus oportunidades publicadas.

El registro empresarial está dividido en:

1. **Crear cuenta como empresa**
2. **Información de la empresa**

Los sectores disponibles incluyen:

- Tecnología
- Educación
- Salud
- Finanzas
- Comercio
- Manufactura
- Servicios
- Construcción
- Transporte
- Turismo
- Otro

---

## 🛠️ Tecnologías utilizadas

### Aplicación móvil

- **Flutter**
- **Dart**
- Material 3
- `http`
- `shared_preferences`
- `file_picker`

### Backend

- **Node.js**
- **Express.js**
- **MongoDB**
- **Mongoose**
- **JWT**
- **bcryptjs**
- **CORS**
- **dotenv**

### Infraestructura

- **GitHub** — Control de versiones
- **GitHub Actions** — Integración y construcción automática
- **Render** — Despliegue de la API
- **MongoDB** — Persistencia de datos

---

## 📁 Estructura del proyecto

```text
Inklu/
│
├── .github/
│   └── workflows/
│       └── android-apk.yml
│
├── assets/
│   └── logo.png
│
├── backend/
│   ├── controllers/
│   ├── middleware/
│   ├── models/
│   ├── routes/
│   ├── server.js
│   ├── package.json
│   └── .env
│
├── flutter_app/
│   ├── android/
│   ├── assets/
│   ├── lib/
│   │   ├── main.dart
│   │   └── services/
│   │       └── api_service.dart
│   ├── pubspec.yaml
│   └── ...
│
├── render.yaml
└── README.md
```

---

## 🔄 Arquitectura

```text
┌───────────────────────────┐
│       Aplicación          │
│          INKLU            │
│         Flutter           │
└─────────────┬─────────────┘
              │
              │ HTTP / REST API
              ▼
┌───────────────────────────┐
│       INKLU API           │
│      Node.js + Express    │
└─────────────┬─────────────┘
              │
              │ Mongoose
              ▼
┌───────────────────────────┐
│         MongoDB           │
│       Base de datos       │
└───────────────────────────┘
```

---

## 🔐 Seguridad

INKLU incorpora mecanismos básicos de seguridad para proteger la información de los usuarios:

- Contraseñas almacenadas mediante hash.
- Autenticación mediante JWT.
- Validación de datos durante el registro.
- Validación de correo electrónico.
- Validación de número de teléfono.
- Validación de RUC.
- Validación del número de CONADIS.
- Variables sensibles mediante variables de entorno.
- Comunicación entre la aplicación y el backend mediante API.

Las credenciales y secretos no deben almacenarse directamente en el código fuente.

---

## ⚙️ Requisitos

Para ejecutar el proyecto localmente se requiere:

### Flutter

- Flutter 3.x
- Dart 3.x
- Android Studio o VS Code
- Android SDK

### Backend

- Node.js 20 o superior
- npm
- MongoDB

---

## 🚀 Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/Isa18121999/Inklu.git
cd Inklu
```

### 2. Configurar el backend

```bash
cd backend
npm install
```

Crear un archivo `.env`:

```env
MONGODB_URI=tu_conexion_mongodb
JWT_SECRET=
FRONTEND_ORIGIN=https://isa18121999.github.io
```

Genera el valor de `JWT_SECRET` con un generador criptográficamente seguro. Con Node.js puedes ejecutar:

```bash
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
```

Copia el resultado en `JWT_SECRET`; no uses el texto de ejemplo, no compartas el valor ni lo guardes en Git. El backend no arranca si el secreto falta o tiene menos de 32 caracteres. En Render configura el mismo tipo de secreto como variable privada, sin mostrarlo en capturas.

Iniciar el servidor:

```bash
npm start
```

Para desarrollo:

```bash
npm run dev
```

### 3. Configurar la aplicación Flutter

Desde la raíz del proyecto:

```bash
cd flutter_app
flutter pub get
```

Ejecutar la aplicación:

```bash
flutter run
```

---

## 📱 Generar APK

La aplicación Android puede compilarse mediante:

```bash
flutter build apk --release
```

El APK generado se encuentra en:

```text
flutter_app/build/app/outputs/flutter-apk/app-release.apk
```

También existe un flujo de **GitHub Actions** que permite generar automáticamente el APK de Android.

---

## 🔁 Integración continua

El proyecto utiliza GitHub Actions para automatizar el proceso de construcción de la aplicación Android.

El flujo realiza:

1. Configuración del entorno Flutter.
2. Generación de la plataforma Android.
3. Instalación de la identidad visual de INKLU.
4. Configuración de permisos necesarios.
5. Instalación de dependencias.
6. Análisis del código Flutter.
7. Construcción del APK en modo Release.
8. Publicación del APK como artefacto de GitHub Actions.

---

## 🌐 Backend desplegado

La API de INKLU se encuentra preparada para ejecutarse en **Render**.

**API:** https://inklu-api.onrender.com

El backend utiliza:

- Node.js
- Express
- MongoDB
- Variables de entorno
- Render Web Service

---

## ♿ Enfoque de accesibilidad e inclusión

INKLU se desarrolla bajo un enfoque centrado en la inclusión laboral de personas con discapacidad.

Entre los elementos considerados se encuentran:

- Registro del número de CONADIS.
- Interfaz sencilla y orientada a tareas.
- Navegación diferenciada según el tipo de usuario.
- Flujo específico para candidatos y empresas.
- Diseño pensado para dispositivos móviles.
- Identidad visual propia de INKLU.
- Reducción de pasos innecesarios durante el registro.

El proyecto busca que la tecnología funcione como un medio para facilitar el acceso a oportunidades laborales y mejorar la interacción entre candidatos y empresas.

---

## 🧪 Estado del proyecto

**Estado:** 🚀 Startup en desarrollo / MVP

Actualmente se encuentran implementados:

- [x] Aplicación Flutter
- [x] Identidad visual INKLU
- [x] Registro de candidatos
- [x] Registro de empresas
- [x] Validación de formularios
- [x] Número de CONADIS obligatorio
- [x] Selección de CV
- [x] Sector empresarial mediante lista de opciones
- [x] Dashboard de candidato
- [x] Dashboard de empresa
- [x] API REST
- [x] MongoDB
- [x] Autenticación
- [x] Despliegue del backend
- [x] Construcción automática del APK
- [ ] Integración completa del almacenamiento del CV
- [ ] Implementación completa de recomendaciones inteligentes
- [ ] Filtros avanzados de ofertas
- [ ] Notificaciones de nuevas oportunidades
- [ ] Pruebas de accesibilidad
- [ ] Publicación en tiendas de aplicaciones

---

## 👥 Tipos de usuario

| Usuario | Funcionalidades |
|---|---|
| 👤 Candidato | Registro, perfil, CV, ofertas, recomendaciones y postulaciones |
| 🏢 Empresa | Registro, perfil empresarial, publicación y gestión de ofertas |
| ⚙️ Sistema | Autenticación, validación, persistencia y comunicación mediante API |

---

## 📌 Próximas mejoras

- Integración completa del CV con almacenamiento en el backend.
- Sistema de recomendaciones basado en el perfil del candidato.
- Filtros avanzados de ofertas.
- Notificaciones de nuevas oportunidades.
- Seguimiento del estado de las postulaciones.
- Mejoras de accesibilidad.
- Pruebas automatizadas.
- Pruebas de usabilidad con usuarios.
- Publicación de la aplicación para Android.
- Integración de analítica y métricas de uso.

---

## 📄 Licencia

© 2026 INKLU. Todos los derechos reservados.

El código fuente, diseño, identidad visual, documentación, contenidos y demás componentes de este proyecto son propiedad de INKLU.

Queda prohibida la reproducción, distribución, modificación, publicación o uso comercial del proyecto o de cualquiera de sus componentes sin autorización previa y por escrito de sus propietarios.

---

## 🦋 INKLU

**Tecnología para conectar talento, oportunidades e inclusión.**

INKLU es una startup tecnológica que busca transformar la manera en que las personas con discapacidad acceden a oportunidades laborales y cómo las empresas incorporan talento diverso.

> La inclusión no es solo una oportunidad. Es una forma de construir un futuro laboral para todos.


## Recuperación de contraseña

La pantalla de inicio de sesión incluye **¿Olvidaste tu contraseña?**. Para activar el envío real de enlaces, configura en Render las variables:

- **Sin dominio propio:** configura `SMTP_USER` con una cuenta Gmail, `SMTP_APP_PASSWORD` con una contraseña de aplicación de Google y `SMTP_SERVICE=gmail`. Usa una dirección remitente `EMAIL_FROM` igual a `SMTP_USER` o déjala sin configurar para que use esa misma dirección.
- Para generar una contraseña de aplicación, la cuenta debe tener verificación en dos pasos habilitada. No uses tu contraseña normal de Gmail ni la compartas por chat.
- **Alternativa con dominio verificado:** configura `RESEND_API_KEY` y `EMAIL_FROM` con una dirección de ese dominio.
- `PASSWORD_RESET_URL`: URL pública de la página de restablecimiento: `https://isa18121999.github.io/Inklu/reset-password.html`.

Los enlaces caducan a los 30 minutos, el token se almacena como hash y se invalida después de usarlo. La nueva contraseña debe incluir al menos ocho caracteres, mayúscula, minúscula, número y símbolo. Si no existe configuración de correo válida, la API informa del problema sin afirmar que se envió el correo.
