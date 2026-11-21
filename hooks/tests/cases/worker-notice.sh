# worker-notice 케이스 — gate-guard 의 "구현은 Opus 워커에게(낮은 stakes·긴급 제외) — core §5" 알림 (task 03)
# 계약 정본: docs/plans/2026-11-21/implementation-by-workers/requirement-spec.md §2 "훅 알림" · "훅 알림의 세부" · §5 훅(자동)·반증.
# 설계: blind 테스트 워커 — 구현 diff 미열람, 기대값의 출처는 명세뿐. 알림 기능이 없는 기준 커밋에서 작성했다.
# 관례: sandbox_init 은 run.sh 러너가 각 테스트 앞에서 호출한다 — 케이스 함수는 호출하지 않는다.
# 관찰 지점(사이드카의 이름·형식은 구현자 몫이라 기대지 않는다):
#   stdout(알림 JSON 유무·모양) · 종료 코드 · stderr(기준 커밋과 같은가) · 상태파일 바이트 · 상태 디렉토리 밖의 새 파일 ·
#   git status · "상태 디렉토리의 덧붙은 파일을 지우면 다시 알린다"(기억이 상태 디렉토리에 있다는 간접 관찰).
# "알림 기능이 없을 때" = 기준 커밋(WN_BASE_SHA — 이 기능 착수 직전 main)의 gate-guard·state-lib 사본
#   (hooks/tests/fixtures/legacy-2f07fb0/ — `git show $WN_BASE_SHA:hooks/<파일>` 그대로)을 같은 입력으로 실행한 값.
#   git 이력이 없는 배포 사본에서도 돌도록 git 을 쓰지 않는다(decision-reread.sh 의 legacy 관례와 같다).
# 판정 기준(명세 문장 → 사례): 사례 머리 주석의 [명세 …] 표시.

WN_BASE_SHA=2f07fb079ca4be263b52e55d346c6e7b8468f03f
WN_LEGACY_SOURCE="$TESTS_DIR/fixtures/legacy-2f07fb0"

# ── 케이스 전용 셋업 ───────────────────────────────────────────────────────────
# 작업 폴더를 만들고(spec·log 포함) canonical 경로를 출력한다. TASK_PATH 는 task-mode-guard 가 쓰는 형태(canonical 절대경로).
wn_task_dir() { # <이름> → stdout: 작업 폴더 경로
  local folder
  folder=$(realpath -m -- "$REPO/docs/plans/2026-11-21/$1")
  mkdir -p "$folder"
  printf 'spec body\n' > "$folder/requirement-spec.md"
  printf 'log body\n' > "$folder/log.md"
  printf '%s' "$folder"
}
# 상태파일을 통째로 쓴다(write_state 와 같은 SCHEMA=4 형식 + TASK_PATH 줄). TASK_PATH 인자 '-' = 줄 없음, '' = 빈 값 줄.
wn_state() { # <MODE> <PENDING_GATE> <DEBT> <SPEC> <TASK_PATH|-> [상태파일 경로]
  local target="${6:-$STATE}"
  {
    echo "SCHEMA=4"; echo "MODE=$1"; echo "SPEC=$4"; echo "PENDING_GATE=$2"; echo "DEBT=$3"
    if [ "$5" != "-" ]; then echo "TASK_PATH=$5"; fi
  } > "$target"
}
# 자기무시 .gitignore 를 미리 둔다 — git 노출 관찰이 "기존 훅이 처음 만드는 .gitignore" 에 흔들리지 않게.
wn_gitignore() { printf '*\n' > "$STATE_DIR/.gitignore"; }
wn_root_skip() { [ "$(id -u)" = "0" ]; }   # root 는 chmod 를 무시 — 권한 실패 주입 케이스 무의미

# ── 케이스 전용 JSON 빌더 (실제 훅 입력 모양 — decision-reread.sh dr_tool 과 같은 필드) ─────────────
# agent 인자: none = agent_id 키 없음(메인) · empty = agent_id:"" · null = agent_id:null · 그 밖 = 워커 agent_id 값(+agent_type)
wn_json() { # <event> <tool> <file_path> [agent] [session_id] [cwd]
  jq -cn --arg e "$1" --arg t "$2" --arg f "$3" --arg agent "${4:-none}" --arg s "${5:-$SID}" --arg c "${6:-$REPO}" '
    {session_id:$s, cwd:$c, permission_mode:"auto", hook_event_name:$e, tool_name:$t,
     tool_input:({file_path:$f}
       + (if $t == "Write" then {content:"x"} elif $t == "Edit" then {old_string:"a", new_string:"b"}
          else {edits:[{old_string:"a", new_string:"b"}]} end)),
     tool_use_id:"toolu_wn"}
    + (if $agent == "none" then {}
       elif $agent == "empty" then {agent_id:""}
       elif $agent == "null" then {agent_id:null}
       else {agent_id:$agent, agent_type:"general-purpose"} end)'
}

# ── 실행 헬퍼 ──────────────────────────────────────────────────────────────────
# 훅의 stdout·stderr 를 따로 받는다(run_hook 은 stdout 을, run_hook_stdout 은 stderr 를 버린다).
#   바이트 비교용 원본은 $SANDBOX/wn-capture/<태그>.out|.err 에 남긴다. → HOOK_EXIT · HOOK_STDOUT · HOOK_STDERR
WN_CAPTURE_DIR_NAME=wn-capture
wn_run_with() { # <hook 절대경로> <json> [태그]
  local capture="$SANDBOX/$WN_CAPTURE_DIR_NAME" tag="${3:-last}"
  mkdir -p "$capture"
  set +e
  printf '%s' "$2" | env HOME="$HOME_DIR" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
    XDG_CONFIG_HOME="$XDG_DIR" ${WN_TIMEOUT:+timeout "$WN_TIMEOUT"} bash "$1" > "$capture/$tag.out" 2> "$capture/$tag.err"
  HOOK_EXIT=$?
  set -e
  WN_LAST_STDOUT_FILE="$capture/$tag.out"                 # 바이트 단위 판정용($(...) 는 끝 개행을 지운다)
  HOOK_STDOUT=$(cat "$capture/$tag.out")
  HOOK_STDERR=$(cat "$capture/$tag.err")
}
wn_gate() { wn_run_with "$HOOKS_DIR/gate-guard.sh" "$(wn_json "$@")"; }      # 새 훅 — wn_json 인자 그대로
wn_gate_json() { wn_run_with "$HOOKS_DIR/gate-guard.sh" "$1" "${2:-last}"; }   # 새 훅 — 완성된 JSON

# ── 단언 ───────────────────────────────────────────────────────────────────────
WN_NOTICE_FILTER='
  length == 1
  and (.[0] | type == "object")
  and ((.[0] | keys) == ["hookSpecificOutput"])
  and ((.[0].hookSpecificOutput | keys) == ["additionalContext", "hookEventName"])
  and .[0].hookSpecificOutput.hookEventName == "PreToolUse"
  and (.[0].hookSpecificOutput.additionalContext | type == "string"
       and contains("워커") and contains("core §5") and (contains("\n") | not))'
wn_is_notice() { printf '%s' "$1" | jq -se "$WN_NOTICE_FILTER" >/dev/null 2>&1; }   # <stdout 문자열> → rc 0 = 알림 JSON 하나
# 알림: exit 0 + stdout 이 정확히 JSON 하나 + 명세의 모양({"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":…}})
#   + 문구의 핵심 낱말("워커"·"core §5") + 한 줄. 판정 키(permissionDecision 등)가 섞이면 판정을 바꾸므로 키 집합을 고정한다.
wn_assert_notice() { # <assert-id>
  assert_exit 0 "$1-exit"
  wn_is_notice "$HOOK_STDOUT" || { echo "  [dbg] stdout=$(printf '%s' "$HOOK_STDOUT" | head -c 240)"; fail "$1-notice"; }
}
# 알림 없음: 종료 코드 + stdout 이 비어 있다(이 경로들은 기준 커밋에서 stdout 을 쓰지 않는다).
wn_assert_quiet() { # <want-exit> <assert-id>
  assert_exit "$1" "$2-exit"
  [ -z "$HOOK_STDOUT" ] || { echo "  [dbg] stdout=$(printf '%s' "$HOOK_STDOUT" | head -c 240)"; fail "$2-stdout-empty"; }
  [ ! -s "${WN_LAST_STDOUT_FILE:-/dev/null}" ] || { echo "  [dbg] stdout 바이트=$(wc -c < "$WN_LAST_STDOUT_FILE")"; fail "$2-stdout-zero-bytes"; }   # 빈 줄 하나도 출력이다
}
# stdout 이 비었거나 알림 JSON 하나 — 깨진 JSON·JSON 둘 이어 붙임 금지(실패 정책 사례용)
wn_assert_empty_or_notice() { # <assert-id>
  if [ -n "$HOOK_STDOUT" ] && ! wn_is_notice "$HOOK_STDOUT"; then
    echo "  [dbg] stdout=$(printf '%s' "$HOOK_STDOUT" | head -c 240)"; fail "$1-wellformed"
  fi
  if [ -z "$HOOK_STDOUT" ] && [ -s "${WN_LAST_STDOUT_FILE:-/dev/null}" ]; then   # 공백·개행뿐인 출력 = 비지 않은 깨진 출력
    echo "  [dbg] stdout 바이트=$(wc -c < "$WN_LAST_STDOUT_FILE")"; fail "$1-wellformed-zero-bytes"
  fi
}

