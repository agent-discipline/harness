#!/bin/bash
# reinject-mode.sh — 매 사용자 턴 시작 시 현재 구현 모드 + 세션 상태파일 경로를 재주입한다.
# UserPromptSubmit 이벤트. stdin JSON: {session_id, cwd, ...}
#
# 정책 (core.md §1 C3):
#   - session_id 용 env var가 없으므로(문서 미보장), 에이전트가 자기 세션 상태파일 경로를
#     알도록 매 턴 주입한다 — 컨텍스트가 요약돼도 모드·경로·PENDING 복구(일관성).
#   - 상태: <project>/.claude/lazymode/<session_id> — SCHEMA=4(state-lib.sh 소유).
#   - 손상 상태는 quarantine + UNSET 재생성(자동 변환 금지) — 다음 게이트가 재질문.
#   - 긴급 빚(DEBT) 재주입: **모드·리셋 무관** DEBT=1 이면 **매 턴 빚 1줄** (해소 전 완료 선언 금지·차기 L1 빚 우선).
#     빚 정본은 log.md '생략한 검증' — 훅은 재주입만, DEBT 토글은 set-state debt-clear(사용자 확인 후)만.
#   - 요구 대조(v4.10): 읽는 log 의 표에 위반 · 판정 불가 · 열린 빈 칸이 있으면 종류마다 한 줄(없으면 출력 없음).
#
# 종료 코드: 0 (stdout이 컨텍스트로 주입됨)

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=state-lib.sh
. "$SCRIPT_DIR/state-lib.sh" 2>/dev/null || exit 0
# 고정 지시(v4.5 I6): 상태파일이 없어도·MODE=UNSET 이어도·어느 종료 경로에서도 출력 **끝**에 넣는다.
#   파일이 없거나 유효 줄이 없으면 아무것도 출력하지 않는다 — 종전 출력과 바이트 동일.
trap 'state_standing_print' EXIT

HOOK_INPUT=$(cat)

# stdin JSON 파싱 가드 (비차단 훅 — malformed/빈 입력에서 set -e 하 jq 대입 실패로 죽지 않게. 경고 1줄 + exit 0).
if [ -z "$HOOK_INPUT" ] || ! printf '%s' "$HOOK_INPUT" | jq -e 'type == "object"' >/dev/null 2>&1; then
  echo "[reinject-mode] 경고: stdin JSON 파싱 실패(빈 입력 포함) — 모드 재주입 생략(통과)." >&2
  exit 0
fi

CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty')
if [ -z "$CWD" ] || [ ! -d "$CWD" ]; then
  CWD="$PWD"
fi
SESSION_ID=$(state_sanitize_sid "$(echo "$HOOK_INPUT" | jq -r '(.session_id // "") | if type == "string" and test("^[A-Za-z0-9-]+\\z") then . else "" end' 2>/dev/null || true)")
[ -z "$SESSION_ID" ] && exit 0

STATE="$(state_resolve_dir "$CWD" "$SESSION_ID")/$SESSION_ID"   # 조상 탐색 — cwd 추종 오차단 수정(gate-cwd-resolution)
if [ ! -e "$STATE" ] && [ ! -L "$STATE" ]; then exit 0; fi
# rc 1 = 판정 불가(flock/재생성) → UserPromptSubmit(비차단): 경고 1줄 + 통과(C2). 모드 재주입 생략.
if ! state_ensure_valid "$STATE"; then
  echo "[reinject-mode] 경고: 상태 검증 실패(flock/재생성) — 모드 재주입 생략. .claude/lazymode/$SESSION_ID 확인." >&2
  exit 0
fi
[ -f "$STATE" ] || exit 0

MODE=$(state_get "$STATE" MODE)
SPEC=$(state_get "$STATE" SPEC)
PENDING=$(state_get "$STATE" PENDING_GATE)
DEBT=$(state_get "$STATE" DEBT)

case "$MODE" in
  lazy)
    echo "[게이트] MODE=lazy (SPEC=${SPEC:-0}). 상태파일: $STATE (PENDING_GATE=${PENDING:-0}). 매 diff 이해 게이트 — before/after 스니펫 기록 → 사용자 주관식 설명 → 사전 점검(실코드 대조·정답 비노출 힌트, 시도 미산정) → 판정 워커 → 통과 시 set-state.sh gate-pass. ★ 질문·재질문·힌트는 매번 자기완결 — 근거 코드를 파일:줄과 함께 그 메시지에 다시 붙인다(앞서 보였어도). (implementation-lazymode.md §1·§4)"
    ;;
  auto)
    echo "[게이트] MODE=auto (SPEC=${SPEC:-0}). 상태파일: $STATE. 명세 합의 후 자율 실행 — per-diff 게이트 없음. 검증·리뷰는 stakes 비례(자율 ≠ 검증 생략)."
    ;;
  *)
    : # UNSET — L1 진입 시 gate-guard가 SPEC→MODE 순서로 질문
    ;;
