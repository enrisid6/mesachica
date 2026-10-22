begin;
create or replace function public.sync_author_name() returns trigger language plpgsql set search_path='' as $$begin
 update public.articles set author=new.name where author_id=new.id;
 return new;
end$$;
revoke all on function public.sync_author_name() from public;
create trigger sync_author_name after update of name on public.authors for each row when (old.name is distinct from new.name) execute function public.sync_author_name();
commit;
