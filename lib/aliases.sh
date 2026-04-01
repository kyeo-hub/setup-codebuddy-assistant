#!/usr/bin/env bash
# aliases.sh - tmux 快捷别名

setup_aliases() {
    echo -e "${CYAN}━━━ tmux 快捷别名 ━━━${NC}"

    local shell_rc
    shell_rc=$(detect_shell_rc)

    if [[ -z "$shell_rc" ]]; then
        warn "未找到 .bashrc 或 .zshrc，跳过别名配置"
        return 0
    fi

    if [[ ! -f "$shell_rc" ]]; then
        info "未找到 ${shell_rc}，已创建"
        touch "$shell_rc"
    fi

    # 清理旧别名
    sed -i '/^# CodeBuddy tmux aliases$/d' "$shell_rc"
    sed -i '/^cbc() {$/,/^}$/d' "$shell_rc"
    sed -i '/^cbc-stop() {$/,/^}$/d' "$shell_rc"

    # 写入新别名
    cat >> "$shell_rc" << 'ALIAS_EOF'

# CodeBuddy tmux aliases
cbc() {
    if ! command -v codebuddy &>/dev/null; then
        echo "[ERROR] 未检测到 codebuddy 可执行文件，请先安装或确保 PATH 中有 codebuddy"
        return 1
    fi

    if tmux has-session -t codebuddy 2>/dev/null; then
        # 如果已存在会话，检测是否已有 codebuddy 进程
        if tmux list-panes -t codebuddy -F '#{pane_current_command}' | grep -qi '^codebuddy$'; then
            tmux attach -t codebuddy
        else
            tmux kill-session -t codebuddy
            tmux new-session -s codebuddy codebuddy \; bind-key -n F12 detach
        fi
    else
        tmux new-session -s codebuddy codebuddy \; bind-key -n F12 detach
    fi
}
cbc-stop() {
    tmux kill-session -t codebuddy 2>/dev/null && echo "CodeBuddy 会话已关闭" || echo "没有运行中的 CodeBuddy 会话"
}
ALIAS_EOF
    info "已写入别名到 ${shell_rc}"
    echo ""
    info "快捷命令："
    info "  cbc       启动或连接 CodeBuddy"
    info "  cbc-stop  关闭 CodeBuddy 会话"
    info "  F12       在 CodeBuddy 中脱离 tmux（不需要 Ctrl+B）"
}

remove_aliases() {
    local shell_rc
    for shell_rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
        if [[ -f "$shell_rc" ]]; then
            sed -i '/^# CodeBuddy tmux aliases$/d' "$shell_rc"
            sed -i '/^cbc() {$/,/^}$/d' "$shell_rc"
            sed -i '/^cbc-stop() {$/,/^}$/d' "$shell_rc"
            info "已清理 ${shell_rc} 中的别名"
        fi
    done
}
