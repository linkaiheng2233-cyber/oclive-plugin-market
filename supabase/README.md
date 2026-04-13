# Supabase 数据库脚本

## 在 SQL Editor 里按顺序做

1. **整段执行** `schema.sql`（建表、触发器、RLS、Storage 策略）。
2. **已有项目**若早期建库，请再执行 `migrations/001_add_announcement_type.sql`（`announcement` 类型 + 公告仅管理员可插入）。
3. 用浏览器在站点上 **邮箱登录一次**（确保 `auth.users` 里有你的用户，且触发器已写入 `profiles`）。
4. 如需数据库侧管理员标记，执行 `set_admin_by_email.sql`（先改邮箱再运行）。**发布公告**依赖 `profiles.is_admin`，仅配 `VITE_ADMIN_EMAILS` 不足以通过 RLS。

## Auth（魔法链接）必配

在 Supabase **Authentication → URL Configuration**：

- **Site URL**：本地开发可填 `http://localhost:5173`（或你的预览域名）。
- **Redirect URLs** 增加：
  - `http://localhost:5173/**`
  - 生产环境：`https://你的域名/**` 以及 GitHub Pages：`https://<用户>.github.io/<仓库>/**`

否则点击邮件里的链接会报 redirect 不允许。

## 可选：演示数据（沐沐语气）

登录至少一次后，可在 SQL Editor 执行 `seed_demo_mumu.sql`，插入一条欢迎公告和一条示例插件（`author_id` 取最早注册的 `profiles`）。不要重复执行，否则会重复条目。

## 公告脚本（`announcements/`）

**告示常用操作（复制到 SQL Editor 执行）**见 [`announcements/OPERATIONS.md`](announcements/OPERATIONS.md)。

沐沐语气开发计划：`announcements/2026-04-09_dev_plugins_and_security_mumu.sql`。默认 **方案 A**（取最早一条 `profiles` 作为 `author_id`）。该文件已「同标题先删再插」，重复执行一般不会叠多条同标题。
