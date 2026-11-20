# INKLU — Lista de preparación para piloto

**Estado:** MVP en desarrollo; todavía no está autorizado para un piloto externo. Este documento separa lo identificado en el código, la evidencia automatizada disponible y las validaciones manuales pendientes. No equivale a certificación de seguridad, accesibilidad ni cumplimiento legal.

**Regla de evaluación:** una función se considera implementada cuando existe en el código; solo se considera validada cuando se completa el flujo esperado con cuentas y datos de prueba, se comprueban permisos y se registra evidencia reproducible.

## 1. Estado funcional y validación pendiente

| Área | Estado identificado en el código | Validación pendiente |
|---|---|---|
| Recomendaciones | Motor determinista que combina carrera, texto del CV, habilidades, experiencia y preferencias; presenta motivos y aclara que la puntuación es orientativa. | Probar perfiles sintéticos de distintas áreas y niveles. Comprobar que ofertas irrelevantes no aparezcan como adecuadas. No describirlo como modelo de IA entrenado. |
| Perfil de candidato | Resumen, formación, experiencia, habilidades, proyectos y certificaciones; herramientas de análisis y edición de CV. | Completar perfiles de prueba y revisar extracción con PDF, DOC y DOCX variados, edición y descarga del CV. |
| Perfil de empresa | Perfil de empresa y presentación pública asociada a las ofertas. | Comprobar edición, visibilidad, permisos y visualización en pantallas pequeñas. |
| Ofertas, favoritos y filtros | Publicación y consulta de ofertas, favoritos, filtros y búsquedas guardadas, incluida información de accesibilidad. | Verificar persistencia al cerrar sesión, volver a ingresar, aplicar, editar y eliminar filtros. |
| Postulaciones | Estados, historial, notificaciones internas y retiro; gestión desde el lado de la empresa. | Ejecutar recorrido integral candidato–empresa, validar transiciones permitidas, historial y notificaciones. |
| Alertas | Notificaciones dentro de la aplicación y coincidencias de ofertas nuevas con búsquedas guardadas. | Probar coincidencias y no coincidencias. No asumir que existen notificaciones push o avisos por correo operativos. |
| Accesibilidad | Preferencias visuales, ajustes de texto/contraste y etiquetas semánticas en controles relevantes. | Pruebas manuales con TalkBack, texto ampliado, navegación, foco, áreas táctiles y contraste en Android real. No es una certificación WCAG. |
| Chat | Funcionalidad de chat identificada en el código. | Probar intercambio real entre cuentas distintas, persistencia, permisos, actualización de mensajes y manejo de errores. |
| Verificación de empresas | Estados de verificación identificados en el modelo/código. | Definir y probar el proceso real de revisión, aprobación/rechazo, evidencia, trazabilidad y permisos administrativos. Un estado no prueba por sí mismo la verificación. |
| Seguridad y privacidad | Hash de contraseñas, JWT, limitación de intentos, descarga de CV protegida por postulación y reducción de datos personales expuestos en listados empresariales. | Revisar configuración de secretos, CORS, autorización entre cuentas, consentimiento, retención y eliminación. Ejecutar pruebas negativas. |
| Modelo de negocio | El esquema Freemium está definido como propuesta del producto. | No se identificó implementación integral de suscripciones ni pagos. Definir planes, periodo gratuito de postulantes, cobro a empresas, proveedor de pagos y gestión de cancelaciones. |
| CI y compilación | Se observaron ejecuciones satisfactorias de backend, verificación Flutter y generación del APK Android. | Volver a ejecutar workflows tras cambios; conservar evidencia del commit exacto. Revisar duplicación de compilaciones y diferencias de versiones de Flutter. |

## 2. Evidencia de integración continua observada

En la revisión del repositorio se identificaron estas ejecuciones satisfactorias:

