#!/bin/bash
# reread-track.sh — 압축 뒤 재독 판정용: 작업 기록(spec·log·decisions.md)을 Read 한 시각을 사이드카에 남긴다.
# PostToolUse(matcher: Read). stdin JSON: {session_id, cwd, tool_name, tool_input:{file_path, offset, limit}, agent_id?, ...}
#
# 계약 (decision-archive-compact-reread §10 · core v4.5):
#   - 기록 = <state_dir>/<sid>.reread, 줄마다 `<epoch>\t<canonical 경로>` — 같은 경로는 최신 시각 한 줄로 교체.
#   - 메인의 Read 만(agent_id 있으면 무시 — 서브에이전트가 읽어도 메인 맥락은 복구되지 않는다).
#   - 대상 = 상태 TASK_PATH 의 requirement-spec.md·log.md·decisions.md (canonical 일치). 그 밖의 Read 는 무시.
#   - offset·limit 부분 읽기도 읽은 것으로 본다(전부 읽었는지는 훅이 알 수 없다 — README 한계).
#   - 상태파일은 읽기만 한다. 쓰기 = flock + temp + mv. **어떤 입력·실패에서도 exit 0**(관측 훅 — I7).

set -u   # set -e 금지 — 모든 실패가 exit 0 으로 수렴해야 한다

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=state-lib.sh
. "$SCRIPT_DIR/state-lib.sh" 2>/dev/null || exit 0

HOOK_INPUT=$(cat 2>/dev/null || true)
if [ -z "$HOOK_INPUT" ] || ! printf '%s' "$HOOK_INPUT" | jq -e 'type == "object"' >/dev/null 2>&1; then
  echo "[reread-track] 경고: stdin JSON 파싱 실패(빈 입력 포함) — 기록 생략(통과)." >&2
  exit 0
fi

# Read 마다 도는 훅 — jq 1회로 필드를 뽑는다(구분자 US, 값의 개행·US 는 공백으로).
IFS=$'\x1f' read -r TOOL_NAME AGENT_ID RAW_SID CWD FILE_PATH <<< "$(printf '%s' "$HOOK_INPUT" | jq -j '
  [.tool_name, .agent_id, .session_id, .cwd, .tool_input.file_path]
  | map(if . == null then "" else tostring | gsub("[\n\u001f]"; " ") end) | join("\u001f")' 2>/dev/null)"
[ "${TOOL_NAME:-}" = "Read" ] || exit 0
[ -z "${AGENT_ID:-}" ] || exit 0
[ -n "${FILE_PATH:-}" ] || exit 0
case "${RAW_SID:-}" in ''|*[!A-Za-z0-9-]*) exit 0 ;; esac
SESSION_ID="$RAW_SID"
if [ -z "${CWD:-}" ] || [ ! -d "$CWD" ]; then CWD="$PWD"; fi

STATE_DIR="$(state_resolve_dir "$CWD" "$SESSION_ID")"
STATE="$STATE_DIR/$SESSION_ID"
[ -f "$STATE" ] && [ ! -L "$STATE" ] || exit 0
TASK_PATH=$(state_get "$STATE" TASK_PATH)
[ -n "$TASK_PATH" ] || exit 0

case "$FILE_PATH" in /*) ;; *) FILE_PATH="$CWD/$FILE_PATH" ;; esac
CFILE=$(realpath -m -- "$FILE_PATH" 2>/dev/null) || exit 0
TARGETS=$(state_reread_targets "$TASK_PATH") || exit 0
printf '%s\n' "$TARGETS" | grep -qxF -- "$CFILE" || exit 0

RR="$STATE_DIR/$SESSION_ID.reread"
TS=$(date +%s 2>/dev/null) || exit 0
(
  exec 9>>"$RR.lock" 2>/dev/null || exit 1
  flock -x -w 2 9 2>/dev/null || exit 1
  TMP=$(mktemp "$STATE_DIR/.reread.XXXXXX" 2>/dev/null) || exit 1
  # 기존 줄 보존(이 경로 줄만 교체) — 읽기 실패는 원본을 덮지 않고 중단.
  if [ -e "$RR" ] || [ -L "$RR" ]; then
    awk -F'\t' -v p="$CFILE" '$2 != p' "$RR" > "$TMP" 2>/dev/null || { rm -f "$TMP"; exit 1; }
  fi
  printf '%s\t%s\n' "$TS" "$CFILE" >> "$TMP" 2>/dev/null || { rm -f "$TMP"; exit 1; }
  mv -fT -- "$TMP" "$RR" 2>/dev/null || { rm -f "$TMP"; exit 1; }
) 2>/dev/null || echo "[reread-track] 경고: 읽은 시각 기록 실패($RR) — 압축 뒤 미독 상태가 풀리지 않을 수 있습니다." >&2

exit 0
