#!/usr/bin/env bash
# uninstall.sh - 一键卸载

do_uninstall() {
    info "开始卸载 CodeBuddy 助手..."

    # 停止 tmux 会话
    tmux kill-session -t codebuddy 2>/dev/null && info "已清理 tmux 会话" || true

    # 清理旧版 systemd
    _cleanup_old_systemd_uninstall

    # 清理别名
    remove_aliases

    # 清理 wrapper（兼容旧版）
    if [[ -f "/usr/local/bin/codebuddy-wecom-wrapper.sh" ]]; then
        rm -f "/usr/local/bin/codebuddy-wecom-wrapper.sh"
        info "已清理 wrapper 脚本"
    fi

    # 清理版本文件
    rm -f "$HOME/.codebuddy/.cbc-version"

    echo ""
    info "卸载完成。以下配置保留未删（如需清理请手动操作）："
    echo "  - ~/.codebuddy/          (身份设定、记忆、Skill 等)"
    echo "  - ~/.bashrc 中的环境变量   (CODEBUDDY_WECOM_BOT_ID/SECRET)"
    echo "  - CodeBuddy 本体          (npm uninstall -g @tencent-ai/codebuddy-code)"
}

_cleanup_old_systemd_uninstall() {
    local service_name="codebuddy"
    for sf in "/etc/systemd/system/${service_name}.service" "$HOME/.config/systemd/user/${service_name}.service"; do
        if [[ -f "$sf" ]]; then
            if [[ "$(id -u)" -eq 0 ]]; then
                systemctl stop "$service_name" 2>/dev/null
                systemctl disable "$service_name" 2>/dev/null
                rm -f "$sf"
                systemctl daemon-reload
            else
                systemctl --user stop "$service_name" 2>/dev/null
                systemctl --user disable "$service_name" 2>/dev/null
                rm -f "$sf"
                systemctl --user daemon-reload
            fi
            info "已删除 systemd 服务: ${sf}"
        fi
    done
}
