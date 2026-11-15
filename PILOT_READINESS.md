# INKLU — Lista de preparación del piloto

Este documento sirve como punto de control previo a una prueba piloto. No sustituye pruebas reales con usuarios.

## Antes del piloto

- [ ] Configurar MongoDB y las variables privadas del backend.
- [ ] Generar un `JWT_SECRET` nuevo y robusto.
- [ ] Configurar el origen permitido del frontend.
- [ ] Verificar registro e inicio de sesión de candidatos y empresas.
- [ ] Verificar creación, edición y consulta de ofertas.
- [ ] Verificar postulación y seguimiento de estado.
- [ ] Comprobar protección de rutas y autorización por rol.
- [ ] Revisar tratamiento de CV y archivos cargados.
- [ ] Probar recuperación de contraseña con proveedor SMTP/Resend configurado.
- [ ] Comprobar que la aplicación no expone tokens en logs o almacenamiento inseguro.

## Accesibilidad

- [ ] Navegación completa con lector de pantalla.
- [ ] Orden de foco lógico y visible.
- [ ] Contraste suficiente y escalado de texto.
- [ ] Controles táctiles con etiquetas semánticas.
- [ ] Formularios con errores claros y asociados a cada campo.
- [ ] Pruebas con personas con distintas necesidades de accesibilidad.

## Datos y privacidad

- [ ] Usar datos ficticios o consentidos en el entorno de prueba.
- [ ] Evitar publicar información personal identificable en repositorios y capturas.
- [ ] Definir retención, eliminación y acceso a documentos CV.
- [ ] Verificar el proceso de eliminación de cuenta.

## Criterio de salida

El piloto debe comenzar solo después de que los responsables hayan revisado y aprobado los puntos críticos de seguridad, privacidad, funcionalidad y accesibilidad. Registrar incidencias y decisiones antes de ampliar el acceso.
