# req-check.sh — 요구 대조 표 파서 `state_reqcheck_scan <log.md>` 단위 케이스 (v4.10 · task 03)
# 계약 정본: docs/plans/2026-11-27/close-out-requirement-check/requirement-spec.md 2절 · 6.1 ① ② · 6.2
#            + 표의 꼴 = templates/log.md 의 "요구 대조" 절.
#   rc 0 = 판정함 — stdout: `VIOLATION\t<task>\t<행>`(닫음 + 넷째 칸 빈 칸) 그다음
#          `OPEN\t<task>\t<열림 빈 칸 수>\t<그 task 의 표 줄 수>`(열림 빈 칸이 있는 task 만, 처음 나온 차례)
#   rc 1 = 판정 불가 — stdout 한 줄(까닭 · 행 번호가 있으면 함께)
#   rc 2 = 표지 없음 · 파일 없음 — 출력 없음
# 설계: blind 테스트 워커(구현 미열람 — 명세와 proposal 7.5 의 사례 표에서 출발).
# 관례: sandbox_init 은 run.sh 러너가 각 테스트 앞에서 호출한다. 테스트 이름은 러너의 수집 정규식
#   (`test_[a-z0-9_]+`)에 맞춰 영문 규칙 문장으로, 사례 id(P1~)는 이름 앞머리와 주석에 둔다.

# ── 케이스 전용 상수 · 헬퍼 ───────────────────────────────────────────────────
RQ_MARK='<!-- req-check:v1 -->'
RQ_HEAD='| task | 원문 위치 | 요구 | 만든 곳 / 넘긴 곳 | 상태 |'
RQ_SEP='|---|---|---|---|---|'
RQ_TAB=$'\t'

rq_log() { # <줄...> → $RQ_LOG 에 한 줄씩 쓴다(sandbox 안)
  RQ_LOG="$SANDBOX/plans/t1/log.md"
  mkdir -p "$(dirname "$RQ_LOG")"
  printf '%s\n' "$@" > "$RQ_LOG"
}
rq_scan() { # <파일> [env 할당...] → RQ_OUT(stdout) · RQ_RC · RQ_ERR(stderr 앞부분 — dbg 용)
  local file=$1; shift
  set +e
  RQ_OUT=$(env "$@" HOME="$HOME_DIR" bash -c '. "$1" 2>/dev/null; state_reqcheck_scan "$2"' \
    _ "$HOOKS_DIR/state-lib.sh" "$file" 2>"$SANDBOX/scan.err")
  RQ_RC=$?
  set -e
  RQ_ERR=$(head -c 240 "$SANDBOX/scan.err" 2>/dev/null || true)
}
rq_line() { # <고정 문자열> → 그 글자가 처음 나오는 파일 행 번호(고정 자료 자체 확인)
  local number
  number=$(grep -nF -- "$1" "$RQ_LOG" | head -1 | cut -d: -f1 || true)
  [ -n "$number" ] || { echo "  [dbg] fixture 에 '$1' 없음"; fail fixture-needle-missing; }
  printf '%s' "$number"
}
rq_dbg() { echo "  [dbg] rc=$RQ_RC out=$(printf '%s' "$RQ_OUT" | head -c 300 | tr '\t\n' '>~') err=$RQ_ERR"; }
rq_assert_rc() { # <want> <assert-id>
  [ "$RQ_RC" = "$1" ] || { rq_dbg; fail "$2"; }
}
rq_assert_out() { # <want — 줄은 \n 으로> <assert-id>  — 바이트 그대로(차례 포함)
  [ "$RQ_OUT" = "$1" ] || { rq_dbg; echo "  [dbg] want=$(printf '%s' "$1" | tr '\t\n' '>~')"; fail "$2"; }
}
rq_assert_empty() { # <assert-id>
  [ -z "$RQ_OUT" ] || { rq_dbg; fail "$1"; }
}
rq_assert_one_line() { # <assert-id> — 판정 불가의 까닭은 비지 않은 한 줄
  local lines
  lines=$(printf '%s\n' "$RQ_OUT" | grep -c . || true)
  { [ -n "$RQ_OUT" ] && [ "$lines" = "1" ]; } || { rq_dbg; fail "$1"; }
}
rq_assert_has_number() { # <행 번호> <assert-id> — 까닭에 그 수가 낱말로(앞뒤가 숫자 아님)있다
  printf '%s' "$RQ_OUT" | grep -qE "(^|[^0-9])$1([^0-9]|\$)" || { rq_dbg; echo "  [dbg] want line=$1"; fail "$2"; }
}
rq_assert_has_text() { # <고정 문자열> <assert-id>
  printf '%s' "$RQ_OUT" | grep -qF -- "$1" || { rq_dbg; fail "$2"; }
}
rq_violation() { printf 'VIOLATION%s%s%s%s' "$RQ_TAB" "$1" "$RQ_TAB" "$2"; }               # <task> <행>
rq_open() { printf 'OPEN%s%s%s%s%s%s' "$RQ_TAB" "$1" "$RQ_TAB" "$2" "$RQ_TAB" "$3"; }      # <task> <빈 칸> <줄 수>

