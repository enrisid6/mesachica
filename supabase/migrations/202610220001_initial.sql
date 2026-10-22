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
