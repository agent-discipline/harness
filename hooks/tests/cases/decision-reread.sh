# decision-reread 케이스 — 선택 질문 아카이브(capture-decision) · 압축 시각(session-mode-guard compact)
#   · 재독 판정(reread-track) · 미독 차단(gate-guard)·미독 재주입(reinject-mode) · 고정 지시 재주입 (v4.5)
# 계약 정본: docs/plans/2026-11-19/decision-archive-compact-reread/requirement-spec.md §2 I1~I9 · §10.
# 설계: blind 워커(구현 미열람 계약 — spec·probe 실측 JSON에서 출발). fixture 형태 = 같은 폴더 probe/*.json.
# 관례: sandbox_init 은 run.sh 러너가 각 테스트 앞에서 호출한다 — 케이스 함수는 호출하지 않는다.
# "종전 출력" = 기준 커밋(DR_BASE_SHA — 이 기능 착수 직전 main)의 훅 사본(hooks/tests/fixtures/legacy/ —
#   `git show $DR_BASE_SHA:hooks/<파일>` 그대로)을 sandbox 에 복사해 같은 입력으로 실행한 값.
#   git 이력이 없는 배포 사본(~/.claude/hooks/tests)에서도 돌도록 git 을 쓰지 않는다.
#   출력 문자열을 하드코딩하지 않는다(I6·I3 "바이트 단위로 같다"·"종전 동작 그대로").

DR_BASE_SHA=b685d3eba54b17df668812fa21737e13e4446b3c

# ── 케이스 전용 셋업 ───────────────────────────────────────────────────────────
# 작업 폴더 + 상태(TASK_PATH) 준비. TASK_PATH 는 task-mode-guard 가 쓰는 형태(canonical 절대경로)로 기록.
dr_setup_task() { # [MODE] [PENDING] [DEBT] [SPEC]
  write_state "${1:-auto}" "${2:-0}" "${3:-0}" "${4:-1}"
  TP=$(realpath -m -- "$REPO/docs/plans/2026-11-19/t1")
  mkdir -p "$TP"
  printf 'spec body\n' > "$TP/requirement-spec.md"
  printf 'log body\n' > "$TP/log.md"
  echo "TASK_PATH=$TP" >> "$STATE"
  SPECF="$TP/requirement-spec.md"; LOGF="$TP/log.md"; DECF="$TP/decisions.md"
}
dr_compact_at() { printf '%s\n' "$1" > "$STATE_DIR/$SID.compact"; }   # fixture: 압축 시각(epoch 한 줄)
dr_now() { date +%s; }
DR_TITLE='# decisions — 선택 질문과 답 (훅이 자동 기록)'

# ── 케이스 전용 JSON 빌더 (probe/post-ask.json·post-read.json 형태) ─────────────
dr_q() { # <question> <header> <label...> → 질문 1개 JSON (description = "설명-<label>")
  local q=$1 h=$2; shift 2
  printf '%s\n' "$@" | jq -R . | jq -cs --arg q "$q" --arg h "$h" \
    '{question:$q, header:$h, options:[.[] | {label:., description:("설명-" + .)}], multiSelect:false}'
}
dr_ask() { # <tool_use_id> <questions-array-json> <answers-object-json|null> [agent_id]
  jq -cn --arg s "$SID" --arg c "$REPO" --arg id "$1" --argjson q "$2" --argjson a "$3" \
         --arg ag "${4:-}" --arg tr "$SANDBOX/transcript.jsonl" '
    {session_id:$s, transcript_path:$tr, cwd:$c, prompt_id:"p-1", permission_mode:"auto",
     effort:{level:"medium"}, hook_event_name:"PostToolUse", tool_name:"AskUserQuestion",
     tool_input:({questions:$q} + (if $a == null then {} else {answers:$a, annotations:{}} end)),
     tool_response:({questions:$q} + (if $a == null then {} else {answers:$a, annotations:{}} end)),
     tool_use_id:$id, duration_ms:2}
    + (if $ag == "" then {} else {agent_id:$ag, agent_type:"general-purpose"} end)'
}
# 질문 1개 + 답 1개짜리 단축형
dr_ask1() { # <tool_use_id> <question> <header> <answer> [agent_id] — 선택지 = A안 / B안 / C안
  local q; q=$(dr_q "$2" "$3" "A안" "B안" "C안")
  dr_ask "$1" "[$q]" "$(jq -cn --arg k "$2" --arg v "$4" '{($k):$v}')" "${5:-}"
}
dr_read() { # <file_path> [agent_id] [offset] [limit]
  jq -cn --arg s "$SID" --arg c "$REPO" --arg f "$1" --arg ag "${2:-}" --arg o "${3:-}" --arg l "${4:-}" \
         --arg tr "$SANDBOX/transcript.jsonl" '
    {session_id:$s, transcript_path:$tr, cwd:$c, prompt_id:"p-1", permission_mode:"auto",
     hook_event_name:"PostToolUse", tool_name:"Read",
     tool_input:({file_path:$f}
       + (if $o == "" then {} else {offset:($o|tonumber)} end)
       + (if $l == "" then {} else {limit:($l|tonumber)} end)),
     tool_response:{type:"text", file:{filePath:$f, content:"x", numLines:1, startLine:1, totalLines:1}},
     tool_use_id:"toolu_read", duration_ms:4}
    + (if $ag == "" then {} else {agent_id:$ag, agent_type:"general-purpose"} end)'
}
dr_tool() { # <event> <tool> <file_path> [agent_id]   (Edit/Write/MultiEdit — gate-guard 입력)
  jq -cn --arg s "$SID" --arg c "$REPO" --arg e "$1" --arg t "$2" --arg f "$3" --arg ag "${4:-}" '
    {session_id:$s, cwd:$c, permission_mode:"auto", hook_event_name:$e, tool_name:$t,
     tool_input:({file_path:$f}
       + (if $t == "Write" then {content:"x"} elif $t == "Edit" then {old_string:"a", new_string:"b"}
          else {edits:[{old_string:"a", new_string:"b"}]} end)),
     tool_use_id:"toolu_w"}
    + (if $ag == "" then {} else {agent_id:$ag, agent_type:"general-purpose"} end)'
}
dr_ss() { # <source> — SessionStart
  jq -cn --arg s "$SID" --arg c "$REPO" --arg src "$1" --arg tr "$SANDBOX/transcript.jsonl" \
    '{session_id:$s, transcript_path:$tr, cwd:$c, hook_event_name:"SessionStart", source:$src}'
}

# ── 케이스 전용 실행 헬퍼 ─────────────────────────────────────────────────────
dr_read_hook() { run_hook reread-track.sh "$(dr_read "$@")"; }          # <file_path> [agent] [offset] [limit]
dr_read_targets() { # 현재 존재하는 대상 전부를 메인(Read) 으로 읽음
  dr_read_hook "$SPECF"; dr_read_hook "$LOGF"
  if [ -e "$DECF" ]; then dr_read_hook "$DECF"; fi
}
dr_l1() { run_hook gate-guard.sh "$(dr_tool PreToolUse "${1:-Write}" "$REPO/src/app.sh" "${2:-}")"; }  # L1 쓰기 시도
# 훅 stdout 을 바이트 그대로 파일로 (끝 개행 포함 비교용 — $(...) 는 끝 개행을 지운다)
dr_raw() { # <hook 절대경로> <json> <outfile>
  printf '%s' "$2" | env HOME="$HOME_DIR" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
    XDG_CONFIG_HOME="$XDG_DIR" bash "$1" > "$3" 2>/dev/null || true
}
# 기준 커밋의 훅(종전 구현)을 sandbox 로 꺼낸다 → LEG
dr_legacy_init() { # fixture 사본 → $SANDBOX/legacy (SCRIPT_DIR 기준 state-lib.sh source 가 사본끼리 맞물림)
  LEG="$SANDBOX/legacy"; mkdir -p "$LEG"
  local f
  for f in state-lib.sh reinject-mode.sh session-mode-guard.sh; do
    [ -f "$TESTS_DIR/fixtures/legacy/$f" ] || fail legacy-fixture-missing
    cp "$TESTS_DIR/fixtures/legacy/$f" "$LEG/$f"
  done
}
# 보충 13·27: reread-track 를 한 번 실행해 이 세션의 표시 파일(<state_dir>/<sid>.reread-seen)이 생기게 한다(대상 아닌 Read)
dr_seen() { # <assert-id>
  run_hook reread-track.sh "$(dr_read "$REPO/README.md")"
  [ -e "$STATE_DIR/$SID.reread-seen" ] || fail "$1"
}
dr_add_task() { # 상태를 다시 쓰지 않고 작업 폴더 + TASK_PATH 만 추가 (TP·SPECF·LOGF·DECF 설정)
  TP=$(realpath -m -- "$REPO/docs/plans/2026-11-19/${1:-t1}"); mkdir -p "$TP"
  printf 'spec body\n' > "$TP/requirement-spec.md"; printf 'log body\n' > "$TP/log.md"
  echo "TASK_PATH=$TP" >> "$STATE"
  SPECF="$TP/requirement-spec.md"; LOGF="$TP/log.md"; DECF="$TP/decisions.md"
}
dr_heading_count() { [ -f "$1" ] || { echo 0; return 0; }; grep -cE "^## [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \\($2\\)\$" "$1" 2>/dev/null || true; }  # <file> <id ERE>
dr_path_lines() { # <.reread> <path> → 첫 탭 뒤가 정확히 path 인 줄 수 (보충 18)
  awk -v p="$2" '{ i = index($0, "\t"); if (i && substr($0, i + 1) == p) n++ } END { print n + 0 }' "$1" 2>/dev/null || echo 0
}
dr_is_prefix() { # <prefix-file> <file> → rc 0 이면 prefix-file 이 file 의 바이트 접두
  local n; n=$(wc -c < "$1")
  head -c "$n" "$2" | cmp -s - "$1"
}
dr_standing() { mkdir -p "$HOME_DIR/.claude"; printf '%b' "$1" > "$HOME_DIR/.claude/standing-instructions.md"; }
dr_lineno() { grep -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1; }   # <file> <fixed> → 첫 줄 번호(없으면 빈 값)
dr_count() { grep -cF -- "$2" "$1" 2>/dev/null || true; }                    # <file> <fixed> → 일치 줄 수
dr_reread_has() { grep -qF -- "	$1" "$STATE_DIR/$SID.reread" 2>/dev/null; }   # <canonical path>
# <먼저 와야 할 문구 ERE> <assert-id> — stderr 에 그 문구가 있고, 미독 문구가 있다면 그보다 뒤 (보충 11)
dr_reason_first() {
  local f="$SANDBOX/stderr.chk"; printf '%s\n' "$HOOK_STDERR" > "$f"
  local a b; a=$(grep -nE -- "$1" "$f" | head -1 | cut -d: -f1); b=$(grep -nF '압축 뒤 작업 기록 미독' "$f" | head -1 | cut -d: -f1)
  [ -n "$a" ] || { echo "  [dbg] stderr=$(head -n 3 "$f" | tr '\n' ' ')"; fail "$2"; }
  [ -z "$b" ] || [ "$a" -lt "$b" ] || fail "$2-order"
}
dr_root_skip() { [ "$(id -u)" = "0" ]; }   # root 는 chmod 를 무시 — 권한 실패 주입 케이스 무의미

# ══ I1/I2 선택 질문 아카이브 (capture-decision.sh) ═════════════════════════════

test_dr_ad_01() { # [v4.5] TASK_PATH 있음 → decisions.md 최초 생성(제목 줄+빈 줄) + 블록 형식(한글 질문)
  dr_setup_task
  run_hook capture-decision.sh "$(dr_ask1 toolu_ad01 '컴팩트 실험 결과를 공개할까요?' '공개' 'B안')"
  assert_exit 0 ad01-exit
  [ -f "$DECF" ] || fail ad01-created
  [ "$(sed -n 1p "$DECF")" = "$DR_TITLE" ] || { echo "  [dbg] l1=$(sed -n 1p "$DECF")"; fail ad01-title-line1; }
  [ -z "$(sed -n 2p "$DECF")" ] || fail ad01-title-blank-line2
  grep -qE '^## [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \(toolu_ad01\)$' "$DECF" || fail ad01-heading
  grep -qxF '### 공개' "$DECF" || fail ad01-header
  grep -qxF -- '- 질문: 컴팩트 실험 결과를 공개할까요?' "$DECF" || fail ad01-question
  grep -qxF -- '- 선택지: A안 / B안 / C안' "$DECF" || fail ad01-options
  grep -qxF -- '- 답: B안' "$DECF" || fail ad01-answer
  # 블록 내부 순서: ## → (빈 줄) → ### → 질문 → 선택지 → 답
  local h hh q o a
  h=$(grep -n '^## ' "$DECF" | head -1 | cut -d: -f1); hh=$(dr_lineno "$DECF" '### 공개')
  q=$(dr_lineno "$DECF" '- 질문: '); o=$(dr_lineno "$DECF" '- 선택지: '); a=$(dr_lineno "$DECF" '- 답: ')
  [ "$hh" = "$((h+2))" ] && [ -z "$(sed -n "$((h+1))p" "$DECF")" ] || fail ad01-heading-blank-header
  { [ "$q" = "$((hh+1))" ] && [ "$o" = "$((hh+2))" ] && [ "$a" = "$((hh+3))" ]; } || fail ad01-line-order
  assert_file_not_contains "$DECF" '설명-' ad01-no-option-description   # 형식에 description 없음(I9: 질문·답뿐)
  [ "$(dr_count "$DECF" "$DR_TITLE")" = "1" ] || fail ad01-title-once
}

test_dr_ad_02() { # [v4.5] 한 호출의 질문 여러 개 → 한 블록(## 1개) 안에 차례로
  dr_setup_task
  local q1 q2
  q1=$(dr_q '첫째 질문?' '헤더1' 'x1' 'y1'); q2=$(dr_q '둘째 질문?' '헤더2' 'x2' 'y2' 'z2')
  run_hook capture-decision.sh "$(dr_ask toolu_ad02 "[$q1,$q2]" '{"첫째 질문?":"y1","둘째 질문?":"z2"}')"
  assert_exit 0 ad02-exit
  [ "$(grep -c '^## ' "$DECF" || true)" = "1" ] || fail ad02-one-block
  local h1 h2
  h1=$(dr_lineno "$DECF" '### 헤더1'); h2=$(dr_lineno "$DECF" '### 헤더2')
  { [ -n "$h1" ] && [ -n "$h2" ] && [ "$h1" -lt "$h2" ]; } || fail ad02-order
  [ -z "$(sed -n "$((h2-1))p" "$DECF")" ] || fail ad02-blank-between-questions   # 보충 4
  [ -n "$(sed -n "$((h2-2))p" "$DECF")" ] || fail ad02-single-blank-between-questions
  grep -qxF -- '- 선택지: x1 / y1' "$DECF" || fail ad02-opts1
  grep -qxF -- '- 선택지: x2 / y2 / z2' "$DECF" || fail ad02-opts2
  grep -qxF -- '- 답: y1' "$DECF" || fail ad02-ans1
  grep -qxF -- '- 답: z2' "$DECF" || fail ad02-ans2
  # 각 답이 자기 질문 아래(다음 ### 전)에 있다
  local a1 a2; a1=$(dr_lineno "$DECF" '- 답: y1'); a2=$(dr_lineno "$DECF" '- 답: z2')
  { [ "$a1" -gt "$h1" ] && [ "$a1" -lt "$h2" ] && [ "$a2" -gt "$h2" ]; } || fail ad02-answer-placement
}

test_dr_ad_03() { # [v4.5] 자유 서술 답(라벨 밖 문자열) → 원문 그대로
  dr_setup_task
  run_hook capture-decision.sh "$(dr_ask1 toolu_ad03 '압축 직후 무엇을 넣을까?' '압축' '압축 시각을 기록하고, 읽은 시각이 앞이면 다시 읽게 하자 (원문: "그대로")')"
  assert_exit 0 ad03-exit
  grep -qxF -- '- 답: 압축 시각을 기록하고, 읽은 시각이 앞이면 다시 읽게 하자 (원문: "그대로")' "$DECF" || fail ad03-freeform
}

