begin;
create or replace function private.image_in_use(object_name text) returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.articles where right(image_url,length(object_name)+1)='/'||object_name)$$;
revoke all on function private.image_in_use(text) from public;
grant execute on function private.image_in_use(text) to authenticated;
create policy editorial_list on storage.objects for select to authenticated using(bucket_id='editorial' and (private.team_role() in ('admin','editor') or (private.team_role()='writer' and (storage.foldername(name))[1]=auth.uid()::text)));
create policy editorial_delete_unused on storage.objects for delete to authenticated using(bucket_id='editorial' and (private.team_role() in ('admin','editor') or (private.team_role()='writer' and (storage.foldername(name))[1]=auth.uid()::text)) and not private.image_in_use(name));
commit;
