alter table public.authors
 add column headline text not null default '' check(length(headline)<=200),
 add column interests text not null default '' check(length(interests)<=500),
 add column photo_url text not null default '' check(photo_url='' or photo_url ~ '^https?://[^[:space:]]+$'),
 add column linkedin_url text not null default '' check(linkedin_url='' or linkedin_url ~ '^https?://[^[:space:]]+$'),
 add column website_url text not null default '' check(website_url='' or website_url ~ '^https?://[^[:space:]]+$');
create or replace function private.image_in_use(object_name text) returns boolean language sql stable security definer set search_path='' as $$
select exists(select 1 from public.articles where right(image_url,length(object_name)+1)='/'||object_name)
 or exists(select 1 from public.authors where right(photo_url,length(object_name)+1)='/'||object_name)
$$;
revoke all on function private.image_in_use(text) from public;
grant execute on function private.image_in_use(text) to authenticated;