test_dr_ad_04() { # [v4.5] 줄바꿈이 든 질문 → '- 질문:' 한 줄(줄바꿈은 공백), 블록 줄 구조 유지
  dr_setup_task
  local qtext; qtext=$(printf '첫 줄 설명\n둘째 줄 질문?')
  run_hook capture-decision.sh "$(dr_ask1 toolu_ad04 "$qtext" '멀티' 'A안')"
  assert_exit 0 ad04-exit
  grep -qxF -- '- 질문: 첫 줄 설명 둘째 줄 질문?' "$DECF" || fail ad04-newline-to-space
  if grep -qxF '둘째 줄 질문?' "$DECF"; then fail ad04-no-raw-newline; fi
  grep -qxF -- '- 답: A안' "$DECF" || fail ad04-answer-by-raw-key   # answers 맵 키는 줄바꿈 원문
}

test_dr_ad_05() { # [v4.5] 기존 decisions.md 에는 끝에 덧붙임(append-only) — 제목 1회, 앞 블록 보존·순서
  dr_setup_task
  run_hook capture-decision.sh "$(dr_ask1 toolu_ad05a '질문 하나?' 'H1' 'A안')"
  [ -f "$DECF" ] || fail ad05-first-recorded
  cp "$DECF" "$SANDBOX/ad05.before"                       # 바이트 그대로 보관(글자 수·바이트 수 혼용 금지)
  run_hook capture-decision.sh "$(dr_ask1 toolu_ad05b '질문 둘?' 'H2' 'C안')"
  assert_exit 0 ad05-exit
  dr_is_prefix "$SANDBOX/ad05.before" "$DECF" || fail ad05-prefix-preserved
  [ "$(dr_count "$DECF" "$DR_TITLE")" = "1" ] || fail ad05-title-once
  local a b; a=$(dr_lineno "$DECF" '(toolu_ad05a)'); b=$(dr_lineno "$DECF" '(toolu_ad05b)')
  { [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; } || fail ad05-order
  [ -z "$(sed -n "$((b-1))p" "$DECF")" ] || fail ad05-blank-between-blocks   # 보충 4
  [ -n "$(sed -n "$((b-2))p" "$DECF")" ] || fail ad05-single-blank-between-blocks
}

test_dr_ad_06() { # [v4.5] TASK_PATH 없음 → 세션 사이드카 <sid>.decisions 에 쌓임, decisions.md 미생성
  write_state auto
  run_hook capture-decision.sh "$(dr_ask1 toolu_ad06 '작업 폴더 전 질문?' '전' 'A안')"
  assert_exit 0 ad06-exit
  local sc="$STATE_DIR/$SID.decisions"
  [ -f "$sc" ] || fail ad06-sidecar-created
  grep -qE '^## [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \(toolu_ad06\)$' "$sc" || fail ad06-sidecar-heading
  grep -qxF -- '- 질문: 작업 폴더 전 질문?' "$sc" || fail ad06-sidecar-question
  grep -qxF -- '- 답: A안' "$sc" || fail ad06-sidecar-answer
  assert_file_not_contains "$sc" "$DR_TITLE" ad06-sidecar-no-title
  [ -z "$(find "$REPO" -name decisions.md 2>/dev/null)" ] || fail ad06-no-decisions-md
}

test_dr_ad_07() { # [v4.5] TASK_PATH 생긴 뒤 첫 기록 → 사이드카분 먼저 순서대로 옮기고 사이드카 삭제(유실·중복 없음)
  write_state auto
  run_hook capture-decision.sh "$(dr_ask1 toolu_m1 '첫 결정?' 'M1' 'A안')"
  run_hook capture-decision.sh "$(dr_ask1 toolu_m2 '둘째 결정?' 'M2' 'B안')"
  [ -f "$STATE_DIR/$SID.decisions" ] || fail ad07-sidecar-precondition
  TP=$(realpath -m -- "$REPO/docs/plans/2026-11-19/t1"); mkdir -p "$TP"
  printf 's\n' > "$TP/requirement-spec.md"; printf 'l\n' > "$TP/log.md"
  echo "TASK_PATH=$TP" >> "$STATE"
  run_hook capture-decision.sh "$(dr_ask1 toolu_m3 '셋째 결정?' 'M3' 'C안')"
  assert_exit 0 ad07-exit
  local D="$TP/decisions.md"
  [ "$(sed -n 1p "$D")" = "$DR_TITLE" ] || fail ad07-title-line1
  [ "$(dr_count "$D" "$DR_TITLE")" = "1" ] || fail ad07-title-once
  local i
  for i in m1 m2 m3; do [ "$(dr_count "$D" "(toolu_$i)")" = "1" ] || fail "ad07-once-$i"; done
  local l1 l2 l3; l1=$(dr_lineno "$D" '(toolu_m1)'); l2=$(dr_lineno "$D" '(toolu_m2)'); l3=$(dr_lineno "$D" '(toolu_m3)')
  { [ "$l1" -lt "$l2" ] && [ "$l2" -lt "$l3" ]; } || fail ad07-order
  grep -qxF -- '- 답: B안' "$D" || fail ad07-migrated-answer
  [ ! -e "$STATE_DIR/$SID.decisions" ] || fail ad07-sidecar-removed
  # 이후 기록은 사이드카로 다시 가지 않는다
  run_hook capture-decision.sh "$(dr_ask1 toolu_m4 '넷째 결정?' 'M4' 'A안')"
  [ ! -e "$STATE_DIR/$SID.decisions" ] || fail ad07-no-sidecar-after
  [ "$(dr_count "$D" '(toolu_m1)')" = "1" ] || fail ad07-no-remigrate
}

test_dr_ad_07b() { # [v4.5] 이전 이동 시 decisions.md 가 이미 있으면 그 끝에 사이드카분 → 새 블록 순
  dr_setup_task
  printf '%s\n\n## 2026-11-19 00:00:00 (toolu_old)\n\n### 옛\n- 질문: 옛?\n- 선택지: a / b\n- 답: a\n' "$DR_TITLE" > "$DECF"
  sed -i '/^TASK_PATH=/d' "$STATE"                         # 작업 폴더 없는 상태에서 사이드카 기록
  run_hook capture-decision.sh "$(dr_ask1 toolu_s1 '사이드카 결정?' 'S1' 'B안')"
  [ -f "$STATE_DIR/$SID.decisions" ] || fail ad07b-sidecar-precondition
  echo "TASK_PATH=$TP" >> "$STATE"
  run_hook capture-decision.sh "$(dr_ask1 toolu_s2 '새 결정?' 'S2' 'C안')"
  assert_exit 0 ad07b-exit
  local o s n; o=$(dr_lineno "$DECF" '(toolu_old)'); s=$(dr_lineno "$DECF" '(toolu_s1)'); n=$(dr_lineno "$DECF" '(toolu_s2)')
  { [ -n "$o" ] && [ -n "$s" ] && [ -n "$n" ] && [ "$o" -lt "$s" ] && [ "$s" -lt "$n" ]; } || fail ad07b-order
  [ "$(dr_count "$DECF" "$DR_TITLE")" = "1" ] || fail ad07b-title-once
  [ ! -e "$STATE_DIR/$SID.decisions" ] || fail ad07b-sidecar-removed
}

test_dr_ad_08() { # [v4.5] 같은 tool_use_id 재호출 → 중복 기록 없음 (decisions.md)
  dr_setup_task
  local j; j=$(dr_ask1 toolu_dup '중복?' 'D' 'A안')
  run_hook capture-decision.sh "$j"
  run_hook capture-decision.sh "$j"
  assert_exit 0 ad08-exit
  [ "$(dr_count "$DECF" '(toolu_dup)')" = "1" ] || fail ad08-no-dup
  [ "$(dr_count "$DECF" '- 질문: 중복?')" = "1" ] || fail ad08-no-dup-body
}

test_dr_ad_08b() { # [v4.5] 같은 tool_use_id 재호출 → 중복 없음 (사이드카 단계에서도)
  write_state auto
  local j; j=$(dr_ask1 toolu_dup2 '중복2?' 'D' 'A안')
  run_hook capture-decision.sh "$j"
  run_hook capture-decision.sh "$j"
  [ "$(dr_count "$STATE_DIR/$SID.decisions" '(toolu_dup2)')" = "1" ] || fail ad08b-no-dup-sidecar
}

test_dr_ad_09() { # [v4.5] 답 없이 끝난 호출(answers 부재·빈 맵) → 기록 없음(파일도 만들지 않음)
  dr_setup_task
  local q; q=$(dr_q '답 안 한 질문?' 'N' 'A안' 'B안')
  run_hook capture-decision.sh "$(dr_ask toolu_na "[$q]" null)"
  assert_exit 0 ad09-absent-exit
  run_hook capture-decision.sh "$(dr_ask toolu_ne "[$q]" '{}')"
  assert_exit 0 ad09-empty-exit
  [ ! -e "$DECF" ] || fail ad09-no-file
  [ ! -e "$STATE_DIR/$SID.decisions" ] || fail ad09-no-sidecar
}

test_dr_ad_10() { # [v4.5] 서브에이전트 안의 호출(agent_id 있음)도 기록
  dr_setup_task
  run_hook capture-decision.sh "$(dr_ask1 toolu_ag '서브에이전트 질문?' 'AG' 'C안' agent-123)"
  assert_exit 0 ad10-exit
  assert_file_contains "$DECF" '(toolu_ag)' ad10-recorded
  grep -qxF -- '- 답: C안' "$DECF" || fail ad10-answer
}

test_dr_ad_11() { # [v4.5 I2] 훅은 명세서·log 를 건드리지 않는다 + 상태파일 무변경
  dr_setup_task
  local hs hl hst
  hs=$(sha256sum < "$SPECF"); hl=$(sha256sum < "$LOGF"); hst=$(sha256sum < "$STATE")
  run_hook capture-decision.sh "$(dr_ask1 toolu_i2 '불변?' 'I2' 'A안')"
  assert_exit 0 ad11-exit
  [ "$(sha256sum < "$SPECF")" = "$hs" ] || fail ad11-spec-untouched
  [ "$(sha256sum < "$LOGF")" = "$hl" ] || fail ad11-log-untouched
  [ "$(sha256sum < "$STATE")" = "$hst" ] || fail ad11-state-untouched
  [ -f "$DECF" ] || fail ad11-recorded   # 무동작으로 통과하는 위장 차단
}

test_dr_ad_12() { # [v4.5 I7] 쓰기 실패(읽기 전용 작업 폴더) → exit 0(도구 사용을 막지 않음) + 경고
  dr_root_skip && return 0
  dr_setup_task
  chmod 555 "$TP"
  run_hook capture-decision.sh "$(dr_ask1 toolu_ro '읽기 전용?' 'RO' 'A안')"
  chmod 755 "$TP"
  assert_exit 0 ad12-exit-0
  [ -n "$HOOK_STDERR" ] || fail ad12-warn
  assert_file_contains "$STATE_DIR/$SID.decisions" '(toolu_ro)' ad12-fallback-sidecar     # 보충 6
  run_hook capture-decision.sh "$(dr_ask1 toolu_ro2 '복구 뒤?' 'RO' 'B안')"
  assert_exit 0 ad12-retry-exit
  local a b; a=$(dr_lineno "$DECF" '(toolu_ro)'); b=$(dr_lineno "$DECF" '(toolu_ro2)')
  { [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; } || fail ad12-retry-migrated-in-order
  [ "$(dr_count "$DECF" '(toolu_ro)')" = "1" ] || fail ad12-retry-once
  [ ! -e "$STATE_DIR/$SID.decisions" ] || fail ad12-retry-sidecar-removed
}

test_dr_ad_12b() { # [v4.5 I7] 쓰기 실패(decisions.md 읽기 전용) → exit 0 + 기존 내용 보존
  dr_root_skip && return 0
  dr_setup_task
  run_hook capture-decision.sh "$(dr_ask1 toolu_r1 '첫?' 'R' 'A안')"
  [ -f "$DECF" ] || fail ad12b-first-recorded
  local before; before=$(sha256sum < "$DECF")
  chmod 444 "$DECF"
  run_hook capture-decision.sh "$(dr_ask1 toolu_r2 '둘?' 'R' 'B안')"
  chmod 644 "$DECF"
  assert_exit 0 ad12b-exit-0
  [ "$(sha256sum < "$DECF")" = "$before" ] || fail ad12b-preserved
  [ -n "$HOOK_STDERR" ] || fail ad12b-warn
  assert_file_contains "$STATE_DIR/$SID.decisions" '(toolu_r2)' ad12b-fallback-sidecar  # 보충 6
  run_hook capture-decision.sh "$(dr_ask1 toolu_r3 '셋?' 'R' 'C안')"
  local a b c; a=$(dr_lineno "$DECF" '(toolu_r1)'); b=$(dr_lineno "$DECF" '(toolu_r2)'); c=$(dr_lineno "$DECF" '(toolu_r3)')
  { [ -n "$a" ] && [ -n "$b" ] && [ -n "$c" ] && [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ]; } || fail ad12b-retry-order
  [ ! -e "$STATE_DIR/$SID.decisions" ] || fail ad12b-retry-sidecar-removed
}

test_dr_ad_15() { # [v4.5 보충 3] 중복은 양쪽에서 본다 — 사이드카에 있는 id 를 TASK_PATH 뒤 재호출·이동해도 1회
  write_state auto
  local j; j=$(dr_ask1 toolu_both '양쪽?' 'B' 'A안')
  run_hook capture-decision.sh "$j"
  [ -f "$STATE_DIR/$SID.decisions" ] || fail ad15-sidecar-precondition
  TP=$(realpath -m -- "$REPO/docs/plans/2026-11-19/t1"); mkdir -p "$TP"
  echo s > "$TP/requirement-spec.md"; echo l > "$TP/log.md"; echo "TASK_PATH=$TP" >> "$STATE"
  run_hook capture-decision.sh "$j"
  assert_exit 0 ad15-exit
  [ "$(dr_count "$TP/decisions.md" '(toolu_both)')" = "1" ] || fail ad15-once-after-migrate
  [ ! -e "$STATE_DIR/$SID.decisions" ] || fail ad15-sidecar-removed
}

test_dr_ad_15b() { # [v4.5 보충 3] 이동 때 decisions.md 에 이미 있는 블록(같은 id)은 다시 쓰지 않음
  dr_setup_task
  printf '%s\n\n## 2026-11-19 00:00:00 (toolu_same)\n\n### 옛\n- 질문: 옛?\n- 선택지: a / b\n- 답: a\n' "$DR_TITLE" > "$DECF"
  printf '## 2026-11-19 00:00:00 (toolu_same)\n\n### 옛\n- 질문: 옛?\n- 선택지: a / b\n- 답: a\n\n## 2026-11-19 00:00:01 (toolu_only_sc)\n\n### 새\n- 질문: 새?\n- 선택지: a / b\n- 답: b\n' > "$STATE_DIR/$SID.decisions"
  run_hook capture-decision.sh "$(dr_ask1 toolu_trig '촉발?' 'T' 'A안')"
  assert_exit 0 ad15b-exit
  [ "$(dr_count "$DECF" '(toolu_same)')" = "1" ] || fail ad15b-existing-not-rewritten
  [ "$(dr_count "$DECF" '(toolu_only_sc)')" = "1" ] || fail ad15b-new-migrated
  [ "$(dr_count "$DECF" '(toolu_trig)')" = "1" ] || fail ad15b-new-record
  [ ! -e "$STATE_DIR/$SID.decisions" ] || fail ad15b-sidecar-removed
}

test_dr_ad_16() { # [v4.5 보충 4] 시각은 로컬 시간 (UTC 와 다른 TZ 에서 실행해 구분)
  dr_setup_task
  export TZ=Asia/Kathmandu                                   # UTC+05:45 — UTC 로 쓰면 5시간 45분 어긋남
  local t0; t0=$(dr_now)
  run_hook capture-decision.sh "$(dr_ask1 toolu_tz '시간대?' 'TZ' 'A안')"
  assert_exit 0 ad16-exit
  local ts e; ts=$(sed -n 's/^## \([0-9-]* [0-9:]*\) (toolu_tz)$/\1/p' "$DECF")
  [ -n "$ts" ] || fail ad16-heading
  e=$(date -d "$ts" +%s 2>/dev/null || echo 0)
  { [ "$e" -ge "$((t0-120))" ] && [ "$e" -le "$((t0+120))" ]; } || { echo "  [dbg] ts=$ts e=$e t0=$t0"; fail ad16-local-time; }
}

test_dr_ad_17() { # [v4.5 보충 5] 답의 줄바꿈 → 공백 · 여러 개 고른 답은 받은 문자열 그대로
  dr_setup_task
  run_hook capture-decision.sh "$(dr_ask1 toolu_nl '자유 서술?' 'NL' "$(printf '첫 줄 답\n둘째 줄 답')")"
  assert_exit 0 ad17-exit
  grep -qxF -- '- 답: 첫 줄 답 둘째 줄 답' "$DECF" || fail ad17-answer-newline-to-space
  if grep -qxF '둘째 줄 답' "$DECF"; then fail ad17-no-raw-newline; fi
  local q; q=$(dr_q '여러 개?' 'MS' 'A안' 'B안' 'C안' | jq -c '.multiSelect=true')
  run_hook capture-decision.sh "$(dr_ask toolu_ms "[$q]" '{"여러 개?":"A안, C안"}')"
  grep -qxF -- '- 답: A안, C안' "$DECF" || fail ad17-multiselect-verbatim
}

test_dr_ad_13() { # [v4.5 I7] 깨진 stdin·session_id 부재 → exit 0, 파일 없음
  run_hook capture-decision.sh 'not-json {{{'
  assert_exit 0 ad13-garbage-exit
  run_hook capture-decision.sh ''
  assert_exit 0 ad13-empty-exit
  write_state auto
  run_hook capture-decision.sh "$(dr_ask1 toolu_ns '세션 없음?' 'NS' 'A안' | jq -c 'del(.session_id)')"
  assert_exit 0 ad13-nosid-exit
  [ -z "$(find "$SANDBOX" -name '*.decisions' -o -name decisions.md 2>/dev/null)" ] || fail ad13-no-files
}

test_dr_ad_14() { # [v4.5] probe 원형(post-ask.json 그대로의 필드) — 긴 한글 질문·(Recommended) 라벨
  dr_setup_task
  local q='컴팩트 실험(compaction-experiment)의 결과 문서와 마감 기록을 커밋했습니다. 지금은 로컬 저장소만 있고 원격이 없습니다. agent-discipline 조직에 저장소를 만들어 올릴까요?'
  local qs; qs=$(dr_q "$q" '공개' '조직에 public으로 올리기 (Recommended)' '조직에 private으로 먼저' '아직 올리지 않기')
  run_hook capture-decision.sh "$(dr_ask toolu_01Hezw1XdP7B64m4aJA6cAGv "[$qs]" "$(jq -cn --arg k "$q" '{($k):"조직에 public으로 올리기 (Recommended)"}')")"
  assert_exit 0 ad14-exit
  grep -qxF -- "- 질문: $q" "$DECF" || fail ad14-question
  grep -qxF -- '- 선택지: 조직에 public으로 올리기 (Recommended) / 조직에 private으로 먼저 / 아직 올리지 않기' "$DECF" || fail ad14-options
  grep -qxF -- '- 답: 조직에 public으로 올리기 (Recommended)' "$DECF" || fail ad14-answer
}

# ══ I3 압축 시각 (session-mode-guard source=compact) ═══════════════════════════

test_dr_cp_01() { # [v4.5] source=compact(표시 파일 있음 — 보충 13) → <sid>.compact 한 줄 epoch(실행 시각) 기록, 상태 키 무변경
  dr_setup_task
  dr_seen cp01-marker-created
  local t0 t1 v; t0=$(dr_now)
  run_hook session-mode-guard.sh "$(dr_ss compact)"
  t1=$(dr_now)
  assert_exit 0 cp01-exit
  [ -f "$STATE_DIR/$SID.compact" ] || fail cp01-created
  [ "$(grep -c '' "$STATE_DIR/$SID.compact" || true)" = "1" ] || fail cp01-one-line
  v=$(head -1 "$STATE_DIR/$SID.compact")
  printf '%s' "$v" | grep -qE '^[0-9]+$' || fail cp01-epoch-format
  { [ "$v" -ge "$t0" ] && [ "$v" -le "$t1" ]; } || { echo "  [dbg] v=$v t0=$t0 t1=$t1"; fail cp01-epoch-now; }
  assert_state MODE auto cp01-mode-kept
  assert_state SPEC 1 cp01-spec-kept
  assert_state TASK_PATH "$TP" cp01-taskpath-kept
}

test_dr_cp_02() { # [v4.5] startup·resume·clear·fork → .compact 를 만들지 않음
  local s
  for s in startup resume clear fork; do
    dr_setup_task
    rm -f "$STATE_DIR/$SID.compact"
    run_hook session-mode-guard.sh "$(dr_ss "$s")"
    assert_exit 0 "cp02-exit-$s"
    [ ! -e "$STATE_DIR/$SID.compact" ] || fail "cp02-no-compact-$s"
  done
}

test_dr_cp_03() { # [v4.5] startup·resume 는 기존 .compact 를 건드리지 않음(종전 동작 — 재독 의무 유지)
  local s
  for s in startup resume clear fork; do                    # 보충 10
    dr_setup_task
    dr_compact_at 1000
    printf '%s\t%s\n' 1001 "$SPECF" > "$STATE_DIR/$SID.reread"
    cp "$STATE_DIR/$SID.reread" "$SANDBOX/rr.before"
    run_hook session-mode-guard.sh "$(dr_ss "$s")"
    [ "$(cat "$STATE_DIR/$SID.compact")" = "1000" ] || fail "cp03-kept-$s"
    cmp -s "$SANDBOX/rr.before" "$STATE_DIR/$SID.reread" || fail "cp03-reread-kept-$s"
  done
}

test_dr_cp_04() { # [v4.5 I3·I6] 고정 지시 없음 → startup·resume·clear·fork 출력이 종전 훅과 바이트 동일
  dr_legacy_init
  local s
  for s in startup resume clear fork; do
    dr_setup_task; rm -f "$STATE_DIR/$SID.compact"
    dr_raw "$LEG/session-mode-guard.sh" "$(dr_ss "$s")" "$SANDBOX/old.$s"
    dr_setup_task; rm -f "$STATE_DIR/$SID.compact"
    dr_raw "$HOOKS_DIR/session-mode-guard.sh" "$(dr_ss "$s")" "$SANDBOX/new.$s"
    [ -s "$SANDBOX/old.$s" ] || fail "cp04-legacy-nonempty-$s"
    cmp -s "$SANDBOX/old.$s" "$SANDBOX/new.$s" || { echo "  [dbg] $s diff: $(diff "$SANDBOX/old.$s" "$SANDBOX/new.$s" | head -3)"; fail "cp04-identical-$s"; }
  done
}

test_dr_cp_05() { # [v4.5] compact + TASK_PATH → 종전 안내문 + 재독 안내 줄(정확한 문구)
  dr_legacy_init
  dr_setup_task
  dr_raw "$LEG/session-mode-guard.sh" "$(dr_ss compact)" "$SANDBOX/old"
  dr_setup_task; rm -f "$STATE_DIR/$SID.compact"
  dr_seen cp05-marker-created                                # 보충 13
  dr_raw "$HOOKS_DIR/session-mode-guard.sh" "$(dr_ss compact)" "$SANDBOX/new"
  dr_is_prefix "$SANDBOX/old" "$SANDBOX/new" || fail cp05-legacy-kept
  tail -c +"$(( $(wc -c < "$SANDBOX/old") + 1 ))" "$SANDBOX/new" | head -n 1 > "$SANDBOX/after"   # 보충 12
  grep -qxF "[게이트] 맥락이 압축됐습니다. 작업 폴더: $TP — requirement-spec.md · log.md · decisions.md를 Read 한 뒤 진행하세요." "$SANDBOX/after" \
    || fail cp05-guidance-right-after-legacy
  grep -qxF "[게이트] 맥락이 압축됐습니다. 작업 폴더: $TP — requirement-spec.md · log.md · decisions.md를 Read 한 뒤 진행하세요." "$SANDBOX/new" \
    || { echo "  [dbg] new-tail=$(tail -n 2 "$SANDBOX/new" | tr '\n' ' ')"; fail cp05-guidance-line; }
}

test_dr_cp_06() { # [v4.5] compact + TASK_PATH 없음 → 안내 줄 없음, 종전 출력과 바이트 동일, .compact 는 기록
  dr_legacy_init
  write_state auto
  dr_raw "$LEG/session-mode-guard.sh" "$(dr_ss compact)" "$SANDBOX/old"
  write_state auto; rm -f "$STATE_DIR/$SID.compact"
  dr_seen cp06-marker-created                                # 보충 13
  dr_raw "$HOOKS_DIR/session-mode-guard.sh" "$(dr_ss compact)" "$SANDBOX/new"
  assert_file_not_contains "$SANDBOX/new" '맥락이 압축됐습니다' cp06-no-guidance
  cmp -s "$SANDBOX/old" "$SANDBOX/new" || fail cp06-identical
  [ -f "$STATE_DIR/$SID.compact" ] || fail cp06-compact-recorded
}

test_dr_cp_07() { # [v4.5 보충 13·27] 이 세션 표시 파일 없음 → compact 여도 .compact·안내 줄 없음(종전 출력과 바이트 동일)·L1 차단 없음 / 표시 파일 생기면 종전 기대대로
  dr_legacy_init
  dr_setup_task
  dr_raw "$LEG/session-mode-guard.sh" "$(dr_ss compact)" "$SANDBOX/old"
  dr_setup_task
  [ ! -e "$STATE_DIR/$SID.reread-seen" ] || fail cp07-precondition-no-marker
  dr_raw "$HOOKS_DIR/session-mode-guard.sh" "$(dr_ss compact)" "$SANDBOX/new"
  [ ! -e "$STATE_DIR/$SID.compact" ] || fail cp07-no-compact-without-marker
  assert_file_not_contains "$SANDBOX/new" '맥락이 압축됐습니다' cp07-no-guidance-without-marker
  cmp -s "$SANDBOX/old" "$SANDBOX/new" || fail cp07-identical-without-marker
  dr_l1; assert_exit 0 cp07-no-block-without-marker
  dr_seen cp07-marker-created
  run_hook_stdout session-mode-guard.sh "$(dr_ss compact)"
  [ -f "$STATE_DIR/$SID.compact" ] || fail cp07-compact-with-marker
  assert_stdout_match '맥락이 압축됐습니다' cp07-guidance-with-marker
  dr_l1; assert_exit 2 cp07-block-with-marker
}

test_dr_cp_08() { # [v4.5 보충 13·27] reread-track 는 대상 아닌 Read·agent_id 있는 Read·TASK_PATH 없음에서도 표시 파일을 만든다
  write_state auto
  [ ! -e "$STATE_DIR/$SID.reread-seen" ] || fail cp08-precondition
  dr_read_hook "$REPO/README.md"
  assert_exit 0 cp08-nontarget-exit
  [ -e "$STATE_DIR/$SID.reread-seen" ] || fail cp08-marker-nontarget-no-taskpath
  rm -f "$STATE_DIR/$SID.reread-seen"
  dr_read_hook "$REPO/README.md" agent-5
  [ -e "$STATE_DIR/$SID.reread-seen" ] || fail cp08-marker-agent-read
  rm -f "$STATE_DIR/$SID.reread-seen"
  dr_add_task
  dr_read_hook "$SPECF" agent-6
  [ -e "$STATE_DIR/$SID.reread-seen" ] || fail cp08-marker-agent-target-read
  dr_reread_has "$SPECF" && fail cp08-agent-read-not-recorded
  return 0
}

test_dr_cp_09() { # [v4.5 보충 13·27] 현재 세션의 표시 파일은 prune 대상 아님(31일 지난 mtime 이어도 SessionStart 뒤 남음)
  write_state auto
  dr_seen cp09-marker-created
  touch -d '31 days ago' "$STATE_DIR/$SID.reread-seen"
  run_hook session-mode-guard.sh "$(dr_ss startup)"
  assert_exit 0 cp09-exit
  [ -e "$STATE_DIR/$SID.reread-seen" ] || fail cp09-marker-survives-prune
}

test_dr_cp_10() { # [v4.5 보충 17] prune 은 현재 세션 .compact·.reread 와 모든 세션 *.decisions 를 지우지 않음
  dr_setup_task
  dr_compact_at 1000
  printf '%s\t%s\n' 1001 "$SPECF" > "$STATE_DIR/$SID.reread"
  local other="${SID}o"
  printf '## 2026-01-01 00:00:00 (toolu_o)\n' > "$STATE_DIR/$other.decisions"
  printf '## 2026-01-01 00:00:00 (toolu_me)\n' > "$STATE_DIR/$SID.decisions"
  printf '1000\n' > "$STATE_DIR/$other.compact"; printf '1\tx\n' > "$STATE_DIR/$other.reread"   # 다른 세션 것 — 지워져도 됨(단정 안 함)
  touch -d '31 days ago' "$STATE_DIR/$SID.compact" "$STATE_DIR/$SID.reread" "$STATE_DIR/$other.decisions" \
    "$STATE_DIR/$SID.decisions" "$STATE_DIR/$other.compact" "$STATE_DIR/$other.reread"
  run_hook session-mode-guard.sh "$(dr_ss startup)"
  assert_exit 0 cp10-exit
  [ -f "$STATE_DIR/$SID.compact" ] || fail cp10-own-compact-kept
  [ -f "$STATE_DIR/$SID.reread" ] || fail cp10-own-reread-kept
  [ -f "$STATE_DIR/$other.decisions" ] || fail cp10-other-decisions-kept
  [ -f "$STATE_DIR/$SID.decisions" ] || fail cp10-own-decisions-kept
}

test_dr_cp_11() { # [v4.5 보충 27 a] 다른 세션 A 가 Read 해 표시 파일을 만들어도, Read 한 적 없는 세션 B 의 compact 는 .compact 를 쓰지 않고 L1 을 막지 않음
  dr_setup_task                                              # 세션 B = $SID (TASK_PATH 있음, Read 없음)
  local A="${SID}a"
  printf 'SCHEMA=4\nMODE=auto\nSPEC=1\nPENDING_GATE=0\nDEBT=0\nTASK_PATH=%s\n' "$TP" > "$STATE_DIR/$A"
  run_hook reread-track.sh "$(dr_read "$REPO/README.md" | jq -c --arg s "$A" '.session_id=$s')"
  assert_exit 0 cp11-a-read-exit
  [ -e "$STATE_DIR/$A.reread-seen" ] || fail cp11-a-marker-created
  [ ! -e "$STATE_DIR/$SID.reread-seen" ] || fail cp11-b-no-marker
  run_hook_stdout session-mode-guard.sh "$(dr_ss compact)"
  assert_exit 0 cp11-b-compact-exit
  [ ! -e "$STATE_DIR/$SID.compact" ] || fail cp11-b-no-compact
  assert_stdout_no_match '맥락이 압축됐습니다' cp11-b-no-guidance
  dr_l1; assert_exit 0 cp11-b-no-block
  dr_seen cp11-b-marker-after-read                           # 대조: B 가 Read 하면 B 의 compact 가 기록됨
  run_hook session-mode-guard.sh "$(dr_ss compact)"
  [ -f "$STATE_DIR/$SID.compact" ] || fail cp11-b-compact-after-own-read
}

test_dr_cp_12() { # [v4.5 보충 27 b] 옛 디렉토리 단위 .reread-hook-seen 만 있고 세션 표시 파일이 없으면 compact 가 .compact 를 쓰지 않음
  dr_setup_task
  : > "$STATE_DIR/.reread-hook-seen"
  run_hook session-mode-guard.sh "$(dr_ss compact)"
  assert_exit 0 cp12-exit
  [ ! -e "$STATE_DIR/$SID.compact" ] || fail cp12-legacy-marker-ignored
  dr_l1; assert_exit 0 cp12-no-block
  dr_seen cp12-session-marker
  run_hook session-mode-guard.sh "$(dr_ss compact)"
  [ -f "$STATE_DIR/$SID.compact" ] || fail cp12-control-session-marker
}

test_dr_cp_13() { # [v4.5 보충 27 c] session_id 가 없거나 유효하지 않은 Read → 표시 파일 없음, exit 0
  write_state auto
  run_hook reread-track.sh "$(dr_read "$REPO/README.md" | jq -c 'del(.session_id)')"
  assert_exit 0 cp13-nosid-exit
  run_hook reread-track.sh "$(dr_read "$REPO/README.md" | jq -c '.session_id="bad.sid/x"')"
  assert_exit 0 cp13-badsid-exit
  [ -z "$(find "$SANDBOX" -name '*.reread-seen' 2>/dev/null)" ] || fail cp13-no-marker
  [ ! -e "$STATE_DIR/.reread-hook-seen" ] || fail cp13-no-dir-marker
  dr_seen cp13-control-valid-sid
}

# ══ I4 재독 판정 (reread-track.sh + 판정은 gate-guard 차단으로 관측) ═══════════════

test_dr_rr_01() { # [v4.5] 압축 뒤 아무것도 안 읽음 → 미독(차단). decisions.md 없음 → 대상 = spec·log
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1
  assert_exit 2 rr01-blocked
  assert_stderr_match "$SPECF" rr01-spec-listed
  assert_stderr_match "$LOGF" rr01-log-listed
  assert_stderr_no_match 'decisions\.md' rr01-absent-decisions-not-listed
}

test_dr_rr_02() { # [v4.5] 대상 세 파일(decisions.md 있음)을 압축 뒤 모두 Read → 해제
  dr_setup_task; printf '%s\n' "$DR_TITLE" > "$DECF"
  dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1; assert_exit 2 rr02-control-blocked
  dr_read_targets
  assert_exit 0 rr02-read-exit
  dr_l1
  assert_exit 0 rr02-released
}

test_dr_rr_03() { # [v4.5] 하나만 읽음 → 미독 유지, 읽지 않은 것만 차단 문구에
  dr_setup_task; printf '%s\n' "$DR_TITLE" > "$DECF"
  dr_compact_at $(( $(dr_now) - 100 ))
  dr_read_hook "$SPECF"
  dr_l1
  assert_exit 2 rr03-still-blocked
  assert_stderr_match "$LOGF" rr03-log-listed
  assert_stderr_match "$DECF" rr03-decisions-listed
  assert_stderr_no_match "$SPECF" rr03-read-not-listed
}

test_dr_rr_04() { # [v4.5] decisions.md 가 있으면 대상 — spec·log 만 읽으면 미독
  dr_setup_task; printf '%s\n' "$DR_TITLE" > "$DECF"
  dr_compact_at $(( $(dr_now) - 100 ))
  dr_read_hook "$SPECF"; dr_read_hook "$LOGF"
  dr_l1
  assert_exit 2 rr04-decisions-required
  assert_stderr_match "$DECF" rr04-decisions-listed
}

test_dr_rr_05() { # [v4.5] decisions.md 없으면 spec·log 두 파일만으로 해제
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1; assert_exit 2 rr05-control-blocked
  dr_read_hook "$SPECF"; dr_read_hook "$LOGF"
  dr_l1
  assert_exit 0 rr05-two-files-release
}

test_dr_rr_06() { # [v4.5] 압축 전에 읽은 기록은 인정 안 됨 (fixture .reread 시각 < 압축 시각)
  dr_setup_task
  local c; c=$(( $(dr_now) - 100 ))
  dr_compact_at "$c"
  printf '%s\t%s\n%s\t%s\n' "$((c-50))" "$SPECF" "$((c-50))" "$LOGF" > "$STATE_DIR/$SID.reread"
  dr_l1
  assert_exit 2 rr06-stale-fixture-blocked
}

test_dr_rr_06b() { # [v4.5] 압축 전 Read(훅 기록) 뒤 압축 → 미독
  dr_setup_task
  dr_read_hook "$SPECF"; dr_read_hook "$LOGF"
  dr_compact_at $(( $(dr_now) + 100 ))     # 읽은 뒤에 일어난 압축
  dr_l1
  assert_exit 2 rr06b-read-before-compact-blocked
}

test_dr_rr_07() { # [v4.5] '이상' 경계: 읽은 시각 == 압축 시각 → 읽음
  dr_setup_task
  local c; c=$(( $(dr_now) - 100 ))
  dr_compact_at "$c"
  printf '%s\t%s\n%s\t%s\n' "$((c-1))" "$SPECF" "$c" "$LOGF" > "$STATE_DIR/$SID.reread"
  dr_l1; assert_exit 2 rr07-control-one-second-before
  printf '%s\t%s\n%s\t%s\n' "$c" "$SPECF" "$c" "$LOGF" > "$STATE_DIR/$SID.reread"
  dr_l1
  assert_exit 0 rr07-equal-is-read
}

test_dr_rr_07b() { # [v4.5 보충 8] 읽는 쪽은 소수 초 표기도 받아들여 수로 비교 (같은 값 = 읽음)
  dr_setup_task
  local c; c=$(( $(dr_now) - 100 ))
  printf '%s.500000000\n' "$c" > "$STATE_DIR/$SID.compact"
  printf '%s.200000000\t%s\n%s.900000000\t%s\n' "$c" "$SPECF" "$c" "$LOGF" > "$STATE_DIR/$SID.reread"
  dr_l1; assert_exit 2 rr07b-fraction-before-unread
  printf '%s.500000000\t%s\n%s\t%s\n' "$c" "$SPECF" "$((c+1))" "$LOGF" > "$STATE_DIR/$SID.reread"
  dr_l1; assert_exit 0 rr07b-fraction-equal-and-int-read
  printf '%s\n' "$c" > "$STATE_DIR/$SID.compact"
  printf '%s.000000000\t%s\n%s\t%s\n' "$c" "$SPECF" "$c" "$LOGF" > "$STATE_DIR/$SID.reread"
  dr_l1; assert_exit 0 rr07b-int-compact-vs-fraction-equal
}

test_dr_rr_08() { # [v4.5] 재압축 → 다시 미독 (session-mode-guard compact 가 .compact 갱신)
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  dr_read_targets
  dr_l1; assert_exit 0 rr08-released-first
  # 읽은 기록을 과거로 밀어 '그 뒤 재압축' 을 결정론적으로 재현 (형식: <epoch>\t<path>)
  [ -f "$STATE_DIR/$SID.reread" ] || fail rr08-reread-recorded
  local old=$(( $(dr_now) - 10 ))
  sed -i -E "s/^[0-9]+\t/$old\t/" "$STATE_DIR/$SID.reread"
  run_hook session-mode-guard.sh "$(dr_ss compact)"
  [ "$(head -1 "$STATE_DIR/$SID.compact")" -gt "$old" ] || fail rr08-compact-updated
  dr_l1
  assert_exit 2 rr08-relocked
  dr_read_targets
  dr_l1
  assert_exit 0 rr08-released-again
}

test_dr_rr_09() { # [v4.5] agent_id 있는 Read 는 기록 안 됨(서브에이전트가 읽어도 메인 맥락 복구 아님)
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  dr_read_hook "$SPECF" agent-9; dr_read_hook "$LOGF" agent-9
  assert_exit 0 rr09-exit
  dr_reread_has "$SPECF" && fail rr09-not-recorded
  dr_l1
  assert_exit 2 rr09-still-blocked
}

test_dr_rr_10() { # [v4.5] 대상이 아닌 파일 Read 는 무시
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  printf 'x\n' > "$TP/other.md"
  dr_read_hook "$REPO/README.md"; dr_read_hook "$TP/other.md"
  assert_exit 0 rr10-exit
  if grep -qF 'README.md' "$STATE_DIR/$SID.reread" 2>/dev/null; then fail rr10-readme-ignored; fi
  if grep -qF 'other.md' "$STATE_DIR/$SID.reread" 2>/dev/null; then fail rr10-other-ignored; fi
  dr_l1
  assert_exit 2 rr10-still-blocked
}

test_dr_rr_11() { # [v4.5] 심링크 경유 경로 → canonical 로 일치(기록은 canonical 경로)
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1; assert_exit 2 rr11-control-blocked
  ln -s "$REPO" "$SANDBOX/lnk"
  local rel="${TP#"$(realpath -m -- "$REPO")"/}"
  dr_read_hook "$SANDBOX/lnk/$rel/requirement-spec.md"; dr_read_hook "$SANDBOX/lnk/$rel/log.md"
  dr_reread_has "$SPECF" || fail rr11-canonical-recorded
  dr_l1
  assert_exit 0 rr11-symlink-release
}

test_dr_rr_12() { # [v4.5] '..' 가 든 경로 → canonical 일치
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1; assert_exit 2 rr12-control-blocked
  dr_read_hook "$TP/../t1/requirement-spec.md"; dr_read_hook "$TP/../t1/./log.md"
  dr_l1
  assert_exit 0 rr12-dotdot-release
}

test_dr_rr_13() { # [v4.5] 상대 경로(cwd 기준) → canonical 일치
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1; assert_exit 2 rr13-control-blocked
  local rel="${TP#"$(realpath -m -- "$REPO")"/}"
  dr_read_hook "$rel/requirement-spec.md"; dr_read_hook "$rel/log.md"
  dr_l1
  assert_exit 0 rr13-relative-release
}

test_dr_rr_14() { # [v4.5] 부분 읽기(offset/limit)도 읽음으로 인정
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1; assert_exit 2 rr14-control-blocked
  dr_read_hook "$SPECF" "" 40 25; dr_read_hook "$LOGF" "" 1 1
  dr_l1
  assert_exit 0 rr14-partial-release
}

test_dr_rr_15() { # [v4.5] .reread 형식 = 줄마다 <epoch>\t<canonical> · 같은 파일 재Read 는 그 줄을 교체(중복 줄 없음)
  dr_setup_task
  dr_read_hook "$SPECF"
  printf '%s\t%s\n' 5 "$SPECF" > "$STATE_DIR/$SID.reread"    # 옛 시각으로 고정
  dr_read_hook "$SPECF"; dr_read_hook "$LOGF"
  local f="$STATE_DIR/$SID.reread"
  [ "$(grep -cF "	$SPECF" "$f" || true)" = "1" ] || fail rr15-one-line-per-path
  awk -F'\t' -v p="$SPECF" '$2 == p && $1 ~ /^[0-9]+$/ && NF == 2 {ok=1} END {exit !ok}' "$f" || fail rr15-format
  [ "$(grep -F "	$SPECF" "$f" | cut -f1)" -gt 5 ] || fail rr15-time-updated
  if grep -qvE '^[0-9]+	/' "$f"; then fail rr15-all-lines-format; fi
}

test_dr_rr_16() { # [v4.5 I7] reread-track: 깨진 stdin·TASK_PATH 없음 → exit 0 (관측 훅 — 막지 않음)
  run_hook reread-track.sh 'not-json {{{'
  assert_exit 0 rr16-garbage-exit
  write_state auto
  dr_read_hook "$REPO/README.md"
  assert_exit 0 rr16-no-taskpath-exit
}

# ══ I5 미독 중 강제 (gate-guard 차단 · reinject 재주입) ═════════════════════════

test_dr_bl_01() { # [v4.5] 미독 + L1 Write → exit 2, 계약 문구로 시작하는 줄 + 읽을 경로 줄마다
  dr_setup_task; printf '%s\n' "$DR_TITLE" > "$DECF"
  dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1 Write
  assert_exit 2 bl01-exit
  printf '%s\n' "$HOOK_STDERR" | grep -q '^\[gate-guard\] 압축 뒤 작업 기록 미독 — 다음 파일을 Read 한 뒤 다시 시도:' \
    || { echo "  [dbg] stderr=$(printf '%s' "$HOOK_STDERR" | head -n 3 | tr '\n' ' ')"; fail bl01-message-prefix; }
  local p q
  for p in "$SPECF" "$LOGF" "$DECF"; do
    printf '%s\n' "$HOOK_STDERR" | grep -qF -- "$p" || fail bl01-path-listed
    for q in "$SPECF" "$LOGF" "$DECF"; do       # 경로는 줄마다 하나
      [ "$p" = "$q" ] && continue
      if printf '%s\n' "$HOOK_STDERR" | grep -F -- "$p" | grep -qF -- "$q"; then fail bl01-one-path-per-line; fi
    done
  done
  local f="$SANDBOX/bl01.err" note last; printf '%s\n' "$HOOK_STDERR" > "$f"     # 보충 23
  note=$(grep -nF '(offset·limit 부분 읽기도 인정)' "$f" | head -1 | cut -d: -f1)
  last=$(grep -nF -e "$SPECF" -e "$LOGF" -e "$DECF" "$f" | tail -1 | cut -d: -f1)
  [ -n "$note" ] || fail bl01-partial-read-note
  [ "$note" -gt "$last" ] || fail bl01-partial-read-note-after-paths
}

test_dr_bl_02() { # [v4.5] Edit·MultiEdit 도 차단
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1 Edit;      assert_exit 2 bl02-edit-blocked
  assert_stderr_match '압축 뒤 작업 기록 미독' bl02-edit-msg
  dr_l1 MultiEdit; assert_exit 2 bl02-multiedit-blocked
  assert_stderr_match '압축 뒤 작업 기록 미독' bl02-multiedit-msg
}

test_dr_bl_03() { # [v4.5] 미독이어도 L0(docs/**) 쓰기는 통과 — 작업 폴더 log.md·다른 docs
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  run_hook gate-guard.sh "$(dr_tool PreToolUse Write "$LOGF")"
  assert_exit 0 bl03-log-pass
  run_hook gate-guard.sh "$(dr_tool PreToolUse Edit "$REPO/docs/notes.md")"
  assert_exit 0 bl03-docs-pass
  dr_l1; assert_exit 2 bl03-control-l1-blocked
}

test_dr_bl_04() { # [v4.5] agent_id 있는 쓰기는 이 차단 대상 아님
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1 Write agent-77
  assert_exit 0 bl04-subagent-pass
  assert_stderr_no_match '압축 뒤 작업 기록 미독' bl04-no-msg
  dr_l1 Write; assert_exit 2 bl04-control-main-blocked
}

test_dr_bl_05() { # [v4.5] TASK_PATH 없음 → 재독 강제 없음
  write_state auto; dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1
  assert_exit 0 bl05-no-taskpath-pass
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1; assert_exit 2 bl05-control-with-taskpath
}

test_dr_bl_06() { # [v4.5] .compact 없음 → 미독 아님 (압축 전 세션)
  dr_setup_task
  dr_l1
  assert_exit 0 bl06-no-compact-pass
  dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1; assert_exit 2 bl06-control-with-compact
}

test_dr_bl_07() { # [v4.5 I8] 종전 SPEC/MODE 차단이 먼저 — 그 문구 그대로, 미독 문구 없음
  dr_setup_task UNSET 0 0 0; dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1
  assert_exit 2 bl07-spec0-exit
  dr_reason_first '요구사항 명세 미합의\(SPEC=0\)' bl07-spec0-first
  dr_setup_task UNSET 0 0 1; dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1
  assert_exit 2 bl07-unset-exit
  dr_reason_first '자율성 미선택\(MODE=UNSET\)' bl07-unset-first
}

test_dr_bl_08() { # [v4.5 I7] 사이드카가 깨져 판정 불가 → 새 차단 없음(종전 판정만: auto → 통과)
  dr_setup_task
  printf 'garbage\n' > "$STATE_DIR/$SID.compact"
  dr_l1
  assert_exit 0 bl08-garbage-compact-pass
  rm -f "$STATE_DIR/$SID.compact"; mkdir "$STATE_DIR/$SID.compact"
  dr_l1
  assert_exit 0 bl08-dir-compact-pass
  rmdir "$STATE_DIR/$SID.compact"; : > "$STATE_DIR/$SID.compact"   # 보충 7: 빈 파일
  dr_l1
  assert_exit 0 bl08-empty-compact-pass
  dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1; assert_exit 2 bl08-control-valid-compact
}

test_dr_bl_08b() { # [v4.5 I7] .reread 읽기 실패(권한) → 판정 불가 → 새 차단 없음
  dr_root_skip && return 0
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  printf '%s\t%s\n' 1 "$SPECF" > "$STATE_DIR/$SID.reread"
  chmod 000 "$STATE_DIR/$SID.reread"
  dr_l1
  chmod 644 "$STATE_DIR/$SID.reread"
  assert_exit 0 bl08b-unreadable-reread-pass
  dr_l1; assert_exit 2 bl08b-control-readable-unread
}

test_dr_bl_08c() { # [v4.5 보충 7] 판정 불가(.compact 숫자 아님·빔·디렉토리 / .reread 읽기 불가) → reinject 미독 알림도 없음
  dr_setup_task
  local v c="$STATE_DIR/$SID.compact"
  for v in garbage empty dir; do
    if [ -d "$c" ]; then rmdir "$c"; fi
    case "$v" in garbage) printf 'abc\n' > "$c" ;; empty) : > "$c" ;; dir) rm -f "$c"; mkdir "$c" ;; esac
    run_hook_stdout reinject-mode.sh "$(json_prompt '계속')"
    assert_exit 0 "bl08c-exit-$v"
    assert_stdout_no_match '압축 뒤 작업 기록 미독' "bl08c-no-notice-$v"
  done
  rmdir "$c"; dr_compact_at $(( $(dr_now) - 100 ))
  if ! dr_root_skip; then
    printf '%s\t%s\n' 1 "$SPECF" > "$STATE_DIR/$SID.reread"; chmod 000 "$STATE_DIR/$SID.reread"
    run_hook_stdout reinject-mode.sh "$(json_prompt '계속')"
    chmod 644 "$STATE_DIR/$SID.reread"
    assert_stdout_no_match '압축 뒤 작업 기록 미독' bl08c-no-notice-unreadable-reread
  fi
  run_hook_stdout reinject-mode.sh "$(json_prompt '계속')"
  assert_stdout_match '압축 뒤 작업 기록 미독' bl08c-control-notice
}

