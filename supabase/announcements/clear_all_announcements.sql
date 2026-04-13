-- 删除「所有」type = announcement 的行（公告列表清空）
-- 在 Supabase SQL Editor 以 postgres 执行。清完后若要一条沐沐公告，再整段执行 2026-04-09_dev_plugins_and_security_mumu.sql 一次即可。

delete from public.content_items
where type = 'announcement';
