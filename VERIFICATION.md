# Estado de verificación — 22 de octubre de 2026

## Confirmado

- Compilación Vite de producción exitosa y revisión de espacios/patches sin errores.
- Cambios guardados en el repositorio original, rama main.
- Migraciones aplicadas en el Supabase existente. No había artículos ni cuentas previas.
- Variables públicas de Supabase configuradas en producción, preview y desarrollo del proyecto Vercel `mesachica`.
- Despliegue de producción READY en https://mesachica-five.vercel.app.
- Portada comprobada en navegador real, incluyendo categorías obtenidas desde Supabase y formulario de acceso habilitado.
- Pruebas SQL bajo roles reales anon/authenticated: borrador propio, rechazo de publicación por redactor, rechazo de elevación de rol, rechazo de categorías por redactor, aislamiento de borradores frente a cuenta ajena, publicación por editor, autor técnico inmutable, lectura pública, bloqueo de modificación publicada por redactor, despublicación y administración de roles. Resultado PASS.
- Pruebas SQL de políticas de objetos: carga en carpeta propia, rechazo de carpeta ajena, lectura de galería propia y detección de imagen referenciada. Resultado PASS. No equivale a transferir un archivo por Storage API.
- Supabase Security Advisor: sin alertas después de mover consultas de autorización a esquema privado.
- Todas las pruebas de base se ejecutaron con rollback. Base confirmada sin usuarios, notas ni archivos de prueba después de ejecutarlas.

## Implementado, pendiente de prueba con sesión real

Inicio/cierre de sesión, formulario del dashboard, guardado persistente entre sesiones y recargas, publicación visible en portada, edición de categorías/autores/equipo, carga y eliminación mediante Storage API. Las pruebas SQL verifican las reglas de la base; no reemplazan esta prueba de interfaz y API.

La creación de una cuenta temporal de administrador fue rechazada por revisión automática por requerir autorización explícita. No se creó esa cuenta ni se intentó una vía alternativa. Hace falta el correo del administrador real y autorización para el acceso de prueba, o una sesión real existente.

## Pendientes de operación

- Crear/asignar la cuenta real de administrador e invitar al equipo.
- Desactivar registro público de Supabase Auth (actualmente habilitado; las cuentas sin membresía no tienen permisos editoriales).
- Configurar URL del sitio, redirecciones, SMTP y recuperación de contraseña desde Supabase Auth.
- Publicar notas reales. Los ejemplos se conservan en código pero están ocultos en producción.
- Las URLs de artículos usan hash; SEO con metadatos por nota y renderizado servidor queda fuera de esta implementación.
