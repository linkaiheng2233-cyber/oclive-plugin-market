# OCLive 社区站原型

**暂停迭代，保留实现供研究与后续评估。它不是 A.I.Live 客户端内置的“插件与后端管理”。**

A paused Supabase-backed community-site prototype for OCLive, separate from in-app plugin management.

本仓包含资源浏览、详情、外部下载链接、登录后投稿与公告界面。站点是否可用还取决于部署、数据源和认证配置，源码存在不代表已有一个持续运营的公共服务。

## 普通用户入口

体验角色与管理运行时能力，请从 [A.I.Live 主仓库](https://github.com/linkaiheng2233-cyber/oclivenewnew)及其[用户手册](https://github.com/linkaiheng2233-cyber/oclivenewnew/blob/main/creator-docs/getting-started/USER_MANUAL.md)开始。

公开目录文件分别在 [插件目录](https://github.com/linkaiheng2233-cyber/awesome-oclive-plugins)和[角色包目录](https://github.com/linkaiheng2233-cyber/awesome-oclive-roles)维护；这些索引与本社区站不是同一交付物。

## 研究与本地开发

本仓 CI 使用 Node.js 22。准备依赖后，可按 `.env.example` 配置自己的 Supabase 项目，再运行：

```bash
npm ci
npm run dev
```

数据库与演示数据说明见 [supabase/README.md](supabase/README.md)，实际脚本见 [package.json](package.json)。缺少数据源配置时，浏览和投稿不能作为可用功能验收。

## 部署与边界

[Pages workflow](.github/workflows/pages.yml)会在默认发布分支推送时构建并部署；维护者应先确认自己有意更新该站点，再合并会触发部署的变更。前端 `VITE_*` 会进入构建产物，服务端特权密钥不应写入前端配置；访问控制仍须由数据服务的实际策略负责。

网站职责说明见主仓[社区站分区文档](https://github.com/linkaiheng2233-cyber/oclivenewnew/blob/main/creator-docs/roadmap/PLUGIN_WEB_SECTION.md)。暂停状态和未来重启属于单独的产品决定，本页不把路线图描述为已提供的服务。

问题与研究建议可提交 [Issue](https://github.com/linkaiheng2233-cyber/oclive-plugin-market/issues)。


<!-- Preserve previously published section bookmarks. -->
<a id="oclive-插件市场社区站-v1"></a>
<a id="开发"></a>
<a id="supabase"></a>
<a id="管理员与公告"></a>
<a id="路由说明"></a>
<a id="演示数据可选"></a>
<a id="构建与部署"></a>
<a id="安全"></a>

旧版章节书签保留在此。[整理前的首页](https://github.com/linkaiheng2233-cyber/oclive-plugin-market/blob/33b52827117888d50a04f8c5f3059e8390c04c1b/README.md)可用于查阅历史说明；现行入口以本页与所链文档为准。
