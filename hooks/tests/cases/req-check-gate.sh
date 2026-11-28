# req-check-gate.sh — 요구 대조 표를 읽는 쪽: state-lib `state_reqcheck_paths` · gate-guard 의 차단 · reinject-mode 의 알림 (v4.10 · task 04)
# 계약 정본: docs/plans/2026-11-27/close-out-requirement-check/requirement-spec.md 2절 · 6.1 ② ③ · 6.2
#            + task 04 브리핑의 A · B · C 조항(읽는 쪽만 — 사이드카에 쓰는 것은 task 05. 여기서는 사이드카를 직접 만든다).
#            + 표의 꼴 = templates/log.md 의 "요구 대조" 절 · 파서 = state_reqcheck_scan(task 03 — cases/req-check.sh).
# 설계: blind 테스트 워커(구현 미열람 — 계약에서 출발). 출력 글자 전체를 고정하지 않고 핵심 낱말 · 수 · 행 번호 · 경로 ·
#   JSON 의 꼴을 본다.
# 관례: sandbox_init 은 run.sh 러너가 각 테스트 앞에서 호출한다. 테스트 이름은 러너의 수집 정규식(`test_[a-z0-9_]+`)에
#   맞춰 영문 규칙 문장으로, 조항(a · b · c)과 번호를 앞머리에 둔다.
# "종전과 같다" = 기준 커밋(RG_BASE_SHA — 이 task 착수 직전)의 gate-guard · reinject-mode · state-lib 사본
#   (hooks/tests/fixtures/legacy-d42c6a9/ — `git show $RG_BASE_SHA:hooks/<파일>` 그대로)을 같은 입력으로 실행한 값.
#   git 이력이 없는 배포 사본에서도 돌도록 git 을 쓰지 않는다(decision-reread.sh · worker-notice.sh 의 legacy 관례와 같다).
#   비교 = 종료 코드 · stdout 바이트 · stderr 바이트 · 실행 뒤 상태파일 바이트. 두 실행은 각자 비운 상태 디렉토리에서 한다
#   (구현 주체 알림의 사이드카가 앞 실행의 기억을 넘기지 않게).

RG_BASE_SHA=d42c6a95b48424e543fbad11e4d9accbc6625788
RG_LEGACY_SOURCE="$TESTS_DIR/fixtures/legacy-d42c6a9"

# ── 표의 꼴(templates/log.md 의 글자 그대로) ─────────────────────────────────────
RG_MARK='<!-- req-check:v1 -->'
RG_HEAD='| task | 원문 위치 | 요구 | 만든 곳 / 넘긴 곳 | 상태 |'
RG_SEP='|---|---|---|---|---|'

# ── 셋업 ────────────────────────────────────────────────────────────────────────
rg_folder() { # <이름> → stdout: 작업 폴더(canonical 절대 경로) — 폴더를 만든다(log.md 는 만들지 않는다)
  local folder
  folder=$(realpath -m -- "$REPO/docs/plans/2026-11-27/$1")
  mkdir -p "$folder"
  printf '%s' "$folder"
}
rg_preamble() { # [앞 줄 수 — 기본 0] → 행 번호가 폴더마다 다르게 군더더기 줄을 더 둔다
  printf '%s\n' '# 작업 log' '' '## 타임라인' '' '| 시각 | 사건 | 결과 |' '|---|---|---|' '| 17:00 | 시작 | - |'
  local index=0
  while [ "$index" -lt "${1:-0}" ]; do printf '%s\n' "- 메모 $index"; index=$((index + 1)); done
  printf '%s\n' '' '## 요구 대조' ''
}
rg_log_lines() { # <폴더> <줄...> → <폴더>/log.md 에 줄마다
  local folder=$1; shift
  printf '%s\n' "$@" > "$folder/log.md"
}
rg_log_table() { # <폴더> <앞 줄 수> <표 본문 줄...> → 표지 + 머리 줄 + 구분 줄 + 본문 + 빈 줄 + 뒤 절
  local folder=$1 extra=$2; shift 2
  rg_log_lines "$folder" "$(rg_preamble "$extra")" "$RG_MARK" "$RG_HEAD" "$RG_SEP" "$@" '' '## 고장 내기' '' \
    '| 불변식 | 테스트 | 고장 낸 곳 | 실패 메시지 첫 줄 | 되돌린 뒤 통과 |' '|---|---|---|---|---|' '| | | | | |'
}
rg_lineno() { # <파일> <고정 문자열> → 그 글자가 처음 나오는 행 번호(고정 자료 자체 확인)
  local number
  number=$(grep -nF -- "$2" "$1" | head -1 | cut -d: -f1 || true)
  [ -n "$number" ] || { echo "  [dbg] fixture $1 에 '$2' 없음"; fail fixture-needle-missing; }
  printf '%s' "$number"
}
# 자주 쓰는 표 — 위반(닫음 빈 칸) · 열린 빈 칸만 · 다 채움 · 머리 줄 틀림
rg_log_violation() { # <폴더> <task> [앞 줄 수] → RG_VLINE = 위반 줄의 행 번호
  rg_log_table "$1" "${3:-0}" \
    "| $2 | 규약 §1 | 요구-채움 | hooks/a.sh:3 | 닫음 |" \
    "| $2 | 규약 §2 | 요구-닫음-빈칸-$2 | | 닫음 |"
  RG_VLINE=$(rg_lineno "$1/log.md" "요구-닫음-빈칸-$2")
}
rg_log_open_only() { # <폴더> → 열림 빈 칸 하나 · 위반 없음(T01 1/2)
  rg_log_table "$1" 0 \
    '| T01 | 규약 §1 | 요구-가 | hooks/a.sh:3 | 닫음 |' \
    '| T01 | 규약 §2 | 요구-나 | | 열림 |'
}
rg_log_filled() { # <폴더> → 모든 줄 채움(출력 없음)
  rg_log_table "$1" 0 \
    '| T01 | 규약 §1 | 요구-가 | hooks/a.sh:3 | 닫음 |' \
    '| T02 | 규약 §2 | 요구-나 | T03 으로 넘김 | 열림 |'
}
rg_log_bad_header() { # <폴더> → 머리 줄 틀림(판정 불가) — RG_HLINE = 틀린 머리 줄의 행 번호
  rg_log_lines "$1" "$(rg_preamble 0)" "$RG_MARK" '| task | 원문 위치 | 요구 | 만든 곳 | 상태 |' "$RG_SEP" \
    '| T01 | 규약 §1 | 요구-가 | hooks/a.sh:1 | 닫음 |'
  RG_HLINE=$(rg_lineno "$1/log.md" '| task | 원문 위치 | 요구 | 만든 곳 | 상태 |')
}
rg_log_no_marker() { # <폴더> → 표지 없는 log(닫음 빈 칸 줄이 있어도 대상 아님)
  rg_log_lines "$1" "$(rg_preamble 0)" "$RG_HEAD" "$RG_SEP" '| T01 | 규약 §1 | 요구-가 | | 닫음 |'
}
rg_log_template() { # <폴더> → templates/log.md 그대로(없으면 건너뜀)
  local template="$HOOKS_DIR/../templates/log.md"
  [ -f "$template" ] || skip_test log-template-absent
  grep -qxF -- "$RG_MARK" "$template" || fail template-has-marker
  cp -- "$template" "$1/log.md"
}

# 상태파일을 통째로 쓴다(SCHEMA=4 + TASK_PATH 줄). TASK_PATH 인자 '-' = 줄 없음.
rg_state() { # <MODE> <PENDING_GATE> <DEBT> <SPEC> <TASK_PATH|->
  {
    echo "SCHEMA=4"; echo "MODE=$1"; echo "SPEC=$4"; echo "PENDING_GATE=$2"; echo "DEBT=$3"
    if [ "$5" != "-" ]; then echo "TASK_PATH=$5"; fi
  } > "$STATE"
}
RG_SIDECAR_NAME_SUFFIX=.req-check-paths
rg_sidecar_path() { printf '%s' "$STATE_DIR/$SID$RG_SIDECAR_NAME_SUFFIX"; }
rg_sidecar() { # <줄...> → 사이드카에 줄마다(끝 개행 있음)
  printf '%s\n' "$@" > "$(rg_sidecar_path)"
}
rg_sidecar_raw() { # <printf 형식 그대로의 내용> → 끝 개행 · 빈 줄을 손으로 정할 때
  printf '%s' "$1" > "$(rg_sidecar_path)"
}
rg_standing() { mkdir -p "$HOME_DIR/.claude"; printf '%s\n' '# 머리 주석' '응답은 한국어로' > "$HOME_DIR/.claude/standing-instructions.md"; }
rg_clear_state_dir() { find "$STATE_DIR" -mindepth 1 -delete 2>/dev/null || true; }

