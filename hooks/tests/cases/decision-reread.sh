# decision-reread 케이스 — 선택 질문 아카이브(capture-decision) · 압축 시각(session-mode-guard compact)
#   · 재독 판정(reread-track) · 미독 차단(gate-guard)·미독 재주입(reinject-mode) · 고정 지시 재주입 (v4.5)
# 계약 정본: docs/plans/2026-11-19/decision-archive-compact-reread/requirement-spec.md §2 I1~I9 · §10.
# 설계: blind 워커(구현 미열람 계약 — spec·probe 실측 JSON에서 출발). fixture 형태 = 같은 폴더 probe/*.json.
# 관례: sandbox_init 은 run.sh 러너가 각 테스트 앞에서 호출한다 — 케이스 함수는 호출하지 않는다.
# "종전 출력" = 기준 커밋(DR_BASE_SHA — 이 기능 착수 직전 main)의 훅을 sandbox 에 꺼내 같은 입력으로 실행한 값.
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
dr_legacy_init() {
  LEG="$SANDBOX/legacy"; mkdir -p "$LEG"
  local f
  for f in state-lib.sh reinject-mode.sh session-mode-guard.sh; do
    git -C "$HOOKS_DIR" show "$DR_BASE_SHA:hooks/$f" > "$LEG/$f" 2>/dev/null || fail legacy-extract
  done
}
dr_is_prefix() { # <prefix-file> <file> → rc 0 이면 prefix-file 이 file 의 바이트 접두
  local n; n=$(wc -c < "$1")
  head -c "$n" "$2" | cmp -s - "$1"
}
dr_standing() { mkdir -p "$HOME_DIR/.claude"; printf '%b' "$1" > "$HOME_DIR/.claude/standing-instructions.md"; }
dr_lineno() { grep -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1; }   # <file> <fixed> → 첫 줄 번호(없으면 빈 값)
dr_count() { grep -cF -- "$2" "$1" 2>/dev/null || true; }                    # <file> <fixed> → 일치 줄 수
dr_reread_has() { grep -qF -- "	$1" "$STATE_DIR/$SID.reread" 2>/dev/null; }   # <canonical path>
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
  local before; before=$(cat "$DECF")
  run_hook capture-decision.sh "$(dr_ask1 toolu_ad05b '질문 둘?' 'H2' 'C안')"
  assert_exit 0 ad05-exit
  [ "$(head -c "${#before}" "$DECF")" = "$before" ] || fail ad05-prefix-preserved
  [ "$(dr_count "$DECF" "$DR_TITLE")" = "1" ] || fail ad05-title-once
  local a b; a=$(dr_lineno "$DECF" '(toolu_ad05a)'); b=$(dr_lineno "$DECF" '(toolu_ad05b)')
  { [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; } || fail ad05-order
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

test_dr_cp_01() { # [v4.5] source=compact → <sid>.compact 한 줄 epoch(실행 시각) 기록, 상태 키 무변경
  dr_setup_task
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
  for s in startup resume; do
    dr_setup_task
    dr_compact_at 1000
    run_hook session-mode-guard.sh "$(dr_ss "$s")"
    [ "$(cat "$STATE_DIR/$SID.compact")" = "1000" ] || fail "cp03-kept-$s"
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
  dr_raw "$HOOKS_DIR/session-mode-guard.sh" "$(dr_ss compact)" "$SANDBOX/new"
  dr_is_prefix "$SANDBOX/old" "$SANDBOX/new" || fail cp05-legacy-kept
  grep -qxF "[게이트] 맥락이 압축됐습니다. 작업 폴더: $TP — requirement-spec.md · log.md · decisions.md를 Read 한 뒤 진행하세요." "$SANDBOX/new" \
    || { echo "  [dbg] new-tail=$(tail -n 2 "$SANDBOX/new" | tr '\n' ' ')"; fail cp05-guidance-line; }
}

test_dr_cp_06() { # [v4.5] compact + TASK_PATH 없음 → 안내 줄 없음, 종전 출력과 바이트 동일, .compact 는 기록
  dr_legacy_init
  write_state auto
  dr_raw "$LEG/session-mode-guard.sh" "$(dr_ss compact)" "$SANDBOX/old"
  write_state auto; rm -f "$STATE_DIR/$SID.compact"
  dr_raw "$HOOKS_DIR/session-mode-guard.sh" "$(dr_ss compact)" "$SANDBOX/new"
  assert_file_not_contains "$SANDBOX/new" '맥락이 압축됐습니다' cp06-no-guidance
  cmp -s "$SANDBOX/old" "$SANDBOX/new" || fail cp06-identical
  [ -f "$STATE_DIR/$SID.compact" ] || fail cp06-compact-recorded
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
    || { echo "  [dbg] stderr=$(printf '%s' "$HOOK_STDERR" | head -c 300)"; fail bl01-message-prefix; }
  local p q
  for p in "$SPECF" "$LOGF" "$DECF"; do
    printf '%s\n' "$HOOK_STDERR" | grep -qF -- "$p" || fail bl01-path-listed
    for q in "$SPECF" "$LOGF" "$DECF"; do       # 경로는 줄마다 하나
      [ "$p" = "$q" ] && continue
      if printf '%s\n' "$HOOK_STDERR" | grep -F -- "$p" | grep -qF -- "$q"; then fail bl01-one-path-per-line; fi
    done
  done
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
  assert_stderr_match '요구사항 명세 미합의\(SPEC=0\)' bl07-spec0-msg
  assert_stderr_no_match '압축 뒤 작업 기록 미독' bl07-spec0-first
  dr_setup_task UNSET 0 0 1; dr_compact_at $(( $(dr_now) - 100 ))
  dr_l1
  assert_exit 2 bl07-unset-exit
  assert_stderr_match '자율성 미선택\(MODE=UNSET\)' bl07-unset-msg
  assert_stderr_no_match '압축 뒤 작업 기록 미독' bl07-unset-first
}

test_dr_bl_08() { # [v4.5 I7] 사이드카가 깨져 판정 불가 → 새 차단 없음(종전 판정만: auto → 통과)
  dr_setup_task
  printf 'garbage\n' > "$STATE_DIR/$SID.compact"
  dr_l1
  assert_exit 0 bl08-garbage-compact-pass
  rm -f "$STATE_DIR/$SID.compact"; mkdir "$STATE_DIR/$SID.compact"
  dr_l1
  assert_exit 0 bl08-dir-compact-pass
  rmdir "$STATE_DIR/$SID.compact"; dr_compact_at $(( $(dr_now) - 100 ))
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
  dr_raw "$HOOKS_DIR/session-mode-guard.sh" "$(dr_ss compact)" "$SANDBOX/new"
  local g s; g=$(dr_lineno "$SANDBOX/new" '맥락이 압축됐습니다'); s=$(dr_lineno "$SANDBOX/new" '[고정 지시]')
  { [ -n "$g" ] && [ -n "$s" ] && [ "$g" -lt "$s" ]; } || { echo "  [dbg] g=$g s=$s"; fail si04-standing-last; }
}

test_dr_si_05() { # [v4.5] 1,500자 초과 → 잘라 넣고 '…(잘림)' (reinject·session 둘 다)
  local long; long=$(printf '가%.0s' $(seq 1 2000))
  dr_standing "$long\n"
  write_state auto
  local h out n
  for h in reinject-mode.sh session-mode-guard.sh; do
    out="$SANDBOX/trunc.$h"
    if [ "$h" = reinject-mode.sh ]; then dr_raw "$HOOKS_DIR/$h" "$(json_prompt '계속')" "$out"
    else dr_raw "$HOOKS_DIR/$h" "$(dr_ss startup)" "$out"; fi
    assert_file_contains "$out" '…(잘림)' "si05-marker-$h"
    if LC_ALL=C grep -qE '(가){1501}' "$out"; then fail "si05-cut-$h"; fi
    LC_ALL=C grep -qE '(가){1400}' "$out" || fail "si05-kept-$h"
    n=$(LC_ALL=C grep -o '가' "$out" | wc -l)
    [ "$n" -le 1500 ] || { echo "  [dbg] n=$n"; fail "si05-total-le-1500-$h"; }
  done
}

test_dr_si_06() { # [v4.5] 상한 미만(1,000자) → 자르지 않음
  local mid; mid=$(printf '나%.0s' $(seq 1 1000))
  dr_standing "$mid\n"
  write_state auto
  dr_raw "$HOOKS_DIR/reinject-mode.sh" "$(json_prompt '계속')" "$SANDBOX/o"
  assert_file_not_contains "$SANDBOX/o" '…(잘림)' si06-no-marker
  LC_ALL=C grep -qE '(나){1000}' "$SANDBOX/o" || fail si06-full
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

test_dr_cm_03() { # [v4.5 I8] 새 사이드카도 상태 디렉토리 하드 거부 범위 — Claude 가 .reread/.compact 를 직접 써서 해제 불가
  dr_setup_task; dr_compact_at $(( $(dr_now) - 100 ))
  run_hook gate-guard.sh "$(dr_tool PreToolUse Write "$STATE_DIR/$SID.reread")"
  assert_exit 2 cm03-write-reread-denied
  run_hook gate-guard.sh "$(dr_tool PreToolUse Edit "$STATE_DIR/$SID.compact")"
  assert_exit 2 cm03-edit-compact-denied
  run_hook gate-guard.sh "$(json_bash "printf '1\t$SPECF\n' > .claude/lazymode/$SID.reread")"
  assert_exit 2 cm03-bash-reread-denied
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
  run_hook capture-prompt.sh "$(json_prompt "$secret 이걸로 진행해")"
  run_hook_stdout reinject-mode.sh "$(json_prompt "$secret 이걸로 진행해")"
  run_hook capture-decision.sh "$(dr_ask1 toolu_pv1 '보호 질문?' 'PV' 'A안')"
  [ -f "$STATE_DIR/$SID.decisions" ] || fail pv01-sidecar-precondition
  assert_file_not_contains "$STATE_DIR/$SID.decisions" "$secret" pv01-sidecar-no-prompt
  TP=$(realpath -m -- "$REPO/docs/plans/2026-11-19/t1"); mkdir -p "$TP"
  echo s > "$TP/requirement-spec.md"; echo l > "$TP/log.md"; echo "TASK_PATH=$TP" >> "$STATE"
  run_hook capture-prompt.sh "$(json_prompt "$secret 두번째")"
  run_hook capture-decision.sh "$(dr_ask1 toolu_pv2 '보호 질문2?' 'PV' 'B안')"
  [ -f "$TP/decisions.md" ] || fail pv01-decisions-precondition
  assert_file_not_contains "$TP/decisions.md" "$secret" pv01-decisions-no-prompt
  if grep -rqF "$secret" "$STATE_DIR"/*.decisions 2>/dev/null; then fail pv01-no-prompt-anywhere; fi
}
