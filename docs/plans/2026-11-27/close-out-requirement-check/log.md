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
| 11-27 16:27 | 루프 3 반영 워커(Opus 79k) 회수 → 커밋 `8c4739c` | task-units 80줄 · 템플릿은 꼴만 · work-records 규칙 10 가리킴을 꼴/쓰는 법으로 나눔 · 지운 문장 대조표(워커 packet — 모두 task-units §3 에 같은 뜻) |
| 11-27 16:30 | 루프 4: t01 Opus(127k — 지적 2) ∥ codex(지적 1) | 채택 둘(16 · 17) · 기각 하나(18). 채택 수 6 → 5 → 2 → 2 로 줄어듦 · 같은 결함의 되풀이 아님. 반영 워커 시작 → 루프 5 |
| 11-27 16:31 | 루프 4 반영 워커(Opus 65k) 회수 → 커밋 `065edb3` | task-units 80줄 |
| 11-27 16:35 | 루프 5: t01 Opus(116k — 지적 2) ∥ codex(지적 없음) | 채택 둘(19 · 20). 19 는 차례의 설계 결함(대조가 검증 뒤) — 같은 결함의 되풀이가 아니라 새 지적. 채택 수 6 → 5 → 2 → 2 → 2. 반영 워커 시작 → 루프 6 |
| 11-27 16:35 | 루프 5 반영 워커(Opus 70k) 회수 → 커밋 `b693e1d` | task-units 80줄 · 그림 · 트리거 · 요구 대조 줄이 같은 차례(요구 옮기기 → 구현 → 커밋 → 요구 대조 → 검증 → … → 대조 재확인(닫음)) |
| 11-27 16:39 | 루프 6: t01 Opus(109k) ∥ codex — **둘 다 지적 없음** | **task 01 리뷰 종료**. 지적 수(채택): 6 · 5 · 2 · 2 · 2 · 0. 읽기 시험: 고치기 전 판(`wt/harness-base`) 워커(Opus 73k) 끝 · 고친 판 워커 시작 |
| 11-27 16:41 | **읽기 시험**(reading-test.md — 사례 (가) 셋 · (나) 둘, 맞는 답은 시험 전에 `…/scratchpad/reading-test/cases.md` 에 고정) — 고치기 전 판 워커(Opus 73k · `wt/harness-base` `7688bad`) · 고친 판 워커(Opus · `wt/harness-closeout` `153bc8a` — 맥락의 배포본 core 는 고치기 전 판이라는 것을 알림) | 사례마다 고치기 전 / 고친 뒤 / 맞나: ① T4 — 전: "닫지 말고 묻는다"(판정은 맞음) · 다만 "요구 대조가 정의돼 있지 않다 · 메인이 스스로 알아챘을 때만 작동 · 적을 칸 없음"으로 막힘 / 후: 13줄로 나눠 옮기고 빈 칸 7 → 닫지 않음 · 넘김은 묻기 · 워커 대조 — **맞음** ② T2 `head -8` — 전: "안 된다"(core §4 의 비슷한 조항에서 끌어옴 · 직접 규칙 없음 — 막힘 부분) / 후: tu:45 직접 인용 — **맞음** ③ T8 — 전: 닫지 말고 묻기 · 넘김을 적을 꼴 없음(막힘) / 후: 대상마다 나눠 (b) 빈 칸 → 묻거나 넘김 기록 — **맞음** ④ 낮음 오타(나) — 전: 대조 없음 / 후: 표 한 줄 · 워커 대조 없음 — **맞음**(과한 절차 없음) ⑤ 넘긴 지적 기각(나) — 전 · 후 모두 기각(근거 = 명세 배정) — **같음 · 맞음**. 고친 뒤 판의 막힘(결함으로 셈): a "원문의 줄 수"를 절 전체로 세나 그 task 줄만 세나 · 계약 문서가 없을 때 무엇을 세나 b `·` 로 이은 할 일을 나누나 c 워커 대조 조건의 "저장소 둘 이상"을 무엇으로 세나 d core:75 "넘긴 곳(받는 task·사용자 합의 시각)"이 늘 둘 다로 읽힘. 원래 있던 것(후보): e 명세 템플릿의 task 정의(spec:94 "한 가지 방법으로 확인되는") ↔ task-units:8 f 명세 템플릿 111-112행 깨진 표 조각(리뷰어 셋 · 읽기 시험 둘이 짚음) → a~d 를 고치는 워커 시작 → 고친 뒤 다시 리뷰(사용자의 답) |
| 11-27 16:42 | 읽기 시험 막힘 반영 워커(Opus 62k) 회수 → 커밋 `979e8a2` | core **15,370자** · task-units 80줄 |
| 11-27 16:44 | 루프 7: Opus(100k — 지적 2) ∥ codex(지적 1) — **셋 모두 "옮긴 줄 수 / 원문의 줄 수" 한 문장** | **정지 규칙(core §3)에 걸림**: 이 문장은 루프 4(분자) · 루프 5(분모) · 읽기 시험(범위) · 루프 7(배정 판정 · 명세 칸 · 넘겨받은 줄)로 네 번째 깨짐 — 같은 곳을 두 번 넘게 고쳐도 또 깨진다 = 토대가 틀렸다. 해석: 이 수는 메인이 같은 읽기로 양쪽을 세는 자기 보고라 사고의 `head -8` 같은 잘린 읽기에서는 두 수가 함께 틀려 잡는 것이 없다(명세 0절이 훅 대조에서 뺀 까닭과 같음) — 그런데 뜻을 정할수록 범위 규칙이 늘었다. 멈추고 메인에 올림(설계를 되돌릴 안: 수 대조를 빼고 "끝까지 Read · 대상마다 나눔 · 큰 표는 워커 대조"만 남김) |
| 11-27 17:43 | (메인 전달) 사용자의 답(선택지): "수 대조를 뺀다" · 덧붙임: 리뷰어에게 주는 범위를 좁게(고친 곳 · 닿는 곳 · 이미 판정한 목록) · 문서 문구는 읽는 사람이 다르게 행동하게 되는 것만 고친다(취향은 기각) · 힘은 task 03~05 에 | task-units §3 · log 템플릿의 수 줄 · 명세 0절의 해당 줄을 뺀다 → 루프 8 → task 03 |
| 11-27 17:44 | 수 대조 삭제 워커(Opus) 회수 → 커밋 `a44da7a` | task-units §3 의 수 문장 · log 템플릿의 줄 수 한 줄을 뺌(`git grep` 0건) · task-units 80줄 · 표지 · 머리 줄 그대로. t01-21~23 은 이 삭제로 풀림(ledger) → 루프 8(좁게 — 이번 삭제와 닿는 곳만) |
| 11-27 17:45 | 루프 8(좁게): Opus(74k — 낮음 1, 기각) ∥ codex(지적 없음) | **task 01 리뷰 종료**(채택 0). 지적 수(채택) 6 · 5 · 2 · 2 · 2 · 0 · 3(정지 → 설계 되돌림) · 0. 이제 task 03 |
| 11-27 17:5x | task 03 blind 테스트 워커(Opus 117k+) 보고(메인 전달 — 이 워커가 넘긴 뒤 도착) | 새 파일 `hooks/tests/cases/req-check.sh` 26개(`test_rq_` — P1~P16 · C 로캘 둘 · 더한 넷) · tests.lock 다시 만듦 · `run.sh` 436 통과 · 26 실패(함수 없음 rc 127 — red 기록) · 건너뜀 0. 워커의 임시 참조 파서 `…/scratchpad/rqref/state-lib.sh` 는 구현 워커에게 열지 않게 한다. 해석 여덟 모두 받음(① 테스트 이름은 영문 — 한글은 `run.sh` 의 `test_[a-z0-9_]+` 에 걸러져 0 으로 세어진다는 실측 → 명세 ② 표의 이름을 실제 이름으로 고침) |
| 11-27 17:55 | 워커가 남긴 모호한 곳을 계약으로 정해 같은 워커에게 테스트를 더하게 함 | 판정 불가 = 모든 L1 차단이라 흔한 꼴은 판정 불가로 떨어지지 않게: ① 표지와 머리 줄 사이 빈 줄은 건너뜀 ② CRLF 의 `\r` 은 공백 ③ 읽을 수 없는 log → rc 1(명세 2절 그대로) ④ 들여쓴 표 줄은 앞뒤 공백을 무시한 뒤 `|` 로 시작하면 표 ⑤ 넷째 칸의 `\|` 는 채움 ⑥ `**닫음**` 은 상태 값 밖 → rc 1 · 공백은 무시 |
| 11-27 18:0x | red 기준 메인 재실행(`f6101f3`) | **436 통과 · 33 실패 · 0 건너뜀** — 실패 33 모두 `test_rq_` · rc 127(함수 없음) · 기존 실패 0 |
| 11-27 18:17 | task 03 구현 워커(Opus 131k+) 회수 → 커밋 `a5a8c2c` | 바뀐 것 `hooks/state-lib.sh` 하나(+53) · 테스트 · lock 변경 없음(`git diff --quiet -- hooks/tests`). **메인 재실행 469 통과 · 0 실패 · 0 건너뜀**. 워커 packet: mawk · mawk+C 로캘 · busybox awk 33/33 · gawk 는 이 머신에 없음 · 고장 다섯 모두 잡힘 · proposal 과 다른 곳 하나(표지를 grep 으로 먼저 찾지 않고 awk 가 줄 전체로 판정 — 인용 안의 표지 글자만 있는 log 가 차단으로 떨어지지 않게). **메인 고장 내기**: 저장소 밖 사본(`…/scratchpad/break-t03`)에서 state-lib.sh:430 빈 칸 정의의 `|| s == "-"` 를 지움(`cmp` 430행 다름 확인) → 넷째 칸 `-` 인 닫음 줄의 VIOLATION 이 사라짐(원본은 `VIOLATION T01 6`) — P5 가 지키는 규칙. **지연 실측**: 156KB log(사고의 139KB log + 표) 10회 0.098s(한 번 약 10ms) |
| 11-27 18:27 | t03 루프 1: Opus(실행 · 123k) ∥ codex | 측정(Opus): 195KB 한 번 약 11.5ms · 폴더 열 개 81ms · 1.37MB 29ms · 새 bash+source+scan 19ms · gawk 5.2.1(docker · C · C.UTF-8) 33/33 · mawk · busybox 와 탐침 29개 바이트까지 같음 · 반쯤 쓴 표는 판정 불가 + 행 번호(무엇을 하라는 말은 없음 — task 04 메시지에서). 지적: Opus 1(펜스 — 실행 재현) · codex 2(칸만 있는 구분 줄 · 앞 `|` 빠진 첫 본문 줄 — 메인이 사본에서 재현) · 테스트 공백 1. 채택 넷 → 수정 워커. **사고**: Opus 리뷰어가 읽기 전용 사본 mkdir 실패 뒤 cd 실패를 모른 채 명령을 이어 deploy-study-note 의 backend 저장소 작업 트리에 임시 파일 15개를 만들었고 스스로 스크래치로 옮김 — 메인 확인: backend 저장소 `git status --porcelain` 비어 있음 · 그 파일들 없음 |
| 11-27 18:50 | task 03 리뷰 반영 워커(Opus 96k+) 회수 → 커밋 `79bf27c` | 바뀐 것 셋(state-lib · req-check.sh 끝에 다섯 더함 · tests.lock — lock 재생성 사유 = 리뷰 반영 재현 테스트 p26 · p26b · p27 · p28 · p29, run.sh 가 말하는 gate.md 는 v3 페이즈 문서라 이 log 가 그 기록). **메인 재실행 474 통과 · 0 실패 · 0 건너뜀**. 메인이 사본에서 재현했던 c1 · c2 → 이제 rc 1(`구분 줄이 꼴과 다름 (3행)` · `표의 줄이 \| 로 시작하지 않음 (4행)`). 워커 고장 넷 잡힘. 워커가 든 위험 둘: ① 닫히지 않은 펜스 뒤의 표지 → rc 2(조용히 꺼짐) ② 표 바로 아래 `|` 가 든 보통 글 → 차단 |
| 11-27 18:50 | 위험 ① 의 근거: 실제 log 22개(하네스 `docs/plans/**/log.md` 21 + 사고 log)의 펜스 줄 수를 셈 | 짝이 안 맞는 log 0 · 펜스가 있는 log 9(2~16줄). 드물지만 일어나면 그 log 의 검사가 조용히 꺼진다 → 가장 작은 고침: 파일 끝까지 펜스가 닫히지 않았고 그 펜스 안에 줄 전체 표지가 있었으면 판정 불가(rc 1 · 행 번호) — 놓침을 차단으로 바꾼다(원칙: 판정할 수 없으면 막는다 · 표를 고쳐 푼다). 위험 ② 는 받아들인다: 표 바로 아래에 빈 줄을 두면 풀린다 — 템플릿에 한 구절("표 바로 아래에는 빈 줄을 둔다") · 차단 메시지의 "몇 행 · 무엇을 하면 풀리나"는 task 04(gate-guard) 몫 |
| 19:0x | p30c 회수(워커 — 메인의 고장 내기에서 `fmark = 0` 리셋을 지켜 주는 테스트가 없음을 보고 더하게 함) → 커밋 `69dce52` | 워커 보고 477 통과. 메인 재실행은 무효 — 도는 동안 메인 세션의 capture-decision 이 이 작업 폴더의 `decisions.md`(TASK_PATH)에 덧붙여 hermetic 검사가 깨짐(exit 1 · 차이 = decisions.md 해시뿐). 다시 돌릴 것 |
| 11-27 19:06 | t03 루프 2(좁게): Opus(실행 · mawk · gawk 5.3.0 docker — req-check 41/41) ∥ codex | 지적 셋 — **모두 코드 펜스의 짝 세기**(t03-5 닫히지 않은 펜스 뒤 코드 블록 · t03-6 인라인 백틱을 펜스로 · t03-7 펜스 안의 다른 펜스 줄). **정지 규칙(core §3)**: 펜스 처리는 루프 1(t03-1 펜스 안 표지) → 닫히지 않은 펜스(진행 중 결정) → 루프 2 셋으로 같은 곳을 두 번 고쳐도 또 깨짐 — 마크다운 펜스의 짝을 awk 로 바르게 세는 것이 토대의 문제. 멈추고 메인에 올림. 되돌릴 안: 펜스를 세지 않고 "줄 전체 표지는 log 에 하나 — 둘 이상이면 판정 불가(행 번호 둘 · 예시는 인라인 백틱으로)" |
| 11-27 19:07 | (메인 전달) 사용자의 답(선택지): "세지 않고 '표지는 하나'" | 펜스 코드를 빼고 "줄 전체 표지가 둘 이상 → 판정 불가(두 행 번호)" · 펜스 테스트를 새 계약으로(blind) · 템플릿 구절. `pgrep -fa hooks/tests/run.sh` — 남은 실행 0(멈출 것 없음) |
| 11-27 19:07 | 무효였던 메인 재실행(`69dce52`)의 판정 | `run.sh` 는 INTEGRITY VIOLATION 이면 통과 · 실패 수를 내지 않는다 → 결과가 없으니 유효로 칠 수 없다(차이 목록은 `decisions.md` 한 줄뿐 — 테스트가 더럽힌 것이 아니라 메인 세션의 capture-decision 이 TASK_PATH 에 쓴 것). 앞으로: 메인 재실행은 **따로 된 깨끗한 작업 트리**(`…/scratchpad/wt/harness-base` 를 그 커밋으로 detached checkout)에서 돌린다 — 추적되지 않는 decisions.md 가 없어 메인의 질문과 부딪히지 않는다 |
| 19:1x | 인증이 끊겨(사용자 로그인 변경) blind 테스트 워커가 도중에 멈춤 → 메인이 확인: 테스트 파일 문법 통과 · 43개 · 끝까지 쓰여 있음 · 그 워커의 run.sh 둘은 이미 끝남(남은 실행 0). lock 을 메인이 다시 만들고 커밋 `01c139a`(테스트 — 구현 전) | 깨끗한 작업 트리(`wt/harness-base` 를 `01c139a` 로 detached)에서 red: **473 통과 · 6 실패 · 0 건너뜀** — 실패 6 = 새 계약 테스트(p26 · p30 · p30b · p30c · p31 · p31b) |
| 11-27 19:17 | 구현 워커(Opus 105k) 회수 → 커밋 `2b6fb33` | state-lib +19/−21(펜스 코드 7줄 지움 · 표지 줄 수 · `die` 가 끝까지 읽게) · 템플릿 두 구절 · 워커의 고장 내기 2(둘째 표지 무시 → p26 · p31 · p31b 실패 / `die` 가 exit → 잡는 테스트 없음 → 같은 워커가 p31c 를 더함 · 그 고장에서 p31c 실패) · lock 480. 메인 재실행(깨끗한 작업 트리) · 루프 3(좁게 · Opus 실행 ∥ codex) 시작. lock 을 다시 만든 사유 = 이 행 |
| 11-27 19:22 | t03 루프 3(좁게): Opus(실행 · 89k — mawk · gawk 5.3.2 에서 44/44) ∥ codex — **둘 다 지적 없음** · 메인 재실행(깨끗한 작업 트리 `2b6fb33`) **480 통과 · 0 실패 · 0 건너뜀** | **task 03 닫음**. 후보 하나(BOM · NBSP 표지). task 04 blind 테스트 워커 시작 — 계약을 처음부터 넉넉히(흔한 꼴 · 놓침과 막힘 양쪽). **진행 중 결정**: 사이드카에 **쓰는** 일(task-mode-guard)은 task 05 로 옮김(task-mode-guard 를 고치는 일을 한 task 에) — task 04 는 읽는 쪽(`state_reqcheck_paths` · gate-guard · reinject) |
| 11-27 19:30 | task 04 blind 테스트 워커(Opus 179k) 회수 → 커밋 `6e6b70c` | 새 `hooks/tests/cases/req-check-gate.sh` 48개(A paths 12 · B gate 25 · C reinject 11) · legacy 사본 `fixtures/legacy-d42c6a9/`(gate-guard · reinject · state-lib — 지금 훅과 cmp 같음) · lock 528(사유 = 이 행). 워커 사본에서 8 통과(종전과 같다 · 막지 않는다) · 40 실패(함수 · 동작 없음). 워커의 해석 여덟 받음(DEBT=1 은 stdout JSON 만 단언 · reinject 위반은 모은 한 줄 · 위반 줄이 앞 등). 메인 red 재실행(깨끗한 작업 트리) · 구현 워커 시작 |
| 19:4x | task 04 red(깨끗한 작업 트리 `6e6b70c`) | **488 통과 · 40 실패 · 0 건너뜀** — 실패 40 모두 `test_rg_` |
| 11-27 19:41 | task 04 구현 워커(Opus 192k) 회수 → 커밋 `38c2d23` | 세 파일 +127(state-lib: paths · findings(공용 — 두 훅이 어긋나지 않게 · 브리프에 없던 것) · gate-guard: req_check_gate · reinject 단락). 워커 사본 528/0/0 · 고장 일곱 잡힘 · 지연 L1 Write 한 번 약 +18~40ms(243 대 225ms). **메인 고장 내기**: 저장소 밖 사본(`…/scratchpad/break-t04`)에서 gate-guard.sh:391 의 `VIOLATION)` 갈래를 `VIOLATIONX)` 로(cmp 391행) → 워커(agent_id) 의 L1 Write 가 원본 exit 2(요구 대조 메시지 · T01 · 6행 · 푸는 길) → 고장 사본 exit 0 — b01 · b03 이 지키는 규칙. 메인 전체 재실행(깨끗한 작업 트리) · 리뷰 루프 1(Opus 실행 ∥ codex) 시작 |
| 11-27 20:02 | 메인 재실행(깨끗한 작업 트리 `38c2d23`) **528 통과 · 0 실패 · 0 건너뜀** · t04 루프 1: Opus(실행 · 185k — 놓침 9가지 · 오탐 · 종전 바이트 비교 10 시나리오 · 겹친 상태 · 지연 · 고장 9개 모두 잡힘) ∥ codex — 둘이 같은 지적 둘 | 채택 둘(t04-1 사이드카 손상의 푸는 길 · t04-2 DEBT 의 stderr 한 줄). 지연: gate-guard 한 번 약 +5~45ms · findings 한 번 3~43ms(폴더 다섯 40줄씩). 겹친 상태(DEBT=1 + PENDING=1 / 미독)는 exit 2 에 stdout JSON — 막는 판정은 그대로라 결함 아님(알림은 다음 쓰기에) |
| 20:1x | t04 리뷰 반영 워커(Opus 87k+) 회수 → 커밋 `1257b33` | gate-guard 하나(+ 테스트 b26 · b27 · lock 530). **메인 재실행(깨끗한 작업 트리) 530 통과 · 0 실패 · 0 건너뜀**. **메인 고장 내기**: 사본(`…/scratchpad/break-t04`)에서 gate-guard.sh:409 의 DEBT stderr `echo` 를 `: echo` 로(cmp 409행) → DEBT=1 · 위반 1건의 L1 Write: 원본 stderr "요구 대조 — 긴급(DEBT=1)이라 막지 않는다: 닫음 빈 칸 1건 …" / 고장 사본 stderr 없음 — b27 이 지키는 규칙 |
| 11-27 20:23 | t04 루프 2(좁게): Opus(실행 · 79k) — 지적 없음 ∥ codex — 지적 1(jq 실패 시 stderr 두 줄 — 기각) | **task 04 닫음**. 메인 세션의 게이트가 다른 작업 폴더로 리셋됨(상태파일 읽기: SPEC=0 · MODE=UNSET · TASK_PATH=study-note 의 study-site-import) — task 05 의 워커가 저장소 안 L1 파일을 Edit/Write 하면 gate-guard 가 막는다. 우회하지 않고 메인에 보고 |
| 11-28 02:37 | (메인 전달) 사용자 "하네스도 진행하자" — 메인 세션 게이트는 아직 SPEC=0 · MODE=UNSET(상태 기록은 사용자가 직접 하기로 · 아직 안 됨) | 진행법: 워커는 작업 트리가 아니라 **저장소 밖 사본**(`…/scratchpad/harness-t05/copy` — `d38839a` 를 git archive 로 푼 것 · git 저장소 아님 → gate-guard 의 L0)에서 쓰고 돌린다 · task 마다 patch 를 떠 두고 회수 · 리뷰도 사본 기준 · 작업 트리 적용 · 커밋은 게이트가 열린 뒤(상태파일을 읽어 확인). task 05 blind 테스트 워커 시작 |
| 11-28 02:48 | task 05 blind 테스트 워커(Opus 136k) 회수 — 사본에서 | 새 `hooks/tests/cases/req-check-writer.sh` 39개(조항 1 워커 Write 11 · 2 사이드카 쓰기 19 · 3 종전과 같다 5 · 4 읽는 쪽과의 맞물림 4) · legacy 사본 `fixtures/legacy-d38839a/`(task-mode-guard · state-lib — sha256 같음) · lock 569. 사본 전체 **542 통과 · 27 실패 · 0 건너뜀**(실패 27 = 새 테스트 · 기존 깨짐 0). 테스트 patch = `…/scratchpad/harness-t05/t05-tests.patch`. 워커 해석: 경고 글은 `req-check-paths` 또는 `사이드카` 낱말(구현에 알림) · 상태 없음 · reset-pending 분기는 계약 밖 → 메인이 정함: 상태 없으면 쓰지 않음 · reset-pending 에서도 메인의 새 폴더면 씀. 구현 워커 시작(같은 사본) |
| 11-28 03:02 | task 05 구현 워커(Opus 131k) 회수 — 사본에서 | 바뀐 것 둘(task-mode-guard +21 · state-lib `state_reqcheck_remember` +41) · 테스트 · lock 그대로(`diff -rq` 로 범위 확인). patch = `…/scratchpad/harness-t05/t05-impl.patch`(테스트 patch 와 따로). **메인 재실행**(사본의 새 사본 `harness-t05/verify`) **569 통과 · 0 실패 · 0 건너뜀**. **메인 고장 내기**(`harness-t05/mb-broken`): task-mode-guard.sh:43 의 `[ -z "$AGENT_ID" ] || exit 0` 을 `:` 로(cmp 43행) → 워커의 log.md Write: 원본 SPEC=1 · MODE=auto 그대로 · 사이드카 없음 / 고장 사본 MODE=UNSET · SPEC=0 · 사이드카 생김(사고 그대로) — a01~a05 가 지키는 규칙. 워커가 든 살아남은 고장: 중복일 때 경고 없음을 지키는 테스트가 없다(리뷰에 넘김). 리뷰 루프 1(Opus 실행 ∥ codex — 사본 기준) 시작 |
| 11-28 03:11 | t05 루프 1: Opus(실행 · 103k) ∥ codex — **둘 다 지적 없음** | **task 05 닫음**(사본 기준). 후보 하나(t05-1 테스트 공백). 게이트(상태파일 읽기)가 열려 있지 않으면 patch 둘(`t05-tests.patch` · `t05-impl.patch`)을 남기고 task 06 으로 |
| 11-28 03:13 | task 06(낮음 — 메인이 직접 · 사본에서): README 구조 절 훅 줄 셋(gate-guard · task-mode-guard · reinject) · 새 절 "요구 대조 (v4.10)"(무엇을 하나 · 푸는 길 · 못 보는 것 아홉 · 근거) · README 이력 v4.10 · HISTORY 한 줄 · 명세 ② 의 테스트 이름 표를 실제 영문 이름으로(작업 트리 docs — L0) | 셀프체크: README 의 사실(표지 둘 이상 · 긴급은 알림 · 사이드카는 사용자가 고침 · 끄는 길 없음)을 훅 코드와 대조 · 표의 이름 넷을 grep 으로 확인. patch = `harness-t05/t06-docs.patch` · 05 와 06 을 합친 patch = `harness-t05/t05-t06-all.patch`(파일 8). **게이트 닫힘(상태파일 SPEC=0 · MODE=UNSET · TASK_PATH=study-note) — 작업 트리 적용 · 커밋은 열린 뒤**. core 15,370자 · task-units 80줄 |
| 11-28 12:01 | (메인 전달) 게이트 열림 — 사용자가 set-state 를 직접 실행(상태파일 읽기: SPEC=1 · MODE=auto · DEBT=0) | patch 셋을 작업 트리에 차례로 적용(`patch -p1` — dry-run 먼저) → 커밋 test `3fa929b` · fix `07c8ea6` · docs `4dabf83` · 적용한 파일이 사본과 `cmp` 로 같음. **메인 재실행(깨끗한 작업 트리 `4dabf83`) 569 통과 · 0 실패 · 0 건너뜀**. task 05 · 06 닫음 |
| 11-28 17:19 | (메인 전달) 사용자 "하네스 배포여부도 확인해서 해당 작업 마무리하면 될 꺼 같아." → task 07 | 확인: 작업 트리 깨끗 · 끝 `3564bb4` · `git fetch` 뒤 `origin/main` = `7688bad` 그대로(조상) · 범위 대조 = 파일 25(src/core.md · playbooks 둘 · templates 둘 · hooks 넷 · hooks/tests 의 케이스 셋 · fixtures 다섯 · lock · README · HISTORY · docs/plans 다섯 — 이 작업의 범위와 같음) · push-scan: 걸린 것 2 · 확인 필요 1 = 개인 경로 `/home/jun/...` 2곳(incident.md · requirement-spec.md — 프로젝트 폴더 경로 · 비밀값 아님 · 같은 저장소의 기존 docs/plans 에 같은 꼴 95줄 — 저장소는 PUBLIC) |
| 11-28 17:19 | push → PR #17(base main · 앞선 PR 꼴의 제목 · 본문 — 작성 도구 표기 없음) → 병합(앞선 PR 과 같은 병합 커밋 꼴) | 병합 커밋 **`4bab9dd`**. 검사(checks) 없음 |
| 11-28 17:19 | 배포: 저장소 본 폴더는 다른 세션의 가지(`docs/communication-decisions` · 커밋 안 된 변경 있음)라 main 으로 바꾸지 않고, 깨끗한 작업 트리(`wt/harness-base` 를 `origin/main` `4bab9dd` 로 detached)에서 `bash hooks/deploy.sh --dry-run` | manifest diff = core.md · HISTORY.md · hooks 넷(gate-guard · reinject-mode · state-lib · task-mode-guard) · hooks/tests(케이스 셋 · fixtures 둘 · lock) · playbooks 둘(task-units · writing/work-records) · templates 둘 — 이 작업의 변경과 같고 DEST 에만 있는 파일 없음 |
| 11-28 17:19 | 실배포 `bash hooks/deploy.sh` | **권한 거부**(Claude Code auto mode 의 분류기 — "Destructive or Unwanted Actions"). 우회하지 않고 멈춤 — 배포 · smoke 는 사용자가 허락하거나 직접 실행해야 한다. 배포본 `~/.claude` 는 바뀌지 않았다 |