# ── JSON 빌더(worker-notice.sh wn_json 과 같은 필드) ─────────────────────────────
# agent 인자: none = agent_id 키 없음(메인) · 그 밖 = 워커 agent_id 값(+agent_type)
rg_json() { # <event> <tool> <file_path> [agent]
  jq -cn --arg e "$1" --arg t "$2" --arg f "$3" --arg agent "${4:-none}" --arg s "$SID" --arg c "$REPO" '
    {session_id:$s, cwd:$c, permission_mode:"auto", hook_event_name:$e, tool_name:$t,
     tool_input:({file_path:$f}
       + (if $t == "Write" then {content:"x"} elif $t == "Edit" then {old_string:"a", new_string:"b"}
          else {edits:[{old_string:"a", new_string:"b"}]} end)),
     tool_use_id:"toolu_rg"}
    + (if $agent == "none" then {} else {agent_id:$agent, agent_type:"general-purpose"} end)'
}
RG_L1="src/app.sh"   # L1 쓰기 대상(REPO 안 · docs 밖)

# ── 실행 헬퍼 — stdout · stderr 를 따로 받는다 → HOOK_EXIT · HOOK_STDOUT · HOOK_STDERR · RG_OUT_FILE ───────
rg_run() { # <hook 절대경로> <json> [태그]
  local capture="$SANDBOX/rg-capture" tag="${3:-last}"
  mkdir -p "$capture"
  set +e
  printf '%s' "$2" | env HOME="$HOME_DIR" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
    XDG_CONFIG_HOME="$XDG_DIR" bash "$1" > "$capture/$tag.out" 2> "$capture/$tag.err"
  HOOK_EXIT=$?
  set -e
  RG_OUT_FILE="$capture/$tag.out"
  HOOK_STDOUT=$(cat "$capture/$tag.out")
  HOOK_STDERR=$(cat "$capture/$tag.err")
}
rg_gate() { rg_run "$HOOKS_DIR/gate-guard.sh" "$(rg_json "$@")" "${RG_TAG:-last}"; }   # <event> <tool> <file_path> [agent]
rg_l1() { rg_gate PreToolUse "${1:-Write}" "$REPO/$RG_L1" "${2:-none}"; }               # [tool] [agent]
rg_reinject() { rg_run "$HOOKS_DIR/reinject-mode.sh" "$(json_prompt '다음 할 일')" "${RG_TAG:-last}"; }

