#!/usr/bin/env bash
# install-codebuddy.sh - 安装/更新 CodeBuddy CLI

install_codebuddy() {
    if command -v codebuddy &>/dev/null; then
        local cb_ver
        cb_ver=$(codebuddy --version 2>/dev/null | head -1 || echo "unknown")
        info "CodeBuddy 已安装: ${cb_ver}"
        if confirm "是否重新安装/升级 CodeBuddy?" "N"; then
            _do_install_codebuddy
        fi
        return 0
    fi

    info "CodeBuddy 未安装，开始安装..."
    _do_install_codebuddy
}

_do_install_codebuddy() {
    npm install -g @tencent-ai/codebuddy-code || error "CodeBuddy 安装失败"
    local cb_ver
    cb_ver=$(codebuddy --version 2>/dev/null | head -1 || echo "unknown")
    info "CodeBuddy 安装完成: ${cb_ver}"
}

get_codebuddy_path() {
    local cb_bin
    cb_bin=$(which codebuddy 2>/dev/null) || return 1
    readlink -f "$cb_bin" 2>/dev/null || echo "$cb_bin"
}