# 실패 시 stderr: `[gate-guard] 경고` 로 시작하는 줄이 정확히 한 줄(실패를 드러내기 — 한 번만). 정상 경로에는 0줄.
wn_warning_count() { printf '%s\n' "$1" | grep -ac '^\[gate-guard\] 경고' || true; }   # <stderr 문자열>
wn_assert_one_warning() { # <assert-id> [stderr 문자열 — 기본 HOOK_STDERR]
  local count; count=$(wn_warning_count "${2-$HOOK_STDERR}")
  [ "$count" = "1" ] || { echo "  [dbg] 경고 줄 수=$count stderr=$(printf '%s' "${2-$HOOK_STDERR}" | head -c 240)"; fail "$1-one-warning-line"; }
}
wn_assert_no_warning() { # <assert-id>
  local count; count=$(wn_warning_count "$HOOK_STDERR")
  [ "$count" = "0" ] || { echo "  [dbg] 경고 줄 수=$count stderr=$(printf '%s' "$HOOK_STDERR" | head -c 240)"; fail "$1-no-warning-line"; }
}

# ── 기준 커밋(알림 없음)과의 비교 ───────────────────────────────────────────────
wn_legacy_init() { # fixture 사본 → $WN_LEGACY_DIR (SCRIPT_DIR 기준 state-lib.sh source 가 사본끼리 맞물림)
  WN_LEGACY_DIR="$SANDBOX/legacy-gate"
  mkdir -p "$WN_LEGACY_DIR"
  local name
  for name in gate-guard.sh state-lib.sh; do
    [ -f "$WN_LEGACY_SOURCE/$name" ] || fail legacy-fixture-missing
    cp "$WN_LEGACY_SOURCE/$name" "$WN_LEGACY_DIR/$name"
  done
}
wn_clear_state_dir() { find "$STATE_DIR" -mindepth 1 -delete 2>/dev/null || true; }
# 상태 디렉토리를 비우고 시나리오를 세운다 → WN_JSON(그 시나리오의 입력) · WN_HOLD_LOCK(1 이면 실행 중 상태 lock 점유)
wn_prepare() { # <시나리오 이름>
  wn_clear_state_dir
  WN_HOLD_LOCK=0
  local folder; folder=$(wn_task_dir matrix)
  case "$1" in
    auto-first)        wn_state auto 0 0 1 "$folder"; WN_JSON=$(wn_json PreToolUse Write "$REPO/src/a.c") ;;
    auto-edit)         wn_state auto 0 0 1 "$folder"; WN_JSON=$(wn_json PreToolUse Edit "$REPO/src/a.c") ;;
    auto-multiedit)    wn_state auto 0 0 1 "$folder"; WN_JSON=$(wn_json PreToolUse MultiEdit "$REPO/src/a.c") ;;
    auto-second)       wn_state auto 0 0 1 "$folder"; WN_JSON=$(wn_json PreToolUse Write "$REPO/src/a.c")
                       wn_gate_json "$WN_JSON" prime ;;                       # 같은 폴더에서 한 번 먼저(새 훅) — 두 번째 호출
    auto-no-taskpath)  wn_state auto 0 0 1 -; WN_JSON=$(wn_json PreToolUse Write "$REPO/src/a.c") ;;
    auto-policy-docs)  wn_state auto 0 0 1 "$folder"; WN_JSON=$(wn_json PreToolUse Write "$REPO/docs/core.md") ;;
    auto-worker)       wn_state auto 0 0 1 "$folder"; WN_JSON=$(wn_json PreToolUse Write "$REPO/src/a.c" agent-9) ;;
    auto-docs)         wn_state auto 0 0 1 "$folder"; WN_JSON=$(wn_json PreToolUse Write "$REPO/docs/notes.md") ;;
    auto-debt)         wn_state auto 0 1 1 "$folder"; WN_JSON=$(wn_json PreToolUse Write "$REPO/src/a.c") ;;
    auto-post)         wn_state auto 0 0 1 "$folder"; WN_JSON=$(wn_json PostToolUse Write "$REPO/src/a.c") ;;
    auto-bash)         wn_state auto 0 0 1 "$folder"; WN_JSON=$(json_bash "sed -i 's/a/b/' src/a.c") ;;
    lazy-pass)         wn_state lazy 0 0 1 "$folder"; WN_JSON=$(wn_json PreToolUse Write "$REPO/src/a.c") ;;
    lazy-post)         wn_state lazy 0 0 1 "$folder"; WN_JSON=$(wn_json PostToolUse Edit "$REPO/src/a.c") ;;
    lazy-pending)      wn_state lazy 1 0 1 "$folder"; WN_JSON=$(wn_json PreToolUse Write "$REPO/src/a.c") ;;
    lazy-bash)         wn_state lazy 0 0 1 "$folder"; WN_JSON=$(json_bash "sed -i 's/a/b/' src/a.c") ;;
    spec0)             wn_state UNSET 0 0 0 "$folder"; WN_JSON=$(wn_json PreToolUse Write "$REPO/src/a.c") ;;
    spec0-mode-auto)   wn_state auto 0 0 0 "$folder"; WN_JSON=$(wn_json PreToolUse Write "$REPO/src/a.c") ;;
    mode-unset)        wn_state UNSET 0 0 1 "$folder"; WN_JSON=$(wn_json PreToolUse Write "$REPO/src/a.c") ;;
    state-file-edit)   wn_state auto 0 0 1 "$folder"; WN_JSON=$(wn_json PreToolUse Edit "$STATE") ;;
    no-file-path)      wn_state auto 0 0 1 "$folder"
                       WN_JSON=$(jq -cn --arg c "$REPO" --arg s "$SID" \
                         '{hook_event_name:"PreToolUse", tool_name:"Write", tool_input:{}, cwd:$c, session_id:$s}') ;;
    reset-pending)     wn_state auto 0 0 1 "$folder"; printf '%s\n' "$folder" > "$STATE.reset-pending"
                       WN_JSON=$(wn_json PreToolUse Write "$REPO/src/a.c") ;;
    corrupt-state)     printf 'garbage not a state file\n' > "$STATE"; WN_JSON=$(wn_json PreToolUse Write "$REPO/src/a.c") ;;
    lock-held)         wn_state auto 0 0 1 "$folder"; WN_HOLD_LOCK=1; WN_JSON=$(wn_json PreToolUse Write "$REPO/src/a.c") ;;
    compact-unread)    wn_state auto 0 0 1 "$folder"; printf '%s\n' "$(( $(date +%s) - 100 ))" > "$STATE_DIR/$SID.compact"
                       WN_JSON=$(wn_json PreToolUse Write "$REPO/src/a.c") ;;
    standing-ask)      wn_state auto 0 0 1 "$folder"; mkdir -p "$HOME_DIR/.claude"
                       printf '지시\n' > "$HOME_DIR/.claude/standing-instructions.md"
                       WN_JSON=$(wn_json PreToolUse Edit "$HOME_DIR/.claude/standing-instructions.md") ;;
    *) fail "unknown-scenario-$1" ;;
  esac
}
# 시나리오의 입력을 한 훅으로 실행하고 결과(exit·stdout·stderr·실행 뒤 상태파일)를 <태그> 로 남긴다.
wn_run_scenario() { # <hook 절대경로> <태그>
  local capture="$SANDBOX/$WN_CAPTURE_DIR_NAME"
  if [ "$WN_HOLD_LOCK" = "1" ]; then exec 8>>"$STATE.lock"; flock -x 8; fi
  wn_run_with "$1" "$WN_JSON" "$2"
  if [ "$WN_HOLD_LOCK" = "1" ]; then flock -u 8 2>/dev/null || true; exec 8>&-; fi
  printf '%s\n' "$HOOK_EXIT" > "$capture/$2.exit"
  if [ -f "$STATE" ]; then cp "$STATE" "$capture/$2.state"; else : > "$capture/$2.state"; fi
}
# 같은 시나리오를 기준 커밋 훅과 새 훅으로 각각 깨끗한 상태에서 돌려 비교한다.
#   같아야 하는 것: 종료 코드 · stderr 바이트 · 실행 뒤 상태파일 바이트.
#   stdout: 바이트가 같거나, 기준이 비어 있고 새 쪽이 알림 JSON 하나일 때만 다를 수 있다.
#   want_notice = yes|no|any — 새 쪽 stdout 에 알림이 있어야/없어야/상관없음.
wn_compare_with_legacy() { # <시나리오 이름> <want_notice>
  local capture="$SANDBOX/$WN_CAPTURE_DIR_NAME" name="$1" legacy_tag="legacy-$1" new_tag="new-$1"
  wn_prepare "$name"; wn_run_scenario "$WN_LEGACY_DIR/gate-guard.sh" "$legacy_tag"
  wn_prepare "$name"; wn_run_scenario "$HOOKS_DIR/gate-guard.sh" "$new_tag"
  cmp -s "$capture/$legacy_tag.exit" "$capture/$new_tag.exit" \
    || { echo "  [dbg] $name exit legacy=$(cat "$capture/$legacy_tag.exit") new=$(cat "$capture/$new_tag.exit")"; fail "same-exit-$name"; }
  cmp -s "$capture/$legacy_tag.err" "$capture/$new_tag.err" \
    || { echo "  [dbg] $name stderr legacy=$(head -c 160 "$capture/$legacy_tag.err") new=$(head -c 160 "$capture/$new_tag.err")"; fail "same-stderr-$name"; }
  cmp -s "$capture/$legacy_tag.state" "$capture/$new_tag.state" \
    || { echo "  [dbg] $name state legacy=$(tr '\n' ' ' < "$capture/$legacy_tag.state") new=$(tr '\n' ' ' < "$capture/$new_tag.state")"; fail "same-state-$name"; }
  local new_out; new_out=$(cat "$capture/$new_tag.out")
  if ! cmp -s "$capture/$legacy_tag.out" "$capture/$new_tag.out"; then
    { [ ! -s "$capture/$legacy_tag.out" ] && wn_is_notice "$new_out"; } \
      || { echo "  [dbg] $name stdout legacy=$(head -c 160 "$capture/$legacy_tag.out") new=$(head -c 160 "$capture/$new_tag.out")"; fail "stdout-only-notice-added-$name"; }
  fi
  case "$2" in
    yes) wn_is_notice "$new_out" || { echo "  [dbg] $name stdout=$(printf '%s' "$new_out" | head -c 160)"; fail "notice-present-$name"; } ;;
    no)  if [ -n "$new_out" ] && wn_is_notice "$new_out"; then fail "notice-absent-$name"; fi
         if printf '%s' "$new_out" | grep -q 'additionalContext'; then fail "no-additional-context-$name"; fi ;;
    any) ;;
  esac
}

