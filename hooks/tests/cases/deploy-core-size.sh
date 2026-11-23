# deploy-core-size 케이스 — hooks/deploy.sh 가 src/core.md 의 글자 수가 상한(15,404자)을 넘으면 한 줄로 알린다(막지 않음).
# 계약 정본: docs/plans/2026-11-22/service-communication-http-default/requirement-spec.md 9절 task 10나 "계약" ①~⑥.
# 설계: blind 테스트 워커 — hooks/deploy.sh 의 내용을 읽지 않고 계약에서만 썼다. 기대값의 출처는 명세뿐.
# 관례: sandbox_init 은 run.sh 러너가 각 테스트 앞에서 호출한다 — 케이스 함수는 호출하지 않는다.
# 격리: 테스트마다 $SANDBOX 안에 저장소 사본(hooks/ 전체 + manifest 의 나머지는 최소 더미)과 임시 HOME(.claude)을 만들고
#   그 사본의 deploy.sh 를 --dry-run 으로만 부른다. 실제 배포는 끝의 smoke 가 테스트 전체를 다시 돌려 재귀가 되므로 쓰지 않는다.
# 글자 수 fixture 는 python3 으로 만들고, README 의 세는 법(같은 python3 한 줄)으로 길이를 다시 확인한다.

DC_LIMIT=15404
DC_DRYRUN_LINE='[deploy] dry-run — 실제 배포·smoke 는 수행하지 않음(기존 유지).'
DC_NOTICE_PREFIX='[deploy] 알림:'

# ── 셋업 ─────────────────────────────────────────────────────────────────────
# 저장소 사본을 $SANDBOX/harness 에 만든다. hooks/ 는 작업 트리의 것을 통째로(deploy.sh 가 무엇을 쓰는지 보지 않으므로),
# manifest 의 나머지(HISTORY.md, playbooks, templates, agents)는 최소 더미. 임시 HOME 에 .claude 를 둔다.
dc_setup() {
  command -v python3 >/dev/null 2>&1 || skip_test no-python3-for-fixture
  DC_HARNESS="$SANDBOX/harness"
  DC_HOME="$SANDBOX/dchome"
  mkdir -p "$DC_HARNESS/src" "$DC_HARNESS/playbooks" "$DC_HARNESS/templates" "$DC_HARNESS/agents" "$DC_HOME/.claude"
  cp -a "$HOOKS_DIR" "$DC_HARNESS/hooks"
  [ -f "$DC_HARNESS/hooks/deploy.sh" ] || fail dc-setup-deploy-missing
  printf '# HISTORY\n' > "$DC_HARNESS/HISTORY.md"
  printf '# playbook\n' > "$DC_HARNESS/playbooks/dummy.md"
  printf '# template\n' > "$DC_HARNESS/templates/dummy.md"
  printf '# agent\n' > "$DC_HARNESS/agents/dummy.md"
}