test_dr_bl_09() { # [v4.5] 차단 → 재독 → 같은 쓰기 통과 (exit 2 가 미독 때문이었음을 확인)
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1; assert_exit 2 bl09-before
  dr_read_targets
  dr_l1; assert_exit 0 bl09-after
}

test_dr_bl_10() { # [v4.5] Bash·Read 는 미독이어도 막지 않음, PostToolUse(auto) 는 exit 0
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  run_hook gate-guard.sh "$(json_bash 'ls src')"
  assert_exit 0 bl10-bash-pass
  run_hook gate-guard.sh "$(dr_read "$SPECF" | jq -c '.hook_event_name="PreToolUse"')"
  assert_exit 0 bl10-read-pass
  run_hook gate-guard.sh "$(dr_tool PostToolUse Edit "$REPO/src/app.sh")"
  assert_exit 0 bl10-post-pass
  dr_l1; assert_exit 2 bl10-control-still-unread   # 위 통과가 '미독 아님' 때문이 아님을 확인
}

test_dr_bl_11() { # [v4.5] lazy(PENDING_GATE=0) 에서도 미독이면 차단
  dr_setup_task lazy 0 0 1; dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1
  assert_exit 2 bl11-lazy-blocked
  assert_stderr_match '압축 뒤 작업 기록 미독' bl11-lazy-msg
}

