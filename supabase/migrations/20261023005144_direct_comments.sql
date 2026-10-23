alter table public.comments alter column status set default 'approved';
drop policy comments_insert on public.comments;
create policy comments_insert on public.comments for insert to authenticated with check(user_id=(select auth.uid()) and status='approved' and exists(select 1 from public.articles a where a.id=article_id and a.status='published'));
create policy comments_delete on public.comments for delete to authenticated using(private.team_role() in ('admin','editor'));
grant delete on public.comments to authenticated;