# 앞머리 글(행 번호가 표의 차례와 겹치지 않게 몇 줄 둔다)
rq_preamble() { printf '%s\n' '# 작업 log' '' '## 타임라인' '' '| 시각 | 사건 | 결과 |' '|---|---|---|' '| 17:00 | 시작 | - |' '' '## 요구 대조' ''; }

# ── P1 · 표지 ────────────────────────────────────────────────────────────────
test_rq_p01_log_without_marker_is_not_checked() { # P1 표지 없는 log → rc 2 · 출력 없음(닫음 빈 칸 줄이 있어도)
  rq_log "$(rq_preamble)" "$RQ_HEAD" "$RQ_SEP" '| T01 | 규약 §1 | 요구-가 | | 닫음 |' '| T01 | 규약 §2 | 요구-나 | | 열림 |'
  rq_scan "$RQ_LOG"
  rq_assert_rc 2 p01-rc2
  rq_assert_empty p01-no-output
}

test_rq_p15_quoted_marker_text_is_not_a_marker() { # P15 백틱 · 인용 안의 표지 글자는 표지가 아니다 — 진짜 표지 줄 뒤의 표만 판정
  rq_log "$(rq_preamble)" \
    "표지 줄은 \`$RQ_MARK\` 를 글자 그대로 둔다." \
    "$RQ_HEAD" "$RQ_SEP" '| T09 | 가짜 | 가짜-닫음 | | 닫음 |' '| T09 | 가짜 | 가짜-열림 | | 열림 |' \
    '' \
    "> $RQ_MARK" \
    "$RQ_HEAD" "$RQ_SEP" '| T08 | 가짜 | 인용-닫음 | | 닫음 |' \
    '' \
    "$RQ_MARK" \
    "$RQ_HEAD" "$RQ_SEP" '| T01 | 규약 §1 | 진짜-열림 | | 열림 |'
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p15-rc0
  rq_assert_out "$(rq_open T01 1 1)" p15-only-real-table
}

test_rq_p18_marker_and_header_ignore_surrounding_spaces() { # 표지 줄 앞뒤 공백 · 머리 줄 뒤 공백은 무시한다
  rq_log "$(rq_preamble)" "   $RQ_MARK  " "$RQ_HEAD   " "$RQ_SEP" '| T01 | 규약 §1 | 요구-가 | | 열림 |'
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p18-rc0
  rq_assert_out "$(rq_open T01 1 1)" p18-open
}

# ── P2 ~ P6 · 판정 ───────────────────────────────────────────────────────────
test_rq_p02_filled_table_reports_nothing() { # P2 모든 줄의 넷째 칸이 채워지면(열림 · 닫음 섞음) rc 0 · 출력 없음
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" \
    '| T01 | 규약 §1 · 10행 | 요구-가 | hooks/a.sh:10 | 닫음 |' \
    '| T01 | 규약 §2 | 요구-나 | 작성 중 hooks/a.sh | 열림 |' \
    '| T02 | - | 요구-다(원문 위치 칸만 비어 있다) | T03 으로 넘김(사용자 합의 17:10) | 닫음 |' \
    '| T02 | 규약 §3 | 요구-라 | abc1234 | 열림 |'
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p02-rc0
  rq_assert_empty p02-no-output
}

