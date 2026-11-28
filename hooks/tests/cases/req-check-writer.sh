# req-check-writer.sh — task-mode-guard 가 요구 대조 사이드카에 쓰는 쪽 · 워커의 Write 를 게이트에서 가르는 것 (task 05)
# 계약 정본: docs/plans/2026-11-27/close-out-requirement-check/requirement-spec.md 2절(Q8 (가)) · 6.1 ②(Q7 (나)) · 9절 task 05
#            + task 05 브리핑의 조항 1 ~ 4. 읽는 쪽(state_reqcheck_paths)은 task 04 — cases/req-check-gate.sh.
# 설계: blind 테스트 워커(구현 미열람 — 계약에서 출발). 테스트 이름의 앞머리 = 조항(a = 1 워커 · b = 2 사이드카 ·
#   c = 3 종전과 같음 · d = 4 읽는 쪽과의 맞물림)과 번호.
# "종전과 같다" = 기준 커밋(RW_BASE_SHA — task 05 착수 직전)의 task-mode-guard · state-lib 사본
#   (hooks/tests/fixtures/legacy-d38839a/ — 그 커밋의 hooks/<파일> 그대로)을 같은 입력으로 돌린 값.
#   git 을 쓰지 않는다(배포 사본에서도 돈다 — req-check-gate.sh 의 legacy 관례와 같다).
#   비교 = 종료 코드 · stdout 바이트 · stderr 바이트 · 실행 뒤 상태파일 바이트 · 상태 디렉토리의 파일 목록(*.lock 제외).

RW_BASE_SHA=d38839a
RW_LEGACY_SOURCE="$TESTS_DIR/fixtures/legacy-d38839a"
RW_RESET_MSG='새 작업 폴더 감지'

# ── 셋업 ────────────────────────────────────────────────────────────────────────
rw_sidecar() { printf '%s' "$STATE_DIR/$SID.req-check-paths"; }
rw_folder() { # <저장소 루트> <이름> → stdout: 작업 폴더(canonical 절대 경로) — 폴더와 log.md · requirement-spec.md 를 만든다
  local folder
  mkdir -p "$1/docs/plans/2026-11-28/$2"
  folder=$(realpath -- "$1/docs/plans/2026-11-28/$2")
  printf 'l\n' > "$folder/log.md"; printf 's\n' > "$folder/requirement-spec.md"
  printf '%s' "$folder"
}
rw_state() { # <MODE> <SPEC> <PENDING> <DEBT> [TASK_PATH] — SCHEMA=4 상태파일을 새로 쓴다
  { echo "SCHEMA=4"; echo "MODE=$1"; echo "SPEC=$2"; echo "PENDING_GATE=$3"; echo "DEBT=$4"
    [ -z "${5:-}" ] || echo "TASK_PATH=$5"; } > "$STATE"
}
# agent 인자: none = agent_id 키 없음 · empty = "" · null = null · 그 밖 = 워커 agent_id 값(+agent_type)
rw_json() { # <tool> <file_path> [agent] [cwd]
  jq -cn --arg t "$1" --arg f "$2" --arg agent "${3:-none}" --arg c "${4:-$REPO}" --arg s "$SID" '
    {session_id:$s, cwd:$c, permission_mode:"auto", hook_event_name:"PostToolUse", tool_name:$t,
     tool_input:({file_path:$f} + (if $t == "Write" then {content:"x"} else {old_string:"a", new_string:"b"} end)),
     tool_response:{filePath:$f}, tool_use_id:"toolu_rw"}
    + (if $agent == "none" then {}
       elif $agent == "empty" then {agent_id:""}
       elif $agent == "null" then {agent_id:null}
       else {agent_id:$agent, agent_type:"general-purpose"} end)'
}
rw_run() { # <hook 절대경로> <json> [태그] → HOOK_EXIT · HOOK_STDOUT · HOOK_STDERR (+ 캡처 파일)
  local capture="$SANDBOX/rw-capture" tag="${3:-last}"
  mkdir -p "$capture"
  set +e
  printf '%s' "$2" | env HOME="$HOME_DIR" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
    XDG_CONFIG_HOME="$XDG_DIR" bash "$1" > "$capture/$tag.out" 2> "$capture/$tag.err"
  HOOK_EXIT=$?
  set -e
  HOOK_STDOUT=$(cat "$capture/$tag.out")
  HOOK_STDERR=$(cat "$capture/$tag.err")
}
rw_tmg() { rw_run "$HOOKS_DIR/task-mode-guard.sh" "$(rw_json "$@")" "${RW_TAG:-last}"; }   # <tool> <file_path> [agent] [cwd]

