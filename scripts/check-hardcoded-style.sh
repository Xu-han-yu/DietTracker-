#!/usr/bin/env bash
#
# 硬编码样式扫描：确保除了 DietTracker/Theme/ 之外，没有任何文件出现
# 颜色 / 字号 / 圆角 / 阴影的字面量。违反即在 CI 上让构建失败。
#
# 用法（本地）：bash scripts/check-hardcoded-style.sh
#

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

SCAN_DIRS=(DietTracker DietTrackerTests)
ALLOW_PREFIX="DietTracker/Theme/"

# 命中但属于合法用法的行，直接放行
ALLOW_EXPR='Tokens\.|dtTheme|DynamicTypeSize|shadow\(\.none\)'

PATTERNS=(
  'Color\(red:|Color\(green:|Color\(blue:'
  'Color\("[A-Za-z]'
  'Color\(hex:'
  'UIColor\(red:|UIColor\(displayP3Red:'
  'Font\.system\(size:'
  '\.font\(\.system\(size:'
  '\.cornerRadius\([[:space:]]*[0-9]'
  '\.shadow\('
)

failed=0
scanned=0

for dir in "${SCAN_DIRS[@]}"; do
  [ -d "$dir" ] || continue

  while IFS= read -r file; do
    # Theme/ 目录是令牌唯一定义处，豁免
    case "$file" in
      "$ALLOW_PREFIX"*) continue ;;
    esac

    scanned=$((scanned + 1))

    for pattern in "${PATTERNS[@]}"; do
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        num="${line%%:*}"
        text="${line#*:}"

        # 剔除注释行
        trimmed="$(printf '%s' "$text" | sed 's/^[[:space:]]*//')"
        case "$trimmed" in
          '//'*|'*'*|'/*'*) continue ;;
        esac

        # 合法豁免
        if printf '%s' "$text" | grep -qE "$ALLOW_EXPR"; then
          continue
        fi

        echo "::error file=$file,line=$num::发现硬编码样式，请改用 DesignTokens.swift 中的令牌 :: $trimmed"
        failed=1
      done < <(grep -nE "$pattern" "$file" 2>/dev/null)
    done
  done < <(find "$dir" -type f -name '*.swift' | sort)
done

if [ "$failed" -eq 0 ]; then
  echo "check-hardcoded-style: PASS（已扫描 $scanned 个 Swift 文件，未发现硬编码样式）"
else
  echo "::error::发现硬编码样式。原始值只能出现在 DietTracker/Theme/DesignTokens.swift 中。"
fi

exit "$failed"
