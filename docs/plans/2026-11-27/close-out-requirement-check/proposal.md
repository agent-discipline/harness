# 바꿀 글의 제안 — task 를 닫기 전 요구 대조 (2판 — 사용자의 답 반영)

> 기준: 하네스 `origin/main` `7688bad`. 줄 번호는 그 판의 것이다. **이 문서의 diff 는 아직 적용하지 않았다** — 정책 파일 · 훅은 고치지 않았다.
> 사용자의 답(명세 0절): 훅으로도 막는다 · 모든 task(큰 표만 워커 대조) · 안 A(훅 목록을 README 로). 아래는 더 물을 것(Q6 (가) · Q7 (나) · Q8 (가))을 권하는 답으로 가정해 썼다 — 다른 답이면 그 부분을 뺀다.
> 글자 수는 README 33행의 세는 법으로, 제안을 저장소 밖 사본(`…/scratchpad/proposal-check/core-A2.md`)에 실제로 적용해 셌다. 훅 코드는 **제안 글**이다 — 돌려 보지 않았다(구현 · 테스트는 다음 차례 task 03~05).

## 0. 요지

- **core 에 들어갈 문장**(§4 "개발 자세" 줄 바로 아래 — 340자):

  > - **task를 닫기 전 요구 대조(실측 2026-11-27)**: task를 시작할 때 명세와 명세가 가리키는 계약 문서에서 그 task의 요구를 줄마다 log 표에 옮기고, 닫기 전에 줄마다 만든 곳(file:line·커밋)이나 넘긴 곳(받는 task·사용자 합의 시각)을 채운 뒤 상태를 `닫음`으로 바꾼다. 빈 칸이 있으면 닫지 않는다 — `닫음` 줄의 빈 칸은 gate-guard가 L1 쓰기를 막고 `열림` 줄의 빈 칸은 매 턴 알린다(표가 없으면 훅은 보지 못한다). 테스트·리뷰·회수는 만든 것을 기준으로 돌아 이것을 대신하지 않는다 — 옮기는 법·표 = `task-units.md` §3.

- **글자 수**: 지금 15,390 → 새 줄 +340 · 활성 훅 목록 −391(483 → 92) → **15,339자**(상한 15,404 · 여유 65).
- **훅의 요지**: log.md 의 쓰기를 지켜보지 않고, 판정할 때마다 **표의 지금 글자**를 읽는다(어느 도구로 썼든 같다). "닫음"은 타임라인의 자유 글이 아니라 표의 상태 칸 값(`열림` · `닫음`)으로만 읽는다. `닫음` 줄의 빈 칸 → PreToolUse L1 쓰기 차단(메인 · 워커) · `열림` 줄의 빈 칸 → 매 턴 한 줄 알림 · 표지가 있는데 꼴이 틀리면 차단(C2 ②) · 표지가 없으면 검사하지 않음. 자세한 설계 = 명세 6.1 · 볼 수 없는 것 = 명세 6.2.

## 1. `src/core.md`

### 1.1 §4 — 74행 뒤에 0절의 한 줄을 넣는다

```diff
  - **개발 자세**: … (실측 사후 관찰 — `design-taste.md` §6).
+ - **task를 닫기 전 요구 대조(실측 2026-11-27)**: …(0절의 문장 그대로)…
  - **덜 만드는 순서**: …
```

### 1.2 §6 — 110행의 활성 훅 목록을 README 로 옮긴다

```diff
- - **활성 훅**(배포 단일 출처 = 이 repo): `git-guard`(push ask·커밋/gh 발행 attribution 차단) · `codex-scan`(시크릿 backstop) · `gate-guard`(C1·C2·SPEC/MODE 게이트·고정 지시 파일 쓰기 ask·메인의 L1 직접 쓰기에 작업 폴더당 1회 알림 — 차단 아님) · `session-mode-guard` · `reinject-mode` · `task-mode-guard`(spec|log 리셋) · `detect-layer`(관측 전용 — InstructionsLoaded·ConfigChange·SubagentStop → 세션 `.events` 사이드카, 차단 없음) · `capture-decision`(선택 질문·답 → 작업 폴더 `decisions.md`) · `reread-track`(압축 뒤 작업 기록 Read 시각). 테스트: `hooks/tests/run.sh`.
+ - **활성 훅**(배포 단일 출처 = 이 repo): 목록과 하는 일 = README 구조 절의 `hooks/`. 테스트: `hooks/tests/run.sh`.
```

옮김 대조표(`writing/rule-docs.md` 규칙 6 — 옮긴 뒤 위치가 빈 것 0):

| 원래(core 110행) | 옮긴 뒤 위치 | 지금 README 에 있나 |
|---|---|---|
| `git-guard`(push ask · 커밋/gh 발행 attribution 차단) | README 186행 | 있다(규칙 자체는 core §6 git 줄에도) |
| `codex-scan`(시크릿 backstop) | README 187행 | 있다 |
| `gate-guard`(C1 · C2 · SPEC/MODE 게이트) | README 180행 | 있다 |
| `gate-guard` — 고정 지시 파일 쓰기 ask · 메인의 L1 직접 쓰기에 작업 폴더당 1회 알림(차단 아님) | README 180행에 덧붙임(5.1) | **없다 — 더한다** |
| `session-mode-guard` · `reinject-mode` · `task-mode-guard`(spec · log 리셋) | README 183 · 184 · 185행 | 있다 |
| `detect-layer`(관측 전용 · 차단 없음) | README 188행 | 있다 |
| `capture-decision` · `reread-track` | README 189 · 190행 | 있다 |
| 테스트 `hooks/tests/run.sh` | core 에 남긴다 | — |