rw_listing() { (cd "$STATE_DIR" && find . -mindepth 1 ! -name '*.lock' -printf '%P %y\n' | LC_ALL=C sort); }
rw_dbg_sidecar() {
  local sc; sc=$(rw_sidecar)
  echo "  [dbg] sidecar=$( { [ -e "$sc" ] || [ -L "$sc" ]; } && od -c "$sc" 2>/dev/null | head -6 | tr '\n' '~' || echo ABSENT) stderr=$(printf '%s' "$HOOK_STDERR" | head -c 240)"
}
rw_assert_sidecar() { # <id> <줄...> — 사이드카가 정규 파일이고 내용이 그 줄들(줄마다 끝 개행) 바이트 그대로
  local id=$1; shift
  local sc want_file="$SANDBOX/rw-want"
  sc=$(rw_sidecar)
  printf '%s\n' "$@" > "$want_file"
  { [ -f "$sc" ] && [ ! -L "$sc" ]; } || { rw_dbg_sidecar; fail "$id-regular"; }
  cmp -s "$sc" "$want_file" || { rw_dbg_sidecar; echo "  [dbg] want=$(od -c "$want_file" | head -6 | tr '\n' '~')"; fail "$id-bytes"; }
}
rw_assert_no_sidecar() { # <id>
  local sc; sc=$(rw_sidecar)
  if [ -e "$sc" ] || [ -L "$sc" ]; then rw_dbg_sidecar; fail "$id"; fi
}
rw_assert_no_temp_left() { # <id> — 상태 디렉토리에 임시 파일(점 파일 — state-lib 의 .gitignore 제외 · 사이드카 이름 뒤에 군더더기가 붙은 파일)이 남지 않았다
  local left
  left=$(cd "$STATE_DIR" && find . -mindepth 1 -maxdepth 1 \( \( -name '.*' ! -name .gitignore \) -o \( -name "$SID.req-check-paths?*" ! -name '*.lock' \) \) -printf '%P\n')
  [ -z "$left" ] || { echo "  [dbg] left=$(printf '%s' "$left" | tr '\n' '~')"; fail "$id"; }
}
rw_assert_state_bytes_same() { # <before 파일> <id>
  cmp -s "$1" "$STATE" || { echo "  [dbg] before=$(tr '\n' '~' < "$1") after=$(tr '\n' '~' < "$STATE" 2>/dev/null)"; fail "$2"; }
}

# ── 기준 커밋(사이드카 · 워커 판별 없음)과의 비교 ───────────────────────────────────
rw_legacy_init() {
  RW_LEGACY_DIR="$SANDBOX/legacy-rw"
  [ -d "$RW_LEGACY_DIR" ] && return 0
  mkdir -p "$RW_LEGACY_DIR"
  local name
  for name in task-mode-guard.sh state-lib.sh; do
    [ -f "$RW_LEGACY_SOURCE/$name" ] || fail legacy-fixture-missing
    cp "$RW_LEGACY_SOURCE/$name" "$RW_LEGACY_DIR/$name"
  done
}
rw_clear_state_dir() { find "$STATE_DIR" -mindepth 1 -delete 2>/dev/null || true; }
# 시나리오: 상태 디렉토리를 비우고 상태파일(auto · SPEC=1 · TASK_PATH=직전 폴더)을 세운 뒤 같은 stdin 으로 기준 훅 · 새 훅을 돌린다.
rw_same_as_legacy() { # <시나리오 이름> <stdin 글자> [상태 — none 이면 상태파일 없음] [견줄 것 — 기본 exit out err state list]
  local name=$1 input=$2 with_state=${3:-state} parts=${4:-exit out err state list} capture="$SANDBOX/rw-capture" prev part side
  rw_legacy_init
  prev=$(rw_folder "$REPO" prev)
  for side in legacy new; do
    rw_clear_state_dir
    [ "$with_state" = none ] || rw_state auto 1 0 0 "$prev"
    if [ "$side" = legacy ]; then rw_run "$RW_LEGACY_DIR/task-mode-guard.sh" "$input" "$side-$name"
    else rw_run "$HOOKS_DIR/task-mode-guard.sh" "$input" "$side-$name"; fi
    printf '%s\n' "$HOOK_EXIT" > "$capture/$side-$name.exit"
    if [ -f "$STATE" ]; then cp "$STATE" "$capture/$side-$name.state"; else : > "$capture/$side-$name.state"; fi
    rw_listing > "$capture/$side-$name.list"
  done
  for part in $parts; do
    cmp -s "$capture/legacy-$name.$part" "$capture/new-$name.$part" || {
      echo "  [dbg] $name $part legacy=$(head -c 200 "$capture/legacy-$name.$part" | tr '\n' '~') new=$(head -c 200 "$capture/new-$name.$part" | tr '\n' '~')"
      fail "same-as-legacy-$name-$part"; }
  done
}

# ═══ 조항 1 — 워커의 Write 는 게이트를 바꾸지 않는다 ═════════════════════════════════