# ── 단언 ────────────────────────────────────────────────────────────────────────
rg_dbg() { # 글자 단위로 자른다(바이트로 자르면 한글이 깨져 러너의 grep 이 [dbg] 줄을 바이너리로 본다)
  local out=${HOOK_STDOUT//$'\n'/\~} err=${HOOK_STDERR//$'\n'/\~}
  echo "  [dbg] exit=$HOOK_EXIT stdout=${out:0:200} stderr=${err:0:300}"
}
rg_assert_exit() { [ "$HOOK_EXIT" = "$1" ] || { rg_dbg; fail "$2"; }; }                                     # <want> <id>
rg_err_has() { printf '%s' "$HOOK_STDERR" | grep -qF -- "$1" || { rg_dbg; echo "  [dbg] want-in-stderr=$1"; fail "$2"; }; }   # <고정 문자열> <id>
rg_err_lacks() { if printf '%s' "$HOOK_STDERR" | grep -qF -- "$1"; then rg_dbg; fail "$2"; fi; }              # <고정 문자열> <id>
rg_err_has_number() { # <수> <id> — 앞뒤가 숫자가 아닌 낱말로
  printf '%s' "$HOOK_STDERR" | grep -qE "(^|[^0-9])$1([^0-9]|\$)" || { rg_dbg; echo "  [dbg] want-number=$1"; fail "$2"; }
}
rg_text_has_number() { printf '%s' "$1" | grep -qE "(^|[^0-9])$2([^0-9]|\$)"; }   # <글> <수>
# 막힘의 공통 꼴: exit 2 · stderr 에 `요구 대조` · 푸는 길(넷째 칸 이름 · `열림`으로 되돌리기)
rg_assert_reqcheck_block() { # <id>
  rg_assert_exit 2 "$1-exit2"
  rg_err_has '요구 대조' "$1-word"
  rg_err_has '만든 곳 / 넘긴 곳' "$1-how-fill"
  rg_err_has '열림' "$1-how-reopen"
}
rg_assert_violation_reported() { # <task> <행> <log 경로> <id> — 위반마다 task · 행 번호 · 그 log 경로
  rg_err_has "$1" "$4-task"
  rg_err_has_number "$2" "$4-line"
  rg_err_has "$3" "$4-path"
}
# DEBT=1 알림: stdout 이 정확히 JSON 하나 · 키 = hookSpecificOutput{hookEventName:"PreToolUse", additionalContext:string}
RG_CONTEXT_FILTER='
  length == 1
  and (.[0] | type == "object")
  and ((.[0] | keys) == ["hookSpecificOutput"])
  and ((.[0].hookSpecificOutput | keys) == ["additionalContext", "hookEventName"])
  and .[0].hookSpecificOutput.hookEventName == "PreToolUse"
  and (.[0].hookSpecificOutput.additionalContext | type == "string")'
rg_assert_single_context_json() { # <id> → RG_CONTEXT = additionalContext 글
  jq -se "$RG_CONTEXT_FILTER" < "$RG_OUT_FILE" >/dev/null 2>&1 || { rg_dbg; fail "$1-one-json"; }
  RG_CONTEXT=$(jq -sr '.[0].hookSpecificOutput.additionalContext' < "$RG_OUT_FILE")
}
rg_context_has() { printf '%s' "$RG_CONTEXT" | grep -qF -- "$1" || { echo "  [dbg] context=$(printf '%s' "$RG_CONTEXT" | head -c 400)"; fail "$2"; }; }
# reinject 의 `[요구 대조]` 줄들
rg_rq_lines() { printf '%s\n' "$HOOK_STDOUT" | grep -F '[요구 대조]' || true; }
rg_rq_line_with() { rg_rq_lines | grep -F -- "$1" || true; }   # <고정 문자열>
rg_count_lines() { if [ -z "$1" ]; then echo 0; else printf '%s\n' "$1" | grep -c . || true; fi; }

# ── state_reqcheck_paths 실행 ─────────────────────────────────────────────────
rg_paths() { # <state_dir> <sid> <task_path> → RG_P_OUT · RG_P_RC
  set +e
  RG_P_OUT=$(env HOME="$HOME_DIR" bash -c '. "$1" 2>/dev/null; state_reqcheck_paths "$2" "$3" "$4"' \
    _ "$HOOKS_DIR/state-lib.sh" "$1" "$2" "$3" 2>"$SANDBOX/paths.err")
  RG_P_RC=$?
  set -e
}
rg_paths_dbg() { echo "  [dbg] rc=$RG_P_RC out=$(printf '%s' "$RG_P_OUT" | tr '\n' '~' | head -c 400) err=$(head -c 200 "$SANDBOX/paths.err" 2>/dev/null)"; }
rg_assert_paths() { # <id> <want 줄...> — rc 0 · 출력이 그 줄들 그대로(차례 포함)
  local id=$1; shift
  local want; want=$(printf '%s\n' "$@")
  [ "$RG_P_RC" = 0 ] || { rg_paths_dbg; fail "$id-rc0"; }
  [ "$RG_P_OUT" = "$want" ] || { rg_paths_dbg; echo "  [dbg] want=$(printf '%s' "$want" | tr '\n' '~')"; fail "$id-lines"; }
}

# ── 기준 커밋(요구 대조 없음)과의 비교 ─────────────────────────────────────────────
rg_legacy_init() { # fixture 사본 → $RG_LEGACY_DIR (SCRIPT_DIR 기준 state-lib.sh source 가 사본끼리 맞물림)
  RG_LEGACY_DIR="$SANDBOX/legacy-rg"
  [ -d "$RG_LEGACY_DIR" ] && return 0
  mkdir -p "$RG_LEGACY_DIR"
  local name
  for name in gate-guard.sh reinject-mode.sh state-lib.sh; do
    [ -f "$RG_LEGACY_SOURCE/$name" ] || fail legacy-fixture-missing
    cp "$RG_LEGACY_SOURCE/$name" "$RG_LEGACY_DIR/$name"
  done
}
# 같은 시나리오를 기준 훅과 새 훅으로 각각 비운 상태 디렉토리에서 돌려, 종료 코드 · stdout · stderr · 상태파일 바이트를 견준다.
#   시나리오 = rg_prepare 의 이름(상태 · 사이드카 · log · RG_JSON 을 세운다).
rg_same_as_legacy() { # <hook 파일 이름> <시나리오 이름>
  local hook=$1 name=$2 capture="$SANDBOX/rg-capture"
  rg_legacy_init
  rg_clear_state_dir; rg_prepare "$name"
  rg_run "$RG_LEGACY_DIR/$hook" "$RG_JSON" "legacy-$name"
  if [ -f "$STATE" ]; then cp "$STATE" "$capture/legacy-$name.state"; else : > "$capture/legacy-$name.state"; fi
  printf '%s\n' "$HOOK_EXIT" > "$capture/legacy-$name.exit"
  rg_clear_state_dir; rg_prepare "$name"
  rg_run "$HOOKS_DIR/$hook" "$RG_JSON" "new-$name"
  if [ -f "$STATE" ]; then cp "$STATE" "$capture/new-$name.state"; else : > "$capture/new-$name.state"; fi
  printf '%s\n' "$HOOK_EXIT" > "$capture/new-$name.exit"
  local part
  for part in exit out err state; do
    cmp -s "$capture/legacy-$name.$part" "$capture/new-$name.$part" || {
      echo "  [dbg] $hook $name $part legacy=$(head -c 200 "$capture/legacy-$name.$part" | tr '\n' '~') new=$(head -c 200 "$capture/new-$name.$part" | tr '\n' '~')"
      fail "same-as-legacy-$name-$part"; }
  done
}
# 시나리오 — 폴더 이름은 고정(두 실행이 같은 경로를 쓰게). log 는 저장소 안이라 상태 디렉토리를 비워도 남는다(다시 써도 같다).
rg_prepare() { # <이름> → RG_JSON
  local f1 f2 gone
  f1=$(rg_folder f1); f2=$(rg_folder f2); gone=$(realpath -m -- "$REPO/docs/plans/2026-11-01/gone")
  rg_standing
  case "$1" in
    # 표지가 있는 log 가 하나도 없다(gate-guard · reinject 공용)
    no-taskpath-no-sidecar)   rg_state auto 0 0 1 -;    RG_JSON=$(rg_json PreToolUse Write "$REPO/$RG_L1") ;;
    taskpath-no-marker)       rg_log_no_marker "$f1"; rg_state auto 0 0 1 "$f1"; RG_JSON=$(rg_json PreToolUse Write "$REPO/$RG_L1") ;;
    taskpath-no-log)          rm -f "$f1/log.md"; rg_state auto 0 0 1 "$f1"; RG_JSON=$(rg_json PreToolUse Write "$REPO/$RG_L1") ;;
    template-as-is)           rg_log_template "$f1"; rg_state auto 0 0 1 "$f1"; RG_JSON=$(rg_json PreToolUse Write "$REPO/$RG_L1") ;;
    filled-table)             rg_log_filled "$f1"; rg_state auto 0 0 1 "$f1"; RG_JSON=$(rg_json PreToolUse Write "$REPO/$RG_L1") ;;
    sidecar-gone-folder)      rg_log_no_marker "$f1"; rm -f "$f2/log.md"; rg_state auto 0 0 1 "$f1"
                              rg_sidecar "$gone" "$f2"; RG_JSON=$(rg_json PreToolUse Write "$REPO/$RG_L1") ;;
    sidecar-empty-file)       rg_log_no_marker "$f1"; rg_state auto 0 0 1 "$f1"; rg_sidecar_raw ''
                              RG_JSON=$(rg_json PreToolUse Write "$REPO/$RG_L1") ;;
    # 위반 없고 열린 빈 칸만 — 메인(구현 주체 알림이 함께 나오는 첫 쓰기) · 워커 · lazy · 긴급
    open-only-auto-main)      rg_log_open_only "$f1"; rg_state auto 0 0 1 "$f1"; RG_JSON=$(rg_json PreToolUse Write "$REPO/$RG_L1") ;;
    open-only-auto-worker)    rg_log_open_only "$f1"; rg_state auto 0 0 1 "$f1"; RG_JSON=$(rg_json PreToolUse Edit "$REPO/$RG_L1" agent-7) ;;
    open-only-lazy)           rg_log_open_only "$f1"; rg_state lazy 0 0 1 "$f1"; RG_JSON=$(rg_json PreToolUse MultiEdit "$REPO/$RG_L1") ;;
    open-only-debt)           rg_log_open_only "$f1"; rg_state auto 0 1 1 "$f1"; RG_JSON=$(rg_json PreToolUse Write "$REPO/$RG_L1") ;;
    open-only-sidecar)        rg_log_no_marker "$f1"; rg_log_open_only "$f2"; rg_state auto 0 0 1 "$f1"; rg_sidecar "$f2"
                              RG_JSON=$(rg_json PreToolUse Write "$REPO/$RG_L1") ;;
    # 위반이 있어도 이 길은 종전 그대로(PostToolUse · Bash · L0 · SPEC=0 · MODE=UNSET · 상태파일 거부 · 고정 지시 ask)
    violation-auto-post)      rg_log_violation "$f1" T01; rg_state auto 0 0 1 "$f1"; RG_JSON=$(rg_json PostToolUse Write "$REPO/$RG_L1") ;;
    violation-lazy-post)      rg_log_violation "$f1" T01; rg_state lazy 0 0 1 "$f1"; RG_JSON=$(rg_json PostToolUse Edit "$REPO/$RG_L1") ;;
    violation-auto-bash)      rg_log_violation "$f1" T01; rg_state auto 0 0 1 "$f1"; RG_JSON=$(json_bash "sed -i 's/a/b/' $RG_L1") ;;
    violation-lazy-bash)      rg_log_violation "$f1" T01; rg_state lazy 0 0 1 "$f1"; RG_JSON=$(json_bash "sed -i 's/a/b/' $RG_L1") ;;
    violation-edit-log)       rg_log_violation "$f1" T01; rg_state auto 0 0 1 "$f1"; RG_JSON=$(rg_json PreToolUse Edit "$f1/log.md") ;;
    violation-write-log)      rg_log_violation "$f1" T01; rg_state lazy 1 0 1 "$f1"; RG_JSON=$(rg_json PreToolUse Write "$f1/log.md") ;;
    violation-worker-edit-log) rg_log_violation "$f1" T01; rg_state auto 0 0 1 "$f1"; RG_JSON=$(rg_json PreToolUse MultiEdit "$f1/log.md" agent-3) ;;
    violation-sidecar-edit-log) rg_log_no_marker "$f1"; rg_log_violation "$f2" T02; rg_state auto 0 0 1 "$f1"; rg_sidecar "$f2"
                              RG_JSON=$(rg_json PreToolUse Edit "$f2/log.md") ;;
    violation-spec0)          rg_log_violation "$f1" T01; rg_state UNSET 0 0 0 "$f1"; RG_JSON=$(rg_json PreToolUse Write "$REPO/$RG_L1") ;;
    violation-spec0-auto)     rg_log_violation "$f1" T01; rg_state auto 0 0 0 "$f1"; RG_JSON=$(rg_json PreToolUse Write "$REPO/$RG_L1") ;;
    violation-mode-unset)     rg_log_violation "$f1" T01; rg_state UNSET 0 0 1 "$f1"; RG_JSON=$(rg_json PreToolUse Write "$REPO/$RG_L1") ;;
    violation-state-file)     rg_log_violation "$f1" T01; rg_state auto 0 0 1 "$f1"; RG_JSON=$(rg_json PreToolUse Edit "$STATE") ;;
    violation-standing-ask)   rg_log_violation "$f1" T01; rg_state auto 0 0 1 "$f1"
                              RG_JSON=$(rg_json PreToolUse Edit "$HOME_DIR/.claude/standing-instructions.md") ;;
    # reinject 전용(입력은 UserPromptSubmit)
    prompt-no-taskpath)       rg_state auto 0 0 1 -; RG_JSON=$(json_prompt '다음 할 일') ;;
    prompt-no-marker)         rg_log_no_marker "$f1"; rg_state auto 0 0 1 "$f1"; RG_JSON=$(json_prompt '다음 할 일') ;;
    prompt-filled)            rg_log_filled "$f1"; rg_state lazy 1 0 1 "$f1"; RG_JSON=$(json_prompt '다음 할 일') ;;
    prompt-template)          rg_log_template "$f1"; rg_state auto 0 0 1 "$f1"; RG_JSON=$(json_prompt '다음 할 일') ;;
    prompt-gone-folder)       rg_log_filled "$f1"; rm -f "$f2/log.md"; rg_state auto 0 0 1 "$f1"; rg_sidecar "$gone" "$f2"
                              RG_JSON=$(json_prompt '다음 할 일') ;;
    prompt-debt-filled)       rg_log_filled "$f1"; rg_state auto 0 1 1 "$f1"; RG_JSON=$(json_prompt '다음 할 일') ;;
    prompt-unset-no-marker)   rg_log_no_marker "$f1"; rg_state UNSET 0 0 0 "$f1"; RG_JSON=$(json_prompt '다음 할 일') ;;
    *) fail "unknown-scenario-$1" ;;
  esac
}

