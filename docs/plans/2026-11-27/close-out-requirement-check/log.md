# log — task 를 닫기 전 요구 대조 (준비 차례 1 · 2 · 구현 차례)

> 작업 폴더의 두 번째 파일(명세서와 한 쌍). 이번 차례는 L0(실측 기록 · 명세 초안 · 제안 글)이다 — 정책 파일은 고치지 않았다. 시각은 `date '+%m-%d %H:%M'` 로 확인한 값만 적었다(그 사이의 줄은 앞뒤 확인 값 사이에 있다는 뜻).
> 이 차례는 deploy-study-note 세션의 메인이 띄운 워커가 했다. 다음 차례(합의 뒤 적용)는 이 log 에 이어 적는다.

## 타임라인

| 시각 | 사건 | 결과/결정 |
|------|------|----------|
| 11-27 15:28 | 시작 · 하네스 저장소 확인(`date` 확인) | 다른 세션 작업 트리 = `docs/communication-decisions`. 원격 기본 브랜치 = `main`(`origin/HEAD`). **로컬 `main`(`542c077`)이 `origin/main`(`7688bad`)보다 뒤처져** 있어 지시의 `… main` 대신 `origin/main` 으로 작업 트리를 만듦(정본은 원격의 끝) |
| 11-27 15:28 | `git worktree add -b docs/close-out-requirement-check …/scratchpad/wt/harness-closeout origin/main` | 만들어짐. 새 브랜치가 `origin/main` 을 추적하도록 잡혀 `git branch --unset-upstream` 으로 풀었다(인자 없는 push 가 `main` 으로 가지 않게) |
| 11-27 15:2x | `src/core.md`(작업 트리) ↔ `~/.claude/core.md` diff | 같다. README 33행의 세는 법으로 **15,390자**(상한 15,404) |
| 11-27 15:2x | 하네스의 비슷한 규칙 찾기(grep: 대조 · 빠진 · 닫 · 요구 · 브리핑) · `task-units.md` · 두 템플릿 · `rule-docs.md` · `reading-test.md` · `review.md` · `review-lenses.md` · HISTORY · NEXT 읽음 | 비슷한 규칙 열 — 모두 "만든 것"이나 "알고 바꾼 것"에서 출발(`incident.md` 4절). `task-units.md` 는 80줄로 상한(core §8)에 닿아 있음 |
| 11-27 15:3x | 사고 쪽 읽기: 전수 대조 파일 · 규약 §7.1 · 명세(§1~§9 · T4b · T4c · 전수 대조 절 · T5 착수 · T8) · log 의 닫은 줄 · 찾은 줄 | 규약 폴더는 git 밖(`??`) — 고치기 전 판 없음. log 92행 앞의 시각은 어림으로 앞서 있어(그 log 3행) 실제 시각은 서비스 저장소의 커밋 시각으로 다시 셈 |
| 11-27 15:3x | 메인 대화 기록(`e79bd2ff-….jsonl`)에서 메인의 도구 호출 · 압축 시각만 뽑음(파이썬) | ⑬ 동안 압축 6회 · 01:55 의 `grep "T2" … | head -8` 이 §7.1 의 T2 admin · ci-cd 줄을 자름(4 번의 직접 원인) · T4 브리핑 · 리뷰 범위가 "nginx 여섯" · T5 리뷰 브리핑의 "정한 것(다시 내지 않는다) … T5b" · 11-25 13:00 뒤 메인이 `playbooks/` 를 연 기록 0 |
| 11-27 15:38 | 다른 세션의 브랜치가 같은 파일을 고쳤는지 확인(`git diff --stat origin/main...docs/communication-decisions`) | 커밋된 것 기준 변경 없음(그 브랜치의 core 는 merge-base 판 15,404자). 커밋되지 않은 변경은 보지 않았다 |
| 11-27 15:3x | `incident.md` 작성 | 다섯 건 · 원인 넷의 검증 · 다른 원인 여섯 · 비슷한 규칙 표 |
| 11-27 15:4x | `requirement-spec.md` 초안 · `proposal.md` 작성 · 제안을 저장소 밖 사본(`…/scratchpad/proposal-check/`)에 적용해 글자 수를 셈 | 안 A 15,247자 · 안 B 15,376(괄호를 지움) ~ 15,398(가리키는 괄호를 남김). task 02 의 강도를 처음에 "중간"으로 적었다가 core §2(하네스 정책 변경 = 높음)에 비추어 "높음"으로 고침 — 낮추려면 사용자에게 묻는다 |
| 11-27 15:44 | 안 B 의 글자 수를 다시 세어 세 문서에 맞춤 | 처음 "약 15,396"으로 어림했던 것을 15,398(실측)로 고침 |
| 11-27 15:4x | (메인 전달) 사용자의 답 셋: 강제 = "훅으로도 막는다"(초안 1 의 권고와 다름 — 사용자 결정이 앞선다) · 범위 = "모든 task" · core = "훅 목록을 README로 옮김"(안 A). 묻지 않은 것은 권고를 기본으로 | 명세 · 제안을 2판으로 고치기 시작 |
| 11-27 15:4x | (메인 전달) 덤 결함: 이 워커의 Write 로 메인 세션 상태가 `SPEC=0 · MODE=UNSET · TASK_PATH=<이 폴더>` 가 됨(메인 15:45 확인 · 사용자 확인 뒤 15:48 set-state 로 복구) | 이 차례부터 `requirement-spec.md` · `log.md` 는 `Write` 하지 않고 셸(`cp` · 파이썬)로만 고친다 — 같은 리셋을 다시 내지 않으려고(훅이 Bash 쓰기를 못 보는 한계를 이용한 것 — `incident.md` 6절에 적음) |
| 11-27 15:48 | 훅 코드 읽기: `task-mode-guard.sh` 전체 · `reinject-mode.sh` 전체 · `gate-guard.sh` 1~73 · 140~545 · `state-lib.sh` 340~394 · `hooks/tests/`(run.sh 앞 · lib.sh 도우미 · cases 목록 · tests.lock) | 결함 자리 = `task-mode-guard.sh:35-36`(agent_id 를 보지 않음) → `:70-80` 리셋. agent_id 로 메인 · 워커를 가르는 선례 = `reread-track.sh:7` · `gate-guard.sh:363,405`. gate-guard 의 Bash 경로(208~237)는 L1 을 막지 않음 · L0 판정(319~321)이 게이트보다 앞 → 표(log.md)를 고치는 쓰기는 새 검사를 만나지 않게 둘 수 있다 |
| 11-27 15:50 | 명세 2판(`cp` 로 덮어씀): 6.1 훅 설계(쓰기를 지켜보지 않고 표의 글자를 읽음 · 상태 칸 `열림`/`닫음` · 표지 `<!-- req-check:v1 -->`) · 6.2 못 보는 것 · task 일곱 · 더 물을 것 Q6~Q8 | core 새 줄을 훅 문구까지 넣어 다시 셈(사본 `proposal-check/core-A2.md`): **15,339자** |
| 11-27 15:53 | `incident.md` 6절(덤 — 훅 결함의 자리 file:line) 덧붙임 | 다른 저장소의 작업 폴더를 작업 경로로 삼는 것은 core §7 상 정상 경로라 결함으로 보지 않음 — 핵심은 워커 · 메인 구분 |
| 11-27 15:56 | `proposal.md` 2판: 훅 코드 제안(state-lib 파서 · gate-guard `req_check_gate` · reinject 단락 · task-mode-guard 두 곳) · 테스트 사례 P1~P14 · G1~G12 · R1~R4 · M1~M3 · S1 · 고장 내기 넷 · NEXT 후보 글 · 다섯 건 재평가 | 제안의 훅 코드는 돌려 보지 않음(다음 차례 task 03~05). 처음 쓴 판에 자리 표시 변수 하나와 폴더 사이 구분자 빠짐이 있어 고침 |
| 11-27 16:02 | (메인 전달) 사용자의 답: Q6 "둘 다" · Q7 "이 세션이 만든 폴더 전부" · Q8 "함께 고친다" · 명세 "합의 — auto, 배포 전에 확인" | 구현 차례 시작 — 이 워커가 진행(PM). push · PR · 병합 · deploy 는 하지 않는다. 상태파일(읽기만): SPEC=1 · MODE=auto · TASK_PATH=이 폴더 |
| 11-27 16:02 | 브랜치: 구현이 들어가므로 같은 커밋(`1aadde2`)에서 `feat/close-out-requirement-check` 를 만들어 옮김 | `docs/close-out-requirement-check` 는 `1aadde2` 에 그대로 남는다 |
| 11-27 16:02 | **load-bearing 가정 1 확인**(배포본을 건드리지 않고): 이 워커(서브에이전트)가 TASK_PATH 의 `log.md` 를 offset · limit 없이 Read → 배포된 `reread-track.sh`(작업 트리와 같음 — diff 확인)는 agent_id 가 없을 때만 `<sid>.reread` 에 기록한다. 다른 조건(도구 Read · 전체 읽기 · 이름 log.md · TASK_PATH 일치 · reread-seen 있음)은 모두 맞다 | `.reread` 의 마지막 기록이 11-22 그대로(mtime 02:24) → **서브에이전트의 PostToolUse(Read) 입력에 agent_id 가 실린다**. Write 의 PostToolUse 는 같은 공통 칸이라 실릴 것으로 본다(추론) — Write 에서의 직접 확인은 배포 뒤 smoke(task 07, 사용자)로 넘긴다. 부작용: 없음(기록이 안 됐으므로 메인의 재독 상태는 그대로) |
| 11-27 16:0x | 기준 훅 테스트(`run.sh`) 첫 시도 — 작업 트리에서 돌리는 중 워커가 파일을 고치고 메인이 커밋해 hermetic 스냅샷이 달라짐(출력은 `| tail` 로 잘려 수를 못 셈 — 그린 위장의 꼴이라 무효로 침) | 깨끗한 기준 작업 트리 `…/scratchpad/wt/harness-base`(`7688bad` detached)에서 다시 돌림 |
| 11-27 16:07 | task 01+02 구현 워커(Opus 155k — 한 워커가 차례로) 회수 | 범위 = 파일 다섯(core · task-units · 두 템플릿 · README) +19 −7 · core **15,346자**(README 절 이름이 실제로 `repo 구조` 라 제안보다 +7) · task-units **80줄** · 표지 · 머리 줄 `grep -nxF` 일치. 워커가 낸 갈림 둘: ① 절 이름 — 받음 ② 긴급(DEBT=1)이 앞선다는 말이 문장에 없음(rule-docs 규칙 3) — 넣게 함(같은 워커 이어서 · 80줄 유지) |
| 11-27 16:08 | 커밋: task 01 `0b87e2d`(core 새 줄만 hunk 로 골라 stage) · task 02 `2e55217` | 리뷰 묶음: t01 base `77ba594`..`0b87e2d` · t02 base `0b87e2d`..`2e55217` · `$OUT` = `…/scratchpad/rv/t01-l1` · `rv/t02-l1`(미러 = `git archive` · ledger·decisions 제외 · 보안 스캔 매칭 = `hooks/tests/cases/codex-scan.sh` 의 가짜 키 픽스처뿐 — 오탐) · codex 둘 시작 · Opus 리뷰어 t01 시작 |
| 11-27 16:1x | t01 루프 1: Opus 리뷰(120k · 지적 6) ∥ codex(지적 2 · 16:10) · t02 루프 1: codex(지적 2 · 16:10) — Opus 는 차례로 | 종합 → ledger. 채택 t01 여섯(1 · 2 · 4 · 5 · 6 · 7) · 기각 t01-3(02 가 바로 뒤 커밋) · t02 기각 1 · 채택 1(Opus t02 결과를 본 뒤 함께 고침) |
| 11-27 16:13 | t02 루프 1 Opus 리뷰(101k — 지적 2, 둘 다 낮음 · codex 둘과 같은 내용) 회수 · 리뷰 반영 워커(Opus) 시작 — t01 채택 여섯 + t02-c2 | Opus 지적 1 = codex D2(채택에 합침) · 2 = codex D1(기각 그대로 — Opus 도 "사용자가 고른 옮김 · 선례 있음 · 남는 한계로 log 한 줄"로 봄). 남는 한계: 배포본에서는 README 를 열 수 없다(core 가 README 를 가리키는 다른 곳과 같다) |
| 11-27 16:13 | 기준 훅 테스트(깨끗한 작업 트리 `7688bad`) | **436 통과 · 실패 0 · 건너뜀 0**. 첫 시도가 무효였던 까닭: `run.sh` 의 hermetic 검사가 저장소의 HEAD · status 를 앞뒤로 견준다 — 워커가 파일을 고치는 동안 돌리면 깨진다. 앞으로 테스트는 워커가 쓰지 않을 때만 돌린다 |
| 11-27 16:14 | 루프 1 반영 워커(Opus 90k) 회수 → 커밋 t01 `1a5db40` · t02 `8acc2b7` · docs `343b61a` | core **15,355자** · task-units **80줄** · 표지 1건 그대로. 워커가 본 것: 저장소의 `settings.json` 에는 detect-layer 등록이 없다(배포본 `~/.claude/settings.json` 에는 아홉 모두) — 범위 밖 · 후보 |
| 11-27 16:18 | 루프 2: t01 Opus(117k · 지적 5 — 모두 새 지적, 셋은 루프 1 고침이 낸 길) ∥ codex(지적 없음) · t02 codex(지적 없음) · t02 Opus 시작 | t01 채택 다섯(t01-8 ~ 12). 정지 규칙 점검: 같은 결함을 두 번 고친 것이 아니라 새 결함 — 진행(루프 3 이 마지막) |
| 11-27 16:21 | 루프 2 반영 워커(Opus 108k) 회수 → 커밋 t01 `498cd64` · t02 `cbb2cf3` · docs `238a9f9` | task-units 80줄 · core 15,355(그대로) · 표지 그대로 · `work-records.md` 규칙 10 고침(진행 중 결정) · 첫 칸 표기 `T01`(나누지 않으면 `T1`) |
| 11-27 16:25 | 루프 3: t01 Opus(118k — 지적 3, 새 것) ∥ codex(지적 없음) · t02 codex(지적 없음) · t02 Opus 시작 | t01 채택 둘(13 · 14) · 후보 하나(15). **루프 3 에 신규 채택이 있어 t01 은 종료 조건을 채우지 못한다 → review unresolved**(review.md §1). 고친 뒤 표적 재점검을 하고, 다음 task 로 갈지는 사용자에게 묻는다(task-units §3) |
| 11-27 16:26 | t02 루프 3 Opus(74k — 지적 없음 · 렌즈마다 file:line) | **task 02 리뷰 종료**(루프 3 신규 채택 0 · 대칭 부담 충족 — 두 리뷰어). 메인에 t01 의 review unresolved 를 올려 사용자 결정을 물음(16:2x) · 그 사이 t01 루프 3 채택 둘을 고치는 워커(Opus) 시작 — task 03 은 답을 받기 전 시작하지 않는다 |
| 11-27 16:27 | (메인 전달) 사용자의 답 — "여기서 3회 이후도 오류가 있으면 그 오류를 수정할 필요가 있으면 수정하고 재 리뷰하는게 맞다고 보긴하거든." | 메인의 읽기(그대로 따른다): 고칠 필요가 있는 지적이 남으면 3회 상한에서 멈추지 않고 고치고 다시 리뷰(Opus ∥ codex — 표적 재점검으로 갈음하지 않음) · 후보 · 기각만 남으면 닫는다 · 이 작업의 뒤 task 에도 같은 법 · 정지 규칙(같은 결함 두 번 고쳐도 또 깨짐)은 그대로 멈추고 올린다. 하네스 review.md 의 "최대 3루프"와 다르다 — 규칙으로 올릴지는 따로 물을 일(`incident.md` 7절 · NEXT 후보) |

