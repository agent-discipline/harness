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
| 11-19 14:05 | task 02 — 테스트 설계 워커(Opus, 구현 미열람) 시작 | 진행 중 |

## 리뷰 ledger (中↑ — 듀얼 리뷰가 돈 작업 필수)

- review packet: (리뷰 때 기록)

| id | first_seen_loop | source | 근거(file:line) | disposition | status | fixed_in_loop |
|----|-----------------|--------|-----------------|-------------|--------|---------------|
| | | | | | | |

## 생략한 검증 (긴급 경로 빚 — DEBT=1인 동안 정본)

- 없음.

## 완료 요약 (마감 시)