test_rw_a01_worker_write_of_new_log_md_keeps_state_bytes() { # [1] agent_id 가 있는 log.md Write → 상태 바이트 그대로 · 리셋 메시지 없음 · 사이드카 없음
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" worker-made)
  rw_state auto 1 0 0 "$prev"; cp "$STATE" "$SANDBOX/before"
  rw_tmg Write "$folder/log.md" agent-a01
  assert_exit 0 a01-exit
  rw_assert_state_bytes_same "$SANDBOX/before" a01-state-same
  assert_state TASK_PATH "$prev" a01-task-path-kept
  assert_stderr_no_match "$RW_RESET_MSG|SPEC=0|MODE=UNSET" a01-no-reset-msg
  rw_assert_no_sidecar a01-no-sidecar
  [ ! -e "$STATE.reset-pending" ] || fail a01-no-reset-marker
}

test_rw_a02_worker_write_of_new_requirement_spec_keeps_state_bytes() { # [1] requirement-spec.md 도 같다
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" worker-spec)
  rw_state auto 1 0 0 "$prev"; cp "$STATE" "$SANDBOX/before"
  rw_tmg Write "$folder/requirement-spec.md" agent-a02
  assert_exit 0 a02-exit
  rw_assert_state_bytes_same "$SANDBOX/before" a02-state-same
  assert_stderr_no_match "$RW_RESET_MSG|SPEC=0|MODE=UNSET" a02-no-reset-msg
  rw_assert_no_sidecar a02-no-sidecar
}

test_rw_a03_worker_write_keeps_lazy_pending_debt_and_task_path() { # [1] lazy · PENDING_GATE=1 · DEBT=1 도 그대로(다섯 키 모두)
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" worker-lazy)
  rw_state lazy 1 1 1 "$prev"; cp "$STATE" "$SANDBOX/before"
  rw_tmg Write "$folder/log.md" agent-a03
  assert_exit 0 a03-exit
  rw_assert_state_bytes_same "$SANDBOX/before" a03-state-same
  assert_state MODE lazy a03-mode
  assert_state SPEC 1 a03-spec
  assert_state PENDING_GATE 1 a03-pending
  assert_state DEBT 1 a03-debt
  assert_state TASK_PATH "$prev" a03-task-path
}

test_rw_a04_worker_write_in_other_repo_folder_keeps_state() { # [1] 다른 저장소의 작업 폴더를 워커가 써도 그대로(사고의 꼴)
  local prev other folder
  prev=$(rw_folder "$REPO" prev)
  other="$SANDBOX/other-repo"; mkdir -p "$other"
  folder=$(rw_folder "$other" close-out)
  rw_state auto 1 0 0 "$prev"; cp "$STATE" "$SANDBOX/before"
  rw_tmg Write "$folder/requirement-spec.md" agent-a04
  rw_tmg Write "$folder/log.md" agent-a04
  assert_exit 0 a04-exit
  rw_assert_state_bytes_same "$SANDBOX/before" a04-state-same
  assert_stderr_no_match "$RW_RESET_MSG" a04-no-reset-msg
  rw_assert_no_sidecar a04-no-sidecar
}

test_rw_a05_worker_write_with_unset_state_keeps_state() { # [1] 리셋 직후(UNSET · SPEC=0)의 다른 폴더 Write 도 TASK_PATH 를 옮기지 않는다
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" worker-unset)
  rw_state UNSET 0 0 0 "$prev"; cp "$STATE" "$SANDBOX/before"
  rw_tmg Write "$folder/log.md" agent-a05
  assert_exit 0 a05-exit
  rw_assert_state_bytes_same "$SANDBOX/before" a05-state-same
  rw_assert_no_sidecar a05-no-sidecar
}

test_rw_a06_main_write_without_agent_id_still_resets() { # [1 회귀] agent_id 키 없음 = 메인 → 종전대로 리셋(DEBT 유지 · TASK_PATH 갱신 · 메시지)
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" main-new)
  rw_state auto 1 1 1 "$prev"
  rw_tmg Write "$folder/log.md" none
  assert_exit 0 a06-exit
  assert_state MODE UNSET a06-mode
  assert_state SPEC 0 a06-spec
  assert_state PENDING_GATE 0 a06-pending
  assert_state DEBT 1 a06-debt-kept
  assert_state TASK_PATH "$folder" a06-task-path
  assert_stderr_match "$RW_RESET_MSG" a06-reset-msg
}

test_rw_a07_main_write_with_empty_agent_id_resets() { # [1 회귀] agent_id "" = 메인
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" main-empty)
  rw_state auto 1 0 0 "$prev"
  rw_tmg Write "$folder/requirement-spec.md" empty
  assert_exit 0 a07-exit
  assert_state MODE UNSET a07-mode
  assert_state SPEC 0 a07-spec
  assert_state TASK_PATH "$folder" a07-task-path
  assert_stderr_match "$RW_RESET_MSG" a07-reset-msg
}

