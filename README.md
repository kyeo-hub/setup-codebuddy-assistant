# CodeBuddy 个人助理一键配置

把 CodeBuddy 变成你的 7x24 私人编程助理。一条命令搞定后台常驻、企微接入、身份设定和记忆管理。

## 它是什么

基于 [CodeBuddy Code](https://codebuddy.cn/) 的个人助理方案，实现类似 OpenClaw 的体验：

- **企业微信接入** — 通过企微机器人随时对话，手机/电脑都能用
- **后台常驻** — systemd 服务管理，开机自启，崩溃自动重启
- **身份设定** — 自定义 Bot 名字、回复风格、技术栈偏好
- **记忆管理** — Auto Memory + Typed Memory，跨会话记住你的偏好
- **一键部署** — 新设备一条命令完成全部配置

## 前置条件

| 依赖 | 说明 |
|------|------|
| Linux 系统 | systemd 管理后台服务 |
| Node.js | 安装 CodeBuddy 的前提 |
| CodeBuddy Code | `npm install -g @tencent-ai/codebuddy-code` |
| 企业微信 Bot | [智能机器人接入指南](https://developer.work.weixin.qq.com/document/path/101463) |

## 快速开始

### 0. 前置准备

```bash
# 安装 CodeBuddy
npm install -g @tencent-ai/codebuddy-code
codebuddy
# 在 CodeBuddy 中执行 /login 完成登录

# 获取企微 Bot 凭据
# 登录企业微信管理后台 → 应用管理 → 智能机器人 → 复制 Bot ID 和 Bot Secret
```

### 1. 一键启动（curl | bash）

不留本地文件，直接远程执行。国内环境需加代理：

```bash
# 国内环境（通过 ghfast 代理）
bash <(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main/setup-codebuddy-assistant.sh)

# 国际环境（直连）
bash <(curl -fsSL https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main/setup-codebuddy-assistant.sh)

# 自定义代理
bash <(curl -fsSLx http://your-proxy:port https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main/setup-codebuddy-assistant.sh)
```

### 2. 一键启动（SSH + tmux 后台模式）

SSH 连接服务器后，用 tmux 保持会话，断开 SSH 后 CodeBuddy 继续运行：

```bash
# 一行搞定：SSH 连接 + tmux 会话 + 脚本执行
ssh user@your-server -t "tmux new-session -A -s cbc 'bash <(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main/setup-codebuddy-assistant.sh)'"

# 或者 SSH 上去后手动操作
tmux new-session -s cbc
bash <(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main/setup-codebuddy-assistant.sh)
# 配置完成后，连接企微 → 按 Ctrl+B 然后按 D 脱离 tmux（CodeBuddy 继续后台运行）
# 下次重新连接：tmux attach -t cbc
```

### 3. 一键启动（非 root 用户）

非 root 用户使用 `systemctl --user` 管理服务：

```bash
# 国内环境
bash <(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main/setup-codebuddy-assistant.sh)

# 服务管理命令（注意 --user）
systemctl --user start codebuddy
systemctl --user stop codebuddy
systemctl --user status codebuddy
journalctl --user -u codebuddy -f

# 确保注销后服务继续运行
loginctl enable-linger $(whoami)
```

### 4. 克隆到本地执行

```bash
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
| Step 4 | 创建 systemd 后台常驻服务 |
| Step 5 | 安装 /init-setup Skill（后续交互式调整配置） |

## 配置文件说明

```
~/.codebuddy/
├── CODEBUDDY.md              # 身份设定（Bot名字、用户角色、回复偏好）
├── settings.json             # 全局设置（语言、记忆、权限等）
├── rules/                    # 模块化个人规则
│   ├── preferences.md
│   └── workflows.md
├── skills/
│   └── init-setup/
│       └── SKILL.md          # 交互式配置向导
├── memories/
│   ├── global/               # 全局记忆
│   └── {project-id}/         # 项目记忆
└── agents/                   # 自定义子代理
```

## 日常使用

### systemd 服务管理

```bash
sudo systemctl start codebuddy    # 启动
sudo systemctl stop codebuddy     # 停止
sudo systemctl restart codebuddy  # 重启
sudo systemctl status codebuddy   # 查看状态
sudo journalctl -u codebuddy -f   # 查看实时日志
```

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

编辑 `~/.codebuddy/CODEBUDDY.md`，修改后重启服务生效：

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
# 编辑环境变量
vim ~/.bashrc
# 修改 CODEBUDDY_WECOM_BOT_ID 和 CODEBUDDY_WECOM_BOT_SECRET

# 同步到 systemd 服务
sudo vim /etc/systemd/system/codebuddy.service
# 修改 Environment=CODEBUDDY_WECOM_BOT_ID=... 和 SECRET=...

# 重载并重启
sudo systemctl daemon-reload
sudo systemctl restart codebuddy
```

## 新设备快速复用

```bash
# 一行命令，不留本地
curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main/setup-codebuddy-assistant.sh | bash
```

## 常见问题

### 服务启动后如何连接企微？

服务启动后会自动执行 `/remote-control`，打开交互面板。如果是新安装，需要 SSH 到服务器，通过 `tmux attach` 或直接终端操作来选择 `wecom-bot` 连接。

### 服务器重启后需要重新连接吗？

是的，`/remote-control` 连接状态是临时的。重启后服务会自动启动，但需要再次在面板中选择 `wecom-bot` 连接。连接后会自动恢复企微通信。

### 如何查看 Bot 是否正常工作？

```bash
# 查看服务状态
sudo systemctl status codebuddy

# 查看日志
sudo journalctl -u codebuddy -f

# 在企微中发送测试消息
```

### 非 root 用户怎么用？

脚本会自动检测用户权限，非 root 用户使用 `systemctl --user` 创建用户级服务。需要确保 `loginctl enable-linger` 已开启，否则注销后服务会停止。

## License

MIT
