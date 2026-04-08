# oclive 插件市场（静态站）

列出 **Remote HTTP 侧车** 项目信息；**下载与源码在作者仓库**，本站只维护 `public/data/plugins.json`。

- **契约说明**（主仓）：[PLUGIN_WEB_SECTION.md](https://github.com/linkaiheng2233-cyber/oclivenewnew/blob/main/creator-docs/roadmap/PLUGIN_WEB_SECTION.md)  
- **JSON-RPC 协议**：[REMOTE_PLUGIN_PROTOCOL.md](https://github.com/linkaiheng2233-cyber/oclivenewnew/blob/main/creator-docs/plugin-and-architecture/REMOTE_PLUGIN_PROTOCOL.md)

## 开发

```bash
npm install
npm run dev
```

## 构建（可部署到 GitHub Pages / 任意静态托管）

```bash
npm run build
```

产物在 `dist/`。将 `base` 设为子路径时，改 `vite.config.ts` 里 `base: '/仓库名/'`。

## 新增条目

编辑 `public/data/plugins.json`，在 `plugins` 数组中追加对象（字段见主仓 `PLUGIN_WEB_SECTION.md`）。