test_rq_p03_open_row_with_blank_counts_per_task() { # P3 열림 줄 둘 중 하나가 빈 칸 → OPEN T01 1 2
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" \
    '| T01 | 규약 §1 | 요구-가 | hooks/a.sh:3 | 열림 |' \
    '| T01 | 규약 §2 | 요구-나 | | 열림 |'
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p03-rc0
  rq_assert_out "$(rq_open T01 1 2)" p03-open-1-of-2
}

rq_fixture_p04() {
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" \
    '| T01 | 규약 §1 | 요구-채움 | hooks/a.sh:3 | 닫음 |' \
    '| T01 | 규약 §2 | 요구-닫음-빈칸 | | 닫음 |'
}
test_rq_p04_closed_row_with_blank_is_violation_with_file_line() { # P4 닫음 줄의 넷째 칸이 비면 VIOLATION · 행 = 파일의 실제 행
  rq_fixture_p04
  local line; line=$(rq_line '요구-닫음-빈칸')
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p04-rc0
  rq_assert_out "$(rq_violation T01 "$line")" p04-violation-line
}
test_rq_p04c_closed_row_violation_same_in_c_locale() { # P4 를 LC_ALL=C 로 — 같은 결과
  rq_fixture_p04
  local line; line=$(rq_line '요구-닫음-빈칸')
  rq_scan "$RQ_LOG" LC_ALL=C LANG=C
  rq_assert_rc 0 p04c-rc0
  rq_assert_out "$(rq_violation T01 "$line")" p04c-violation-line
}

rq_fixture_p05_closed() { # 닫음 줄 — 넷째 칸이 공백 · - · — · ? · 빈 글 / x · --
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" \
    '| T01 | 규약 §1 | 요구-공백 |    | 닫음 |' \
    '| T02 | 규약 §1 | 요구-하이픈 | - | 닫음 |' \
    '| T03 | 규약 §1 | 요구-엠대시 | — | 닫음 |' \
    '| T04 | 규약 §1 | 요구-물음 | ? | 닫음 |' \
    '| T05 | 규약 §1 | 요구-빈글 || 닫음 |' \
    '| T06 | 규약 §1 | 요구-엑스 | x | 닫음 |' \
    '| T07 | 규약 §1 | 요구-대시둘 | -- | 닫음 |'
}
rq_expect_p05_closed() { # → 위반 다섯(파일 차례) — T06(x) · T07(--) 은 채움
  printf '%s\n%s\n%s\n%s\n%s' \
    "$(rq_violation T01 "$(rq_line '요구-공백')")" \
    "$(rq_violation T02 "$(rq_line '요구-하이픈')")" \
    "$(rq_violation T03 "$(rq_line '요구-엠대시')")" \
    "$(rq_violation T04 "$(rq_line '요구-물음')")" \
    "$(rq_violation T05 "$(rq_line '요구-빈글')")"
}
test_rq_p05_single_dash_emdash_question_space_are_blank_x_is_filled() { # P5 공백 · - · — · ? 하나뿐은 빈 칸, x · -- 는 채움(닫음)
  rq_fixture_p05_closed
  local want; want=$(rq_expect_p05_closed)
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p05-rc0
  # VIOLATION 사이의 차례는 계약에 적혀 있지 않다 — 집합으로 본다
  [ "$(printf '%s\n' "$RQ_OUT" | LC_ALL=C sort)" = "$(printf '%s\n' "$want" | LC_ALL=C sort)" ] || {
    rq_dbg; echo "  [dbg] want=$(printf '%s' "$want" | tr '\t\n' '>~')"; fail p05-blank-kinds; }
}
test_rq_p05c_blank_kinds_same_in_c_locale() { # P5 를 LC_ALL=C 로 — 같은 결과(— 는 여러 바이트)
  rq_fixture_p05_closed
  local want; want=$(rq_expect_p05_closed)
  rq_scan "$RQ_LOG" LC_ALL=C LANG=C
  rq_assert_rc 0 p05c-rc0
  [ "$(printf '%s\n' "$RQ_OUT" | LC_ALL=C sort)" = "$(printf '%s\n' "$want" | LC_ALL=C sort)" ] || {
    rq_dbg; echo "  [dbg] want=$(printf '%s' "$want" | tr '\t\n' '>~')"; fail p05c-blank-kinds; }
}
test_rq_p05b_blank_kinds_count_in_open_rows() { # P5 열림 줄 — 공백 · - · — · ? 는 빈 칸 넷, x · -- 는 채움 → OPEN T01 4 6
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" \
    '| T01 | 규약 §1 | 요구-공백 |   | 열림 |' \
    '| T01 | 규약 §1 | 요구-하이픈 | - | 열림 |' \
    '| T01 | 규약 §1 | 요구-엠대시 | — | 열림 |' \
    '| T01 | 규약 §1 | 요구-물음 | ? | 열림 |' \
    '| T01 | 규약 §1 | 요구-엑스 | x | 열림 |' \
    '| T01 | 규약 §1 | 요구-대시둘 | -- | 열림 |'
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p05b-rc0
  rq_assert_out "$(rq_open T01 4 6)" p05b-open-4-of-6
}