- **Flutter verification:** [Run 44776317144](https://github.com/Isa18121999/Inklu/actions/runs/44776317144). Incluyó dependencias, `flutter analyze --no-pub`, pruebas Flutter y compilación Android.
- **Android APK build:** [Run 44776317149](https://github.com/Isa18121999/Inklu/actions/runs/44776317149). Incluyó configuración de Firebase y firma, análisis, pruebas, compilación release, limpieza del material de firma y publicación del artefacto.
- **Backend checks:** [Run 44571447254](https://github.com/Isa18121999/Inklu/actions/runs/44571447254). Incluyó comprobación de sintaxis, carga de parsers de CV, auditoría de dependencias de producción y `npm test`.

Estas ejecuciones demuestran que esos workflows finalizaron correctamente en los commits que procesaron. No demuestran cobertura total, ausencia de vulnerabilidades ni que todos los recorridos manuales estén validados. Antes de cada piloto o release, comprobar que los workflows vuelvan a pasar en el commit candidato.

## 3. Bloqueadores previos a un piloto externo

### 3.1 Correo: verificación de cuenta y recuperación de contraseña
**Bloqueador.** El relay de Google Apps Script no se ha validado de extremo a extremo y anteriormente devolvió `Script function not found: doGet`.

Antes de habilitar usuarios externos:
- Corregir y desplegar el endpoint del relay.
- Probar envío real a una cuenta de prueba.
- Verificar expiración, uso único y protección de los enlaces/tokens.
- Probar verificación de cuenta, recuperación y cambio de contraseña desde el inicio hasta el final.
- Confirmar mensajes de error seguros y que no se revele si una cuenta existe.

No comunicar estas funciones como operativas hasta completar y documentar las pruebas.

### 3.2 Secreto JWT y configuración de despliegue
**Bloqueador de confirmación operativa.** El backend se detiene si `JWT_SECRET` falta, es un valor de ejemplo o tiene menos de 32 caracteres. La revisión previa observó un despliegue que arrancó correctamente, pero la persona responsable debe confirmar en Render que la clave sea aleatoria, privada y exclusiva de producción.

- No copiar secretos a capturas, issues, repositorios ni chats.
- No compartir el valor para “verificarlo”; basta confirmar que cumple los requisitos.
- Coordinar cualquier rotación porque invalida las sesiones existentes.
- Confirmar que las demás variables de entorno requeridas estén configuradas en el entorno correcto.

### 3.3 Privacidad y autorización
**Bloqueador.** Antes de recibir CV reales o información relacionada con discapacidad:
- Revisar aviso de privacidad y consentimiento informado.
- Definir finalidad, acceso por roles, retención y eliminación de datos.
- Verificar que una empresa solo acceda a CV y postulaciones autorizadas.
- Probar que una segunda empresa no pueda consultar ni descargar el CV de una postulación ajena.
- Comprobar que listados y respuestas de API no expongan teléfono, correo, dirección, fecha de nacimiento ni identificadores sensibles que no sean necesarios.
- Realizar revisión legal y de protección de datos con asesoría competente.

Usar perfiles y CV ficticios durante el desarrollo y las pruebas.

### 3.4 Accesibilidad práctica
**Bloqueador.** Completar pruebas en un dispositivo Android real con TalkBack y tamaño de texto ampliado. Verificar nombres accesibles, orden de lectura, foco, controles táctiles, contraste, mensajes de validación y recorridos principales. Registrar y corregir barreras que impidan completar tareas esenciales.

### 3.5 CORS y operación
**Bloqueador de validación.** La configuración de `FRONTEND_ORIGIN` en Render se ajustó al origen oficial `https://isa18121999.github.io`; en los registros revisados no se observaron advertencias de CORS posteriores al ajuste.

Pendiente:
- Confirmar que el frontend oficial puede completar los flujos necesarios.
- Verificar que un origen no autorizado no reciba cabeceras CORS permisivas.
- Revisar logs de errores, disponibilidad, reinicios y comportamiento ante fallos de servicios externos.
- Definir responsable y procedimiento de respuesta ante incidentes.

### 3.6 Chat y verificación de empresas
**Bloqueador funcional.** Validar la comunicación entre cuentas y el procedimiento de verificación empresarial antes de presentarlos como servicios disponibles para el piloto. No aprobar empresas automáticamente por tener un estado o campo de verificación.

### 3.7 Modelo Freemium y pagos
No es necesariamente un bloqueador para un piloto cerrado y gratuito, pero sí para lanzar el modelo comercial definido. Antes de cobrar:
- Definir con claridad los planes y beneficios.
- Confirmar el periodo gratuito de tres meses para postulantes y el esquema de pago posterior.
- Definir planes de pago para empresas.
- Implementar y probar pagos, renovaciones, cancelaciones, comprobantes y atención de incidencias.
- Comunicar precios y condiciones antes de que el usuario acepte.

## 4. Guion de prueba con datos ficticios

1. Crear dos candidatos de prueba de áreas diferentes (por ejemplo, tecnología y salud) y una empresa de prueba. Usar correos ficticios/controlados y CV sin datos personales reales.
2. Completar el perfil profesional. Cargar un CV PDF con texto seleccionable y archivos DOC/DOCX; revisar el análisis, corregir los datos extraídos y descargar el CV generado.
3. Comprobar que las recomendaciones se relacionan con carrera, experiencia y habilidades. Registrar ejemplos relevantes e irrelevantes y sus motivos.
4. En el candidato de tecnología, guardar una búsqueda “Remoto · Tecnología · accesibilidad”. Cerrar sesión, volver a ingresar y comprobar que la búsqueda persiste, se puede aplicar y eliminar.
5. Desde la empresa de prueba, publicar una oferta que coincida con los filtros y otra que no coincida. Confirmar que solo la coincidencia genera la alerta correspondiente.
6. Guardar una oferta y postularse. Confirmar que la postulación aparece una sola vez y que el historial muestra el estado inicial.
7. Desde la empresa propietaria de la oferta, abrir la postulación, consultar únicamente la información autorizada y descargar el CV permitido. Avanzar por los estados disponibles y confirmar el historial y las notificaciones.
8. Desde una segunda cuenta empresarial, intentar acceder al CV y a la postulación ajena. La API debe denegar el acceso.
9. Probar chat entre el candidato y la empresa con cuentas distintas. Confirmar envío, recepción, persistencia y restricciones de acceso.
10. Retirar una postulación activa desde el candidato. Confirmar cierre, registro histórico y notificación a la empresa; probar que no se pueda reactivar mediante una transición no permitida.
11. Probar registro, verificación de correo y recuperación de contraseña con cuentas controladas. Verificar expiración y uso único de enlaces.
12. Repetir los recorridos principales con TalkBack y texto ampliado. Comprobar que los controles y mensajes sean comprensibles y utilizables.
13. Probar CORS desde el origen oficial y desde un origen no autorizado. Revisar logs del backend durante el recorrido.

## 5. Criterios para detener la prueba

No continuar con usuarios externos si ocurre cualquiera de estos casos:

- Una cuenta accede a datos, CV o postulaciones de otra empresa sin autorización.
- Se expone información personal o sensible innecesaria.
- Una postulación presenta estados contradictorios o transiciones no autorizadas.
- Los enlaces de verificación o recuperación permiten reutilización, no expiran o no funcionan.
- Un paso esencial no puede completarse con lector de pantalla.
- El origen no autorizado puede acceder a la API por una configuración CORS permisiva.
- Los workflows requeridos fallan en el commit candidato.
- No existe un procedimiento claro para responder a incidentes o eliminar datos de prueba.

## 6. Evidencia que debe registrarse

Por cada prueba, anotar:
- Fecha y hora.
- Versión/commit de la aplicación y backend.
- Dispositivo, versión de Android y configuración de accesibilidad.
- Rol de la cuenta de prueba.
- Resultado esperado y resultado real.
- Estado: aprobado, fallido o bloqueado.
- Captura o log con todos los datos personales ocultos.
- Incidencia asociada y responsable de corregirla.

Nunca adjuntar tokens, contraseñas, claves, CV reales, DNI ni números de acreditación.

**Última revisión documental:** 20 de noviembre de 2026.