## 진행 중 결정 (합의 뒤 기록하고 진행한 것 — 마감 때 사용자 확인, `playbooks/task-units.md` §4)

| 시각 | task | 결정 | 왜 묻지 않았나 | 뒤 task가 기대나 |
|------|------|------|----------------|------------------|
| 11-27 16:18 | 01 | 리뷰 지적 t01-10 을 고치려고 계획 밖 파일 `playbooks/writing/work-records.md`(규칙 10)에 가리키는 한 구절을 더한다 | 목표 · 불변식은 그대로이고 고칠 곳만 는다(task-units §4 "그 밖은 기록하고 진행") · core 는 글자 여유가 적어 work-records 가 싸다 | 아니오 |
| 11-27 17:55 | 03 | 파서 계약의 세부 여섯(위 타임라인 11-27 17:55 행)을 메인이 정함 | 명세 6.1 ① 이 정하지 않은 꼴이고, 판정 불가(차단)와 오탐 사이에서 명세의 "푸는 길"에 맞게 흔한 꼴을 받아들이는 쪽 — 나중에 바꾸기 쉬운 파서 세부(task-units §4 의 넷에 들지 않음) | 예 — task 04 가 같은 파서를 부른다 |
| 11-27 18:50 | 03 | 리뷰 반영 뒤 드러난 위험 ①(닫히지 않은 펜스 → 조용히 꺼짐)을 루프 2 를 기다리지 않고 바로 고치고, 템플릿(task 01 의 파일)에 "표 바로 아래 빈 줄" 한 구절을 더한다 | 목표 · 불변식(놓치지 않음 · 판정할 수 없으면 막는다)에 맞추는 고침이고 고칠 곳만 는다 | 아니오 |
| 11-27 19:22 | 04 · 05 | 사이드카(`<sid>.req-check-paths`)에 쓰는 일을 task 04 에서 task 05 로 옮김 | task-mode-guard 를 고치는 두 일(agent_id 검사 · 사이드카 쓰기)을 같은 파일 · 같은 task 에 모은다 — 목표 · 불변식 그대로, 나누는 자리만 바뀜 | 예 — task 04 테스트는 사이드카 파일을 직접 만든다 |
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