# 상태 디렉토리 밖의 경로 목록(사이드카가 다른 곳에 생기지 않았나 — 캡처 폴더 제외)
wn_paths_outside_state_dir() { # <출력 파일>
  find "$SANDBOX" \( -path "$STATE_DIR" -o -path "$SANDBOX/$WN_CAPTURE_DIR_NAME" \) -prune -o -print 2>/dev/null \
    | LC_ALL=C sort > "$1"
}

# ══ 1·2 첫 호출 알림 · 같은 폴더 두 번째 호출 없음 ═══════════════════════════════

test_wn_01() { # [명세 훅 알림·세부 대상 도구] 메인의 L1 Edit/Write/MultiEdit PreToolUse 첫 호출 → exit 0 + 알림 JSON 하나
  # 도구마다 다른 작업 폴더로 "첫 호출"을 만든다 — 세 도구 모두 같은 경로로 알림을 내야 한다(MultiEdit 포함).
  local tool folder
  for tool in Edit Write MultiEdit; do
    folder=$(wn_task_dir "first-$tool")
    wn_state auto 0 0 1 "$folder"
    mkdir -p "$REPO/src"
    wn_gate PreToolUse "$tool" "$REPO/src/a.c"
    wn_assert_notice "wn01-$tool-first"
  done
}

test_wn_02() { # [명세 한 번의 범위] 같은 세션·같은 작업 폴더의 두 번째 쓰기 — 도구를 바꿔도 알림 없음(짝: 첫 호출은 알림)
  local folder; folder=$(wn_task_dir same)
  wn_state auto 0 0 1 "$folder"
  wn_gate PreToolUse Write "$REPO/src/a.c"
  wn_assert_notice wn02-first-write
  wn_assert_no_warning wn02-first-write                                       # 정상 경로 대조: 경고 줄 없음
  wn_gate PreToolUse Edit "$REPO/src/b.c"
  wn_assert_quiet 0 wn02-second-edit
  wn_assert_no_warning wn02-second-edit
  wn_gate PreToolUse MultiEdit "$REPO/src/c.c"
  wn_assert_quiet 0 wn02-third-multiedit
  wn_gate PreToolUse Write "$REPO/src/a.c"
  wn_assert_quiet 0 wn02-fourth-same-file
}

# ══ 3·4·5 "한 번"의 범위 — 작업 폴더 · 세션 · 빈 TASK_PATH · 압축 ══════════════════

test_wn_03() { # [명세 TASK_PATH 마다 한 번] 폴더가 바뀌면 다시 한 번, 원래 폴더로 돌아가면 다시 내지 않는다
  local folder_a folder_b
  folder_a=$(wn_task_dir task-a); folder_b=$(wn_task_dir task-b)
  wn_state auto 0 0 1 "$folder_a"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn03-a-first
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 0 wn03-a-second
  wn_state auto 0 0 1 "$folder_b"
  wn_gate PreToolUse Edit "$REPO/src/a.c";  wn_assert_notice wn03-b-first
  wn_gate PreToolUse Edit "$REPO/src/a.c";  wn_assert_quiet 0 wn03-b-second
  wn_state auto 0 0 1 "$folder_a"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 0 wn03-back-to-a
  wn_state auto 0 0 1 "$folder_b"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 0 wn03-back-to-b
}

test_wn_03b() { # [명세 TASK_PATH 마다 한 번 — 판단: 기억의 열쇠는 TASK_PATH 값] 같은 경로의 폴더를 지웠다 다시 만들어도 같은 폴더로 센다
  local folder; folder=$(wn_task_dir recreate)
  wn_state auto 0 0 1 "$folder"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn03b-first
  rm -rf "$folder"; folder=$(wn_task_dir recreate)
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 0 wn03b-recreated-same-path
  local other; other=$(wn_task_dir recreate-other)                                  # 짝: 다른 경로면 다시 낸다
  wn_state auto 0 0 1 "$other"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn03b-control-other-path
}

test_wn_04() { # [명세 세션마다] 다른 세션 ID 에서 같은 작업 폴더 → 다시 한 번, 원래 세션은 계속 조용하다
  local folder; folder=$(wn_task_dir shared)
  local other_session="${SID}x2"
  wn_state auto 0 0 1 "$folder"
  wn_state auto 0 0 1 "$folder" "$STATE_DIR/$other_session"
  wn_gate PreToolUse Write "$REPO/src/a.c";                          wn_assert_notice wn04-session1-first
  wn_gate PreToolUse Write "$REPO/src/a.c" none "$other_session";    wn_assert_notice wn04-session2-first
  wn_gate PreToolUse Write "$REPO/src/a.c" none "$other_session";    wn_assert_quiet 0 wn04-session2-second
  wn_gate PreToolUse Write "$REPO/src/a.c";                          wn_assert_quiet 0 wn04-session1-second
}

test_wn_05() { # [명세 TASK_PATH 가 비어 있으면 "폴더 없음"을 하나의 폴더로] 줄 없음 = 빈 값 = 같은 폴더, 그 뒤 실제 폴더는 다른 폴더
  wn_state auto 0 0 1 -                                                      # TASK_PATH 줄 없음
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn05-no-taskpath-first
  wn_gate PreToolUse Edit "$REPO/src/a.c";  wn_assert_quiet 0 wn05-no-taskpath-second
  wn_state auto 0 0 1 ''                                                     # TASK_PATH= (빈 값) — 같은 "폴더 없음"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 0 wn05-empty-value-same-bucket
  local folder; folder=$(wn_task_dir after-empty)                            # 짝: 실제 폴더가 생기면 다시 한 번
  wn_state auto 0 0 1 "$folder"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn05-real-folder-after-empty
}

test_wn_05b() { # [명세 압축은 세션을 끝내지 않으므로 다시 내지 않는다] 알림 → 압축 → 미독 차단(알림 없음) → 재독 → 통과(알림 없음)
  local folder; folder=$(wn_task_dir compact)
  wn_state auto 0 0 1 "$folder"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn05b-before-compact
  printf '%s\n' "$(( $(date +%s) - 100 ))" > "$STATE_DIR/$SID.compact"       # fixture: 압축 시각(decision-reread 관례)
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 2 wn05b-unread-blocked
  local target
  for target in "$folder/requirement-spec.md" "$folder/log.md"; do         # 메인의 전체 Read 로 재독
    run_hook reread-track.sh "$(jq -cn --arg s "$SID" --arg c "$REPO" --arg f "$target" \
      '{session_id:$s, cwd:$c, hook_event_name:"PostToolUse", tool_name:"Read", tool_input:{file_path:$f}}')"
  done
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 0 wn05b-after-reread-no-renotice
}

# ══ 6 메인 판별 — agent_id ═══════════════════════════════════════════════════

test_wn_06() { # [명세 워커의 쓰기(agent_id 있음)에는 내지 않는다] 워커 호출은 조용하고 "한 번"을 소비하지 않는다(짝: 같은 입력의 메인)
  local folder; folder=$(wn_task_dir worker)
  wn_state auto 0 0 1 "$folder"
  wn_gate PreToolUse Write "$REPO/src/a.c" agent-77;      wn_assert_quiet 0 wn06-worker-write
  wn_gate PreToolUse Edit "$REPO/src/a.c" agent-77;       wn_assert_quiet 0 wn06-worker-edit
  wn_gate PreToolUse MultiEdit "$REPO/src/a.c" agent-78;  wn_assert_quiet 0 wn06-worker-multiedit
  wn_gate PreToolUse Write "$REPO/src/a.c";               wn_assert_notice wn06-control-main-first
  wn_gate PreToolUse Write "$REPO/src/a.c" agent-77;      wn_assert_quiet 0 wn06-worker-after-main
}

test_wn_06b() { # [명세 메인 판별: agent_id 가 없거나 비어 있으면(빈 문자열·null) 메인] 빈 문자열·null 은 메인으로 보아 낸다
  local folder_empty folder_null
  folder_empty=$(wn_task_dir agent-empty); folder_null=$(wn_task_dir agent-null)
  wn_state auto 0 0 1 "$folder_empty"
  wn_gate PreToolUse Write "$REPO/src/a.c" empty; wn_assert_notice wn06b-empty-string-is-main
  wn_gate PreToolUse Write "$REPO/src/a.c" empty; wn_assert_quiet 0 wn06b-empty-string-second
  wn_state auto 0 0 1 "$folder_null"
  wn_gate PreToolUse Write "$REPO/src/a.c" null;  wn_assert_notice wn06b-null-is-main
  wn_gate PreToolUse Write "$REPO/src/a.c";       wn_assert_quiet 0 wn06b-null-and-absent-same-main
}

# ══ 7 L0/L1 — 기존 분류를 그대로 쓴다 ══════════════════════════════════════════

