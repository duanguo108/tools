# jq 工具与 PowerShell 剪贴板格式化

实现的效果：

安装 jq 并合入 PowerShell profile 之后：

- 新开的 PowerShell 中可直接运行 `jq`，不必每次手动改 PATH。
- 复制任意 JSON 到剪贴板，执行 `jsontidy`，剪贴板内容会被格式化为带缩进的 JSON，可直接粘贴；不是合法 JSON 时剪贴板保持原样。

示例：复制下面这种单行 JSON，再执行 `jsontidy`：

```json
{"name":"demo","items":[{"id":1,"ok":true}]}
```

剪贴板会变成：

```json
{
  "name": "demo",
  "items": [
    {
      "id": 1,
      "ok": true
    }
  ]
}
```

本目录提供两件事：

1. 在 Windows 上安装 [jq](https://jqlang.github.io/jq/)（命令行 JSON 处理器）。
2. 将 `Microsoft.PowerShell_profile.ps1` 合入 PowerShell 配置文件，使新开的终端能找到 `jq.exe`，并提供 `jsontidy` 命令：用 jq 格式化**系统剪贴板**里的 JSON。

官方下载页：[https://jqlang.github.io/jq/download/](https://jqlang.github.io/jq/download/)

---

## 安装 jq（Windows）

推荐使用 **winget**。本仓库的 profile 脚本按 winget 默认安装路径查找 `jq.exe`。

### 方式一：winget（推荐）

Windows 10（1809+）/ Windows 11 一般已自带 winget（随 App Installer 提供）。在 **PowerShell** 或 **Windows Terminal** 中执行：

```powershell
winget install --id jqlang.jq --exact
```

安装结束后：

1. **关闭并重新打开**当前终端（winget 写入的 PATH 对已打开的会话通常不生效）。
2. 验证：

```powershell
jq --version
```

应输出类似 `jq-1.8.2` 的版本号。

若提示找不到 `jq`，见下文 [PATH 未生效](#安装后找不到-jq)。

### 方式二：Scoop

```powershell
scoop install jq
```

### 方式三：Chocolatey

```powershell
choco install jq
```

### 方式四：手动下载可执行文件

从官方页下载对应架构的 `jq.exe`（例如 Windows AMD64），放到已在 `PATH` 中的目录，或自行把该目录加入用户 PATH。

---

## 安装后找不到 jq

winget 将便携包放在类似路径：

```text
%LOCALAPPDATA%\Microsoft\WinGet\Packages\jqlang.jq_Microsoft.Winget.Source_8wekyb3d8bbwe\
```

常见原因：安装时已打开的终端没有刷新 PATH。处理顺序：

1. 新开一个 PowerShell 窗口，再执行 `jq --version`。
2. 若仍失败，把本目录的 `Microsoft.PowerShell_profile.ps1` 合入用户 profile（见下一节）。脚本会在会话启动时把上述目录加入 `PATH`，并在 PATH 无效时按该路径（及 WinGet Packages 下递归查找）定位 `jq.exe`。
3. 确认包已安装：

```powershell
winget list --id jqlang.jq
```

---

## 使用 `Microsoft.PowerShell_profile.ps1`

该文件是 **CurrentUser、CurrentHost** 的 PowerShell 配置片段，不是独立可执行脚本。需要合入你的 `$PROFILE` 后，每次启动 PowerShell 才会生效。

### 脚本做了什么

| 内容 | 作用 |
| --- | --- |
| 启动时补 PATH | 若 `jq.exe` 已在 winget 默认目录中，但当前会话 PATH 尚未包含该目录，则追加到 `$env:PATH`。 |
| `Get-JqExe` | 解析 `jq.exe`：先 `Get-Command`，再试 winget 默认路径，再在 `%LOCALAPPDATA%\Microsoft\WinGet\Packages` 下递归查找。 |
| `jsontidy` | 读取剪贴板全文，用 `jq .` 做美化缩进；成功则写回剪贴板；不是合法 JSON 则**不覆盖**剪贴板。 |

### 合入用户 profile

1. 查看当前主机的 profile 路径：

```powershell
echo $PROFILE
```

Windows PowerShell 5.1 通常是：

```text
~\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
```

PowerShell 7+ 通常是：

```text
~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```

若 5.1 与 7 都要用，两套 profile 都需要合入（或其中一份 `.` 点源另一份）。

2. 若文件或目录不存在，先创建：

```powershell
if (-not (Test-Path -LiteralPath $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}
```

3. 把本目录 `Microsoft.PowerShell_profile.ps1` 的**全部内容**追加到 `$PROFILE`（不要覆盖已有的其它配置）。可用编辑器手动粘贴，或先 `cd` 到本目录再执行：

```powershell
Get-Content -LiteralPath .\Microsoft.PowerShell_profile.ps1 -Raw |
    Add-Content -LiteralPath $PROFILE
```

4. 若执行策略禁止加载 profile，当前用户可设为 `RemoteSigned`（按公司策略调整）：

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

5. **重新打开** PowerShell，确认函数已加载：

```powershell
Get-Command jsontidy
jq --version
```

### 使用 `jsontidy`

1. 复制一段 JSON 到剪贴板（例如从浏览器、日志、聊天窗口全选复制）。
2. 在已加载该 profile 的 PowerShell 中执行：

```powershell
jsontidy
```

3. 根据输出判断结果：

| 输出 | 含义 |
| --- | --- |
| `Clipboard JSON formatted.` | 已格式化并写回剪贴板，可直接粘贴。 |
| `Clipboard is empty.` | 剪贴板为空或只有空白，未改动。 |
| `Clipboard is not valid JSON; left unchanged.` | 不是合法 JSON，剪贴板保持原样；若 jq 有报错会同时 `Write-Warning`。 |
| `jq.exe not found...` | 未找到 jq，请先完成安装并确认 PATH / profile。 |

`jsontidy` 使用 UTF-8（无 BOM）读写临时文件，适合含中文的 JSON。

### 日常 jq 用法（与 profile 无关）

安装成功后也可直接在管道里用 jq，例如：

```powershell
Get-Content .\data.json -Raw | jq '.'
Get-Content .\data.json -Raw | jq '.items[0].id'
```

Windows 上从文件过滤时，更稳妥的方式是让 jq 读文件路径，避免编码问题：

```powershell
jq '.' .\data.json
```

---

## 依赖与限制

- **Windows + PowerShell**：`jsontidy` 依赖 `Get-Clipboard` / `Set-Clipboard`。
- **jq**：`jsontidy` 调用 `jq .`；未安装 jq 时命令会报错并返回。
- **winget 路径**：PATH 补丁针对包 ID `jqlang.jq` 的默认 WinGet 目录。若用 Scoop/Chocolatey/手动安装且 `jq.exe` 已在 PATH 中，`Get-JqExe` 仍可通过 `Get-Command` 找到。
- **会话范围**：合入 `$PROFILE` 后对新开的 PowerShell 生效；已打开的窗口需重开或手动 `. $PROFILE`。
)
</think>

FYI: https://chris48s.github.io/blogmarks/posts/2021/jsontidy/