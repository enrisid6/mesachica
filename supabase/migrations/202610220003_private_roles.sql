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
