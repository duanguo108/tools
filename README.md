# 工具集

本仓库收集日常使用的小工具。每个子目录对应一个工具，详细步骤见该目录下的文档。

## 工具列表

| 工具 | 目录 | 简介 |
| --- | --- | --- |
| jq | [jq tool](./jq%20tool/) | Windows 上安装 [jq](https://jqlang.github.io/jq/)（JSON 命令行处理器），并提供 PowerShell 函数 `jsontidy`：把系统剪贴板里的 JSON 格式化后再写回剪贴板。非法 JSON 不会被覆盖。 |

## jq

- **作用**：处理 JSON；配合 `jsontidy` 可一键整理剪贴板中的 JSON。
- **主要内容**：
  - 安装 jq（推荐 winget）
  - 将 `Microsoft.PowerShell_profile.ps1` 合入 PowerShell `$PROFILE`
- **效果**：新开的 PowerShell 可直接运行 `jq`；复制 JSON 后执行 `jsontidy`，剪贴板变为带缩进的 JSON。
- **文档**：[jq tool/README.md](./jq%20tool/README.md)
