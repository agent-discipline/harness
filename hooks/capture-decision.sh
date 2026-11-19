#!/bin/bash
# capture-decision.sh — 선택 질문(AskUserQuestion)의 질문·선택지·답을 작업 폴더 decisions.md 에 자동으로 덧붙인다.
# PostToolUse(matcher: AskUserQuestion). stdin JSON: {session_id, cwd, tool_use_id, tool_input:{questions[]},
#   tool_response:{answers{질문 원문: 답}}, agent_id?, ...}
#
# 계약 (decision-archive-compact-reread §2 I1·I2·I9 · §10 · core v4.5):
#   - 호출 1회 = 블록 1개(`## <로컬 시각> (<tool_use_id>)` + 질문마다 `### header`·질문·선택지·답). 줄바꿈은 공백.
#   - TASK_PATH 있음 → <TASK_PATH>/decisions.md 끝에 덧붙임(append-only — 없으면 제목 줄+빈 줄 먼저).
#     없음 → <state_dir>/<sid>.decisions 사이드카. TASK_PATH 가 생긴 뒤 첫 기록 때 사이드카분을 먼저 옮기고 지운다.
#   - 같은 tool_use_id 는 decisions.md·사이드카 어디에 있든 다시 쓰지 않는다(옮길 때도).
#   - answers 가 없거나 비면 기록하지 않는다. 서브에이전트 안의 호출도 기록한다.
#   - decisions.md 에 못 쓰면 사이드카에 쌓고 경고 — 다음 기록 때 다시 옮긴다.
#   - 쓰는 것은 질문 도구의 질문·답뿐(자유 프롬프트 원문 없음). 명세서·log·상태파일은 건드리지 않는다.
#   - 질문·답·라벨·header 의 줄바꿈·탭·제어 문자·U+2028/2029 는 공백. 빈 tool_use_id 블록은 중복 판정에서 뺀다.
#   - 사이드카를 읽지 못하면 목적지에 새 블록을 쓰지 않는다(순서 보존). 쓰기 실패는 원래 크기로 truncate.
#   - **어떤 입력·실패에서도 exit 0**(관측 훅 — I7). 직렬화 = <sid>.decisions.lock + decisions.md append fd flock.

set -u   # set -e 금지 — 모든 실패가 exit 0 으로 수렴해야 한다

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=state-lib.sh
. "$SCRIPT_DIR/state-lib.sh" 2>/dev/null || exit 0

HOOK_INPUT=$(cat 2>/dev/null || true)
if [ -z "$HOOK_INPUT" ] || ! printf '%s' "$HOOK_INPUT" | jq -e 'type == "object"' >/dev/null 2>&1; then
  echo "[capture-decision] 경고: stdin JSON 파싱 실패(빈 입력 포함) — 기록 생략(통과)." >&2
  exit 0
fi
jqr() { printf '%s' "$HOOK_INPUT" | jq -r "$1" 2>/dev/null || true; }

[ "$(jqr '.tool_name // empty')" = "AskUserQuestion" ] || exit 0
# 답이 없거나 빈 맵(사용자가 답하지 않고 끝난 호출) → 기록 없음.
[ "$(jqr '.tool_response.answers | type == "object" and length > 0')" = "true" ] || exit 0

SESSION_ID=$(state_sanitize_sid "$(jqr '(.session_id // "") | if type == "string" and test("^[A-Za-z0-9-]+\\z") then . else "" end')")
[ -n "$SESSION_ID" ] || exit 0
CWD=$(jqr '.cwd // empty')
if [ -z "$CWD" ] || [ ! -d "$CWD" ]; then CWD="$PWD"; fi

STATE_DIR="$(state_resolve_dir "$CWD" "$SESSION_ID")"
_ED_RC=0; state_ensure_dir "$STATE_DIR" || _ED_RC=$?
case "$_ED_RC" in
  0) ;;
  3) echo "[capture-decision] 경고: 상태 디렉토리 보호 미보장 (원인: ${STATE_ENSURE_REASON:-unknown}) — 사이드카가 git status 에 노출될 수 있습니다(계속)." >&2 ;;
  *) echo "[capture-decision] 경고: 상태 디렉토리 확보 실패 (원인: ${STATE_ENSURE_REASON:-unknown}) — 선택 질문 기록 생략." >&2
     exit 0 ;;
