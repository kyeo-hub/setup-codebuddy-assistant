# CodeBuddy 个人助理一键配置

把 CodeBuddy 变成你的私人编程助理。一条命令搞定企微接入、身份设定和记忆管理，通过 tmux 后台常驻。

## 它是什么

基于 [CodeBuddy Code](https://codebuddy.cn/) 的个人助理方案：

- **企业微信接入** — 通过企微机器人随时对话，手机/电脑都能用
- **tmux 后台常驻** — 断开 SSH 后 CodeBuddy 继续运行
- **快捷别名** — `cbc` 一键启动/连接，`cbc-stop` 关闭
- **身份设定** — 自定义 Bot 名字、回复风格、技术栈偏好
- **记忆管理** — Auto Memory + Typed Memory，跨会话记住你的偏好
- **一键部署** — 新设备一条命令完成全部配置

## 前置条件

| 依赖 | 说明 |
|------|------|
| Linux 系统 | 支持 bash + tmux |
| tmux | `apt install -y tmux` 或 `yum install -y tmux` |
| Node.js | 安装 CodeBuddy 的前提 |
| CodeBuddy Code | `npm install -g @tencent-ai/codebuddy-code` |
| 企业微信 Bot | [智能机器人接入指南](https://developer.work.weixin.qq.com/document/path/101463) |

## 快速开始

### 0. 前置准备

```bash
# 安装 tmux（如果没有）
sudo apt install -y tmux   # Debian/Ubuntu
# 或 sudo yum install -y tmux  # CentOS/RHEL

# 安装 CodeBuddy
npm install -g @tencent-ai/codebuddy-code
codebuddy
# 在 CodeBuddy 中执行 /login 完成登录

# 获取企微 Bot 凭据
# 登录企业微信管理后台 → 应用管理 → 智能机器人 → 复制 Bot ID 和 Bot Secret
```

### 1. 一键配置

```bash
# 国内环境（通过 ghfast 代理）
bash <(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main/setup-codebuddy-assistant.sh)

# 国际环境（直连）
bash <(curl -fsSL https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main/setup-codebuddy-assistant.sh)

# 克隆到本地执行
git clone git@github.com:kyeo-hub/setup-codebuddy-assistant.git
cd setup-codebuddy-assistant
bash setup-codebuddy-assistant.sh
```

### 配置流程

脚本会交互式引导你完成以下配置：

| 步骤 | 内容 |
|------|------|
| Step 1 | 配置企微 Bot 环境变量（写入 ~/.bashrc） |
| Step 2 | 身份设定（Bot 名字、你的角色、技术栈、回复风格） |
| Step 3 | 启用 Auto Memory + Typed Memory |
| Step 4 | 配置 tmux 快捷别名（cbc / cbc-stop） |
| Step 5 | 安装 /init-setup Skill（后续交互式调整配置） |

## 日常使用

### 启动和连接

```bash
cbc            # 启动或连接 CodeBuddy（tmux 会话名: codebuddy）
cbc-stop       # 关闭 CodeBuddy 会话
```

- 如果已有运行中的 `codebuddy` tmux 会话，`cbc` 会直接连接
- 如果没有，`cbc` 会创建新会话并启动 codebuddy
- **分离会话**: 直接按 `F12`（不要按 Ctrl+D，那会终止进程）

### 连接企微

在 CodeBuddy 中输入 `/remote-control`，选择 wecom-bot 并连接。

### CodeBuddy 内置命令

| 命令 | 说明 |
|------|------|
| `/init-setup` | 交互式调整身份、记忆、规则等配置 |
| `/memory` | 管理记忆文件 |
| `/config` | 查看/修改设置 |
| `/clear` | 清空当前对话上下文 |
| `/compact` | 压缩上下文 |
| `/remote-control` | 远程控制面板（管理企微等连接） |

### 记忆系统

- **Auto Memory** — CodeBuddy 自动记住重要信息（偏好、决策、项目状态）
- **Typed Memory** — 结构化记忆，4 种类型：
  - `user` — 你的角色、目标、背景
  - `feedback` — 你对 Bot 的纠正和指导
  - `project` — 项目进展和决策
  - `reference` — 外部系统和资源指引

### 会话恢复

```bash
codebuddy --continue    # 继续上次对话
codebuddy --resume      # 选择历史会话恢复
```

## 修改配置

### 调整个人设定

编辑 `~/.codebuddy/CODEBUDDY.md`，修改后下次启动 CodeBuddy 生效：

```markdown
## 身份设定
- 你的名字是"小码"，是 YangKai 的私人编程助手
- YangKai 的角色：资深工程师
- YangKai 主要使用的技术栈：Go, Python, TypeScript

## 回复偏好
- 回复语言：简体中文
- 回复风格：简洁直接，不要废话
```

或者直接在 CodeBuddy 中运行 `/init-setup`，交互式修改。

### 企微 Bot 凭据

```bash
vim ~/.bashrc
# 修改 CODEBUDDY_WECOM_BOT_ID 和 CODEBUDDY_WECOM_BOT_SECRET
source ~/.bashrc
```

## 配置文件说明

```
~/.codebuddy/
├── CODEBUDDY.md              # 身份设定（Bot名字、用户角色、回复偏好）
├── settings.json             # 全局设置（语言、记忆、权限等）
├── rules/                    # 模块化个人规则
├── skills/
│   └── init-setup/
│       └── SKILL.md          # 交互式配置向导
├── memories/
│   ├── global/               # 全局记忆
│   └── {project-id}/         # 项目记忆
└── agents/                   # 自定义子代理
```

## 一键更新

```bash
bash <(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main/setup-codebuddy-assistant.sh) --update
```

## 一键卸载

```bash
bash <(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main/setup-codebuddy-assistant.sh) --uninstall
```

## 常见问题

### 服务器重启后需要重新启动吗？

是的，tmux 会话不会在重启后存活。重新 SSH 上去执行 `cbc` 即可。

### 如何查看 Bot 是否正常工作？

```bash
cbc            # 连接 CodeBuddy，检查 /remote-control 连接状态
```

在企微中发送测试消息验证。

### tmux 常用操作

| 操作 | 快捷键 |
|------|--------|
| 分离会话（后台运行） | 直接按 `F12` |
| 重新连接 | `cbc` 或 `tmux attach -t codebuddy` |
| 关闭会话 | `cbc-stop` |

> codebuddy 的 TUI 界面会拦截 `Ctrl+B`，所以 tmux 默认的分离快捷键不可用。`cbc` 别名已将 `F12` 绑定为直接分离键。

## License

MIT