방어선 점검(core §0.3): 이 목록은 훅의 색인이고 모델이 따를 행동이 아니다. 행동 규칙(push ask · attribution 금지 · 게이트 · 압축 뒤 재독 · decisions.md 를 손대지 않음)은 core §1 · §6 git · §7 에 남는다.

## 2. `playbooks/task-units.md`

80줄(끝의 빈 줄 포함 — 상한 80). 새 줄 하나를 넣고 끝의 빈 줄을 지운다.

```diff
@@ 3행 — 트리거
- > 트리거: 명세서를 쓸 때(9절 task 분해), 그리고 합의 뒤 task를 진행할 때.
+ > 트리거: 명세서를 쓸 때(9절 task 분해), 그리고 합의 뒤 task를 진행할 때(task를 시작할 때와 닫을 때 — §3 요구 대조).

@@ 26행 — §2 의 "결과" 칸
- | 결과 | 한 문장. 끝났을 때 무엇이 참인가(확인할 수 있는 말로) |
+ | 결과 | 한 문장. 끝났을 때 무엇이 참인가(확인할 수 있는 말로). 요구가 계약 문서(규약·설계)의 표나 절에 있으면 그 위치(문서 §·줄)를 함께 적는다 — §3의 요구 대조가 거기서 옮긴다 |

@@ 40행 — §3 의 그림
- task N: 구현 -> 커밋 -> 검증(이 task의 강도대로) -> 지적 가르기 -> 고친 것 커밋   (task마다 되풀이)
+ task N: 요구 옮기기 -> 구현 -> 커밋 -> 검증(이 task의 강도대로) -> 지적 가르기 -> 고친 것 커밋 -> 요구 대조(닫음)   (task마다 되풀이)

@@ 44행 뒤에 한 줄
+ - **요구 대조(core §4 — 실측 2026-11-27: 닫은 task 에 빠진 요구 다섯, 테스트·리뷰·회수가 잡은 것 0)**: task를 시작할 때 명세의 그 task 칸(결과·끝났을 때의 모습)과 거기서 가리키는 계약 문서의 줄을 log의 "요구 대조" 표(꼴 = `templates/log.md` — 표지 줄·머리 줄을 글자 그대로, 훅이 읽는다)에 상태 `열림`으로 옮긴다. 문서는 그 절을 Read로 끝까지 읽고 옮기며, `grep`·`head`·`cut`으로 거른 출력으로 줄을 세지 않는다(실측: `head -8`이 일곱 줄 가운데 둘을 잘랐다). 한 줄에 대상(저장소·파일·표)이 여럿이거나 할 일이 "과"·"그리고"로 이어지면 대상마다 나눠 적고, 옮긴 줄 수와 원문의 줄 수를 함께 적는다. 워커 브리핑의 범위는 이 표의 줄로 적고, 워커는 줄마다 만든 곳을 packet에 적는다. 닫을 때 메인이 줄마다 만든 곳(file:line·커밋)을 채우고 그 task의 줄을 `닫음`으로 바꾼다. 이 task에서 하지 않는 줄은 받는 task 번호를 적고 그 task의 표에도 옮긴다. 명세에 없던 넘김(후보로 내리기, 빼기)은 합의한 것을 바꾸는 것이라 §4의 "멈추고 묻는다"가 앞서고, 사용자의 답과 시각을 적는다. 빈 칸이 있으면 닫지 않는다(`닫음` 줄의 빈 칸은 gate-guard가 L1 쓰기를 막는다 — 표를 고치는 쓰기는 막히지 않는다. 훅이 보는 것과 못 보는 것 = README). 표가 10줄을 넘거나 저장소가 둘 이상이거나 그 task가 높음이면 채운 표를 읽기 전용 Opus 워커(다른 브랜치를 보려면 Bash가 필요해 explorer로는 안 된다)에게 줄마다 코드와 맞춰 보게 하고, 메인은 그 결과의 핵심 한두 줄을 확인해 채택한다(core §2). 리뷰어가 다른 task로 넘긴 줄을 "빠졌다"고 하면 아래 "명세가 다른 task에 배정한 일" 줄대로 기각한다 — 표의 넘긴 곳이 근거다.

@@ 80행 — 끝의 빈 줄을 지운다
-
```

부딪히는 규칙과 앞서는 쪽(`rule-docs.md` 규칙 3):

