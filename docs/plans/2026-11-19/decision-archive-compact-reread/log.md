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
| 11-19 19:05 | 메인: 전체 실행 | 353 통과, 0 실패. 커밋 `e73a8c6` |
| 11-19 19:06~19:18 | 리뷰 루프 2 — Opus 워커(199k) ∥ codex. 미러 `/tmp/claude-1000/hmr2-loop` | 루프 1 수정 반영 확인(Opus가 `.git` 없는 미러에서 353 통과 실행). 새 결함: 표시 파일이 상태 디렉토리 단위라 다른 세션의 표시로 영구 차단 재발(두 리뷰 공통, Opus 재현) · 기록 중 파일 교체 시 유실(codex) · 잠금 실패 때 빈 파일(Opus) · 읽을 수 없는 `decisions.md`에서 중복(Opus). codex의 '테스트 헬퍼의 탭이 역슬래시-t' 지적은 기각(메인과 테스트 워커가 실제 탭임을 확인) |
| 11-19 19:19~19:24 | 구현 워커 후속 4(누적 약 270k) · 테스트 워커 후속 3(누적 289k) — 계약 보충 3(27~31) | 표시 파일을 세션 단위로, inode 확인, 빈 파일 정리, 읽을 수 없는 목적지 처리. 테스트 98개(파일 교체를 flock 래퍼로 재현) |
| 11-19 19:25 | 메인: lock 재생성(사유: 케이스 추가) → 전체 실행 | 359 통과. 커밋 `f8e028b` |
| 11-19 19:26~19:36 | 리뷰 루프 3(좁게) — Opus 워커(118k) ∥ codex. 미러 `/tmp/claude-1000/hmr3-loop` | 27·28·30항 반영 확인, Opus가 미러에서 359 통과 실행·10세션×5건 동시 기록 5회 모두 정상. 새 결함 1건(두 리뷰 공통): 29항의 빈 파일 삭제가 잠금 밖에서 일어나 다른 세션의 기록을 지울 수 있음(Opus가 확인~삭제 사이를 벌려 재현). 낮음: `/proc` 실패 시 사이드카에만 쌓임 |
| 11-19 19:37~19:41 | 구현 워커 후속 5(누적 285k) · 테스트 워커 후속 4(누적 303k) | **29항 철회**(삭제 함수와 호출 5곳 제거), inode 대체 경로(32항). 테스트 100개(`rm` 래퍼로 '훅이 decisions.md를 지우지 않음'을 직접 확인) |
| 11-19 19:45 | 메인: lock 재생성(사유: 케이스 수정·추가) → 전체 실행 → 동시 기록 실험 재실행 | **361 통과, 0 실패**. 리뷰어의 실험 스크립트(`exp1.sh 10 5`)를 최종 훅으로 3회: 매번 제목 1·블록 50·중복 0·사이드카 잔여 0. `drop_created_empty` 잔존 0 |
| 11-19 19:45 | 리뷰 종료 판정 | 최대 3루프 도달. 루프 3에서도 채택 1건이 있어 '신규 채택 0인 루프' 조건은 미충족 → **`review unresolved`가 아니라 open finding 0·조건 미충족**으로 기록하고 사용자에게 보고. 근거: 루프 3의 수정은 루프 2에서 넣은 삭제 동작의 제거(코드 감소)이고, 제거 뒤 전체 테스트와 동시 기록 실험을 메인이 재실행. 4회차 여부는 사용자 결정 |
| 11-19 19:50 | 커밋 `3a971e4`(리뷰 3회차 반영) → 사용자 확인(질문 도구) | "지금 배포하고 등록" · Bash 우회는 "한계로 적고 넘어간다" · 고정 지시 승인 창은 "이게 왜 필요한거지?"(설명 뒤 다시 물음) |
| 11-19 20:00 | `deploy.sh` 1차 → **smoke 실패, 자동 원복(D9)** | 배포 뒤 테스트 전체 실행이 300초 제한 초과. 원인: 테스트 361개 + 머신 부하 14(다른 프로젝트의 Gradle 테스트) → 실측 400초. `deploy.sh`의 제한을 900초로(커밋 `d5f38e4`) |
| 11-19 20:25 | `deploy.sh` 2차 → smoke 통과, 배포 완료 | 백업 `~/.claude/.deploy-backup-594567`. `~/.claude/settings.json` 백업(`settings.json.bak-2026-11-19-reread`) 뒤 PostToolUse에 `AskUserQuestion`→`capture-decision.sh`, `Read`→`reread-track.sh`만 추가(다른 설정 동일 확인) |
| 11-19 20:30~21:05 | 실제 세션 smoke(이 세션) | ①Read → `<sid>.reread-seen`·`.reread` 기록 확인 ②질문 도구 답 → `decisions.md`에 블록 기록 확인(이 폴더의 `decisions.md` — 첫 블록) ③사용자 확인("한국어 응답 한 줄") 뒤 `~/.claude/standing-instructions.md` 생성 → reinject 출력 끝에 `[고정 지시]` 줄 확인. 압축 뒤 차단은 다음 압축 때 관측(이 세션은 압축이 잦음) |
| 11-19 21:05 | 사용자 결정: 승인 창 "넣는다" | 명세 "계약 보충 4"(33·34). 후속 구현 착수 |
| 11-19 21:05~21:10 | 테스트 워커 후속 5(누적 310k)·구현 워커 후속 6(누적 294k) — 계약 보충 33 | `gate-guard.sh` #1b(상태파일 하드 거부 다음, L0/L1 분류 앞)에서 고정 지시 파일 Edit/Write/MultiEdit에 ask. 테스트 7개(sa_01~07) |
| 11-19 21:20 | 메인: lock 재생성(사유: 케이스 추가) → 전체 실행 | 368 통과. 커밋 `8ac1565` |
| 11-19 21:25 | post-fix 타깃 리뷰(codex, 미러 `/tmp/claude-1000/hmr4-ask`) | 중간 3건 — 모두 기각: ①`session_id` 없는 입력은 그 앞에서 통과(훅 전체의 기존 원칙 — Claude Code는 항상 session_id를 보냄) ②하드링크·대소문자 무시 파일 시스템(하드링크를 만들려면 Bash가 필요 — 수용한 한계, 대상 환경은 Linux) ③고정 지시 파일이 심링크일 때 그 대상 파일 쓰기에도 ask(해가 없음 — 승인 창 한 번). 테스트 지적 2건(존재하지 않는 `sub/../`, 순서 입증 약함)은 낮음 — 미수정으로 기록 |
| 11-19 21:30 | `deploy.sh` 3차(승인 창 포함) | smoke 통과. 백업 `~/.claude/.deploy-backup-906648` |
| 11-19 21:30~23:40 | task 06 — Haiku 확인 실행 3회(진행자 Fable 5.2, 162k 토큰). compaction-experiment에 조건 `standing` 추가(커밋 `8f0af58`·`c757f04`): 압축 설정 + UserPromptSubmit·SessionStart 훅이 고정 지시 한 줄을 주입 | 3회 모두 유효·완료. **K8 3/3 fail**(위반 턴 [0] / [3,4,6] / [2,4,5]). 첫 압축 뒤 한글 비율 0.772 / 0.460 / 0.447(compact 0.257, outbox 0.229, control은 압축 없이 0.930). 주입은 맥락에 도달함(r1 세션 기록의 hook_success attachment: UserPromptSubmit 9, SessionStart:compact 12). 메인이 `run.json`·`score.json`에서 K8 값과 주입 횟수를 직접 대조 |
| 11-19 23:40 | 같은 실행의 부수 관측 | r2 턴 7·8, r3 턴 6·7·8에서 에이전트가 "예산 소진"이라며 도구를 쓰지 않고 작업을 거부(실제 한도에는 닿지 않음 — status complete, abort_reason 없음). 이 때문에 r2·r3은 뒤 단계 구현이 빠져 계약 테스트 38개 중 8개, 11개 실패(모두 거부한 단계 D6·D7의 항목). K7a(단계마다 커밋)도 3/3 fail — r1 S7과 r3 S5는 거부가 아닌데 커밋하지 않음. 거부 턴의 응답은 한국어라 r2·r3의 '압축 뒤 한글 비율'을 올리는 쪽으로 작용. 본 실행 9회에는 이런 턴이 없었음 |
| 11-19 23:41 | 압축 뒤 재독 — 실제 세션 관측(이 세션, 23:3x 압축) | SessionStart(compact)에 안내 줄, 다음 턴 재주입에 미독 파일 3개 목록이 들어옴. 세 파일을 Read 한 뒤 다음 턴 재주입에서 미독 줄이 사라짐. 미독 상태의 L1 쓰기 차단은 시도하지 않아 미관측 |

