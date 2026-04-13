# Oclive 插件市场（社区站 V1）

以 **Supabase** 为数据源的动态站点：浏览资源、查看详情与外部下载链接、登录后发布内容、公告列表。首页为功能入口枢纽，并展示最新一条公告标题。

- 契约说明：[PLUGIN_WEB_SECTION.md](https://github.com/linkaiheng2233-cyber/oclivenewnew/blob/main/creator-docs/roadmap/PLUGIN_WEB_SECTION.md)
- 协议文档：[REMOTE_PLUGIN_PROTOCOL.md](https://github.com/linkaiheng2233-cyber/oclivenewnew/blob/main/creator-docs/plugin-and-architecture/REMOTE_PLUGIN_PROTOCOL.md)

## 开发

推荐使用 **Node 22**（与 CI 一致；仓库根目录有 `.node-version` 供 nvm / fnm 等读取）。

```bash
npm install
npm run dev
```

## Supabase

1. 复制 `.env.example` 为 `.env.local`，填入：

```bash
VITE_SUPABASE_URL=...
VITE_SUPABASE_ANON_KEY=...
VITE_ADMIN_EMAILS=你的邮箱@example.com
```

2. 在 SQL Editor 中执行 `supabase/schema.sql`（新建项目）。**已有项目**请再执行 `supabase/migrations/001_add_announcement_type.sql`（扩展 `type` 含 `announcement` 并收紧公告插入策略）。
3. **Authentication**：启用邮箱登录（OTP / magic link）；在 **URL Configuration** 配置 Site URL 与 Redirect URLs（本地 + 线上）。
4. 使用 **个人设置** 完成登录（写入 `profiles`）。

### 管理员与公告

- 前端「管理」入口：`profiles.is_admin` 或邮箱在 `VITE_ADMIN_EMAILS` 中。
- **发布公告**时，数据库 RLS 要求 `profiles.is_admin = true`。若仅配置环境变量而未把对应账号设为管理员，插入会失败；请执行 `set_admin_by_email.sql` 或在表中开启 `is_admin`。

### 路由说明

| 路径 | 说明 |
|------|------|
| `/` | 入口枢纽 + 最新公告 |
| `/browse` | 资源列表（可筛选类型） |
| `/item/:id` | 详情；非公告显示下载按钮 |
| `/submit` | 发布（需登录） |
| `/announcements` | 公告列表 |
| `/me`、`/manage`、`/admin`、`/versions` | 个人、我的上传、管理、版本下载 |

未配置 `VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY` 时，浏览与发布不可用。

## 构建与部署

```bash
npm run build
```

GitHub Pages 项目站会通过 `VITE_BASE` 自动处理子路径。构建生成 `404.html` 以便子路径刷新。

请在仓库 **Settings → Secrets and variables → Actions** 配置与本地一致的 `VITE_*`（见上）。

### 安全

- **不要**把 `VITE_SUPABASE_ANON_KEY`、`.env.local` 提交到 Git 或公开泄露。