test_dr_bl_11b() { # [v4.5 보충 11] lazy PENDING_GATE=1 + 미독 → PENDING 문구가 먼저 · PostToolUse 동작은 종전 그대로
  dr_setup_task lazy 1 0 1; dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1
  assert_exit 2 bl11b-pending-exit
  dr_reason_first '이해 게이트가 미처리\(PENDING_GATE=1\)' bl11b-pending-first
  dr_setup_task lazy 0 0 1; dr_compact_at $(( $(dr_now) - 100 ))
  run_hook gate-guard.sh "$(dr_tool PostToolUse Edit "$REPO/src/app.sh")"
  assert_exit 0 bl11b-post-exit
  assert_state PENDING_GATE 1 bl11b-post-pending-set
  assert_stderr_no_match '압축 뒤 작업 기록 미독' bl11b-post-no-unread-msg
}

test_dr_ri_01() { # [v4.5] reinject: 미독 → 종전 출력 뒤에 미독 줄 + 읽지 않은 경로
  dr_legacy_init
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  dr_raw "$LEG/reinject-mode.sh" "$(json_prompt '계속')" "$SANDBOX/old"
  dr_raw "$HOOKS_DIR/reinject-mode.sh" "$(json_prompt '계속')" "$SANDBOX/new"
  dr_is_prefix "$SANDBOX/old" "$SANDBOX/new" || fail ri01-legacy-prefix
  assert_file_contains "$SANDBOX/new" '[게이트] 압축 뒤 작업 기록 미독 — 구현 파일 쓰기 전에 Read:' ri01-line
  assert_file_contains "$SANDBOX/new" "$SPECF" ri01-spec-path
  assert_file_contains "$SANDBOX/new" "$LOGF" ri01-log-path
}

