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
    XDG_CONFIG_HOME="$XDG_DIR" bash "$1" > "$capture/$tag.out" 2> "$capture/$tag.err"
  HOOK_EXIT=$?
  set -e
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
}
# stdout 이 비었거나 알림 JSON 하나 — 깨진 JSON·JSON 둘 이어 붙임 금지(실패 정책 사례용)
wn_assert_empty_or_notice() { # <assert-id>
  if [ -n "$HOOK_STDOUT" ] && ! wn_is_notice "$HOOK_STDOUT"; then
    echo "  [dbg] stdout=$(printf '%s' "$HOOK_STDOUT" | head -c 240)"; fail "$1-wellformed"
  fi
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
  wn_gate PreToolUse Edit "$REPO/src/b.c"
  wn_assert_quiet 0 wn02-second-edit
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
  local readonly_exit=$HOOK_EXIT readonly_stdout=$HOOK_STDOUT
  wn_gate PreToolUse Edit "$REPO/src/b.c"
  local readonly_exit_again=$HOOK_EXIT readonly_stdout_again=$HOOK_STDOUT
  chmod 755 "$STATE_DIR"
  HOOK_EXIT=$readonly_exit; HOOK_STDOUT=$readonly_stdout
  wn_assert_quiet 0 wn13-readonly-pass-no-notice     # 명세: 기록이 실패하면 알림을 내지 않는다(중복 대신 생략)
  HOOK_EXIT=$readonly_exit_again; HOOK_STDOUT=$readonly_stdout_again
  wn_assert_quiet 0 wn13-readonly-pass-again
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
  wn_assert_empty_or_notice wn13b-flock-fail
  if [ -s "$hits" ] && [ -n "$HOOK_STDOUT" ]; then           # 구현이 별도 잠금을 쓰다 실패했다면 알림은 없어야 한다
    echo "  [dbg] hits=$(head -c 160 "$hits")"; fail wn13b-lock-failed-but-noticed
  fi
  local fresh; fresh=$(wn_task_dir flock-control)            # 짝: 래퍼 없이 새 폴더 → 낸다
  wn_state auto 0 0 1 "$fresh"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn13b-control-real-flock
}

test_wn_13c() { # [명세 실패 정책: JSON 생성 실패·임시 파일 실패 → 통과 우선] jq -n 실패 · TMPDIR 무효 → exit 0·깨진 JSON 없음
  local folder; folder=$(wn_task_dir jq-fail)
  wn_state auto 0 0 1 "$folder"
  local fake="$SANDBOX/fakejq"; mkdir -p "$fake"
  local real_jq; real_jq=$(command -v jq) || fail wn13c-jq-missing
  # 래퍼: 입력 없이 JSON 을 만드는 호출(-n·--null-input, 묶음 짧은 옵션 포함)만 실패, 입력 파싱은 진짜 jq.
  cat > "$fake/jq" <<'WRAP'
#!/bin/bash
for argument in "$@"; do
  case "$argument" in
    --null-input) exit 5 ;;
    --*) ;;
    -*n*) exit 5 ;;
  esac
done
exec "$WN_REAL_JQ" "$@"
WRAP
  chmod +x "$fake/jq"
  PATH="$fake:$PATH" WN_REAL_JQ="$real_jq" wn_gate PreToolUse Write "$REPO/src/a.c"
  assert_exit 0 wn13c-jq-null-input-fail-pass
  wn_assert_empty_or_notice wn13c-jq-null-input-fail
  local folder_tmp; folder_tmp=$(wn_task_dir tmpdir-fail)
  wn_state auto 0 0 1 "$folder_tmp"
  TMPDIR="$SANDBOX/no-such-tmpdir" wn_gate PreToolUse Write "$REPO/src/a.c"
  assert_exit 0 wn13c-bad-tmpdir-pass
  wn_assert_empty_or_notice wn13c-bad-tmpdir
  local fresh; fresh=$(wn_task_dir jq-control)               # 짝: 정상 환경의 새 폴더 → 낸다
  wn_state auto 0 0 1 "$fresh"
  wn_gate PreToolUse Write "$REPO/src/a.c"; wn_assert_notice wn13c-control-normal
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
