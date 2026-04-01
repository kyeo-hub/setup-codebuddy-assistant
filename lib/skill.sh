#!/usr/bin/env bash
# skill.sh - 安装 /init-setup Skill

setup_skill() {
    echo -e "${CYAN}━━━ 安装 /init-setup Skill ━━━${NC}"

    local skill_dir="$HOME/.codebuddy/skills/init-setup"
    mkdir -p "$skill_dir"

    cat > "$skill_dir/SKILL.md" << 'SKILLEOF'
---
name: init-setup
description: 交互式配置 CodeBuddy 个人助理的身份设定、偏好和记忆管理。在新设备或需要调整配置时使用。
allowed-tools: Read, Write, Bash, Edit, Glob, Grep
---

# CodeBuddy 个人助理配置向导

你是一个配置向导，帮助用户设置或调整 CodeBuddy 个人助理的各项配置。

## 当用户触发此 Skill 时

请依次询问以下配置项（已有配置项显示当前值供确认）：

### 1. 身份设定
读取 `~/.codebuddy/CODEBUDDY.md`，展示当前身份配置，询问是否需要修改：
- 你的名字（Bot 对你的称呼）
- 你的职业/角色
- 主要编程语言
- Bot 的名字
- 回复语言
- 回复风格

### 2. 记忆管理
读取 `~/.codebuddy/settings.json` 中的 `memory` 配置，询问是否需要调整：
- Auto Memory 开关
- Typed Memory 开关

### 3. 项目配置
询问是否需要在当前项目目录生成 `CODEBUDDY.md`（执行 `/init`）

### 4. 规则管理
列出 `~/.codebuddy/rules/` 下的规则文件，询问是否需要添加/修改/删除规则

## 配置完成后

更新对应文件并提示用户：
- CODEBUDDY.md: `~/.codebuddy/CODEBUDDY.md`
- settings.json: `~/.codebuddy/settings.json`
- rules: `~/.codebuddy/rules/*.md`
SKILLEOF

    info "已安装 /init-setup Skill"
}
