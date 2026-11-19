# 요구사항 명세서 — 결정 기록 아카이브 · 압축 뒤 재독 강제 · 고정 지시 재주입

> 작성일: 2026-11-19 · 작업 폴더: `docs/plans/2026-11-19/decision-archive-compact-reread/`
> NEXT.md N5(아웃박스)를 대체한다. 근거 실험: `agent-discipline/compaction-experiment`(Haiku 9회, 2026-11-18~19).

---

## 0. 요구사항 원문 (인터뷰 기록)

- 원문(2026-11-19, 컴팩트 실험 결과를 본 뒤):
  - "우리 의사결정 로그를 남기고 있잖아? 그것만 읽도록 강제함으로 써 해당 맥락을 관리할 수 있을꺼고, 대화에만 남은 지시사항들에 대해서 로그로 기록하도록 강제하는게 맞겠네. 그리고 셀렉트박스로 인한 질문과 그에 대한 답변을 아카이브하는쪽으로 가는게 나을 꺼 같네."
  - "1,2,3 진행하고 컴팩트는 크게 의식할 이유 없이 이후 해당 내용을 읽으며 맥락을 파악하는 쪽으로 신경을 쓰게 하면 되는거네 … 하네스 개선 진행하자. 한국어로 응답하도록 위 3개의 단계를 진행해보자."
- Q/A(질문 도구, 2026-11-19):
  - 선택 질문과 답을 남길 곳 → "작업 폴더에 decisions.md". 작업 폴더가 아직 없을 때의 답은 세션 임시 파일에 쌓았다가 작업 폴더가 생기면 옮긴다.
  - 압축 직후 무엇을 넣을까 → 사용자 답(원문): "이때 맥락 압축 직후 이 맥락이 압축되었는지 안되었는지 이걸 어떻게 알 수 있어? 내부 플래그 값이 있다면 맥락압축 후 해당 시간을 기록하고, 압축을 다시되었을때 기록과 내용을 읽은 시간이 안맞는다면 한번 더 읽고 기록 시간을 현재시간으로 쓰는게 좋지않나."
    - 메인의 답: 압축 여부는 훅이 안다. 압축 직후 SessionStart 훅이 `source=compact`로 호출된다(이 세션에서도 압축 때마다 그 훅이 돈 것을 확인). 그래서 사용자 안대로 한다 — 압축 시각과 읽은 시각을 기록하고, 읽은 시각이 압축 시각보다 앞이면 다시 읽게 한다.
  - 계속 지켜야 하는 행동 지시(응답 언어 등) → "상시 문서 + 매 턴 한 줄 재주입".
  - 확인 방법 → "훅 테스트 + Haiku 확인 실행 3회".
- 실험 근거(compaction-experiment, Haiku, 조건당 3회): 압축 10~14회 뒤에도 코드로 옮겨진 결정과 코드 쪽 제약은 전부 유지. 대화에만 있던 지시(한국어 응답)는 3/3 소실. 압축 직후 원문을 한 번 다시 주입하는 방식(아웃박스)도 3/3 소실.

---

## 1. 목표·대상 (필수)

하네스 저장소(`agent-discipline/harness`)의 훅과 core.md에 세 가지를 넣는다.

1. **선택 질문 아카이브**: AskUserQuestion의 질문·선택지·답을 훅이 작업 폴더의 `decisions.md`에 자동으로 붙인다.
2. **압축 뒤 재독 강제**: 압축이 일어나면 그 시각을 기록하고, 그 뒤로 작업 폴더의 기록(명세서·log·decisions.md)을 읽기 전까지 L1 쓰기를 막고 매 턴 읽으라고 알린다. 읽으면 읽은 시각을 기록해 해제한다.
3. **고정 지시 재주입**: 응답 언어처럼 계속 지켜야 하는 지시를 설정 파일 하나에 두고, 매 턴 재주입 훅이 그 내용을 함께 넣는다. 대화에서 나온 행동 지시는 그 파일에 올린다는 절차 규칙을 core.md에 추가한다.

끝의 기준: 훅 테스트 통과 + 배포 + 새 세션 smoke + Haiku 확인 실행 3회에서 압축 뒤 한글 비율이 대조군 수준(K8 통과)인지 측정해 결과를 기록한다. 측정 결과가 "유지 안 됨"이어도 작업은 끝이고, 그 결과를 README 실측 절과 NEXT에 적는다.

