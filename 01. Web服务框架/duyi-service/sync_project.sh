#!/usr/bin/env zsh
# ==============================================================================
# sync_project.sh
# 将指定路径下的 duyi-service 目录完整同步（替换）到当前工程目录
# ==============================================================================

set -euo pipefail

# 获取当前脚本所在的工程根目录
TARGET_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$(basename "$0")"

# 获取源目录参数（支持命令行传参，也支持交互式拖入文件夹）
SOURCE_INPUT="${1:-}"
if [[ -z "$SOURCE_INPUT" ]]; then
    echo "请输入（或直接从访达拖拽）源 duyi-service 目录路径，然后按回车："
    read -r SOURCE_INPUT
fi

# 去除拖拽路径可能自带的首尾引号、空格及转义反斜杠
SOURCE_INPUT="${SOURCE_INPUT#"${SOURCE_INPUT%%[![:space:]]*}"}"
SOURCE_INPUT="${SOURCE_INPUT%"${SOURCE_INPUT##*[![:space:]]}"}"
SOURCE_INPUT="${SOURCE_INPUT#[\'\"]}"
SOURCE_INPUT="${SOURCE_INPUT%[\'\"]}"
SOURCE_INPUT="${SOURCE_INPUT//\\ / }"

if [[ ! -d "$SOURCE_INPUT" ]]; then
    echo "❌ 错误：找不到源目录 -> $SOURCE_INPUT"
    exit 1
fi

SOURCE_DIR="$(cd "$SOURCE_INPUT" && pwd)"

# 如果传入的是外层章节目录（如 "16. 长事务和短事务"），自动定位到其内部的 duyi-service
if [[ "$(basename "$SOURCE_DIR")" != "duyi-service" && -d "$SOURCE_DIR/duyi-service" ]]; then
    SOURCE_DIR="$SOURCE_DIR/duyi-service"
    echo "💡 自动识别到内部子目录: $SOURCE_DIR"
fi

# 安全校验：禁止源目录和目标目录相同
if [[ "$SOURCE_DIR" == "$TARGET_DIR" ]]; then
    echo "❌ 错误：源目录与当前目标工程目录相同，无需替换！"
    exit 1
fi

# 安全校验：确认源目录是一个有效的 duyi-service 工程
if [[ ! -f "$SOURCE_DIR/pyproject.toml" && ! -d "$SOURCE_DIR/apps" ]]; then
    echo "❌ 错误：源目录看起来不是有效的 duyi-service 工程（缺少 pyproject.toml 或 apps 目录）："
    echo "   $SOURCE_DIR"
    exit 1
fi

echo "=================================================="
echo "📂 源目录  : $SOURCE_DIR"
echo "🎯 目标目录: $TARGET_DIR"
echo "=================================================="
echo "⚠️  即将把源目录的文件递归覆盖合并到当前工程（保留当前工程已有的其他文件及本地环境）。"
printf "确认执行覆盖合并吗？[y/N]: "
read -r CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "已取消操作。"
    exit 0
fi

# 使用 rsync 进行递归覆盖合并（不加 --delete，因为课程每章目录仅存放该章新增/修改的增量文件）
rsync -av \
    --exclude="$SCRIPT_NAME" \
    --exclude="scripts/run_changed_tests.py" \
    --exclude=".venv/" \
    --exclude=".git/" \
    --exclude=".vscode/" \
    --exclude=".env" \
    --exclude=".env.test" \
    --exclude="node_modules/" \
    --exclude=".pytest_cache/" \
    --exclude="__pycache__/" \
    --exclude=".coverage*" \
    --exclude="htmlcov/" \
    --exclude="tmp/" \
    --exclude=".DS_Store" \
    "$SOURCE_DIR/" "$TARGET_DIR/"

# 如果子包 pyproject.toml 声明了 readme = "README.md" 但课程资料漏掉了该文件，自动补齐防止 uv sync 报错
if [[ -f "$TARGET_DIR/apps/web-service/pyproject.toml" ]] && grep -q 'readme *= *"README.md"' "$TARGET_DIR/apps/web-service/pyproject.toml"; then
    [[ -f "$TARGET_DIR/apps/web-service/README.md" ]] || touch "$TARGET_DIR/apps/web-service/README.md"
fi

echo ""
echo "✅ 目录替换完成！"
echo "💡 提示：如果新章节新增了依赖，可执行 'uv sync'（Python）或 'pnpm install'（前端）更新依赖。"