esac
STATE="$STATE_DIR/$SESSION_ID"
SIDECAR="$STATE_DIR/$SESSION_ID.decisions"

# 한 줄로 만들기(FIX-8): CRLF·CR·LF·탭·그 밖의 제어 문자(Cc)·U+2028·U+2029 → 공백.
TOOL_USE_ID=$(jqr '(.tool_use_id // "") | tostring | gsub("\r\n"; " ") | gsub("[\\p{Cc}\u2028\u2029]"; " ")')
# 블록 본문 — 질문·header·선택지·답은 한 줄로. 답은 받은 값 그대로(문자열이 아니면 JSON 표기).
BLOCK=$(printf '%s' "$HOOK_INPUT" | jq -r --arg ts "$(date '+%F %T')" --arg id "$TOOL_USE_ID" '
  def one: tostring | gsub("\r\n"; " ") | gsub("[\\p{Cc}\u2028\u2029]"; " ");
  .tool_response.answers as $a
  | "## \($ts) (\($id))\n\n"
    + ([ (.tool_input.questions // .tool_response.questions // [])[]
         | (.question // "") as $q
         | "### \(.header // "" | one)\n- 질문: \($q | one)\n- 선택지: \([.options[]?.label // "" | one] | join(" / "))\n- 답: \($a[$q] // "" | if type == "string" then . else tojson end | one)" ]
       | join("\n\n"))' 2>/dev/null) || BLOCK=""
[ -n "$BLOCK" ] || { echo "[capture-decision] 경고: 블록 생성 실패 — 기록 생략." >&2; exit 0; }
BLOCK="$BLOCK"$'\n'

TITLE='# decisions — 선택 질문과 답 (훅이 자동 기록)'

has_id() { # <file> — 이 tool_use_id 의 블록이 이미 있나 (빈 id 는 중복 판정에서 뺀다 — 항상 "없음")
  [ -n "$TOOL_USE_ID" ] && [ -f "$1" ] && grep -F -- " ($TOOL_USE_ID)" "$1" 2>/dev/null | grep -q '^## '
}
sep_for() { # <file> → 덧붙이기 전 구분 개행(블록 사이 빈 줄 하나)
  [ -s "$1" ] || return 0
  if [ -n "$(tail -c 1 -- "$1" 2>/dev/null)" ]; then printf '\n\n'      # 끝 개행 없음
  elif [ -n "$(tail -n 1 -- "$1" 2>/dev/null)" ]; then printf '\n'      # 마지막 줄이 내용
  fi                                                                    # 이미 빈 줄로 끝남
}
# 사이드카 블록 중 <dest> 에 없는 tool_use_id 만, 앞뒤 빈 줄 없이 출력. 빈 id 블록은 항상 옮긴다.
#   rc 비-0 = 사이드카 읽기·파싱 실패(호출부는 새 블록을 목적지에 쓰지 않는다 — 순서 보존). 경로는 ENVIRON 으로.
pending_from_sidecar() { # <dest>
  local dest="$1"
  if [ ! -e "$SIDECAR" ] && [ ! -L "$SIDECAR" ]; then return 0; fi
  { [ -f "$SIDECAR" ] && [ ! -L "$SIDECAR" ] && [ -r "$SIDECAR" ]; } || return 1
  [ -f "$dest" ] || dest=/dev/null
  _CD_D="$dest" awk '
    function bid(s) { sub(/^.* \(/, "", s); sub(/\)$/, "", s); return s }
    FILENAME == ENVIRON["_CD_D"] { if ($0 ~ /^## /) { id = bid($0); if (id != "") seen[id] = 1 }; next }
    /^## / { id = bid($0); keep = (id == "") || !(id in seen); if (id != "") seen[id] = 1 }
    keep { if ($0 == "") { nb++; next } if (out) for (i = 0; i < nb; i++) print ""; nb = 0; print; out = 1 }
  ' "$dest" "$SIDECAR"
}
sidecar_append() { # 새 블록을 사이드카에 (temp+mv). rc 비-0 = 실패
  local tmp
  # 읽을 수 없는(쓰기만 되는) 정규 사이드카 — 읽지 않고 >> 한 번으로 끝에 덧붙인다(기존 내용 보존).
  #   중복 판정은 못 하므로 건너뛴다(유실보다 중복 — 옮길 때 목적지 기준 중복은 다시 걸러진다). 앞 빈 줄 하나로 구분.
  if [ -f "$SIDECAR" ] && [ ! -L "$SIDECAR" ] && [ ! -r "$SIDECAR" ]; then
    printf '\n%s' "$BLOCK" >> "$SIDECAR" 2>/dev/null
    return
  fi
  has_id "$SIDECAR" && return 0
  tmp=$(mktemp "$STATE_DIR/.decisions.XXXXXX" 2>/dev/null) || return 1
  # 단계마다 검사 — 기존 사이드카 읽기 실패가 뒤 printf 성공에 가려져 원본을 새 블록만으로 덮는 사고 차단.
  if [ -e "$SIDECAR" ] || [ -L "$SIDECAR" ]; then
    { cat -- "$SIDECAR" > "$tmp" && sep_for "$SIDECAR" >> "$tmp"; } 2>/dev/null || { rm -f -- "$tmp"; return 1; }
  fi
  printf '%s' "$BLOCK" >> "$tmp" 2>/dev/null && mv -fT -- "$tmp" "$SIDECAR" 2>/dev/null || { rm -f -- "$tmp"; return 1; }
}
sidecar_fallback() { # 새 블록을 사이드카로 — 실패하면 경고(이번 질문·답 유실)
  sidecar_append || echo "[capture-decision] 경고: 사이드카($SIDECAR) 쓰기 실패 — 이번 선택 질문·답이 남지 않았습니다." >&2
}

# 잠금 2단: 세션 사이드카 lock(종전) → 목적지 decisions.md 의 append fd 에 flock(목적지 단위 — 다른 세션과도
#   직렬화. docs 폴더에 lock 파일을 만들지 않는다). 제목 판정·사이드카 이동·append 는 한 임계구역.
(
  { exec 9>>"$SIDECAR.lock"; } 2>/dev/null || exit 1   # 묶음 리디렉션 — 서브셸 stderr(경고) 는 살린다
  flock -x -w 2 9 2>/dev/null || exit 1
  TASK_PATH=""
  [ -f "$STATE" ] && TASK_PATH=$(state_get "$STATE" TASK_PATH)
  if [ -z "$TASK_PATH" ]; then sidecar_fallback; exit 0; fi
  D="$TASK_PATH/decisions.md"
  if [ -L "$D" ] || { [ -e "$D" ] && [ ! -f "$D" ]; }; then
    echo "[capture-decision] 경고: $D 가 정규 파일이 아님 — 사이드카에 쌓습니다." >&2
    sidecar_fallback; exit 0
  fi
  # 옮길 사이드카를 읽을 수 없으면 목적지를 열기(=빈 파일 생성) 전에 물러난다. 임계구역 안에서도 다시 본다.
  if { [ -e "$SIDECAR" ] || [ -L "$SIDECAR" ]; } && ! { [ -f "$SIDECAR" ] && [ ! -L "$SIDECAR" ] && [ -r "$SIDECAR" ]; }; then
    echo "[capture-decision] 경고: 사이드카($SIDECAR)를 읽지 못함 — 순서를 지키려고 $D 에 쓰지 않고 사이드카에 덧붙입니다(사이드카는 지우지 않음)." >&2
    sidecar_fallback; exit 0
  fi
  # 보충 30: 있는데 읽을 수 없으면 중복 판정이 안 되므로 쓰지 않는다.
  D_EXISTED=0
  if [ -e "$D" ]; then
    D_EXISTED=1
    if [ ! -r "$D" ]; then
      echo "[capture-decision] 경고: $D 를 읽을 수 없음(중복 판정 불가) — 쓰지 않고 사이드카($SIDECAR)에 쌓습니다." >&2
      sidecar_fallback; exit 0
    fi
  fi
  # 보충 29: 실패 경로에서 이 실행이 새로 만든 빈 decisions.md 를 지운다(그 사이 다른 writer 가 내용을 썼으면 남김).
  drop_created_empty() { if [ "$D_EXISTED" = 0 ] && [ -f "$D" ] && [ ! -s "$D" ]; then rm -f -- "$D"; fi; }
  # append-only: 목적지를 >> 로 연다(임시 파일 교체를 쓰지 않는다 — 읽기 전용 decisions.md 를 덮어쓰지 않게).
  if ! { exec 8>>"$D"; } 2>/dev/null || ! flock -x -w 2 8 2>/dev/null; then
    drop_created_empty
    echo "[capture-decision] 경고: $D 를 열거나 잠그지 못함 — 사이드카($SIDECAR)에 쌓고 다음 기록 때 다시 옮깁니다." >&2
    sidecar_fallback; exit 0
  fi
  # 보충 28: 잠근 fd 의 inode(쓰기 뒤 경로의 inode 와 비교 — 쓰는 사이 파일 교체 감지).
  FD_INO=$(stat -L -c %i /proc/self/fd/8 2>/dev/null) || FD_INO=""
  if ! MIG=$(pending_from_sidecar "$D"); then
    drop_created_empty
    echo "[capture-decision] 경고: 사이드카($SIDECAR)를 읽지 못함 — 순서를 지키려고 $D 에 쓰지 않고 사이드카에 덧붙입니다(사이드카는 지우지 않음)." >&2
    sidecar_fallback; exit 0
  fi
  NEW="$BLOCK"   # 같은 tool_use_id 가 decisions.md 또는 옮길 사이드카분에 있으면 새 블록은 쓰지 않는다
  if has_id "$D" || { [ -n "$TOOL_USE_ID" ] && printf '%s\n' "$MIG" | grep -F -- " ($TOOL_USE_ID)" | grep -q '^## '; }; then
    NEW=""
  fi
  if [ -z "$MIG" ] && [ -z "$NEW" ]; then drop_created_empty; rm -f -- "$SIDECAR"; exit 0; fi
  CHUNK=""
  [ -n "$MIG" ] && CHUNK="$MIG"$'\n'
  if [ -n "$NEW" ]; then
    [ -n "$CHUNK" ] && CHUNK="$CHUNK"$'\n'
    CHUNK="$CHUNK$NEW"
  fi
  SIZE=$(stat -c %s -- "$D" 2>/dev/null) || SIZE=""
  if [ "$SIZE" = 0 ]; then OUT="$TITLE"$'\n\n'"$CHUNK"
  else OUT="$(sep_for "$D"; printf '.')"; OUT="${OUT%.}$CHUNK"; fi
  if [ -n "$SIZE" ] && [ -n "$FD_INO" ] && printf '%s' "$OUT" >&8 2>/dev/null; then
    if [ "$(stat -c %i -- "$D" 2>/dev/null)" = "$FD_INO" ]; then
      rm -f -- "$SIDECAR"
      exit 0
    fi
    # 쓰는 사이 경로의 파일이 바뀌었다 — 쓴 내용은 경로에 없다. 옮기던 분은 사이드카에 그대로, 새 블록도 사이드카로.
    echo "[capture-decision] 경고: $D 가 기록 중 다른 파일로 바뀜(inode 불일치) — 사이드카($SIDECAR)에 남기고 다음 기록 때 다시 옮깁니다." >&2
    [ -z "$NEW" ] || sidecar_fallback
    exit 0
  fi
  # 쓰기 실패 — 부분 쓰기를 원래 크기로 되돌린다. 옮길 사이드카분은 사이드카에 그대로 남는다.
  if [ -n "$SIZE" ] && ! truncate -s "$SIZE" -- "$D" 2>/dev/null; then
    echo "[capture-decision] 경고: $D 쓰기 실패 후 되돌리기도 실패 — ${SIZE} 바이트 뒤에 일부 블록이 남았을 수 있습니다." >&2
  fi
  drop_created_empty
  echo "[capture-decision] 경고: $D 에 쓰지 못함 — 사이드카($SIDECAR)에 쌓고 다음 기록 때 다시 옮깁니다." >&2
  [ -z "$NEW" ] || sidecar_fallback
  exit 0
) || echo "[capture-decision] 경고: 선택 질문 기록 실패(잠금) — 이번 질문·답이 남지 않았습니다." >&2

exit 0