# ══ A · state_reqcheck_paths <state_dir> <sid> <task_path> ═══════════════════════════════

test_rg_a01_task_path_only_gives_its_log() { # [A] TASK_PATH 만 · 사이드카 없음 → `<task_path>/log.md` 한 줄 · rc 0
  local f1; f1=$(rg_folder f1)
  rg_paths "$STATE_DIR" "$SID" "$f1"
  rg_assert_paths a01 "$f1/log.md"
}

test_rg_a02_task_path_first_then_sidecar_lines_in_order() { # [A] TASK_PATH 의 log 먼저, 그다음 사이드카 줄의 차례대로
  local f1 f2 f3; f1=$(rg_folder f1); f2=$(rg_folder f2); f3=$(rg_folder f3)
  rg_sidecar "$f3" "$f2"
  rg_paths "$STATE_DIR" "$SID" "$f1"
  rg_assert_paths a02 "$f1/log.md" "$f3/log.md" "$f2/log.md"
}

test_rg_a03_duplicates_keep_first_occurrence_only() { # [A] TASK_PATH 와 같은 줄 · 사이드카 안의 반복 줄 → 처음 것만
  local f1 f2; f1=$(rg_folder f1); f2=$(rg_folder f2)
  rg_sidecar "$f2" "$f1" "$f2" "$f1"
  rg_paths "$STATE_DIR" "$SID" "$f1"
  rg_assert_paths a03 "$f1/log.md" "$f2/log.md"
}

test_rg_a04_blank_lines_skipped_and_last_line_without_newline_read() { # [A] 빈 줄은 건너뛰고 · 끝 개행 없는 마지막 줄도 읽는다
  local f2 f3; f2=$(rg_folder f2); f3=$(rg_folder f3)
  rg_sidecar_raw "$(printf '\n%s\n\n\n%s' "$f2" "$f3")"
  [ -n "$(tail -c 1 "$(rg_sidecar_path)")" ] || fail a04-fixture-no-trailing-newline
  rg_paths "$STATE_DIR" "$SID" ""
  rg_assert_paths a04 "$f2/log.md" "$f3/log.md"
}

test_rg_a05_empty_task_path_reads_only_sidecar() { # [A] task_path 가 비면 사이드카 줄만
  local f2; f2=$(rg_folder f2)
  rg_sidecar "$f2"
  rg_paths "$STATE_DIR" "$SID" ""
  rg_assert_paths a05 "$f2/log.md"
}

test_rg_a06_nothing_gives_no_output_rc0() { # [A] task_path 가 비고 사이드카도 없으면 출력 없음 · rc 0
  rg_paths "$STATE_DIR" "$SID" ""
  [ "$RG_P_RC" = 0 ] || { rg_paths_dbg; fail a06-rc0; }
  [ -z "$RG_P_OUT" ] || { rg_paths_dbg; fail a06-empty; }
}

test_rg_a07_path_with_spaces_is_kept_whole() { # [A] 경로에 공백이 있어도 한 줄 그대로(TASK_PATH · 사이드카 모두)
  local f1 f2; f1=$(rg_folder 'with space'); f2=$(rg_folder 'side car dir')
  rg_sidecar "$f2"
  rg_paths "$STATE_DIR" "$SID" "$f1"
  rg_assert_paths a07 "$f1/log.md" "$f2/log.md"
}

test_rg_a08_symlinked_sidecar_is_rc1_with_sidecar_path() { # [A] 사이드카가 심링크면(가리키는 파일이 맞아도) rc 1 · stdout = 사이드카 경로 한 줄
  local f1 f2; f1=$(rg_folder f1); f2=$(rg_folder f2)
  printf '%s\n' "$f2" > "$SANDBOX/real-paths"
  ln -s "$SANDBOX/real-paths" "$(rg_sidecar_path)"
  rg_paths "$STATE_DIR" "$SID" "$f1"
  [ "$RG_P_RC" = 1 ] || { rg_paths_dbg; fail a08-rc1; }
  [ "$RG_P_OUT" = "$(rg_sidecar_path)" ] || { rg_paths_dbg; fail a08-stdout-sidecar-path; }
}

test_rg_a09_non_regular_sidecar_is_rc1_with_sidecar_path() { # [A] 사이드카가 디렉토리(정규 파일 아님)면 rc 1 · stdout = 사이드카 경로
  local f1; f1=$(rg_folder f1)
  mkdir -p "$(rg_sidecar_path)"
  rg_paths "$STATE_DIR" "$SID" "$f1"
  [ "$RG_P_RC" = 1 ] || { rg_paths_dbg; fail a09-rc1; }
  [ "$RG_P_OUT" = "$(rg_sidecar_path)" ] || { rg_paths_dbg; fail a09-stdout-sidecar-path; }
}

test_rg_a10_unreadable_sidecar_is_rc1_with_sidecar_path() { # [A] 읽기 권한 없는 사이드카 → rc 1 · stdout = 사이드카 경로
  [ "$(id -u)" != "0" ] || skip_test root-reads-anything
  local f1 f2; f1=$(rg_folder f1); f2=$(rg_folder f2)
  rg_sidecar "$f2"
  chmod 000 "$(rg_sidecar_path)"
  rg_paths "$STATE_DIR" "$SID" "$f1"
  chmod 600 "$(rg_sidecar_path)"
  [ "$RG_P_RC" = 1 ] || { rg_paths_dbg; fail a10-rc1; }
  [ "$RG_P_OUT" = "$(rg_sidecar_path)" ] || { rg_paths_dbg; fail a10-stdout-sidecar-path; }
}

