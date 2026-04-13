-- 沐沐语气 · 创作者指路公告（市场首页/公告列表）
-- 在 Supabase SQL Editor 以 postgres 执行即可；方案 A 不依赖 is_admin。
-- 同标题先删再插：重复执行本文件不会叠多条本标题。

delete from public.content_items
where type = 'announcement'
  and title = '沐沐的小喇叭：给创作者指个路';

insert into public.content_items (
  type, title, description, tags, author_id, status, download_url, version, metadata
)
select
  'announcement',
  '沐沐的小喇叭：给创作者指个路',
  E'嗨，是我沐沐～

**你现在看的这个站**：用来逛大家挂的资源、点外链、登录后发自己的条目；公告栏也会更新近况。

如果你是 **创作者**，「说明书」的正本在主程序仓库里，不用在市场里找完整契约哦：

- **按任务选读**：打开 **oclivenewnew** 仓库里的文档索引（复制到浏览器打开即可）  
  https://github.com/linkaiheng2233-cyber/oclivenewnew/blob/main/creator-docs/getting-started/DOCUMENTATION_INDEX.md  
  想做角色包、侧车、还是对接启动器，从表里点进去就行。
- **角色包编辑**：用独立仓库 **oclive-pack-editor** 导出 zip；包的 **manifest / settings** 以主仓 **`roles/README_MANIFEST.md`** 和 **`creator-docs/role-pack/`** 为准。
- **HTTP 侧车与 JSON-RPC 协议**：主仓 **`creator-docs/plugin-and-architecture/REMOTE_PLUGIN_PROTOCOL.md`**（本市场仓库 README 顶部也有链过去）。

发资源还是老规矩：**链接谁挂的谁负责**，点下载前多看一眼对方仓库说明～

我去继续填架子啦，有问题欢迎去主仓或各工具仓库提 issue。',
  array['沐沐', '公告', '创作者']::text[],
  p.id,
  'published',
  '',
  '1.0.0',
  '{"voice": "mumu"}'::jsonb
from public.profiles p
order by p.created_at asc
limit 1;

-- select id, title, created_at from public.content_items where type = 'announcement' order by created_at desc limit 5;
