-- 沐沐语气 · 开发计划公告
-- 在 Supabase SQL Editor 执行时一般为 postgres 角色，会绕过 RLS；author_id 取「任意一条」profiles 即可插入。
-- 若你坚持用 is_admin 当作者，把下面「方案 A」整段注释掉，改用「方案 B」。

-- ========== 方案 A（推荐：不依赖 is_admin，避免 0 行插入）==========
insert into public.content_items (
  type, title, description, tags, author_id, status, download_url, version, metadata
)
select
  'announcement',
  '沐沐的小喇叭：接下来要忙插件和角色包啦',
  E'嗨，是我这边来敲个黑板～

动态社区站这边已经能正常逛、能登录、能发资源了。我接下来会先搓几个 **插件** 和 **角色包** 填填架子，等页面上多一点真东西之后，再和大家一起把 **安全规则**（审核、举报那一套）慢慢收紧——不急在一时，但会认真对待。

如果你也在做 Oclive 相关的东西，欢迎把下载链接挂上来，路过的人说不定就用上了。链接还是老规矩：**作者自己对链接负责**，大家点之前多留个心眼哦。

先这样，去赶工啦～',
  array['沐沐', '公告', '开发计划']::text[],
  p.id,
  'published',
  '',
  '1.0.0',
  '{"voice": "mumu"}'::jsonb
from public.profiles p
order by p.created_at asc
limit 1;

-- 执行后在 SQL Editor 跑下面这句，确认是否多了一条公告（应看到新标题）：
-- select id, title, created_at from public.content_items where type = 'announcement' order by created_at desc limit 5;

-- ========== 方案 B（仅当存在管理员时插入；否则 0 行）==========
-- insert into public.content_items (
--   type, title, description, tags, author_id, status, download_url, version, metadata
-- )
-- select
--   'announcement',
--   '沐沐的小喇叭：接下来要忙插件和角色包啦',
--   E'...同上正文...',
--   array['沐沐', '公告', '开发计划']::text[],
--   p.id, 'published', '', '1.0.0', '{"voice": "mumu"}'::jsonb
-- from public.profiles p
-- where p.is_admin = true
-- order by p.created_at asc
-- limit 1;
