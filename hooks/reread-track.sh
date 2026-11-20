#!/bin/bash
# reread-track.sh — 압축 뒤 재독 판정용: 작업 기록(spec·log·decisions.md)을 Read 한 시각을 사이드카에 남긴다.
# PostToolUse(matcher: Read). stdin JSON: {session_id, cwd, tool_name, tool_input:{file_path, offset, limit}, agent_id?, ...}
#
# 계약 (decision-archive-compact-reread §10 · core v4.5):
#   - 기록 = <state_dir>/<sid>.reread, 줄마다 `<epoch>\t<canonical 경로>` — 같은 경로는 최신 시각 한 줄로 교체.
#   - 메인의 Read 만(agent_id 있으면 무시 — 서브에이전트가 읽어도 메인 맥락은 복구되지 않는다).
#   - 대상 = 상태 TASK_PATH 의 requirement-spec.md·log.md·decisions.md (canonical 일치). 그 밖의 Read 는 무시.
#   - offset·limit 이 값으로 들어온 부분 읽기는 기록하지 않는다(둘 다 없거나 null 인 전체 Read 만 — v4.6 I1).
#   - 매 호출 세션 표시 <sid>.reread-seen 을 보장한다(없을 때만 생성 — session-mode-guard 가 그 세션 것만 확인).
#   - 상태파일은 읽기만 한다. 쓰기 = flock + temp + mv. **어떤 입력·실패에서도 exit 0**(관측 훅 — I7).

set -u   # set -e 금지 — 모든 실패가 exit 0 으로 수렴해야 한다

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=state-lib.sh
. "$SCRIPT_DIR/state-lib.sh" 2>/dev/null || exit 0

HOOK_INPUT=$(cat 2>/dev/null || true)
# Read 마다 도는 훅 — 파싱 검사와 필드 추출을 jq 1회로(객체가 아니면 error → rc≠0). 구분자 US, 값의 개행·US 는 공백.
FIELDS=""
[ -n "$HOOK_INPUT" ] && FIELDS=$(printf '%s' "$HOOK_INPUT" | jq -j '
  if type != "object" then error("not object") else . end
  | [.tool_name, .agent_id, .session_id, .cwd, .tool_input.file_path,
     (if .tool_input.offset != null or .tool_input.limit != null then "1" else null end)]
  | map(if . == null then "" else tostring | gsub("[\n\u001f]"; " ") end) | join("\u001f")' 2>/dev/null) || FIELDS=""
if [ -z "$FIELDS" ]; then
  echo "[reread-track] 경고: stdin JSON 파싱 실패(빈 입력 포함) — 기록 생략(통과)." >&2
  exit 0
fi
IFS=$'\x1f' read -r TOOL_NAME AGENT_ID RAW_SID CWD FILE_PATH PARTIAL <<< "$FIELDS"
[ "${TOOL_NAME:-}" = "Read" ] || exit 0
case "${RAW_SID:-}" in ''|*[!A-Za-z0-9-]*) exit 0 ;; esac
SESSION_ID="$RAW_SID"
if [ -z "${CWD:-}" ] || [ ! -d "$CWD" ]; then CWD="$PWD"; fi
STATE_DIR="$(state_resolve_dir "$CWD" "$SESSION_ID")"

# 세션 표시(<sid>.reread-seen, 보충 27) — 이 세션에서 이 훅이 돈 적이 있다는 표시. session-mode-guard 는 그 세션의
#   표시가 있을 때만 압축 시각을 쓴다(Read 등록 없는 상태의 영구 차단 방지). 대상·agent_id 와 무관하게 매 호출 확인,
#   없을 때만 만든다(유효한 session_id 일 때만 — 위에서 걸렀다).
SEEN="$STATE_DIR/$SESSION_ID.reread-seen"
if [ ! -e "$SEEN" ]; then
  _ED_RC=0; state_ensure_dir "$STATE_DIR" || _ED_RC=$?
  case "$_ED_RC" in
    0|3) : >> "$SEEN" 2>/dev/null \
           || echo "[reread-track] 경고: 세션 표시 생성 실패($SEEN) — 압축 뒤 재독 강제가 걸리지 않습니다." >&2 ;;
    *) echo "[reread-track] 경고: 상태 디렉토리 확보 실패 (원인: ${STATE_ENSURE_REASON:-unknown}) — 기록 생략." >&2
       exit 0 ;;
  esac
fi

[ -z "${AGENT_ID:-}" ] || exit 0
[ -z "${PARTIAL:-}" ] || exit 0   # 부분 읽기(offset·limit)는 읽은 것으로 세지 않는다(v4.6 I1) — 세션 표시는 위에서 이미 만들었다
# 대상 이름이 아니면 상태파일·realpath 전에 끝낸다(성능 — 대부분의 Read 가 여기서 끝난다).
case "${FILE_PATH##*/}" in requirement-spec.md|log.md|decisions.md) ;; *) exit 0 ;; esac

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
  # 기존 줄 보존(이 경로 줄만 교체 — 첫 탭 뒤 전체가 경로, 경로는 ENVIRON 으로) — 읽기 실패는 원본을 덮지 않고 중단.
  if [ -e "$RR" ] || [ -L "$RR" ]; then
    _RR_P="$CFILE" awk '{ i = index($0, "\t"); if (i > 0 && substr($0, i + 1) == ENVIRON["_RR_P"]) next; print }' \
      "$RR" > "$TMP" 2>/dev/null || { rm -f "$TMP"; exit 1; }
  fi
  printf '%s\t%s\n' "$TS" "$CFILE" >> "$TMP" 2>/dev/null || { rm -f "$TMP"; exit 1; }
  mv -fT -- "$TMP" "$RR" 2>/dev/null || { rm -f "$TMP"; exit 1; }
) 2>/dev/null || echo "[reread-track] 경고: 읽은 시각 기록 실패($RR) — 압축 뒤 미독 상태가 풀리지 않을 수 있습니다." >&2

exit 0
