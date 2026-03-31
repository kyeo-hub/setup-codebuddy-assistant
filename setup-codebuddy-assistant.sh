#!/usr/bin/env bash
#
# CodeBuddy 个人助理一键配置脚本
# 用法: bash setup-codebuddy-assistant.sh
#
# 功能:
#   1. 配置企微机器人环境变量
#   2. 创建身份设定 CODEBUDDY.md
#   3. 启用 Auto Memory 和 Typed Memory
#   4. 设置语言偏好为简体中文
#   5. 创建 systemd 后台服务
#   6. 安装 /init-setup Skill (用于后续通过 CodeBuddy 交互式调整配置)
#
set -euo pipefail

# ========== 颜色 ==========
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; die; }
die()     { echo -e "${RED}配置中断，请重新运行脚本。${NC}"; exit 1; }

# ========== 前置检查 ==========
info "正在检查环境..."

if ! command -v codebuddy &>/dev/null; then
    error "未找到 codebuddy，请先安装 CodeBuddy Code"
fi

CODEBUDDY_BIN=$(which codebuddy)
CODEBUDDY_BIN=$(readlink -f "$CODEBUDDY_BIN" 2>/dev/null || echo "$CODEBUDDY_BIN")
CODEBUDDY_VERSION=$(codebuddy --version 2>/dev/null | head -1 || echo "unknown")
info "CodeBuddy 路径: ${CODEBUDDY_BIN}"
info "CodeBuddy 版本: ${CODEBUDDY_VERSION}"

# 确认 HOME 目录存在
if [[ ! -d "$HOME" ]]; then
    mkdir -p "$HOME"
    info "已创建 HOME 目录: ${HOME}"
fi

CONFIG_DIR="$HOME/.codebuddy"
mkdir -p "$CONFIG_DIR/rules" "$CONFIG_DIR/skills/init-setup" "$CONFIG_DIR/memories/global"
info "配置目录: ${CONFIG_DIR}"

# ========== Step 1: 企微机器人环境变量 ==========
echo ""
echo -e "${CYAN}━━━ Step 1/5: 企业微信机器人配置 ━━━${NC}"

BOT_ID=${CODEBUDDY_WECOM_BOT_ID:-""}
BOT_SECRET=${CODEBUDDY_WECOM_BOT_SECRET:-""}

if [[ -z "$BOT_ID" ]]; then
    read -rp "请输入企业微信 Bot ID: " BOT_ID
fi
if [[ -z "$BOT_SECRET" ]]; then
    read -rp "请输入企业微信 Bot Secret: " BOT_SECRET
fi

if [[ -z "$BOT_ID" || -z "$BOT_SECRET" ]]; then
    warn "未配置企微 Bot，跳过此步骤（后续可手动配置环境变量）"
