-- 可选演示数据：沐沐语气的公告 + 一条示例插件（挂在「最早创建的 profiles」上）
-- 使用前请至少登录过一次站点，确保存在 profiles 行。
-- 在 Supabase SQL Editor 整段执行；若重复执行可能报唯一冲突，可先删同名标题或改标题。

insert into public.content_items (
  type, title, description, tags, author_id, status, download_url, version, metadata
)
select
  'announcement',
  '欢迎来到沐沐的社区小站～',
  E'嗨，我是沐沐这边的入口文案（演示用）。\n\n这里会挂上大家做的角色包、插件和小模块。你可以先随便逛逛；有好东西也欢迎贴下载链接上来，让路过的人都能摸到～\n\n论坛还在装修，别急，先在这边玩～',
  array['welcome', '沐沐']::text[],
  p.id,
  'published',
  '',
  '1.0.0',
  '{}'::jsonb
from public.profiles p
order by p.created_at asc
limit 1;

-- 示例资源（插件占位，执行过一次即可；重复执行会多出多条，可自行删除）
insert into public.content_items (
  type, title, description, tags, author_id, status, download_url, version, metadata
)
select
  'plugin',
  '示例：Remote 插件投稿占位',
  E'这是一条演示用的插件条目，方便你检查列表和详情页长什么样。\n\n真正发布时请换成你自己的仓库说明、兼容版本和下载地址～',
  array['demo', 'plugin', '示例']::text[],
  p.id,
  'published',
  'https://github.com/linkaiheng2233-cyber/oclivenewnew',
  '0.0.0-demo',
  '{"demo": true}'::jsonb
from public.profiles p
order by p.created_at asc
limit 1;
