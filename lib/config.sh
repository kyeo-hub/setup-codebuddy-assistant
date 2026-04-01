#!/usr/bin/env bash
# config.sh - 环境变量、身份设定、记忆管理

config_all() {
    config_env
    config_identity
    config_memory
}

# ========== 环境变量 ==========
config_env() {
    echo -e "${CYAN}━━━ 企业微信机器人配置 ━━━${NC}"

    BOT_ID=${CODEBUDDY_WECOM_BOT_ID:-""}
    BOT_SECRET=${CODEBUDDY_WECOM_BOT_SECRET:-""}

    if [[ -z "$BOT_ID" ]]; then
        read -rp "请输入企业微信 Bot ID: " BOT_ID
    fi
    if [[ -z "$BOT_SECRET" ]]; then
        read -rp "请输入企业微信 Bot Secret: " BOT_SECRET
    fi

    if [[ -z "$BOT_ID" || -z "$BOT_SECRET" ]]; then
        warn "未配置企微 Bot，跳过（后续可手动设置环境变量）"
        return 0
    fi

    local shell_rc
    shell_rc=$(detect_shell_rc)
    if [[ -n "$shell_rc" ]]; then
        if [[ ! -f "$shell_rc" ]]; then
            info "未找到 ${shell_rc}，已创建"
            touch "$shell_rc"
        fi
        # 清理旧配置
        sed -i '/^export CODEBUDDY_WECOM_BOT_ID=/d' "$shell_rc"
        sed -i '/^export CODEBUDDY_WECOM_BOT_SECRET=/d' "$shell_rc"
        sed -i '/^# CodeBuddy WeChat Work Bot$/d' "$shell_rc"
        # 写入新配置
        {
            echo ""
            echo "# CodeBuddy WeChat Work Bot"
            echo "export CODEBUDDY_WECOM_BOT_ID=\"${BOT_ID}\""
            echo "export CODEBUDDY_WECOM_BOT_SECRET=\"${BOT_SECRET}\""
        } >> "$shell_rc"
        export CODEBUDDY_WECOM_BOT_ID="$BOT_ID"
        export CODEBUDDY_WECOM_BOT_SECRET="$BOT_SECRET"
        info "已写入 ${shell_rc}"
    fi
    info "企微 Bot 环境变量已配置"
}

# ========== 身份设定 ==========
config_identity() {
    echo ""
    echo -e "${CYAN}━━━ 身份设定 ━━━${NC}"

    local config_dir="$HOME/.codebuddy"
    local codebuddy_md="$config_dir/CODEBUDDY.md"
    local create_identity=false

    if [[ -f "$codebuddy_md" ]]; then
        echo "检测到已有 CODEBUDDY.md："
        echo "---"
        head -20 "$codebuddy_md"
        echo "..."
        if confirm "是否覆盖?" "N"; then
            create_identity=true
        else
            warn "跳过身份设定，保留现有配置"
        fi
    else
        create_identity=true
    fi

    if [[ "$create_identity" == "true" ]]; then
        local username user_role user_langs bot_name reply_lang reply_style

        read -rp "你的名字（Bot 对你的称呼）[默认: 老板]: " username
        username=${username:-老板}

        read -rp "你的职业/角色 [默认: 资深工程师]: " user_role
        user_role=${user_role:-资深工程师}

        read -rp "主要编程语言（逗号分隔）[默认: Go, Python, TypeScript]: " user_langs
        user_langs=${user_langs:-Go, Python, TypeScript}

        read -rp "Bot 的名字 [默认: 小码]: " bot_name
        bot_name=${bot_name:-小码}

        read -rp "回复语言 [默认: 简体中文]: " reply_lang
        reply_lang=${reply_lang:-简体中文}

        read -rp "回复风格 [默认: 简洁直接]: " reply_style
        reply_style=${reply_style:-简洁直接}

        mkdir -p "$config_dir"
        cat > "$codebuddy_md" << EOF
## 身份设定

- 你的名字是"${bot_name}"，是${username}的私人编程助手
- ${username}的角色：${user_role}
- ${username}主要使用的技术栈：${user_langs}

## 回复偏好

- 回复语言：${reply_lang}
- 回复风格：${reply_style}，不要废话
- 遇到不确定的问题，先确认再动手
- 代码注释使用${reply_lang}

## 工具偏好

- 优先使用简洁的方案，避免过度工程
- 保持代码可读性和可维护性
EOF
        info "身份设定已写入 ${codebuddy_md}"
    fi
}

# ========== 记忆管理 ==========
config_memory() {
    echo ""
    echo -e "${CYAN}━━━ 记忆管理 ━━━${NC}"

    local config_dir="$HOME/.codebuddy"
    local settings_json="$config_dir/settings.json"
    mkdir -p "$config_dir"

    if [[ -f "$settings_json" ]]; then
        info "检测到已有 settings.json，将在其基础上更新"
    fi

    node -e "
const fs = require('fs');
const path = '${settings_json}';
let settings = {};
try {
    settings = JSON.parse(fs.readFileSync(path, 'utf8'));
} catch(e) {}

if (!settings.language) settings.language = '简体中文';
if (!settings.memory) settings.memory = {};
settings.memory.enabled = true;
settings.memory.autoMemoryEnabled = true;
settings.memory.typedMemory = true;

fs.writeFileSync(path, JSON.stringify(settings, null, 2) + '\n');
"

    info "已启用: Auto Memory + Typed Memory"
}
