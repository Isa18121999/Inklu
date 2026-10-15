# INKLU — Lista de preparación para piloto

**Estado:** MVP en desarrollo. Este documento separa funciones implementadas de pruebas y tareas que todavía bloquean un piloto externo. No equivale a una certificación de seguridad, accesibilidad ni cumplimiento legal.

## Estado de la hoja de ruta

| Área | Estado en el código | Validación pendiente |
|---|---|---|
| Recomendaciones | Motor determinista que combina carrera, texto del CV, habilidades, experiencia y preferencias; muestra los motivos y aclara que la puntuación es orientativa. | Revisar con perfiles sintéticos de distintas áreas y confirmar que las recomendaciones irrelevantes no se presenten como adecuadas. No es un modelo de IA entrenado. |
| Perfiles de candidatos y empresas | Perfil de candidato con resumen, formación, experiencia, habilidades, proyectos y certificaciones; perfil de empresa y presentación pública en las ofertas. | Completar perfiles de prueba y comprobar su visualización en pantallas pequeñas y con texto ampliado. |
| Ofertas, favoritos y filtros | Ofertas guardadas y búsquedas con filtros persistentes, incluido “solo con información de accesibilidad”. | Confirmar que guardar, aplicar y eliminar filtros se conserva al cerrar y volver a iniciar sesión. |
| Postulaciones | Estados, historial visual, notificaciones de cambios, retirada de postulaciones y chat según la etapa. | Ejecutar la secuencia completa candidato–empresa y revisar las transiciones de estado. |
| Alertas | Notificaciones dentro de la aplicación; alertas cuando una oferta nueva coincide con una búsqueda guardada y contador de no leídas. | Verificar coincidencias y no coincidencias con ofertas de prueba. No se consideran activadas notificaciones push ni avisos por correo. |
| Accesibilidad | Ajuste de tamaño del texto, etiquetas/tooltip en acciones importantes y anuncios de mensajes temporales al lector de pantalla. | Pruebas manuales con TalkBack, aumento del texto del sistema, navegación sin precisión motora y revisión de contraste/lectura. Esto no es una certificación WCAG. |
| Seguridad y privacidad | Hash de contraseñas, JWT, limitación de intentos, CV con descarga protegida por postulación y reducción de los datos personales expuestos a empresas en el listado de postulantes. | Verificar la configuración real de secretos de Render, limitar CORS, revisar consentimiento/retención y realizar pruebas de autorización entre cuentas. |
| Pruebas | Tests de recomendación, coincidencia de búsquedas guardadas, esquema de usuario y widgets Flutter. | Esperar a que el último flujo de compilación y pruebas quede verde; ejecutar el guion manual de este documento. |
| Preparación de piloto | Hay API desplegada y construcción automática del APK. | No abrir un piloto externo hasta cerrar los bloqueadores de la sección siguiente. |

## Bloqueadores previos a un piloto externo

- **Secreto JWT:** el backend ahora se detiene si `JWT_SECRET` falta, es el valor de ejemplo o tiene menos de 32 caracteres. Falta confirmar en Render que la variable es aleatoria, privada, única y no coincide con ninguna clave de desarrollo. Rotarla invalida las sesiones actuales, por lo que debe coordinarse.
- **Recuperación y verificación por correo:** pendientes. El relay de Google Apps Script no se ha validado y ya devolvió el error `Script function not found: doGet`. No comunicar que estas funciones están operativas hasta probar el envío y el enlace completo.
- **Accesibilidad práctica:** realizar una sesión con TalkBack y con tamaño de texto ampliado en un Android real; corregir los problemas encontrados.
- **Privacidad:** utilizar perfiles/CV ficticios en pruebas. Antes de recibir datos reales de discapacidad o currículums, revisar el aviso de privacidad, los consentimientos, el acceso por roles, la retención y el procedimiento de eliminación con asesoría apropiada.
- **CORS y operación:** el backend aplica una lista permitida de orígenes web y mantiene por defecto el origen de GitHub Pages del proyecto; confirmar que `FRONTEND_ORIGIN` en Render contiene solo los orígenes realmente usados, nunca `*`, y revisar los registros de fallos.

## Guion de prueba con datos ficticios

1. Crear un candidato de prueba del área de tecnología y otro de salud. Usar correos de prueba y CV ficticios, sin DNI, número real de CONADIS ni información clínica.
2. Completar formación, resumen profesional, experiencia, habilidades, proyectos y cursos. Cargar un CV con texto seleccionable, ejecutar el análisis y revisar los motivos de cada recomendación. El perfil de salud no debe recibir una oferta tecnológica sin evidencia profesional relevante.
3. En el candidato de tecnología, guardar una búsqueda “Remoto · Tecnología · accesibilidad”. Cerrar sesión y volver a entrar; verificar que la búsqueda sigue guardada, que puede aplicarse y que puede eliminarse.
4. Desde una empresa de prueba, publicar una oferta que coincida con esos filtros y otra que no coincida. Confirmar que solo la primera genera una notificación de búsqueda guardada.
5. Guardar una oferta y postularse. Confirmar que la postulación aparece una sola vez y que su historial muestra el estado inicial.
6. Desde la empresa propietaria de la oferta, abrir el perfil profesional, descargar el CV autorizado y avanzar la postulación por “CV visto” y “En proceso”. Confirmar las notificaciones y el chat cuando se habilite.
7. Verificar que una segunda cuenta de empresa no puede consultar ni descargar el CV de esa postulación. Confirmar también que el listado empresarial no expone teléfono, correo, dirección, fecha de nacimiento ni número CONADIS del candidato.
8. Retirar una postulación activa desde el candidato. Confirmar el cierre, su registro en el historial y la notificación a la empresa. Comprobar que no se puede reactivar mediante una transición de empresa no permitida.
9. Repetir el recorrido con TalkBack y texto ampliado. Verificar que cada control tiene nombre comprensible, foco visible, área táctil suficiente y que los mensajes de error/éxito se anuncian.

## Criterios para detener la prueba

No continuar con usuarios externos si ocurre cualquiera de estos casos: una cuenta accede a datos o CV de otra empresa; se expone información personal innecesaria; una postulación tiene estados contradictorios; se producen recomendaciones manifiestamente irrelevantes sin explicaciones; un paso esencial no puede completarse con lector de pantalla; o las acciones de recuperación/verificación de cuenta no funcionan.

## Evidencia por recopilar

Para cada prueba, anotar fecha, versión/commit, dispositivo, rol de la cuenta, resultado esperado, resultado real y captura con datos personales ocultos. Registrar los fallos como incidencias; no adjuntar tokens, contraseñas, CV reales ni números de acreditación.
