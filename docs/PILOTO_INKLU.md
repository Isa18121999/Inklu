# INKLU — lista de preparación para el piloto

Este documento distingue entre lo implementado y las comprobaciones manuales pendientes. La compilación automática o el despliegue exitoso no sustituyen las pruebas con cuentas y dispositivos reales.

## Estado del MVP

- [x] Registro y acceso para candidatos y empresas.
- [x] Perfil de candidato con formación, resumen, habilidades, experiencia, proyectos y certificaciones.
- [x] Ofertas con habilidades obligatorias/deseables y descripción de accesibilidad declarada.
- [x] Recomendaciones orientativas basadas en términos del CV y perfil; no es un modelo de IA entrenado y no garantiza contratación.
- [x] Guardado de ofertas y búsquedas.
- [x] Seguimiento de postulación con historial de estados y avisos dentro de la aplicación.
- [x] Aviso en la aplicación cuando una oferta nueva coincide con una búsqueda guardada.
- [x] Descarga del CV mediante un endpoint autenticado y autorizado a la empresa de la oferta.
- [x] Pruebas automáticas del recomendador, filtros de búsquedas guardadas y esquema de usuario.
- [ ] Validación manual completa en Android, con cuentas de prueba independientes.
- [ ] Auditoría de accesibilidad con TalkBack y dispositivos de distintos tamaños.
- [ ] Confirmación de configuración segura de los secretos de producción y del origen permitido para el frontend.
- [ ] Recuperación y verificación por correo: pendiente deliberadamente hasta retomar la configuración del servicio de correo.
- [ ] Notificaciones push/SMS/correo: no incluidas; las alertas descritas aquí son dentro de la aplicación.
- [ ] Firma definitiva del APK y proceso de publicación en tiendas, si aplica.

## Preparación técnica antes de invitar participantes

- [ ] Confirmar que Render muestra el último despliegue como `Live` y que `/api/health` responde correctamente.
- [ ] En Render, confirmar que `JWT_SECRET` es una clave privada, única, larga y diferente de cualquier valor de ejemplo. No pegarla en issues, capturas ni chats.
- [ ] Confirmar que `MONGODB_URI` usa una cuenta de base de datos de mínimo privilegio y que el acceso de red está limitado cuando sea posible.
- [ ] Configurar `FRONTEND_ORIGIN` con los orígenes realmente utilizados; evitar `*` para una experiencia web de producción.
- [ ] Confirmar HTTPS en la API y no almacenar secretos dentro de Flutter ni del repositorio.
- [ ] Preparar una política de copias de seguridad y una persona responsable de recuperación.
- [ ] No usar nombres, CV, teléfonos o números de CONADIS reales en las pruebas iniciales. Usar cuentas y documentos ficticios.
- [ ] Probar la eliminación de cuenta con datos de prueba y comprobar qué registros asociados se eliminan.
- [ ] Informar a cada participante qué datos se recogen, para qué se utilizan, quién puede verlos y cómo dejar de participar.
- [ ] Mantener la recuperación por correo fuera del alcance de este piloto hasta resolverla; no anunciar que está operativa.

## Escenarios manuales de extremo a extremo

Marcar cada caso solo después de ejecutarlo y anotar dispositivo, versión, resultado y evidencia sin datos personales.

| ID | Escenario | Resultado esperado | Estado |
|---|---|---|---|
| P01 | Registrar un candidato de prueba con datos ficticios | La cuenta se crea, puede iniciar sesión y ve su panel | Pendiente |
| P02 | Completar resumen, carrera, experiencia, habilidades, proyectos y cursos | Los campos se guardan y persisten al volver a abrir el perfil | Pendiente |
| P03 | Subir y analizar un CV PDF/DOCX de prueba | Se informa si se detectaron habilidades; no se promete extracción perfecta | Pendiente |
| P04 | Comparar una oferta relacionada con otra de área distinta | La relacionada se prioriza y muestra motivos; se explica que la puntuación es orientativa | Pendiente |
| P05 | Guardar y quitar una oferta | La lista se actualiza y se mantiene tras cerrar e iniciar sesión | Pendiente |
| P06 | Guardar una búsqueda y crear una oferta que coincide | Aparece una notificación dentro de la aplicación para ese candidato | Pendiente |
| P07 | Guardar una búsqueda y crear una oferta que no coincide con sus filtros | No aparece una alerta de coincidencia | Pendiente |
| P08 | Activar filtro de ofertas con información de accesibilidad | Solo aparecen ofertas que declararon información de accesibilidad; esto no certifica accesibilidad real | Pendiente |
| P09 | Postular dos veces a la misma oferta | La segunda postulación se rechaza como duplicada | Pendiente |
| P10 | Empresa cambia el estado de una postulación | El candidato ve el nuevo estado y recibe una notificación dentro de la app | Pendiente |
| P11 | Retirar una postulación abierta y probar una postulación finalizada | Solo se permite retirar en las etapas habilitadas | Pendiente |
| P12 | Una empresa intenta descargar un CV de una oferta de otra empresa | El servidor rechaza el acceso | Pendiente |
| P13 | Abrir otra cuenta y tratar de leer/marcar notificaciones ajenas | El servidor no revela ni modifica datos de otra cuenta | Pendiente |
| P14 | Guardar perfil y navegar con TalkBack y texto ampliado | Etiquetas y estados se anuncian, no se corta el contenido ni se bloquea una acción | Pendiente |
| P15 | Probar pérdida de conexión, API lenta y sesión vencida | Se muestra un error comprensible y se permite reintentar o iniciar sesión | Pendiente |
| P16 | Eliminar una cuenta ficticia | Se pide contraseña y se eliminan los registros asociados previstos | Pendiente |

## Auditoría manual de accesibilidad

- [ ] Probar la app completa con TalkBack habilitado; confirmar orden de foco y etiquetas en botones, iconos, filtros y estados.
- [ ] Aumentar el tamaño de texto al 200 % y revisar pantallas de registro, perfil, ofertas, formularios y postulaciones.
- [ ] Verificar que el color nunca sea la única señal de estado.
- [ ] Comprobar que los controles táctiles sean cómodos de activar y que los diálogos se puedan desplazar.
- [ ] Probar Android pequeño, Android grande y orientación compatible.
- [ ] Pedir a participantes con distintas discapacidades que señalen barreras; registrar las observaciones con consentimiento y sin datos clínicos innecesarios.

## Criterios para iniciar un piloto pequeño

No invitar participantes externos hasta que:
1. Los controles de acceso y privacidad P12/P13 hayan pasado.
2. Los recorridos P01–P11 no tengan fallos bloqueantes.
3. La prueba de accesibilidad P14 y la auditoría manual tengan resultado documentado.
4. Los secretos de producción estén verificados y haya una forma probada de recuperar la base de datos.
5. La persona responsable haya comunicado las limitaciones: recomendaciones orientativas, alertas dentro de la app y recuperación por correo pendiente.

## Registro de resultados

Para cada incidencia anotar: fecha, versión del APK/commit, dispositivo y tamaño de texto, pasos para reproducir, resultado esperado, resultado obtenido, severidad, responsable y estado. No incluir contraseñas, tokens, CV reales ni números de CONADIS en las evidencias.

Se recomienda iniciar con un grupo pequeño de prueba, usar datos ficticios al principio y ampliar el acceso solo después de resolver los errores bloqueantes.