| 기존 규칙 | 관계 | 앞서는 쪽 |
|---|---|---|
| task-units §3 48행 "명세가 다른 task에 배정한 일 … 기각" | 넘긴 줄도 표에 있다 | 기존 줄 — 새 줄 끝에 적음 |
| task-units §4 "합의한 것을 바꾼다 → 멈추고 묻는다" | 넘김 · 빼기 | §4 — 새 줄에 적음 |
| core §5 "메인 소유 — 게이트 판정" · core §2 "워커 결과 교차 확인 후 채택" | 큰 표의 대조를 워커에게 | 판정은 메인 — 새 줄에 적음 |
| task-units §3 52행 "마지막 확인" | 작업 전체 · 마감 때 | 둘 다 한다 |
| core §4 안전선 ③ · core §5 회수 | 만든 것 기준 · 요구 기준 | 둘 다 — core 새 줄이 "대신하지 않는다" |
| core §1 긴급 수정(스모크만 즉시 · 나머지 빚) | DEBT=1 에서 `닫음` 빈 칸 | 긴급이 앞선다 — 훅은 알림만(명세 0절 기본으로 정한 것) |

## 3. `templates/log.md` — 20행 뒤 · 22행("## 고장 내기") 앞에 절 하나

```diff
  | | | | | |
+
+ ## 요구 대조 (task마다 — core §4 · `playbooks/task-units.md` §3)
+
+ > task를 시작할 때 요구를 상태 `열림`으로 옮기고(원문의 그 절을 Read로 끝까지 — 거른 출력으로 세지 않는다), 닫을 때 넷째 칸을 채우고 상태를 `닫음`으로 바꾼다. **빈 칸이 있으면 그 task를 닫지 않는다.** 대상이 여럿인 줄은 대상마다 한 줄. 하지 않는 줄은 받는 task(그 task의 표에도 옮긴다) 또는 사용자 합의 시각.
+ > 훅이 이 표를 읽는다(gate-guard · reinject-mode): 아래 표지 줄과 머리 줄을 **글자 그대로** 둔다. 상태는 `열림` · `닫음` 둘뿐. 빈 칸 = 비었거나 `-` · `—` · `?` 하나. 칸 안의 `|` 는 `\|` 로. 표지가 있는데 꼴이 틀리면 L1 쓰기가 막힌다 — 표를 고치면 풀린다.
+
+ <!-- req-check:v1 -->
+ | task | 원문 위치 | 요구 | 만든 곳 / 넘긴 곳 | 상태 |
+ |---|---|---|---|---|
+
+ - 옮긴 줄 수 / 원문의 줄 수 (task마다 한 줄 — 예: `T2 — 7 / 7`. 훅은 대조하지 않는다):
+
  ## 고장 내기 (…)
```

(빈 표 — 본문 줄이 0 이면 훅은 "판정함 · 출력 없음"으로 본다. 새 작업 폴더가 이 틀을 복사하면 처음부터 표지가 있다.)

## 4. `templates/requirement-spec.md`

```diff
@@ 98행 — 9절 task 의 "결과"
- - **결과**: 한 문장.
+ - **결과**: 한 문장. 요구가 계약 문서에 있으면 그 위치(문서 §·줄 — 요구 대조가 거기서 옮긴다, `playbooks/task-units.md` §3).
```

## 5. README.md

### 5.1 구조 절 — 훅 줄

```diff
- │   ├── gate-guard.sh          #   L0/L1 판별(C1) + SPEC→MODE 게이트 + lazy per-diff 차단
+ │   ├── gate-guard.sh          #   L0/L1 판별(C1·C2) + SPEC→MODE 게이트 + lazy per-diff 차단 + 고정 지시 파일 쓰기 ask + 메인의 L1 직접 쓰기에 작업 폴더당 1회 알림(차단 아님) + 요구 대조 표의 `닫음` 빈 칸이면 L1 쓰기 차단(메인·워커, 긴급은 알림만)
- │   ├── task-mode-guard.sh     #   새 작업 폴더(spec·log 생성) → SPEC·MODE 리셋 (DEBT 는 유지 — 크로스-태스크 빚)
+ │   ├── task-mode-guard.sh     #   메인의 새 작업 폴더(spec·log Write) → SPEC·MODE 리셋 (DEBT 는 유지 — 크로스-태스크 빚) · 워커(agent_id)의 Write 는 무시 · 요구 대조 사이드카(<sid>.req-check-paths)에 폴더 추가
- │   ├── reinject-mode.sh       #   매 턴 모드·빚(DEBT)·압축 뒤 미독·고정 지시(…) 재주입
+ │   ├── reinject-mode.sh       #   매 턴 모드·빚(DEBT)·압축 뒤 미독·요구 대조의 열린 빈 칸·고정 지시(…) 재주입
```

### 5.2 새 절 — "요구 대조 (v4.10)" (196행 "압축 뒤 재독 …" 절 다음)

```diff
+ ### 요구 대조 (v4.10)
+
+ - 훅은 log.md 의 쓰기를 지켜보지 않고 판정할 때마다 `<!-- req-check:v1 -->` 표지 뒤의 표를 끝까지 읽는다(Bash 로 쓴 log 도 같다). 읽는 폴더 = `TASK_PATH` + `<sid>.req-check-paths`(메인이 Write 로 만든 작업 폴더). `닫음` 줄의 넷째 칸이 비면 PreToolUse L1 쓰기(메인·워커)를 막고, 표지가 있는데 꼴이 틀리면 막는다(C2 ②). `열림` 줄의 빈 칸은 reinject 가 매 턴 한 줄로 알린다. 긴급(DEBT=1)은 알림만. log.md 는 L0 라 표를 고치는 쓰기는 막히지 않는다.
+ - 한계(절차 규칙으로 남는다 — core §0.5): ① 표지·표가 없으면 검사하지 않는다 ② 타임라인에만 "닫음"을 쓰고 표를 `열림`으로 두면 막지 않는다(알림만) ③ 칸이 비었는지만 본다 — 엉뚱한 file:line 은 못 본다 ④ 원문을 잘라 읽어 옮기지 않은 요구는 못 본다 ⑤ Bash·MCP 로 쓴 L1 은 막지 않는다(gate-guard 의 Bash 경로) ⑥ 표지 줄을 지우면 그 폴더의 검사가 꺼진다(log 의 diff 로 남는다 — 환경 변수·set-state 로 끄는 길은 두지 않는다) ⑦ 사이드카에 없는 폴더(워커·Bash 가 만든 작업 폴더)는 보지 않는다.
```

