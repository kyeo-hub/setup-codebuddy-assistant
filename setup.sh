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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# 加载公共模块
if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
else
    echo "[ERROR] 找不到 lib/common.sh，请确认在项目目录下运行"
    exit 1
fi

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

# ========== 参数解析 ==========
MODE="${1:-}"

case "$MODE" in
    --help|-h|"")
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

        check_system
        echo ""

        # 交互式安装依赖
        if confirm "是否检查并安装缺失的依赖？" "Y"; then
            install_deps
        fi

        # 安装 CodeBuddy
        install_codebuddy
        echo ""

        # 配置
        config_all
        echo ""

        # 别名
        setup_aliases
        echo ""

        # Skill
        setup_skill
        echo ""

        # 备份标记
        set_installed_version "$(date +%Y%m%d-%H%M%S)"

        # 完成提示
        local shell_rc
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
        ;;
esac
