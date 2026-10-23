-- Transactional integration test: all fixtures and publication changes roll back.
begin;
select set_config('test.article',(select id::text from public.articles where title like 'PRUEBA TÉCNICA%' limit 1),true);
select set_config('test.admin',(select user_id::text from public.editors where role='admin' limit 1),true);
select set_config('request.jwt.claim.sub',current_setting('test.admin'),true);
update public.articles set status='published' where id=current_setting('test.article')::uuid;
set local role authenticated;
do $$ declare root_id uuid; reply_id uuid; begin
 insert into public.comments(article_id,full_name,body) values(current_setting('test.article')::uuid,'Nombre Ignorado','Prueba temporal de hilo editorial.') returning id into root_id;
 perform set_config('test.root',root_id::text,true);
 insert into public.comments(article_id,parent_id,full_name,body) values(current_setting('test.article')::uuid,root_id,'Nombre Ignorado','Respuesta temporal de hilo editorial.') returning id into reply_id;
 perform set_config('test.reply',reply_id::text,true);
 if not exists(select 1 from public.comments where id=root_id and status='approved') then raise exception 'Direct publication failed'; end if;
end $$;
reset role;
-- An authenticated identity without editorial membership cannot moderate/delete.
select set_config('request.jwt.claim.sub',gen_random_uuid()::text,true);
set local role authenticated;
do $$ declare changed integer; begin
 delete from public.comments where id=current_setting('test.root')::uuid; get diagnostics changed=row_count;
 if changed<>0 then raise exception 'Reader deleted comment'; end if;
 update public.comments set status='rejected' where id=current_setting('test.root')::uuid; get diagnostics changed=row_count;
 if changed<>0 then raise exception 'Reader moderated comment'; end if;
end $$;
reset role;
select set_config('request.jwt.claim.sub',current_setting('test.admin'),true);
set local role authenticated;
delete from public.comments where id=current_setting('test.root')::uuid;
do $$ begin
 if exists(select 1 from public.comments where id=current_setting('test.root')::uuid) then raise exception 'Editorial delete failed'; end if;
 if not exists(select 1 from public.comments where id=current_setting('test.reply')::uuid and parent_id is null) then raise exception 'Reply preservation failed'; end if;
end $$;
insert into public.comment_reads(user_id,seen_at) values(auth.uid(),now()) on conflict(user_id) do update set seen_at=excluded.seen_at;
reset role;
rollback;