test_wn_07() { # [명세 L0 경로에는 내지 않는다] docs/** 일반 문서·저장소 밖·~/.claude 비배포 → 조용, "한 번"을 소비하지 않음(짝: 뒤의 L1)
  local folder; folder=$(wn_task_dir l0)
  wn_state auto 0 0 1 "$folder"
  mkdir -p "$REPO/docs/notes" "$SANDBOX/outside" "$HOME_DIR/.claude/projects/p/memory"
  wn_gate PreToolUse Write "$REPO/docs/notes/TECHNICAL.md";                  wn_assert_quiet 0 wn07-docs-note
  wn_gate PreToolUse Edit "$folder/log.md";                                  wn_assert_quiet 0 wn07-task-log
  wn_gate PreToolUse Write "$SANDBOX/outside/packet.md";                     wn_assert_quiet 0 wn07-outside-repo
  wn_gate PreToolUse Write "$HOME_DIR/.claude/projects/p/memory/m.md";       wn_assert_quiet 0 wn07-claude-memory
  wn_gate PreToolUse Write "$REPO/src/a.c";                                  wn_assert_notice wn07-control-l1-after-l0
}

test_wn_07b() { # [명세 "L1 경로" = gate-guard 의 기존 분류] docs 아래라도 정책 파일(core.md)은 L1 → 낸다
  local folder; folder=$(wn_task_dir policy-docs)
  wn_state auto 0 0 1 "$folder"
  mkdir -p "$REPO/docs"
  wn_gate PreToolUse Write "$REPO/docs/core.md"; wn_assert_notice wn07b-docs-core-md
}

test_wn_07c() { # [명세 "L1 경로" = 기존 분류 — 저장소 안 정책 디렉토리] repo 루트 hooks/ 파일 → 낸다
  local folder; folder=$(wn_task_dir policy-hooks)
  wn_state auto 0 0 1 "$folder"
  wn_gate PreToolUse Edit "$REPO/hooks/gate-guard.sh"; wn_assert_notice wn07c-repo-hooks
}

test_wn_07d() { # [명세 "L1 경로" = 기존 분류 — 저장소 밖이라도 ~/.claude 배포 경로는 L1] → 낸다
  local folder; folder=$(wn_task_dir policy-deploy)
  wn_state auto 0 0 1 "$folder"
  mkdir -p "$HOME_DIR/.claude/hooks"
  wn_gate PreToolUse Write "$HOME_DIR/.claude/hooks/x.sh"; wn_assert_notice wn07d-claude-deploy-hooks
}

# ══ 8 lazy · 긴급(DEBT=1) ════════════════════════════════════════════════════

test_wn_08() { # [명세 lazy 모드에는 내지 않는다] lazy 통과 쓰기는 조용, 소비하지 않음 — 같은 폴더에서 auto 로 바꾸면 낸다(짝)
  local folder; folder=$(wn_task_dir lazy)
  wn_state lazy 0 0 1 "$folder"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 0 wn08-lazy-pass
  wn_gate PreToolUse Edit "$REPO/src/a.c";  wn_assert_quiet 0 wn08-lazy-pass-again
  wn_state auto 0 0 1 "$folder"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn08-control-auto-same-folder
}

test_wn_08b() { # [명세 긴급(DEBT=1 로 들어온 작업)에는 내지 않는다] DEBT=1 조용, 소비하지 않음 — DEBT=0 이면 낸다(짝)
  local folder; folder=$(wn_task_dir debt)
  wn_state auto 0 1 1 "$folder"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 0 wn08b-debt-pass
  wn_gate PreToolUse Edit "$REPO/src/a.c";  wn_assert_quiet 0 wn08b-debt-pass-again
  wn_state auto 0 0 1 "$folder"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn08b-control-debt-cleared
}

test_wn_08c() { # [명세 긴급 = DEBT=1] set-state emergency 로 실제 진입한 경로도 조용하다(짝: 같은 폴더 DEBT=0 → 낸다)
  local folder; folder=$(wn_task_dir emergency)
  wn_state UNSET 0 0 0 "$folder"
  set +e; env HOME="$HOME_DIR" bash "$HOOKS_DIR/set-state.sh" emergency "$STATE" >/dev/null 2>&1; set -e
  assert_state DEBT 1 wn08c-emergency-precondition
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 0 wn08c-emergency-pass
  wn_state auto 0 0 1 "$folder"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn08c-control-after-debt-clear
}

# ══ 9 차단 경로 — 차단 사유만, 알림 없음, "한 번"을 소비하지 않음 ═══════════════════

test_wn_09() { # [명세 이미 차단되는 경우(차단 사유만) · 판정 순서] SPEC=0 차단 → 합의 뒤 첫 통과 쓰기에 알림
  local folder; folder=$(wn_task_dir spec0)
  wn_state UNSET 0 0 0 "$folder"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 2 wn09-spec0-blocked
  assert_stderr_match '요구사항 명세 미합의\(SPEC=0\)' wn09-spec0-reason
  wn_state auto 0 0 0 "$folder"                                              # 직전 모드 잔존 + SPEC=0
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 2 wn09-spec0-mode-auto-blocked
  wn_state UNSET 0 0 1 "$folder"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 2 wn09-mode-unset-blocked
  assert_stderr_match '자율성 미선택\(MODE=UNSET\)' wn09-mode-unset-reason
  wn_state auto 0 0 1 "$folder"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn09-first-pass-after-blocks
}

test_wn_09b() { # [명세 차단 경로에는 내지 않는다 · 판정 순서] 상태 검증 실패(lock 점유) 차단 → 풀린 뒤 첫 통과에 알림
  local folder; folder=$(wn_task_dir lock)
  wn_state auto 0 0 1 "$folder"
  exec 8>>"$STATE.lock"; flock -x 8
  wn_gate PreToolUse Write "$REPO/src/a.c"
  flock -u 8 2>/dev/null || true; exec 8>&-
  wn_assert_quiet 2 wn09b-lock-blocked
  assert_stderr_match '상태 검증 실패' wn09b-lock-reason
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn09b-first-pass-after-lock
}

test_wn_09c() { # [명세 차단 경로 · 판정 순서 — auto 에서도 막는 압축 뒤 미독] 미독 차단 → 재독 뒤 첫 통과에 알림
  local folder; folder=$(wn_task_dir unread)
  wn_state auto 0 0 1 "$folder"
  printf '%s\n' "$(( $(date +%s) - 100 ))" > "$STATE_DIR/$SID.compact"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 2 wn09c-unread-blocked
  assert_stderr_match '압축 뒤 작업 기록 미독' wn09c-unread-reason
  local target
  for target in "$folder/requirement-spec.md" "$folder/log.md"; do
    run_hook reread-track.sh "$(jq -cn --arg s "$SID" --arg c "$REPO" --arg f "$target" \
      '{session_id:$s, cwd:$c, hook_event_name:"PostToolUse", tool_name:"Read", tool_input:{file_path:$f}}')"
  done
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn09c-first-pass-after-reread
}

test_wn_09d() { # [명세 차단 경로 · 판정 순서] reset-pending 인계 차단(UNSET 로 리셋) → 다시 합의·auto 뒤 첫 통과에 알림
  local folder; folder=$(wn_task_dir reset)
  wn_state auto 0 0 1 "$folder"
  printf '%s\n' "$folder" > "$STATE.reset-pending"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 2 wn09d-reset-pending-blocked
  [ ! -e "$STATE.reset-pending" ] || fail wn09d-precondition-handoff
  wn_state auto 0 0 1 "$folder"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn09d-first-pass-after-reset
}

test_wn_09e() { # [명세 차단 경로] lazy PENDING_GATE=1 차단 · 상태파일 직접 편집 거부 · file_path 없음 차단 → 모두 알림 없음
  local folder; folder=$(wn_task_dir lazy-pending)
  wn_state lazy 1 0 1 "$folder"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 2 wn09e-lazy-pending-blocked
  wn_state auto 0 0 1 "$folder"
  wn_gate PreToolUse Edit "$STATE";         wn_assert_quiet 2 wn09e-state-file-denied
  wn_gate_json "$(jq -cn --arg c "$REPO" --arg s "$SID" \
    '{hook_event_name:"PreToolUse", tool_name:"Write", tool_input:{}, cwd:$c, session_id:$s}')"
  wn_assert_quiet 2 wn09e-no-file-path-blocked
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn09e-control-first-pass
}

# ══ 10 고정 지시 파일 ask — JSON 은 ask 하나뿐 ═══════════════════════════════════

test_wn_10() { # [명세 다른 JSON(ask)을 내는 경로에는 내지 않는다 — stdout 에 JSON 이 둘 이어 붙지 않는다]
  local folder; folder=$(wn_task_dir standing)
  wn_state auto 0 0 1 "$folder"
  mkdir -p "$HOME_DIR/.claude"; printf '지시\n' > "$HOME_DIR/.claude/standing-instructions.md"
  local tool
  for tool in Write Edit MultiEdit; do
    wn_gate PreToolUse "$tool" "$HOME_DIR/.claude/standing-instructions.md"
    assert_exit 0 "wn10-$tool-ask-exit"
    printf '%s' "$HOOK_STDOUT" | jq -se '
        length == 1
        and .[0].hookSpecificOutput.permissionDecision == "ask"
        and (.[0].hookSpecificOutput | has("additionalContext") | not)' >/dev/null 2>&1 \
      || { echo "  [dbg] stdout=$(printf '%s' "$HOOK_STDOUT" | head -c 240)"; fail "wn10-$tool-only-ask-json"; }
    assert_stdout_no_match '워커|core §5' "wn10-$tool-no-notice-words"
  done
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn10-control-l1-after-ask   # ask 는 "한 번"을 소비하지 않는다
}

# ══ 11 PostToolUse · Bash ═══════════════════════════════════════════════════