### 5.3 이력 절 — 225행("## 이력") 아래 맨 위

```diff
+ - **v4.10 (2026-11-2x)**: task를 닫기 전 요구 대조 — core §4 새 줄 · `task-units.md` §3 · log 템플릿 "요구 대조" 표(표지·고정 머리 줄·상태 칸) · gate-guard 가 `닫음` 빈 칸에 L1 쓰기 차단 · reinject 가 열린 빈 칸 알림 · task-mode-guard 가 워커의 Write 로 리셋하지 않음 · core §6 활성 훅 목록을 README 로(core 15,390 → 15,339자). 근거: deploy-study-note ⑬ 실측(닫은 task 에 빠진 요구 다섯, 테스트·리뷰·회수가 잡은 것 0) · `docs/plans/2026-11-27/close-out-requirement-check/`
```

## 6. `HISTORY.md` — 41행 뒤에 한 줄

```diff
+ | 2026-11-2x | 메인 <모델> · 구현 · 테스트 · 리뷰 워커 Opus · 둘째 리뷰어 codex | **v4.10 — task를 닫기 전 요구 대조** — core §4 한 줄 · `task-units.md` §3 · log 템플릿 표 · gate-guard 차단 · reinject 알림 · state-lib 표 파서 · task-mode-guard 워커 Write 무시 · core §6 훅 목록을 README 로(15,390 → 15,339자) — `docs/plans/2026-11-27/close-out-requirement-check/` | 실측(deploy-study-note ⑬, 2026-11-27): 닫은 task 에 규약 표의 요구 다섯이 남아 있었고 테스트 · 리뷰 · 고장 내기 · 회수가 잡은 것 0. 같은 날 워커의 Write 가 메인의 게이트를 리셋한 결함(`incident.md` 6절) |
```

## 7. 훅의 변경 (제안 — 지금의 코드 → 바꾼 코드)

### 7.1 `hooks/state-lib.sh` — 386행(`state_reread_unread` 끝) 뒤에 둘

```bash
# ── v4.10 요구 대조(close-out-requirement-check) ─────────────────────────────────────
# 표지 줄 다음의 첫 표 하나. log.md 는 **끝까지** 읽는다(줄 상한 없음 — 절단은 이 방어선이 생긴 사고의 원인).
#   stdout: `VIOLATION\t<task>\t<행>` (상태 닫음 + 넷째 칸 빈 칸) · `OPEN\t<task>\t<빈 칸 수>\t<줄 수>` (열림의 빈 칸)
#   rc 0 = 판정함 · rc 1 = 판정 불가(stdout = 까닭 한 줄) · rc 2 = 표지 없음 · 파일 없음(검사 대상 아님)
REQCHECK_MARKER='<!-- req-check:v1 -->'
REQCHECK_HEADER='| task | 원문 위치 | 요구 | 만든 곳 / 넘긴 곳 | 상태 |'
state_reqcheck_scan() { # <log.md>
  local f="${1:-}" out rc=0
  [ -n "$f" ] || return 2
  if [ ! -e "$f" ] && [ ! -L "$f" ]; then return 2; fi
  { [ -f "$f" ] && [ ! -L "$f" ] && [ -r "$f" ]; } || { printf '%s\n' "log.md 를 읽을 수 없음(심링크·비정규·권한): $f"; return 1; }
  grep -qF -- "$REQCHECK_MARKER" "$f" || { rc=$?; [ "$rc" = 1 ] && return 2; printf '%s\n' "log.md 읽기 실패: $f"; return 1; }
  out=$(_RC_M="$REQCHECK_MARKER" _RC_H="$REQCHECK_HEADER" awk '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    function blank(s) { s = trim(s); return (s == "" || s == "-" || s == "—" || s == "?") }
    function die(m)  { print m " (" NR "행)"; bad = 1; exit }
    st == 0 { if (trim($0) == ENVIRON["_RC_M"]) st = 1; next }
    st == 1 { if (trim($0) == "") next; if (trim($0) != ENVIRON["_RC_H"]) die("머리 줄이 꼴과 다름"); st = 2; next }
    st == 2 { if (trim($0) !~ /^\|[ :-]+\|[ :-]+\|[ :-]+\|[ :-]+\|[ :-]+\|$/) die("구분 줄이 꼴과 다름"); st = 3; next }
    st == 3 { line = trim($0); if (substr(line, 1, 1) != "|") { st = 4; next }
              gsub(/\\\|/, "\001", line)                       # 칸 안의 \| 는 경계가 아니다
              if (substr(line, length(line)) != "|") die("줄이 | 로 끝나지 않음")
              n = split(substr(line, 2, length(line) - 2), c, "|")
              if (n != 5) die("칸 수가 5가 아님")
              t = trim(c[1]); s = trim(c[5])
              if (t == "") die("task 칸이 빔")
              if (s != "열림" && s != "닫음") die("상태가 열림·닫음이 아님: " s)
              if (!(t in total)) order[++k] = t
              total[t]++
              if (blank(c[4])) { if (s == "닫음") viol[++v] = t "\t" NR; else open_n[t]++ }
              next }
    END { if (bad) exit 1
          if (st < 3) { print "표지 뒤에 표가 없음"; exit 1 }
          for (i = 1; i <= v; i++) print "VIOLATION\t" viol[i]
          for (i = 1; i <= k; i++) if (open_n[order[i]] > 0) print "OPEN\t" order[i] "\t" open_n[order[i]] "\t" total[order[i]] }
  ' "$f") || { printf '%s\n' "${out:-awk 실패: $f}"; return 1; }
  [ -z "$out" ] || printf '%s\n' "$out"
  return 0
}

# 읽을 log.md 목록 — TASK_PATH + <sid>.req-check-paths(메인이 Write 로 만든 작업 폴더). 중복 없음 · 차례 보존.
#   사이드카가 심링크·비정규·읽기 불가면 rc 1(stdout = 그 경로) — 호출부는 판정 불가로 다룬다.
state_reqcheck_paths() { # <state_dir> <sid> <task_path>
  local dir="${1:-}" sid="${2:-}" tp="${3:-}" sc
  sc="$dir/$sid.req-check-paths"
  if [ -e "$sc" ] || [ -L "$sc" ]; then
    { [ -f "$sc" ] && [ ! -L "$sc" ] && [ -r "$sc" ]; } || { printf '%s\n' "$sc"; return 1; }
  fi
  { [ -n "$tp" ] && printf '%s\n' "$tp"; [ -f "$sc" ] && cat -- "$sc"; } | awk 'NF && !seen[$0]++ { print $0 "/log.md" }'
}
```