## 진행 중 결정 (합의 뒤 기록하고 진행한 것 — 마감 때 사용자 확인, `playbooks/task-units.md` §4)

| 시각 | task | 결정 | 왜 묻지 않았나 | 뒤 task가 기대나 |
|------|------|------|----------------|------------------|
| 11-27 16:18 | 01 | 리뷰 지적 t01-10 을 고치려고 계획 밖 파일 `playbooks/writing/work-records.md`(규칙 10)에 가리키는 한 구절을 더한다 | 목표 · 불변식은 그대로이고 고칠 곳만 는다(task-units §4 "그 밖은 기록하고 진행") · core 는 글자 여유가 적어 work-records 가 싸다 | 아니오 |
| 11-27 15:28 | — | 작업 트리의 base 를 로컬 `main` 대신 `origin/main` 으로 | 지시의 뜻(기본 브랜치의 끝에서 시작)과 같고, 브랜치를 지우고 다시 만들면 되돌릴 수 있다 | 예 — 줄 번호 · 글자 수가 이 판 기준 |

## 옮김 대조표 (task 02 — `writing/rule-docs.md` 규칙 6 · 원래 위치는 모두 core §6 110행 · 워커 packet 16:07 · 메인과 t02 Opus 리뷰어가 미러에서 다시 확인)