test_wn_11() { # [명세 PostToolUse 와 Bash 에는 내지 않는다] auto Post(Edit/Write/MultiEdit)·Bash → stdout 비어 있음, 소비 안 함(짝: 뒤의 Pre)
  local folder; folder=$(wn_task_dir post-bash)
  wn_state auto 0 0 1 "$folder"
  local tool
  for tool in Edit Write MultiEdit; do
    wn_gate PostToolUse "$tool" "$REPO/src/a.c"; wn_assert_quiet 0 "wn11-post-$tool"
  done
  wn_gate_json "$(json_bash "printf 'x' > src/a.c")";       wn_assert_quiet 0 wn11-bash-redirect
  wn_gate_json "$(json_bash "sed -i 's/a/b/' src/a.c")";    wn_assert_quiet 0 wn11-bash-sed
  wn_gate PreToolUse Write "$REPO/src/a.c";                 wn_assert_notice wn11-control-pre-after
}

# ══ 12 알림이 판정을 바꾸지 않는다 — 기준 커밋 훅과 나란히 ═══════════════════════════

test_wn_12() { # [명세 막지 않는다(종료 코드·차단 판정은 지금과 같다) · 불변: SPEC/MODE 차단 판정·lazy 동작]
  # 시나리오마다 깨끗한 상태에서 기준 커밋 훅과 새 훅을 돌려 종료 코드·stderr·실행 뒤 상태파일이 바이트까지 같고,
  # stdout 은 "기준이 비어 있고 새 쪽이 알림 하나"일 때만 다르다. 마지막 칸 = 새 쪽에 알림이 있어야 하나.
  wn_legacy_init
  mkdir -p "$REPO/src" "$REPO/docs"
  wn_compare_with_legacy auto-first        yes
  wn_compare_with_legacy auto-edit         yes
  wn_compare_with_legacy auto-multiedit    yes
  wn_compare_with_legacy auto-second       no
  wn_compare_with_legacy auto-no-taskpath  yes
  wn_compare_with_legacy auto-policy-docs  yes
  wn_compare_with_legacy auto-worker       no
  wn_compare_with_legacy auto-docs         no
  wn_compare_with_legacy auto-debt         no
  wn_compare_with_legacy auto-post         no
  wn_compare_with_legacy auto-bash         no
  wn_compare_with_legacy lazy-pass         no
  wn_compare_with_legacy lazy-post         no
  wn_compare_with_legacy lazy-pending      no
  wn_compare_with_legacy lazy-bash         no      # 기존 lazy Bash 리마인더 출력(stderr) 바이트 불변
  wn_compare_with_legacy spec0             no
  wn_compare_with_legacy spec0-mode-auto   no
  wn_compare_with_legacy mode-unset        no
  wn_compare_with_legacy state-file-edit   no
  wn_compare_with_legacy no-file-path      no
  wn_compare_with_legacy reset-pending     no
  wn_compare_with_legacy corrupt-state     no
  wn_compare_with_legacy lock-held         no
  wn_compare_with_legacy compact-unread    no
  wn_compare_with_legacy standing-ask      no      # ask JSON 바이트 불변(알림이 이어 붙지 않음)
}

test_wn_12b() { # [명세 알림이 나가도 종료 코드와 차단 판정이 알림 없는 경우와 같음] 같은 입력: 알림 나간 호출 = 안 나간 호출(두 번째)
  local folder; folder=$(wn_task_dir same-verdict)
  wn_state auto 0 0 1 "$folder"
  local json; json=$(wn_json PreToolUse Edit "$REPO/src/a.c")
  wn_gate_json "$json" first;  local first_exit=$HOOK_EXIT; wn_assert_notice wn12b-first
  wn_gate_json "$json" second; wn_assert_quiet "$first_exit" wn12b-second-same-exit
  cmp -s "$SANDBOX/$WN_CAPTURE_DIR_NAME/first.err" "$SANDBOX/$WN_CAPTURE_DIR_NAME/second.err" || fail wn12b-same-stderr
}

# ══ 13 실패 정책 — 통과가 우선 ════════════════════════════════════════════════

test_wn_13() { # [명세 실패 정책: 사이드카 기록 실패 → 알림 없이 조용히 통과] 상태 디렉토리 읽기 전용 → exit 0·알림 없음, 풀리면 낸다
  wn_root_skip && return 0
  local folder; folder=$(wn_task_dir readonly)
  wn_state auto 0 0 1 "$folder"
  wn_gitignore; : > "$STATE.lock"                    # 기존 판정(상태 검증)은 읽기 전용에서도 통과하게 준비(gt_06 관례)
  chmod 555 "$STATE_DIR"
  wn_gate PreToolUse Write "$REPO/src/a.c"
  local readonly_exit=$HOOK_EXIT readonly_stdout=$HOOK_STDOUT readonly_stderr=$HOOK_STDERR
  wn_gate PreToolUse Edit "$REPO/src/b.c"
  local readonly_exit_again=$HOOK_EXIT readonly_stdout_again=$HOOK_STDOUT readonly_stderr_again=$HOOK_STDERR
  chmod 755 "$STATE_DIR"
  HOOK_EXIT=$readonly_exit; HOOK_STDOUT=$readonly_stdout
  wn_assert_quiet 0 wn13-readonly-pass-no-notice     # 명세: 기록이 실패하면 알림을 내지 않는다(중복 대신 생략)
  HOOK_EXIT=$readonly_exit_again; HOOK_STDOUT=$readonly_stdout_again
  wn_assert_quiet 0 wn13-readonly-pass-again
  wn_assert_one_warning wn13-readonly "$readonly_stderr"
  wn_assert_one_warning wn13-readonly-again "$readonly_stderr_again"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn13-control-after-writable   # 실패한 호출은 "한 번"을 소비 못 했다
}

test_wn_13b() { # [명세 실패 정책: 잠금 실패 → 통과 우선] 상태 lock 밖의 flock 이 실패해도 exit 0·깨진 JSON 없음(잠금이 실패했으면 알림 없음)
  local folder; folder=$(wn_task_dir flock-fail)
  wn_state auto 0 0 1 "$folder"
  local fake="$SANDBOX/fakebin"; mkdir -p "$fake"
  local real_flock; real_flock=$(command -v flock) || fail wn13b-flock-missing
  local hits="$SANDBOX/flock.hits"; : > "$hits"
  local state_lock; state_lock=$(realpath -m -- "$STATE.lock")
  # 래퍼: 잠그려는 대상이 상태 lock 이면 진짜 flock(기존 판정 보존), 그 밖의 대상이면 기록 후 실패.
  cat > "$fake/flock" <<'WRAP'
#!/bin/bash
target=""
for argument in "$@"; do
  if [[ "$argument" =~ ^[0-9]+$ ]] && [ -e "/proc/$$/fd/$argument" ]; then target=$(readlink "/proc/$$/fd/$argument")
  elif [ -e "$argument" ]; then target=$(realpath -- "$argument"); fi
done
if [ -z "$target" ] || [ "$target" = "$WN_STATE_LOCK" ]; then exec "$WN_REAL_FLOCK" "$@"; fi
echo "$target" >> "$WN_FLOCK_HITS"
exit 1
WRAP
  chmod +x "$fake/flock"
  PATH="$fake:$PATH" WN_REAL_FLOCK="$real_flock" WN_FLOCK_HITS="$hits" WN_STATE_LOCK="$state_lock" \
    wn_gate PreToolUse Write "$REPO/src/a.c"
  assert_exit 0 wn13b-flock-fail-pass
  wn_assert_one_warning wn13b-flock-fail
  wn_assert_empty_or_notice wn13b-flock-fail
  # 재현 성립: 알림 기록이 상태 lock 과 다른 잠금(gate-guard.sh worker_notice 6b0a43c — <sidecar>.lock)을 잡다 실패했다.
  #   구현이 잠금 방식을 바꿔 래퍼가 안 걸리면 이 단언이 빨강으로 알린다(사례가 조용히 약해지지 않게).
  [ -s "$hits" ] || fail wn13b-lock-failure-reproduced
  if [ -s "$hits" ] && [ -n "$HOOK_STDOUT" ]; then           # 구현이 별도 잠금을 쓰다 실패했다면 알림은 없어야 한다
    echo "  [dbg] hits=$(head -c 160 "$hits")"; fail wn13b-lock-failed-but-noticed
  fi
  # 짝: 래퍼 없이 **같은 폴더** → 낸다. 잠금이 실패한 호출은 기록하지 못했으니 "한 번"을 소비하지 않았다
  #   (명세: 잠금 실패 → 알림 없이 통과. 기록이 없으니 다음 통과가 그 폴더의 첫 알림이다).
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn13b-control-real-flock-same-folder
}

test_wn_13c() { # [명세 실패 정책: JSON 생성 실패 → 통과 우선] jq -n 실패 → exit 0·깨진 JSON 없음·경고 한 줄·소비 안 함
  local folder; folder=$(wn_task_dir jq-fail)
  wn_state auto 0 0 1 "$folder"
  local fake="$SANDBOX/fakejq"; mkdir -p "$fake"
  local real_jq; real_jq=$(command -v jq) || fail wn13c-jq-missing
  # 래퍼: 입력 없이 JSON 을 만드는 호출(-n·--null-input, 묶음 짧은 옵션 포함)만 실패, 입력 파싱은 진짜 jq.
  local hits="$SANDBOX/jq.hits"; : > "$hits"
  cat > "$fake/jq" <<'WRAP'
#!/bin/bash
for argument in "$@"; do
  case "$argument" in
    --null-input) echo hit >> "$WN_JQ_HITS"; exit 5 ;;
    --*) ;;
    -*n*) echo hit >> "$WN_JQ_HITS"; exit 5 ;;
  esac
