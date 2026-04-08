# oclive 插件市场（静态站）

列出 **Remote HTTP 侧车** 项目信息；**下载与源码在作者仓库**，本站只维护 `public/data/plugins.json`。

- **契约说明**（主仓）：[PLUGIN_WEB_SECTION.md](https://github.com/linkaiheng2233-cyber/oclivenewnew/blob/main/creator-docs/roadmap/PLUGIN_WEB_SECTION.md)  
- **JSON-RPC 协议**：[REMOTE_PLUGIN_PROTOCOL.md](https://github.com/linkaiheng2233-cyber/oclivenewnew/blob/main/creator-docs/plugin-and-architecture/REMOTE_PLUGIN_PROTOCOL.md)

## 开发

```bash
npm install
npm run dev
```

浏览器打开终端里提示的本地地址（默认 `http://localhost:5173`）。

## 构建

```bash
npm run build
```

- **本地预览根路径**：`vite.config.ts` 默认 `base` 为 `/`，直接 `npm run preview` 即可。  
- **GitHub Pages（项目站）**：地址为 `https://<用户>.github.io/<仓库名>/`，CI 会自动设置 `VITE_BASE=/<仓库名>/`，无需手改。

产物在 `dist/`。

## GitHub Pages 部署（本仓库已含 workflow）

1. 在 GitHub 打开本仓库 **Settings → Pages**。  
2. **Build and deployment**：Source 选 **GitHub Actions**（不要选 branch 直出 `dist`）。  
3. 推送至 `main` 后，工作流 **Deploy to GitHub Pages** 会构建并发布；站点 URL 在 **Actions** 与 **Pages** 页面可见。

若首次部署报权限错误，确认 **Settings → Actions → General → Workflow permissions** 为 **Read and write**，并允许 **GitHub Pages** 创建。

## 新增条目

编辑 `public/data/plugins.json`，在 `plugins` 数组中追加对象（字段见主仓 `PLUGIN_WEB_SECTION.md`）。

## CI

- **Pull Request**：`.github/workflows/ci.yml` 仅做 `npm ci` + `npm run build`（与 Pages 相同的 `VITE_BASE`）。  
- **Push `main`**：`.github/workflows/pages.yml` 构建并部署到 Pages。
