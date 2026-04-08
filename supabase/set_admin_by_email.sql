-- 将你的账号设为管理员（把邮箱改成你自己的）
-- 在 SQL Editor 中执行一次即可。

update public.profiles
set is_admin = true
where id = (
  select id
  from auth.users
  where lower(email) = lower('your-email@example.com')
  limit 1
);

-- 验证
-- select id, username, is_admin from public.profiles;
