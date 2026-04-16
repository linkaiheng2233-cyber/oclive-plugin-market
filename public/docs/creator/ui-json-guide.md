# 角色包里的 `ui.json` 是什么？

`ui.json` 放在**角色包根目录**（与导出后的其他文件在一起），用来描述 **Oclive 主界面推荐长什么样**：用哪个整壳插件、各插槽里有哪些插件、主题色和布局偏好等。

你在 **oclive-pack-editor（编写器）** 里改「前端设计」时，就是在填这些概念；导出角色包时，编写器会**自动生成** `ui.json`，一般不需要手抄 JSON。

---

## 在编写器里怎么配？

1. 打开编写器中的 **「前端设计」**（或名称相近的布局/主题面板）。
2. 选择 **整壳**（可选某个目录插件作为全屏外壳，或留空用内置主界面）。
3. 为各个 **插槽**（如聊天工具栏、设置页扩展区、角色详情区等）设置 **插件顺序** 与 **是否显示**。
4. 设置 **主题**（如主色、背景色、字体）和 **布局**（如侧栏在左/右、输入框在上/下等，具体选项以编写器为准）。

> **截图占位**：在此处附上编写器「前端设计」面板截图，便于新用户对照按钮位置。

---

## 文件里大概长什么样？（字段含义）

下面用通俗说法对应 `ui.json` 里的常见字段（具体键名以导出结果为准）：

| 区域 | 含义 |
|------|------|
| **`shell`** | 整壳目录插件的 **插件 ID**（`manifest.json` 里的 `id`）。空字符串表示使用 Oclive **内置主界面**。 |
| **`slots`** | 每个官方插槽一组 **`order`**（插件显示顺序）和 **`visible`**（哪些默认显示）。插槽名例如：`chat_toolbar`、`settings.panel`、`role.detail` 等（以编写器列表为准）。 |
| **`theme`** | 主题：**主色**、背景色、字体等（CSS 可用的颜色/字体值）。 |
| **`layout`** | 布局：例如侧栏相对聊天区在左还是右、输入区在消息列表上方还是下方等。 |

完整机器可读定义见主仓库中的 **`creator-docs/role-pack/ui.json.schema.json`**（随版本更新）。

---

## 一个简单的例子

```json
{
  "shell": "com.example.my.shell",
  "theme": {
    "primaryColor": "#7a6b58",
    "backgroundColor": "#f2ebe3"
  },
  "layout": {
    "sidebar": "left",
    "chatInput": "bottom"
  },
  "slots": {
    "chat_toolbar": {
      "order": ["com.example.toolbar"],
      "visible": ["com.example.toolbar"]
    },
    "settings.panel": {
      "order": [],
      "visible": []
    },
    "role.detail": {
      "order": [],
      "visible": []
    }
  }
}
```

上例仅作结构说明；**请以编写器导出为准**，不要复制粘贴后忘记改插件 ID。

---

## 和「后端设置」有什么区别？

- **`ui.json`**：管 **界面长什么样、插件摆在哪儿**（前端）。
- 角色包里的 **`settings.json`**：管 **对话引擎、模型、插件后端能力** 等（后端）。在编写器里通常也有对应表单，**不必**为了做角色内容去啃 JSON。

需要插件开发、桥接 API、目录插件 `manifest` 等内容，请到 [GitHub 上的完整创作者文档](https://github.com/linkaiheng2233-cyber/oclivenewnew/tree/main/creator-docs) 查看。
