# La Mesa Chica

Medio editorial en React + Vite, Supabase Auth, Postgres con RLS y Storage. La portada original se conserva. Las notas ficticias siguen en `src/data.js`, ocultas salvo que `VITE_SHOW_DEMO=true`.

## Desarrollo

Node 22 o 24. Ejecutar `npm ci`, copiar `.env.example` a `.env.local`, completar la URL y la clave publicable, y ejecutar `npm run dev`. `npm run build` genera `dist/`.

Nunca colocar claves secretas o `service_role` en variables VITE. La clave publicable es pública por diseño; los permisos se aplican en Postgres.

## Base de datos

Proyecto existente: `qjwqificdwnoxaudxjda`. Las migraciones editoriales se aplicaron sobre la base existente. No ejecutar `supabase.sql` sobre esa base otra vez: es el instalador para proyectos vacíos. Las migraciones en `supabase/migrations` documentan el esquema y los cambios incrementales.

Para probar RLS: ejecutar `supabase/tests/permissions.sql` con una conexión administrativa en una sesión. Todas las cuentas y notas de prueba se revierten con ROLLBACK.

## Acceso

Ingresar desde la cabecera o `/#redaccion`. Los usuarios necesitan una cuenta de Supabase Auth y una fila en `editors`. El primer administrador se configura desde una conexión administrativa; el panel permite agregar integrantes por UUID y cambiar roles. La creación/invitación de cuentas y recuperación de contraseña se administran en Supabase Auth.

| Rol | Acceso |
| --- | --- |
| Público | Lee notas publicadas, categorías y autores |
| Cuenta sin rol | Sin acceso a la redacción ni borradores |
| Redactor | Crea y edita sus borradores, carga imágenes propias |
| Editor | Edita, publica y despublica notas; administra categorías, autores e imágenes |
| Administrador | Todo lo anterior más integrantes y roles |

Los redactores no pueden modificar notas ya publicadas ni leer borradores ajenos. El autor técnico es inmutable. Un administrador no puede cambiar su propio rol. No hay eliminación de artículos: despublicar conserva el contenido.

## Trabajo editorial

El panel incluye archivo con búsqueda y filtro, borradores, publicación y despublicación explícita, categorías, firmas y biografías, portadas, créditos y descripción alternativa. Guardar comprueba la fila devuelta por la base y detecta ediciones concurrentes mediante `updated_at`. Las notas tienen enlaces `/#nota/UUID`.

Las portadas se almacenan en el bucket público `editorial`: no subir documentos privados. JPG, PNG, WebP y AVIF hasta 5 MB. Cada carga genera una ruta nueva; no sobrescribe archivos anteriores. La galería permite copiar enlaces y eliminar archivos sin referencias. Postgres bloquea la eliminación de una imagen utilizada por cualquier nota.

## Vercel

Proyecto principal: `mesachica` (`prj_fZeRovxu4xOBahv7ief6zARaxNsg`). Dominio: https://mesachica-five.vercel.app. Repositorio: https://github.com/enrisid6/mesachica, rama `main`.

Variables de producción, preview y desarrollo: `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` (acepta clave publicable moderna). No hace falta un servidor propio. La integración Git despliega los cambios de la rama principal.

## Pendientes de operación

Asignar la cuenta real del director como primer administrador. Desactivar registro público en Supabase Auth, configurar URL del sitio y redirecciones de correo y revisar política de contraseña/SMTP antes de invitar al equipo. El control editorial rechaza cuentas sin membresía aunque exista registro público. No hay notas reales todavía.