done
exec "$WN_REAL_JQ" "$@"
WRAP
  chmod +x "$fake/jq"
  # 입력 JSON 은 래퍼를 켜기 **전에** 만든다 — wn_json 도 jq -n 을 쓰므로, 래퍼 아래에서 만들면 훅이 빈 입력을 받아
  #   "파싱 실패 → 통과" 로 끝나 이 사례가 아무것도 시험하지 않는다(2026-11-21 감사에서 실측한 결함).
  local json; json=$(wn_json PreToolUse Write "$REPO/src/a.c")
  PATH="$fake:$PATH" WN_REAL_JQ="$real_jq" WN_JQ_HITS="$hits" wn_gate_json "$json"
  assert_exit 0 wn13c-jq-null-input-fail-pass
  wn_assert_one_warning wn13c-jq-null-input-fail
  wn_assert_empty_or_notice wn13c-jq-null-input-fail
  assert_stderr_no_match 'stdin JSON 파싱 실패' wn13c-input-parsed            # 재현 성립: 훅이 입력은 제대로 읽었다
  # 재현 성립: 알림 JSON 생성(jq -n — gate-guard.sh worker_notice 6b0a43c 의 구현 방식에 기댄다)에 래퍼가 걸렸다.
  #   구현이 jq -n 을 안 쓰게 바뀌면 이 단언이 빨강으로 알린다(조용히 약해지지 않게).
  [ -s "$hits" ] || fail wn13c-jq-null-input-reproduced
  # (TMPDIR 무효 부분은 지웠다 — 구현의 mktemp 가 상태 디렉토리를 직접 받아 아무것도 실패시키지 못했다. 임시 파일 실패는 wn_18.)
  local fresh; fresh=$(wn_task_dir jq-control)               # 짝: 정상 환경의 새 폴더 → 낸다
  wn_state auto 0 0 1 "$fresh"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn13c-control-normal
  # JSON 생성이 실패한 호출은 "한 번"을 소비하지 않는다 — 그 폴더로 돌아가 정상 환경이면 낸다.
  #   (판단: 명세 53행 "실패하면 알림을 내지 않고 조용히 통과" + 실패한 기록·잠금이 소비하지 않는 것(wn_13·13b)과 같은 규칙으로 본다.
  #    알림이 생략된 채 기억만 남으면 그 폴더에서는 영영 안 뜬다.)
  wn_state auto 0 0 1 "$folder"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn13c-jq-fail-not-consumed
}

# ══ 14 동시 호출 ═══════════════════════════════════════════════════════════

test_wn_14() { # [명세 동시에 들어온 호출 중 하나만 낸다("이미 냈나 확인 → 기록"이 한 잠금 안)] 8개 동시 → 알림 정확히 1개, 전부 exit 0
  local folder; folder=$(wn_task_dir concurrent)
  wn_state auto 0 0 1 "$folder"
  local json; json=$(wn_json PreToolUse Write "$REPO/src/a.c")
  local race="$SANDBOX/race"; mkdir -p "$race"
  local pids="" index process
  for index in 1 2 3 4 5 6 7 8; do
    (
      set +e
      printf '%s' "$json" | env HOME="$HOME_DIR" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
        XDG_CONFIG_HOME="$XDG_DIR" bash "$HOOKS_DIR/gate-guard.sh" > "$race/out.$index" 2> "$race/err.$index"
      echo $? > "$race/exit.$index"
    ) &
    pids="$pids $!"
  done
  for process in $pids; do wait "$process" || true; done
  local notices=0 output
  for index in 1 2 3 4 5 6 7 8; do
    [ "$(cat "$race/exit.$index" 2>/dev/null)" = "0" ] || { echo "  [dbg] #$index exit=$(cat "$race/exit.$index" 2>/dev/null)"; fail wn14-all-exit-0; }
    output=$(cat "$race/out.$index")
    if [ -n "$output" ]; then
      wn_is_notice "$output" || { echo "  [dbg] #$index stdout=$(printf '%s' "$output" | head -c 160)"; fail wn14-wellformed; }
      notices=$((notices + 1))
    fi
  done
  [ "$notices" = "1" ] || { echo "  [dbg] notices=$notices"; fail wn14-exactly-one-notice; }
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 0 wn14-after-race-quiet
  assert_single_line SCHEMA wn14-schema-single
  assert_state SCHEMA 4 wn14-schema-intact
}