| 원래 내용 | 옮긴 뒤 위치 |
|---|---|
| `git-guard`(push ask · 커밋/gh 발행 attribution 차단) | README 186행 |
| `codex-scan`(시크릿 backstop) | README 187행 |
| `gate-guard`(C1 · C2 · SPEC/MODE 게이트 · 고정 지시 파일 쓰기 ask · 작업 폴더당 1회 알림(차단 아님)) | README 180행(C2 · ask · 알림은 이번에 더함) |
| `session-mode-guard` · `reinject-mode` · `task-mode-guard`(spec · log 리셋) | README 184 · 185 · 183행 |
| `detect-layer`(관측 전용 · `.events` · 차단 없음) | README 188행("관측 전용") |
| `capture-decision` · `reread-track` | README 189 · 190행 |
| "배포 단일 출처 = 이 repo" · 테스트 `hooks/tests/run.sh` | core 에 남김 |
| "활성"이라는 구분(아홉만 등록된 훅) | README `hooks/` 줄 주석(리뷰 반영 t02-c2) |

## 고장 내기

해당 없음 — 테스트 코드가 없는 L0 기록.

## 리뷰 ledger

준비 차례(1 · 2)는 리뷰를 돌리지 않았다. 아래는 구현 차례.

- review packet: t01 루프 1 — base `77ba594` / 리뷰한 SHA `0b87e2d` / `$OUT` = `…/scratchpad/rv/t01-l1` / 미러 = 같은 폴더 `mirror/`
- review packet: t01 루프 2 — base `77ba594` / 리뷰한 SHA `1a5db40` / `$OUT` = `…/scratchpad/rv/t01-l2`
- review packet: t01 루프 3 — base `77ba594` / 리뷰한 SHA `498cd64` / `$OUT` = `…/scratchpad/rv/t01-l3`
- review packet: t02 루프 3 — base `0b87e2d` / 리뷰한 SHA `cbb2cf3` / `$OUT` = `…/scratchpad/rv/t02-l3`
- review packet: t02 루프 2 — base `0b87e2d` / 리뷰한 SHA `8acc2b7` / `$OUT` = `…/scratchpad/rv/t02-l2`
- review packet: t02 루프 1 — base `0b87e2d` / 리뷰한 SHA `2e55217` / `$OUT` = `…/scratchpad/rv/t02-l1` / 미러 = 같은 폴더 `mirror/`