[구현 검증] 표시해 둘 것: ① 훅이 도는 awk 가 mawk 인지 gawk 인지 — 위 코드는 `{n}` 반복을 쓰지 않았고 `ENVIRON` · `split` · `gsub` 만 쓴다 ② C 로캘에서 `—`(3바이트) · 한글 상태 값의 비교가 바이트 비교로 맞는지 ③ `exit` 뒤 `END` 가 도는 awk 의 성질(POSIX)에 기댄다.

### 7.2 `hooks/gate-guard.sh`

① 372행(`reread_gate` 끝) 뒤에 함수 하나:

```bash
# 요구 대조 차단(v4.10 — 명세 6.1): 지금 글자를 읽는다 — 쓰기를 지켜보지 않는다(Bash 로 쓴 log 도 같다).
#   PreToolUse 의 L1 쓰기만(이 함수에 닿은 것 = L0 · 상태파일 · SPEC/MODE 차단을 이미 통과). 메인 · 워커 구분 없음(내용 판정).
#   VIOLATION 또는 판정 불가(C2 ②) → exit 2. DEBT=1(긴급) → 막지 않고 additionalContext 한 덩어리(worker_notice 는
#   DEBT=1 에서 내지 않으므로 stdout JSON 이 겹치지 않는다). 표지 없음 · 위반 없음 → return 0(종전 흐름 · 출력 바이트 동일).
req_check_gate() {
  local lf out rc paths prc=0 report="" debt
  [ "$EVENT" = "PreToolUse" ] || return 0
  paths=$(state_reqcheck_paths "$(dirname -- "$STATE")" "$SESSION_ID" "$(state_get "$STATE" TASK_PATH)") || prc=$?
  if [ "$prc" != 0 ]; then   # 사이드카를 못 읽으면 판정 불가로 알리고 TASK_PATH 하나만이라도 읽는다
    report+="  판정 불가 — 요구 대조 사이드카를 읽을 수 없음: $paths"$'\n'
    paths=$(state_get "$STATE" TASK_PATH); [ -z "$paths" ] || paths="$paths/log.md"
  fi
  while IFS= read -r lf; do
    [ -n "$lf" ] || continue
    rc=0; out=$(state_reqcheck_scan "$lf") || rc=$?
    case "$rc" in
      2) ;;
      1) report+="  판정 불가 — $lf: $out"$'\n' ;;
      0) out=$(printf '%s\n' "$out" | awk -F'\t' -v f="$lf" '$1 == "VIOLATION" { printf "  %s — %s %s행: 닫음인데 만든 곳/넘긴 곳이 빔\n", $2, f, $3 }')
         [ -z "$out" ] || report+="$out"$'\n' ;;
    esac
  done <<< "$paths"
  [ -n "$report" ] || return 0
  debt=$(state_get "$STATE" DEBT)
  if [ "$debt" = "1" ]; then
    jq -cn --arg c "[gate-guard] 요구 대조(긴급 — 막지 않음): ${report} — 빈 칸은 log '생략한 검증'에 빚으로 적는다." \
      '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$c}}' 2>/dev/null || true
    return 0
  fi
  {
    echo "[gate-guard] 요구 대조 — 닫았다고 표시한 task 의 줄에 빈 칸이 있다(또는 표를 읽을 수 없다). L1 쓰기를 막는다:"
    printf '%s' "$report"
    echo "푸는 길: 그 줄의 '만든 곳 / 넘긴 곳'을 채우거나(넘기면 받는 task·합의 시각), 아직 닫지 않았으면 상태를 열림으로 되돌린다. log.md 쓰기는 막히지 않는다. (core §4 · task-units.md §3)"
  } >&2
  exit 2
}
```


