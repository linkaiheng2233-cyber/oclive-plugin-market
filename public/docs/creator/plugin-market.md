# 插件市场与客户端安装

本站 **浏览/详情** 与 Oclive **桌面客户端** 通过统一约定打通：用 **`metadata.git`**（Git 克隆地址）发起安装，用 **公开插件索引 JSON** 与客户端默认源对齐。

---

## 1. 资源条目里的 `metadata.git`

在 Supabase 资源（如类型为 **插件**）的 **`metadata`** JSON 中建议填写：

```json
{
  "git": "https://github.com/your-org/your-plugin.git"
}
```

- 详情页 **「在 Oclive 客户端安装」** 仅依赖该字段，**不使用** `download_url` 作为协议安装源。  
- 点击后浏览器会导航到：`oclive://install?plugin=<经 URL 编码的 git 地址>`。

---

## 2. 本站环境变量 `VITE_PLUGIN_INDEX_URL`

仓库根目录 **`.env`**（或部署环境）可配置：

```bash
VITE_PLUGIN_INDEX_URL=https://raw.githubusercontent.com/linkaiheng2233-cyber/awesome-oclive-plugins/main/plugins.json
```

- **浏览页** 会在标题区显示「插件索引 JSON」外链（与客户端拉取的默认索引同源，便于核对）。  
- 构建时注入 Vite，修改后需重新 **`npm run build`**。

---

## 3. 客户端行为（概要）

- 已安装并注册 **`oclive://`** 协议后，系统会把链接交给 Oclive；客户端从查询参数 **`plugin`** 解析 Git 地址并执行安装/队列消费逻辑。  
- 若用户尚未安装客户端，详情页提供 **GitHub 最新发行版** 外链作为兜底（`oclive/oclive` releases）。  
- 客户端默认索引与上述 raw URL 一致；也可通过环境变量 **`OCLIVE_PLUGIN_INDEX_URL`** 覆盖。

更细的协议、索引字段与宿主命令以主程序仓库 **`creator-docs`** 与代码为准；本站文档仅保留创作者与市场运营需要的最小说明。

---

## 4. 公开索引仓库 `awesome-oclive-plugins`

索引文件 **`plugins.json`** 位于仓库 **默认分支** 根目录，raw 地址形如：

`https://raw.githubusercontent.com/linkaiheng2233-cyber/awesome-oclive-plugins/main/plugins.json`

向索引中追加条目时，请与客户端 **`PluginIndexEntry`** 字段对齐（至少包含 **`id`**、**`version`**、**`git`** 等；可选 **`dependencies`** 等）。具体 schema 以主程序 `plugin_installer` 与文档为准。