else
    # 检测 shell 配置文件
    SHELL_RC=""
    if [[ -f "$HOME/.zshrc" ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        SHELL_RC="$HOME/.bashrc"
    fi

    if [[ -n "$SHELL_RC" ]]; then
        # 移除旧的配置行，避免重复
        sed -i '/^export CODEBUDDY_WECOM_BOT_ID=/d' "$SHELL_RC"
        sed -i '/^export CODEBUDDY_WECOM_BOT_SECRET=/d' "$SHELL_RC"
        sed -i '/^# CodeBuddy WeChat Work Bot$/d' "$SHELL_RC"
        echo "" >> "$SHELL_RC"
        echo "# CodeBuddy WeChat Work Bot" >> "$SHELL_RC"
        echo "export CODEBUDDY_WECOM_BOT_ID=\"${BOT_ID}\"" >> "$SHELL_RC"
        echo "export CODEBUDDY_WECOM_BOT_SECRET=\"${BOT_SECRET}\"" >> "$SHELL_RC"
        export CODEBUDDY_WECOM_BOT_ID="$BOT_ID"
        export CODEBUDDY_WECOM_BOT_SECRET="$BOT_SECRET"
        info "已写入 ${SHELL_RC}"
    fi
    info "企微 Bot 环境变量已配置"
fi

# ========== Step 2: 身份设定 ==========
echo ""
echo -e "${CYAN}━━━ Step 2/5: 身份设定 ━━━${NC}"

CODEBUDDY_MD="$CONFIG_DIR/CODEBUDDY.md"

if [[ -f "$CODEBUDDY_MD" ]]; then
    echo "检测到已有 CODEBUDDY.md："
    echo "---"
    head -20 "$CODEBUDDY_MD"
    echo "..."
    read -rp "是否覆盖？[y/N]: " OVERWRITE
    if [[ "$OVERWRITE" != "y" && "$OVERWRITE" != "Y" ]]; then
        warn "跳过身份设定，保留现有配置"
    else
        create_identity=true
    fi
else
    create_identity=true
fi

if [[ "${create_identity:-false}" == "true" ]]; then
    read -rp "你的名字（Bot 对你的称呼）[默认: 老板]: " USERNAME
    USERNAME=${USERNAME:-老板}

    read -rp "你的职业/角色（如: 全栈工程师、产品经理）[默认: 资深工程师]: " USER_ROLE
    USER_ROLE=${USER_ROLE:-资深工程师}

    read -rp "你主要使用的编程语言（逗号分隔）[默认: Go, Python, TypeScript]: " USER_LANGS
    USER_LANGS=${USER_LANGS:-Go, Python, TypeScript}

    read -rp "Bot 的名字（你给它取的名字）[默认: 小码]: " BOT_NAME
    BOT_NAME=${BOT_NAME:-小码}

    read -rp "回复语言 [默认: 简体中文]: " REPLY_LANG
    REPLY_LANG=${REPLY_LANG:-简体中文}

    read -rp "回复风格（如: 简洁直接/详细解释/幽默风趣）[默认: 简洁直接]: " REPLY_STYLE
    REPLY_STYLE=${REPLY_STYLE:-简洁直接}

    cat > "$CODEBUDDY_MD" << EOF
## 身份设定

- 你的名字是"${BOT_NAME}"，是${USERNAME}的私人编程助手
- ${USERNAME}的角色：${USER_ROLE}
- ${USERNAME}主要使用的技术栈：${USER_LANGS}

## 回复偏好

- 回复语言：${REPLY_LANG}
- 回复风格：${REPLY_STYLE}，不要废话
- 遇到不确定的问题，先确认再动手
- 代码注释使用${REPLY_LANG}

## 工具偏好

- 优先使用简洁的方案，避免过度工程
- 保持代码可读性和可维护性
EOF
    info "身份设定已写入 ${CODEBUDDY_MD}"
fi

# ========== Step 3: 记忆管理 ==========
echo ""
echo -e "${CYAN}━━━ Step 3/5: 记忆管理 ━━━${NC}"

SETTINGS_JSON="$CONFIG_DIR/settings.json"

# 读取现有 settings.json 或创建新的
if [[ -f "$SETTINGS_JSON" ]]; then
    info "检测到已有 settings.json，将在其基础上更新"
fi

# 使用 node 来安全地合并 JSON
node -e "
const fs = require('fs');
const path = '${SETTINGS_JSON}';
let settings = {};
try {
    settings = JSON.parse(fs.readFileSync(path, 'utf8'));
} catch(e) {}

// 语言
if (!settings.language) settings.language = '${REPLY_LANG:-简体中文}';

// 记忆配置
if (!settings.memory) settings.memory = {};
settings.memory.enabled = true;
settings.memory.autoMemoryEnabled = true;
settings.memory.typedMemory = true;

fs.writeFileSync(path, JSON.stringify(settings, null, 2) + '\n');
console.log(JSON.stringify(settings, null, 2));
"

info "已启用: Auto Memory + Typed Memory"
info "语言偏好: ${REPLY_LANG:-简体中文}"

# ========== Step 4: 后台服务 (systemd) ==========
echo ""
echo -e "${CYAN}━━━ Step 4/5: 后台常驻服务 ━━━${NC}"

if [[ "$(id -u)" -eq 0 ]]; then
    IS_ROOT=true
else
    IS_ROOT=false
    warn "当前非 root 用户，systemd 服务将以当前用户创建（systemctl --user）"
fi

SERVICE_NAME="codebuddy"
if [[ "$IS_ROOT" == "true" ]]; then
    SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
else
    SERVICE_FILE="$HOME/.config/systemd/user/${SERVICE_NAME}.service"
    mkdir -p "$(dirname "$SERVICE_FILE")"
fi

read -rp "工作目录（CodeBuddy 运行目录）[默认: ${HOME}]: " WORK_DIR
WORK_DIR=${WORK_DIR:-$HOME}

# 确保 WorkingDirectory 存在
if [[ ! -d "$WORK_DIR" ]]; then
    info "工作目录不存在，自动创建: ${WORK_DIR}"
    mkdir -p "$WORK_DIR" || { error "无法创建工作目录: ${WORK_DIR}"; }
fi

read -rp "是否创建 systemd 后台服务？[Y/n]: " CREATE_SERVICE
CREATE_SERVICE=${CREATE_SERVICE:-Y}

if [[ "$CREATE_SERVICE" == "y" || "$CREATE_SERVICE" == "Y" ]]; then
    # 解析 node 真实路径（兼容 nvm、fnm 等版本管理器）
    NODE_BIN=""
    NODE_REAL=$(readlink -f "$(which node)" 2>/dev/null || echo "")
    if [[ -n "$NODE_REAL" ]]; then
        NODE_BIN=$(dirname "$NODE_REAL")
    fi
    NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

    if [[ "$IS_ROOT" == "true" ]]; then
        cat > "$SERVICE_FILE" << EOF
[Unit]
Description=CodeBuddy Code - Personal AI Assistant
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Environment=HOME=/root
Environment=PATH=${CODEBUDDY_BIN%/*}:${NODE_BIN}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=CODEBUDDY_WECOM_BOT_ID=${BOT_ID}
Environment=CODEBUDDY_WECOM_BOT_SECRET=${BOT_SECRET}
WorkingDirectory=${WORK_DIR}
ExecStart=${CODEBUDDY_BIN} -c "/remote-control"
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl enable "${SERVICE_NAME}"
        # 先测试服务配置是否合法
        if systemctl start "${SERVICE_NAME}" 2>/dev/null; then
            info "服务启动成功"
        else
            JOURNAL=$(journalctl -u "${SERVICE_NAME}" --no-pager -n 10 2>/dev/null)
            warn "服务启动失败，尝试排查..."
            echo "$JOURNAL" | tail -5
            # 常见修复：如果路径含 nvm，尝试用 node 绝对路径
            if [[ "$CODEBUDDY_BIN" == *"/.nvm/"* ]]; then
                warn "检测到 nvm 环境，systemd 可能无法加载 nvm 路径"
                warn "建议将 ExecStart 中的 codebuddy 替换为绝对路径: ${CODEBUDDY_BIN}"
                warn "服务文件: ${SERVICE_FILE}"
            fi
        fi
        info "systemd 服务已创建并启用"
        info "  启动: systemctl start ${SERVICE_NAME}"
        info "  停止: systemctl stop ${SERVICE_NAME}"
        info "  日志: journalctl -u ${SERVICE_NAME} -f"
    else
        cat > "$SERVICE_FILE" << EOF
[Unit]
Description=CodeBuddy Code - Personal AI Assistant
After=network-online.target

[Service]
Type=simple
Environment=CODEBUDDY_WECOM_BOT_ID=${BOT_ID}
Environment=CODEBUDDY_WECOM_BOT_SECRET=${BOT_SECRET}
Environment=PATH=${CODEBUDDY_BIN%/*}:${NODE_BIN}:/usr/local/bin:/usr/bin:/bin
WorkingDirectory=${WORK_DIR}
ExecStart=${CODEBUDDY_BIN} -c "/remote-control"
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

        systemctl --user daemon-reload
        systemctl --user enable "${SERVICE_NAME}"
        if systemctl --user start "${SERVICE_NAME}" 2>/dev/null; then
            info "服务启动成功"
        else
            JOURNAL=$(journalctl --user -u "${SERVICE_NAME}" --no-pager -n 10 2>/dev/null)
            warn "服务启动失败"
            echo "$JOURNAL" | tail -5
        fi
        info "用户级 systemd 服务已创建并启用"
        info "  启动: systemctl --user start ${SERVICE_NAME}"
        info "  停止: systemctl --user stop ${SERVICE_NAME}"
        info "  日志: journalctl --user -u ${SERVICE_NAME} -f"
        # 确保 loginctl enable-linger 让用户服务在退出后继续运行
        if command -v loginctl &>/dev/null; then
            loginctl enable-linger "$(whoami)" 2>/dev/null || warn "无法设置 linger，服务可能在注销后停止"
        fi
    fi
else
    warn "跳过后台服务创建"
fi

# ========== Step 5: 安装 init-setup Skill ==========
echo ""
echo -e "${CYAN}━━━ Step 5/5: 安装交互式配置 Skill ━━━${NC}"

SKILL_DIR="$CONFIG_DIR/skills/init-setup"
mkdir -p "$SKILL_DIR"

cat > "$SKILL_DIR/SKILL.md" << 'SKILLEOF'
---
name: init-setup
description: 交互式配置 CodeBuddy 个人助理的身份设定、偏好和记忆管理。在新设备或需要调整配置时使用。
allowed-tools: Read, Write, Bash, Edit, Glob, Grep
---

# CodeBuddy 个人助理配置向导

你是一个配置向导，帮助用户设置或调整 CodeBuddy 个人助理的各项配置。

## 当用户触发此 Skill 时

请依次询问以下配置项（已有配置项显示当前值供确认）：

### 1. 身份设定
读取 `~/.codebuddy/CODEBUDDY.md`，展示当前身份配置，询问是否需要修改：
- 你的名字（Bot 对你的称呼）
- 你的职业/角色
- 主要编程语言
- Bot 的名字
- 回复语言
- 回复风格

### 2. 记忆管理
读取 `~/.codebuddy/settings.json` 中的 `memory` 配置，询问是否需要调整：
- Auto Memory 开关
- Typed Memory 开关

### 3. 项目配置
询问是否需要在当前项目目录生成 `CODEBUDDY.md`（执行 `/init`）

### 4. 规则管理
列出 `~/.codebuddy/rules/` 下的规则文件，询问是否需要添加/修改/删除规则

## 配置完成后

更新对应文件并提示用户：
- CODEBUDDY.md: `~/.codebuddy/CODEBUDDY.md`
- settings.json: `~/.codebuddy/settings.json`
- rules: `~/.codebuddy/rules/*.md`
SKILLEOF

info "已安装 /init-setup Skill"
info "后续可通过在 CodeBuddy 中执行 /init-setup 交互式调整配置"

# ========== 完成 ==========
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     CodeBuddy 个人助理配置完成!          ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  配置文件:                               ║${NC}"
echo -e "${GREEN}║    身份设定: ~/.codebuddy/CODEBUDDY.md   ║${NC}"
echo -e "${GREEN}║    用户设置: ~/.codebuddy/settings.json  ║${NC}"
echo -e "${GREEN}║    规则目录: ~/.codebuddy/rules/         ║${NC}"
echo -e "${GREEN}║    记忆目录: ~/.codebuddy/memories/      ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  快捷命令:                               ║${NC}"
echo -e "${GREEN}║    /init-setup   交互式调整配置           ║${NC}"
echo -e "${GREEN}║    /memory       管理记忆文件             ║${NC}"
echo -e "${GREEN}║    /config       查看修改设置             ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"

# 提示 source shell
if [[ -n "$SHELL_RC" && -f "$SHELL_RC" ]]; then
    echo ""
    info "请执行以下命令使环境变量生效："
    echo -e "  ${CYAN}source ${SHELL_RC}${NC}"
fi

echo ""
info "配置完成！如需重新配置，重新运行此脚本或使用 /init-setup"
