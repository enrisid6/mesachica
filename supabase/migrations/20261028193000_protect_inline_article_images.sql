-- Mantener protegidas las imágenes incluidas entre párrafos, además de las portadas.
create or replace function private.image_in_use(object_name text)
returns boolean language sql stable security definer set search_path='' as $$
  select exists (
    select 1 from public.articles
    where right(coalesce(image_url,''),length(object_name)+1)='/'||object_name
       or position('/'||object_name in coalesce(body,''))>0
  )
$$;
revoke all on function private.image_in_use(text) from public;
grant execute on function private.image_in_use(text) to authenticated;