② 부르는 자리 — 514~519행(auto), 528~535행(lazy Pre):

```diff
  if [ "$MODE" = "auto" ]; then
+   req_check_gate
    reread_gate
    worker_notice || true
    exit 0
  fi
@@
    if [ "$EVENT" = "PreToolUse" ]; then
+     req_check_gate
      if [ "$PENDING" = "1" ]; then
```

자리를 이렇게 둔 까닭: L0(319~321행) · 상태파일(291~300행) · 고정 지시 ask(306~314행) · SPEC(485~498행) · MODE(501~512행) 판정이 모두 앞서 끝나므로 표를 고치는 쓰기와 합의 전 단계는 이 검사를 만나지 않는다. Bash(210~237행)는 종전대로 검사하지 않는다(한계 — 명세 6.2).

### 7.3 `hooks/reinject-mode.sh` — 79행(압축 뒤 미독 단락 끝) 뒤에

```bash
# 요구 대조 알림(v4.10) — 위반 · 열린 빈 칸 · 판정 불가를 한 줄씩. 표가 없으면 출력 없음(종전과 바이트 동일).
RC_PATHS=$(state_reqcheck_paths "$(dirname -- "$STATE")" "$SESSION_ID" "$(state_get "$STATE" TASK_PATH)") || RC_PATHS=$(state_get "$STATE" TASK_PATH)/log.md
RC_OPEN=""; RC_VIOL=""; RC_BAD=""
while IFS= read -r rc_lf; do
  [ -n "$rc_lf" ] || continue
  rc_rc=0; rc_out=$(state_reqcheck_scan "$rc_lf") || rc_rc=$?
  case "$rc_rc" in
    1) RC_BAD+="${RC_BAD:+ · }$rc_out" ;;
    0) rc_v=$(printf '%s\n' "$rc_out" | awk -F'\t' '$1=="VIOLATION"{printf "%s%s(%s행)", (n++?" · ":""), $2, $3}')
       rc_o=$(printf '%s\n' "$rc_out" | awk -F'\t' '$1=="OPEN"{printf "%s%s %s/%s", (n++?" · ":""), $2, $3, $4}')
       [ -z "$rc_v" ] || RC_VIOL+="${RC_VIOL:+ · }$rc_v"
       [ -z "$rc_o" ] || RC_OPEN+="${RC_OPEN:+ · }$rc_o" ;;
  esac
done <<< "$RC_PATHS"
[ -z "$RC_VIOL" ] || echo "[요구 대조] 닫음인데 빈 칸 — $RC_VIOL (L1 쓰기가 막힌다 — 표를 채우거나 열림으로)"
[ -z "$RC_OPEN" ] || echo "[요구 대조] 열린 빈 칸 — $(printf '%s' "$RC_OPEN" | awk -F' · ' '{for(i=1;i<=NF&&i<=5;i++)printf "%s%s",(i>1?" · ":""),$i; if(NF>5)printf " 외 %d",NF-5}')"
[ -z "$RC_BAD" ] || echo "[요구 대조] 표 판정 불가 — $RC_BAD"
```

### 7.4 `hooks/task-mode-guard.sh`

① 덤(Q8 (가)) — 36행 뒤:

```diff
  [ "$TOOL_NAME" = "Write" ] || exit 0
+ # 워커(서브에이전트)의 Write 는 메인의 게이트를 바꾸지 않는다(실측 2026-11-27 — 워커가 작업 폴더 문서를 Write 하자
+ #   메인 세션의 SPEC·MODE 가 리셋됐다). 기준은 gate-guard reread_gate·worker_notice 와 같다: agent_id 가 비어 있지 않은
+ #   문자열이면 워커. 판별 불가(jq 실패)면 종전대로(메인으로 본다 — 리셋이 빠지는 것이 게이트 우회라 더 나쁘다).
+ AGENT_ID=$(echo "$HOOK_INPUT" | jq -r '.agent_id // empty' 2>/dev/null || true)
+ [ -z "$AGENT_ID" ] || exit 0
```

② Q7 (나) — 사이드카 목록. 70~74행(같은 폴더면 exit) **앞**에, 같은 폴더 재진입에서도 한 번은 목록에 오르게:

```diff
+ # 요구 대조가 읽을 작업 폴더 목록(v4.10) — 메인이 Write 로 만든 작업 폴더를 <sid>.req-check-paths 에 한 줄씩(중복 없음).
+ #   잠금·임시 파일·mv 는 gate-guard worker_notice 의 사이드카 관례 그대로(심링크·비정규면 쓰지 않는다). 실패는 경고 한 줄 + 통과
+ #   (이 훅은 비차단) — 목록에 빠진 폴더는 TASK_PATH 일 때만 읽힌다(README 한계 ⑦).
+ req_check_remember "$(dirname -- "$STATE")" "$SESSION_ID" "$CFP" || echo "[task-mode-guard] 경고: 요구 대조 폴더 목록 기록 실패 — $CFP" >&2
  PREV_TASK=$(state_get "$STATE" TASK_PATH)
```