# src/core.md 를 정확히 <N> 글자로 쓴다. <kind> = ascii('x') | hangul('가' — UTF-8 3바이트).
#   100글자(99글자 + 줄바꿈)짜리 줄을 이어 붙이고 나머지를 마지막 줄로. 줄바꿈도 글자로 센다.
#   [mirror] 를 주면 임시 HOME 의 .claude/core.md 도 같은 내용으로 둔다(manifest diff 에 core.md 가 나오지 않게).
dc_core() { # <N> <ascii|hangul> [mirror]
  python3 - "$DC_HARNESS/src/core.md" "$1" "$2" <<'PY'
import sys
path, n, kind = sys.argv[1], int(sys.argv[2]), sys.argv[3]
ch = 'x' if kind == 'ascii' else '가'
line = ch * 99 + '\n'
s = line * (n // 100) + ch * (n % 100)
with open(path, 'w', encoding='utf-8', newline='') as f:
    f.write(s)
PY
  local got
  got=$(python3 -c 'import sys;print(len(open(sys.argv[1],encoding="utf-8").read()))' "$DC_HARNESS/src/core.md")
  [ "$got" = "$1" ] || { echo "  [dbg] fixture chars=$got want=$1"; fail dc-fixture-length; }
  if [ "${3:-}" = "mirror" ]; then cp "$DC_HARNESS/src/core.md" "$DC_HOME/.claude/core.md"; fi
}

# 사본의 deploy.sh --dry-run 을 부른다. 앞 인자는 env 에 그대로 넘긴다(PATH=…, LC_ALL=… 등).
#   → DC_EXIT · DC_OUT(stdout) · DC_ERR(stderr) · DC_ALL(둘을 이어 붙인 것)
dc_run() { # [VAR=값 ...]
  local out="$SANDBOX/dc.out" err="$SANDBOX/dc.err"
  set +e
  env HOME="$DC_HOME" "$@" "$BASH" "$DC_HARNESS/hooks/deploy.sh" --dry-run >"$out" 2>"$err"
  DC_EXIT=$?
  set -e
  DC_OUT=$(cat "$out"); DC_ERR=$(cat "$err")
  DC_ALL=$(printf '%s\n%s' "$DC_OUT" "$DC_ERR")
}

dc_dbg() { echo "  [dbg] exit=$DC_EXIT stdout=$(printf '%s' "$DC_OUT" | tail -c 400) stderr=$(printf '%s' "$DC_ERR" | head -c 240)"; }

# 알림 줄 수 — `[deploy] 알림:` 으로 시작하는 줄
dc_notice_count() { # <text>
  printf '%s\n' "$1" | grep -cF -- "$DC_NOTICE_PREFIX" | tr -d ' ' || true
}
dc_notice_lines() { # <text>
  printf '%s\n' "$1" | grep -F -- "$DC_NOTICE_PREFIX" || true
}
dc_line_starts_with() { # <text> <prefix> → 0 이면 그 prefix 로 시작하는 줄이 있다
  printf '%s\n' "$1" | awk -v p="$2" 'index($0, p) == 1 { found=1 } END { exit !found }'
}

# 공통 단정: 막지 않는다 — 종료 0, dry-run 끝 줄이 나온다 (계약 ④)
dc_assert_not_blocked() { # <assert-id 접두>
  [ "$DC_EXIT" = "0" ] || { dc_dbg; fail "$1-exit"; }
  printf '%s\n' "$DC_ALL" | grep -qxF -- "$DC_DRYRUN_LINE" || { dc_dbg; fail "$1-dryrun-line"; }
}
# 알림이 정확히 한 번, stdout 에, 기대한 앞부분으로 (계약 ②)
dc_assert_over_notice() { # <N> <assert-id 접두>
  local n=$1 over=$(( $1 - DC_LIMIT ))
  local want="[deploy] 알림: src/core.md ${n}자 — 상한 ${DC_LIMIT}자를 ${over}자 넘음."
  [ "$(dc_notice_count "$DC_ALL")" = "1" ] || { dc_dbg; fail "$2-once"; }
  [ "$(dc_notice_count "$DC_OUT")" = "1" ] || { dc_dbg; fail "$2-stdout"; }
  dc_line_starts_with "$DC_OUT" "$want" || { echo "  [dbg] want-prefix=$want got=$(dc_notice_lines "$DC_ALL")"; fail "$2-text"; }
}
dc_assert_no_notice() { # <assert-id>
  [ "$(dc_notice_count "$DC_ALL")" = "0" ] || { echo "  [dbg] got=$(dc_notice_lines "$DC_ALL")"; fail "$1"; }
}

# 임시 HOME 의 .claude 상태(내용·형식) — dry-run 이 아무것도 쓰지 않았나
dc_home_snapshot() {
  (cd "$DC_HOME" && find . -printf '%p %y %m %s\n' | LC_ALL=C sort
   find . -type f -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum)
}

# python3 만 뺀 PATH 용 bin 폴더 — 지금 PATH 의 모든 실행 파일을 심볼릭 링크로 모으고 python* 만 뺀다
#   (deploy.sh 가 무엇을 쓰는지 보지 않으므로 넉넉히 전부 넣는다). → stdout: bin 경로
dc_bin_without_python() {
  local bin="$SANDBOX/dc-bin" dir f name
  mkdir -p "$bin"
  local IFS=:
  for dir in $PATH; do
    [ -d "$dir" ] || continue
    for f in "$dir"/*; do
      name=${f##*/}
      case "$name" in python|python[0-9]*) continue ;; esac
      [ -x "$f" ] && [ ! -d "$f" ] && [ ! -e "$bin/$name" ] && ln -s "$f" "$bin/$name"
    done
  done
  printf '%s' "$bin"
}

