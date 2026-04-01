#!/usr/bin/env bash
# common.sh - 公共函数：日志、颜色、工具、版本管理、lib 加载

set -euo pipefail

# ========== 颜色 ==========
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }
die()     { echo -e "${RED}操作中断，请重新运行。${NC}"; exit 1; }

# ========== 版本管理 ==========
VERSION_FILE="$HOME/.codebuddy/.cbc-version"
GITHUB_RAW="https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main"
GITHUB_PROXY="https://ghfast.top/https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main"

get_installed_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE"
    else
        echo "unknown"
    fi
}

set_installed_version() {
    local version="$1"
    mkdir -p "$(dirname "$VERSION_FILE")"
    echo "$version" > "$VERSION_FILE"
}

detect_shell_rc() {
    if [[ -f "$HOME/.zshrc" ]]; then
        echo "$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        echo "$HOME/.bashrc"
    else
        echo ""
    fi
}

# ========== lib 加载 ==========
_CBC_LIB_DIR=""

load_lib() {
    # 优先使用本地 lib/ 目录
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    if [[ -d "$script_dir/lib" ]]; then
        _CBC_LIB_DIR="$script_dir/lib"
    fi
}

# ========== 交互确认 ==========
confirm() {
    local prompt="$1"
    local default="${2:-Y}"
    local answer
    read -rp "${prompt} [${default}]: " answer
    answer="${answer:-$default}"
    [[ "$answer" =~ ^[yY]$ ]]
}
