#!/usr/bin/env bash
#
# CodeBuddy 个人助理一键配置脚本
# 用法:
#   bash setup-codebuddy-assistant.sh          # 完整安装配置
#   bash setup-codebuddy-assistant.sh --update  # 一键更新 wrapper 脚本并重启服务
#   bash setup-codebuddy-assistant.sh --uninstall # 一键卸载（清理服务和 wrapper）
#
set -euo pipefail

# ========== 参数解析 ==========
MODE="install"
if [[ "${1:-}" == "--update" ]]; then
    MODE="update"
elif [[ "${1:-}" == "--uninstall" ]]; then
    MODE="uninstall"
elif [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "用法:"
    echo "  bash $0            完整安装配置"
    echo "  bash $0 --update   一键更新 wrapper 脚本并重启服务"
    echo "  bash $0 --uninstall 一键卸载（清理服务和 wrapper）"
    exit 0
fi

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

# ========== 卸载模式 ==========
if [[ "$MODE" == "uninstall" ]]; then
    info "开始卸载 CodeBuddy 服务..."

    info "开始卸载 CodeBuddy 配置..."

    # 停止并删除 systemd 服务（兼容旧版本安装）
    SERVICE_NAME="codebuddy"
    for SF in "/etc/systemd/system/${SERVICE_NAME}.service" "$HOME/.config/systemd/user/${SERVICE_NAME}.service"; do
        if [[ -f "$SF" ]]; then
            if [[ "$(id -u)" -eq 0 ]]; then
                systemctl stop "${SERVICE_NAME}" 2>/dev/null
                systemctl disable "${SERVICE_NAME}" 2>/dev/null
            else
                systemctl --user stop "${SERVICE_NAME}" 2>/dev/null
                systemctl --user disable "${SERVICE_NAME}" 2>/dev/null
            fi
            rm -f "$SF"
            if [[ "$(id -u)" -eq 0 ]]; then
                systemctl daemon-reload
            else
                systemctl --user daemon-reload
            fi
            info "已删除 systemd 服务: ${SF}"
        fi
    done

    # 清理 wrapper 脚本（兼容旧版本）
    if [[ -f "/usr/local/bin/codebuddy-wecom-wrapper.sh" ]]; then
        rm -f "/usr/local/bin/codebuddy-wecom-wrapper.sh"
        info "已删除 wrapper 脚本"
    fi

    # 清理 tmux 会话
    tmux kill-session -t codebuddy 2>/dev/null && info "已清理 tmux 会话" || true

    # 清理 shell 配置文件中的别名
    for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
        if [[ -f "$RC" ]]; then
            sed -i '/^# CodeBuddy tmux aliases$/d' "$RC"
            sed -i '/^cbc() {$/,/^}$/d' "$RC"
            sed -i '/^cbc-stop() {$/,/^}$/d' "$RC"
            info "已清理 ${RC} 中的别名"
        fi
    done

    echo ""
    info "卸载完成。以下配置保留未删（如需清理请手动操作）："
    echo "  - ~/.codebuddy/          (身份设定、记忆、Skill 等)"
    echo "  - ~/.bashrc 中的环境变量   (CODEBUDDY_WECOM_BOT_ID/SECRET)"
    echo "  - CodeBuddy 本体          (npm uninstall -g @tencent-ai/codebuddy-code)"
    exit 0
fi

# ========== 更新模式 ==========
if [[ "$MODE" == "update" ]]; then
    info "更新 tmux 别名..."

    SHELL_RC=""
    if [[ -f "$HOME/.zshrc" ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        SHELL_RC="$HOME/.bashrc"
    fi

    if [[ -n "$SHELL_RC" ]]; then
        sed -i '/^# CodeBuddy tmux aliases$/d' "$SHELL_RC"
        sed -i '/^cbc() {$/,/^}$/d' "$SHELL_RC"
        sed -i '/^cbc-stop() {$/,/^}$/d' "$SHELL_RC"
        cat >> "$SHELL_RC" << 'ALIAS_EOF'

# CodeBuddy tmux aliases
cbc() {
    if tmux has-session -t codebuddy 2>/dev/null; then
        tmux attach -t codebuddy
    else
        tmux new-session -s codebuddy codebuddy
    fi
}
cbc-stop() {
    tmux kill-session -t codebuddy 2>/dev/null && echo "CodeBuddy 会话已关闭" || echo "没有运行中的 CodeBuddy 会话"
}
ALIAS_EOF
        info "已更新 ${SHELL_RC} 中的别名"
    else
        warn "未找到 .bashrc 或 .zshrc"
    fi

    # 兼容旧版本：清理 systemd 服务和 wrapper
    SERVICE_NAME="codebuddy"
    for SF in "/etc/systemd/system/${SERVICE_NAME}.service" "$HOME/.config/systemd/user/${SERVICE_NAME}.service"; do
        if [[ -f "$SF" ]]; then
            if [[ "$(id -u)" -eq 0 ]]; then
                systemctl stop "${SERVICE_NAME}" 2>/dev/null
                systemctl disable "${SERVICE_NAME}" 2>/dev/null
            else
                systemctl --user stop "${SERVICE_NAME}" 2>/dev/null
                systemctl --user disable "${SERVICE_NAME}" 2>/dev/null
            fi
            rm -f "$SF"
            if [[ "$(id -u)" -eq 0 ]]; then
                systemctl daemon-reload
            else
                systemctl --user daemon-reload
            fi
            info "已清理旧版 systemd 服务: ${SF}"
        fi
    done
    if [[ -f "/usr/local/bin/codebuddy-wecom-wrapper.sh" ]]; then
        rm -f "/usr/local/bin/codebuddy-wecom-wrapper.sh"
        info "已清理旧版 wrapper 脚本"
    fi

    info "更新完成！执行 source ${SHELL_RC:-~/.bashrc} 使别名生效"
    exit 0
fi

# ========== 完整安装模式 ==========
# ========== 前置检查 ==========
info "正在检查环境..."

if ! command -v codebuddy &>/dev/null; then
    error "未找到 codebuddy，请先安装 CodeBuddy Code"
fi

if ! command -v tmux &>/dev/null; then
    error "未找到 tmux，请先安装: apt install -y tmux 或 yum install -y tmux"
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

# ========== Step 4: tmux 快捷启动别名 ==========
echo ""
echo -e "${CYAN}━━━ Step 4/5: tmux 快捷启动别名 ━━━${NC}"

# 检测 shell 配置文件
SHELL_RC=""
if [[ -f "$HOME/.zshrc" ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [[ -n "$SHELL_RC" ]]; then
    # 移除旧的别名，避免重复
    sed -i '/^# CodeBuddy tmux aliases$/d' "$SHELL_RC"
    sed -i '/^cbc() {$/,/^}$/d' "$SHELL_RC"
    sed -i '/^cbc-stop() {$/,/^}$/d' "$SHELL_RC"

    cat >> "$SHELL_RC" << 'ALIAS_EOF'

# CodeBuddy tmux aliases
cbc() {
    if tmux has-session -t codebuddy 2>/dev/null; then
        tmux attach -t codebuddy
    else
        tmux new-session -s codebuddy codebuddy
    fi
}
cbc-stop() {
    tmux kill-session -t codebuddy 2>/dev/null && echo "CodeBuddy 会话已关闭" || echo "没有运行中的 CodeBuddy 会话"
}
ALIAS_EOF
    info "已写入别名到 ${SHELL_RC}"
else
    warn "未找到 .bashrc 或 .zshrc，跳过别名配置"
    warn "可手动添加别名到你的 shell 配置文件"
fi

info "tmux 快捷别名已配置："
info "  cbc       启动或连接 CodeBuddy（tmux 后台运行）"
info "  cbc-stop  关闭 CodeBuddy 会话"
info "  分离会话: 按 Ctrl+B 然后按 D（不是 Ctrl+D）"

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