(`req_check_remember` 는 state-lib 에 두는 작은 함수 — worker_notice 의 잠금 단락을 함수로 빼서 함께 쓸지는 구현 때 `build-less.md` §1 로 정한다.)

### 7.5 테스트의 사례 (`hooks/tests/cases/req-check.sh` 새 파일 · task-mode-guard 셋은 `misc-guards.sh` 에 · 끝에 `run.sh --lock`)

파서(`state_reqcheck_scan` — state-lib 을 직접 source):

| id | 입력 | 기대 |
|---|---|---|
| P1 | 표지 없는 log | rc 2 · 출력 없음 |
| P2 | 표지 + 모든 줄 채움(열림 · 닫음 섞음) | rc 0 · 출력 없음 |
| P3 | 열림 줄 둘 중 하나 빈 칸 | `OPEN T4 1 2` |
| P4 | 닫음 줄의 넷째 칸 빈 칸 | `VIOLATION T4 <행>` |
| P5 | 넷째 칸이 공백 · `-` · `—` · `?` / `x` | 앞의 넷은 빈 칸, `x` 는 채움 |
| P6 | 셋째 칸에 `a \| b` | 칸 수 5 로 판정(판정 불가 아님) |
| P7 | 머리 줄의 칸 이름 하나가 다름 | rc 1 · 까닭에 행 번호 |
| P8 | 상태 `닫힘` | rc 1 · 까닭에 값 |
| P9 | 칸 수 4 | rc 1 |
| P10 | 표지 뒤에 표 없음 | rc 1 |
| P11 | 200KB 의 앞 내용 뒤에 표(빈 칸 닫음) | VIOLATION — 끝까지 읽는다 |
| P12 | log.md 가 심링크 / 없음 | rc 1 / rc 2 |
| P13 | 표 뒤 빈 줄 다음의 다른 표(고장 내기 표) | 읽지 않는다 |
| P14 | 빈 표(본문 0줄 — 템플릿 그대로) | rc 0 · 출력 없음 |

gate-guard:

| id | 상태 · 입력 | 기대 |
|---|---|---|
| G1 | auto · SPEC=1 · 메인 · L1 Write · 위반 | exit 2 · stderr 에 task · 행 · 푸는 길 |
| G2 | G1 과 같고 `agent_id` 있음(워커) | exit 2 |
| G3 | G1 과 같고 대상이 `docs/plans/…/log.md`(L0) | exit 0 · 출력 없음 |
| G4 | G1 과 같고 PostToolUse | exit 0 |
| G5 | 판정 불가(머리 줄 틀림) | exit 2 · 까닭 |
| G6 | 표지 없음 | exit 0 · stdout · stderr 가 종전 판과 바이트까지 같다 |
| G7 | DEBT=1 · 위반 | exit 0 · stdout 에 additionalContext JSON 한 덩어리 |
| G8 | lazy · PENDING=0 · 위반 / lazy · PENDING=1 · 위반 | 둘 다 exit 2 · 둘째는 요구 대조 메시지가 먼저 |
| G9 | SPEC=0 · 위반 | 종전 SPEC 메시지 그대로(요구 대조 검사 전) |
| G10 | Bash 명령(위반 상태) | exit 0 — 한계를 고정하는 테스트 |
| G11 | 사이드카 목록의 둘째 폴더에 위반 · TASK_PATH 는 깨끗 | exit 2 |
| G12 | 사이드카가 심링크 | exit 2(판정 불가) |

reinject-mode:

| id | 입력 | 기대 |
|---|---|---|
| R1 | 열린 빈 칸 T4 7/13 · T5 1/9 | `[요구 대조] 열린 빈 칸 — T4 7/13 · T5 1/9` 한 줄 |
| R2 | 빈 칸 있는 task 여섯 | 다섯 + ` 외 1` |
| R3 | 표지 없음 | 종전 출력과 바이트까지 같다(고정 지시 trap 포함) |
| R4 | 판정 불가 | `[요구 대조] 표 판정 불가 — …` 한 줄 |

task-mode-guard:

| id | 입력 | 기대 |
|---|---|---|
| M1 | `agent_id` 있음 · 새 폴더 log.md Write | SPEC · MODE · TASK_PATH 그대로 · 리셋 메시지 없음 · 사이드카 그대로 |
| M2 | `agent_id` 없음 | 종전 리셋(회귀) · 사이드카에 한 줄 |
| M3 | `agent_id` 가 `""` · `null` | 메인으로 보고 리셋 |
| S1 | 메인이 같은 폴더를 두 번 Write | 사이드카에 한 줄 |

고장 내기(log "고장 내기" 표에): `blank()` 가 `-` 를 채움으로 보게 · `st==1` 의 머리 줄 비교를 지움 · `awk` 앞에 `head -c 65536` 을 끼움 · task-mode-guard 의 `[ -z "$AGENT_ID" ] || exit 0` 을 지움 — 각각 P5 · P7 · P11 · M1 이 실패해야 한다.