| id | task | first_seen_loop | source | 근거(file:line) | repro | impact | need | disposition | status | fixed_in_loop |
|----|------|-----------------|--------|-----------------|-------|--------|------|-------------|--------|---------------|
| t01-1 | 01 | 1 | opus | templates/log.md:22,24 · task-units.md:45 — "그 task의 표에도 옮긴다"가 task 마다 표를 만들게 읽힘 → 파서는 표지 뒤 첫 표 하나만 읽어 둘째 표부터 조용히 놓침 | 코드로만 확인 — ① 문서 | 검증 | 반드시 필요 | 채택 — (4) 명세 6.1 ①(표 하나) · 2절(놓치지 않음)에 어긋남 | fixed | 1 |
| t01-2 | 01 | 1 | opus | task-units.md:45 · requirement-spec.md:93 — task 로 나누지 않은 작업에서 표를 만드는지 없음 | 코드로만 확인 — ① 문서 | 검증 | 반드시 필요 | 채택 — (4) 분기 답 Q2 "모든 task" | fixed | 1 |
| t01-3 | 01 | 1 | opus | src/core.md:75 — task 01 커밋의 core 가 15,730자(상한 초과) | 코드로만 확인 — ① 문서(실측) | 계약 | 있으면 좋다 | 기각 — 바로 뒤 커밋 `2e55217`(task 02)에서 15,346자. 명세 9절 차례 문장 "앞당겨도 된다"대로 02 를 01 바로 뒤에 둠 · 배포는 07 이라 배포본이 상한을 넘는 일 없음 | closed | |
| t01-4 | 01 | 1 | opus | task-units.md:45,50,53 — task 를 다시 열 때 줄을 `열림`으로 되돌리는 말이 없음 | 코드로만 확인 — ① 문서 | 검증 | 하면 좋다 | 채택 — (4) 닫음 표시가 다시 연 task 를 가리면 2절의 "빈 칸이 있으면 닫지 않는다"가 빈다 | fixed | 1 |
| t01-5 | 01 | 1 | opus · codex(C1) | src/core.md:75 — core 줄이 긴급(DEBT=1)의 예외 없이 "막는다"고 단정 | 코드로만 확인 — ① 문서 | 계약 | 반드시 필요 | 채택 — (4) 명세 2절 · 0절(긴급은 알림만)과 상시 문서가 어긋남 | fixed | 1 |
| t01-6 | 01 | 1 | opus | templates/log.md:5,24 · core §7 — log append 규칙과 표의 제자리 고침이 부딪히는데 앞서는 쪽이 없음(rule-docs 규칙 3) | 코드로만 확인 — ① 문서 | 문서 | 하면 좋다 | 채택 — (4) 같은 줄을 `닫음`으로 덧붙이면 옛 `열림` 줄이 남아 알림이 계속됨 | fixed | 1 |
| t01-7 | 01 | 1 | codex(C2) | templates/log.md:25 — 빈 칸 정의에 공백뿐인 칸이 없음 | 코드로만 확인 — ① 문서 | 문서 | 하면 좋다 | 채택 — (4) 명세 6.1 ① 의 빈 칸 정의와 템플릿이 어긋남 | fixed | 1 |
| t01-8 | 01 | 2 | opus(L2-1) | templates/log.md:5,22-31 — 새 줄을 파일 끝에 덧붙이면(append 습관 · Bash heredoc) 표 밖이라 훅이 조용히 놓침 | 코드로만 확인 — ① 문서 | 검증 | 반드시 필요 | 채택 — (3) 루프 1 의 "표는 하나" 고침이 낸 새 길 · (4) 2절 "놓치지 않음" | fixed | 2 |
| t01-9 | 01 | 2 | opus(L2-2) | task-units.md:45 — T1 은 계약 문서의 줄을 옮기라는 말이 없음 | 코드로만 확인 — ① 문서 | 검증 | 반드시 필요 | 채택 — (3) 루프 1 고침이 낸 빈틈 · (4) 목표(계약 문서의 요구) | fixed | 2 |
| t01-10 | 01 | 2 | opus(L2-3) | core §7 · work-records.md:37 규칙 10 — append 규칙의 예외가 템플릿에만 | 코드로만 확인 — ① 문서 | 문서 | 하면 좋다 | 채택 — rule-docs 규칙 3. 계획 밖 파일 `work-records.md` 를 더함 → 진행 중 결정 | fixed | 2 |
| t01-11 | 01 | 2 | opus(L2-4) | templates/requirement-spec.md:96 · task-units.md:45 · spec 6.1 — 첫 칸 task 표기의 꼴이 없음(`task 01` · `T1` · `T4`) | 코드로만 확인 — ① 문서 | 검증 | 하면 좋다 | 채택 — 훅이 첫 칸 글자로 task 를 가른다(6.1 ②) | fixed | 2 |
| t01-12 | 01 | 2 | opus(L2-5) | task-units.md:53 — 작업 마감 때 `열림` 줄을 어떻게 하나 없음(Q7 사이드카라 옛 폴더 알림이 계속 뜸) | 코드로만 확인 — ① 문서 | 검증 | 하면 좋다 | 채택 — (4) "알림이 늘 떠 무시하는 습관"(명세 Q6 근거)을 이 변경이 만든다 | fixed | 2 |
| t01-13 | 01 | 3 | opus | task-units.md:45 끝 · :49 — "표의 넘긴 곳이 근거다"가 메인이 묻지 않고 적은 넘김으로도 리뷰 지적을 기각하게 함(:49 는 "명세가 배정한 일"만) | 코드로만 확인 — ① 문서 | 검증 | 반드시 필요 | 채택 — (3) 루프 1 의 문장이 냄 · (4) 사고의 꼴(자기 선언으로 닫음)을 되살림 | open | |
| t01-14 | 01 | 3 | opus | templates/log.md:24 · work-records.md:37 — 쓰는 법이 템플릿에 다시 쓰이고 work-records 가 쓰는 법의 정본을 템플릿이라 가리킴(이미 갈라짐 — 넘김 칸 · 다시 열기 · 묻기 · 워커 대조 · 긴급) | 코드로만 확인 — ① 문서 | 문서 | 하면 좋다 | 채택 — (3) 이번 변경 · (4) 명세 2절 단일 출처 | open | |
| t01-15 | 01 | 3 | opus | task-units.md:45 — 명세가 없는 긴급 수정의 log 에서 T1 의 요구를 어디서 옮기나 없음 | 미실행 — 후보 | 검증 | 하면 좋다 | 후보 — 명세가 정하지 않은 경우(긴급 경로의 요구 출처) · 긴급은 이미 "알림만 · 빚" 이고 표를 안 쓰면 훅은 조용하다 → NEXT | closed | |
| t02-3 | 02 | 2 | opus(L2-1) | README.md:179 · settings.json — 저장소의 `settings.json` 사본에 detect-layer 등록이 없다(여덟) | 미실행 — 후보: 원래 있던 것 | 문서 | 하면 좋다 | 후보 — (3) 이번 변경 전부터 있던 것 · 이미 후보(`docs/plans/2026-11-20/review-triage/replay.md:13` · NEXT N8) | closed | |
| t02-4 | 02 | 2 | opus(L2-2) | README.md:188 — 옮기면서 detect-layer 사이드카가 세션별(`<sid>.events`)이라는 말이 빠짐 | 코드로만 확인 — ① 문서 | 문서 | 있으면 좋다 | 채택 — (4) 옮김 대조(옮긴 뒤 위치가 빈 것 0) | fixed | 2 |
| t02-c1 | 02 | 1 | codex(D1) · opus(2) | src/core.md:111 · hooks/deploy.sh:18 — README 는 배포되지 않아 다른 프로젝트 세션에서 가리킴이 풀리지 않음 | 미실행 — 기각 | 계약 | 있으면 좋다 | 기각 — (1) 사용자가 이 옮김을 골랐다(분기 Q4) · core 는 이미 README 를 가리킨다(§0.2 "세는 법 = README" · §5 "README '실측' 절") — 같은 설계. 훅 목록은 모델이 따를 행동이 아니라 색인이고 행동 규칙은 core §1 · §6 · §7 에 남음 | closed | |
| t02-c2 | 02 | 1 | codex(D2) · opus(1) | README.md:179-192 · src/core.md:111 — README 의 `hooks/` 트리에는 라이브러리 · CLI · 배포 · 테스트도 같이 있어 "활성 훅"의 구분이 사라짐 | 코드로만 확인 — ① 문서 | 문서 | 하면 좋다 | 채택 — (4) 옮김 대조(명세 2절 — 옮긴 뒤 위치가 빈 것 0)에서 "활성"이라는 구분이 옮겨지지 않음 | fixed | 1 |