## 요구 대조 (이 작업 자신 — 새 규칙을 먼저 써 봄)

<!-- req-check:v1 -->
| task | 원문 위치 | 요구 | 만든 곳 / 넘긴 곳 | 상태 |
|---|---|---|---|---|
| T01 | 명세 9절 task 01 | core §4 한 줄 · task-units §3 · log 템플릿 표 · 명세 템플릿 9절 결과 칸 | `0b87e2d` … `a44da7a`(리뷰 루프 8 · 읽기 시험) | 닫음 |
| T02 | 명세 9절 task 02 | core §6 활성 훅 목록 → README · core 에는 가리키는 줄 | `2e55217` · `8acc2b7` · `cbb2cf3` | 닫음 |
| T03 | 명세 9절 task 03 · 6.1 ① | state-lib 의 표 파서와 테스트 | `8061aa2` … `2b6fb33`(hooks/state-lib.sh `state_reqcheck_scan` · tests/cases/req-check.sh) | 닫음 |
| T04 | 명세 9절 task 04 · 6.1 ② | 사이드카 읽기 · gate-guard 차단 · reinject 알림과 테스트 | `6e6b70c` · `38c2d23` · `1257b33` | 닫음 |
| T05 | 명세 9절 task 05 · 진행 중 결정(사이드카 쓰기 이동) | task-mode-guard 가 워커의 Write 로 리셋하지 않음 · 사이드카 쓰기와 테스트 | `3fa929b` · `07c8ea6` | 닫음 |
| T06 | 명세 9절 task 06 | README 의 훅 설명 · HISTORY · 버전 줄 · 명세 ② 의 테스트 이름 | `4dabf83` · `04e86b3` | 닫음 |
| T07 | 명세 9절 task 07 | deploy.sh 로 배포 · 새 세션 smoke | | 열림 |


