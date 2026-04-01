#!/usr/bin/env bash
#
# CodeBuddy 个人助理一键配置
# 用法:
#   bash setup.sh                  # 完整安装配置
#   bash setup.sh --install-deps   # 仅安装系统依赖（Node.js、tmux）
#   bash setup.sh --install-cb     # 仅安装 CodeBuddy CLI
#   bash setup.sh --upgrade        # 一键升级（别名、Skill、清理旧版残留）
#   bash setup.sh --uninstall      # 一键卸载
#   bash setup.sh --health         # 健康检查
#   bash setup.sh --check          # 仅检查系统环境
#
set -euo pipefail

# ========== lib 加载 ==========
GITHUB_RAW="https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main"
GITHUB_PROXY="https://ghfast.top/https://raw.githubusercontent.com/kyeo-hub/setup-codebuddy-assistant/main"
LIB_MODULES="common check install-deps install-codebuddy config aliases skill upgrade uninstall health backup"

_resolve_lib_dir() {
    # 尝试本地 lib/ 目录
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
    if [[ -n "$script_dir" && -f "$script_dir/lib/common.sh" ]]; then
        echo "$script_dir/lib"
        return 0
    fi

    # 远程模式：下载到临时目录
    local tmp_dir
    tmp_dir=$(mktemp -d)
    local base_url

    if curl -fsSL --connect-timeout 5 "${GITHUB_PROXY}/lib/common.sh" -o "${tmp_dir}/common.sh" 2>/dev/null; then
        base_url="$GITHUB_PROXY"
    elif curl -fsSL --connect-timeout 10 "${GITHUB_RAW}/lib/common.sh" -o "${tmp_dir}/common.sh" 2>/dev/null; then
        base_url="$GITHUB_RAW"
    else
        echo "" >&2
        echo "[ERROR] 无法下载模块文件，请检查网络或手动克隆仓库：" >&2
        echo "  git clone git@github.com:kyeo-hub/setup-codebuddy-assistant.git" >&2
        echo "  cd setup-codebuddy-assistant && bash setup.sh" >&2
        rm -rf "$tmp_dir"
        exit 1
    fi

    local module
    for module in $LIB_MODULES; do
        curl -fsSL "${base_url}/lib/${module}.sh" -o "${tmp_dir}/${module}.sh" 2>/dev/null || true
    done
    echo "$tmp_dir"
}

LIB_DIR=$(_resolve_lib_dir)

# 加载所有模块
for module in $LIB_MODULES; do
    source "${LIB_DIR}/${module}.sh"
done

# ========== 参数解析 ==========
MODE="${1:-}"

case "$MODE" in
    --help|-h)
        cat << 'HELP'
用法: bash setup.sh [选项]

选项:
  (无参数)       完整安装配置（交互式）
  --install-deps 仅安装系统依赖（Node.js、tmux）
  --install-cb   仅安装 CodeBuddy CLI
  --upgrade      一键升级
  --uninstall    一键卸载
  --health       健康检查
  --check        仅检查系统环境
HELP
        exit 0
        ;;
esac

# 加载其余模块
source "$LIB_DIR/check.sh"
source "$LIB_DIR/install-deps.sh"
source "$LIB_DIR/install-codebuddy.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/aliases.sh"
source "$LIB_DIR/skill.sh"
source "$LIB_DIR/upgrade.sh"
source "$LIB_DIR/uninstall.sh"
source "$LIB_DIR/health.sh"
source "$LIB_DIR/backup.sh"

# ========== 路由 ==========
case "$MODE" in
    --check)
        check_system
        ;;
    --install-deps)
        install_deps
        ;;
    --install-cb)
        install_codebuddy
        ;;
    --upgrade)
        do_upgrade
        ;;
    --uninstall)
        if confirm "确定要卸载 CodeBuddy 助手吗？" "N"; then
            do_uninstall
        else
            info "已取消"
        fi
        ;;
    --health)
        do_health_check
        ;;
    *)
        echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║   CodeBuddy 个人助理配置                   ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"

        # 交互菜单
        while true; do
            echo ""
            echo "请选择要执行的操作（可多选，用空格分隔）:"
            echo "  1) 检查系统环境"
            echo "  2) 安装系统依赖（Node.js、tmux）"
            echo "  3) 安装 CodeBuddy CLI"
            echo "  4) 配置环境变量和身份设定"
            echo "  5) 设置 tmux 快捷别名"
            echo "  6) 安装 /init-setup Skill"
            echo "  7) 全部执行"
            echo "  0) 退出"
            echo ""
            read -rp "请输入选项 [7]: " choices
            choices="${choices:-7}"

            if [[ "$choices" == "0" ]]; then
                info "已退出"
                exit 0
            fi

            # 解析选择
            declare -A selected
            for choice in $choices; do
                selected[$choice]=1
            done

            # 执行选择
            if [[ ${selected[1]} || ${selected[7]} ]]; then
                check_system
                echo ""
            fi

            if [[ ${selected[2]} || ${selected[7]} ]]; then
                install_deps
                echo ""
            fi

            if [[ ${selected[3]} || ${selected[7]} ]]; then
                install_codebuddy
                echo ""
            fi

            if [[ ${selected[4]} || ${selected[7]} ]]; then
                config_all
                echo ""
            fi

            if [[ ${selected[5]} || ${selected[7]} ]]; then
                setup_aliases
                echo ""
            fi

            if [[ ${selected[6]} || ${selected[7]} ]]; then
                setup_skill
                echo ""
            fi

            # 备份标记（如果执行了安装或配置）
            if [[ ${selected[3]} || ${selected[4]} || ${selected[5]} || ${selected[6]} || ${selected[7]} ]]; then
                set_installed_version "$(date +%Y%m%d-%H%M%S)"
            fi

            # 完成提示
            if [[ ${selected[7]} ]]; then
                shell_rc=$(detect_shell_rc)
                echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
                echo -e "${GREEN}║     配置完成!                            ║${NC}"
                echo -e "${GREEN}╠══════════════════════════════════════════╣${NC}"
                echo -e "${GREEN}║  cbc         启动/连接 CodeBuddy          ║${NC}"
                echo -e "${GREEN}║  cbc-stop    关闭 CodeBuddy              ║${NC}"
                echo -e "${GREEN}║  F12         脱离 tmux                   ║${NC}"
                echo -e "${GREEN}║  /remote-control  连接企微              ║${NC}"
                echo -e "${GREEN}║  /init-setup 交互式调整配置              ║${NC}"
                echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"

                if [[ -n "$shell_rc" ]]; then
                    echo ""
                    info "请执行: source ${shell_rc}"
                fi
                break
            else
                if confirm "是否继续选择其他操作？" "N"; then
                    continue
                else
                    break
                fi
            fi
        done
        ;;
esac