test_wn_14b() { # [명세 "이미 냈나 확인 → 기록"이 한 잠금 안] 확인과 기록 사이를 넓혀도 동시 8개 중 알림은 정확히 1개
  # 왜 따로 있나: wn_14 만으로는 잠금을 빼도 통과한다(구현 뮤테이션 실측 40/40) — 8개 호출이 앞의 상태 lock 에서
  #   직렬화된 뒤 경로 길이가 거의 같아, 호출 사이 간격이 "확인 → 기록" 창(몇 ms)보다 길다. 그래서 창을 넓힌다.
  # 방법: PATH 앞의 mktemp 래퍼가 **상태 디렉토리 안** 임시 파일을 만들 때만 WN_MKTEMP_DELAY 초 잔 뒤 진짜 mktemp 를 부른다.
  #   이 경로(유효 상태 + .gitignore 있음)에서 상태 디렉토리에 mktemp 를 쓰는 것은 알림 기록뿐이다(state_ensure_valid 는
  #   유효 상태에 쓰지 않고, .gitignore 는 미리 둔다). 잠금이 없으면 8개가 모두 "아직 안 냄"을 확인한 채 잠들어 여럿이 낸다.
  # 구현 의존(이름 무관 원칙의 예외 — 이 사례만): "기록이 상태 디렉토리의 mktemp 임시 파일 → mv" 라는 구현 방식에 기댄다
  #   (gate-guard.sh worker_notice, 6b0a43c). 파일 이름에는 기대지 않는다. 구현이 mktemp 를 안 쓰게 바뀌면 래퍼가 걸리지
  #   않아 이 사례가 조용히 약해지므로, 래퍼가 실제로 걸렸는지(재현 성립)를 먼저 단언한다 — 그때는 빨강으로 알린다.
  # 지연 길이 근거: 1.5초. ① 거짓 초록 방지 — 잠금이 없을 때 빨강이 되려면 두 호출이 첫 호출의 기록(mv) 전에 확인만
  #   하면 된다. 8개의 도착 간격(실측 수십~수백 ms)보다 1.5초가 몇 배 길어 느린 기계에서도 둘 이상이 창 안에 든다.
  #   ② 거짓 빨강 방지 — 잠금이 있으면 첫 호출이 잠금을 쥔 채 1.5초 자고, 나머지는 flock -w 2 로 기다리다 "이미 냄"을 본다.
  #   느린 기계에서 대기가 2초를 넘어도 그 호출은 "기록 실패 → 알림 생략"이라 알림은 늘지 않는다(1개 유지) — 지연이
  #   길어질수록 알림이 줄 수는 있어도 늘 수는 없어, 초록 판정은 시간에 기대지 않는다. 0개도 실패로 본다(첫 호출은
  #   잠금 대기 없이 기록하므로 정상 구현에서 0개는 나오지 않는다).
  local folder; folder=$(wn_task_dir concurrent-widened)
  wn_state auto 0 0 1 "$folder"
  wn_gitignore
  local json; json=$(wn_json PreToolUse Write "$REPO/src/a.c")
  local fake="$SANDBOX/fakemktemp"; mkdir -p "$fake"
  local real_mktemp; real_mktemp=$(command -v mktemp) || fail wn14b-mktemp-missing
  local hits="$SANDBOX/mktemp.hits"; : > "$hits"
  cat > "$fake/mktemp" <<'WRAP'
#!/bin/bash
for argument in "$@"; do
  case "$argument" in
    "$WN_STATE_DIR"/*) echo "$argument" >> "$WN_MKTEMP_HITS"; sleep "$WN_MKTEMP_DELAY"; break ;;
  esac
done
exec "$WN_REAL_MKTEMP" "$@"
WRAP
  chmod +x "$fake/mktemp"
  local race="$SANDBOX/race-widened"; mkdir -p "$race"
  local pids="" index process
  for index in 1 2 3 4 5 6 7 8; do
    (
      set +e
      printf '%s' "$json" | env HOME="$HOME_DIR" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
        XDG_CONFIG_HOME="$XDG_DIR" PATH="$fake:$PATH" WN_REAL_MKTEMP="$real_mktemp" WN_MKTEMP_HITS="$hits" \
        WN_MKTEMP_DELAY=1.5 WN_STATE_DIR="$STATE_DIR" \
        bash "$HOOKS_DIR/gate-guard.sh" > "$race/out.$index" 2> "$race/err.$index"
      echo $? > "$race/exit.$index"
    ) &
    pids="$pids $!"
  done
  for process in $pids; do wait "$process" || true; done
  [ -s "$hits" ] || fail wn14b-widening-reproduced       # 래퍼가 기록 단계에 걸리지 않았다 = 창을 못 넓힘(사례 무력)
  local notices=0 output
  for index in 1 2 3 4 5 6 7 8; do
    [ "$(cat "$race/exit.$index" 2>/dev/null)" = "0" ] || { echo "  [dbg] #$index exit=$(cat "$race/exit.$index" 2>/dev/null)"; fail wn14b-all-exit-0; }
    output=$(cat "$race/out.$index")
    if [ -n "$output" ]; then
      wn_is_notice "$output" || { echo "  [dbg] #$index stdout=$(printf '%s' "$output" | head -c 160)"; fail wn14b-wellformed; }
      notices=$((notices + 1))
    fi
  done
  [ "$notices" = "1" ] || { echo "  [dbg] notices=$notices hits=$(wc -l < "$hits")"; fail wn14b-exactly-one-notice-widened; }
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 0 wn14b-after-race-quiet
}

# ══ 15 상태파일 불변 · 사이드카 자리 ═══════════════════════════════════════════

test_wn_15() { # [명세 기억하는 곳: 상태파일·SCHEMA=4·set-state 키는 건드리지 않는다] 알림 전후 상태파일 바이트 동일(짝: 알림이 실제로 나감)
  local folder; folder=$(wn_task_dir state-intact)
  wn_state auto 0 0 1 "$folder"
  cp "$STATE" "$SANDBOX/state.before"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn15-notice
  cmp -s "$SANDBOX/state.before" "$STATE" || { echo "  [dbg] after=$(tr '\n' ' ' < "$STATE")"; fail wn15-state-bytes-unchanged; }
  wn_gate PreToolUse Edit "$REPO/src/a.c"; wn_assert_quiet 0 wn15-second
  cmp -s "$SANDBOX/state.before" "$STATE" || fail wn15-state-bytes-unchanged-second
  if ls -d "$STATE".corrupt-* >/dev/null 2>&1; then fail wn15-no-quarantine; fi
}

test_wn_15b() { # [명세 사이드카는 상태 디렉토리 안 · 기존 보호(gitignore)를 우회하지 않는다] 상태 디렉토리 밖에 새 파일 없음 · git status 불변
  local folder; folder=$(wn_task_dir no-leak)
  wn_state auto 0 0 1 "$folder"
  wn_gitignore
  mkdir -p "$REPO/src"
  local capture="$SANDBOX/$WN_CAPTURE_DIR_NAME"; mkdir -p "$capture"        # 관찰 기록은 목록에서 빠지는 캡처 폴더에
  git -C "$REPO" status --porcelain=v1 -uall > "$capture/git-status.before" 2>/dev/null
  wn_paths_outside_state_dir "$capture/paths.before"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn15b-notice
  wn_paths_outside_state_dir "$capture/paths.after"
  git -C "$REPO" status --porcelain=v1 -uall > "$capture/git-status.after" 2>/dev/null
  diff -q "$capture/paths.before" "$capture/paths.after" >/dev/null \
    || { echo "  [dbg] new=$(comm -13 "$capture/paths.before" "$capture/paths.after" | head -3 | tr '\n' ' ')"; fail wn15b-no-file-outside-state-dir; }
  cmp -s "$capture/git-status.before" "$capture/git-status.after" \
    || { echo "  [dbg] status=$(head -c 200 "$capture/git-status.after")"; fail wn15b-git-status-unchanged; }
  if grep -q '\.claude' "$capture/git-status.after"; then fail wn15b-no-claude-in-git-status; fi
}

test_wn_15c() { # [명세 기억하는 곳 = 세션 상태 디렉토리의 사이드카] 상태 디렉토리의 덧붙은 파일을 지우면 같은 폴더에서 다시 낸다
  # 이름을 모르는 사이드카를 관찰하는 방법: 상태파일·.gitignore 만 남기고 지우면 기억이 사라져야 한다(다른 곳에 기억하지 않는다).
  local folder; folder=$(wn_task_dir sidecar-place)
  wn_state auto 0 0 1 "$folder"
  wn_gitignore
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn15c-first
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 0 wn15c-remembered
  find "$STATE_DIR" -mindepth 1 -maxdepth 1 ! -name "$SID" ! -name '.gitignore' -exec rm -rf {} + 2>/dev/null || true
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn15c-forgotten-after-sidecar-removed
}

test_wn_15d() { # [명세 사이드카는 세션 상태 디렉토리 — 해소된 위치] cwd 가 하위 디렉토리여도 루트 상태를 쓰고 하위에 .claude 를 만들지 않는다
  local folder; folder=$(wn_task_dir subdir-cwd)
  wn_state auto 0 0 1 "$folder"
  mkdir -p "$REPO/sub/deep"
  wn_gate PreToolUse Write "$REPO/src/a.c" none "$SID" "$REPO/sub/deep"; wn_assert_notice wn15d-subdir-cwd-notice
  [ ! -e "$REPO/sub/deep/.claude" ] || fail wn15d-no-subdir-sidecar
  [ ! -e "$REPO/sub/.claude" ] || fail wn15d-no-sub-sidecar
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_quiet 0 wn15d-root-cwd-same-memory   # 같은 상태 디렉토리 = 같은 기억
}

# ══ 16·17 리뷰 루프 1 채택 지적 — 구현 전에 쓴 사례(S1·S2) ═══════════════════════════
# 이름 의존: 아래 16·19 계열은 구현의 사이드카 이름 `<sid>.worker-notice`·잠금 `<sid>.worker-notice.lock`
#   (gate-guard.sh worker_notice, 6b0a43c)에 기댄다 — 그 자리에 심링크·디렉토리·FIFO 를 미리 두려면 이름이 필요하다.
#   이름이 바뀌면 이 사례들을 함께 고친다. 각 사례는 "미리 둔 것이 실제로 그 자리에 있었다"를 재현 단언으로 확인한다.
wn_notice_sidecar_path() { printf '%s/%s.worker-notice' "$STATE_DIR" "$SID"; }
# 디렉토리의 경로·종류·크기·mtime(ns)·내용 해시 목록 — 바깥 파일이 생기거나 바뀌지 않았는지 보는 데 쓴다.
wn_snapshot_dir() { # <dir> <출력 파일>
  { find "$1" -printf '%p %y %s %T@\n' 2>/dev/null | LC_ALL=C sort
    find "$1" -type f -exec sha256sum {} + 2>/dev/null | LC_ALL=C sort; } > "$2"
}
wn_assert_snapshot_same() { # <before> <after> <assert-id>
  cmp -s "$1" "$2" || { echo "  [dbg] 바뀜: $(diff "$1" "$2" | head -4 | tr '\n' ' ')"; fail "$3"; }
}
# 실패 래퍼: 인자 중 하나가 상태 디렉토리 안 경로면 기록 후 실패, 아니면 진짜 명령. → WN_FAIL_BIN(PATH 앞에 둘 디렉토리)
#   이 경로(유효 상태 + .gitignore 있음 — 사례가 미리 둔다)에서 상태 디렉토리를 인자로 mktemp·mv 를 부르는 것은 알림 기록뿐이다.
wn_fail_wrapper() { # <명령 이름>
  WN_FAIL_BIN="$SANDBOX/fail-$1"; mkdir -p "$WN_FAIL_BIN"
  WN_FAIL_HITS="$SANDBOX/fail-$1.hits"; : > "$WN_FAIL_HITS"
  local real; real=$(command -v "$1") || fail "wrapper-real-$1-missing"
  cat > "$WN_FAIL_BIN/$1" <<WRAP
#!/bin/bash
for argument in "\$@"; do
  case "\$argument" in
    "\$WN_STATE_DIR"/*) echo "\$argument" >> "$WN_FAIL_HITS"; exit 1 ;;
  esac
done
exec "$real" "\$@"
WRAP
  chmod +x "$WN_FAIL_BIN/$1"
}

test_wn_16() { # [S1 · 명세 기억하는 곳 — 상태 디렉토리의 기존 보호(심링크)를 우회하지 않는다] 알림 잠금 자리가 바깥의 **없는** 파일을 가리키는 심링크
  # 고정: exit 0 · 바깥에 새 파일이 생기지 않는다 · 알림 없음(stdout 0바이트) · 경고 한 줄 · 심링크를 치우면 같은 폴더에서 낸다(소비 안 함).
  local folder; folder=$(wn_task_dir lock-link-absent)
  wn_state auto 0 0 1 "$folder"; wn_gitignore
  local outside="$SANDBOX/outside-lock"; mkdir -p "$outside"
  ln -s "$outside/absent.lock" "$(wn_notice_sidecar_path).lock"
  [ -L "$(wn_notice_sidecar_path).lock" ] || fail wn16-precondition-link        # 재현 성립
  wn_snapshot_dir "$outside" "$SANDBOX/outside.before"
  wn_gate PreToolUse Write "$REPO/src/a.c"
  wn_snapshot_dir "$outside" "$SANDBOX/outside.after"
  [ ! -e "$outside/absent.lock" ] || fail wn16-no-file-created-outside
  wn_assert_snapshot_same "$SANDBOX/outside.before" "$SANDBOX/outside.after" wn16-outside-unchanged
  wn_assert_quiet 0 wn16-lock-link-no-notice
  wn_assert_one_warning wn16-lock-link
  rm -f "$(wn_notice_sidecar_path).lock"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn16-not-consumed-after-link-removed
}

test_wn_16b() { # [S1] 알림 잠금 자리가 바깥의 **있는** 파일을 가리키는 심링크 → 그 파일의 내용·mtime 불변, 알림 없음, 경고 한 줄, 소비 안 함
  local folder; folder=$(wn_task_dir lock-link-existing)
  wn_state auto 0 0 1 "$folder"; wn_gitignore
  local outside="$SANDBOX/outside-lock"; mkdir -p "$outside"
  printf 'keep me\n' > "$outside/existing.lock"
  touch -d '2 days ago' "$outside/existing.lock"
  ln -s "$outside/existing.lock" "$(wn_notice_sidecar_path).lock"
  [ -L "$(wn_notice_sidecar_path).lock" ] || fail wn16b-precondition-link
  wn_snapshot_dir "$outside" "$SANDBOX/outside.before"
  wn_gate PreToolUse Write "$REPO/src/a.c"
  wn_snapshot_dir "$outside" "$SANDBOX/outside.after"
  wn_assert_snapshot_same "$SANDBOX/outside.before" "$SANDBOX/outside.after" wn16b-outside-content-mtime-unchanged
  wn_assert_quiet 0 wn16b-lock-link-no-notice
  wn_assert_one_warning wn16b-lock-link
  rm -f "$(wn_notice_sidecar_path).lock"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn16b-not-consumed-after-link-removed
}

# stdout 을 쓸 수 없는 상태로 훅을 부른다. mode: full(/dev/full — 쓰기가 ENOSPC 로 실패) | closed(>&- — 쓰기가 EBADF 로 실패)
wn_run_unwritable_stdout() { # <mode> <json> → HOOK_EXIT · HOOK_STDERR
  local err="$SANDBOX/$WN_CAPTURE_DIR_NAME/unwritable.err"; mkdir -p "$SANDBOX/$WN_CAPTURE_DIR_NAME"
  set +e
  if [ "$1" = "full" ]; then
    printf '%s' "$2" | env HOME="$HOME_DIR" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
      XDG_CONFIG_HOME="$XDG_DIR" bash "$HOOKS_DIR/gate-guard.sh" > /dev/full 2> "$err"
  else
    printf '%s' "$2" | env HOME="$HOME_DIR" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
      XDG_CONFIG_HOME="$XDG_DIR" bash "$HOOKS_DIR/gate-guard.sh" >&- 2> "$err"
  fi
  HOOK_EXIT=$?
  set -e
  HOOK_STDERR=$(cat "$err")
}
# 재현 성립: 이 환경에서 그 방식이 bash 의 printf(훅의 출력 명령)를 실제로 실패시키나
wn_assert_unwritable_reproduces() { # <mode> <assert-id>
  local rc
  set +e
  if [ "$1" = "full" ]; then bash -c 'printf "%s\n" x' > /dev/full 2>/dev/null; rc=$?
  else bash -c 'printf "%s\n" x' >&- 2>/dev/null; rc=$?; fi
  set -e
  [ "$rc" != "0" ] || fail "$2"
}

test_wn_17() { # [S2 · 명세 실패한 호출은 "한 번"을 소비하지 않는다] stdout 이 /dev/full(출력 실패) → exit 0 · 경고 한 줄 · 정상 stdout 의 다음 호출에 알림
  [ -w /dev/full ] || return 0                                               # /dev/full 없는 환경은 wn_17b 가 같은 계약을 본다
  wn_assert_unwritable_reproduces full wn17-precondition-printf-fails
  local folder; folder=$(wn_task_dir stdout-full)
  wn_state auto 0 0 1 "$folder"; wn_gitignore
  wn_run_unwritable_stdout full "$(wn_json PreToolUse Write "$REPO/src/a.c")"
  assert_exit 0 wn17-full-exit
  wn_assert_one_warning wn17-full
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn17-not-consumed-after-output-failure
}

test_wn_17b() { # [S2] stdout 이 닫힘(>&-) → exit 0 · 경고 한 줄 · 정상 stdout 의 다음 호출에 알림
  wn_assert_unwritable_reproduces closed wn17b-precondition-printf-fails
  local folder; folder=$(wn_task_dir stdout-closed)
  wn_state auto 0 0 1 "$folder"; wn_gitignore
  wn_run_unwritable_stdout closed "$(wn_json PreToolUse Write "$REPO/src/a.c")"
  assert_exit 0 wn17b-closed-exit
  wn_assert_one_warning wn17b-closed
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn17b-not-consumed-after-output-failure
}

# ══ 18·19 실패 경로의 fix verification(S3 — 구현 뒤 작성, 이름 의존 허용) ═════════════════

test_wn_18() { # [S3① · 명세 실패 정책] 기록용 임시 파일(mktemp) 실패 → exit 0 · stdout 0바이트 · 경고 한 줄 · 소비 안 함
  local folder; folder=$(wn_task_dir mktemp-fail)
  wn_state auto 0 0 1 "$folder"; wn_gitignore
  wn_fail_wrapper mktemp
  local json; json=$(wn_json PreToolUse Write "$REPO/src/a.c")
  PATH="$WN_FAIL_BIN:$PATH" WN_STATE_DIR="$STATE_DIR" wn_gate_json "$json"
  [ -s "$WN_FAIL_HITS" ] || fail wn18-mktemp-failure-reproduced              # 재현 성립: 기록 단계의 mktemp 가 실제로 실패했다
  wn_assert_quiet 0 wn18-mktemp-fail-no-notice
  wn_assert_one_warning wn18-mktemp-fail
  [ ! -e "$(wn_notice_sidecar_path)" ] || fail wn18-no-sidecar-written
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn18-not-consumed
}

test_wn_18b() { # [S3 실패 시 임시 파일 정리] 기록의 mv 실패 → exit 0 · 알림 없음 · 경고 한 줄 · 임시 파일 잔재 없음 · 소비 안 함
  local folder; folder=$(wn_task_dir mv-fail)
  wn_state auto 0 0 1 "$folder"; wn_gitignore
  wn_fail_wrapper mv
  local json; json=$(wn_json PreToolUse Write "$REPO/src/a.c")
  PATH="$WN_FAIL_BIN:$PATH" WN_STATE_DIR="$STATE_DIR" wn_gate_json "$json"
  [ -s "$WN_FAIL_HITS" ] || fail wn18b-mv-failure-reproduced
  wn_assert_quiet 0 wn18b-mv-fail-no-notice
  wn_assert_one_warning wn18b-mv-fail
  # 이름 의존: 임시 파일 형판 `.worker-notice.XXXXXX`(구현 6b0a43c). 잔재가 없어야 한다.
  local leftovers; leftovers=$(find "$STATE_DIR" -maxdepth 1 -name '.worker-notice.*' 2>/dev/null | head -3)
  [ -z "$leftovers" ] || { echo "  [dbg] 잔재=$leftovers"; fail wn18b-no-temporary-leftover; }
  [ ! -e "$(wn_notice_sidecar_path)" ] || fail wn18b-no-sidecar-written
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn18b-not-consumed
}

test_wn_19() { # [S3② · 명세 심링크 보호] 사이드카 자리가 바깥 파일을 가리키는 심링크 → exit 0 · 알림 없음 · 바깥 파일 무변경 · 경고 한 줄
  local folder; folder=$(wn_task_dir sidecar-link)
  wn_state auto 0 0 1 "$folder"; wn_gitignore
  local outside="$SANDBOX/outside-sidecar"; mkdir -p "$outside"
  printf 'other\n' > "$outside/notice"; touch -d '2 days ago' "$outside/notice"
  ln -s "$outside/notice" "$(wn_notice_sidecar_path)"
  [ -L "$(wn_notice_sidecar_path)" ] || fail wn19-precondition-link
  wn_snapshot_dir "$outside" "$SANDBOX/outside.before"
  wn_gate PreToolUse Write "$REPO/src/a.c"
  wn_snapshot_dir "$outside" "$SANDBOX/outside.after"
  wn_assert_snapshot_same "$SANDBOX/outside.before" "$SANDBOX/outside.after" wn19-outside-unchanged
  wn_assert_quiet 0 wn19-sidecar-link-no-notice
  wn_assert_one_warning wn19-sidecar-link
  [ -L "$(wn_notice_sidecar_path)" ] || fail wn19-link-left-alone                # 그 너머로도, 그 자리에도 쓰지 않는다
}

test_wn_19b() { # [S3②] 사이드카 자리가 디렉토리 → exit 0 · 알림 없음 · 경고 한 줄 · 디렉토리 안에 아무것도 생기지 않음
  local folder; folder=$(wn_task_dir sidecar-dir)
  wn_state auto 0 0 1 "$folder"; wn_gitignore
  mkdir "$(wn_notice_sidecar_path)"
  [ -d "$(wn_notice_sidecar_path)" ] || fail wn19b-precondition-dir
  wn_gate PreToolUse Write "$REPO/src/a.c"
  wn_assert_quiet 0 wn19b-sidecar-dir-no-notice
  wn_assert_one_warning wn19b-sidecar-dir
  [ -z "$(ls -A "$(wn_notice_sidecar_path)")" ] || fail wn19b-dir-left-empty
}

test_wn_19c() { # [S3②] 사이드카 자리가 FIFO → 막히지 않고 exit 0 · 알림 없음 · 경고 한 줄 (읽기를 시도하면 막힌다 — 시간 제한으로 걸러낸다)
  local folder; folder=$(wn_task_dir sidecar-fifo)
  wn_state auto 0 0 1 "$folder"; wn_gitignore
  mkfifo "$(wn_notice_sidecar_path)" || fail wn19c-mkfifo
  [ -p "$(wn_notice_sidecar_path)" ] || fail wn19c-precondition-fifo
  # 시간 제한 30초: 정상 경로는 1초 안쪽(실측). 넘으면 timeout 이 124 를 내 exit 단언이 빨강이 된다(막힘 = 실패).
  WN_TIMEOUT=30 wn_gate PreToolUse Write "$REPO/src/a.c"
  wn_assert_quiet 0 wn19c-sidecar-fifo-no-notice
  wn_assert_one_warning wn19c-sidecar-fifo
}

test_wn_19d() { # [S3③] 사이드카 읽기 실패(권한 000) → exit 0 · 알림 없음 · 경고 한 줄 · 권한이 돌아오면 같은 폴더에서 낸다(소비 안 함)
  wn_root_skip && return 0
  local folder; folder=$(wn_task_dir sidecar-unreadable)
  wn_state auto 0 0 1 "$folder"; wn_gitignore
  printf '%s\n' "$REPO/docs/plans/2026-11-21/some-other-folder" > "$(wn_notice_sidecar_path)"   # 다른 폴더만 기억
  chmod 000 "$(wn_notice_sidecar_path)"
  [ ! -r "$(wn_notice_sidecar_path)" ] || { chmod 644 "$(wn_notice_sidecar_path)"; fail wn19d-precondition-unreadable; }
  wn_gate PreToolUse Write "$REPO/src/a.c"
  chmod 644 "$(wn_notice_sidecar_path)"
  wn_assert_quiet 0 wn19d-unreadable-no-notice
  wn_assert_one_warning wn19d-unreadable
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn19d-not-consumed
}
