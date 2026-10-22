-- Ejecutar en Supabase > SQL Editor. Usuarios se crean en Authentication > Users.
create extension if not exists pgcrypto;
create table if not exists public.editors (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Redactor',
  role text not null default 'writer' check (role in ('writer','editor','admin'))
);
create table if not exists public.articles (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  deck text not null default '',
  section text not null check (section in ('Actualidad','Análisis','Informes','Internacional','Ideas')),
  topic text not null default '',
  author text not null default 'Equipo editorial',
  image_url text not null default '',
  body text not null,
  read_minutes int not null default 5 check (read_minutes between 1 and 60),
  status text not null default 'draft' check(status in ('draft','published')),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid not null default auth.uid() references auth.users(id)
);
alter table public.editors enable row level security;
alter table public.articles enable row level security;
create policy "Editors view own membership" on public.editors for select to authenticated using (user_id=auth.uid());
create policy "Published articles are public" on public.articles for select to anon, authenticated using(status='published');
create policy "Team can read work" on public.articles for select to authenticated using(exists (select 1 from public.editors where user_id=auth.uid()));
create policy "Team can insert" on public.articles for insert to authenticated with check(exists(select 1 from public.editors where user_id=auth.uid()) and created_by=auth.uid());
create policy "Editors can update; writers own" on public.articles for update to authenticated using(exists(select 1 from public.editors e where e.user_id=auth.uid() and (e.role in ('editor','admin') or public.articles.created_by=auth.uid()))) with check(exists(select 1 from public.editors e where e.user_id=auth.uid() and (e.role in ('editor','admin') or public.articles.created_by=auth.uid())));
-- Primer usuario: copiá UUID desde Authentication > Users y ejecutá:
-- insert into public.editors (user_id, display_name, role)
-- values ('REEMPLAZAR-UUID','Fundador','admin');
-- Repetir para cada integrante. NO habilitar inscripción pública sin invitaciones.
begin;
create or replace function public.team_role() returns text language sql stable security definer set search_path='' as $$select role from public.editors where user_id=(select auth.uid())$$;
revoke all on function public.team_role() from public;
grant execute on function public.team_role() to anon, authenticated;
create table if not exists public.categories(id uuid primary key default gen_random_uuid(), name text unique not null check(length(trim(name)) between 1 and 80));
insert into public.categories(name) values ('Actualidad'),('Análisis'),('Informes'),('Internacional'),('Ideas') on conflict do nothing;
insert into public.categories(name) select distinct section from public.articles on conflict do nothing;
create table if not exists public.authors(id uuid primary key default gen_random_uuid(), name text not null check(length(trim(name)) between 1 and 160), bio text not null default '');
insert into public.authors(name) select distinct author from public.articles a where not exists(select 1 from public.authors b where b.name=a.author);
alter table public.articles drop constraint if exists articles_section_check;
alter table public.articles add constraint articles_section_fkey foreign key(section) references public.categories(name) on update cascade;
alter table public.articles add column if not exists author_id uuid references public.authors(id) on delete set null;
alter table public.articles add column if not exists image_credit text not null default '';
alter table public.articles add column if not exists image_alt text not null default '';
update public.articles a set author_id=(select id from public.authors b where b.name=a.author limit 1) where author_id is null;
-- Replace policies installed by the original application.
drop policy if exists "Admins or authors delete" on public.articles;
drop trigger if exists article_change_guard on public.articles;
drop policy if exists "Editors view own membership" on public.editors;
drop policy if exists "Published articles are public" on public.articles;
drop policy if exists "Team can read work" on public.articles;
drop policy if exists "Team can insert" on public.articles;
drop policy if exists "Editors can update; writers own" on public.articles;
drop function if exists public.guard_article_changes();
drop function if exists public.can_write_article(uuid);
drop function if exists public.can_publish_article();
drop function if exists public.is_team_member();
create policy memberships_read on public.editors for select to authenticated using(user_id=auth.uid() or public.team_role()='admin');
create policy memberships_insert on public.editors for insert to authenticated with check(public.team_role()='admin');
create policy memberships_update on public.editors for update to authenticated using(public.team_role()='admin') with check(public.team_role()='admin');
create policy articles_read on public.articles for select to anon,authenticated using(status='published' or public.team_role() in ('admin','editor') or (public.team_role()='writer' and created_by=auth.uid()));
create policy articles_insert on public.articles for insert to authenticated with check(created_by=auth.uid() and (public.team_role() in ('admin','editor') or (public.team_role()='writer' and status='draft')));
create policy articles_update on public.articles for update to authenticated using(public.team_role() in ('admin','editor') or (public.team_role()='writer' and created_by=auth.uid() and status='draft')) with check(public.team_role() in ('admin','editor') or (public.team_role()='writer' and created_by=auth.uid() and status='draft'));
create or replace function public.article_guard() returns trigger language plpgsql set search_path='' as $$
begin
 if TG_OP='UPDATE' and (new.created_by is distinct from old.created_by or new.created_at is distinct from old.created_at) then raise exception 'No se puede transferir la propiedad de una nota'; end if;
 new.updated_at=now();
 if new.status='published' then new.published_at=coalesce(new.published_at,now()); else new.published_at=null; end if;
 if new.author_id is not null then select name into new.author from public.authors where id=new.author_id; end if;
 return new;