## 고장 내기

| 불변식 | 테스트 | 고장 낸 곳(file:line · 바꾼 내용) | 실패 메시지 첫 줄 | 되돌린 뒤 통과 |
|--------|--------|-----------------------------------|-------------------|----------------|
| 넷째 칸 `-` 는 빈 칸 | test_rq_p05… | hooks/state-lib.sh:430 · `blank()` 에서 `|| s == "-"` 삭제(메인 — 저장소 밖 사본 · cmp 확인) | 닫음 줄의 VIOLATION 출력이 사라짐(직접 호출로 확인) | 원본에서 `VIOLATION T01 6` |
| (구현 워커 packet) 빈 칸에서 `-` · 표지 부분 일치 · `head -c 65536` · `\r` trim 제거 · 빈 줄 건너뛰기 제거 | 해당 test_rq_ | 저장소 밖 사본 | 다섯 모두 해당 테스트 실패 | 33/33 |

## 리뷰 ledger

준비 차례(1 · 2)는 리뷰를 돌리지 않았다. 아래는 구현 차례.

- review packet: t01 루프 1 — base `77ba594` / 리뷰한 SHA `0b87e2d` / `$OUT` = `…/scratchpad/rv/t01-l1` / 미러 = 같은 폴더 `mirror/`
- review packet: t01 루프 2 — base `77ba594` / 리뷰한 SHA `1a5db40` / `$OUT` = `…/scratchpad/rv/t01-l2`
- review packet: t05 루프 1 — base = `d38839a` 사본(`harness-t05/base`) / 리뷰한 상태 = 사본 `harness-t05/copy`(git 밖 — 게이트가 닫혀 있어 커밋 전) / `$OUT` = `…/scratchpad/rv/t05-l1`
- review packet: t04 루프 2(좁게) — base `38c2d23` / 리뷰한 SHA `1257b33` / `$OUT` = `…/scratchpad/rv/t04-l2`
- review packet: t04 루프 1 — base `6e6b70c` / 리뷰한 SHA `38c2d23` / `$OUT` = `…/scratchpad/rv/t04-l1`
- review packet: t03 루프 3(좁게) — base `69dce52` / 리뷰한 SHA `2b6fb33` / `$OUT` = `…/scratchpad/rv/t03-l3`
- review packet: t03 루프 2(좁게) — base `a5a8c2c` / 리뷰한 SHA `69dce52` / `$OUT` = `…/scratchpad/rv/t03-l2`
- review packet: t03 루프 1 — base `f6101f3` / 리뷰한 SHA `a5a8c2c` / `$OUT` = `…/scratchpad/rv/t03-l1`
- review packet: t01 루프 8(좁게 — 이번 삭제와 닿는 곳만) — base `979e8a2`(delta) · 누적 `77ba594` / 리뷰한 SHA = 수 대조 삭제 커밋 / `$OUT` = `…/scratchpad/rv/t01-l8`
- review packet: t01 루프 7 — base `77ba594` / 리뷰한 SHA `979e8a2` / `$OUT` = `…/scratchpad/rv/t01-l7`
- review packet: t01 루프 6 — base `77ba594` / 리뷰한 SHA `b693e1d` / `$OUT` = `…/scratchpad/rv/t01-l6`
- review packet: t01 루프 5 — base `77ba594` / 리뷰한 SHA `065edb3` / `$OUT` = `…/scratchpad/rv/t01-l5`
- review packet: t01 루프 4 — base `77ba594` / 리뷰한 SHA `8c4739c` / `$OUT` = `…/scratchpad/rv/t01-l4`
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
| t01-13 | 01 | 3 | opus | task-units.md:45 끝 · :49 — "표의 넘긴 곳이 근거다"가 메인이 묻지 않고 적은 넘김으로도 리뷰 지적을 기각하게 함(:49 는 "명세가 배정한 일"만) | 코드로만 확인 — ① 문서 | 검증 | 반드시 필요 | 채택 — (3) 루프 1 의 문장이 냄 · (4) 사고의 꼴(자기 선언으로 닫음)을 되살림 | fixed | 3 |
| t01-14 | 01 | 3 | opus | templates/log.md:24 · work-records.md:37 — 쓰는 법이 템플릿에 다시 쓰이고 work-records 가 쓰는 법의 정본을 템플릿이라 가리킴(이미 갈라짐 — 넘김 칸 · 다시 열기 · 묻기 · 워커 대조 · 긴급) | 코드로만 확인 — ① 문서 | 문서 | 하면 좋다 | 채택 — (3) 이번 변경 · (4) 명세 2절 단일 출처 | fixed | 3 |
| t01-15 | 01 | 3 | opus | task-units.md:45 — 명세가 없는 긴급 수정의 log 에서 T1 의 요구를 어디서 옮기나 없음 | 미실행 — 후보 | 검증 | 하면 좋다 | 후보 — 명세가 정하지 않은 경우(긴급 경로의 요구 출처) · 긴급은 이미 "알림만 · 빚" 이고 표를 안 쓰면 훅은 조용하다 → NEXT | closed | |
| t01-16 | 01 | 4 | opus | task-units.md:45 · templates/log.md:32 — "옮긴 줄 수"를 표 줄로 세면 원문 한 줄을 빠뜨리고 다른 줄을 나눠도 `7 / 7` | 코드로만 확인 — ① 문서 | 검증 | 반드시 필요 | 채택 — (4) 사고 4번(잘린 읽기)을 드러내려고 둔 수가 아무것도 잡지 못함 | fixed | 4 |
| t01-17 | 01 | 4 | opus | task-units.md:45 — 명세가 배정하지 않은 다른 task 로 옮기기를 묻는지 세 문장이 다르게 읽힘 | 코드로만 확인 — ① 문서 | 검증 | 하면 좋다 | 채택 — (3) 루프 3 고침과 어긋남 · core §1(검증 강도를 낮추는 것은 묻는다) | fixed | 4 |
| t01-18 | 01 | 4 | codex | task-units.md:45 · spec 2절 — 명세 ② 의 작업 전체 불변식이 task 의 표에 옮겨지지 않을 수 있음 | 미실행 — 기각 | 계약 | 있으면 좋다 | 기각 — (1) 작업 전체의 불변식은 이미 다른 겹이 본다: task-units §3 마지막 확인("작업 전체의 목표와 불변식이 지켜졌는가") · 명세 ② 의 "불변식 → 지키는 테스트" 표(testing.md §1). 요구 대조는 task 의 요구(9절 칸 · 계약 문서)를 맡는다 | closed | |
| t01-19 | 01 | 5 | opus | task-units.md:40,45 · core.md:75 — 요구 대조가 검증 뒤라 닫을 때 메운 구현이 그 task 의 강도로 검증되지 않고 닫힌다(:50 · :53 에는 "고친 곳만 다시 확인"이 있는데 여기엔 없음) | 코드로만 확인 — ① 문서 | 검증 | 반드시 필요 | 채택 — (4) 이 방어선이 막으려던 경우(빠진 요구)에서 바로 검증이 빠짐 | fixed | 5 |
| t01-20 | 01 | 5 | opus | task-units.md:45 · templates/log.md:32 — "원문의 줄 수"(분모)의 정의가 없음 | 코드로만 확인 — ① 문서 | 검증 | 하면 좋다 | 채택 — (3) 루프 4 고침(분자만 정함)의 빈틈 | fixed | 5 |
| t01-21 | 01 | 7 | opus | task-units.md:45 — "그 task 에 배정된 줄"로 원문 줄 수를 좁히자 메인이 혼자 "배정 아님"으로 뺀 줄이 개수 대조와 넘김 물음을 모두 지나감(사고 ② 의 꼴) | 코드로만 확인 — ① 문서 | 검증 | 반드시 필요 | 채택 → 설계를 되돌림 — 풀림 — 수 대조를 뺐다(사용자의 답). "배정 아님"으로 뺀 줄이 지나가는 개수 대조 자체가 없고, 빠진 원문 줄은 끝까지 읽기 · 큰 표의 워커 대조가 맡는다 | fixed | 7 |
| t01-22 | 01 | 7 | opus | task-units.md:45 — 계약 문서가 있을 때 명세 칸의 요구가 원문 줄 수에 드는지 두 갈래 | 코드로만 확인 — ① 문서 | 검증 | 하면 좋다 | 채택 → 설계를 되돌림 — 풀림 — 원문 줄 수가 없어졌다 | fixed | 7 |
| t01-23 | 01 | 7 | codex | task-units.md:45 — 넘겨받은 줄은 받는 task 의 원문 줄 수와 맞출 기준이 없음 | 코드로만 확인 — ① 문서 | 검증 | 하면 좋다 | 채택 → 설계를 되돌림 — 풀림 — 받는 task 의 줄 수를 맞출 일이 없어졌다 | fixed | 7 |
| t01-24 | 01 | 8 | opus | task-units.md:45 — 남은 "거른 출력으로 줄을 세지 않는다"가 '세기'만 막는 것으로 읽힐 수 있음 | 미실행 — 기각 | 문서 | 있으면 좋다 | 기각 — 바로 앞 구절 "그 절을 Read 로 끝까지 읽고 옮기며"가 같은 행동을 막는다(리뷰어도 실제로 잘못 행동할 가능성 낮음으로 봄) — 읽는 사람의 행동이 달라지지 않는 문구(메인 지시: 취향의 문구는 기각) | closed | |
| t03-1 | 03 | 1 | opus | hooks/state-lib.sh:432(:416 주석과 다름) · req-check.sh:73-86 — 코드 펜스(``` · ~~~) 안의 표지 줄을 진짜 표지로 읽음 → 진짜 표의 닫음 빈 칸을 놓치거나(조용한 통과) 펜스 안 예시의 꼴로 판정 불가(차단) | 실행 — `a5a8c2c` · opus-run/work/fence.sh · f1 rc=0 `OPEN T4 1 1`(기대 VIOLATION T01) · f2 rc=1 | 데이터 | 반드시 필요 | 채택 — (3) 이번 코드 · (4) 2절 "놓치지 않음" · 이 작업의 명세 6.1 ① 예시가 바로 그 꼴 | fixed | 1 |
| t03-2 | 03 | 1 | codex | hooks/state-lib.sh:435 — 칸만 있는 `|   |   |…|` 를 구분 줄로 받아 빈 표 · rc 0 | 실행 — 메인 · `a5a8c2c` 사본 · rc=0 출력 없음(기대 rc 1) | 계약 | 반드시 필요 | 채택 — (4) 2절 "표지가 있는데 꼴이 틀리면 막는다" | fixed | 1 |
| t03-3 | 03 | 1 | codex | hooks/state-lib.sh:436 — 구분 줄 바로 아래 첫 본문 줄의 앞 `|` 가 빠지면 표가 거기서 끝나 rc 0 · 출력 없음(닫음 빈 칸을 놓침) | 실행 — 메인 · `a5a8c2c` 사본 · rc=0 출력 없음 | 계약 | 반드시 필요 | 채택 — (4) 조용한 놓침 · 쓰는 중 흔한 한 글자 누락 | fixed | 1 |
| t03-4 | 03 | 1 | opus | req-check.sh — "표지 + 머리 줄, 파일 끝"을 보는 사례가 없어 `st < 3` → `st < 2` 고장이 통과 | 코드로만 확인 — ② 테스트 공백 | 검증 | 하면 좋다 | 채택 — (2) 그 꼴이 차단에서 통과로 바뀌어도 테스트가 모름 | fixed | 1 |
| t03-5 | 03 | 2 | opus | hooks/state-lib.sh:437,459 · req-check.sh:531(p30c) — 닫히지 않은 펜스 뒤에 보통 코드 블록이 하나라도 있으면 짝이 뒤집혀 `fmark=0` → rc 2(검사가 조용히 꺼짐) | 실행 — `69dce52` · rvcase/A.md · mawk 1.3.4 · gawk 5.3.0 모두 rc=2(대조 B.md 는 VIOLATION) | 검증 | 반드시 필요 | 채택 → 설계를 되돌림(사용자의 답 — 펜스를 세지 않고 표지는 하나) | fixed | 2 |
| t03-6 | 03 | 2 | opus | hooks/state-lib.sh:436,438 — 줄 앞 백틱 셋으로 시작하는 인라인 코드(```` ```rm -rf``` ````)를 펜스로 셈 → 짝이 뒤집혀 조용히 꺼지거나(rc 2) 오탐(rc 1) | 실행 — rvcase/C.md · E.md rc=2 · D.md rc=1 | 검증 | 반드시 필요 | 채택 → 설계를 되돌림(사용자의 답 — 펜스를 세지 않고 표지는 하나) | fixed | 2 |
| t03-7 | 03 | 2 | codex | hooks/state-lib.sh:436-439,458-460 — 열린 ```` ```text ```` 안의 ```` ```sh ```` 를 닫는 줄로 보아 표지 기록을 지움 → rc 2 | 코드로만 확인(같은 원인 — t03-5) | 검증 | 반드시 필요 | 채택 → 설계를 되돌림(사용자의 답 — 펜스를 세지 않고 표지는 하나) | fixed | 2 |
| t03-8 | 03 | 3 | opus | (참고) 파일 머리 BOM · NBSP 가 붙은 표지 줄은 표지로 안 봐 rc 2 | 미실행 — 후보 | 검증 | 있으면 좋다 | 후보 — (2) 경로는 있으나 트리거가 현실에 드묾(log 는 Claude 의 Write · Edit · 셸이 쓰고 BOM 을 붙이지 않는다) → NEXT | closed | |
| t04-1 | 04 | 1 | opus · codex | hooks/gate-guard.sh:399 · state-lib.sh:484,505-507 — 사이드카가 손상되면 모든 L1 쓰기가 막히는데 푸는 길이 "표를 고친다" 하나뿐(사이드카는 상태 디렉토리 — 모델이 Edit/Write/Bash 로 고칠 수 없다) | 잠재 — `38c2d23` · probe/p5.sh(심링크 · 상대 경로 줄 · 디렉토리 → exit 2 · 안내가 틀림) | 가용성 | 반드시 필요 | 채택 — (4) 명세 6.1 ③ "오탐일 때 푸는 길" · 손상은 task 05 의 쓰는 쪽 결함이나 손으로만 닿지만 닿으면 세션 전체가 멈춤 | fixed | 1 |
| t04-2 | 04 | 1 | opus · codex | hooks/gate-guard.sh:400-406 · spec 6.1 ② — DEBT=1 일 때 stderr 한 줄이 없음(명세는 stderr 한 줄 + additionalContext) | 실행 — probe/p1.sh h · i2 stderr 0바이트 | 계약 | 하면 좋다 | 채택 — (4) 명세와 다름 · 한 줄이라 코드를 명세에 맞춘다 | fixed | 1 |
| t04-3 | 04 | 2 | codex | hooks/gate-guard.sh:409,413 — DEBT=1 에서 jq 가 실패하면 stderr 가 두 줄(요약 줄 + 실패 경고) | 미실행 — 기각 | 계약 | 있으면 좋다 | 기각 — 명세의 "stderr 한 줄"은 정상 경로의 알림이고, 둘째 줄은 jq 실패를 드러내는 경고(core §4 "실패를 드러내기") — 읽는 사람의 행동이 달라지지 않는다 | closed | |
| t05-1 | 05 | 1 | 구현 워커 · opus | req-check-writer.sh — "같은 폴더 재진입이면 사이드카 경고가 없다"를 지키는 assert 가 없음(`seen_rc = 0` 갈래를 고장 내도 39 통과 — 경고 한 줄만 늘어남) | 실행 — 구현 워커 고장 · Opus 가 재진입 3회 stderr 0 확인 | 검증 | 있으면 좋다 | 후보 — 동작은 맞고(실행 확인) 테스트 공백 · 경고가 늘어도 막히지 않음 → NEXT | closed | |
| t02-3 | 02 | 2 | opus(L2-1) | README.md:179 · settings.json — 저장소의 `settings.json` 사본에 detect-layer 등록이 없다(여덟) | 미실행 — 후보: 원래 있던 것 | 문서 | 하면 좋다 | 후보 — (3) 이번 변경 전부터 있던 것 · 이미 후보(`docs/plans/2026-11-20/review-triage/replay.md:13` · NEXT N8) | closed | |
| t02-4 | 02 | 2 | opus(L2-2) | README.md:188 — 옮기면서 detect-layer 사이드카가 세션별(`<sid>.events`)이라는 말이 빠짐 | 코드로만 확인 — ① 문서 | 문서 | 있으면 좋다 | 채택 — (4) 옮김 대조(옮긴 뒤 위치가 빈 것 0) | fixed | 2 |
| t02-c1 | 02 | 1 | codex(D1) · opus(2) | src/core.md:111 · hooks/deploy.sh:18 — README 는 배포되지 않아 다른 프로젝트 세션에서 가리킴이 풀리지 않음 | 미실행 — 기각 | 계약 | 있으면 좋다 | 기각 — (1) 사용자가 이 옮김을 골랐다(분기 Q4) · core 는 이미 README 를 가리킨다(§0.2 "세는 법 = README" · §5 "README '실측' 절") — 같은 설계. 훅 목록은 모델이 따를 행동이 아니라 색인이고 행동 규칙은 core §1 · §6 · §7 에 남음 | closed | |
| t02-c2 | 02 | 1 | codex(D2) · opus(1) | README.md:179-192 · src/core.md:111 — README 의 `hooks/` 트리에는 라이브러리 · CLI · 배포 · 테스트도 같이 있어 "활성 훅"의 구분이 사라짐 | 코드로만 확인 — ① 문서 | 문서 | 하면 좋다 | 채택 — (4) 옮김 대조(명세 2절 — 옮긴 뒤 위치가 빈 것 0)에서 "활성"이라는 구분이 옮겨지지 않음 | fixed | 1 |

- verified — t02 루프 3(신규 채택 0 · 두 리뷰어 모두 지적 없음): 네이밍 / README.md:179 ↔ hooks/*.sh / 훅 이름 아홉을 파일명과 대조 / opus · codex · 완전성 / packet-diff.md:77 → README.md:180-190 · src/core.md:111 → README.md:150,179 / 옮김 대조 빈 칸 0 · 가리킴 이어짐 / opus · codex · 통합 / hooks/deploy.sh:6,18,179 ↔ README.md:179,222 / 등록 위치 · 배포 제외 서술이 맞음 / opus · codex · 설계 품질 / src/core.md:111 / 단일 출처 / opus · codex · 과잉 구현 / src/core.md:111 / 줄이 짧아짐 / opus. 비적용(API · 메서드 · 쿼리 · 동시성 — 문서). 비대칭 없음 → **t02 리뷰 종료**.
- verified — t01 루프 6(신규 채택 0 · 두 리뷰어 모두 지적 없음): API 단위 / templates/log.md:25-26 · task-units.md:45 · core.md:75 / 표가 조용히 무시되는 경로(둘째 표 · 표 밖 줄 · 표지 리터럴) · 꼴이 틀리면 막힘 · 긴급은 알림 / opus · codex · 메서드 내부(절차 흐름) / task-units.md:40,45,52,53 / 검증 앞 대조 → 재확인 → 메운 diff 재검증 / opus · codex · 네이밍 / templates/log.md:26,28-29,32 ↔ spec 6.1 ① / 표지 · 머리 줄 · 상태 값 · `T01` / opus · codex · 완전성 / task-units.md:26,45,53 · requirement-spec.md:98 / 넘김 · 다시 열기 · 워커 대조 · 기각 조건 · 마감 / opus · codex · 통합 / templates/log.md:5,25 · work-records.md:37 · task-units.md:45,61 · core.md:75,115 / 앞서는 쪽이 문장에 있음 / opus · codex · 설계 품질 / templates/log.md:24 · task-units §3 / 단일 출처 / opus · codex · 과잉 구현 / templates/log.md:24 / 되풀이 없음 / opus · codex. 비적용(쿼리 · 동시성 — 문서). 비대칭 없음 → **t01 리뷰 종료**(루프 6 — 사용자의 답대로 3 을 넘겨 계속함).
- verified — t03 루프 3(신규 채택 0 · 두 리뷰어 지적 없음): 메서드 내부 / hooks/state-lib.sh:430-466 / 펜스 코드 없음(grep) · 표지 줄 수를 모든 줄에서 셈 · END 에서 표지 둘 이상이 꼴 틀림보다 앞섬 / opus(실행) · codex · 이식성 / mawk · mawk C · gawk 5.3.2(docker) · gawk C 에서 test_rq_ 44/44 / opus · 문서 / templates/log.md 두 구절 ↔ 구현 / opus · codex. → **t03 리뷰 종료**.
- verified — t04 루프 2(신규 채택 0): 고친 두 곳 / hooks/gate-guard.sh:389,400-401,409 / 사이드카 경로가 findings 의 where 와 글자 그대로 같음 · 고장 두 방향(늘 참 · 늘 거짓) 모두 b26 이 잡음 · DEBT stderr 한 줄을 지우거나 수를 고정하면 b27 이 잡음 · 찾은 것이 없으면 출력 종전과 같음(c11) / opus(실행 — 사본 run.sh 530/0/0) · codex. → **t04 리뷰 종료**.
- verified — t05 루프 1(신규 채택 0): 워커 판별 양쪽 / task-mode-guard.sh:43 ↔ gate-guard.sh:365,456 / 상태 바이트 · 사이드카 / opus(실행) · codex · 원자성 · 심링크 · 하드링크 / state-lib remember / 병렬 40회 40줄 · 심링크 rc 2 · 잠금 심링크 rc 1 / opus · 끝에서 끝까지 / 워커 Write → 메인 Write 둘 → gate-guard 가 사이드카로만 닿는 폴더의 위반으로 exit 2 / opus · 종전과 바이트 / legacy-d38839a 와 stderr · rc · 상태 diff 0 / opus · codex. → **t05 리뷰 종료**.

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

## 완료 요약 (구현 차례 — 11-28 12:01)

- 된 것: task 01~06(규칙 문서 · 훅 목록 이동 · 표 파서 · gate-guard 차단과 reinject 알림 · task-mode-guard 의 워커 Write 무시와 사이드카 쓰기 · README · 이력). 마지막 재실행 569 통과 · 0 실패 · 0 건너뜀(기준 436). core 15,370자(상한 15,404) · task-units 80줄. **task 07(배포)은 하지 않았다 — 사용자 확인 뒤.**
- 핵심 diff: core §4 에 "task를 닫기 전 요구 대조(실측 2026-11-27)" 한 줄(지금 `src/core.md:75` 의 글 그대로 — 최종 보고에 실음) · 훅 셋(state-lib · gate-guard · reinject) + task-mode-guard.
- 배운 것: 같은 문장 · 같은 곳을 리뷰마다 고치는 일이 두 번 났다(원문 줄 수 대조 · 코드 펜스 짝 세기) — 둘 다 정지 규칙으로 멈추고 사용자에게 물어 설계를 뺐을 때 수렴했다. 테스트 이름은 영문이어야 한다(`run.sh` 이름 검사). 메인 재실행은 깨끗한 별도 작업 트리에서(TASK_PATH 의 decisions.md 가 hermetic 검사를 깬다).
- 확인하지 않은 것과 알아야 할 위험: 서브에이전트의 PostToolUse(Write) 입력에 agent_id 가 실리는지(Read 는 확인 — 배포 뒤 smoke) · BSD awk · NFS 의 지연 · 펜스 안에 줄 전체 표지 예시를 둔 log 는 막힌다(사용자가 고른 대가).
- 뺀 것과 다시 더할 조건: 원문 줄 수 대조(사용자 — 잘린 읽기에서 함께 틀림) · 코드 펜스 짝 세기(사용자 — 표지는 하나로) · git-guard push 사유에 빈 칸 수(차단 · 알림이 있는데도 빈 칸을 둔 채 push 한 실측이 나오면) · 압축 뒤 재독에 계약 문서(표를 log 에 둔 뒤에도 압축 뒤 요구를 잃은 실측이 나오면) · 검사를 끄는 스위치(두지 않음).
- 더 나은 대안: 없음.
- 이번 변경의 `단순화:` 주석: 없음(펜스 글자 수의 `단순화:` 는 펜스 코드와 함께 지워짐).
- NEXT 로 옮긴 것: `docs/plans/NEXT.md` N15.