## 리뷰 ledger (中↑ — 듀얼 리뷰가 돈 작업 필수)

- review packet: base `b685d3e` · `$OUT` `/tmp/claude-1000/hrv-UpGr` · 미러 루프1 `/tmp/claude-1000/hmr-MdA3` · 루프2 `/tmp/claude-1000/hmr2-loop` · 루프3 `/tmp/claude-1000/hmr3-loop`

| id | first_seen_loop | source | 근거(file:line) | disposition | status | fixed_in_loop |
|----|-----------------|--------|-----------------|-------------|--------|---------------|
| H1 | 1 | opus F1 | session-mode-guard.sh:69-77 · gate-guard.sh:346-357 — Read 훅 미등록 상태의 영구 차단 | 채택(표시 파일) | fixed | 1(디렉토리 단위) → 2(세션 단위로 재수정) |
| H2 | 1 | opus F2 | tests/cases/decision-reread.sh:9,86-92 — git 이력 의존으로 배포 smoke 실패 | 채택(fixture) | fixed | 1 |
| H3 | 1 | opus F3 · codex F7 | gate-guard.sh:86-111 · state-lib.sh:385-395 — 고정 지시 파일 무게이트·심링크·무제한 읽기 | 일부 채택(심링크 거부·64KB) / ask 게이트는 §4 범위라 **user-deferred** | fixed / user-deferred | 1 |
| H4 | 1 | codex F1 · opus F4 | gate-guard.sh:210 · state-lib.sh:362-373 — Bash로 사이드카를 고쳐 차단 해제 | 일부 채택(판정 불가 알림·README) / 차단 자체는 수용한 한계 — **user-deferred** | fixed / user-deferred | 1 |
| H5 | 1 | codex F2 · opus F5 | capture-decision.sh:93-127 — 세션별 잠금으로 동시 기록 손상(실측) | 채택 | fixed | 1 |
| H6 | 1 | codex F3 | capture-decision.sh:104 — 읽지 못한 사이드카 삭제 | 채택 | fixed | 1 |
| H7 | 1 | codex F4 · opus F10 | capture-decision.sh:118-123 — 부분 쓰기 | 채택 | fixed | 1 |
| H8 | 1 | codex F5 · opus F9 | session-mode-guard.sh:65 — prune이 사이드카 삭제 | 채택 | fixed | 1 |
| H9 | 1 | codex F6 · opus F6 | state-lib.sh:375 · capture-decision.sh:78-83 — 탭·역슬래시 경로 | 채택 | fixed | 1 |
| H10 | 1 | opus F7 | capture-decision.sh:64-66 — 빈 id 블록 유실 | 채택 | fixed | 1 |
| H11 | 1 | opus F8 | capture-decision.sh:52 — CR·U+2028 | 채택 | fixed | 1 |
| H12 | 1 | opus F11 | 새 decisions.md 뒤 재차단 | 기각(감사: '읽음' 정의 위반) — 한계로 README | — | — |
| H13 | 1 | opus F12 | reread-track.sh:18-44 — 성능 | 채택 | fixed | 1 |
| L2-1 | 2 | codex F1 · opus N1 | session-mode-guard.sh:75 — 디렉토리 단위 표시 파일 | 채택(세션 단위) | fixed | 2 |
| L2-2 | 2 | codex F2 | tests/cases/decision-reread.sh:118 — 탭 리터럴 | 기각(실제 탭 문자 — 메인·테스트 워커 확인) | — | — |
| L2-3 | 2 | codex F3 | capture-decision.sh:129 — 기록 중 파일 교체 | 채택(inode 확인) | fixed | 2 |
| L2-4 | 2 | codex F4 | tests ad_20 — 가운데 블록 미검증 | 채택 | fixed | 2 |
| L2-5 | 2 | opus N2 | capture-decision.sh:129 — 빈 파일 | 채택(삭제) → 루프 3에서 철회 | fixed(철회) | 2 → 3 |
| L2-6 | 2 | opus N3 | capture-decision.sh:68 — 읽을 수 없는 목적지 | 채택 | fixed | 2 |
| L3-1 | 3 | codex · opus L3-01 | capture-decision.sh:138-141 — 잠금 밖 삭제 경합(재현) | 채택(삭제 동작 제거) | fixed | 3 |
| L3-2 | 3 | opus L3-02 | capture-decision.sh:146 — /proc 실패 | 채택(대체 경로) | fixed | 3 |
| L3-3 | 3 | opus T-01 | tests ad_24 — 빈 파일 보존 미검증 | 채택 | fixed | 3 |

| A1 | post-fix | codex | gate-guard.sh:65 — session_id 없는 입력에서 ask 생략 | 기각(기존 원칙: 세션 식별 불가 = inert) | — | — |
| A2 | post-fix | codex | gate-guard.sh:306 — 하드링크·대소문자 | 기각(Bash 필요 — 수용한 한계) | — | — |
| A3 | post-fix | codex | gate-guard.sh:307 — 심링크 대상에 추가 ask | 기각(무해) | — | — |

- 종료 조건: open finding 0 · 루프 3 신규 채택 3건(조건 미충족) · user-deferred 2건(H3 ask 게이트, H4 Bash 우회). 사용자 보고 뒤 결정.

## 생략한 검증 (긴급 경로 빚 — DEBT=1인 동안 정본)

- 없음.

## 완료 요약 (마감 시)

