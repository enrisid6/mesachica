create table public.comments (
 id uuid primary key default gen_random_uuid(),
 article_id uuid not null references public.articles(id) on delete cascade,
 user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 full_name text not null check(char_length(trim(full_name)) between 5 and 100 and trim(full_name) ~ '^[[:alpha:]][[:alpha:] ''’.-]+[[:space:]]+[[:alpha:]][[:alpha:] ''’.-]*$'),
 body text not null check(char_length(trim(body)) between 10 and 3000),
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 created_at timestamptz not null default now()
);
create index comments_article_status_date on public.comments(article_id,status,created_at);
create index comments_user_date on public.comments(user_id,created_at);
create index comments_status_date on public.comments(status,created_at);
alter table public.comments enable row level security;
create policy comments_read on public.comments for select to anon,authenticated using (
 private.team_role() in ('admin','editor') or
 (exists(select 1 from public.articles a where a.id=article_id and a.status='published') and (status='approved' or user_id=(select auth.uid())))
);
create policy comments_insert on public.comments for insert to authenticated with check(user_id=(select auth.uid()) and status='pending' and exists(select 1 from public.articles a where a.id=article_id and a.status='published'));
create policy comments_moderate on public.comments for update to authenticated using(private.team_role() in ('admin','editor')) with check(private.team_role() in ('admin','editor'));
revoke all on public.comments from anon,authenticated;
grant select on public.comments to anon,authenticated;
grant insert(article_id,full_name,body) on public.comments to authenticated;
grant update(status) on public.comments to authenticated;
create function private.guard_reader_comment() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or new.user_id is distinct from auth.uid() then raise exception 'Iniciá sesión para comentar'; end if;
 if not exists(select 1 from auth.users where id=auth.uid() and email_confirmed_at is not null) then raise exception 'Confirmá tu correo antes de comentar'; end if;
 if not exists(select 1 from public.articles where id=new.article_id and status='published') then raise exception 'Esta publicación no admite comentarios'; end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
 if exists(select 1 from public.comments where user_id=auth.uid() and created_at>now()-interval '60 seconds') then raise exception 'Esperá un minuto antes de enviar otro comentario'; end if;
 if (select count(*) from public.comments where user_id=auth.uid() and created_at>now()-interval '1 day')>=10 then raise exception 'Alcanzaste el límite de 10 comentarios por día'; end if;
 new.full_name=trim(new.full_name);new.body=trim(new.body);
 return new;
end $$;
revoke all on function private.guard_reader_comment() from public;
create trigger guard_reader_comment before insert on public.comments for each row execute function private.guard_reader_comment();
