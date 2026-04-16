# 版本兼容性（编写器与主程序）

**编写器**（oclive-pack-editor）与 **Oclive 主程序**（oclivenewnew）各自有版本号（见各项目 `package.json`），采用 **语义化版本** `主版本.次版本.修订号`。

---

## 当前推荐（0.2.x）

| 编写器 | 主程序 |
|--------|--------|
| **0.2.x** | **0.2.0** 及以上（同为 **0.2** 线最稳妥） |

在此组合下，角色包中的 **`ui.json`**（整壳、插槽、主题、布局等）与当前公开的 schema 一致，可减少「导出了但主程序不认」的问题。

---

## 升级建议

- **建议保持编写器与主程序同为 0.2.x**，或至少 **次版本不要跨太大**；发新版后若出现异常，请两边都更新到最新 **0.2.x** 再试。
- 若只升级其一，可能出现：编写器多出来的字段在主程序里**暂时不用**，或主程序已支持的新能力旧编写器**导不出**——以各自 [CHANGELOG](https://github.com/linkaiheng2233-cyber/oclivenewnew/blob/main/CHANGELOG.md) 为准。

---

## 如何查看版本

- **主程序**：安装包或关于页；仓库 **`oclivenewnew`** 的 `package.json`。
- **编写器**：关于页；仓库 **`oclive-pack-editor`** 的 `package.json`。

需要更细的契约、未来版本规划与开发者说明，请访问 [GitHub 上的完整文档](https://github.com/linkaiheng2233-cyber/oclivenewnew/tree/main/creator-docs)。