test_rq_p06_escaped_pipe_is_not_a_cell_boundary() { # P6 칸 안의 \| 는 칸 경계가 아니다 — 칸 다섯으로 판정
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" \
    '| T01 | 규약 §1 | a \| b | hooks/a.sh:1 | 닫음 |' \
    '| T01 | 규약 §2 | c \| d | | 열림 |'
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p06-rc0
  rq_assert_out "$(rq_open T01 1 2)" p06-five-cells
}

test_rq_p16_open_lines_follow_first_appearance_with_per_task_counts() { # P16 T01 · T02 · T01 순 → OPEN 은 T01 · T02 차례, 수는 task 별
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" \
    '| T01 | 규약 §1 | 요구-1 | | 열림 |' \
    '| T02 | 규약 §2 | 요구-2 | | 열림 |' \
    '| T01 | 규약 §3 | 요구-3 | hooks/a.sh:9 | 닫음 |' \
    '| T02 | 규약 §4 | 요구-4 | hooks/b.sh:1 | 열림 |' \
    '| T01 | 규약 §5 | 요구-5 | | 열림 |'
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p16-rc0
  rq_assert_out "$(printf '%s\n%s' "$(rq_open T01 2 3)" "$(rq_open T02 1 2)")" p16-order-and-counts
}

test_rq_p17_violations_come_before_open_lines() { # VIOLATION 줄이 OPEN 줄보다 먼저(파일에서 열림 줄이 앞이어도) · 닫음 줄도 줄 수에 든다
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" \
    '| T01 | 규약 §1 | 요구-열림-빈칸 | | 열림 |' \
    '| T02 | 규약 §2 | 요구-닫음-빈칸 | | 닫음 |' \
    '| T01 | 규약 §3 | 요구-닫음-채움 | hooks/a.sh:2 | 닫음 |'
  local line; line=$(rq_line '요구-닫음-빈칸')
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p17-rc0
  rq_assert_out "$(printf '%s\n%s' "$(rq_violation T02 "$line")" "$(rq_open T01 1 2)")" p17-violation-first
}

# ── P7 ~ P10 · 판정 불가 ─────────────────────────────────────────────────────
test_rq_p07_header_mismatch_is_undecidable_with_line() { # P7 머리 줄의 칸 이름 하나가 다르면 rc 1 · 까닭에 머리 줄의 행 번호
  rq_log "$(rq_preamble)" "$RQ_MARK" '| task | 원문 위치 | 요구 | 만든 곳 | 상태 |' "$RQ_SEP" \
    '| T01 | 규약 §1 | 요구-가 | hooks/a.sh:1 | 닫음 |'
  local line; line=$(rq_line '| task | 원문 위치 | 요구 | 만든 곳 | 상태 |')
  rq_scan "$RQ_LOG"
  rq_assert_rc 1 p07-rc1
  rq_assert_one_line p07-one-line
  rq_assert_has_number "$line" p07-reason-line
}

test_rq_p08_unknown_status_value_is_undecidable() { # P8 상태가 열림 · 닫음 밖(닫힘)이면 rc 1 · 까닭에 값과 행 번호
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" \
    '| T01 | 규약 §1 | 요구-가 | hooks/a.sh:1 | 닫음 |' \
    '| T01 | 규약 §2 | 요구-상태틀림 | hooks/a.sh:2 | 닫힘 |'
  local line; line=$(rq_line '요구-상태틀림')
  rq_scan "$RQ_LOG"
  rq_assert_rc 1 p08-rc1
  rq_assert_one_line p08-one-line
  rq_assert_has_text '닫힘' p08-reason-value
  rq_assert_has_number "$line" p08-reason-line
}