test_rg_a11_relative_line_is_rc1_not_skipped() { # [A] 절대 경로가 아닌 줄이 있으면 rc 1(손상 — 조용히 건너뛰지 않는다)
  local f1 f2; f1=$(rg_folder f1); f2=$(rg_folder f2)
  rg_sidecar "$f2" 'docs/plans/2026-11-27/f3'
  rg_paths "$STATE_DIR" "$SID" "$f1"
  [ "$RG_P_RC" = 1 ] || { rg_paths_dbg; fail a11-rc1; }
  printf '%s' "$RG_P_OUT" | grep -qF -- "$(rg_sidecar_path)" || { rg_paths_dbg; fail a11-stdout-names-sidecar; }
}

test_rg_a12_sidecar_of_other_session_is_not_read() { # [A] 사이드카 이름은 <sid>.req-check-paths — 다른 세션의 것은 읽지 않는다
  local f1 f2; f1=$(rg_folder f1); f2=$(rg_folder f2)
  printf '%s\n' "$f2" > "$STATE_DIR/other-session$RG_SIDECAR_NAME_SUFFIX"
  rg_paths "$STATE_DIR" "$SID" "$f1"
  rg_assert_paths a12 "$f1/log.md"
}

# ══ B · gate-guard (PreToolUse L1 쓰기) ═══════════════════════════════════════════════

test_rg_b01_closed_blank_in_task_path_log_blocks_l1_write() { # [B] TASK_PATH log 의 닫음 빈 칸 → Write 막힘(exit 2) · task · 행 · 경로 · 푸는 길
  local f1; f1=$(rg_folder f1)
  rg_log_violation "$f1" T01; rg_state auto 0 0 1 "$f1"
  rg_l1 Write
  rg_assert_reqcheck_block b01
  rg_assert_violation_reported T01 "$RG_VLINE" "$f1/log.md" b01
}

test_rg_b02_edit_and_multiedit_are_blocked_too() { # [B] Edit · MultiEdit 도 같다
  local f1 tool; f1=$(rg_folder f1)
  rg_log_violation "$f1" T01; rg_state auto 0 0 1 "$f1"
  for tool in Edit MultiEdit; do
    rg_l1 "$tool"
    rg_assert_reqcheck_block "b02-$tool"
    rg_assert_violation_reported T01 "$RG_VLINE" "$f1/log.md" "b02-$tool"
  done
}

test_rg_b03_worker_write_is_blocked_too() { # [B] 워커(agent_id 있음)도 막는다(내용 판정)
  local f1; f1=$(rg_folder f1)
  rg_log_violation "$f1" T01; rg_state auto 0 0 1 "$f1"
  rg_l1 Write agent-42
  rg_assert_reqcheck_block b03
  rg_assert_violation_reported T01 "$RG_VLINE" "$f1/log.md" b03
}

test_rg_b04_lazy_mode_is_blocked_too() { # [B] lazy(PENDING_GATE=0)도 막는다 · 막힌 쓰기는 PENDING_GATE 를 세우지 않는다
  local f1; f1=$(rg_folder f1)
  rg_log_violation "$f1" T01; rg_state lazy 0 0 1 "$f1"
  rg_l1 Edit
  rg_assert_reqcheck_block b04
  rg_assert_violation_reported T01 "$RG_VLINE" "$f1/log.md" b04
  assert_state PENDING_GATE 0 b04-pending-unchanged
}

test_rg_b05_lazy_pending_is_blocked_by_reqcheck_first() { # [B] lazy · PENDING_GATE=1 · 위반 → 요구 대조가 PENDING 판정보다 앞(그 메시지로 막힌다)
  local f1; f1=$(rg_folder f1)
  rg_log_violation "$f1" T01; rg_state lazy 1 0 1 "$f1"
  rg_l1 Write
  rg_assert_reqcheck_block b05
  rg_assert_violation_reported T01 "$RG_VLINE" "$f1/log.md" b05
  rg_err_lacks '이해 게이트가 미처리' b05-not-pending-message
}

test_rg_b06_bad_header_blocks_with_reason_path_and_expected_header() { # [B] 판정 불가(머리 줄) → 막힘 · 까닭 · 경로 · 기대하는 머리 줄 글자
  local f1; f1=$(rg_folder f1)
  rg_log_bad_header "$f1"; rg_state auto 0 0 1 "$f1"
  rg_l1 Write
  rg_assert_reqcheck_block b06
  rg_err_has '머리 줄' b06-reason
  rg_err_has_number "$RG_HLINE" b06-reason-line
  rg_err_has "$f1/log.md" b06-path
  rg_err_has "$RG_HEAD" b06-expected-header
}

test_rg_b07_bad_status_blocks_with_reason_value() { # [B] 판정 불가(상태 값 닫힘) → 막힘 · 까닭에 그 값 · 경로
  local f1; f1=$(rg_folder f1)
  rg_log_table "$f1" 0 '| T01 | 규약 §1 | 요구-가 | hooks/a.sh:1 | 닫힘 |'
  rg_state auto 0 0 1 "$f1"
  rg_l1 Write
  rg_assert_reqcheck_block b07
  rg_err_has '닫힘' b07-reason-value
  rg_err_has "$f1/log.md" b07-path
}

test_rg_b08_violation_in_second_sidecar_folder_blocks() { # [B] 여러 폴더 중 사이드카 둘째 폴더의 위반도 막는다(TASK_PATH 는 표지 없음 · 첫째는 채움)
  local f1 f0 f2; f1=$(rg_folder f1); f0=$(rg_folder f0); f2=$(rg_folder f2)
  rg_log_no_marker "$f1"; rg_log_filled "$f0"; rg_log_violation "$f2" T05 7
  rg_state auto 0 0 1 "$f1"; rg_sidecar "$f0" "$f2"
  rg_l1 Write
  rg_assert_reqcheck_block b08
  rg_assert_violation_reported T05 "$RG_VLINE" "$f2/log.md" b08
}

test_rg_b09_violations_in_every_folder_are_all_reported() { # [B] 위반마다 — TASK_PATH 와 사이드카 폴더의 위반이 모두 보인다
  local f1 f2 line1; f1=$(rg_folder f1); f2=$(rg_folder f2)
  rg_log_violation "$f1" T01; line1=$RG_VLINE
  rg_log_violation "$f2" T02 5
  rg_state auto 0 0 1 "$f1"; rg_sidecar "$f2"
  rg_l1 Write
  rg_assert_reqcheck_block b09
  rg_assert_violation_reported T01 "$line1" "$f1/log.md" b09-first
  rg_assert_violation_reported T02 "$RG_VLINE" "$f2/log.md" b09-second
}

test_rg_b10_same_folder_in_task_path_and_sidecar_reported_once() { # [B] 같은 폴더가 TASK_PATH 와 사이드카에 둘 다 → 한 번만(사이드카 없을 때와 stderr 바이트가 같다)
  local f1 once twice; f1=$(rg_folder f1)
  rg_log_violation "$f1" T01; rg_state auto 0 0 1 "$f1"
  RG_TAG=once rg_l1 Write
  rg_assert_reqcheck_block b10-once
  rg_assert_violation_reported T01 "$RG_VLINE" "$f1/log.md" b10-once
  once=$HOOK_STDERR
  rg_sidecar "$f1" "$f1"
  RG_TAG=twice rg_l1 Write
  rg_assert_reqcheck_block b10-twice
  twice=$HOOK_STDERR
  [ "$once" = "$twice" ] || { echo "  [dbg] once=$(printf '%s' "$once" | head -c 300)"; echo "  [dbg] twice=$(printf '%s' "$twice" | head -c 300)"; fail b10-same-stderr; }
}

test_rg_b11_blank_lines_no_trailing_newline_spaced_path_in_sidecar() { # [B] 사이드카의 빈 줄 · 끝 개행 없음 · 공백 든 경로 — 마지막 줄 폴더의 위반을 막는다
  local f1 gone fs; f1=$(rg_folder f1); fs=$(rg_folder 'with space dir')
  gone=$(realpath -m -- "$REPO/docs/plans/2026-11-01/gone")
  rg_log_filled "$f1"; rg_log_violation "$fs" T03 3
  rg_state auto 0 0 1 "$f1"
  rg_sidecar_raw "$(printf '\n%s\n\n%s' "$gone" "$fs")"
  rg_l1 Write
  rg_assert_reqcheck_block b11
  rg_assert_violation_reported T03 "$RG_VLINE" "$fs/log.md" b11
}

