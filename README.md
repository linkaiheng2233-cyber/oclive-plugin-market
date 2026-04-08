# oclive 插件市场（静态站 + Supabase 可选后端）

列出 **角色包 / 插件 / 模块**，支持上传；角色包可接入 Supabase 云端存储。

- 契约说明：[PLUGIN_WEB_SECTION.md](https://github.com/linkaiheng2233-cyber/oclivenewnew/blob/main/creator-docs/roadmap/PLUGIN_WEB_SECTION.md)
- 协议文档：[REMOTE_PLUGIN_PROTOCOL.md](https://github.com/linkaiheng2233-cyber/oclivenewnew/blob/main/creator-docs/plugin-and-architecture/REMOTE_PLUGIN_PROTOCOL.md)

## 开发

推荐使用 **Node 22**（与 CI 一致；仓库根目录有 `.node-version` 供 nvm / fnm 等读取）。

```bash
npm install
npm run dev
```

## Supabase（云端账号 + 内容）

1. 复制 `.env.example` 为 `.env.local`，填入：

```bash
VITE_SUPABASE_URL=...
VITE_SUPABASE_ANON_KEY=...
VITE_ADMIN_EMAILS=你的邮箱@example.com
```

2. **SQL Editor** 整段执行 `supabase/schema.sql`（见 `supabase/README.md` 顺序说明）。
3. **Authentication**：启用邮箱登录（OTP / magic link）；在 **URL Configuration** 配置 Site URL 与 Redirect URLs（本地 + 线上），否则邮件链接无法回站点。
4. 用站点 **个人设置** 发登录邮件并完成一次登录（会写入 `profiles`）。
5. 管理员（二选一即可）：
   - 改 `set_admin_by_email.sql` 里的邮箱后执行；或
   - 仅依赖 `VITE_ADMIN_EMAILS`（无需改库）。

**是的：当前实现里管理员与普通用户一样，用邮箱魔法链接登录**；是否在 UI 里显示「管理」由 `profiles.is_admin` 或 `VITE_ADMIN_EMAILS` 决定。

> 未配置环境变量时，上传将退回本地浏览器存储（仅自己可见）。

## 构建与部署

```bash
npm run build
```

GitHub Pages 项目站会通过 `VITE_BASE` 自动处理子路径。

**打开站点时请用完整项目地址**，例如 `https://<用户名>.github.io/<仓库名>/`。若只打开 `https://<用户名>.github.io/`（用户主页根路径）且未单独部署用户站，会出现 **404**。构建时会生成与首页相同的 `404.html`，便于子路径刷新后仍由 Vue Router 接管。

### GitHub Pages 上使用 Supabase（重要）

CI 构建时会把 `VITE_*` **打进前端包**，请在仓库 **Settings → Secrets and variables → Actions** 添加与本地一致的：

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- `VITE_ADMIN_EMAILS`（可选）

否则线上站点无法连接云端，只会退回本地存储逻辑。

同时在 Supabase **Authentication → URL Configuration** 的 **Redirect URLs** 中加入你的 Pages 地址，例如：

`https://<你的用户名>.github.io/<仓库名>/**`

### 安全

- **不要**把 `VITE_SUPABASE_ANON_KEY`、`.env.local` 内容提交到 Git，也**不要**在聊天、截图、公开 issue 里贴出完整密钥；`anon` 虽非 `service_role`，仍可能被滥用刷配额。
- 若密钥曾泄露，请到 Supabase **Project Settings → API** 轮换 **anon** key，并同步更新本地 `.env.local` 与 GitHub Actions Secrets。