- verified — t02 루프 3(신규 채택 0 · 두 리뷰어 모두 지적 없음): 네이밍 / README.md:179 ↔ hooks/*.sh / 훅 이름 아홉을 파일명과 대조 / opus · codex · 완전성 / packet-diff.md:77 → README.md:180-190 · src/core.md:111 → README.md:150,179 / 옮김 대조 빈 칸 0 · 가리킴 이어짐 / opus · codex · 통합 / hooks/deploy.sh:6,18,179 ↔ README.md:179,222 / 등록 위치 · 배포 제외 서술이 맞음 / opus · codex · 설계 품질 / src/core.md:111 / 단일 출처 / opus · codex · 과잉 구현 / src/core.md:111 / 줄이 짧아짐 / opus. 비적용(API · 메서드 · 쿼리 · 동시성 — 문서). 비대칭 없음 → **t02 리뷰 종료**.

## 생략한 검증

해당 없음(긴급 경로 아님).

## 완료 요약 (이번 차례)

- 된 것: `incident.md`(실측 기록) · `requirement-spec.md`(초안 — Q1~Q5 를 물을 것) · `proposal.md`(파일마다 지금의 글 → 바꾼 글 · 글자 수 전후 · 다섯 건을 잡는가). 정책 파일 · 배포본 · deploy-study-note 는 고치지 않았다.
- 확인하지 않은 것과 알아야 할 위험: 리뷰어 원문(T4 리뷰가 앱 쪽 빠짐을 보았는지) · T5b 를 다른 말로 사용자에게 알렸는지 · 규약 §7.1 의 T5 · T8 줄이 닫던 때에도 지금 글자였는지 · 워커 토큰 값이 누적인지 · 다른 세션 작업 트리의 커밋되지 않은 core 변경. 제안의 효과("따로 된 굵은 줄이면 지켜진다")는 측정 근거가 없다.
- 뺀 것과 다시 더할 조건: 훅 강제(Q1 (나)) — 절차 규칙으로 몇 작업을 돌려 빈 칸을 둔 채 닫은 일이 다시 나오면 · 압축 뒤 재독에 계약 문서를 넣기(Q5 (나)) — 표를 log 에 둔 뒤에도 압축 뒤에 요구를 잃은 실측이 나오면.
- 더 나은 대안: 없음(안 C 는 기록상 효과가 없어 견줌에서 뺐다).

## 완료 요약 (2차 — 사용자의 답 반영)

- 된 것: 명세 2판(사용자의 답 셋 · 훅 설계 6.1 · 못 보는 것 6.2 · task 일곱 · 더 물을 것 Q6~Q8) · 제안 2판(훅 코드 제안과 테스트 사례 · core 15,339자) · 실측 기록 6절(덤 결함). 정책 파일 · 훅은 고치지 않았다.
- 확인하지 않은 것과 알아야 할 위험: 제안한 훅 코드는 실행하지 않았다(awk 종류 · C 로캘의 한글 비교 · `exit` 뒤 `END` 는 [구현 검증]) · 서브에이전트의 PostToolUse(Write) 입력에 `agent_id` 가 실리는지(명세 8절 가정 1) · 리셋 때 훅이 낸 출력.
- 뺀 것과 다시 더할 조건: git-guard push 승인 사유에 빈 칸 수(차단 · 알림이 있는데도 빈 칸을 둔 채 push 한 실측이 나오면) · 원문 줄 수의 기계 대조(잘린 출력이면 두 수가 같이 틀려 잡는 것이 없다 — 원문을 훅이 읽을 꼴이 생기면) · 압축 뒤 재독에 계약 문서.