test_rg_b12_symlinked_sidecar_blocks_and_still_shows_task_path_violation() { # [B] 사이드카 rc 1 → 판정 불가로 막는다 · TASK_PATH log 의 위반도 함께 보인다
  local f1 f2; f1=$(rg_folder f1); f2=$(rg_folder f2)
  rg_log_violation "$f1" T04; rg_log_filled "$f2"
  rg_state auto 0 0 1 "$f1"
  printf '%s\n' "$f2" > "$SANDBOX/real-paths"; ln -s "$SANDBOX/real-paths" "$(rg_sidecar_path)"
  rg_l1 Write
  rg_assert_reqcheck_block b12
  rg_err_has "$(rg_sidecar_path)" b12-sidecar-path
  rg_assert_violation_reported T04 "$RG_VLINE" "$f1/log.md" b12
}

test_rg_b13_broken_sidecar_blocks_even_without_any_marked_log() { # [B] 사이드카 rc 1(심링크 · 상대 경로 줄)이면 TASK_PATH 에 표가 없어도 막는다
  local f1 f2; f1=$(rg_folder f1); f2=$(rg_folder f2)
  rg_log_no_marker "$f1"; rg_state auto 0 0 1 "$f1"
  printf '%s\n' "$f2" > "$SANDBOX/real-paths"; ln -s "$SANDBOX/real-paths" "$(rg_sidecar_path)"
  rg_l1 Write
  rg_assert_exit 2 b13-symlink-exit2
  rg_err_has '요구 대조' b13-symlink-word
  rg_err_has "$(rg_sidecar_path)" b13-symlink-sidecar-path
  rm -f "$(rg_sidecar_path)"
  rg_sidecar "$f2" 'docs/plans/2026-11-27/f3'
  rg_l1 Write
  rg_assert_exit 2 b13-relative-exit2
  rg_err_has '요구 대조' b13-relative-word
}

test_rg_b14_unreadable_marked_log_blocks() { # [B] log.md 를 읽을 수 없으면(파서 rc 1) 판정 불가로 막는다 · 경로
  [ "$(id -u)" != "0" ] || skip_test root-reads-anything
  local f1; f1=$(rg_folder f1)
  rg_log_filled "$f1"; rg_state auto 0 0 1 "$f1"
  chmod 000 "$f1/log.md"
  rg_l1 Write
  chmod 600 "$f1/log.md"
  rg_assert_exit 2 b14-exit2
  rg_err_has '요구 대조' b14-word
  rg_err_has "$f1/log.md" b14-path
}

test_rg_b15_gone_folder_and_unmarked_logs_do_not_block() { # [B] 사라진 폴더 줄 · log 없는 폴더 · 표지 없는 log(닫음 빈 칸이 있어도) → 막지 않는다
  local f1 f2 gone; f1=$(rg_folder f1); f2=$(rg_folder f2)
  gone=$(realpath -m -- "$REPO/docs/plans/2026-11-01/gone")
  rg_log_no_marker "$f1"; rm -f "$f2/log.md"
  rg_state auto 0 0 1 "$f1"; rg_sidecar "$gone" "$f2"
  rg_l1 Write agent-1
  rg_assert_exit 0 b15-exit0
  rg_err_lacks '요구 대조' b15-no-word
}

test_rg_b16_debt_violation_passes_with_one_context_json() { # [B] DEBT=1 · 위반 → exit 0 · stdout = JSON 한 덩어리(같은 정보 + 생략한 검증) · 메인이어도 알림 JSON 이 겹치지 않는다
  local f1; f1=$(rg_folder f1)
  rg_log_violation "$f1" T01; rg_state auto 0 1 1 "$f1"
  rg_l1 Write
  rg_assert_exit 0 b16-exit0
  rg_assert_single_context_json b16
  rg_context_has '요구 대조' b16-word
  rg_context_has '생략한 검증' b16-debt-word
  rg_context_has T01 b16-task
  rg_context_has "$f1/log.md" b16-path
  rg_text_has_number "$RG_CONTEXT" "$RG_VLINE" || { echo "  [dbg] context=$RG_CONTEXT"; fail b16-line; }
}

test_rg_b17_debt_worker_and_lazy_pass_with_one_context_json() { # [B] DEBT=1 · 워커 · lazy 도 exit 0 · JSON 한 덩어리
  local f1; f1=$(rg_folder f1)
  rg_log_violation "$f1" T01
  rg_state auto 0 1 1 "$f1"
  rg_l1 Edit agent-5
  rg_assert_exit 0 b17-worker-exit0
  rg_assert_single_context_json b17-worker
  rg_context_has '생략한 검증' b17-worker-debt-word
  rg_state lazy 0 1 1 "$f1"
  rg_l1 MultiEdit
  rg_assert_exit 0 b17-lazy-exit0
  rg_assert_single_context_json b17-lazy
  rg_context_has '요구 대조' b17-lazy-word
}

test_rg_b18_debt_undecidable_passes_with_reason_in_context() { # [B] DEBT=1 · 판정 불가(머리 줄) → exit 0 · JSON 한 덩어리에 까닭 · 경로 · 기대 머리 줄
  local f1; f1=$(rg_folder f1)
  rg_log_bad_header "$f1"; rg_state auto 0 1 1 "$f1"
  rg_l1 Write
  rg_assert_exit 0 b18-exit0
  rg_assert_single_context_json b18
  rg_context_has '요구 대조' b18-word
  rg_context_has '생략한 검증' b18-debt-word
  rg_context_has '머리 줄' b18-reason
  rg_context_has "$f1/log.md" b18-path
  rg_context_has "$RG_HEAD" b18-expected-header
}

test_rg_b19_no_marked_log_output_same_as_legacy() { # [B] 표지 있는 log 가 하나도 없다 → 종전과 바이트까지 같다(exit · stdout · stderr · 상태)
  local name
  for name in no-taskpath-no-sidecar taskpath-no-marker taskpath-no-log template-as-is filled-table \
              sidecar-gone-folder sidecar-empty-file; do
    rg_same_as_legacy gate-guard.sh "$name"
  done
}

test_rg_b20_open_blanks_only_output_same_as_legacy() { # [B] 위반 없고 열린 빈 칸만 → 종전과 같다(메인 첫 쓰기의 구현 주체 알림 · 워커 · lazy · 긴급 · 사이드카 폴더)
  local name
  for name in open-only-auto-main open-only-auto-worker open-only-lazy open-only-debt open-only-sidecar; do
    rg_same_as_legacy gate-guard.sh "$name"
  done
}

test_rg_b21_post_and_bash_unchanged_with_violation() { # [B] 위반이 있어도 PostToolUse · Bash 도구는 종전과 같다
  local name
  for name in violation-auto-post violation-lazy-post violation-auto-bash violation-lazy-bash; do
    rg_same_as_legacy gate-guard.sh "$name"
  done
}

test_rg_b22_writing_log_md_itself_passes_with_violation() { # [B] L0 쓰기(log.md 자체 — Edit · Write · 워커 MultiEdit · 사이드카 폴더의 log)는 위반이 있어도 통과 · 종전과 같다
  local name
  for name in violation-edit-log violation-write-log violation-worker-edit-log violation-sidecar-edit-log; do
    rg_same_as_legacy gate-guard.sh "$name"
    rg_assert_exit 0 "b22-$name-exit0"
  done
}

test_rg_b23_spec_and_mode_gates_unchanged_with_violation() { # [B] SPEC=0 · MODE=UNSET 은 종전 메시지 그대로(요구 대조 메시지가 섞이지 않는다)
  local name
  for name in violation-spec0 violation-spec0-auto violation-mode-unset; do
    rg_same_as_legacy gate-guard.sh "$name"
    rg_err_lacks '요구 대조' "b23-$name-no-reqcheck"
  done
}