test_dr_ri_02() { # [v4.5] reinject: 일부 읽음 → 읽은 경로는 빠짐 / 전부 읽음 → 미독 줄 사라지고 종전 출력과 바이트 동일
  dr_legacy_init
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  dr_read_hook "$SPECF"
  dr_raw "$HOOKS_DIR/reinject-mode.sh" "$(json_prompt '계속')" "$SANDBOX/mid"
  assert_file_contains "$SANDBOX/mid" '압축 뒤 작업 기록 미독' ri02-still-unread
  assert_file_not_contains "$SANDBOX/mid" "$SPECF" ri02-read-path-dropped
  assert_file_contains "$SANDBOX/mid" "$LOGF" ri02-unread-path-kept
  dr_read_hook "$LOGF"
  dr_raw "$LEG/reinject-mode.sh" "$(json_prompt '계속')" "$SANDBOX/old"
  dr_raw "$HOOKS_DIR/reinject-mode.sh" "$(json_prompt '계속')" "$SANDBOX/new"
  assert_file_not_contains "$SANDBOX/new" '압축 뒤 작업 기록 미독' ri02-line-gone
  cmp -s "$SANDBOX/old" "$SANDBOX/new" || fail ri02-identical-after-release
}

test_dr_ri_03() { # [v4.5] reinject: TASK_PATH 없음 또는 .compact 없음 → 미독 줄 없음
  write_state auto; dr_compact_at $(( $(dr_now) - 100 ))
  run_hook_stdout reinject-mode.sh "$(json_prompt '계속')"
  assert_exit 0 ri03-exit
  assert_stdout_match 'MODE=auto' ri03-base
  assert_stdout_no_match '압축 뒤 작업 기록 미독' ri03-no-taskpath
  dr_setup_task; rm -f "$STATE_DIR/$SID.compact"
  run_hook_stdout reinject-mode.sh "$(json_prompt '계속')"
  assert_stdout_no_match '압축 뒤 작업 기록 미독' ri03-no-compact
  dr_compact_at $(( $(dr_now) - 100 ))
  run_hook_stdout reinject-mode.sh "$(json_prompt '계속')"
  assert_stdout_match '압축 뒤 작업 기록 미독' ri03-control-shown
}

# ══ I6 고정 지시 재주입 (reinject-mode · session-mode-guard) ═════════════════════

DR_SI='# 주석: 이 줄은 들어가면 안 된다\n\n항상 한국어로 답한다\n   \n#또다른주석\n커밋 메시지는 영어로 쓴다\n'

test_dr_si_01() { # [v4.5] reinject: 파일 있음 → 종전 출력 뒤 끝에 [고정 지시] + 유효 줄, 주석·빈 줄 제외
  dr_legacy_init
  dr_setup_task
  dr_raw "$LEG/reinject-mode.sh" "$(json_prompt '계속')" "$SANDBOX/old"
  dr_standing "$DR_SI"
  dr_raw "$HOOKS_DIR/reinject-mode.sh" "$(json_prompt '계속')" "$SANDBOX/new"
  dr_is_prefix "$SANDBOX/old" "$SANDBOX/new" || fail si01-legacy-prefix
  assert_file_contains "$SANDBOX/new" '[고정 지시] ' si01-prefix
  assert_file_contains "$SANDBOX/new" '항상 한국어로 답한다' si01-line1
  assert_file_contains "$SANDBOX/new" '커밋 메시지는 영어로 쓴다' si01-line2
  assert_file_not_contains "$SANDBOX/new" '주석' si01-no-comment
  grep -qxF '[고정 지시] 항상 한국어로 답한다' "$SANDBOX/new" || fail si01-per-line-prefix-1   # 보충 1
  grep -qxF '[고정 지시] 커밋 메시지는 영어로 쓴다' "$SANDBOX/new" || fail si01-per-line-prefix-2
  local a b; a=$(dr_lineno "$SANDBOX/new" '항상 한국어로 답한다'); b=$(dr_lineno "$SANDBOX/new" '커밋 메시지는 영어로 쓴다')
  [ "$a" -le "$b" ] || fail si01-line-order
  # 출력 끝: 마지막 비어 있지 않은 줄에 마지막 지시가 있다
  [ "$(grep -v '^[[:space:]]*$' "$SANDBOX/new" | tail -1 | grep -cF '커밋 메시지는 영어로 쓴다' || true)" = "1" ] || fail si01-at-end
}

test_dr_si_02() { # [v4.5] reinject: 상태파일이 없어도, MODE=UNSET 이어도 주입
  dr_standing "$DR_SI"
  rm -f "$STATE"
  run_hook_stdout reinject-mode.sh "$(json_prompt '계속')"
  assert_exit 0 si02-nostate-exit
  assert_stdout_match '\[고정 지시\] ' si02-nostate-injected
  assert_stdout_match '항상 한국어로 답한다' si02-nostate-line
  write_state UNSET 0 0 0
  run_hook_stdout reinject-mode.sh "$(json_prompt '계속')"
  assert_stdout_match '\[고정 지시\] ' si02-unset-injected
  assert_stdout_match '커밋 메시지는 영어로 쓴다' si02-unset-line
}

test_dr_si_03() { # [v4.5] session-mode-guard: 모든 source 에서 출력 끝에 고정 지시 (종전 출력은 접두로 유지)
  dr_legacy_init
  local s
  for s in startup resume clear compact fork; do
    rm -f "$HOME_DIR/.claude/standing-instructions.md"
    write_state auto; rm -f "$STATE_DIR/$SID.compact"
    dr_raw "$LEG/session-mode-guard.sh" "$(dr_ss "$s")" "$SANDBOX/old.$s"
    dr_standing "$DR_SI"
    write_state auto; rm -f "$STATE_DIR/$SID.compact"
    dr_raw "$HOOKS_DIR/session-mode-guard.sh" "$(dr_ss "$s")" "$SANDBOX/new.$s"
    dr_is_prefix "$SANDBOX/old.$s" "$SANDBOX/new.$s" || fail "si03-legacy-prefix-$s"
    assert_file_contains "$SANDBOX/new.$s" '[고정 지시] ' "si03-injected-$s"
    assert_file_contains "$SANDBOX/new.$s" '항상 한국어로 답한다' "si03-line-$s"
    assert_file_not_contains "$SANDBOX/new.$s" '주석' "si03-no-comment-$s"
  done
}

test_dr_si_04() { # [v4.5] session-mode-guard compact + TASK_PATH: 재독 안내 줄 뒤(출력 끝)에 고정 지시
  dr_standing "$DR_SI"
  dr_setup_task
  dr_seen si04-marker-created                                # 보충 13
  dr_raw "$HOOKS_DIR/session-mode-guard.sh" "$(dr_ss compact)" "$SANDBOX/new"
  local g s; g=$(dr_lineno "$SANDBOX/new" '맥락이 압축됐습니다'); s=$(dr_lineno "$SANDBOX/new" '[고정 지시]')
  { [ -n "$g" ] && [ -n "$s" ] && [ "$g" -lt "$s" ]; } || { echo "  [dbg] g=$g s=$s"; fail si04-standing-last; }
}

# 고정 지시 출력에서 종전 출력(접두)을 뺀 나머지만 <out>.rest 로 — 글자 세기는 여기서만(종전 안내문 글자 오염 방지)
dr_rest_after_legacy() { # <legacy-out> <new-out>
  dr_is_prefix "$1" "$2" || return 1
  tail -c +"$(( $(wc -c < "$1") + 1 ))" "$2" > "$2.rest"
}
dr_si_run_pair() { # <hook> <outbase> — 종전(고정 지시 없음)·새 훅(고정 지시 있음) 출력. 상태는 auto 로 재설정
  local h=$1 o=$2 j
  if [ "$h" = reinject-mode.sh ]; then j=$(json_prompt '계속'); else j=$(dr_ss startup); fi
  write_state auto; dr_raw "$LEG/$h" "$j" "$o.old"
  write_state auto; dr_raw "$HOOKS_DIR/$h" "$j" "$o.new"
}
dr_ccount() { LC_ALL=C grep -o "$2" "$1" 2>/dev/null | wc -l; }   # <file> <글자> → 등장 횟수(바이트열 일치)

test_dr_si_05() { # [v4.5 보충 2] 1,500자 초과 → 1,500자로 자르고 마지막 줄 끝에 '…(잘림)' (reinject·session 둘 다)
  dr_legacy_init
  local long; long=$(printf '꿻%.0s' $(seq 1 2000))
  dr_standing "$long\n"
  local h o
  for h in reinject-mode.sh session-mode-guard.sh; do
    o="$SANDBOX/trunc.$h"; dr_si_run_pair "$h" "$o"
    [ "$(dr_ccount "$o.old" '꿻')" = "0" ] || fail "si05-fixture-absent-in-legacy-$h"
    dr_rest_after_legacy "$o.old" "$o.new" || fail "si05-legacy-prefix-$h"
    assert_file_contains "$o.new.rest" '…(잘림)' "si05-marker-$h"
    [ "$(dr_ccount "$o.new.rest" '꿻')" = "1500" ] || { echo "  [dbg] n=$(dr_ccount "$o.new.rest" '꿻')"; fail "si05-exactly-1500-$h"; }
    [ "$(grep -v '^[[:space:]]*$' "$o.new.rest" | tail -1 | grep -c '…(잘림)$' || true)" = "1" ] || fail "si05-marker-at-last-line-end-$h"
    grep -q '^\[고정 지시\] 꿻' "$o.new.rest" || fail "si05-prefixed-$h"
  done
}

test_dr_si_05b() { # [v4.5 보충 2] 경계: 정확히 1,500자는 자르지 않고 1,501자는 자름 (한 줄)
  dr_legacy_init
  local h o n
  for n in 1500 1501; do
    dr_standing "$(printf '꿻%.0s' $(seq 1 "$n"))\n"
    for h in reinject-mode.sh session-mode-guard.sh; do
      o="$SANDBOX/b$n.$h"; dr_si_run_pair "$h" "$o"
      dr_rest_after_legacy "$o.old" "$o.new" || fail "si05b-legacy-prefix-$n-$h"
      if [ "$n" = 1500 ]; then
        assert_file_not_contains "$o.new.rest" '…(잘림)' "si05b-1500-not-cut-$h"
        [ "$(dr_ccount "$o.new.rest" '꿻')" = "1500" ] || fail "si05b-1500-full-$h"
      else
        assert_file_contains "$o.new.rest" '…(잘림)' "si05b-1501-cut-$h"
        [ "$(dr_ccount "$o.new.rest" '꿻')" = "1500" ] || fail "si05b-1501-to-1500-$h"
      fi
    done
  done
}

test_dr_si_05c() { # [v4.5 보충 2] 여러 줄: 줄 사이 줄바꿈도 센다 (749+1+750=1,500 그대로 / 750+1+750=1,501 자름)
  dr_legacy_init
  local o a b
  a=$(printf '꿻%.0s' $(seq 1 749)); b=$(printf '뷁%.0s' $(seq 1 750))
  dr_standing "$a\n$b\n"
  o="$SANDBOX/ml1500"; dr_si_run_pair reinject-mode.sh "$o"
  dr_rest_after_legacy "$o.old" "$o.new" || fail si05c-legacy-prefix-1500
  assert_file_not_contains "$o.new.rest" '…(잘림)' si05c-1500-not-cut
  [ "$(dr_ccount "$o.new.rest" '뷁')" = "750" ] || fail si05c-1500-second-line-full
  a=$(printf '꿻%.0s' $(seq 1 750))
  dr_standing "$a\n$b\n"
  o="$SANDBOX/ml1501"; dr_si_run_pair reinject-mode.sh "$o"
  dr_rest_after_legacy "$o.old" "$o.new" || fail si05c-legacy-prefix-1501
  assert_file_contains "$o.new.rest" '…(잘림)' si05c-1501-cut
  [ "$(dr_ccount "$o.new.rest" '뷁')" = "749" ] || { echo "  [dbg] n=$(dr_ccount "$o.new.rest" '뷁')"; fail si05c-1501-second-line-749; }
  grep -qxF "[고정 지시] $a" "$o.new.rest" || fail si05c-first-line-intact
}

