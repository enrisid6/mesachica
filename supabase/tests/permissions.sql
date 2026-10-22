-- Integration test against the real schema. All fixtures are rolled back.
begin;
insert into auth.users(id) values ('10000000-0000-0000-0000-000000000001'),('10000000-0000-0000-0000-000000000002'),('10000000-0000-0000-0000-000000000003'),('10000000-0000-0000-0000-000000000004');
insert into public.editors(user_id,role) values ('10000000-0000-0000-0000-000000000001','admin'),('10000000-0000-0000-0000-000000000002','editor'),('10000000-0000-0000-0000-000000000003','writer');
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
insert into public.articles(id,title,section,body) values('20000000-0000-0000-0000-000000000001','TEST writer','Ideas','Persistencia de prueba');
do $$begin
 begin insert into public.articles(title,section,body,status) values('UNAUTHORIZED','Ideas','x','published');raise exception 'FAIL writer published';exception when insufficient_privilege then null;end;
 begin update public.editors set role='admin' where user_id=auth.uid();if found then raise exception 'FAIL role escalation';end if;exception when insufficient_privilege then null;end;
 begin insert into public.categories(name) values('UNAUTHORIZED');raise exception 'FAIL writer managed categories';exception when insufficient_privilege then null;end;
end$$;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000004',true);
do $$begin
 if exists(select 1 from public.articles where id='20000000-0000-0000-0000-000000000001') then raise exception 'FAIL outsider read draft';end if;
 begin insert into public.articles(title,section,body) values('UNAUTHORIZED','Ideas','x');raise exception 'FAIL outsider inserted';exception when insufficient_privilege then null;end;
end$$;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
update public.articles set title='TEST edited',status='published' where id='20000000-0000-0000-0000-000000000001';
do $$begin
 if not exists(select 1 from public.articles where id='20000000-0000-0000-0000-000000000001' and status='published' and published_at is not null) then raise exception 'FAIL editor publishing';end if;
 begin update public.articles set created_by=auth.uid() where id='20000000-0000-0000-0000-000000000001';raise exception 'FAIL owner reassignment';exception when raise_exception then if sqlerrm='FAIL owner reassignment' then raise;end if;end;
end$$;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
do $$begin
 update public.articles set body='UNAUTHORIZED' where id='20000000-0000-0000-0000-000000000001';if found then raise exception 'FAIL writer edited published';end if;
end$$;
set local role anon;
select set_config('request.jwt.claim.sub','',true);
do $$begin
 if not exists(select 1 from public.articles where id='20000000-0000-0000-0000-000000000001') then raise exception 'FAIL public read';end if;
end$$;
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
update public.articles set status='draft' where id='20000000-0000-0000-0000-000000000001';
set local role anon;
select set_config('request.jwt.claim.sub','',true);
do $$begin
 if exists(select 1 from public.articles where id='20000000-0000-0000-0000-000000000001') then raise exception 'FAIL unpublished visible';end if;
end$$;
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
update public.editors set role='editor' where user_id='10000000-0000-0000-0000-000000000003';
do $$begin
 if not exists(select 1 from public.editors where user_id='10000000-0000-0000-0000-000000000003' and role='editor') then raise exception 'FAIL admin role management';end if;
end$$;
select 'PASS: writer draft, publish denial, role escalation denial, categories denial, outsider denial, editor publish, immutable owner, public visibility, writer published edit denial, unpublish, admin roles' as verification;
rollback;
