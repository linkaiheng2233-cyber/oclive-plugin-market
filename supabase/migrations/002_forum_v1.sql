-- Forum v1 tables + RLS + profile donation fields

-- profiles: donation + (optional) ban flag used by forum RLS
alter table public.profiles
  add column if not exists donation_url text not null default '',
  add column if not exists donation_qr_url text not null default '',
  add column if not exists is_banned boolean not null default false;

-- forum_categories (boards)
create table if not exists public.forum_categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  description text not null default '',
  sort_order int not null default 0,
  is_locked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- forum_threads (topics)
create table if not exists public.forum_threads (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.forum_categories(id) on delete restrict,
  author_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  status text not null default 'published' check (status in ('published', 'hidden', 'locked')),
  tags text[] not null default '{}',
  reply_count int not null default 0,
  last_reply_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_forum_threads_category on public.forum_threads(category_id, created_at desc);
create index if not exists idx_forum_threads_status on public.forum_threads(status);
create index if not exists idx_forum_threads_author on public.forum_threads(author_id);

-- forum_posts (floors; includes 1L)
create table if not exists public.forum_posts (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.forum_threads(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  floor int not null,
  status text not null default 'published' check (status in ('published', 'hidden')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (thread_id, floor)
);

create index if not exists idx_forum_posts_thread on public.forum_posts(thread_id, floor asc);
create index if not exists idx_forum_posts_author on public.forum_posts(author_id);
create index if not exists idx_forum_posts_status on public.forum_posts(status);

-- reports
create table if not exists public.forum_reports (
  id uuid primary key default gen_random_uuid(),
  target_type text not null check (target_type in ('thread', 'post')),
  target_id uuid not null,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason_code text not null check (reason_code in ('spam', 'abuse', 'illegal', 'other')),
  reason_text text not null default '',
  status text not null default 'open' check (status in ('open', 'handled', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_forum_reports_status on public.forum_reports(status, created_at desc);
create index if not exists idx_forum_reports_reporter on public.forum_reports(reporter_id, created_at desc);
create index if not exists idx_forum_reports_target on public.forum_reports(target_type, target_id);

-- moderation audit actions
create table if not exists public.forum_moderation_actions (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid not null references public.profiles(id) on delete cascade,
  action text not null check (action in ('hide_thread', 'hide_post', 'lock_thread', 'ban_user', 'unban_user', 'note')),
  target_type text not null,
  target_id uuid not null,
  note text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists idx_forum_mod_actions_actor on public.forum_moderation_actions(actor_id, created_at desc);
create index if not exists idx_forum_mod_actions_target on public.forum_moderation_actions(target_type, target_id, created_at desc);

-- updated_at triggers (reuse style from schema.sql)
create or replace function public.touch_forum_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_forum_categories_touch on public.forum_categories;
create trigger trg_forum_categories_touch
before update on public.forum_categories
for each row execute function public.touch_forum_updated_at();

drop trigger if exists trg_forum_threads_touch on public.forum_threads;
create trigger trg_forum_threads_touch
before update on public.forum_threads
for each row execute function public.touch_forum_updated_at();

drop trigger if exists trg_forum_posts_touch on public.forum_posts;
create trigger trg_forum_posts_touch
before update on public.forum_posts
for each row execute function public.touch_forum_updated_at();

drop trigger if exists trg_forum_reports_touch on public.forum_reports;
create trigger trg_forum_reports_touch
before update on public.forum_reports
for each row execute function public.touch_forum_updated_at();

-- floor allocator: lock the thread row to avoid concurrent floor collisions
create or replace function public.assign_forum_post_floor()
returns trigger
language plpgsql
as $$
declare
  next_floor int;
begin
  -- lock the thread row (serializes per-thread inserts)
  perform 1 from public.forum_threads t where t.id = new.thread_id for update;

  select coalesce(max(p.floor), 0) + 1
    into next_floor
  from public.forum_posts p
  where p.thread_id = new.thread_id;

  new.floor = next_floor;
  return new;
end;
$$;

drop trigger if exists trg_forum_posts_assign_floor on public.forum_posts;
create trigger trg_forum_posts_assign_floor
before insert on public.forum_posts
for each row execute function public.assign_forum_post_floor();

-- maintain reply_count / last_reply_at (counts published posts excluding 1L)
create or replace function public.on_forum_post_inserted()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'published' then
    update public.forum_threads t
      set reply_count = greatest(0, (
            select count(*) from public.forum_posts p
            where p.thread_id = new.thread_id
              and p.status = 'published'
              and p.floor > 1
          )),
          last_reply_at = case when new.floor > 1 then new.created_at else t.last_reply_at end
    where t.id = new.thread_id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_forum_posts_after_insert on public.forum_posts;
create trigger trg_forum_posts_after_insert
after insert on public.forum_posts
for each row execute function public.on_forum_post_inserted();

-- RLS
alter table public.forum_categories enable row level security;
alter table public.forum_threads enable row level security;
alter table public.forum_posts enable row level security;
alter table public.forum_reports enable row level security;
alter table public.forum_moderation_actions enable row level security;

-- helper: current user is admin?
create or replace function public.is_admin(uid uuid)
returns boolean
language sql
stable
as $$
  select exists (select 1 from public.profiles p where p.id = uid and p.is_admin = true);
$$;

-- helper: current user is banned?
create or replace function public.is_banned(uid uuid)
returns boolean
language sql
stable
as $$
  select exists (select 1 from public.profiles p where p.id = uid and p.is_banned = true);
$$;

-- forum_categories policies
drop policy if exists "forum categories readable" on public.forum_categories;
create policy "forum categories readable"
  on public.forum_categories
  for select
  using (true);

drop policy if exists "admin can manage forum categories" on public.forum_categories;
create policy "admin can manage forum categories"
  on public.forum_categories
  for all
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

-- forum_threads policies
drop policy if exists "forum threads readable" on public.forum_threads;
create policy "forum threads readable"
  on public.forum_threads
  for select
  using (
    status = 'published'
    or auth.uid() = author_id
    or public.is_admin(auth.uid())
  );

drop policy if exists "authenticated can create threads" on public.forum_threads;
create policy "authenticated can create threads"
  on public.forum_threads
  for insert
  to authenticated
  with check (
    auth.uid() = author_id
    and not public.is_banned(auth.uid())
    and exists (select 1 from public.forum_categories c where c.id = category_id and c.is_locked = false)
    and status in ('published', 'hidden', 'locked')
  );

drop policy if exists "authors can update own threads" on public.forum_threads;
create policy "authors can update own threads"
  on public.forum_threads
  for update
  to authenticated
  using (auth.uid() = author_id)
  with check (auth.uid() = author_id and not public.is_banned(auth.uid()));

drop policy if exists "admin can update threads" on public.forum_threads;
create policy "admin can update threads"
  on public.forum_threads
  for update
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

-- forum_posts policies
drop policy if exists "forum posts readable" on public.forum_posts;
create policy "forum posts readable"
  on public.forum_posts
  for select
  using (
    status = 'published'
    or auth.uid() = author_id
    or public.is_admin(auth.uid())
  );

drop policy if exists "authenticated can create posts" on public.forum_posts;
create policy "authenticated can create posts"
  on public.forum_posts
  for insert
  to authenticated
  with check (
    auth.uid() = author_id
    and not public.is_banned(auth.uid())
    and exists (
      select 1
      from public.forum_threads t
      join public.forum_categories c on c.id = t.category_id
      where t.id = thread_id
        and t.status <> 'locked'
        and c.is_locked = false
    )
  );

drop policy if exists "authors can update own posts" on public.forum_posts;
create policy "authors can update own posts"
  on public.forum_posts
  for update
  to authenticated
  using (auth.uid() = author_id)
  with check (auth.uid() = author_id and not public.is_banned(auth.uid()));

drop policy if exists "admin can update posts" on public.forum_posts;
create policy "admin can update posts"
  on public.forum_posts
  for update
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

-- reports policies
drop policy if exists "reporter or admin can read reports" on public.forum_reports;
create policy "reporter or admin can read reports"
  on public.forum_reports
  for select
  to authenticated
  using (reporter_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists "authenticated can create reports" on public.forum_reports;
create policy "authenticated can create reports"
  on public.forum_reports
  for insert
  to authenticated
  with check (reporter_id = auth.uid() and not public.is_banned(auth.uid()));

drop policy if exists "admin can update reports" on public.forum_reports;
create policy "admin can update reports"
  on public.forum_reports
  for update
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

-- moderation actions policies (admin only)
drop policy if exists "admin can read moderation actions" on public.forum_moderation_actions;
create policy "admin can read moderation actions"
  on public.forum_moderation_actions
  for select
  to authenticated
  using (public.is_admin(auth.uid()));

drop policy if exists "admin can insert moderation actions" on public.forum_moderation_actions;
create policy "admin can insert moderation actions"
  on public.forum_moderation_actions
  for insert
  to authenticated
  with check (public.is_admin(auth.uid()) and actor_id = auth.uid());

-- Seed default categories (idempotent via slug uniqueness)
insert into public.forum_categories (slug, title, description, sort_order)
values
  ('plugin', '插件论坛', '插件讨论与经验分享', 10),
  ('innovation', '创新论坛', '开放实验场与新点子', 20),
  ('rolepack', '角色包论坛', '角色包发布与交流', 30),
  ('debug', '调试论坛', '排障与日志分析', 40),
  ('newbie', '新手论坛', '从 0 开始上手', 50),
  ('free', '自由论坛', '随便聊聊', 60),
  ('qa', '问题论坛', '提问与解答', 70)
on conflict (slug) do nothing;

