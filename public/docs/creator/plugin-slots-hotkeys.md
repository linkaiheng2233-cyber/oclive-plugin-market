# 插件插槽与快捷键（与 Oclive 宿主对齐）

宿主 **10** 个官方语义插槽名、多外观 `appearance_id`、以及用户全局快捷键配置，以主程序仓库 `creator-docs/role-pack/SLOTS_AND_HOTKEYS.md` 为准（与 Oclive 发行版同步更新）。

## 市场条目可选字段

在资源 JSON 或展示用元数据中可附加（均为可选）：

- **`embeddedSlots`**：`string[]`，插件声明的槽名（去重列表）。
- **`uiSlotVariants`**：`{ "slot": string, "appearanceId": string, "label"?: string }[]`，用于展示多外观变体。

便于筛选「支持 `settings.plugins`」等插件；不参与宿主运行时校验。

安装与索引、协议约定见 **[插件市场与客户端安装](./plugin-market.md)**。