test_rq_p09_four_cells_is_undecidable() { # P9 칸 수 넷이면 rc 1 · 까닭에 행 번호
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" \
    '| T01 | 규약 §1 | 요구-가 | hooks/a.sh:1 | 닫음 |' \
    '| T01 | 요구-칸넷 | hooks/a.sh:2 | 닫음 |'
  local line; line=$(rq_line '요구-칸넷')
  rq_scan "$RQ_LOG"
  rq_assert_rc 1 p09-rc1
  rq_assert_one_line p09-one-line
  rq_assert_has_number "$line" p09-reason-line
}

test_rq_p09b_six_cells_is_undecidable() { # 경계 바깥쪽: 이스케이프하지 않은 | 로 칸 여섯이면 rc 1
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" \
    '| T01 | 규약 §1 | a | b | hooks/a.sh:1 | 닫음 |'
  rq_scan "$RQ_LOG"
  rq_assert_rc 1 p09b-rc1
  rq_assert_one_line p09b-one-line
}

test_rq_p10_marker_without_table_is_undecidable() { # P10 표지 뒤에 표가 없으면 rc 1(표지가 파일 끝 · 표지 뒤가 글뿐)
  rq_log "$(rq_preamble)" "$RQ_MARK"
  rq_scan "$RQ_LOG"
  rq_assert_rc 1 p10-eof-rc1
  rq_assert_one_line p10-eof-one-line
  rq_log "$(rq_preamble)" "$RQ_MARK" '표는 아직 없다.' '' '## 고장 내기' '' '글만 있다.'
  rq_scan "$RQ_LOG"
  rq_assert_rc 1 p10-text-rc1
  rq_assert_one_line p10-text-one-line
}

test_rq_p19_header_without_separator_is_undecidable() { # 머리 줄 다음이 구분 줄이 아니면 rc 1
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" '| T01 | 규약 §1 | 요구-가 | | 닫음 |'
  rq_scan "$RQ_LOG"
  rq_assert_rc 1 p19-rc1
  rq_assert_one_line p19-one-line
}

# ── P11 · P12 · 파일 ─────────────────────────────────────────────────────────
test_rq_p11_table_after_200kb_is_still_read() { # P11 200KB 넘는 앞 내용 뒤의 표도 읽는다(log 를 끝까지 읽는다)
  RQ_LOG="$SANDBOX/plans/t1/log.md"
  mkdir -p "$(dirname "$RQ_LOG")"
  {
    rq_preamble
    awk 'BEGIN { for (i = 1; i <= 6000; i++) printf "| %d | 앞 내용의 긴 타임라인 줄 — 잘라 읽으면 뒤의 표를 놓친다 | 결과 |\n", i }'
    echo ''
    echo "$RQ_MARK"; echo "$RQ_HEAD"; echo "$RQ_SEP"
    echo '| T04 | 규약 §7.1 · 478행 | 요구-끝의-닫음-빈칸 | | 닫음 |'
  } > "$RQ_LOG"
  local size; size=$(wc -c < "$RQ_LOG")
  [ "$size" -gt 204800 ] || { echo "  [dbg] size=$size"; fail p11-fixture-over-200kb; }
  local line; line=$(rq_line '요구-끝의-닫음-빈칸')
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p11-rc0
  rq_assert_out "$(rq_violation T04 "$line")" p11-violation-at-end
}

test_rq_p12_symlinked_log_is_undecidable() { # P12 log.md 가 심링크면 rc 1(가리키는 파일이 맞는 표여도)
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" '| T01 | 규약 §1 | 요구-가 | hooks/a.sh:1 | 닫음 |'
  mkdir -p "$SANDBOX/plans/t2"
  ln -s "$RQ_LOG" "$SANDBOX/plans/t2/log.md"
  rq_scan "$SANDBOX/plans/t2/log.md"
  rq_assert_rc 1 p12-symlink-rc1
  rq_assert_one_line p12-symlink-one-line
}