test_rw_a08_main_write_with_null_agent_id_resets() { # [1 회귀] agent_id null = 메인
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" main-null)
  rw_state auto 1 0 0 "$prev"
  rw_tmg Write "$folder/log.md" null
  assert_exit 0 a08-exit
  assert_state MODE UNSET a08-mode
  assert_state SPEC 0 a08-spec
  assert_state TASK_PATH "$folder" a08-task-path
  assert_stderr_match "$RW_RESET_MSG" a08-reset-msg
}

test_rw_a09_worker_write_then_main_write_same_folder_resets() { # [1] 워커가 먼저 쓴 폴더를 메인이 쓰면 그때 리셋(워커가 TASK_PATH 를 몰래 옮기지 않았다)
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" shared)
  rw_state auto 1 0 0 "$prev"
  rw_tmg Write "$folder/log.md" agent-a09
  assert_state TASK_PATH "$prev" a09-worker-kept-task-path
  rw_tmg Write "$folder/log.md" none
  assert_exit 0 a09-exit
  assert_state MODE UNSET a09-main-reset-mode
  assert_state SPEC 0 a09-main-reset-spec
  assert_state TASK_PATH "$folder" a09-main-task-path
  assert_stderr_match "$RW_RESET_MSG" a09-main-reset-msg
  rw_assert_sidecar a09-sidecar "$folder"
}

test_rw_a10_main_reset_output_same_as_legacy() { # [1 · 2 회귀] 메인의 새 폴더 Write 는 종전과 종료 코드 · stdout · stderr · 상태 바이트가 같다
  local prev folder capture="$SANDBOX/rw-capture" part side input
  rw_legacy_init
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" main-legacy)
  for input in "$folder/log.md" "$folder/requirement-spec.md"; do
    for side in legacy new; do
      rw_clear_state_dir; rw_state auto 1 0 1 "$prev"
      if [ "$side" = legacy ]; then rw_run "$RW_LEGACY_DIR/task-mode-guard.sh" "$(rw_json Write "$input")" "$side"
      else rw_run "$HOOKS_DIR/task-mode-guard.sh" "$(rw_json Write "$input")" "$side"; fi
      printf '%s\n' "$HOOK_EXIT" > "$capture/$side.exit"; cp "$STATE" "$capture/$side.state"
    done
    for part in exit out err state; do
      cmp -s "$capture/legacy.$part" "$capture/new.$part" || {
        echo "  [dbg] $input $part legacy=$(head -c 200 "$capture/legacy.$part" | tr '\n' '~') new=$(head -c 200 "$capture/new.$part" | tr '\n' '~')"
        fail "a10-same-$part"; }
    done
    rw_assert_sidecar a10-sidecar "$folder"
  done
}

test_rw_a11_main_reentry_output_same_as_legacy() { # [1 · 2 회귀] 같은 TASK_PATH 재진입(리셋 없음)도 종전과 출력 · 상태가 같다
  local folder capture="$SANDBOX/rw-capture" part side
  rw_legacy_init
  folder=$(rw_folder "$REPO" same)
  for side in legacy new; do
    rw_clear_state_dir; rw_state auto 1 0 0 "$folder"
    if [ "$side" = legacy ]; then rw_run "$RW_LEGACY_DIR/task-mode-guard.sh" "$(rw_json Write "$folder/log.md")" "$side"
    else rw_run "$HOOKS_DIR/task-mode-guard.sh" "$(rw_json Write "$folder/log.md")" "$side"; fi
    printf '%s\n' "$HOOK_EXIT" > "$capture/$side.exit"; cp "$STATE" "$capture/$side.state"
  done
  for part in exit out err state; do
    cmp -s "$capture/legacy.$part" "$capture/new.$part" || {
      echo "  [dbg] $part legacy=$(head -c 200 "$capture/legacy.$part" | tr '\n' '~') new=$(head -c 200 "$capture/new.$part" | tr '\n' '~')"
      fail "a11-same-$part"; }
  done
}

# ═══ 조항 2 — 메인의 Write 가 사이드카에 작업 폴더를 더한다 ═══════════════════════════

test_rw_b01_main_log_write_creates_sidecar_with_one_line() { # [2] 사이드카가 없을 때 처음 만든다 — 줄 = canonical 폴더 + 끝 개행
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" first)
  rw_state auto 1 0 0 "$prev"
  rw_assert_no_sidecar b01-absent-before
  rw_tmg Write "$folder/log.md"
  assert_exit 0 b01-exit
  rw_assert_sidecar b01 "$folder"
  assert_state TASK_PATH "$folder" b01-task-path
  assert_stderr_match "$RW_RESET_MSG" b01-reset-msg
}

test_rw_b02_main_spec_write_creates_sidecar() { # [2] requirement-spec.md 의 Write 도 같은 줄을 더한다
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" spec-first)
  rw_state auto 1 0 0 "$prev"
  rw_tmg Write "$folder/requirement-spec.md"
  assert_exit 0 b02-exit
  rw_assert_sidecar b02 "$folder"
}

