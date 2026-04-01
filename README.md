# CodeBuddy 个人助理一键配置

把 CodeBuddy 变成你的私人编程助理。通过 tmux 后台常驻，随时通过企业微信对话。

## 它是什么

- **企业微信接入** — 通过企微机器人随时对话，手机/电脑都能用
- **tmux 后台常驻** — 断开 SSH 后 CodeBuddy 继续运行
- **快捷别名** — `cbc` 一键启动/连接，`F12` 脱离 tmux
- **身份设定** — 自定义 Bot 名字、回复风格、技术栈偏好
- **记忆管理** — Auto Memory + Typed Memory，跨会话记住你的偏好
- **模块化** — 脚本拆分为独立模块，便于维护和扩展

## 前置条件

| 依赖 | 说明 |
|------|------|
| Linux 系统 | 支持 bash + tmux |
| Node.js | 安装 CodeBuddy 的前提（脚本可自动安装） |
| tmux | 后台会话管理（脚本可自动安装） |
| CodeBuddy Code | `npm install -g @tencent-ai/codebuddy-code`（脚本可自动安装） |

## 快速开始

### 完整安装

```bash
git clone git@github.com:kyeo-hub/setup-codebuddy-assistant.git
cd setup-codebuddy-assistant
bash setup.sh
```

脚本会交互式引导完成：系统检查 → 安装依赖 → 安装 CodeBuddy → 配置身份 → 配置记忆 → 设置别名 → 安装 Skill。

### 远程执行（curl | bash）

```bash
# 国内环境（通过代理）
bash <(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main/setup.sh)

# 国际环境
bash <(curl -fsSL https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main/setup.sh)
```

## 命令参考

```bash
bash setup.sh                  # 完整安装配置（交互式）
bash setup.sh --install-deps   # 仅安装系统依赖（Node.js、tmux）
bash setup.sh --install-cb     # 仅安装 CodeBuddy CLI
bash setup.sh --upgrade        # 一键升级
bash setup.sh --uninstall      # 一键卸载
bash setup.sh --health         # 健康检查
bash setup.sh --check          # 仅检查系统环境
```

## 日常使用

```bash
cbc            # 启动或连接 CodeBuddy（tmux 会话名: codebuddy）
cbc-stop       # 关闭 CodeBuddy 会话
```

启动后输入 `/remote-control` 连接企微机器人。

### tmux 快捷键

| 操作 | 快捷键 |
|------|--------|
| 分离会话（后台运行） | 直接按 `F12` |
| 重新连接 | `cbc` |
| 关闭会话 | `cbc-stop` |

> codebuddy 的 TUI 会拦截 `Ctrl+B`，`cbc` 别名已将 `F12` 绑定为 tmux 分离键。

### CodeBuddy 内置命令

| 命令 | 说明 |
|------|------|
| `/init-setup` | 交互式调整配置 |
| `/remote-control` | 远程控制面板（管理企微连接） |
| `/memory` | 管理记忆文件 |
| `/config` | 查看/修改设置 |

## 项目结构

```
setup-codebuddy-assistant/
├── setup.sh              # 入口脚本（参数解析、流程编排）
├── lib/
│   ├── common.sh         # 公共函数：日志、颜色、工具
│   ├── check.sh          # 系统检查：OS、架构、网络、依赖版本
│   ├── install-deps.sh   # 安装 Node.js、tmux
│   ├── install-codebuddy.sh  # 安装/更新 CodeBuddy CLI
│   ├── config.sh         # 环境变量、CODEBUDDY.md、settings.json
│   ├── aliases.sh        # tmux 别名（cbc / cbc-stop）
│   ├── skill.sh          # /init-setup Skill
│   ├── upgrade.sh        # 一键升级
│   ├── uninstall.sh      # 一键卸载
│   ├── health.sh         # 健康检查
│   └── backup.sh         # 配置备份（升级前自动执行）
├── _legacy/              # 旧版单文件脚本（仅供参考）
└── README.md
```

## License

MIT
