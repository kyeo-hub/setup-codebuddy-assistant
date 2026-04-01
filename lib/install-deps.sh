#!/usr/bin/env bash
# install-deps.sh - 安装 Node.js 和 tmux

install_deps() {
    echo -e "${CYAN}━━━ 安装系统依赖 ━━━${NC}"
    install_node
    install_tmux
}

install_node() {
    if command -v node &>/dev/null; then
        local node_ver
        node_ver=$(node --version 2>/dev/null)
        info "Node.js 已安装: ${node_ver}"
        if confirm "是否重新安装/升级 Node.js?" "N"; then
            _do_install_node
        fi
        return 0
    fi

    info "Node.js 未安装，开始安装..."
    _do_install_node
}

_do_install_node() {
    local pkg_manager=""

    if command -v apt-get &>/dev/null; then
        pkg_manager="apt"
    elif command -v yum &>/dev/null; then
        pkg_manager="yum"
    elif command -v dnf &>/dev/null; then
        pkg_manager="dnf"
    elif command -v apk &>/dev/null; then
        pkg_manager="apk"
    fi

    case "$pkg_manager" in
        apt)
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - 2>/dev/null \
                && sudo apt-get install -y nodejs \
                || error "Node.js 安装失败（apt）"
            ;;
        yum|dnf)
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash - 2>/dev/null \
                && sudo "$pkg_manager" install -y nodejs \
                || error "Node.js 安装失败（${pkg_manager}）"
            ;;
        apk)
            sudo apk add --no-cache nodejs npm \
                || error "Node.js 安装失败（apk）"
            ;;
        *)
            warn "未识别的包管理器，请手动安装 Node.js: https://nodejs.org/"
            return 1
            ;;
    esac

    info "Node.js 安装完成: $(node --version)"
}

install_tmux() {
    if command -v tmux &>/dev/null; then
        info "tmux 已安装: $(tmux -V)"
        return 0
    fi

    info "tmux 未安装，开始安装..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y tmux || error "tmux 安装失败（apt）"
    elif command -v yum &>/dev/null; then
        sudo yum install -y tmux || error "tmux 安装失败（yum）"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y tmux || error "tmux 安装失败（dnf）"
    elif command -v apk &>/dev/null; then
        sudo apk add --no-cache tmux || error "tmux 安装失败（apk）"
    else
        warn "未识别的包管理器，请手动安装 tmux"
        return 1
    fi

    info "tmux 安装完成: $(tmux -V)"
}