test_dr_si_06() { # [v4.5] 상한 미만(1,000자) → 자르지 않음
  dr_legacy_init
  dr_standing "$(printf '꿻%.0s' $(seq 1 1000))\n"
  local o="$SANDBOX/s06"; dr_si_run_pair reinject-mode.sh "$o"
  dr_rest_after_legacy "$o.old" "$o.new" || fail si06-legacy-prefix
  assert_file_not_contains "$o.new.rest" '…(잘림)' si06-no-marker
  [ "$(dr_ccount "$o.new.rest" '꿻')" = "1000" ] || fail si06-full
}

test_dr_si_07() { # [v4.5] 파일 없음 / 빈 파일 / 주석·빈 줄뿐 → reinject 출력이 종전 훅과 바이트 동일 (여러 상태)
  dr_legacy_init
  local variant st
  for st in "auto 0 0" "lazy 1 1" "UNSET 0 0 0" "UNSET 0 1 0"; do
    for variant in none empty comments; do
      rm -f "$HOME_DIR/.claude/standing-instructions.md"
      # shellcheck disable=SC2086
      write_state $st
      dr_raw "$LEG/reinject-mode.sh" "$(json_prompt '계속')" "$SANDBOX/old"
      case "$variant" in
        empty) dr_standing '' ;;
        comments) dr_standing '# 주석만\n\n#  또 주석\n\n' ;;
      esac
      # shellcheck disable=SC2086
      write_state $st
      dr_raw "$HOOKS_DIR/reinject-mode.sh" "$(json_prompt '계속')" "$SANDBOX/new"
      cmp -s "$SANDBOX/old" "$SANDBOX/new" || { echo "  [dbg] st=$st variant=$variant"; fail "si07-identical-$variant"; }
    done
  done
  # 상태파일 없음 + 파일 없음 → 종전처럼 0바이트
  rm -f "$STATE" "$HOME_DIR/.claude/standing-instructions.md"
  dr_raw "$HOOKS_DIR/reinject-mode.sh" "$(json_prompt '계속')" "$SANDBOX/n0"
  [ ! -s "$SANDBOX/n0" ] || fail si07-nostate-empty
}

test_dr_si_08() { # [v4.5] 파일 없음 / 주석뿐 → session-mode-guard 출력이 종전 훅과 바이트 동일
  dr_legacy_init
  local variant
  for variant in none comments; do
    rm -f "$HOME_DIR/.claude/standing-instructions.md"
    write_state auto
    dr_raw "$LEG/session-mode-guard.sh" "$(dr_ss startup)" "$SANDBOX/old"
    [ "$variant" = comments ] && dr_standing '# 주석만\n\n'
    write_state auto
    dr_raw "$HOOKS_DIR/session-mode-guard.sh" "$(dr_ss startup)" "$SANDBOX/new"
    cmp -s "$SANDBOX/old" "$SANDBOX/new" || fail "si08-identical-$variant"
  done
}

# ══ I7/I8 기존 계약 보존 ═══════════════════════════════════════════════════════

test_dr_cm_01() { # [v4.5 I8] 새 사이드카(.compact·.reread·.decisions)가 있어도 상태파일을 손상으로 보지 않음
  dr_setup_task
  dr_compact_at $(( $(dr_now) - 100 ))
  printf '%s\t%s\n' "$(dr_now)" "$SPECF" > "$STATE_DIR/$SID.reread"
  printf '## 2026-11-19 00:00:00 (toolu_x)\n' > "$STATE_DIR/$SID.decisions"
  run_hook_stdout reinject-mode.sh "$(json_prompt '계속')"
  assert_exit 0 cm01-reinject-exit
  dr_l1
  run_hook session-mode-guard.sh "$(dr_ss startup)"
  assert_exit 0 cm01-session-exit
  run_hook reread-track.sh "$(dr_read "$LOGF")"
  run_hook capture-decision.sh "$(dr_ask1 toolu_cm '보존?' 'CM' 'A안')"
  if ls "$STATE".corrupt-* >/dev/null 2>&1; then fail cm01-no-quarantine; fi
  assert_state SCHEMA 4 cm01-schema
  assert_state MODE auto cm01-mode
  assert_state SPEC 1 cm01-spec
  assert_state TASK_PATH "$TP" cm01-taskpath
  assert_single_line TASK_PATH cm01-taskpath-single
}

test_dr_cm_02() { # [v4.5 I8] reread-track·capture-decision 은 상태파일을 바꾸지 않는다
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  local h; h=$(sha256sum < "$STATE")
  dr_read_targets
  run_hook capture-decision.sh "$(dr_ask1 toolu_cm2 '상태?' 'CM' 'B안')"
  [ "$(sha256sum < "$STATE")" = "$h" ] || fail cm02-state-untouched
  dr_reread_has "$SPECF" || fail cm02-reread-recorded   # 무동작 위장 차단
}

test_dr_cm_03() { # [v4.5 I8] 새 사이드카도 Edit/Write 하드 거부 범위(상태 디렉토리) — Bash 는 종전 redirect backstop 만 확인(전 경로 차단 아님 — 보충 26 수용 한계)
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  run_hook gate-guard.sh "$(dr_tool PreToolUse Write "$STATE_DIR/$SID.reread")"
  assert_exit 2 cm03-write-reread-denied
  run_hook gate-guard.sh "$(dr_tool PreToolUse Edit "$STATE_DIR/$SID.compact")"
  assert_exit 2 cm03-edit-compact-denied
  run_hook gate-guard.sh "$(json_bash "printf '1\t$SPECF\n' > .claude/lazymode/$SID.reread")"
  assert_exit 2 cm03-bash-redirect-backstop
}

test_dr_cm_04() { # [v4.5 I8] task-mode-guard 리셋은 종전대로(새 작업 폴더 → SPEC=0·MODE=UNSET·TASK_PATH 갱신), 압축 기록과 무관
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  local nt; nt=$(realpath -m -- "$REPO/docs/plans/2026-11-19/t2"); mkdir -p "$nt"; echo s > "$nt/requirement-spec.md"
  run_hook task-mode-guard.sh "$(json_file PostToolUse Write "$nt/requirement-spec.md")"
  assert_exit 0 cm04-exit
  assert_state SPEC 0 cm04-spec-reset
  assert_state MODE UNSET cm04-mode-reset
  assert_state TASK_PATH "$nt" cm04-taskpath
}

# ══ I9 사용자 내용 보호 ═════════════════════════════════════════════════════════