## 8. 하네스 `docs/plans/NEXT.md` 후보 — 덤 결함 (Q8 이 (나)일 때만 · (가)면 task 05 로 이번에 한다)

```diff
+ ### N-req. task-mode-guard 가 워커의 Write 로 메인의 게이트를 리셋한다 — 우선순위: 높음 · 관측 신호: 2026-11-27 실측(close-out-requirement-check `incident.md` 6절)
+
+ - 워커가 `docs/plans/*/requirement-spec.md`·`log.md` 를 Write 하면 메인 세션의 SPEC·MODE 가 리셋되고 TASK_PATH 가 그 폴더로 바뀐다 — 메인의 합의된 작업이 사용자 모르게 풀림(11-27 15:45 확인 · 15:48 사용자 확인 뒤 set-state 로 복구).
+ - 자리: `hooks/task-mode-guard.sh:35-36`(agent_id 를 보지 않음) → `:70-80`(리셋). 같은 저장소의 `reread-track.sh:7` · `gate-guard.sh:363,405` 는 agent_id 로 가른다.
+ - 방안: agent_id 가 비어 있지 않으면 exit 0(몇 줄) + 테스트 셋(워커 Write 무시 · 메인 회귀 · 빈 값/null 은 메인). 확인할 것: 서브에이전트의 PostToolUse(Write) 입력에 agent_id 가 실제로 실리는지(실제 세션 stdin).
+ - 그때까지의 회피: 작업 폴더의 명세·log 는 메인이 Write 한다(core §5 "log 단일 writer").
```

## 9. 이 방어선이 오늘의 다섯 건을 잡았을까 (훅 포함)

전제: 메인이 표를 만들었다(표 만들기는 절차 규칙 — 훅은 표 없는 폴더를 보지 못한다).

| # | 잡나 | 절차 규칙 | 훅이 더하는 것 |
|---|---|---|---|
| 1 T4 앱 여섯 | **잡는다** | §7.1 의 T4 세 줄을 대상마다 나누면 13줄 — 브리핑이 nginx 여섯이면 7줄이 비고 닫을 수 없다 | 메인이 T4 줄을 `닫음`으로 바꾸면 그 순간부터 다음 L1 쓰기(T6 의 워커 쓰기 포함)가 막힌다. `열림`으로 둔 채 타임라인에만 "닫음"을 쓰면 30시간 동안 매 턴 `T4 7/13` 이 보인다(막지는 않는다) |
| 2 T4 ci-cd | **잡는다** | 같은 표 · T5 착수의 "T5b" 넘김은 §4 로 사용자에게 묻는다 | 1 과 같음 |
| 3 T5 15칸 | **간접으로** | 2 가 먼저 잡히면 15칸 줄을 쓰는 쪽이 T5 보다 먼저 생긴다(해석). 단독으로는 표의 줄에 없는 요구(본문 §3.4 · §4.2)라 파서 결함 자체는 드러나지 않는다 | 없음 — 표에 없는 요구는 훅도 못 본다 |
| 4 T2 admin | **절차 규칙을 지킬 때만** | "Read 로 끝까지 · 거른 출력으로 세지 않는다" — 지키면 일곱 줄 · admin 빈 칸 · "여섯 닫음"에서 막힌다 | 옮겨지지 않은 줄은 못 본다(명세 6.2). 옮겼다면 admin 줄의 `닫음` 빈 칸 → 차단 |
| 5 T8 stream | **줄을 나눌 때** | 482행을 대상마다 나누면 3.6 의 줄이 T5 로 넘어가 T5 의 표에 든다 | 넘긴 줄이 T5 표에서 `닫음` 빈 칸이면 차단 · `열림` 이면 알림. 한 줄로 두고 `nginx.conf:83` 으로 채우면 훅도 못 잡는다(칸이 찼다) |

다섯 가운데 넷(1 · 2 · 4 · 5)은 직접, 하나(3)는 간접. **훅이 바꾸는 것은 1 · 2 · 5 의 "닫았다고 표시한 뒤 계속 나아가는 것"을 결정론적으로 멈추게 하는 것**이고, 4 의 원인(잘린 읽기)과 3(표 밖 요구)은 훅이 볼 수 없다.

## 10. 규칙 문서를 쓰는 법과의 점검

| 규칙(`writing/rule-docs.md`) | 이 제안 |
|---|---|
| 1 행동 꼴 · 남길 것 | "옮긴다 · 채운다 · 닫음으로 바꾼다 · 닫지 않는다" · 남길 것 = log 의 "요구 대조" 표 · 줄 수 한 줄 |
| 2 판단의 근거 | 워커 대조 조건(10줄 · 저장소 둘 · 높음) · 빈 칸의 정의(글자 목록) |
| 3 부딪히는 규칙 | 2절의 표(긴급 줄 포함) |
| 4 한 곳 | 표의 꼴 = log 템플릿 · 쓰는 법 = `task-units.md` §3 · 훅이 보는 것과 한계 = README 5.2 · core 는 요지와 가리킴 |
| 5 읽기 시험 | 명세 5절 |
| 6 옮김 대조표 | 1.2 의 표 |
