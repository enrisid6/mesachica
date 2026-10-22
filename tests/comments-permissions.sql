begin;
select set_config('test.article_id',(select id::text from public.articles where title like 'PRUEBA TÉCNICA%' limit 1),true);
select set_config('test.user_id',(select user_id::text from public.editors where role='admin' limit 1),true);
-- Existing technical draft is published only inside this rolled-back transaction.
update public.articles set status='published' where id=current_setting('test.article_id')::uuid;
select set_config('request.jwt.claim.sub',current_setting('test.user_id'),true);
select set_config('request.jwt.claims',json_build_object('sub',current_setting('test.user_id'),'role','authenticated')::text,true);
-- Temporarily remove editorial membership to exercise a reader's permissions.
delete from public.editors where user_id=current_setting('test.user_id')::uuid;
set local role authenticated;
insert into public.comments(article_id,full_name,body) values (current_setting('test.article_id')::uuid,'Lector Prueba','Comentario técnico temporal para verificar permisos.');
do $$ declare changed integer; begin
 if (select count(*) from public.comments)<>1 then raise exception 'Reader cannot see own pending comment'; end if;
 update public.comments set status='approved'; get diagnostics changed=row_count;
 if changed<>0 then raise exception 'Reader approved a comment'; end if;
 begin
  insert into public.comments(article_id,full_name,body) values (current_setting('test.article_id')::uuid,'Lector Prueba','Segundo comentario debe rechazarse por límite de tiempo.');
  raise exception 'Rate limit failed';
 exception when others then if sqlerrm='Rate limit failed' then raise; end if; end;
end $$;
reset role;
select set_config('request.jwt.claim.sub','',true);
select set_config('request.jwt.claims','{}',true);
set local role anon;
do $$ begin if (select count(*) from public.comments)<>0 then raise exception 'Pending comment leaked'; end if; end $$;
reset role;
update public.comments set status='approved';
set local role anon;
do $$ begin if (select count(*) from public.comments)<>1 then raise exception 'Approved comment not public'; end if; end $$;
reset role;
update public.articles set status='draft' where id=current_setting('test.article_id')::uuid;
set local role anon;
do $$ begin if (select count(*) from public.comments)<>0 then raise exception 'Comments exposed on draft'; end if; end $$;
reset role;
rollback;