## 2. 경계·불변식 (필수)

- **I1 아카이브 완전성**: AskUserQuestion이 답을 받아 끝난 호출마다 질문 원문·선택지 라벨·사용자의 답(자유 서술 포함)·시각이 한 묶음으로 남는다. `TASK_PATH`가 있으면 `<TASK_PATH>/decisions.md`에, 없으면 세션 사이드카에 쌓고, `TASK_PATH`가 생긴 뒤 첫 기록 때 사이드카분을 순서대로 옮긴다(중복·유실 없음).
- **I2 훅 전용 파일**: `decisions.md`는 훅만 덧붙인다(append-only). 훅은 명세서·log를 쓰지 않는다.
- **I3 압축 시각 기록**: SessionStart `source=compact`에서 상태에 압축 시각을 기록한다. 다른 source(startup·resume·clear)의 종전 동작은 바뀌지 않는다.
- **I4 재독 판정**: "읽음" = 압축 시각 뒤에 Read 도구로 작업 폴더의 대상 파일을 읽은 것. 대상 = `TASK_PATH`의 `requirement-spec.md`·`log.md`, 그리고 있으면 `decisions.md`. 대상 전부를 읽어야 해제된다. 압축이 다시 일어나면 다시 미독 상태가 된다.
- **I5 미독 중 강제**: 미독 상태에서는 ①매 턴 재주입에 "압축 뒤 작업 기록을 아직 읽지 않았다 — 파일 경로"가 들어가고 ②gate-guard가 L1 쓰기(Edit/Write)를 막는다(차단 문구에 읽을 파일 경로). L0 쓰기(`docs/**`)와 Read는 막지 않는다. `TASK_PATH`가 없으면(작업 폴더 없는 세션) 재독 강제는 걸지 않는다.
- **I6 고정 지시**: 설정 파일(전역 1개, 줄 단위 지시)이 있으면 매 턴 재주입 출력에 그 내용이 들어간다. 파일이 없거나 비면 종전 출력 그대로. 길이 상한을 넘으면 잘라 넣고 잘렸음을 표시한다.
- **I7 실패 방향**: 새 훅 로직의 내부 오류는 종전 훅 원칙을 따른다 — 아카이브·기록 실패는 경고만 하고 도구 사용을 막지 않는다(관측 훅). 재독 차단은 "미독"이 상태에서 확실히 읽힐 때만 건다(상태를 못 읽으면 종전 게이트 판정만 적용 — 새 차단을 추가로 걸지 않는다).
- **I8 기존 계약 보존**: SPEC/MODE 게이트, DEBT, PENDING_GATE, task-mode-guard 리셋, 상태파일 SCHEMA 호환(기존 상태파일을 손상으로 보지 않음), 기존 테스트 전부 통과.
- **I9 사용자 내용 보호**: 사이드카와 `decisions.md`에 들어가는 것은 질문 도구의 질문·답뿐이다. 자유 프롬프트 원문은 이번 범위에서 쌓지 않는다.

## 3. 기준소스 (필수)

- 하네스 저장소 `main`의 현재 훅(`hooks/*.sh`, `hooks/tests/`), `src/core.md`, `README.md`.
- Claude Code 훅 계약은 공식 문서와 실제 호출로 확인한다(§8 가정).
- 확인 실행의 기준: compaction-experiment의 K8 채점 규칙과 Haiku 대조군 3회(압축 없음, 한글 비율 0.93).

## 4. 금지영역 (필수)

- `~/.claude/settings.json`은 훅 등록에 필요한 항목만 고친다. **고치기 전 사용자 확인**, 고치기 전 백업. 다른 설정은 건드리지 않는다.
- 배포는 `hooks/deploy.sh` 경유만.
- 기존 훅의 차단 범위를 넓히는 변경은 I5 하나뿐이다. git-guard·codex-scan은 손대지 않는다.
- compaction-experiment의 기존 실행 기록·과제 입력은 고치지 않는다(확인 실행은 새 조건으로 덧붙임).
- push·PR은 사용자 확인 뒤. main 직접 커밋 금지(작업 브랜치).

## 5. 검증 방법 (필수)