# ── 사례 ─────────────────────────────────────────────────────────────────────

# [계약 ③④] 상한과 같은 15,404자 → 알림 줄 없음, 종료 0, dry-run 끝 줄
test_dc_01_core_at_limit_no_notice() {
  dc_setup
  dc_core 15404 ascii
  dc_run
  dc_assert_not_blocked dc01
  dc_assert_no_notice dc01-no-notice
}

# [계약 ①②④] 15,405자(넘는 첫 값) → 알림 한 줄(stdout, 정확히 한 번), "15405자"와 "15404자를 1자 넘음",
#   종료 0, dry-run 끝 줄, 임시 HOME 은 그대로(dry-run 은 쓰지 않는다)
test_dc_02_core_one_over_notice_once() {
  dc_setup
  dc_core 15405 ascii
  local before; before=$(dc_home_snapshot)
  dc_run
  dc_assert_not_blocked dc02
  dc_assert_over_notice 15405 dc02-notice
  [ "$(dc_home_snapshot)" = "$before" ] || fail dc02-home-unchanged
}

# [계약 ②] 크게 넘는 값 16,000자 → N 과 차이(596)가 맞다
test_dc_03_core_far_over_reports_count_and_excess() {
  dc_setup
  dc_core 16000 ascii
  dc_run
  dc_assert_not_blocked dc03
  dc_assert_over_notice 16000 dc03-notice
}

# [계약 ⑤] 한글로 채운 15,404자(바이트는 46,000을 넘음), C 로캘 → 알림 없음 (바이트가 아니라 글자로 센다)
test_dc_04_hangul_bytes_over_chars_at_limit_no_notice() {
  dc_setup
  dc_core 15404 hangul
  local bytes; bytes=$(wc -c < "$DC_HARNESS/src/core.md" | tr -d ' ')
  [ "$bytes" -gt "$DC_LIMIT" ] || { echo "  [dbg] bytes=$bytes"; fail dc04-fixture-bytes; }
  dc_run LC_ALL=C
  dc_assert_not_blocked dc04
  dc_assert_no_notice dc04-no-notice
}

# [계약 ②⑤] 한글 15,405자, C 로캘 → 글자 수로 15405자 / 1자 넘음 (바이트 수를 내지 않는다)
test_dc_05_hangul_one_over_counts_chars() {
  dc_setup
  dc_core 15405 hangul
  dc_run LC_ALL=C
  dc_assert_not_blocked dc05
  dc_assert_over_notice 15405 dc05-notice
}

# [계약 ⑥④] python3 을 찾을 수 없는 PATH → "글자 수를 세지 못함" 한 줄, 다른 알림 줄 없음, 종료 0, dry-run 끝 줄
#   (상한을 넘는 15,405자로 둔다 — 세지 못하면서 넘음 줄을 내거나 조용히 넘어가면 잡힌다)
test_dc_06_no_python3_cannot_count_notice() {
  dc_setup
  dc_core 15405 ascii
  local bin; bin=$(dc_bin_without_python)
  [ -x "$bin/bash" ] || fail dc06-bin-no-bash
  if PATH="$bin" command -v python3 >/dev/null 2>&1; then fail dc06-bin-has-python3; fi
  dc_run PATH="$bin"
  dc_assert_not_blocked dc06
  [ "$(dc_notice_count "$DC_ALL")" = "1" ] || { dc_dbg; fail dc06-notice-once; }
  dc_line_starts_with "$DC_ALL" "[deploy] 알림: src/core.md 글자 수를 세지 못함" || { dc_dbg; fail dc06-notice-text; }
}

