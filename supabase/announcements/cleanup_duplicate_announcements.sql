-- 公告去重 / 删旧留新（在 Supabase SQL Editor 以 postgres 执行，绕过 RLS）
-- 每次跑「插入公告」脚本都会新增一行，不会自动覆盖旧行。

-- 1) 先看有哪些公告（记下要删的 id，或确认要留哪一条）
select id, title, created_at
from public.content_items
where type = 'announcement'
order by created_at desc;

-- 2) 按 id 精确删除（把下面的 uuid 换成上一步查到的「旧」那条）
-- delete from public.content_items
-- where id = '00000000-0000-0000-0000-000000000000';

-- 多条一起删：
-- delete from public.content_items
-- where type = 'announcement'
--   and id in (
--     'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
--     'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
--   );

-- 3) 一键：只保留「最新一条」公告（其余 type=announcement 全部删掉）
--    若你以后需要多条公告并存，不要用这段。
-- delete from public.content_items c
-- where c.type = 'announcement'
--   and c.id <> (
--     select ci.id
--     from public.content_items ci
--     where ci.type = 'announcement'
--     order by ci.created_at desc, ci.id desc
--     limit 1
--   );
