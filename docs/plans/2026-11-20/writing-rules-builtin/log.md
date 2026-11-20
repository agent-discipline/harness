# log — writing-rules-builtin

## 타임라인

| 시각 | 사건 | 결과/결정 |
|------|------|----------|
| 11-20 12:35 무렵 | 사용자 방향 결정(대화) | rules 저장소는 보류하고 하네스에 규칙을 담는다. "번역체들을 어떻게 다듬고 글을 어떻게 써서 문서를 어떻게 써야하는지에 대한 내용을 빌트인하는게 맞겠네." |
| 11-20 14:35 무렵 | 메인 조사(rules 실파일) | `writing/` 네 문서 520줄(principles 120 · wording-table 248 · work-records 77 · diagrams 75) + `ROUTING.md` 38줄. 하네스에는 낱말 부분의 요약 `playbooks/korean-wording.md`(53줄)만 있음 |
| 11-20 15:05 무렵 | 메인 제안 → 사용자 "진행하자" | 네 문서를 `playbooks/writing/`에 그대로 옮기고 요약본은 없앤다 · 사례 표에 줄을 덧붙이는 일은 게이트 없이 · rules의 `writing/`은 옮겼다는 안내만 남기고 지운다 |
| 11-20 15:54 | 브랜치 `feat/writing-rules-builtin`(기준 `399367f`). 이 log.md를 먼저 생성(Write 도구) | 이후 질문은 이 폴더의 `decisions.md`에 기록 |
| 11-20 15:56 | 메인 조사(하네스 실파일) | `deploy.sh`는 `playbooks/`를 통째로 `~/.claude/playbooks/`에 복사(하위 폴더 포함) · `korean-wording.md`를 가리키는 곳은 `src/core.md` 130행(8절 표)과 141행(변경 이력)뿐, 훅과 테스트에는 없음 · core 8절 머리의 "각 ≤80줄"을 principles(120)와 wording-table(248)이 넘음 |
| 11-20 16:03 | 사용자 합의("합의, 낮음 + auto") → `set-state spec-approved`·`mode auto` | 답은 이 폴더의 `decisions.md`에 기록됨 |
| 11-20 16:04 | 가정 1 확인 — `deploy.sh --dry-run` | 미리보기는 차이 없음만 보여 줘 하위 폴더 복사는 실제 배포에서 확인(16:13 행) |
| 11-20 16:05~16:08 | task 01(메인) — 다섯 문서 복사, `ROUTING.md` 경로와 머리 문단 수정, `korean-wording.md` 삭제, core.md 8절, README 구조 절 | 네 문서 `cmp` 동일 · `ROUTING.md` 변경 9줄(3행 머리 문단, 18~23·25·27행의 `writing/` 접두어 제거) · 링크 깨짐 0 · core.md 143줄 유지. 커밋 `d6b4506` |
| 11-20 16:08~16:10 | task 02 — 대조(Opus 워커, 82k 토큰, 읽기 전용) | 네 문서 동일 확인, 길목 시험 세 경우 모두 찾아갈 수 있음. 문제 3건: ①`wording-table.md:247`의 "이 저장소"가 하네스에 없는 폴더를 가리킴 ②사례를 덧붙일 원본의 위치가 없음(배포본에 덧붙이면 다음 배포 때 사라짐) ③요약본에만 있던 규칙 2개를 잃음(글쓴 모델에게 자기 글을 검토시키지 않는다 · 이미 쓴 커밋 메시지는 고치지 않는다) |
| 11-20 16:11 | 반영(메인) | ①"rules 저장소 `docs/plans/…`"로(I1 ②) ②core.md 새 행과 `ROUTING.md`에 하네스 저장소 원본 위치와 배포본 주의 ③두 규칙과 "작업 기록은 검색 대상 아님"을 `ROUTING.md`의 사례 표 문단 아래에 옮겨 적음(명세 I1에 ④ 추가). 네 문서의 본문은 247행 한 낱말 말고는 그대로. 커밋 `5795a97` |
| 11-20 16:12~16:13 | task 03 — `deploy.sh` → smoke 통과 | 백업 `~/.claude/.deploy-backup-3173328`. `~/.claude/playbooks/writing/`에 다섯 파일, `korean-wording.md` 없음, `diff -rq playbooks ~/.claude/playbooks` 차이 없음, core.md 동기. 가정 1 성립 |
| 11-20 16:15~16:20 | task 04 — rules 저장소 브랜치 `chore/move-writing-to-harness`, 커밋 `b3cb778` | `writing/`·`ROUTING.md` 삭제, README "현재 상태"를 보류 상태와 새 위치 안내로. 기록은 rules `docs/plans/2026-11-20/move-writing-to-harness/` |
| 11-20 16:16 | 관측 — 게이트 상태는 저장소마다 따로 | rules의 README Edit이 SPEC=0으로 막힘(하네스에서 기록한 합의는 하네스 쪽 상태 디렉토리에만 있음). 한 작업이 두 저장소를 고칠 때는 저장소마다 작업 폴더와 상태 기록이 필요하다. rules에 작업 폴더를 만들고 같은 합의를 옮겨 적어 진행. 같은 순간에 낸 rules 커밋이 README 없이 만들어져 amend로 고침 |

## 리뷰 ledger (中↑ — 듀얼 리뷰가 돈 작업 필수)

## 생략한 검증 (긴급 경로 빚 — DEBT=1인 동안 정본)

- 없음.

## 완료 요약 (마감 시)

- **옮긴 것**: rules의 `writing/` 네 문서(원본과 동일)와 `ROUTING.md` → `playbooks/writing/`. 요약본 `playbooks/korean-wording.md` 삭제.
- **core.md 8절의 행**(실파일에서 복사):
  - before: `` | `playbooks/korean-wording.md` | 사람이 읽을 한국어 문서(README·ADR 본문·해설·보고)를 쓰거나 고칠 때 — 지어낸 말·직역·보고서 말투 (작업 원본인 명세서·log·측정 원본은 제외) | ``
  - after: `` | `playbooks/writing/ROUTING.md` | 사람이 읽을 문서(README·ADR·해설·보고·커밋·PR 본문)를 쓰거나 고칠 때 · 작업 기록(명세서·log·NEXT)을 쓸 때 · 문서에 그림을 넣을 때 — 표에서 읽을 문서를 찾는다(…) | ``
- **검증**: 원본과의 `cmp`, 링크 확인, 다른 모델의 대조 1회(문제 3건 반영), 배포 smoke(배포된 훅으로 테스트 376). core.md는 143줄 그대로.
- **리뷰**: stakes 낮음(사용자 지정)이라 듀얼 리뷰 없음. ledger 비움.
- **아카이브**: CS 이슈 0건(문서 이전).

