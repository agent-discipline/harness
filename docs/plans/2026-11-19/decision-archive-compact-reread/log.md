# log — decision-archive-compact-reread

## 타임라인

| 시각 | 사건 | 결과/결정 |
|------|------|----------|
| 11-19 12:10 | 사용자 요청(컴팩트 실험 결과를 본 뒤) — 선택 질문 아카이브, 압축 뒤 기록 재독, 대화 지시의 기록화 | NEXT N5(아웃박스)를 대체하는 방향. 근거 = compaction-experiment Haiku 9회(대화에만 있던 지시 3/3 소실, 원문 재주입도 3/3 소실) |
| 11-19 12:12 | explorer(Sonnet, 102k 토큰) — 훅 구조 조사 | SessionStart에 compact 분기 없음 · `TASK_PATH`는 상태파일에만 있고 spec/log Write 때만 설정 · `capture-prompt`는 한 턴만 덮어쓰고 소비자 없음 · PostToolUse에서 `tool_response`를 읽는 훅 없음 · hooks/는 통째로 배포되나 `~/.claude/settings.json` 등록은 수동 · 테스트 추가 시 `run.sh --lock` 필요 |
| 11-19 12:20 | 인터뷰(질문 도구 4건) | 아카이브 = 작업 폴더 `decisions.md` · 압축 뒤 = 사용자 안(압축 시각과 읽은 시각을 기록해 비교, 안 맞으면 다시 읽기) · 행동 지시 = 상시 문서 + 매 턴 한 줄 재주입 · 확인 = 훅 테스트 + Haiku 3회 |
| 11-19 12:30 | 명세 작성 → 사용자 합의("합의, auto로 진행") | `set-state spec-approved`·`mode auto` 기록(12:38). 명세 Write 때 task-mode-guard가 상태를 리셋한 것 확인(MODE=UNSET → 다시 기록) |
| 11-19 12:45 | task 01 — 훅 stdin 계약을 공식 문서로 확인(claude-code-guide, 87k 토큰) | 문서로 확인: SessionStart `source=compact`(자동·수동 모두), stdout 1만 자 상한, PreToolUse exit 2 차단, 서브에이전트 호출에 `agent_id`. **문서에 없음**: PostToolUse가 AskUserQuestion에서 불리는지, `tool_response` 형태 |
| 11-19 13:00 | 사용자 확인(질문 도구) — 프로젝트 설정(`agent-discipline/.claude/settings.local.json`)에 덤프만 하는 임시 훅 등록 | 실제 호출로 확인: PostToolUse는 AskUserQuestion에서 불리고 `tool_response.answers`(질문 원문 → 답)를 받는다. Read에서도 불리고 `tool_input.file_path`를 받는다. 실행 중인 세션이 설정 변경을 바로 반영했다. 표본은 `probe/`, 설정은 백업으로 복원. **가정 1·2 성립** |
| 11-19 13:50 | 메인: 명세 §10 인터페이스 계약 추가(사이드카 이름·기록 형식·미독 정의·차단 문구·고정 지시 주입) | 설계 선검증(I4·I5): 기존 강제 위치 = `gate-guard.sh`의 SPEC/MODE 차단(exit 2 분기들, L0 분류 `classify_l0l1`이 상태검증보다 먼저). 새 차단은 그 뒤에 두고 L0·Read·Bash는 건드리지 않음. 메인 보강: 고정 지시는 UserPromptSubmit뿐 아니라 SessionStart에서도 주입(실험에서 압축이 턴 도중에 일어남) |
| 11-19 14:05~14:14 | task 02 — 테스트 설계 워커(Opus, 184k 토큰, 구현 미열람), 기준 `b685d3e` | `hooks/tests/cases/decision-reread.sh` 68개. 구현 부재로 59개 실패·9개(회귀 가드) 통과를 개별 실행으로 확인. 계약 질문 12건 → 메인이 명세 §10 "계약 보충"으로 답함. 명세와 테스트 커밋 `b6750bd` |
| 11-19 14:15~14:29 | task 03 — 구현 워커(Opus, 199k 토큰), 기준 `b6750bd` | 새 훅 `capture-decision.sh`·`reread-track.sh`, `state-lib.sh` 함수 3개, `session-mode-guard`·`reinject-mode`·`gate-guard` 수정, `settings.json` 사본·`src/core.md`(+3줄)·`README.md`·`templates/log.md`. 새 68개 중 66 통과, 기존 261개 전부 통과(lock 검사 뺀 전체 실행). 실패 2건은 테스트 결함으로 보고(`si_05`: 종전 안내문의 글자를 함께 셈, `ad_05`: 글자 수와 바이트 수 혼용). shellcheck는 설치돼 있지 않아 미실행 |
| 11-19 14:32 | 메인 결정 | ①테스트 결함 2건과 계약 보충에 대한 테스트 추가는 테스트 워커가 고침(구현 미열람 유지) ②계약 보충 8을 정수 초로 고침(사유는 명세에) ③Read마다 도는 `reread-track`이 약 0.13초를 더함 — 리뷰에서 다룸 |
| 11-19 14:30~14:38 | 테스트 워커 후속(누적 220k) | 결함 2건 수정, 계약 보충 반영 → 77개. lock 재생성(사유: 새 케이스 파일 추가) → 전체 338 통과. 구현 커밋 `75a5137` |
| 11-19 15:00~18:25 | 리뷰 루프 1 — Opus 워커(203k) ∥ codex → 메인 종합 → codex 감사. packet base `b685d3e`, `$OUT` `/tmp/claude-1000/hrv-UpGr`, 미러 `/tmp/claude-1000/hmr-MdA3` | opus 13건·codex 7건. 주요: 배포 뒤 Read 훅 미등록 시 영구 차단, 테스트의 git 이력 의존으로 배포 smoke 실패, 고정 지시 파일 무게이트, 동시 기록 손상(실측), Bash 우회. 감사가 메인 종합의 H1(.reread 부재를 무차단으로)·H12(capture가 .reread 기록)를 계약 위반으로 지적 → H1은 표시 파일 방식으로 바꾸고 H12는 기각 |
| 11-19 18:28~18:59 | 구현 워커 후속(누적 254k) FIX-1~12 + 잔여 3건 · 테스트 워커 후속 2(누적 271k) | 명세 "계약 보충 2"(13~26). 새 케이스 92개, 옛 훅 사본 `hooks/tests/fixtures/legacy/`(lock 대상에 추가). 구현 워커가 종전부터 있던 결함 1건 발견·수정(읽을 수 없는 사이드카를 새 블록으로 덮어씀) |
| 11-19 19:05 | 메인: lock 재생성(사유: 케이스 추가·fixtures를 lock 대상에 넣음) → 전체 실행 | 결과는 아래 행 |
| 11-19 19:05 | 사용자 확인 대기 2건 | ①고정 지시 파일 쓰기에 승인 창(ask) 추가 — 명세 §4의 차단 범위 확대에 해당 ②Bash로 사이드카를 고쳐 차단을 푸는 경로를 한계로 둘지 |

## 리뷰 ledger (中↑ — 듀얼 리뷰가 돈 작업 필수)

- review packet: (리뷰 때 기록)

| id | first_seen_loop | source | 근거(file:line) | disposition | status | fixed_in_loop |
|----|-----------------|--------|-----------------|-------------|--------|---------------|
| | | | | | | |

## 생략한 검증 (긴급 경로 빚 — DEBT=1인 동안 정본)

- 없음.

## 완료 요약 (마감 시)

