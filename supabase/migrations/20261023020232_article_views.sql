create table public.article_stats(article_id uuid primary key references public.articles(id) on delete cascade, views bigint not null default 0 check(views>=0));
alter table public.article_stats enable row level security;
create policy article_stats_read on public.article_stats for select to anon,authenticated using(exists(select 1 from public.articles a where a.id=article_id));
revoke all on public.article_stats from anon,authenticated;
grant select on public.article_stats to anon,authenticated;
create table private.article_view_sessions(article_id uuid not null references public.articles(id) on delete cascade,session_hash text not null,primary key(article_id,session_hash));
alter table private.article_view_sessions enable row level security;
revoke all on private.article_view_sessions from public,anon,authenticated;
create function private.record_article_view(p_article_id uuid,p_session uuid) returns bigint language plpgsql security definer set search_path='' as $$
declare added integer; total bigint;
begin
 if p_article_id is null or p_session is null then return null; end if;
 perform 1 from public.articles where id=p_article_id and status='published' for share;
 if not found then return null; end if;
 insert into private.article_view_sessions(article_id,session_hash) values(p_article_id,encode(sha256(convert_to(p_session::text,'UTF8')),'hex')) on conflict do nothing;
 get diagnostics added=row_count;
 if added=1 then
  insert into public.article_stats(article_id,views) values(p_article_id,1) on conflict(article_id) do update set views=public.article_stats.views+1;
 end if;
 select views into total from public.article_stats where article_id=p_article_id;
 return coalesce(total,0);
end $$;
revoke all on function private.record_article_view(uuid,uuid) from public;
grant usage on schema private to anon,authenticated;
grant execute on function private.record_article_view(uuid,uuid) to anon,authenticated;
create function public.record_article_view(p_article_id uuid,p_session uuid) returns bigint language sql security invoker set search_path='' as $$select private.record_article_view(p_article_id,p_session)$$;
revoke all on function public.record_article_view(uuid,uuid) from public;
grant execute on function public.record_article_view(uuid,uuid) to anon,authenticated;