- 훅 테스트(`hooks/tests/run.sh`): I1~I9마다 케이스. 테스트 설계는 구현 diff를 보지 않는 별도 워커(높음 stakes).
- 설계 선검증: I4·I5(새 동작 불변식)를 구현 전에 기존 강제 위치와 대조.
- 듀얼 리뷰 루프(Opus 워커 ∥ codex, 최대 3회) + 보안 스캔.
- 배포(`deploy.sh`) → 새 세션 smoke: ①질문 도구 답이 `decisions.md`에 붙는가 ②수동 압축 뒤 미독 상태에서 L1 쓰기가 막히고, 세 파일을 읽으면 풀리는가 ③고정 지시가 매 턴 들어가는가.
- Haiku 확인 실행 3회(compaction-experiment 도구, 새 조건): 고정 지시 재주입을 넣은 상태에서 압축 뒤 한글 비율과 K8. 결과는 그대로 기록한다.

## 6. stakes (필수)

- 판정: **높음** — 훅·정책 변경(하네스 실행 정책), 모든 세션에 적용, 차단 범위 확대(I5).

---

## 7. 자율성 (모드 — stakes와 별개 축)

- [ ] auto (기본 권장 — 합의 후 Claude 자율 실행)
- [ ] lazy (매 diff 이해 게이트 — 학습·OSS 기여)

## 8. load-bearing 가정 (1~2개)

1. PostToolUse 훅이 AskUserQuestion 호출에서 불리고, stdin의 `tool_input`(질문·선택지)과 `tool_response`(사용자의 답)를 받는다 — 착수 직후 임시 훅으로 실제 호출을 받아 확인한다. 안 되면 대안(세션 기록 파일에서 읽기)을 사용자에게 보고하고 정한다.
2. PostToolUse 훅이 Read 호출에서 불리고 `tool_input.file_path`를 받는다(재독 판정의 토대) — 같은 스모크에서 확인.

## 9. task 분해

| task | 목표 | 의존 | acceptance |
|------|------|------|-----------|
| 01 | 가정 1·2 실증(임시 훅, 이 저장소 밖 설정으로) | — | 실제 stdin JSON 표본 확보 |
| 02 | 테스트 설계(I1~I9, 구현 미열람 워커) | 01 | 케이스 목록·실패 확인 |
| 03 | 구현: 아카이브 훅 · 압축 시각/재독 상태 · gate-guard 차단 · 재주입 확장 · core.md 절차 규칙 | 01 | 테스트 통과 |
| 04 | 듀얼 리뷰 루프 · 보안 스캔 | 03 | open finding 0 |
| 05 | 배포 · settings 등록(사용자 확인) · 새 세션 smoke | 04 | smoke 3항목 |
| 06 | Haiku 확인 실행 3회 · 결과 기록(README 실측, NEXT) | 05 | 측정 결과 기록 |

## 10. 인터페이스 계약 (2026-11-19 메인 — 테스트 설계와 구현이 함께 보는 정본)

task 01 실증(2026-11-19, 실제 세션의 임시 훅 덤프 — 원본 표본은 이 폴더 `probe/`):
- PostToolUse는 `AskUserQuestion`에서 호출된다. stdin에 `tool_input.questions[]`(`question`·`header`·`options[].label`·`options[].description`·`multiSelect`)와 `tool_response.answers`(질문 원문 → 고른 라벨 또는 자유 서술 문자열의 맵), `tool_response.annotations`가 온다. `tool_input.answers`에도 같은 맵이 있다.
- PostToolUse는 `Read`에서 호출된다. `tool_input.file_path`(절대 경로)·`offset`·`limit`이 온다.
- 공통 필드: `session_id`, `cwd`, `hook_event_name`, `tool_name`, `tool_use_id`, `transcript_path`, `permission_mode`. 서브에이전트 안의 호출에는 `agent_id`·`agent_type`이 붙는다(공식 문서).
- SessionStart의 `source` 값: `startup`·`resume`·`clear`·`compact`·`fork`. 자동·수동 압축 모두 `compact`(공식 문서, 이 세션에서도 압축 때마다 호출됨). 훅 stdout은 1만 자까지 맥락에 들어간다.

파일과 위치(상태 디렉토리 = `state_resolve_dir` 결과, 세션 id = `<sid>`):