# [계약 ④] 알림이 있을 때(15,405)와 없을 때(15,404) — 알림 줄을 뺀 stdout, stderr, 종료 코드가 같다.
#   같은 sandbox 에서 core.md 만 바꿔 두 번 부르고, 임시 HOME 의 core.md 도 같게 두어 manifest diff 에 core.md 내용이 끼지 않게 한다.
test_dc_07_notice_leaves_other_output_unchanged() {
  dc_setup
  dc_core 15404 ascii mirror
  dc_run
  local base_out=$DC_OUT base_err=$DC_ERR base_exit=$DC_EXIT
  dc_core 15405 ascii mirror
  dc_run
  dc_assert_over_notice 15405 dc07-notice
  [ "$DC_EXIT" = "$base_exit" ] || { dc_dbg; fail dc07-exit-same; }
  local stripped; stripped=$(printf '%s\n' "$DC_OUT" | grep -vF -- "$DC_NOTICE_PREFIX" || true)
  local base_stripped; base_stripped=$(printf '%s\n' "$base_out" | grep -vF -- "$DC_NOTICE_PREFIX" || true)
  [ "$(dc_notice_count "$base_out")" = "0" ] || fail dc07-base-has-notice
  [ "$stripped" = "$base_stripped" ] || { diff <(printf '%s\n' "$base_stripped") <(printf '%s\n' "$stripped") | head -5 | sed 's/^/  [dbg] /'; fail dc07-stdout-same; }
  [ "$DC_ERR" = "$base_err" ] || { echo "  [dbg] stderr differs"; fail dc07-stderr-same; }
}

# [계약 ⑥④] src/core.md 가 UTF-8 로 읽을 수 없는 바이트를 담음(정상 15,405자 뒤에 \xff\xfe) → 세기가 실행 중 실패하는 경우.
#   "글자 수를 세지 못함" 한 줄이 stdout 에 정확히 한 번, "넘음" 줄 없음, 종료 0, dry-run 끝 줄.
#   (상한을 넘는 내용으로 둔다 — 깨진 바이트를 버리거나 바꿔 세고 넘음 줄을 내거나 조용히 넘어가면 잡힌다)
test_dc_08_undecodable_core_cannot_count_notice() {
  dc_setup
  dc_core 15405 ascii
  printf '\xff\xfe' >> "$DC_HARNESS/src/core.md"
  if python3 -c 'import sys;open(sys.argv[1],encoding="utf-8").read()' "$DC_HARNESS/src/core.md" 2>/dev/null; then
    fail dc08-fixture-decodable
  fi
  dc_run
  dc_assert_not_blocked dc08
  local want="[deploy] 알림: src/core.md 글자 수를 세지 못함"
  [ "$(dc_notice_count "$DC_ALL")" = "1" ] || { dc_dbg; fail dc08-notice-once; }
  [ "$(dc_notice_count "$DC_OUT")" = "1" ] || { dc_dbg; fail dc08-notice-stdout; }
  dc_line_starts_with "$DC_OUT" "$want" || { echo "  [dbg] want-prefix=$want got=$(dc_notice_lines "$DC_ALL")"; fail dc08-notice-text; }
  if printf '%s\n' "$DC_ALL" | grep -F -- "$DC_NOTICE_PREFIX" | grep -qF -- '넘음'; then
    echo "  [dbg] got=$(dc_notice_lines "$DC_ALL")"; fail dc08-no-over-notice
  fi
}