esac

# 긴급 빚 미해소 표시 — **모드·리셋 무관** DEBT=1 이면 매 턴 1줄 (core v4 §1 — 정본은 log.md '생략한 검증').
if [ "$DEBT" = "1" ]; then
  echo "[게이트] 긴급 빚 미해소(DEBT=1): 생략한 검증·리뷰·문서 후불 — 해소 전 '작업 완료' 선언 금지, 차기 L1 진입 시 빚 우선. 전항 해소 + 사용자 확인 후 set-state.sh debt-clear. (정본: 작업 폴더 log.md)"
fi

# 압축 뒤 작업 기록 미독(v4.5 I5①) — 종전 출력 뒤. 판정 불가(rc 1 — 출력 = 확인할 사이드카 경로)면
#   판정 불가 한 줄만 낸다(차단은 걸지 않는다 — I7).
RR_RC=0
UNREAD=$(state_reread_unread "$(dirname -- "$STATE")" "$SESSION_ID" "$(state_get "$STATE" TASK_PATH)") || RR_RC=$?
if [ "$RR_RC" != 0 ]; then
  echo "[게이트] 압축 뒤 재독 상태 판정 불가 — 세션 사이드카 확인: ${UNREAD:-$(dirname -- "$STATE")/$SESSION_ID.compact}"
elif [ -n "$UNREAD" ]; then
  echo "[게이트] 압축 뒤 작업 기록 미독 — 구현 파일 쓰기 전에 Read:"
  printf '%s\n' "$UNREAD" | sed 's/^/  /'
fi

# 요구 대조 알림(v4.10 — 명세 6.1 ②) — 읽는 log(TASK_PATH + 사이드카 폴더)를 모아 종류마다 한 줄:
#   위반(닫음 + 빈 칸) → 판정 불가 → 열린 빈 칸(`T01 1/2` — 처음 나온 차례 · 다섯 task 까지 + ` 외 N`) 차례.
#   막히는 두 줄을 앞에. 찾은 것이 없으면 출력 없음(종전과 바이트 동일). 고정 지시는 trap 이라 이 뒤(출력 끝)에 온다.
RQ_FINDINGS=$(state_reqcheck_findings "$(dirname -- "$STATE")" "$SESSION_ID" "$(state_get "$STATE" TASK_PATH)")
RQ_VIOLATION=""; RQ_UNDECIDABLE=""; RQ_OPEN=""; RQ_OPEN_COUNT=0
while IFS=$'\t' read -r RQ_KIND RQ_WHERE RQ_REST; do
  case "$RQ_KIND" in
    VIOLATION)     # RQ_REST = <task>\t<행>
      RQ_VIOLATION+="${RQ_VIOLATION:+ · }${RQ_REST%$'\t'*} ${RQ_REST##*$'\t'}행($RQ_WHERE)" ;;
    UNDECIDABLE)
      RQ_UNDECIDABLE+="${RQ_UNDECIDABLE:+ · }$RQ_WHERE: $RQ_REST" ;;
    OPEN)          # RQ_REST = <task>\t<빈 칸 수>\t<줄 수> — 수 둘은 뒤에서 가른다
      RQ_OPEN_COUNT=$((RQ_OPEN_COUNT + 1))
      if [ "$RQ_OPEN_COUNT" -le 5 ]; then
        RQ_TASK_BLANK=${RQ_REST%$'\t'*}
        RQ_OPEN+="${RQ_OPEN:+ · }${RQ_TASK_BLANK%$'\t'*} ${RQ_TASK_BLANK##*$'\t'}/${RQ_REST##*$'\t'}"
      fi ;;
  esac
done <<< "$RQ_FINDINGS"
if [ "$DEBT" = "1" ]; then
  RQ_NOTE="긴급(DEBT=1)이라 막지 않는다 — log.md '생략한 검증'에 빚으로"
else
  RQ_NOTE="L1 쓰기가 막힌다 — 칸을 채우거나 상태를 열림으로 되돌린다 · 꼴은 templates/log.md"
fi
[ -z "$RQ_VIOLATION" ] || echo "[요구 대조] 닫음인데 '만든 곳 / 넘긴 곳'이 빈 칸 — $RQ_VIOLATION ($RQ_NOTE)"
[ -z "$RQ_UNDECIDABLE" ] || echo "[요구 대조] 표 판정 불가 — $RQ_UNDECIDABLE ($RQ_NOTE)"
if [ "$RQ_OPEN_COUNT" -gt 0 ]; then
  if [ "$RQ_OPEN_COUNT" -gt 5 ]; then RQ_OPEN+=" 외 $((RQ_OPEN_COUNT - 5))"; fi
  echo "[요구 대조] 열린 빈 칸 — $RQ_OPEN"
fi

exit 0