test_rq_p12b_missing_log_is_not_checked() { # P12 log.md 가 없으면 rc 2 · 출력 없음
  mkdir -p "$SANDBOX/plans/t3"
  rq_scan "$SANDBOX/plans/t3/log.md"
  rq_assert_rc 2 p12b-missing-rc2
  rq_assert_empty p12b-missing-no-output
}

# ── P13 · P14 · 표의 끝 ──────────────────────────────────────────────────────
test_rq_p13_only_first_table_after_marker_is_read() { # P13 표 뒤 빈 줄 다음의 다른 표(빈 칸 많은 표 · 고장 내기 표)는 읽지 않는다
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" \
    '| T01 | 규약 §1 | 요구-가 | hooks/a.sh:1 | 닫음 |' \
    '' \
    "$RQ_HEAD" "$RQ_SEP" \
    '| T02 | 규약 §2 | 둘째표-닫음 | | 닫음 |' \
    '| T02 | 규약 §3 | 둘째표-열림 | | 열림 |' \
    '' \
    '## 고장 내기' \
    '' \
    '| 불변식 | 테스트 | 고장 낸 곳(file:line · 바꾼 내용) | 실패 메시지 첫 줄 | 되돌린 뒤 통과 |' \
    '|--------|--------|-----------------------------------|-------------------|----------------|' \
    '| | | | | |'
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p13-rc0
  rq_assert_empty p13-second-table-ignored
}

test_rq_p13b_table_ends_at_non_pipe_text_line() { # 표는 | 로 시작하지 않는 줄(빈 줄 아님)에서도 끝난다 — 그 뒤의 | 줄은 읽지 않는다
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" \
    '| T01 | 규약 §1 | 요구-가 | hooks/a.sh:1 | 닫음 |' \
    '표 밖의 글 한 줄' \
    '| T02 | 규약 §2 | 표밖-닫음 | | 닫음 |'
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p13b-rc0
  rq_assert_empty p13b-after-text-ignored
}

test_rq_p14_empty_table_reports_nothing() { # P14 빈 표(머리 · 구분 줄만)는 rc 0 · 출력 없음
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" '' '## 고장 내기' '' \
    '| 불변식 | 테스트 | 고장 낸 곳(file:line · 바꾼 내용) | 실패 메시지 첫 줄 | 되돌린 뒤 통과 |' \
    '|--------|--------|-----------------------------------|-------------------|----------------|' \
    '| | | | | |'
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p14-rc0
  rq_assert_empty p14-no-output
}

test_rq_p14b_log_template_as_is_reports_nothing() { # P14 log 템플릿 그대로(가로지르는 계약: 템플릿의 표지 · 머리 줄 ↔ 파서) → rc 0 · 출력 없음
  local template="$HOOKS_DIR/../templates/log.md"
  [ -f "$template" ] || skip_test log-template-absent
  grep -qxF -- "$RQ_MARK" "$template" || fail p14b-template-has-marker
  grep -qxF -- "$RQ_HEAD" "$template" || fail p14b-template-has-header
  RQ_LOG="$SANDBOX/plans/t1/log.md"
  mkdir -p "$(dirname "$RQ_LOG")"
  cp -- "$template" "$RQ_LOG"
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p14b-rc0
  rq_assert_empty p14b-no-output
}

# ── 메인이 더 정한 계약(11-27 17:5x — 판정 불가로 떨어지지 않게 할 흔한 꼴 · 읽을 수 없는 파일) ──
test_rq_p20_blank_lines_between_marker_and_header_are_skipped() { # 표지 줄과 머리 줄 사이의 빈 줄(공백뿐인 줄 포함)은 건너뛴다
  rq_log "$(rq_preamble)" "$RQ_MARK" '' '   ' "$RQ_HEAD" "$RQ_SEP" \
    '| T01 | 규약 §1 | 요구-가 | | 열림 |' \
    '| T01 | 규약 §2 | 요구-닫음-빈칸 | | 닫음 |'
  local line; line=$(rq_line '요구-닫음-빈칸')
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p20-rc0
  rq_assert_out "$(printf '%s\n%s' "$(rq_violation T01 "$line")" "$(rq_open T01 1 2)")" p20-judged
}