end $$;
create trigger article_guard before insert or update on public.articles for each row execute function public.article_guard();
alter table public.categories enable row level security;
alter table public.authors enable row level security;
create policy categories_read on public.categories for select to anon,authenticated using(true);
create policy categories_manage on public.categories for all to authenticated using(public.team_role() in ('admin','editor')) with check(public.team_role() in ('admin','editor'));
create policy authors_read on public.authors for select to anon,authenticated using(true);
create policy authors_manage on public.authors for all to authenticated using(public.team_role() in ('admin','editor')) with check(public.team_role() in ('admin','editor'));
grant select on public.articles,public.categories,public.authors to anon;
grant select,insert,update on public.articles,public.editors to authenticated;
grant select,insert,update,delete on public.categories,public.authors to authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('editorial','editorial',true,5242880,array['image/jpeg','image/png','image/webp','image/avif']) on conflict(id) do nothing;
create policy editorial_upload on storage.objects for insert to authenticated with check(bucket_id='editorial' and public.team_role() in ('admin','editor','writer') and (storage.foldername(name))[1]=auth.uid()::text);
create index if not exists articles_publication_idx on public.articles(status,published_at desc);
create index if not exists articles_owner_idx on public.articles(created_by);
commit;
begin;
create schema if not exists private;
alter function public.team_role() set schema private;
grant usage on schema private to anon,authenticated;
create or replace function public.membership_guard() returns trigger language plpgsql set search_path='' as $$begin
 if new.user_id is distinct from old.user_id then raise exception 'La cuenta del integrante no se puede cambiar'; end if;
 if old.user_id=auth.uid() and new.role is distinct from old.role then raise exception 'Otro administrador debe cambiar tu rol'; end if;
 return new;
end$$;
revoke all on function public.membership_guard() from public;
create trigger membership_guard before update on public.editors for each row execute function public.membership_guard();
revoke all on function public.article_guard() from public;
commit;
begin;
create or replace function private.image_in_use(object_name text) returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.articles where right(image_url,length(object_name)+1)='/'||object_name)$$;
revoke all on function private.image_in_use(text) from public;
grant execute on function private.image_in_use(text) to authenticated;
create policy editorial_list on storage.objects for select to authenticated using(bucket_id='editorial' and (private.team_role() in ('admin','editor') or (private.team_role()='writer' and (storage.foldername(name))[1]=auth.uid()::text)));
create policy editorial_delete_unused on storage.objects for delete to authenticated using(bucket_id='editorial' and (private.team_role() in ('admin','editor') or (private.team_role()='writer' and (storage.foldername(name))[1]=auth.uid()::text)) and not private.image_in_use(name));
commit;
