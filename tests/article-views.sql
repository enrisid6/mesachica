begin;
select set_config('test.article',(select id::text from public.articles where title like 'PRUEBA TÉCNICA%' limit 1),true);
update public.articles set status='published' where id=current_setting('test.article')::uuid;
set local role anon;
do $$ declare article uuid=current_setting('test.article')::uuid; session_a uuid=gen_random_uuid(); session_b uuid=gen_random_uuid(); before_count bigint; first_count bigint; begin
 select coalesce((select views from public.article_stats where article_id=article),0) into before_count;
 first_count=public.record_article_view(article,session_a);
 if first_count<>before_count+1 then raise exception 'First view failed'; end if;
 if public.record_article_view(article,session_a)<>first_count then raise exception 'Reload counted twice'; end if;
 if public.record_article_view(article,session_b)<>first_count+1 then raise exception 'New session not counted'; end if;
 if public.record_article_view(gen_random_uuid(),session_a) is not null then raise exception 'Missing article counted'; end if;
 if has_table_privilege('anon','public.article_stats','UPDATE') then raise exception 'Public can forge counter'; end if;
end $$;
reset role;
update public.articles set status='draft' where id=current_setting('test.article')::uuid;
set local role anon;
do $$ begin
 if public.record_article_view(current_setting('test.article')::uuid,gen_random_uuid()) is not null then raise exception 'Draft counted'; end if;
 if exists(select 1 from public.article_stats where article_id=current_setting('test.article')::uuid) then raise exception 'Draft metrics exposed'; end if;
end $$;
reset role;
rollback;
