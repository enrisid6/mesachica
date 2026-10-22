# LA MESA CHICA — Sitio editorial

Web responsive de estética editorial, pensada para un medio argentino de política, actualidad, análisis e informes. Construida con **React + Vite + Supabase**. Lista para desplegar en **Vercel**.

## Arrancar en tu computadora

1. Instalar Node.js 20 o posterior.
2. En esta carpeta: `npm install`
3. Ejecutar: `npm run dev`
4. Abrir la dirección local que muestra la terminal.

La portada funciona sin configurar servicios externos, con **seis notas ficticias de demostración**. No publicarlas como noticias reales. Para editar y publicar artículos es necesario activar Supabase.

## Activar usuarios, contraseña y redacción privada

1. Creá un proyecto en [Supabase](https://supabase.com/).
2. En **SQL Editor**, ejecutá el contenido de `supabase.sql` (solo una vez).
3. En **Authentication > Users**, creá los usuarios del equipo con email y contraseña (o mediante invitaciones administradas). Para no abrir el registro a extraños, mantené deshabilitado el registro público en Auth.
4. Por cada usuario, buscá su UUID y agregalo a `public.editors` con `role` (`admin`, `editor` o `writer`) según el ejemplo al final de `supabase.sql`. Sin estar en `editors`, no puede editar publicaciones.
5. Copiá `.env.example` a `.env.local` y completá `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY` desde **Project Settings > API**. Usá la clave *anon/publishable*, **NUNCA** `service_role`.
6. Reiniciá el servidor con `npm run dev`. Ingresá a **Ingresar**, iniciá sesión y publicá.

### Permisos implementados

- Anónimo: solo lectura de artículos publicados.
- Usuario autenticado no autorizado: no puede guardar, editar ni leer borradores.
- Writer: crea artículos; modifica solamente los propios.
- Editor/admin: crean y modifican artículos del equipo.
- La autenticación y el control real de permisos se validan en **Supabase Auth + Row Level Security**, no solo en el frontend.

**Nota:** el contenido demo se guarda en código (`src/data.js`), no en la base de datos. Al agregar publicaciones reales, aparecen antes que las demostraciones. Para el lanzamiento definitivo, eliminá o reemplazá los ejemplos del archivo.

## Desplegar en Vercel

1. Subí esta carpeta a un repositorio de GitHub.
2. En Vercel elegí **Add New > Project** y seleccioná el repositorio.
3. Framework preset: **Vite**. Build command: `npm run build`. Output directory: `dist`.
4. En **Settings > Environment Variables** agregá las dos variables `VITE_SUPABASE_*` con los valores reales.
5. Desplegá. No hace falta servidor dedicado.

## Próximas mejoras recomendadas

- Quitar las notas de ejemplo y publicar artículos revisados con autor, fecha y fuentes.
- Cargar imágenes propias y agregar créditos fotográficos.
- Panel editorial con calendario, comentarios y aprobación previa a publicar.
- URLs individuales para artículos, SEO/Open Graph, newsletter, analítica y dominio.
- Página institucional **Quiénes somos** y política de correcciones/editorial.

## Seguridad y alcance

- Login real al configurar Supabase. Sin variables de entorno, el botón muestra claramente que el sistema no está habilitado: **no simula autenticación ni guarda contraseñas**.
- La demo es un prototipo funcional inicial, no un CMS completo ni un portal con noticias verificadas en vivo.
- Antes del lanzamiento real, conviene revisar protección antiabuso, backups, políticas de contenido, fuentes, privacidad y permisos de equipo.
