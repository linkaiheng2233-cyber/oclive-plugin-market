create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  avatar_url text not null default '',
  is_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.content_items (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('character', 'plugin', 'module', 'branch')),
  title text not null,
  description text not null,
  tags text[] not null default '{}',
  author_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'published' check (status in ('published', 'hidden')),
  download_url text not null default '',
  version text not null default 'v1.0.0',
  metadata jsonb not null default '{}'::jsonb,
  download_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_published_at timestamptz not null default now()
);

create index if not exists idx_content_items_type on public.content_items(type);
create index if not exists idx_content_items_status on public.content_items(status);
create index if not exists idx_content_items_author on public.content_items(author_id);
create index if not exists idx_content_items_created on public.content_items(created_at desc);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles(id, username)
  values (new.id, coalesce(split_part(new.email, '@', 1), 'user_' || left(new.id::text, 8)))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.touch_profiles_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.touch_content_items_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  if new.status = 'published' then
    new.last_published_at = now();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_touch on public.profiles;
create trigger trg_profiles_touch
before update on public.profiles
for each row execute function public.touch_profiles_updated_at();

drop trigger if exists trg_content_items_touch on public.content_items;
create trigger trg_content_items_touch
before update on public.content_items
for each row execute function public.touch_content_items_updated_at();

alter table public.profiles enable row level security;
alter table public.content_items enable row level security;

drop policy if exists "profiles are readable" on public.profiles;
create policy "profiles are readable"
  on public.profiles
  for select
  using (true);

drop policy if exists "users can insert own profile" on public.profiles;
create policy "users can insert own profile"
  on public.profiles
  for insert
  to authenticated
  with check (auth.uid() = id);

drop policy if exists "users can update own profile" on public.profiles;
create policy "users can update own profile"
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "published content readable" on public.content_items;
create policy "published content readable"
  on public.content_items
  for select
  using (status = 'published' or auth.uid() = author_id or exists (
    select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true
  ));

drop policy if exists "authors can insert content" on public.content_items;
create policy "authors can insert content"
  on public.content_items
  for insert
  to authenticated
  with check (auth.uid() = author_id);

drop policy if exists "authors or admin can update content" on public.content_items;
create policy "authors or admin can update content"
  on public.content_items
  for update
  to authenticated
  using (auth.uid() = author_id or exists (
    select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true
  ))
  with check (auth.uid() = author_id or exists (
    select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true
  ));

drop policy if exists "authors or admin can delete content" on public.content_items;
create policy "authors or admin can delete content"
  on public.content_items
  for delete
  to authenticated
  using (auth.uid() = author_id or exists (
    select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true
  ));

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('content-files', 'content-files', true)
on conflict (id) do nothing;

drop policy if exists "avatar read public" on storage.objects;
create policy "avatar read public"
  on storage.objects for select
  using (bucket_id = 'avatars');

drop policy if exists "avatar upload own folder" on storage.objects;
create policy "avatar upload own folder"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and split_part(name, '/', 1) = auth.uid()::text
  );

drop policy if exists "avatar update own folder" on storage.objects;
create policy "avatar update own folder"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and split_part(name, '/', 1) = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and split_part(name, '/', 1) = auth.uid()::text
  );

drop policy if exists "avatar delete own folder" on storage.objects;
create policy "avatar delete own folder"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and split_part(name, '/', 1) = auth.uid()::text
  );

drop policy if exists "content files read public" on storage.objects;
create policy "content files read public"
  on storage.objects for select
  using (bucket_id = 'content-files');

drop policy if exists "content files write own folder" on storage.objects;
create policy "content files write own folder"
  on storage.objects for all to authenticated
  using (
    bucket_id = 'content-files'
    and split_part(name, '/', 1) = auth.uid()::text
  )
  with check (
    bucket_id = 'content-files'
    and split_part(name, '/', 1) = auth.uid()::text
  );
