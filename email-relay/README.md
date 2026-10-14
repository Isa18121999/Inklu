# Activar los correos de INKLU con Gmail

El registro de Render mostró un **Connection timeout** al intentar enviar correo mediante SMTP. Para evitar ese bloqueo, INKLU también admite un relay HTTPS con Google Apps Script. No se necesita comprar un dominio. El mismo relay se utiliza para **recuperación de contraseña** y **verificación de correo**.

## 1. Crear el relay de Gmail

1. Inicia sesión en la cuenta de Google desde la que quieres enviar correos de INKLU.
2. Abre https://script.google.com/home/start y crea un proyecto.
3. Reemplaza el contenido de `Code.gs` con el archivo `email-relay/Code.gs` de este repositorio.
4. En **Configuración del proyecto** → **Propiedades del script**, añade:
   - Propiedad: `INKLU_RELAY_TOKEN`
   - Valor: crea una clave aleatoria larga y privada (por ejemplo, una contraseña aleatoria de al menos 32 caracteres). No la compartas por chat ni la guardes en el código.
5. Pulsa **Implementar** → **Nueva implementación** → tipo **Aplicación web**.
6. Configura **Ejecutar como: Yo** y **Quién tiene acceso: Cualquier usuario**. El token privado de la propiedad del script autentica las solicitudes del servidor.
7. Pulsa **Implementar**, autoriza los permisos de envío de correo de Google y copia la URL de la aplicación web que termina en `/exec`.

## 2. Conectar Render

En Render, abre el servicio `inklu-api` → **Environment** y añade estas dos variables:

- `EMAIL_RELAY_URL`: la URL `/exec` que te dio Apps Script.
- `EMAIL_RELAY_TOKEN`: exactamente la misma clave privada guardada como propiedad del script.

Guarda los cambios y espera a que Render termine el nuevo despliegue. El servidor prioriza este relay por HTTPS; si la configuración está correcta, ya no intentará Gmail SMTP.

## 3. Probar recuperación de contraseña

Abre INKLU → **¿Olvidaste tu contraseña?** → introduce el correo de una cuenta registrada. Revisa Recibidos y Spam. El enlace caduca en 30 minutos y solo puede utilizarse una vez.

## 4. Probar verificación de correo

En INKLU, inicia sesión y pulsa **Verificar / reenviar correo** en el aviso que aparece arriba del panel. Abre el enlace recibido; caduca en 24 horas y solo puede utilizarse una vez. Cuando vuelvas a la app, pulsa el mismo botón para actualizar el estado de verificación.

Si no llega, abre los registros de Render y busca `relay de correo`. No pegues capturas que muestren el token ni compartas la clave.

## Seguridad

- No pongas el token dentro de `Code.gs` ni en la aplicación Flutter.
- No desactives la verificación del token.
- Apps Script está sujeto a las cuotas de envío de Google; sirve para pruebas y un piloto, no como infraestructura transaccional de alto volumen.
