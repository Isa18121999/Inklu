# Hoja de ruta INKLU

**Estado general:** MVP funcional en desarrollo. La implementación del producto está más avanzada que la clasificación anterior de la hoja de ruta. Este documento distingue entre código identificado, validación pendiente y trabajo futuro. La presencia de una función en el código no significa que esté validada de extremo a extremo ni lista para producción.

## Fase 1 · Estabilidad del MVP — CERRADA CON VALIDACIÓN FUNCIONAL REPORTADA

La responsable del proyecto comunicó el 19 de noviembre de 2026 pruebas satisfactorias en dispositivos reales de:

- [x] Compilación y generación del APK.
- [x] Recomendaciones y relevancia de ofertas.
- [x] Flujo de postulaciones y notificaciones principales.

**Criterio de cierre:** pruebas funcionales reportadas por la responsable. Esto no sustituye pruebas de seguridad, privacidad, accesibilidad ni una validación integral previa a un piloto externo.

## Fase 2 · Experiencia inclusiva — IMPLEMENTADA EN CÓDIGO; VALIDACIÓN E2E PENDIENTE

Los cuatro componentes principales de esta fase ya cuentan con implementación identificada en el repositorio. El trabajo pendiente es completar pruebas integrales, corregir incidencias y documentar evidencias.

### 2.1 Centro de accesibilidad

**Implementado en código:**
- Preferencias de accesibilidad y ajustes visuales.
- Opciones de tamaño de texto y contraste.
- Etiquetas semánticas y ayudas en controles relevantes.

**Pendiente de validación:**
- Persistencia de preferencias entre sesiones y pantallas.
- Pruebas manuales con TalkBack en Android real.
- Navegación con texto ampliado, foco, orden de lectura y áreas táctiles.
- Revisión de contraste y comprensión de mensajes de error/éxito.

No declarar certificación WCAG ni conformidad completa sin evaluación específica.

### 2.2 Constructor de CV inteligente

**Implementado en código:**
- Carga y procesamiento de archivos PDF, DOC y DOCX.
- Extracción de texto y análisis de datos profesionales.
- Apoyo para completar el perfil y gestionar formación, experiencia, habilidades, proyectos y certificaciones.
- Edición de información del perfil y generación/descarga de CV.

**Pendiente de validación:**
- Probar documentos variados y complejos, incluidos archivos con tablas, columnas y escaneos.
- Confirmar la calidad de extracción y el comportamiento ante archivos inválidos.
- Verificar que los datos extraídos sean revisables y corregibles antes de publicarse.
- Validar el formato ATS del PDF generado y que el texto sea seleccionable.
- Si se requiere procesar documentos escaneados, confirmar disponibilidad y calidad de OCR.

La extracción automática es una propuesta que debe revisar la persona candidata; no debe asumirse que los datos son correctos.

### 2.3 Filtros avanzados y recomendaciones de ofertas

**Implementado en código:**
- Filtros por criterios profesionales y características de la oferta, incluidos modalidad, ubicación, categoría y accesibilidad.
- Búsquedas guardadas y coincidencias con nuevas ofertas.
- Motor de recomendaciones basado en carrera, texto del CV, habilidades, experiencia y preferencias, con motivos explicativos.

**Pendiente de validación:**
- Persistencia de filtros y búsquedas al cerrar sesión y volver a ingresar.
- Pruebas con perfiles sintéticos de distintas áreas y niveles de experiencia.
- Confirmar que las ofertas incompatibles o irrelevantes no se presenten como adecuadas.
- Verificar alertas ante coincidencias y ausencia de alertas cuando no exista coincidencia.

El motor actual es determinista; no debe describirse como un modelo de IA entrenado.

### 2.4 Seguimiento de postulaciones

**Implementado en código:**
- Estados e historial de postulaciones.
- Notificaciones internas de cambios.
- Retiro de postulaciones.
- Funcionalidades de gestión de postulaciones desde el lado de la empresa.

**Pendiente de validación:**
- Recorrido integral candidato–empresa con dos cuentas independientes.
- Permisos para cada transición de estado y consistencia del historial.
- Notificaciones correspondientes a cada cambio.
- Retiro de una postulación y bloqueo de transiciones no permitidas.

## Fase 3 · Ecosistema laboral — IMPLEMENTACIÓN PARCIAL

Hay componentes de esta fase presentes en el código, pero todavía requieren integración y validación operativa.

### 3.1 Comunicación empresa–candidato
- **Implementado parcialmente:** funcionalidad de chat identificada en el proyecto.
- **Pendiente:** probar conversación real entre dos cuentas, autorización, recepción de mensajes, persistencia e indicadores de estado.

### 3.2 Verificación de empresas
- **Implementado parcialmente:** estados de verificación de empresa.
- **Pendiente:** definir y validar el procedimiento documental, revisión, aprobación/rechazo, trazabilidad y controles administrativos. Un estado en la base de datos no equivale a una empresa verificada.

### 3.3 Panel administrativo y reportes
- **Pendiente de validación funcional:** confirmar alcance, roles, métricas, controles y reportes disponibles antes de considerarlos terminados.

## Fase 4 · Modelo de negocio y escalamiento — PENDIENTE

- [ ] Definir e implementar el modelo Freemium.
- [ ] Planes de pago para empresas.
- [ ] Periodo inicial gratuito de tres meses para postulantes y posterior esquema de pago, sujeto a validación del modelo.
- [ ] Integrar un proveedor de pagos y gestionar suscripciones, renovaciones, cancelaciones y comprobantes.
- [ ] Definir límites de uso, beneficios por plan y soporte al usuario.
- [ ] Evaluar operación, monitoreo, escalabilidad y soporte para el piloto.

## Calidad continua y criterios de salida

- Mantener verdes los flujos de CI de backend y Flutter: análisis estático, pruebas automatizadas y compilación Android.
- Reducir duplicación entre workflows y unificar versiones de Flutter cuando sea conveniente.
- No abrir un piloto externo hasta cerrar los bloqueadores de `PILOT_READINESS.md`.
- Registrar evidencias por versión/commit, dispositivo, rol de prueba, resultado esperado y resultado obtenido.
- Usar exclusivamente datos ficticios durante las pruebas de integración y seguridad.

**Última revisión documental:** 20 de noviembre de 2026.