| 대상 | 경로 | 쓰는 훅 | 형식 |
|---|---|---|---|
| 결정 기록(작업 폴더) | `<TASK_PATH>/decisions.md` | `capture-decision.sh` | 아래 "기록 형식" 블록을 끝에 덧붙임. 파일이 없으면 제목 줄 `# decisions — 선택 질문과 답 (훅이 자동 기록)`과 빈 줄을 먼저 씀 |
| 결정 기록(작업 폴더 없을 때) | `<state_dir>/<sid>.decisions` | `capture-decision.sh` | 같은 블록을 쌓음. `TASK_PATH`가 생긴 뒤 첫 기록 때 이 파일 내용을 `decisions.md` 끝에 먼저 옮기고 파일을 지운 다음 새 블록을 붙임 |
| 압축 시각 | `<state_dir>/<sid>.compact` | `session-mode-guard.sh`(`source=compact`) | 한 줄: epoch 초 |
| 읽은 시각 | `<state_dir>/<sid>.reread` | `reread-track.sh` | 줄마다 `<epoch>\t<canonical 경로>` — 대상 파일을 읽을 때마다 그 경로의 줄을 최신 시각으로 교체 |
| 고정 지시 | `$HOME/.claude/standing-instructions.md` | 사용자(훅은 읽기만) | 일반 텍스트. `#`으로 시작하는 줄과 빈 줄은 주석으로 보고 넣지 않음 |

기록 형식(한 번의 AskUserQuestion 호출 = 한 블록, 질문이 여러 개면 한 블록 안에 차례로):

```
## <YYYY-MM-DD HH:MM:SS> (<tool_use_id>)

### <header>
- 질문: <question 원문 — 줄바꿈은 공백으로>
- 선택지: <label 1> / <label 2> / …
- 답: <answers[question] 원문>
```

- 같은 `tool_use_id`의 블록이 이미 있으면 다시 쓰지 않는다(중복 호출 방지).
- `tool_response.answers`가 없거나 비면(사용자가 답하지 않고 끝난 호출) 기록하지 않는다.
- 서브에이전트 안의 호출(`agent_id` 있음)도 기록한다(질문과 답은 사용자 결정이다).

재독 상태의 정의:
- 대상 파일 = `<TASK_PATH>/requirement-spec.md`, `<TASK_PATH>/log.md`, 그리고 판정 시점에 존재하면 `<TASK_PATH>/decisions.md`. 존재하지 않는 대상은 읽은 것으로 본다.
- **미독** = `<sid>.compact`가 있고 `TASK_PATH`가 비어 있지 않으며, 대상 파일 중 하나라도 `.reread`에 압축 시각 **이상**의 시각으로 기록돼 있지 않은 상태. `.compact`가 없으면 미독이 아니다.
- `reread-track.sh`(PostToolUse `Read`)는 `agent_id`가 없는 호출(메인)만 기록한다. `file_path`를 canonical 경로로 바꿔 대상 파일과 일치할 때만 기록한다. `offset`·`limit`이 있는 부분 읽기도 읽은 것으로 본다(전부 읽었는지는 훅이 알 수 없다 — 한계로 README에 적음).
- 압축이 다시 일어나면 `.compact`의 시각이 새로 써져 다시 미독이 된다.

미독 중 동작:
- `gate-guard.sh` PreToolUse(Edit·Write·MultiEdit): 대상이 L1로 분류되고 호출에 `agent_id`가 없으며 미독이면 exit 2. stderr 문구는 `[gate-guard] 압축 뒤 작업 기록 미독 — 다음 파일을 Read 한 뒤 다시 시도:`로 시작하고 아직 읽지 않은 대상 파일의 절대 경로를 줄마다 적는다. 이 차단은 기존 SPEC/MODE 판정보다 **뒤**에 본다(종전 차단 사유가 있으면 그 사유가 먼저). L0 쓰기, Read, Bash는 막지 않는다. 미독 여부를 판정할 수 없으면(사이드카 읽기 실패 등) 이 차단을 걸지 않는다.
- `reinject-mode.sh`(UserPromptSubmit): 미독이면 `[게이트] 압축 뒤 작업 기록 미독 — 구현 파일 쓰기 전에 Read:` 한 줄과 읽지 않은 대상 경로를 넣는다. 종전 출력 뒤에 붙인다.
- `session-mode-guard.sh`(`source=compact`): 종전 안내문에 더해 `TASK_PATH`가 있으면 `[게이트] 맥락이 압축됐습니다. 작업 폴더: <TASK_PATH> — requirement-spec.md · log.md · decisions.md를 Read 한 뒤 진행하세요.`를 출력한다.