test_dr_pv_01() { # [v4.5] 자유 프롬프트 원문은 사이드카(.decisions)·decisions.md 에 쌓이지 않음
  write_state auto
  local secret='자유프롬프트원문-XYZ-7781'
  write_sidecar 1 "$(date +%s)" "$secret 이걸로 진행해"   # 옛 capture-prompt 가 남긴 .prompt 잔재(2026-11-20 훅 삭제 — 파일은 30일 정리까지 남는다)
  run_hook_stdout reinject-mode.sh "$(json_prompt "$secret 이걸로 진행해")"
  run_hook capture-decision.sh "$(dr_ask1 toolu_pv1 '보호 질문?' 'PV' 'A안')"
  [ -f "$STATE_DIR/$SID.decisions" ] || fail pv01-sidecar-precondition
  assert_file_not_contains "$STATE_DIR/$SID.decisions" "$secret" pv01-sidecar-no-prompt
  TP=$(realpath -m -- "$REPO/docs/plans/2026-11-19/t1"); mkdir -p "$TP"
  echo s > "$TP/requirement-spec.md"; echo l > "$TP/log.md"; echo "TASK_PATH=$TP" >> "$STATE"
  write_sidecar 2 "$(date +%s)" "$secret 두번째"
  run_hook capture-decision.sh "$(dr_ask1 toolu_pv2 '보호 질문2?' 'PV' 'B안')"
  [ -f "$TP/decisions.md" ] || fail pv01-decisions-precondition
  assert_file_not_contains "$TP/decisions.md" "$secret" pv01-decisions-no-prompt
  if grep -rqF "$secret" "$STATE_DIR"/*.decisions 2>/dev/null; then fail pv01-no-prompt-anywhere; fi
}

# ══ 계약 보충 2 (리뷰 루프 1) ═════════════════════════════════════════════════

test_dr_ad_18() { # [v4.5 보충 14] 서로 다른 세션 8개가 같은 작업 폴더에 동시에 큰 답(300KB) 기록 → 제목 1개·블록 8개·답 줄 온전·docs 에 lock 파일 없음
  dr_setup_task
  local n=8 i c sid
  for i in $(seq 1 "$n"); do
    sid="${SID}c$i"
    printf 'SCHEMA=4\nMODE=auto\nSPEC=1\nPENDING_GATE=0\nDEBT=0\nTASK_PATH=%s\n' "$TP" > "$STATE_DIR/$sid"
    c=$(printf '%s' abcdefgh | cut -c "$i")
    { printf 'S%s-' "$i"; head -c 300000 /dev/zero | tr '\0' "$c"; printf -- '-E%s' "$i"; } > "$SANDBOX/ans$i"
    printf -- '- 답: %s\n' "$(cat "$SANDBOX/ans$i")" > "$SANDBOX/pat$i"
    jq -cn --arg s "$sid" --arg c "$REPO" --arg id "toolu_c$i" --arg h "C$i" --arg q "동시 질문 $i?" --rawfile a "$SANDBOX/ans$i" '
      ({question:$q, header:$h, options:[{label:"x",description:"d"}], multiSelect:false}) as $qq |
      {session_id:$s, cwd:$c, hook_event_name:"PostToolUse", tool_name:"AskUserQuestion",
       tool_input:{questions:[$qq], answers:{($q):$a}}, tool_response:{questions:[$qq], answers:{($q):$a}, annotations:{}},
       tool_use_id:$id}' > "$SANDBOX/c$i.json"
  done
  for i in $(seq 1 "$n"); do
    ( env HOME="$HOME_DIR" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null XDG_CONFIG_HOME="$XDG_DIR" \
        bash "$HOOKS_DIR/capture-decision.sh" < "$SANDBOX/c$i.json" >/dev/null 2>"$SANDBOX/c$i.err"; echo $? > "$SANDBOX/c$i.rc" ) &
  done
  wait
  for i in $(seq 1 "$n"); do [ "$(cat "$SANDBOX/c$i.rc")" = "0" ] || fail "ad18-exit-$i"; done
  [ "$(dr_count "$DECF" "$DR_TITLE")" = "1" ] || fail ad18-title-once
  [ "$(sed -n 1p "$DECF")" = "$DR_TITLE" ] || fail ad18-title-line1
  [ "$(grep -c '^## ' "$DECF" || true)" = "$n" ] || { echo "  [dbg] blocks=$(grep -c '^## ' "$DECF" || true)"; fail ad18-block-count; }
  local h
  for i in $(seq 1 "$n"); do
    [ "$(dr_heading_count "$DECF" "toolu_c$i")" = "1" ] || fail "ad18-heading-$i"
    h=$(grep -n "(toolu_c$i)\$" "$DECF" | head -1 | cut -d: -f1)
    [ "$(sed -n "$((h+2))p" "$DECF")" = "### C$i" ] || fail "ad18-header-adjacent-$i"
    sed -n "$((h+5))p" "$DECF" | cmp -s - "$SANDBOX/pat$i" || fail "ad18-answer-intact-$i"
  done
  [ -z "$(find "$REPO/docs" -name '*lock*' 2>/dev/null)" ] || fail ad18-no-lock-in-docs
  [ "$(ls -A "$TP" | LC_ALL=C sort | tr '\n' ' ')" = "decisions.md log.md requirement-spec.md " ] || { echo "  [dbg] ls=$(ls -A "$TP" | tr '\n' ' ')"; fail ad18-no-extra-files-in-task; }
}

test_dr_ad_19() { # [v4.5 보충 16] decisions.md 덧붙이기 중 실패(파일 크기 상한 — 부분 쓰기) → 덧붙이기 전 크기로 되돌림, exit 0
  local probe="$SANDBOX/xfsz.probe"
  ( ulimit -f 2; trap '' XFSZ; head -c 5000 /dev/zero >> "$probe" ) 2>/dev/null || true
  if [ "$(wc -c < "$probe" 2>/dev/null || echo 0)" != "2048" ]; then
    echo "  [dbg] skip: 이 환경에서 ulimit -f 부분 쓰기가 재현되지 않음(size=$(wc -c < "$probe" 2>/dev/null || echo none))"; return 0
  fi
  dr_setup_task
  run_hook capture-decision.sh "$(dr_ask1 toolu_p1 '첫?' 'P' 'A안')"
  [ -f "$DECF" ] || fail ad19-first-recorded
  cp "$DECF" "$SANDBOX/p.before"
  local big; big=$(head -c 20000 /dev/zero | tr '\0' 'z')
  dr_ask1 toolu_p2 '큰 답?' 'P' "$big" > "$SANDBOX/p2.json"
  local rc
  set +e
  ( ulimit -f 2; trap '' XFSZ
    env HOME="$HOME_DIR" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null XDG_CONFIG_HOME="$XDG_DIR" \
      bash "$HOOKS_DIR/capture-decision.sh" < "$SANDBOX/p2.json" >/dev/null 2>"$SANDBOX/p2.err" )
  rc=$?
  set -e
  [ "$rc" = "0" ] || { echo "  [dbg] rc=$rc"; fail ad19-exit-0; }
  cmp -s "$SANDBOX/p.before" "$DECF" || { echo "  [dbg] before=$(wc -c < "$SANDBOX/p.before") after=$(wc -c < "$DECF")"; fail ad19-rolled-back; }
}

test_dr_ad_20() { # [v4.5 보충 15] 옮길 사이드카를 읽을 수 없음(000) → decisions.md 미생성·사이드카 보존·경고, 복구 뒤 순서대로 이동
  dr_root_skip && return 0
  write_state auto
  run_hook capture-decision.sh "$(dr_ask1 toolu_u1 '첫?' 'U' 'A안')"
  run_hook capture-decision.sh "$(dr_ask1 toolu_u1b '첫 다음?' 'U' 'B안')"
  local sc="$STATE_DIR/$SID.decisions"
  [ -f "$sc" ] || fail ad20-sidecar-precondition
  cp "$sc" "$SANDBOX/sc.before"
  dr_add_task
  chmod 000 "$sc"
  run_hook capture-decision.sh "$(dr_ask1 toolu_u2 '둘?' 'U' 'B안')"
  chmod 644 "$sc"
  assert_exit 0 ad20-exit
  [ -n "$HOOK_STDERR" ] || fail ad20-warn
  [ ! -e "$DECF" ] || fail ad20-no-decisions-md
  [ -f "$sc" ] || fail ad20-sidecar-kept
  dr_is_prefix "$SANDBOX/sc.before" "$sc" || fail ad20-sidecar-not-overwritten
  run_hook capture-decision.sh "$(dr_ask1 toolu_u3 '셋?' 'U' 'C안')"
  local i a b c m
  for i in u1 u1b u3; do [ "$(dr_heading_count "$DECF" "toolu_$i")" = "1" ] || fail "ad20-once-$i"; done
  a=$(dr_lineno "$DECF" '(toolu_u1)'); b=$(dr_lineno "$DECF" '(toolu_u1b)'); c=$(dr_lineno "$DECF" '(toolu_u3)')
  { [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ]; } || fail ad20-migrated-in-order
  m=$(dr_heading_count "$DECF" toolu_u2)                     # 000 동안의 u2 는 남길 곳이 없어 유실 가능(경고) — 남았다면 1회·제자리
  [ "$m" -le 1 ] || fail ad20-u2-at-most-once
  if [ "$m" = "1" ]; then
    m=$(dr_lineno "$DECF" '(toolu_u2)'); { [ "$b" -lt "$m" ] && [ "$m" -lt "$c" ]; } || fail ad20-u2-in-place
  fi
  [ ! -e "$sc" ] || fail ad20-sidecar-removed-after
}

test_dr_ad_20b() { # [v4.5 보충 15] 사이드카가 쓰기만 가능(200) → 목적지에 쓰지 않고 새 블록은 사이드카 끝에, 복구 뒤 u1<u2<u3
  dr_root_skip && return 0
  write_state auto
  run_hook capture-decision.sh "$(dr_ask1 toolu_w1 '첫?' 'W' 'A안')"
  local sc="$STATE_DIR/$SID.decisions"
  cp "$sc" "$SANDBOX/sc.before"
  dr_add_task
  chmod 200 "$sc"
  run_hook capture-decision.sh "$(dr_ask1 toolu_w2 '둘?' 'W' 'B안')"
  chmod 644 "$sc"
  assert_exit 0 ad20b-exit
  [ ! -e "$DECF" ] || fail ad20b-no-decisions-md
  dr_is_prefix "$SANDBOX/sc.before" "$sc" || fail ad20b-sidecar-not-overwritten
  assert_file_contains "$sc" '(toolu_w2)' ad20b-new-block-appended-to-sidecar
  run_hook capture-decision.sh "$(dr_ask1 toolu_w3 '셋?' 'W' 'C안')"
  local a b c; a=$(dr_lineno "$DECF" '(toolu_w1)'); b=$(dr_lineno "$DECF" '(toolu_w2)'); c=$(dr_lineno "$DECF" '(toolu_w3)')
  { [ -n "$a" ] && [ -n "$b" ] && [ -n "$c" ] && [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ]; } || fail ad20b-order
}

test_dr_ad_21() { # [v4.5 보충 19] 빈 tool_use_id 블록은 중복으로 보지 않음 — 사이드카 2 + 새 1 = 3개 순서대로
  write_state auto
  run_hook capture-decision.sh "$(dr_ask1 '' '빈 아이디 하나?' 'E' 'A안')"
  run_hook capture-decision.sh "$(dr_ask1 '' '빈 아이디 둘?' 'E' 'B안')"
  [ "$(grep -c '^## ' "$STATE_DIR/$SID.decisions" 2>/dev/null || true)" = "2" ] || fail ad21-sidecar-two
  dr_add_task
  run_hook capture-decision.sh "$(dr_ask1 '' '빈 아이디 셋?' 'E' 'C안')"
  assert_exit 0 ad21-exit
  [ "$(grep -c '^## ' "$DECF" || true)" = "3" ] || fail ad21-three-blocks
  local a b c; a=$(dr_lineno "$DECF" '- 질문: 빈 아이디 하나?'); b=$(dr_lineno "$DECF" '- 질문: 빈 아이디 둘?'); c=$(dr_lineno "$DECF" '- 질문: 빈 아이디 셋?')
  { [ -n "$a" ] && [ -n "$b" ] && [ -n "$c" ] && [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ]; } || fail ad21-order
}

test_dr_ad_22() { # [v4.5 보충 20] CR·U+2028·U+2029·탭·제어문자·가짜 블록 문자열 → 공백 치환, 가짜 '## ' 헤더·중복 판정 없음
  dr_setup_task
  local q h l a
  q=$(printf 'Q1\rQ2\xe2\x80\xa8Q3\xe2\x80\xa9Q4\tQ5\x01Q6')
  h=$(printf 'H\tX')
  l=$(printf 'L\rM')
  a=$(printf 'A1\r## 2026-01-01 00:00:00 (toolu_FAKE)\n## 2026-01-01 00:00:01 (toolu_FAKE2)\x01end')
  local qq; qq=$(dr_q "$q" "$h" "$l" '둘')
  run_hook capture-decision.sh "$(dr_ask toolu_real "[$qq]" "$(jq -cn --arg k "$q" --arg v "$a" '{($k):$v}')")"
  assert_exit 0 ad22-exit
  if LC_ALL=C grep -q "$(printf '\r')" "$DECF"; then fail ad22-no-cr; fi
  if LC_ALL=C grep -qF "$(printf '\xe2\x80\xa8')" "$DECF"; then fail ad22-no-u2028; fi
  if LC_ALL=C grep -qF "$(printf '\xe2\x80\xa9')" "$DECF"; then fail ad22-no-u2029; fi
  if LC_ALL=C grep -q "$(printf '\t')" "$DECF"; then fail ad22-no-tab; fi
  if LC_ALL=C grep -q "$(printf '\x01')" "$DECF"; then fail ad22-no-ctrl; fi
  if grep -q '^## 2026-01-01' "$DECF"; then fail ad22-no-fake-heading; fi
  [ "$(grep -c '^## ' "$DECF" || true)" = "1" ] || fail ad22-one-block
  grep -qxF -- '- 질문: Q1 Q2 Q3 Q4 Q5 Q6' "$DECF" || fail ad22-question-spaced
  run_hook capture-decision.sh "$(dr_ask1 toolu_FAKE '진짜 FAKE 아이디?' 'F' 'A안')"
  [ "$(dr_heading_count "$DECF" toolu_FAKE)" = "1" ] || fail ad22-fake-id-not-deduped
}

test_dr_rr_17() { # [v4.5 보충 18] 탭·역슬래시가 든 작업 폴더 이름 — 기록·교체·해제 정상, 결정 블록 중복 없음
  write_state auto
  local name; name=$(printf 't\tb\\x')
  dr_add_task "$name"
  dr_compact_at $(( $(dr_now) - 100 ))
  local j; j=$(dr_ask1 toolu_tab '탭 폴더?' 'T' 'A안')
  run_hook capture-decision.sh "$j"; run_hook capture-decision.sh "$j"
  [ -f "$DECF" ] || fail rr17-decisions-created
  [ "$(dr_heading_count "$DECF" toolu_tab)" = "1" ] || fail rr17-no-dup-block
  dr_l1; assert_exit 2 rr17-blocked
  dr_read_hook "$SPECF"; dr_read_hook "$SPECF"; dr_read_hook "$LOGF"
  dr_l1; assert_exit 2 rr17-decisions-still-needed
  dr_read_hook "$DECF"
  [ "$(dr_path_lines "$STATE_DIR/$SID.reread" "$SPECF")" = "1" ] || fail rr17-spec-one-line
  [ "$(dr_path_lines "$STATE_DIR/$SID.reread" "$DECF")" = "1" ] || fail rr17-decisions-recorded
  dr_l1; assert_exit 0 rr17-released
}

test_dr_rr_18() { # [v4.5 보충 24] 다른 이름의 심링크로 대상 파일을 Read → 읽은 것으로 세지 않음
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  ln -s "$SPECF" "$TP/spec-alias.md"
  dr_read_hook "$TP/spec-alias.md"; dr_read_hook "$LOGF"
  dr_reread_has "$SPECF" && fail rr18-alias-not-recorded
  dr_l1; assert_exit 2 rr18-still-blocked
  dr_read_hook "$SPECF"
  dr_l1; assert_exit 0 rr18-control-direct-read
}

test_dr_si_09() { # [v4.5 보충 21] 고정 지시 파일이 심링크 → 주입 없음(파일 없을 때와 바이트 동일)·stderr 경고 / 디렉토리 → 주입 없음
  local sf="$HOME_DIR/.claude/standing-instructions.md" h j
  mkdir -p "$HOME_DIR/.claude"
  printf '심링크로 들어오면 안 되는 지시\n' > "$SANDBOX/real-standing.md"
  for h in reinject-mode.sh session-mode-guard.sh; do
    if [ "$h" = reinject-mode.sh ]; then j=$(json_prompt '계속'); else j=$(dr_ss startup); fi
    rm -f "$sf"; write_state auto; dr_raw "$HOOKS_DIR/$h" "$j" "$SANDBOX/none.$h"
    ln -s "$SANDBOX/real-standing.md" "$sf"
    write_state auto; dr_raw "$HOOKS_DIR/$h" "$j" "$SANDBOX/link.$h"
    cmp -s "$SANDBOX/none.$h" "$SANDBOX/link.$h" || fail "si09-symlink-not-injected-$h"
    write_state auto; run_hook "$h" "$j"
    assert_exit 0 "si09-symlink-exit-$h"
    [ -n "$HOOK_STDERR" ] || fail "si09-symlink-warn-$h"
    rm -f "$sf"; mkdir "$sf"
    write_state auto; dr_raw "$HOOKS_DIR/$h" "$j" "$SANDBOX/dir.$h"
    cmp -s "$SANDBOX/none.$h" "$SANDBOX/dir.$h" || fail "si09-dir-not-injected-$h"
    rmdir "$sf"
  done
}

test_dr_si_10() { # [v4.5 보충 21] 64KB 를 넘는 고정 지시 파일 → 정상 종료, 1,500자 상한 적용
  dr_legacy_init
  local line i; line=$(printf '꿻%.0s' $(seq 1 100))
  : > "$SANDBOX/big.md"
  for i in $(seq 1 300); do printf '%s\n' "$line" >> "$SANDBOX/big.md"; done   # ≈ 90KB
  [ "$(wc -c < "$SANDBOX/big.md")" -gt 65536 ] || fail si10-fixture-size
  mkdir -p "$HOME_DIR/.claude"; cp "$SANDBOX/big.md" "$HOME_DIR/.claude/standing-instructions.md"
  local o="$SANDBOX/s10" n
  dr_si_run_pair reinject-mode.sh "$o"
  write_state auto; run_hook reinject-mode.sh "$(json_prompt '계속')"
  assert_exit 0 si10-exit
  dr_rest_after_legacy "$o.old" "$o.new" || fail si10-legacy-prefix
  assert_file_contains "$o.new.rest" '…(잘림)' si10-marker
  n=$(dr_ccount "$o.new.rest" '꿻')
  { [ "$n" -le 1500 ] && [ "$n" -ge 1400 ]; } || { echo "  [dbg] n=$n"; fail si10-capped; }
}

dr_undecidable_line() { printf '%s' '[게이트] 압축 뒤 재독 상태 판정 불가 — 세션 사이드카 확인: '; }
test_dr_bl_12() { # [v4.5 보충 22] 사이드카 비정규·손상 → reinject 에 판정 불가 줄(경로 포함), L1 차단 없음 / 정상이면 그 줄 없음
  dr_setup_task
  local c="$STATE_DIR/$SID.compact" r="$STATE_DIR/$SID.reread" v
  printf '%s\n' "$(( $(dr_now) - 100 ))" > "$SANDBOX/compact.real"
  printf '%s\t%s\n' 1 "$SPECF" > "$SANDBOX/reread.real"
  for v in c-garbage c-empty c-symlink c-dir r-dir r-symlink r-000; do
    if [ -d "$c" ] && [ ! -L "$c" ]; then rmdir "$c"; fi; if [ -d "$r" ] && [ ! -L "$r" ]; then rmdir "$r"; fi; rm -f "$c" "$r"
    case "$v" in
      c-garbage) printf 'abc\n' > "$c" ;;
      c-empty) : > "$c" ;;
      c-symlink) ln -s "$SANDBOX/compact.real" "$c" ;;
      c-dir) mkdir "$c" ;;
      r-dir) cp "$SANDBOX/compact.real" "$c"; mkdir "$r" ;;
      r-symlink) cp "$SANDBOX/compact.real" "$c"; ln -s "$SANDBOX/reread.real" "$r" ;;
      r-000) dr_root_skip && continue; cp "$SANDBOX/compact.real" "$c"; cp "$SANDBOX/reread.real" "$r"; chmod 000 "$r" ;;
    esac
    run_hook_stdout reinject-mode.sh "$(json_prompt '계속')"
    [ "$v" = r-000 ] && chmod 644 "$r"
    assert_exit 0 "bl12-exit-$v"
    printf '%s\n' "$HOOK_STDOUT" | grep -F -- "$(dr_undecidable_line)" | grep -qF -- "$STATE_DIR" \
      || { echo "  [dbg] $v stdout=$(printf '%s' "$HOOK_STDOUT" | tail -n 2 | tr '\n' ' ')"; fail "bl12-undecidable-line-$v"; }
    [ "$v" = r-000 ] && chmod 000 "$r"
    dr_l1
    [ "$v" = r-000 ] && chmod 644 "$r"
    assert_exit 0 "bl12-no-block-$v"
  done
  rm -f "$c" "$r"
  cp "$SANDBOX/compact.real" "$c"
  run_hook_stdout reinject-mode.sh "$(json_prompt '계속')"
  assert_stdout_no_match '재독 상태 판정 불가' bl12-normal-no-line
  assert_stdout_match '압축 뒤 작업 기록 미독' bl12-normal-unread-line
  rm -f "$c"
  run_hook_stdout reinject-mode.sh "$(json_prompt '계속')"
  assert_stdout_no_match '재독 상태 판정 불가' bl12-no-compact-no-line
}

# ══ 계약 보충 3 (리뷰 루프 2) ═════════════════════════════════════════════════
# PATH 앞에 둘 flock 래퍼. 잠금 대상(fd 인자 → /proc/<pid>/fd 로 풀거나 경로 인자)이 decisions.md 일 때만 개입한다.
#   mode=swap : 진짜 flock 성공 직후 그 decisions.md 를 다른 inode 의 같은 내용 파일로 교체(mv + cp) — 보충 28
#   mode=fail : decisions.md 잠금만 실패(exit 1) — 보충 29(철회 뒤: 빈 파일 삭제 없음). 다른 잠금(상태·사이드카)은 진짜 flock 그대로.
#   mode=pass : 개입 없음(같은 테스트 안에서 정상 경로로 되돌릴 때).
#   개입할 때마다 $DR_FLOCK_HITS 에 한 줄 — 개입이 실제로 일어났는지(재현 성립) 확인용.
dr_path_without() { printf '%s' "$PATH" | tr ':' '\n' | grep -vxF -- "$1" | paste -sd: -; }   # <dir> → 그 디렉토리를 뺀 PATH
dr_flock_wrapper() { # <mode>
  local d="$SANDBOX/fakebin"; mkdir -p "$d"
  DR_REAL_FLOCK=$(PATH=$(dr_path_without "$d") command -v flock) || fail flock-missing   # 래퍼 자신을 잡지 않게
  DR_FLOCK_HITS="$SANDBOX/flock.hits"; : > "$DR_FLOCK_HITS"
  cat > "$d/flock" <<'WRAP'
#!/bin/bash
t=""
for a in "$@"; do
  if [[ "$a" =~ ^[0-9]+$ ]] && [ -e "/proc/$$/fd/$a" ]; then t=$(readlink "/proc/$$/fd/$a")
  elif [ -e "$a" ]; then t=$(realpath -- "$a"); fi
done
case "$t" in
  */decisions.md) ;;
  *) exec "$DR_REAL_FLOCK" "$@" ;;
esac
if [ "$DR_FLOCK_MODE" = pass ]; then exec "$DR_REAL_FLOCK" "$@"; fi
echo "$DR_FLOCK_MODE $t" >> "$DR_FLOCK_HITS"
if [ "$DR_FLOCK_MODE" = fail ]; then exit 1; fi
"$DR_REAL_FLOCK" "$@" || exit $?
mv -f -- "$t" "$t.swapped-old" && cp -- "$t.swapped-old" "$t"
exit 0
WRAP
  chmod +x "$d/flock"
  export PATH="$d:$PATH" DR_REAL_FLOCK DR_FLOCK_HITS DR_FLOCK_MODE="$1"
}

test_dr_ad_23() { # [v4.5 보충 28] 잠근 뒤 decisions.md 가 교체됨 → 새 블록·옮기던 사이드카분이 유실되지 않고(현재 파일 또는 사이드카), 사이드카는 지워지지 않음
  write_state auto
  run_hook capture-decision.sh "$(dr_ask1 toolu_x1 '사이드카분?' 'X' 'A안')"
  local sc="$STATE_DIR/$SID.decisions"
  [ -f "$sc" ] || fail ad23-sidecar-precondition
  dr_add_task
  printf '%s\n\n' "$DR_TITLE" > "$DECF"
  dr_flock_wrapper swap
  run_hook capture-decision.sh "$(dr_ask1 toolu_x2 '교체 중 기록?' 'X' 'B안')"
  assert_exit 0 ad23-exit
  grep -q '^swap .*/decisions.md$' "$DR_FLOCK_HITS" || fail ad23-swap-reproduced
  local i n
  for i in x1 x2; do
    n=$(( $(dr_heading_count "$DECF" "toolu_$i") + $(dr_heading_count "$sc" "toolu_$i") ))
    [ "$n" -ge 1 ] || { echo "  [dbg] $i 는 교체된 옛 파일에만 있음"; fail "ad23-not-lost-$i"; }
  done
  [ -f "$sc" ] || fail ad23-sidecar-kept
  [ "$(dr_heading_count "$sc" toolu_x1)" = "1" ] || fail ad23-sidecar-content-kept
}

