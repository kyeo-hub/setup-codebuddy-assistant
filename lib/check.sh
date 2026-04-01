#!/usr/bin/env bash
# check.sh - 系统检查：OS、架构、网络、已有依赖版本

check_system() {
    info "正在检查系统环境..."

    # OS 检测
    local os_name="unknown"
    if [[ -f /etc/os-release ]]; then
        os_name=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d'"' -f2)
    fi
    info "操作系统: ${os_name}"

    # 架构检测
    local arch
    arch=$(uname -m)
    info "系统架构: ${arch}"

    # 网络连通性检查
    if curl -fsSL --connect-timeout 5 https://registry.npmjs.org/ >/dev/null 2>&1; then
        info "npm registry: 可达"
    else
        warn "npm registry: 不可达（可能需要代理）"
    fi

    # 已有依赖检查
    _check_existing_deps
}

_check_existing_deps() {
    echo ""

    if command -v node &>/dev/null; then
        local node_ver
        node_ver=$(node --version 2>/dev/null || echo "unknown")
        info "Node.js:  已安装 (${node_ver})"
    else
        warn "Node.js: 未安装"
    fi

    if command -v npm &>/dev/null; then
        local npm_ver
        npm_ver=$(npm --version 2>/dev/null || echo "unknown")
        info "npm:      已安装 (v${npm_ver})"
    else
        warn "npm:      未安装"
    fi

    if command -v tmux &>/dev/null; then
        local tmux_ver
        tmux_ver=$(tmux -V 2>/dev/null || echo "unknown")
        info "tmux:     已安装 (${tmux_ver})"
    else
        warn "tmux:     未安装"
    fi

    if command -v codebuddy &>/dev/null; then
        local cb_ver
        cb_ver=$(codebuddy --version 2>/dev/null | head -1 || echo "unknown")
        info "codebuddy: 已安装 (${cb_ver})"
    else
        warn "codebuddy: 未安装"
    fi

    # 检查 SSH 环境（非交互判断）
    if [[ -n "${SSH_CONNECTION:-}" ]]; then
        info "SSH 会话: 是"
    else
        info "SSH 会话: 否"
    fi

    # 检查 tmux 环境
    if [[ -n "${TMUX:-}" ]]; then
        info "tmux 会话: 是"
    else
        info "tmux 会话: 否"
    fi
}

# 检查所有必要依赖是否就绪
check_ready() {
    if ! command -v node &>/dev/null; then
        die "缺少 Node.js，请先运行安装"
    fi
    if ! command -v tmux &>/dev/null; then
        die "缺少 tmux，请先运行安装"
    fi
    if ! command -v codebuddy &>/dev/null; then
        die "缺少 codebuddy，请先运行安装"
    fi
    return 0
}