test_rg_b24_state_file_refusal_and_standing_ask_unchanged_with_violation() { # [B] 상태파일 거부 · 고정 지시 ask 는 위반이 있어도 종전과 같다
  local name
  for name in violation-state-file violation-standing-ask; do
    rg_same_as_legacy gate-guard.sh "$name"
  done
}

test_rg_b25_filling_the_cell_unblocks() { # [B] 푸는 길 — 그 줄의 넷째 칸을 채우거나 상태를 열림으로 되돌리면 다시 통과한다
  local f1; f1=$(rg_folder f1)
  rg_log_violation "$f1" T01; rg_state auto 0 0 1 "$f1"
  rg_l1 Write agent-2
  rg_assert_exit 2 b25-blocked
  sed -i 's/| 요구-닫음-빈칸-T01 | | 닫음 |/| 요구-닫음-빈칸-T01 | hooks\/b.sh:9 | 닫음 |/' "$f1/log.md"
  grep -qF 'hooks/b.sh:9' "$f1/log.md" || fail b25-fixture-filled
  rg_l1 Write agent-2
  rg_assert_exit 0 b25-filled-passes
  rg_log_violation "$f1" T01
  sed -i 's/| 요구-닫음-빈칸-T01 | | 닫음 |/| 요구-닫음-빈칸-T01 | | 열림 |/' "$f1/log.md"
  grep -qF '| 요구-닫음-빈칸-T01 | | 열림 |' "$f1/log.md" || fail b25-fixture-reopened
  rg_l1 Write agent-2
  rg_assert_exit 0 b25-reopened-passes
}

# ══ C · reinject-mode (UserPromptSubmit — stdout 이 맥락) ══════════════════════════════════

test_rg_c01_violation_gives_one_line_with_tasks_and_lines() { # [C] 위반 → `[요구 대조]` · 닫음 · 빈 칸 · task 와 행이 든 한 줄(여러 폴더를 모아)
  local f1 f2 line1 line; f1=$(rg_folder f1); f2=$(rg_folder f2)
  rg_log_violation "$f1" T01; line1=$RG_VLINE
  rg_log_violation "$f2" T02 6
  rg_state auto 0 0 1 "$f1"; rg_sidecar "$f2"
  rg_reinject
  rg_assert_exit 0 c01-exit0
  line=$(rg_rq_line_with '닫음')
  [ "$(rg_count_lines "$line")" = 1 ] || { rg_dbg; fail c01-one-line; }
  case "$line" in '[요구 대조]'*) ;; *) rg_dbg; fail c01-prefix ;; esac
  printf '%s' "$line" | grep -qF '빈 칸' || { rg_dbg; fail c01-blank-word; }
  printf '%s' "$line" | grep -qF T01 || { rg_dbg; fail c01-task1; }
  printf '%s' "$line" | grep -qF T02 || { rg_dbg; fail c01-task2; }
  rg_text_has_number "$line" "$line1" || { rg_dbg; fail c01-line1; }
  rg_text_has_number "$line" "$RG_VLINE" || { rg_dbg; fail c01-line2; }
}

test_rg_c02_open_blanks_one_line_task_blank_over_rows_across_folders() { # [C] 열린 빈 칸 → 한 줄 `[요구 대조] 열린 빈 칸 — T01 1/2 · T02 3/5`(폴더를 모아 · 처음 나온 차례)
  local f1 f2 line; f1=$(rg_folder f1); f2=$(rg_folder f2)
  rg_log_table "$f1" 0 '| T01 | 규약 §1 | 요구-가 | hooks/a.sh:1 | 닫음 |' '| T01 | 규약 §2 | 요구-나 | | 열림 |'
  rg_log_table "$f2" 0 \
    '| T02 | 규약 §1 | 요구-1 | | 열림 |' '| T02 | 규약 §2 | 요구-2 | - | 열림 |' '| T02 | 규약 §3 | 요구-3 | ? | 열림 |' \
    '| T02 | 규약 §4 | 요구-4 | hooks/b.sh:4 | 열림 |' '| T02 | 규약 §5 | 요구-5 | abc1234 | 닫음 |'
  rg_state auto 0 0 1 "$f1"; rg_sidecar "$f2"
  rg_reinject
  rg_assert_exit 0 c02-exit0
  line=$(rg_rq_line_with '열린 빈 칸')
  [ "$(rg_count_lines "$line")" = 1 ] || { rg_dbg; fail c02-one-line; }
  case "$line" in '[요구 대조] 열린 빈 칸'*) ;; *) rg_dbg; fail c02-prefix ;; esac
  printf '%s' "$line" | grep -qE '(^|[^0-9A-Za-z])T01 1/2([^0-9]|$)' || { rg_dbg; fail c02-t01-1-of-2; }
  printf '%s' "$line" | grep -qE '(^|[^0-9A-Za-z])T02 3/5([^0-9]|$)' || { rg_dbg; fail c02-t02-3-of-5; }
  printf '%s' "$line" | grep -qE 'T01 1/2.*T02 3/5' || { rg_dbg; fail c02-order; }
  [ -z "$(rg_rq_line_with '닫음')" ] || { rg_dbg; fail c02-no-violation-line; }
}

test_rg_c03_open_blanks_show_five_tasks_then_rest_count() { # [C] 열린 빈 칸 task 가 다섯 넘으면 다섯까지 + ` 외 N`
  local f1 line number; f1=$(rg_folder f1)
  local -a rows=()
  for number in 1 2 3 4 5 6 7; do rows+=("| T0$number | 규약 §$number | 요구-$number | | 열림 |"); done
  rg_log_table "$f1" 0 "${rows[@]}"
  rg_state auto 0 0 1 "$f1"
  rg_reinject
  line=$(rg_rq_line_with '열린 빈 칸')
  [ "$(rg_count_lines "$line")" = 1 ] || { rg_dbg; fail c03-one-line; }
  for number in 1 2 3 4 5; do
    printf '%s' "$line" | grep -qF "T0$number 1/1" || { rg_dbg; fail "c03-t0$number-shown"; }
  done
  for number in 6 7; do
    if printf '%s' "$line" | grep -qF "T0$number"; then rg_dbg; fail "c03-t0$number-hidden"; fi
  done
  printf '%s' "$line" | grep -qF ' 외 2' || { rg_dbg; fail c03-rest-count; }
}

test_rg_c04_exactly_five_tasks_have_no_rest_count() { # [C] 경계: 열린 빈 칸 task 가 다섯이면 ` 외` 가 붙지 않는다
  local f1 line number; f1=$(rg_folder f1)
  local -a rows=()
  for number in 1 2 3 4 5; do rows+=("| T0$number | 규약 §$number | 요구-$number | | 열림 |"); done
  rg_log_table "$f1" 0 "${rows[@]}"
  rg_state auto 0 0 1 "$f1"
  rg_reinject
  line=$(rg_rq_line_with '열린 빈 칸')
  printf '%s' "$line" | grep -qF 'T05 1/1' || { rg_dbg; fail c04-t05-shown; }
  if printf '%s' "$line" | grep -qF ' 외 '; then rg_dbg; fail c04-no-rest; fi
}

test_rg_c05_violation_line_comes_before_open_line() { # [C] 위반 줄과 열린 빈 칸 줄이 둘 다면 각 한 줄 · 위반 줄이 앞
  local f1 violation_number open_number; f1=$(rg_folder f1)
  rg_log_table "$f1" 0 '| T01 | 규약 §2 | 요구-나 | | 열림 |' '| T02 | 규약 §1 | 요구-가 | | 닫음 |'
  rg_state auto 0 0 1 "$f1"
  rg_reinject
  [ "$(rg_count_lines "$(rg_rq_line_with '닫음')")" = 1 ] || { rg_dbg; fail c05-one-violation-line; }
  [ "$(rg_count_lines "$(rg_rq_line_with '열린 빈 칸')")" = 1 ] || { rg_dbg; fail c05-one-open-line; }
  violation_number=$(printf '%s\n' "$HOOK_STDOUT" | grep -nF '[요구 대조]' | grep -F '닫음' | head -1 | cut -d: -f1)
  open_number=$(printf '%s\n' "$HOOK_STDOUT" | grep -nF '[요구 대조]' | grep -F '열린 빈 칸' | head -1 | cut -d: -f1)
  { [ -n "$violation_number" ] && [ -n "$open_number" ] && [ "$violation_number" -lt "$open_number" ]; } || { rg_dbg; fail c05-violation-first; }
}