test_rw_b03_log_then_spec_in_same_folder_adds_one_line() { # [2] 같은 폴더의 log.md → requirement-spec.md → log.md 다시 쓰기 = 한 줄
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" twice)
  rw_state auto 1 0 0 "$prev"
  rw_tmg Write "$folder/log.md"
  rw_tmg Write "$folder/requirement-spec.md"
  rw_tmg Write "$folder/log.md"
  assert_exit 0 b03-exit
  rw_assert_sidecar b03 "$folder"
}

test_rw_b04_three_folders_in_order_add_three_lines() { # [2] 폴더 셋을 차례로 → 세 줄 · 쓴 차례대로 · 앞 폴더로 돌아가도 늘지 않는다
  local prev f1 f2 f3
  prev=$(rw_folder "$REPO" prev)
  f1=$(rw_folder "$REPO" one); f2=$(rw_folder "$REPO" two); f3=$(rw_folder "$REPO" three)
  rw_state auto 1 0 0 "$prev"
  rw_tmg Write "$f1/requirement-spec.md"
  rw_tmg Write "$f2/log.md"
  rw_tmg Write "$f3/requirement-spec.md"
  rw_tmg Write "$f1/log.md"
  assert_exit 0 b04-exit
  rw_assert_sidecar b04 "$f1" "$f2" "$f3"
  assert_state TASK_PATH "$f1" b04-task-path
}

test_rw_b05_reentry_with_same_task_path_still_lists_folder() { # [2] TASK_PATH 가 이미 그 폴더(리셋 없음)여도 목록에 오른다 · 상태는 그대로
  local folder
  folder=$(rw_folder "$REPO" reentry)
  rw_state auto 1 0 0 "$folder"; cp "$STATE" "$SANDBOX/before"
  rw_tmg Write "$folder/log.md"
  assert_exit 0 b05-exit
  rw_assert_state_bytes_same "$SANDBOX/before" b05-state-same
  assert_stderr_no_match "$RW_RESET_MSG" b05-no-reset-msg
  rw_assert_sidecar b05 "$folder"
}

test_rw_b06_other_repo_folder_is_listed() { # [2] 다른 저장소의 작업 폴더도 오른다(cwd 는 이 저장소 · 상태 디렉토리도 이 저장소)
  local prev other folder
  prev=$(rw_folder "$REPO" prev)
  other="$SANDBOX/other-repo"; mkdir -p "$other"
  folder=$(rw_folder "$other" elsewhere)
  rw_state auto 1 0 0 "$prev"
  rw_tmg Write "$folder/log.md"
  assert_exit 0 b06-exit
  rw_assert_sidecar b06 "$folder"
  assert_state TASK_PATH "$folder" b06-task-path
  [ ! -e "$other/.claude/lazymode/$SID.req-check-paths" ] || fail b06-not-in-other-repo-state-dir
}

test_rw_b07_folder_with_spaces_is_one_line() { # [2] 경로에 공백 — 한 줄로 그대로
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" "with space  two")
  rw_state auto 1 0 0 "$prev"
  rw_tmg Write "$folder/log.md"
  assert_exit 0 b07-exit
  rw_assert_sidecar b07 "$folder"
}

test_rw_b08_relative_file_path_is_written_absolute() { # [2] 상대 file_path(cwd 기준) → canonical 절대 경로로 적힌다
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" relative)
  rw_state auto 1 0 0 "$prev"
  rw_tmg Write "docs/plans/2026-11-28/relative/log.md"
  assert_exit 0 b08-exit
  rw_assert_sidecar b08 "$folder"
}

test_rw_b09_symlinked_folder_is_written_canonical() { # [2] 심링크를 거친 경로 → 실제 폴더(canonical)로 적히고 실제 경로로 다시 써도 늘지 않는다
  local prev folder link
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" real-target)
  link="$SANDBOX/repo-alias"; ln -s "$REPO" "$link"
  rw_state auto 1 0 0 "$prev"
  rw_tmg Write "$link/docs/plans/2026-11-28/real-target/log.md"
  assert_exit 0 b09-exit
  rw_assert_sidecar b09-via-link "$folder"
  rw_tmg Write "$folder/requirement-spec.md"
  rw_assert_sidecar b09-via-real "$folder"
}

test_rw_b10_existing_sidecar_without_trailing_newline_gets_new_line() { # [2] 끝 개행 없는 기존 사이드카에 더해도 두 줄이 붙지 않는다
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" appended)
  rw_state auto 1 0 0 "$prev"
  printf '%s' "$prev" > "$(rw_sidecar)"
  rw_tmg Write "$folder/log.md"
  assert_exit 0 b10-exit
  rw_assert_sidecar b10 "$prev" "$folder"
}