# PATH 앞에 둘 rm·unlink 래퍼 — 호출 인자를 $DR_RM_LOG 에 기록하고 진짜 명령 실행(훅이 decisions.md 를 지우지 않음 확인용)
dr_rm_wrapper() {
  local d="$SANDBOX/fakebin" c; mkdir -p "$d"
  DR_REAL_RM=$(PATH=$(dr_path_without "$d") command -v rm) || fail rm-missing         # 래퍼 자신을 잡지 않게(재호출 시 무한 exec 방지)
  DR_REAL_UNLINK=$(PATH=$(dr_path_without "$d") command -v unlink) || fail unlink-missing
  DR_RM_LOG="$SANDBOX/rm.log"; : > "$DR_RM_LOG"
  for c in rm unlink; do
    printf '#!/bin/bash\nprintf "%%s %%s\\n" %s "$*" >> "$DR_RM_LOG"\nexec "$DR_REAL_%s" "$@"\n' "$c" "$(printf '%s' "$c" | tr a-z A-Z)" > "$d/$c"
    chmod +x "$d/$c"
  done
  export PATH="$d:$PATH" DR_REAL_RM DR_REAL_UNLINK DR_RM_LOG
  [ "$(command -v rm)" = "$d/rm" ] || fail rm-wrapper-active
}

test_dr_ad_24() { # [v4.5 29항 철회] decisions.md 잠금 실패 → 블록은 사이드카·경고·exit 0, decisions.md 는 없거나 0바이트(내용 있는 파일 생성 금지) / 전부터 있던 0바이트 파일은 남음 / 내용 있던 파일은 그대로
  dr_setup_task
  dr_flock_wrapper fail
  run_hook capture-decision.sh "$(dr_ask1 toolu_f1 '잠금 실패?' 'F' 'A안')"
  assert_exit 0 ad24-exit
  grep -q '^fail .*/decisions.md$' "$DR_FLOCK_HITS" || fail ad24-fail-reproduced
  if [ -e "$DECF" ] && [ -s "$DECF" ]; then fail ad24-no-content-file-created; fi
  assert_file_contains "$STATE_DIR/$SID.decisions" '(toolu_f1)' ad24-block-in-sidecar
  [ -n "$HOOK_STDERR" ] || fail ad24-warn
  # 실행 전부터 있던 0바이트 decisions.md 는 실행 뒤에도 남는다(삭제 금지)
  : > "$DECF"
  run_hook capture-decision.sh "$(dr_ask1 toolu_f0 '빈 파일?' 'F' 'B안')"
  assert_exit 0 ad24-empty-exit
  [ -f "$DECF" ] || fail ad24-preexisting-empty-kept
  [ ! -s "$DECF" ] || fail ad24-preexisting-empty-unchanged
  assert_file_contains "$STATE_DIR/$SID.decisions" '(toolu_f0)' ad24-empty-block-in-sidecar
  # 이미 내용이 있던 decisions.md 는 바이트 그대로
  printf '%s\n\n## 2026-01-01 00:00:00 (toolu_pre)\n\n### P\n- 질문: p?\n- 선택지: a / b\n- 답: a\n' "$DR_TITLE" > "$DECF"
  cp "$DECF" "$SANDBOX/ad24.before"
  run_hook capture-decision.sh "$(dr_ask1 toolu_f2 '기존 파일?' 'F' 'B안')"
  assert_exit 0 ad24-existing-exit
  cmp -s "$SANDBOX/ad24.before" "$DECF" || fail ad24-existing-unchanged
  assert_file_contains "$STATE_DIR/$SID.decisions" '(toolu_f2)' ad24-existing-block-in-sidecar
}

test_dr_ad_24b() { # [v4.5 29항 철회] 잠금 실패로 0바이트 decisions.md 가 남은 뒤 정상 호출 → 제목 줄 정확히 1개(1행)·사이드카분 순서대로 이동
  dr_setup_task
  : > "$DECF"                                                # 잠금 실패 뒤 남은 0바이트 파일 상태를 확정적으로 만든다
  dr_flock_wrapper fail
  run_hook capture-decision.sh "$(dr_ask1 toolu_g1 '첫?' 'G' 'A안')"
  run_hook capture-decision.sh "$(dr_ask1 toolu_g2 '둘?' 'G' 'B안')"
  [ -f "$DECF" ] && [ ! -s "$DECF" ] || fail ad24b-empty-left
  [ "$(dr_heading_count "$STATE_DIR/$SID.decisions" 'toolu_g[12]')" = "2" ] || fail ad24b-sidecar-precondition
  export DR_FLOCK_MODE=pass
  run_hook capture-decision.sh "$(dr_ask1 toolu_g3 '셋?' 'G' 'C안')"
  assert_exit 0 ad24b-exit
  [ "$(sed -n 1p "$DECF")" = "$DR_TITLE" ] || fail ad24b-title-line1
  [ "$(dr_count "$DECF" "$DR_TITLE")" = "1" ] || fail ad24b-title-once
  local i a b c
  for i in g1 g2 g3; do [ "$(dr_heading_count "$DECF" "toolu_$i")" = "1" ] || fail "ad24b-once-$i"; done
  a=$(dr_lineno "$DECF" '(toolu_g1)'); b=$(dr_lineno "$DECF" '(toolu_g2)'); c=$(dr_lineno "$DECF" '(toolu_g3)')
  { [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ]; } || fail ad24b-order
  [ ! -e "$STATE_DIR/$SID.decisions" ] || fail ad24b-sidecar-removed
}

test_dr_ad_26() { # [v4.5 29항 철회] 훅은 decisions.md 를 지우지 않는다 — 잠금 실패·쓰기 실패·사이드카 읽기 실패 경로 모두에서 rm/unlink 인자에 decisions.md 없음
  dr_root_skip && return 0
  dr_setup_task
  dr_flock_wrapper fail
  dr_rm_wrapper
  local sc="$STATE_DIR/$SID.decisions"
  # ① 잠금 실패
  run_hook capture-decision.sh "$(dr_ask1 toolu_d1 '잠금 실패?' 'D' 'A안')"
  grep -q '^fail .*/decisions.md$' "$DR_FLOCK_HITS" || fail ad26-lockfail-reproduced
  # 정상 경로로 되돌려 decisions.md 에 내용을 만든다(사이드카분 이동 포함)
  export DR_FLOCK_MODE=pass
  run_hook capture-decision.sh "$(dr_ask1 toolu_d2 '정상?' 'D' 'B안')"
  [ "$(dr_heading_count "$DECF" toolu_d2)" = "1" ] || fail ad26-normal-recorded
  # ② 쓰기 실패(decisions.md 444)
  chmod 444 "$DECF"
  run_hook capture-decision.sh "$(dr_ask1 toolu_d3 '쓰기 실패?' 'D' 'C안')"
  chmod 644 "$DECF"
  assert_exit 0 ad26-writefail-exit
  assert_file_contains "$sc" '(toolu_d3)' ad26-writefail-to-sidecar
  # ③ 사이드카 읽기 실패(000)
  chmod 000 "$sc"
  run_hook capture-decision.sh "$(dr_ask1 toolu_d4 '사이드카 읽기 실패?' 'D' 'A안')"
  chmod 644 "$sc"
  assert_exit 0 ad26-sidecarfail-exit
  [ -f "$DECF" ] || fail ad26-decisions-still-exists
  # 인자 중 파일 이름이 정확히 decisions.md 인 것(임시 파일 decisions.md.XXXX 등은 허용)
  if awk '{ for (i = 2; i <= NF; i++) { n = split($i, a, "/"); if (a[n] == "decisions.md") f = 1 } } END { exit !f }' "$DR_RM_LOG"; then
    echo "  [dbg] $(grep -F 'decisions.md' "$DR_RM_LOG" | head -2 | tr '\n' ' ')"; fail ad26-never-removes-decisions-md
  fi
}

test_dr_ad_25() { # [v4.5 보충 30] decisions.md 를 읽을 수 없음(200) → 파일 그대로·블록은 사이드카·경고, 같은 id 두 번이어도 복구 뒤 1회
  dr_root_skip && return 0
  dr_setup_task
  run_hook capture-decision.sh "$(dr_ask1 toolu_r0 '처음?' 'R' 'A안')"
  [ -f "$DECF" ] || fail ad25-precondition
  cp "$DECF" "$SANDBOX/ad25.before"
  chmod 200 "$DECF"
  local j; j=$(dr_ask1 toolu_rr '읽기 불가?' 'R' 'B안')
  run_hook capture-decision.sh "$j"
  local e1=$HOOK_EXIT w1=$HOOK_STDERR
  run_hook capture-decision.sh "$j"
  chmod 644 "$DECF"
  HOOK_EXIT=$e1; HOOK_STDERR=$w1
  assert_exit 0 ad25-exit
  [ -n "$w1" ] || fail ad25-warn
  cmp -s "$SANDBOX/ad25.before" "$DECF" || fail ad25-unchanged
  assert_file_contains "$STATE_DIR/$SID.decisions" '(toolu_rr)' ad25-block-in-sidecar
  run_hook capture-decision.sh "$(dr_ask1 toolu_r2 '복구 뒤?' 'R' 'C안')"
  [ "$(dr_heading_count "$DECF" toolu_rr)" = "1" ] || fail ad25-once-after-restore
  local a b c; a=$(dr_lineno "$DECF" '(toolu_r0)'); b=$(dr_lineno "$DECF" '(toolu_rr)'); c=$(dr_lineno "$DECF" '(toolu_r2)')
  { [ -n "$a" ] && [ -n "$b" ] && [ -n "$c" ] && [ "$a" -lt "$b" ] && [ "$b" -lt "$c" ]; } || fail ad25-order
}

# ══ 계약 보충 4 — 33항: 고정 지시 파일 쓰기는 승인 창(permissionDecision "ask") ═══════════
DR_ASK_REASON='[gate-guard] 고정 지시 파일은 모든 세션에 매 턴 주입됩니다 — 변경 내용을 확인하세요.'
dr_si_path() { printf '%s/.claude/standing-instructions.md' "$HOME_DIR"; }
dr_gate_out() { run_hook_stdout gate-guard.sh "$(dr_tool "$1" "$2" "$3" "${4:-}")"; }   # <event> <tool> <file> [agent_id]
dr_assert_ask() { # <assert-id> — exit 0 + stdout JSON 의 hookSpecificOutput 이 계약대로
  assert_exit 0 "$1-exit"
  printf '%s' "$HOOK_STDOUT" | jq -e --arg r "$DR_ASK_REASON" '
      .hookSpecificOutput.hookEventName == "PreToolUse"
      and .hookSpecificOutput.permissionDecision == "ask"
      and (.hookSpecificOutput.permissionDecisionReason | type == "string" and contains($r))' >/dev/null 2>&1 \
    || { echo "  [dbg] stdout=$(printf '%s' "$HOOK_STDOUT" | head -c 200)"; fail "$1-json"; }
}
dr_assert_no_ask() { # <want-exit> <assert-id>
  assert_exit "$1" "$2-exit"
  assert_stdout_no_match 'permissionDecision' "$2-no-ask"
}

test_dr_sa_01() { # [v4.5 보충 33] Edit·Write·MultiEdit 각각 고정 지시 파일 → ask (파일·~/.claude 아직 없음 = 새 Write 포함)
  write_state auto
  [ ! -e "$HOME_DIR/.claude" ] || fail sa01-precondition-no-dir
  local t
  for t in Write Edit MultiEdit; do
    dr_gate_out PreToolUse "$t" "$(dr_si_path)"
    dr_assert_ask "sa01-$t-nofile"
  done
  dr_standing '한국어로 답한다\n'
  for t in Write Edit MultiEdit; do
    dr_gate_out PreToolUse "$t" "$(dr_si_path)"
    dr_assert_ask "sa01-$t-exists"
  done
}

test_dr_sa_02() { # [v4.5 보충 33] 상태 무관 ask — SPEC=0/UNSET · SPEC=1/auto · lazy(PENDING 0·1) · 상태파일 없음
  dr_standing '지시\n'
  local st
  for st in "UNSET 0 0 0" "auto 0 0 1" "lazy 0 0 1" "lazy 1 0 1"; do
    # shellcheck disable=SC2086
    write_state $st
    dr_gate_out PreToolUse Edit "$(dr_si_path)"
    dr_assert_ask "sa02-$(printf '%s' "$st" | tr ' ' '_')"
  done
  rm -f "$STATE"
  dr_gate_out PreToolUse Write "$(dr_si_path)"
  dr_assert_ask sa02-nostate
}

test_dr_sa_03() { # [v4.5 보충 33] agent_id 있는 호출도 ask
  write_state UNSET 0 0 0
  dr_standing '지시\n'
  dr_gate_out PreToolUse Edit "$(dr_si_path)" agent-33
  dr_assert_ask sa03-subagent-edit
  write_state auto
  dr_gate_out PreToolUse Write "$(dr_si_path)" agent-34
  dr_assert_ask sa03-subagent-write
}

test_dr_sa_04() { # [v4.5 보충 33] 심링크를 거쳐 닿는 경로도 ask — 디렉토리 심링크(파일 없음·있음)·파일 심링크
  write_state auto
  mkdir -p "$HOME_DIR/.claude"
  ln -s "$HOME_DIR/.claude" "$SANDBOX/cl-link"
  dr_gate_out PreToolUse Write "$SANDBOX/cl-link/standing-instructions.md"
  dr_assert_ask sa04-dirlink-nofile
  dr_standing '지시\n'
  dr_gate_out PreToolUse Edit "$SANDBOX/cl-link/standing-instructions.md"
  dr_assert_ask sa04-dirlink-exists
  ln -s "$(dr_si_path)" "$SANDBOX/si-file-link.md"
  dr_gate_out PreToolUse Edit "$SANDBOX/si-file-link.md"
  dr_assert_ask sa04-filelink
  dr_gate_out PreToolUse Write "$HOME_DIR/.claude/./sub/../standing-instructions.md"
  dr_assert_ask sa04-dotdot
}

test_dr_sa_05() { # [v4.5 보충 33] 대조: 같은 폴더 다른 파일·이름만 같은 다른 위치 → ask 없음, 종전 판정 그대로
  mkdir -p "$HOME_DIR/.claude" "$REPO/docs"
  write_state UNSET 0 0 0                                    # SPEC=0 — L1 이면 종전대로 exit 2
  dr_gate_out PreToolUse Write "$HOME_DIR/.claude/other.md"
  dr_assert_no_ask 0 sa05-spec0-other-in-claude              # ~/.claude 비배포 파일 = L0
  dr_gate_out PreToolUse Write "$REPO/standing-instructions.md"
  dr_assert_no_ask 2 sa05-spec0-repo-root                    # repo 내 비-docs = L1 → SPEC=0 차단
  dr_gate_out PreToolUse Write "$REPO/docs/standing-instructions.md"
  dr_assert_no_ask 0 sa05-spec0-repo-docs                    # docs = L0
  write_state auto
  dr_gate_out PreToolUse Write "$HOME_DIR/.claude/other.md"
  dr_assert_no_ask 0 sa05-auto-other-in-claude
  dr_gate_out PreToolUse Edit "$REPO/standing-instructions.md"
  dr_assert_no_ask 0 sa05-auto-repo-root
  dr_gate_out PreToolUse Edit "$REPO/docs/standing-instructions.md"
  dr_assert_no_ask 0 sa05-auto-repo-docs
}

test_dr_sa_06() { # [v4.5 보충 33] PostToolUse·Bash 호출에는 ask 없음 (Bash 는 종전 알림 범위 — 한계)
  dr_standing '지시\n'
  write_state auto
  dr_gate_out PostToolUse Edit "$(dr_si_path)"
  dr_assert_no_ask 0 sa06-post-edit
  dr_gate_out PostToolUse Write "$(dr_si_path)"
  dr_assert_no_ask 0 sa06-post-write
  run_hook_stdout gate-guard.sh "$(json_bash "printf 'x\n' > $(dr_si_path)")"
  dr_assert_no_ask 0 sa06-bash-auto
  write_state UNSET 0 0 0
  run_hook_stdout gate-guard.sh "$(json_bash "printf 'x\n' >> $(dr_si_path)")"
  dr_assert_no_ask 0 sa06-bash-spec0
}

test_dr_sa_07() { # [v4.5 보충 33] 상태파일 하드 거부가 여전히 먼저 — 상태파일 Edit 는 exit 2·ask 없음
  write_state auto
  dr_gate_out PreToolUse Edit "$STATE"
  dr_assert_no_ask 2 sa07-statefile-denied
  run_hook gate-guard.sh "$(dr_tool PreToolUse Edit "$STATE")"
  assert_stderr_match '상태파일은 훅 소유' sa07-statefile-msg
}