고정 지시 주입:
- `reinject-mode.sh`는 `standing-instructions.md`가 있으면 유효한 줄들을 `[고정 지시] ` 접두와 함께 출력 끝에 넣는다(상태파일이 없어도, MODE가 UNSET이어도 넣는다). 합쳐 1,500자를 넘으면 1,500자에서 자르고 `…(잘림)`을 붙인다.
- `session-mode-guard.sh`도 모든 `source`에서 같은 내용을 출력 끝에 넣는다(압축 직후에도 다시 들어가게 — 메인 보강: 실험에서 압축은 턴 도중에 일어났고 매 턴 주입만으로는 턴 안의 압축 뒤를 덮지 못한다).
- 파일이 없거나 유효한 줄이 없으면 종전 출력과 바이트 단위로 같다.

등록(`~/.claude/settings.json`, 저장소 사본 `settings.json`): PostToolUse matcher `AskUserQuestion` → `capture-decision.sh`, PostToolUse matcher `Read` → `reread-track.sh`. 나머지는 기존 등록 그대로.

정책 문서: `src/core.md` §6 활성 훅 목록에 두 훅 추가, §7에 `decisions.md`(훅이 쓰는 세 번째 파일)와 세션 재개 시 읽을 대상 추가, 절차 규칙 한 줄("대화에서 나온 계속 지켜야 하는 행동 지시는 `~/.claude/standing-instructions.md`에 올린다 — 사용자 확인 뒤"), 변경 이력 v4.5. `README.md` 훅 표와 한계.

계약 보충(2026-11-19, 테스트 설계 워커의 질문 12건에 대한 메인 결정):
1. 고정 지시는 유효한 줄마다 한 줄씩, 줄마다 `[고정 지시] ` 접두를 붙인다.
2. 1,500자는 접두를 뺀 지시 본문(줄바꿈 포함)의 글자 수로 센다. 1,500자를 넘을 때만 자르고, 자른 뒤 마지막 줄 끝에 `…(잘림)`을 붙인다.
3. 같은 `tool_use_id`의 중복은 `decisions.md`와 사이드카 양쪽에서 본다. 사이드카를 옮길 때도 이미 있는 블록은 다시 쓰지 않는다.
4. 블록과 블록 사이, 한 블록 안의 질문과 질문 사이에 빈 줄 하나. 시각은 로컬 시간.
5. 답에 든 줄바꿈도 공백으로 바꾼다. 여러 개를 고른 답은 받은 문자열 그대로 적는다.
6. `decisions.md`에 쓰지 못하면 사이드카에 쌓고 stderr로 경고한 뒤 exit 0. 다음 기록 때 다시 옮기기를 시도한다.
7. 판정 불가 = `.compact`가 숫자가 아니거나 비었거나 정규 파일이 아님, `.reread`를 읽을 수 없음. 이때 새 차단과 미독 알림을 걸지 않는다. `.reread`가 없는 것은 판정 불가가 아니라 "아무것도 읽지 않음"이다.
8. 시각은 소수 초까지 기록한다(`date +%s.%N`). 비교는 수로 한다. 정수 epoch만 든 기존 형태도 읽을 수 있어야 한다. 같은 값이면 읽은 것으로 본다.
9. Read의 `file_path`가 상대 경로면 stdin의 `cwd` 기준으로 푼다.
10. `clear`·`fork`·`startup`·`resume`은 `.compact`·`.reread`를 건드리지 않는다.
11. gate-guard의 PostToolUse 동작은 바꾸지 않는다. PreToolUse에서 종전 차단 사유(SPEC, MODE, lazy의 PENDING_GATE 등)가 하나라도 있으면 그 문구가 먼저이고 미독 차단은 그 뒤다.
12. compact 안내 줄은 종전 출력 바로 뒤, 고정 지시보다 앞.

---

## 승인 상태

- [x] 필수 6칸 전부 기입 (빈 칸 없음)
- [ ] 사용자 합의 → SPEC=1 (훅 기록 — Claude 직접 편집 금지)
- [ ] 자율성 선택 → MODE 기록
