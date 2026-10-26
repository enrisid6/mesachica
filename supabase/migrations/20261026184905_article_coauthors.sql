alter table public.articles add column coauthor_id uuid references public.authors(id) on delete set null;
alter table public.articles add constraint articles_distinct_authors check (coauthor_id is null or author_id is distinct from coauthor_id);
create index articles_coauthor_idx on public.articles(coauthor_id) where coauthor_id is not null;
