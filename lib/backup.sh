#!/usr/bin/env bash
# backup.sh - 配置备份

BACKUP_DIR="$HOME/.codebuddy/backups"

do_backup() {
    local config_dir="$HOME/.codebuddy"
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_subdir="${BACKUP_DIR}/${timestamp}"

    # 检查是否有需要备份的内容
    if [[ ! -d "$config_dir" ]] || [[ -z "$(ls -A "$config_dir" 2>/dev/null)" ]]; then
        info "没有需要备份的配置"
        return 0
    fi

    mkdir -p "$backup_subdir"

    # 备份关键文件
    local has_backup=false

    if [[ -f "$config_dir/CODEBUDDY.md" ]]; then
        cp "$config_dir/CODEBUDDY.md" "$backup_subdir/"
        has_backup=true
    fi

    if [[ -f "$config_dir/settings.json" ]]; then
        cp "$config_dir/settings.json" "$backup_subdir/"
        has_backup=true
    fi

    if [[ -d "$config_dir/skills" ]]; then
        cp -r "$config_dir/skills" "$backup_subdir/"
        has_backup=true
    fi

    if [[ -d "$config_dir/rules" ]]; then
        cp -r "$config_dir/rules" "$backup_subdir/"
        has_backup=true
    fi

    if [[ "$has_backup" == "true" ]]; then
        info "配置已备份到: ${backup_subdir}"
    else
        info "没有需要备份的配置"
    fi

    # 清理旧备份（保留最近 5 份）
    _cleanup_old_backups
}

_cleanup_old_backups() {
    local count
    count=$(ls -1d "${BACKUP_DIR}"/*/ 2>/dev/null | wc -l)
    if [[ "$count" -gt 5 ]]; then
        local to_remove=$((count - 5))
        ls -1d "${BACKUP_DIR}"/*/ | head -"$to_remove" | while read -r dir; do
            rm -rf "$dir"
            info "已清理旧备份: ${dir}"
        done
    fi
}