test_rw_b11_existing_line_is_not_duplicated_and_others_kept() { # [2] 이미 있는 폴더면 그대로 — 다른 줄 · 차례도 그대로
  local prev f1 f2
  prev=$(rw_folder "$REPO" prev); f1=$(rw_folder "$REPO" kept1); f2=$(rw_folder "$REPO" kept2)
  rw_state auto 1 0 0 "$prev"
  printf '%s\n%s\n' "$f1" "$f2" > "$(rw_sidecar)"
  rw_tmg Write "$f1/log.md"
  assert_exit 0 b11-exit
  rw_assert_sidecar b11 "$f1" "$f2"
}

test_rw_b12_sidecar_line_is_folder_not_file() { # [2] 줄은 작업 폴더(끝 `/` 없음 · log.md 아님)
  local prev folder sc
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" shape)
  rw_state auto 1 0 0 "$prev"
  rw_tmg Write "$folder/requirement-spec.md"
  sc=$(rw_sidecar)
  assert_file_not_contains "$sc" "log.md" b12-no-file-name
  assert_file_not_contains "$sc" "requirement-spec.md" b12-no-spec-name
  if grep -q '/$' "$sc" 2>/dev/null; then fail b12-no-trailing-slash; fi
  rw_assert_sidecar b12 "$folder"
}

test_rw_b13_write_is_atomic_replacement_without_temp_left() { # [2] 원자 쓰기(임시 → mv) — 파일이 새 inode 로 바뀌고 임시 파일이 남지 않는다
  local prev f1 f2 inode_before inode_after
  prev=$(rw_folder "$REPO" prev); f1=$(rw_folder "$REPO" atom1); f2=$(rw_folder "$REPO" atom2)
  rw_state auto 1 0 0 "$prev"
  rw_tmg Write "$f1/log.md"
  rw_assert_sidecar b13-first "$f1"
  inode_before=$(stat -c %i "$(rw_sidecar)")
  rw_tmg Write "$f2/log.md"
  rw_assert_sidecar b13-second "$f1" "$f2"
  inode_after=$(stat -c %i "$(rw_sidecar)")
  [ "$inode_before" != "$inode_after" ] || { echo "  [dbg] inode=$inode_before"; fail b13-replaced-by-mv; }
  rw_assert_no_temp_left b13-no-temp
}

test_rw_b14_symlink_sidecar_is_not_followed() { # [2] 사이드카가 심링크면 쓰지 않는다 — 대상 그대로 · 심링크 그대로 · 경고 한 줄 · exit 0 · 리셋은 종전대로
  local prev folder target sc
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" via-symlink)
  rw_state auto 1 0 0 "$prev"
  target="$SANDBOX/outside-target"; printf 'keep\n' > "$target"
  sc=$(rw_sidecar); ln -s "$target" "$sc"
  rw_tmg Write "$folder/log.md"
  assert_exit 0 b14-exit
  [ -L "$sc" ] || fail b14-still-symlink
  [ "$(readlink -- "$sc")" = "$target" ] || fail b14-link-target-same
  [ "$(cat "$target")" = "keep" ] || { echo "  [dbg] target=$(tr '\n' '~' < "$target")"; fail b14-target-untouched; }
  assert_stderr_match 'req-check-paths|사이드카' b14-warning
  [ "$(printf '%s\n' "$HOOK_STDERR" | grep -cE 'req-check-paths|사이드카')" = 1 ] || fail b14-warning-one-line
  assert_state MODE UNSET b14-reset-mode
  assert_state TASK_PATH "$folder" b14-reset-task-path
  assert_stderr_match "$RW_RESET_MSG" b14-reset-msg
}

test_rw_b15_dangling_symlink_sidecar_is_not_created_through() { # [2] 끊긴 심링크도 그 너머에 파일을 만들지 않는다
  local prev folder target sc
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" dangling)
  rw_state auto 1 0 0 "$prev"
  target="$SANDBOX/not-there"
  sc=$(rw_sidecar); ln -s "$target" "$sc"
  rw_tmg Write "$folder/log.md"
  assert_exit 0 b15-exit
  [ ! -e "$target" ] || fail b15-no-file-through-link
  [ -L "$sc" ] || fail b15-still-symlink
  assert_stderr_match 'req-check-paths|사이드카' b15-warning
}

test_rw_b16_directory_sidecar_is_not_written() { # [2] 사이드카 자리가 디렉토리(비정규) → 쓰지 않음 · 경고 · exit 0 · 리셋은 종전대로
  local prev folder sc
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" dir-sidecar)
  rw_state auto 1 0 0 "$prev"
  sc=$(rw_sidecar); mkdir "$sc"
  rw_tmg Write "$folder/log.md"
  assert_exit 0 b16-exit
  [ -d "$sc" ] && [ ! -L "$sc" ] || fail b16-still-directory
  [ -z "$(ls -A "$sc")" ] || fail b16-nothing-inside
  assert_stderr_match 'req-check-paths|사이드카' b16-warning
  assert_state MODE UNSET b16-reset-mode
  assert_stderr_match "$RW_RESET_MSG" b16-reset-msg
}

