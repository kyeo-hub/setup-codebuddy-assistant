#!/usr/bin/env bash
# upgrade.sh - 一键升级

do_upgrade() {
    info "开始升级 CodeBuddy 助手..."

    # 备份
    do_backup

    # 升级 CodeBuddy CLI
    if command -v codebuddy &>/dev/null; then
        info "升级 CodeBuddy CLI..."
        npm install -g @tencent-ai/codebuddy-code || warn "CodeBuddy CLI 升级失败"
    fi

    # 更新别名
    setup_aliases

    # 更新 Skill
    setup_skill

    # 清理旧版 systemd 残留
    _cleanup_old_systemd

    # 记录版本
    set_installed_version "$(date +%Y%m%d-%H%M%S)"

    echo ""
    info "升级完成！执行 source $(detect_shell_rc || echo ~/.bashrc) 使别名生效"
}

_cleanup_old_systemd() {
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
            info "已清理旧版 systemd 服务: ${sf}"
        fi
    done
    if [[ -f "/usr/local/bin/codebuddy-wecom-wrapper.sh" ]]; then
        rm -f "/usr/local/bin/codebuddy-wecom-wrapper.sh"
        info "已清理旧版 wrapper 脚本"
    fi
}
