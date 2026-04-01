#!/usr/bin/env bash
# health.sh - 健康检查

do_health_check() {
    echo -e "${CYAN}━━━ CodeBuddy 助手健康检查 ━━━${NC}"
    local has_error=false

    # 1. 依赖检查
    echo ""
    echo "--- 依赖检查 ---"
    _health_check_cmd "node" || has_error=true
    _health_check_cmd "npm" || has_error=true
    _health_check_cmd "tmux" || has_error=true
    _health_check_cmd "codebuddy" || has_error=true

    # 2. 配置检查
    echo ""
    echo "--- 配置检查 ---"
    if [[ -f "$HOME/.codebuddy/CODEBUDDY.md" ]]; then
        info "CODEBUDDY.md: 存在"
    else
        warn "CODEBUDDY.md: 不存在（运行完整安装配置身份设定）"
    fi

    if [[ -f "$HOME/.codebuddy/settings.json" ]]; then
        info "settings.json: 存在"
    else
        warn "settings.json: 不存在"
    fi

    # 3. 企微凭据检查
    echo ""
    echo "--- 企微凭据 ---"
    if [[ -n "${CODEBUDDY_WECOM_BOT_ID:-}" ]]; then
        info "CODEBUDDY_WECOM_BOT_ID: 已设置"
    else
        warn "CODEBUDDY_WECOM_BOT_ID: 未设置"
        has_error=true
    fi

    if [[ -n "${CODEBUDDY_WECOM_BOT_SECRET:-}" ]]; then
        info "CODEBUDDY_WECOM_BOT_SECRET: 已设置"
    else
        warn "CODEBUDDY_WECOM_BOT_SECRET: 未设置"
        has_error=true
    fi

    # 4. tmux 会话检查
    echo ""
    echo "--- 运行状态 ---"
    if tmux has-session -t codebuddy 2>/dev/null; then
        info "CodeBuddy tmux 会话: 运行中"
    else
        warn "CodeBuddy tmux 会话: 未运行（执行 cbc 启动）"
    fi

    # 5. 别名检查
    if type cbc &>/dev/null; then
        info "cbc 别名: 已配置"
    else
        warn "cbc 别名: 未配置（运行 --upgrade 配置）"
    fi

    # 6. 网络检查
    echo ""
    echo "--- 网络连通性 ---"
    if curl -fsSL --connect-timeout 5 "https://openws.work.weixin.qq.com" >/dev/null 2>&1; then
        info "企微 WebSocket (openws.work.weixin.qq.com): 可达"
    else
        warn "企微 WebSocket: 不可达（可能被防火墙拦截）"
        has_error=true
    fi

    # 结果
    echo ""
    if [[ "$has_error" == "true" ]]; then
        warn "存在需要关注的问题，请查看上方警告"
    else
        info "一切正常"
    fi
}

_health_check_cmd() {
    local cmd="$1"
    if command -v "$cmd" &>/dev/null; then
        local ver
        ver=$("$cmd" --version 2>/dev/null | head -1 || echo "ok")
        info "${cmd}: ${ver}"
    else
        warn "${cmd}: 未安装"
        return 1
    fi
}