test_rw_b17_unreadable_sidecar_is_not_clobbered() { # [2] 읽을 수 없는 기존 사이드카 — 기존 줄을 잃지 않는다 · 경고 · exit 0
  [ "$(id -u)" != 0 ] || skip_test root-ignores-permissions
  local prev f1 folder sc
  prev=$(rw_folder "$REPO" prev); f1=$(rw_folder "$REPO" old-line); folder=$(rw_folder "$REPO" unreadable)
  rw_state auto 1 0 0 "$prev"
  sc=$(rw_sidecar); printf '%s\n' "$f1" > "$sc"; chmod 000 "$sc"
  rw_tmg Write "$folder/log.md"
  chmod 600 "$sc" 2>/dev/null || true
  assert_exit 0 b17-exit
  grep -qxF -- "$f1" "$sc" 2>/dev/null || { rw_dbg_sidecar; fail b17-old-line-kept; }
  assert_stderr_match 'req-check-paths|사이드카' b17-warning
  assert_state MODE UNSET b17-reset-mode
}

test_rw_b18_write_failure_is_nonblocking_with_warning() { # [2] 상태 디렉토리에 쓸 수 없다 → exit 0 · 사이드카 경고 · 반쪽 파일 없음
  [ "$(id -u)" != 0 ] || skip_test root-ignores-permissions
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" ro-dir)
  rw_state auto 1 0 0 "$prev"
  : > "$STATE.lock"
  chmod 555 "$STATE_DIR"
  rw_tmg Write "$folder/log.md"
  chmod 755 "$STATE_DIR"
  assert_exit 0 b18-exit
  rw_assert_no_sidecar b18-no-sidecar
  rw_assert_no_temp_left b18-no-temp
  assert_stderr_match 'req-check-paths|사이드카' b18-warning
}

test_rw_b19_entry_files_outside_plans_do_not_touch_sidecar() { # [2 경계] 진입점이 아닌 파일(작업 폴더의 다른 파일 · plans 밖 log.md)은 사이드카에 쓰지 않는다
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" other-files)
  rw_state auto 1 0 0 "$prev"
  printf 'x\n' > "$folder/decisions.md"; printf 'x\n' > "$REPO/log.md"
  mkdir -p "$REPO/docs/notes"; printf 'x\n' > "$REPO/docs/notes/log.md"
  rw_tmg Write "$folder/decisions.md"
  rw_tmg Write "$REPO/log.md"
  rw_tmg Write "$REPO/docs/notes/log.md"
  rw_tmg Edit "$folder/log.md"
  assert_exit 0 b19-exit
  rw_assert_no_sidecar b19-no-sidecar
  assert_state TASK_PATH "$prev" b19-task-path-kept
}

# ═══ 조항 3 — 그 밖은 종전과 바이트까지 같다 ═════════════════════════════════════════

test_rw_c01_non_entry_write_same_as_legacy() { # [3] 진입점이 아닌 파일의 Write
  local folder
  folder=$(rw_folder "$REPO" nonentry)
  printf 'x\n' > "$folder/decisions.md"; printf 'x\n' > "$folder/master-plan.md"
  rw_same_as_legacy decisions "$(rw_json Write "$folder/decisions.md")"
  rw_same_as_legacy master-plan "$(rw_json Write "$folder/master-plan.md")"
  rw_same_as_legacy root-log "$(rw_json Write "$REPO/log.md")"
  rw_same_as_legacy code "$(rw_json Write "$REPO/src/app.sh")"
}

test_rw_c02_edit_of_entry_files_same_as_legacy() { # [3] Edit 도구(진입점 파일이어도)
  local folder
  folder=$(rw_folder "$REPO" edited)
  rw_same_as_legacy edit-log "$(rw_json Edit "$folder/log.md")"
  rw_same_as_legacy edit-spec "$(rw_json Edit "$folder/requirement-spec.md")"
  rw_same_as_legacy edit-log-worker "$(rw_json Edit "$folder/log.md" agent-c02)"
}

test_rw_c03_parse_failure_same_as_legacy() { # [3] 파싱 실패 — 망가진 JSON · 빈 입력 · 객체가 아닌 JSON
  rw_same_as_legacy garbage 'not-json {{{'
  rw_same_as_legacy empty ''
  rw_same_as_legacy array '["Write"]'
}