test_rq_p21_crlf_log_gives_same_result_as_lf() { # CRLF — 줄 끝의 \r 은 공백으로 본다 → LF 와 같은 결과
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" \
    '| T01 | 규약 §1 | 요구-1 | | 열림 |' \
    '| T02 | 규약 §2 | 요구-닫음-빈칸 | | 닫음 |' \
    '| T01 | 규약 §3 | 요구-3 | hooks/a.sh:9 | 닫음 |'
  local line; line=$(rq_line '요구-닫음-빈칸')
  sed -i 's/$/\r/' "$RQ_LOG"
  grep -q $'\r$' "$RQ_LOG" || fail p21-fixture-crlf
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p21-rc0
  rq_assert_out "$(printf '%s\n%s' "$(rq_violation T02 "$line")" "$(rq_open T01 1 2)")" p21-same-as-lf
}

test_rq_p22_unreadable_log_is_undecidable() { # 읽기 권한이 없는 log.md 는 표지가 있든 없든 rc 1(판정 불가)
  [ "$(id -u)" != "0" ] || skip_test root-reads-anything
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" '| T01 | 규약 §1 | 요구-가 | hooks/a.sh:1 | 닫음 |'
  chmod 000 "$RQ_LOG"
  rq_scan "$RQ_LOG"
  rq_assert_rc 1 p22-marker-rc1
  rq_assert_one_line p22-marker-one-line
  chmod 600 "$RQ_LOG"
  rq_log "$(rq_preamble)" '표지 없는 log'
  chmod 000 "$RQ_LOG"
  rq_scan "$RQ_LOG"
  rq_assert_rc 1 p22-nomarker-rc1
  rq_assert_one_line p22-nomarker-one-line
  chmod 600 "$RQ_LOG"
}

test_rq_p23_indented_table_lines_are_table_lines() { # 앞뒤 공백을 무시한 뒤 | 로 시작하면 표의 줄(머리 · 구분 · 본문 모두 — 앞 공백 있는 머리 줄도)
  rq_log "$(rq_preamble)" "$RQ_MARK" "  $RQ_HEAD" "  $RQ_SEP" \
    '  | T01 | 규약 §1 | 요구-가 | | 열림 |' \
    $'\t| T01 | 규약 §2 | 요구-닫음-빈칸 | | 닫음 |' \
    '   | T01 | 규약 §3 | 요구-다 | hooks/a.sh:1 | 닫음 |'
  local line; line=$(rq_line '요구-닫음-빈칸')
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p23-rc0
  rq_assert_out "$(printf '%s\n%s' "$(rq_violation T01 "$line")" "$(rq_open T01 1 3)")" p23-indented-rows
}

test_rq_p24_escaped_pipe_in_fourth_cell_is_filled() { # 넷째 칸 안의 \| 는 칸 경계가 아니고 채움이다
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" \
    '| T01 | 규약 §1 | 요구-가 | a.sh:1 \| b.sh:2 | 닫음 |' \
    '| T01 | 규약 §2 | 요구-나 | \| | 열림 |'
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p24-rc0
  rq_assert_empty p24-filled
}

test_rq_p25_bold_status_is_undecidable() { # 상태 **닫음** 은 상태 값 밖 → rc 1
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" '| T01 | 규약 §1 | 요구-굵게 | hooks/a.sh:1 | **닫음** |'
  local line; line=$(rq_line '요구-굵게')
  rq_scan "$RQ_LOG"
  rq_assert_rc 1 p25-rc1
  rq_assert_one_line p25-one-line
  rq_assert_has_number "$line" p25-reason-line
}

test_rq_p25b_status_surrounding_spaces_are_ignored() { # 상태 칸의 앞뒤 공백은 무시한다 —   닫음   은 닫음
  rq_log "$(rq_preamble)" "$RQ_MARK" "$RQ_HEAD" "$RQ_SEP" '| T01 | 규약 §1 | 요구-닫음-빈칸 | |    닫음   |'
  local line; line=$(rq_line '요구-닫음-빈칸')
  rq_scan "$RQ_LOG"
  rq_assert_rc 0 p25b-rc0
  rq_assert_out "$(rq_violation T01 "$line")" p25b-violation
}
