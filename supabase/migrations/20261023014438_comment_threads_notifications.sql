alter table public.comments add column parent_id uuid references public.comments(id) on delete set null;
create index comments_parent on public.comments(parent_id);
grant insert(parent_id) on public.comments to authenticated;
alter table public.comments drop constraint comments_full_name_check;
alter table public.comments add constraint comments_full_name_check check(char_length(trim(full_name)) between 1 and 100);
create or replace function private.guard_reader_comment() returns trigger language plpgsql security definer set search_path='' as $$
declare editorial_name text;
begin
 if auth.uid() is null or new.user_id is distinct from auth.uid() then raise exception 'Iniciá sesión para comentar'; end if;
 if not exists(select 1 from auth.users where id=auth.uid() and email_confirmed_at is not null) then raise exception 'Ingresá a tu cuenta para comentar'; end if;
 if not exists(select 1 from public.articles where id=new.article_id and status='published') then raise exception 'Esta publicación no admite comentarios'; end if;
 if new.parent_id is not null and not exists(select 1 from public.comments where id=new.parent_id and article_id=new.article_id and status='approved') then raise exception 'El comentario al que respondés ya no está disponible'; end if;
 select display_name into editorial_name from public.editors where user_id=auth.uid() and role in ('admin','editor','writer');
 if editorial_name is not null then new.full_name=editorial_name;
 else
  if char_length(trim(new.full_name))<5 or trim(new.full_name) !~ '^[[:alpha:]][[:alpha:] ''’.-]+[[:space:]]+[[:alpha:]][[:alpha:] ''’.-]*$' then raise exception 'Ingresá tu nombre y apellido'; end if;
  perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
  if exists(select 1 from public.comments where user_id=auth.uid() and created_at>now()-interval '60 seconds') then raise exception 'Esperá un minuto antes de enviar otro comentario'; end if;
  if (select count(*) from public.comments where user_id=auth.uid() and created_at>now()-interval '1 day')>=10 then raise exception 'Alcanzaste el límite de 10 comentarios por día'; end if;
 end if;
 new.full_name=trim(new.full_name);new.body=trim(new.body);return new;
end $$;
revoke all on function private.guard_reader_comment() from public;
create table public.comment_reads(user_id uuid primary key references auth.users(id) on delete cascade,seen_at timestamptz not null default now());
alter table public.comment_reads enable row level security;
create policy comment_reads_select on public.comment_reads for select to authenticated using(user_id=(select auth.uid()) and private.team_role() in ('admin','editor'));
create policy comment_reads_insert on public.comment_reads for insert to authenticated with check(user_id=(select auth.uid()) and private.team_role() in ('admin','editor'));
create policy comment_reads_update on public.comment_reads for update to authenticated using(user_id=(select auth.uid()) and private.team_role() in ('admin','editor')) with check(user_id=(select auth.uid()) and private.team_role() in ('admin','editor'));
grant select,insert,update on public.comment_reads to authenticated;