test_rw_c04_missing_or_bad_session_id_same_as_legacy() { # [3] session_id 없음 · 빈 값 · 허용 밖 글자
  local folder
  folder=$(rw_folder "$REPO" nosid)
  rw_same_as_legacy no-sid "$(rw_json Write "$folder/log.md" | jq -c 'del(.session_id)')"
  rw_same_as_legacy empty-sid "$(rw_json Write "$folder/log.md" | jq -c '.session_id = ""')"
  rw_same_as_legacy bad-sid "$(rw_json Write "$folder/log.md" | jq -c '.session_id = "../x"')"
}

test_rw_c05_no_state_file_same_as_legacy() { # [3 해석] 상태파일이 없는 세션의 메인 진입점 Write — 상태를 만들지 않고 종료 코드 · 출력도 종전과 같다
  #   (사이드카를 쓰는지는 계약이 정하지 않아 보지 않는다 — 파일 목록은 견주지 않는다)
  local folder
  folder=$(rw_folder "$REPO" nostate)
  rw_same_as_legacy no-state-log "$(rw_json Write "$folder/log.md")" none "exit out err state"
  [ ! -e "$STATE" ] || fail c05-no-state-created
}

# ═══ 조항 4 — 쓰는 쪽과 읽는 쪽(state_reqcheck_paths)의 맞물림 ═══════════════════════

rw_paths() { # <task_path> → RW_P_OUT · RW_P_RC (state-lib 의 state_reqcheck_paths)
  set +e
  RW_P_OUT=$(bash -c '. "$1/state-lib.sh" >/dev/null 2>&1 || exit 99; state_reqcheck_paths "$2" "$3" "$4"' _ \
    "$HOOKS_DIR" "$STATE_DIR" "$SID" "$1" 2>"$SANDBOX/paths.err")
  RW_P_RC=$?
  set -e
}
rw_assert_paths() { # <id> <want 줄...>
  local id=$1; shift
  local want; want=$(printf '%s\n' "$@")
  [ "$RW_P_RC" = 0 ] || { echo "  [dbg] rc=$RW_P_RC out=$(printf '%s' "$RW_P_OUT" | tr '\n' '~')"; fail "$id-rc0"; }
  [ "$RW_P_OUT" = "$want" ] || { echo "  [dbg] out=$(printf '%s' "$RW_P_OUT" | tr '\n' '~') want=$(printf '%s' "$want" | tr '\n' '~')"; fail "$id-lines"; }
}

test_rw_d01_reader_lists_log_of_written_folder() { # [4] 메인이 쓴 폴더의 log.md 가 읽는 쪽에서 나온다(TASK_PATH 없이 · 있을 때 중복 없이)
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" readable)
  rw_state auto 1 0 0 "$prev"
  rw_tmg Write "$folder/log.md"
  rw_paths ""
  rw_assert_paths d01-no-task-path "$folder/log.md"
  rw_paths "$(grep '^TASK_PATH=' "$STATE" | cut -d= -f2-)"
  rw_assert_paths d01-with-task-path "$folder/log.md"
}

test_rw_d02_reader_lists_three_folders_in_order() { # [4] 폴더 셋(공백 · 다른 저장소 · 상대 경로 포함) → 읽는 쪽이 rc 0 으로 쓴 차례대로
  local prev f1 f2 f3 other
  prev=$(rw_folder "$REPO" prev)
  f1=$(rw_folder "$REPO" "read one"); other="$SANDBOX/other-repo"; mkdir -p "$other"
  f2=$(rw_folder "$other" read-two); f3=$(rw_folder "$REPO" read-three)
  rw_state auto 1 0 0 "$prev"
  rw_tmg Write "$f1/requirement-spec.md"
  rw_tmg Write "$f2/log.md"
  rw_tmg Write "docs/plans/2026-11-28/read-three/log.md"
  rw_paths "$prev"
  rw_assert_paths d02 "$prev/log.md" "$f1/log.md" "$f2/log.md" "$f3/log.md"
}

test_rw_d03_reader_sees_appended_line_after_no_newline_sidecar() { # [4] 끝 개행 없던 사이드카에 더한 뒤에도 읽는 쪽이 두 폴더를 따로 낸다
  local prev f1 folder
  prev=$(rw_folder "$REPO" prev); f1=$(rw_folder "$REPO" first-line); folder=$(rw_folder "$REPO" second-line)
  rw_state auto 1 0 0 "$prev"
  printf '%s' "$f1" > "$(rw_sidecar)"
  rw_tmg Write "$folder/log.md"
  rw_paths ""
  rw_assert_paths d03 "$f1/log.md" "$folder/log.md"
}

test_rw_d04_worker_write_is_not_seen_by_reader() { # [4 · 1] 워커가 쓴 폴더는 읽는 쪽 목록에 없다
  local prev folder
  prev=$(rw_folder "$REPO" prev); folder=$(rw_folder "$REPO" worker-hidden)
  rw_state auto 1 0 0 "$prev"
  rw_tmg Write "$folder/log.md" agent-d04
  rw_paths "$prev"
  rw_assert_paths d04 "$prev/log.md"
}
