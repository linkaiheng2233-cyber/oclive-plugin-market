# Supabase 数据库脚本

## 在 SQL Editor 里按顺序做

1. **整段执行** `schema.sql`（建表、触发器、RLS、Storage 策略）。
2. 用浏览器在站点上 **邮箱登录一次**（确保 `auth.users` 里有你的用户，且触发器已写入 `profiles`）。
3. 如需数据库侧管理员标记，执行 `set_admin_by_email.sql`（先改邮箱再运行）。  
   或仅用前端环境变量 `VITE_ADMIN_EMAILS`（不写库也可以）。

## Auth（魔法链接）必配

在 Supabase **Authentication → URL Configuration**：

- **Site URL**：本地开发可填 `http://localhost:5173`（或你的预览域名）。
- **Redirect URLs** 增加：
  - `http://localhost:5173/**`
  - 生产环境：`https://你的域名/**` 以及 GitHub Pages：`https://<用户>.github.io/<仓库>/**`

否则点击邮件里的链接会报 redirect 不允许。
