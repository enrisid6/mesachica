-- Additive change: retain legacy sections and all existing article content.
alter table public.articles add column theme text not null default '' check (theme in ('','Política nacional','Internacional','Economía','Sociedad','Regional','Otra'));
alter table public.articles add column featured boolean not null default false;
insert into public.categories(name) values ('Opinión') on conflict(name) do nothing;
create function private.guard_featured() returns trigger language plpgsql set search_path='' as $$
begin
 if auth.uid() is not null and coalesce(private.team_role(),'') not in ('admin','editor') then
  if (TG_OP='INSERT' and new.featured) or (TG_OP='UPDATE' and new.featured is distinct from old.featured) then
   raise exception 'Solo administradores y editores pueden destacar publicaciones';
  end if;
 end if;
 return new;
end $$;
revoke all on function private.guard_featured() from public;
create trigger guard_featured before insert or update on public.articles for each row execute function private.guard_featured();
