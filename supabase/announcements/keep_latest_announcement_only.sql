-- 删除除「最新一条」外的所有 announcement（按 created_at，并列时用 id 打破平局）
-- 需要多条公告并存时不要执行本文件。
-- 在 Supabase SQL Editor 以 postgres 执行。

delete from public.content_items c
where c.type = 'announcement'
  and c.id <> (
    select ci.id
    from public.content_items ci
    where ci.type = 'announcement'
    order by ci.created_at desc, ci.id desc
    limit 1
  );