test_rg_c06_undecidable_gives_one_line_with_reason() { # [C] 판정 불가(머리 줄) → 한 줄 `[요구 대조] … 판정 불가 — <까닭>`
  local f1 line; f1=$(rg_folder f1)
  rg_log_bad_header "$f1"; rg_state auto 0 0 1 "$f1"
  rg_reinject
  rg_assert_exit 0 c06-exit0
  line=$(rg_rq_line_with '판정 불가')
  [ "$(rg_count_lines "$line")" = 1 ] || { rg_dbg; fail c06-one-line; }
  case "$line" in '[요구 대조]'*) ;; *) rg_dbg; fail c06-prefix ;; esac
  printf '%s' "$line" | grep -qF '머리 줄' || { rg_dbg; fail c06-reason; }
}

test_rg_c07_broken_sidecar_gives_undecidable_line() { # [C] 사이드카 rc 1(심링크) → 판정 불가 한 줄(까닭 = 사이드카 경로)
  local f1 f2 line; f1=$(rg_folder f1); f2=$(rg_folder f2)
  rg_log_filled "$f1"; rg_state auto 0 0 1 "$f1"
  printf '%s\n' "$f2" > "$SANDBOX/real-paths"; ln -s "$SANDBOX/real-paths" "$(rg_sidecar_path)"
  rg_reinject
  rg_assert_exit 0 c07-exit0
  line=$(rg_rq_line_with '판정 불가')
  [ "$(rg_count_lines "$line")" = 1 ] || { rg_dbg; fail c07-one-line; }
  printf '%s' "$line" | grep -qF -- "$(rg_sidecar_path)" || { rg_dbg; fail c07-sidecar-path; }
}

test_rg_c08_same_folder_twice_is_counted_once() { # [C] 같은 폴더가 TASK_PATH 와 사이드카에 둘 다 → 수가 두 배가 되지 않고 task 가 한 번
  local f1 line; f1=$(rg_folder f1)
  rg_log_open_only "$f1"; rg_state auto 0 0 1 "$f1"; rg_sidecar "$f1"
  rg_reinject
  line=$(rg_rq_line_with '열린 빈 칸')
  printf '%s' "$line" | grep -qF 'T01 1/2' || { rg_dbg; fail c08-t01-1-of-2; }
  [ "$(printf '%s' "$line" | grep -o 'T01' | wc -l)" = 1 ] || { rg_dbg; fail c08-task-once; }
}

test_rg_c09_debt_still_shows_reqcheck_lines() { # [C] DEBT=1 이어도 같은 줄이 나온다(빚 줄과 함께)
  local f1; f1=$(rg_folder f1)
  rg_log_violation "$f1" T01; rg_state auto 0 1 1 "$f1"
  rg_reinject
  [ "$(rg_count_lines "$(rg_rq_line_with '닫음')")" = 1 ] || { rg_dbg; fail c09-violation-line; }
  printf '%s' "$HOOK_STDOUT" | grep -qF 'DEBT=1' || { rg_dbg; fail c09-debt-line-kept; }
}

test_rg_c10_standing_instructions_stay_last() { # [C] 요구 대조 줄이 있어도 고정 지시 줄이 출력의 끝(종전 trap 자리)
  local f1; f1=$(rg_folder f1)
  rg_log_open_only "$f1"; rg_state auto 0 0 1 "$f1"; rg_standing
  rg_reinject
  [ -n "$(rg_rq_line_with '열린 빈 칸')" ] || { rg_dbg; fail c10-open-line; }
  [ "$(printf '%s\n' "$HOOK_STDOUT" | tail -1)" = '[고정 지시] 응답은 한국어로' ] || { rg_dbg; fail c10-standing-last; }
}

test_rg_c11_no_findings_output_same_as_legacy() { # [C] 위반 · 열린 빈 칸 · 판정 불가가 다 없으면 종전과 바이트까지 같다(고정 지시 포함 · 긴급 · lazy · UNSET)
  local name
  for name in prompt-no-taskpath prompt-no-marker prompt-filled prompt-template prompt-gone-folder \
              prompt-debt-filled prompt-unset-no-marker; do
    rg_same_as_legacy reinject-mode.sh "$name"
  done
}

# ── 리뷰 반영(task 04 리뷰 루프 1) — fix verification ─────────────────────────────
# 사이드카는 상태 디렉토리에 있어 모델이 Edit · Write(상태파일 거부) · Bash 로 고칠 수 없다 → 푸는 길에 "사용자에게 요청"이 있어야 한다.
RG_SIDECAR_USER_HINT='모델이 고칠 수 없다'
test_rg_b26_broken_sidecar_howto_asks_user_to_fix_it() { # [B] 사이드카 판정 불가(심링크 · 디렉토리 · 상대 경로 줄) → 푸는 길에 "모델이 고칠 수 없다 · 사용자에게 요청" + 경로 · DEBT=1 JSON 도 · log 판정 불가엔 없음
  local f1 f2 kind; f1=$(rg_folder f1); f2=$(rg_folder f2)
  rg_log_no_marker "$f1"; rg_state auto 0 0 1 "$f1"
  for kind in symlink directory relative; do
    rm -rf -- "$(rg_sidecar_path)"
    case "$kind" in
      symlink)   printf '%s\n' "$f2" > "$SANDBOX/real-paths"; ln -s "$SANDBOX/real-paths" "$(rg_sidecar_path)" ;;
      directory) mkdir -p -- "$(rg_sidecar_path)" ;;
      relative)  rg_sidecar "$f2" 'docs/plans/2026-11-27/f3' ;;
    esac
    rg_l1 Write
    rg_assert_exit 2 "b26-$kind-exit2"
    rg_err_has "$RG_SIDECAR_USER_HINT" "b26-$kind-model-cannot"
    rg_err_has '사용자에게' "b26-$kind-ask-user"
    rg_err_has "$(rg_sidecar_path)" "b26-$kind-path"
  done
  rg_state auto 0 1 1 "$f1"
  rg_l1 Write
  rg_assert_exit 0 b26-debt-exit0
  rg_assert_single_context_json b26-debt
  rg_context_has "$RG_SIDECAR_USER_HINT" b26-debt-model-cannot
  rg_context_has '사용자에게' b26-debt-ask-user
  rm -rf -- "$(rg_sidecar_path)"
  rg_log_bad_header "$f1"; rg_state auto 0 0 1 "$f1"
  rg_l1 Write
  rg_assert_exit 2 b26-log-undecidable-exit2
  rg_err_lacks "$RG_SIDECAR_USER_HINT" b26-log-undecidable-no-sidecar-hint
}

test_rg_b27_debt_writes_one_stderr_line_with_violation_count() { # [B] DEBT=1 · 위반 둘 → stderr 한 줄(요구 대조 · 긴급 · 막지 않음 · 위반 수 2 · 생략한 검증) · stdout 은 JSON 한 덩어리 그대로
  local f1; f1=$(rg_folder f1)
  rg_log_table "$f1" 0 \
    '| T01 | 규약 §1 | 요구-가 | | 닫음 |' \
    '| T02 | 규약 §2 | 요구-나 | | 닫음 |'
  rg_state auto 0 1 1 "$f1"
  rg_l1 Write
  rg_assert_exit 0 b27-exit0
  rg_assert_single_context_json b27
  [ "$(rg_count_lines "$HOOK_STDERR")" = 1 ] || { rg_dbg; fail b27-one-stderr-line; }
  rg_err_has '요구 대조' b27-word
  rg_err_has '긴급' b27-emergency
  rg_err_has '막지 않는다' b27-not-blocked
  rg_err_has '생략한 검증' b27-debt-word
  rg_err_has_number 2 b27-count
}
