# log — implementation-by-workers (구현의 기본 주체를 Opus 워커로)

| 시각(KST) | 사건 | 결과 |
|-----------|------|------|
| 11-21 19:5x | 사용자(deploy-study-note 세션): "토큰보다는 작업 품질이 우선이니까 하네스를 수정할 필요가 있지 않아? 난 토큰은 조금 더 써도 품질적인 면에서 높은 게 더 좋다" → "하네스에 작업 기록하면 될 거고 하네스 수정해 보자" | 작업 폴더 생성. 발단: 같은 세션의 두 작업 비교 — 알림 서버(메인이 구현: 리뷰 지적 15 · 재점검 6) / 관측 서버(Opus 워커가 구현: 리뷰 지적 10 중 중간 1 · 재점검 1 · 테스트 워커가 리뷰 전에 초안 결함 6 검출 · 워커 토큰 약 3배). 기록: `deploy-study-note/docs/cross-cutting/plans/2026-11-20/alert-server/log.md` · `2026-11-21/observation-server-logs/log.md` · 그 저장소 `docs/measurement-log.md` 의 2026-11-21 두 행 |
| 11-21 20:0x | 사전 조사 — explorer(sonnet, 98k 토큰, 30 tool): 위임·테스트 설계·토큰 비용·회수 규칙·측정 로그·길이 상한·이력 관례·배포·훅의 메인/워커 구별 | 구현 주체는 `src/core.md:97` 한 줄("독립 모듈 병렬 구현"만 위임 대상) · 강도표는 core 와 README 두 곳 · 훅 입력의 `agent_id` 로 메인/워커 구별 가능(gate-guard 357~363행·reread-track 가 이미 사용) · 문서 내용을 검사하는 테스트 없음 · `task-units.md` 79줄(상한 80) · 다음 버전 v4.8. explorer 가 긴 줄 일부와 gate-guard 전체 흐름은 읽지 못했다고 밝힘 — 구현 워커가 직접 읽는다 |
| 11-21 20:1x | 인터뷰(선택 질문 3) | 문서 규칙 + 훅 알림(차단 아님) · 낮은 stakes 는 메인 직접 · 테스트 설계는 중간부터 별도 워커. 질문 없이 둔 기본값: lazy 모드 불변 · v4.8. 명세 초안, 합의 대기 |
| 11-21 20:2x | 사용자: "진행해보자." | 명세 합의, set-state spec-approved / mode auto. 기준 SHA: main 2f07fb0. 작업 브랜치 `feat/implementation-by-workers` |
| 11-21 20:2x | 관찰 — 이 작업 폴더의 `decisions.md` 에 세션의 이전 작업들(다른 저장소의 배포·알림 서버·관측 서버) 선택 질문·답이 전부 들어 있음(11-19 행부터) | `capture-decision` 이 작업 폴더가 바뀔 때 세션 전체 기록을 옮겨 적는 것으로 보임(원인 미확인). 비밀값·IP 없음, 서버 표기(`.9`·`.158`)와 다른 프로젝트의 결정 내용 포함. 커밋 여부는 사용자에게 묻는다. 훅 동작은 NEXT 후보 |
| 11-21 20:3x | **task 01 — 가정 실증**(임시 디렉토리에서 별도 세션 `claude -p`, Claude Code 2.1.329, 실험용 PreToolUse 훅) | **가정 1 맞음**: 메인의 Write 입력 키에 `agent_id` 없음 / 서브 에이전트의 것에 `agent_id`·`agent_type: general-purpose` 있음. **가정 2 틀림**: exit 0 과 함께 낸 일반 stdout · stderr · `{"systemMessage":…}` 는 모델에게 보이지 않았고 `{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":…}}` 만 보였다(메인 1회, 서브 에이전트도 1회 — "PreToolUse:Write hook additional context: …" 로 도착). → 알림은 `additionalContext` 로. 부수 발견: 기존 lazy Bash 소프트 리마인더(gate-guard.sh:234, 일반 stdout)는 같은 이유로 모델에게 안 보일 수 있다 — 범위 밖, NEXT 후보 |
| 11-21 20:4x | task 02 문서 규칙 — Opus 워커(135k 토큰, 19 tool, 4분) 회수 | `src/core.md` 144 → 147줄(+794자): §0.2 한정 · §2 explorer 한정 · §4 강도표 중간 테스트 설계 · §5 구현 주체·워커 위임·구현 워커 회수 · §6 gate-guard 알림 한 구절 · 변경 이력 v4.8. README(원칙 5·강도표 사본 전 칸을 core 문구로 맞춤·실측 절 신설·이력) · HISTORY 1행 · 측정 로그 템플릿의 워커 열 설명. `task-units.md`·`templates/log.md` 는 고치지 않음(단일 출처·기존 칸으로 충분). 메인 교차 확인: diff 4파일 +33/−12, 훅·playbooks 무변경, 두 강도표 문구 일치. 워커가 넘긴 판단: ①`playbooks/review.md:70` 의 "spec-우선"은 옛 표현(금지 파일이라 그대로 — 사용자에게 보고) ②README 저장소 구조 절의 gate-guard 설명에 알림 추가는 훅 작업에서 ③§8 "각 ≤80줄"을 원래 넘던 문서 2개(open-source 173·review 116 — 이번 것 아님) |
| 11-21 20:4x | **설계 선검증**(codex, 명세 + gate-guard.sh·state-lib.sh 전문) | 모호 6(MultiEdit 포함 여부 · `agent_id` 빈 값 · "L1 경로"의 뜻 · 낮은 stakes 제외가 조건인지 문구인지 · "한 번"의 범위 · `ask` 경로) + 위험 5(알림 위치는 모든 판정 뒤 · 출력은 JSON 만 · `set -eu` 아래 기록 실패가 차단을 만들 수 있음 · 상태 디렉토리 보호 규약 · 리셋·복구와 사이드카의 수명) + 기억 방법 3안 + 고정할 경계 8. → 명세 ② 에 "훅 알림의 세부" 절 추가(세션·작업 폴더마다 한 번, 통과 우선·실패 시 알림 생략, 판정이 끝난 뒤에만, JSON 하나만). 합의한 의도 안의 세부 확정으로 판단 — 사용자에게 보고 |
| 11-21 20:5x | 사용자: `decisions.md` 는 "1번"(이번 하네스 질문 3건만 남김) | 반영 — 앞선 다른 저장소 작업들의 질문·답(11-19~11-21 15:37) 삭제. 훅 소유 파일을 사용자 확인 아래 고친 예외 |
| 11-21 21:0x | 메인이 `review.md:70` 의 "spec-우선"을 새 기준으로 바꿀지 물음 → 사용자 반문("리뷰는 메인이 하는 게 맞지 않아? spec 우선도 맞는 거 아니야?") | 메인의 질문이 불필요했다 — "spec-우선"은 지금도 참이고 그 문장은 "core §4대로"로 정본을 넘긴다. `review.md` 는 고치지 않는다 |
| 11-21 21:1x | 사용자: "리뷰 이 부분 명확하게 하고 싶은데" → 선택지 3(문면만 분명히 / 메인도 리뷰 참여 / 다른 것) 중 "1번으로 하자" | 명세 ② 에 "리뷰에서의 역할" 조항 추가(범위 확장 — core.md 한 줄, 절차·review.md 불변). 문서 워커에게 이어서 위임 |
| 11-21 21:2x | 문서 워커 후속 회수 — 리뷰 역할 | `src/core.md:98` 워커 위임 줄에 구절로("리뷰(중간↑ — 리뷰어 = Opus 워커 ∥ codex가 결함을 찾고, 메인은 그 지적을 명세에 비추어 기각 / 지금 고친다 / 후보로 판정한다. 메인은 리뷰어가 아니다 — `review.md` §1)"). 줄 수 그대로 147, +138자. 워커가 "중간↑"로 한정(낮음의 셀프체크와 어긋나지 않게 — 타당). README 원칙 5·이력, HISTORY 행 보강. review.md 무변경. 메인 교차 확인 뒤 커밋 |
| 11-21 21:3x | task 03 테스트 — blind 테스트 워커(Opus, 245k 토큰, 53 tool, 30분) 회수 | 새 파일 `hooks/tests/cases/worker-notice.sh` 사례 33개 + 기준 훅 fixture `fixtures/legacy-2f07fb0/`(2f07fb0 의 gate-guard·state-lib 원본) + `baseline.manifest` 에 예상 실패 33행 + `tests.lock` 재생성(**사유: 사례 파일 1개·사례 33개 추가 — 18 files, 409 tests**). 설계 선검증의 경계 8개 전부 사례화. 워커가 임시 구현에 흔한 잘못 11가지를 넣어 전부 걸리는 것을 확인(임시 구현은 저장소 밖 — blind 계약상 구현 워커에게 주지 않는다). 기존 사례 중 알림과 충돌하는 단언 없음(조사 + 임시 구현으로 376개 green 실측) |
| 11-21 21:4x | 메인 재실행 — `bash hooks/tests/run.sh --baseline` | exit 0, 176초: 33 expected-failure confirmed · 376 green · 0 unexpected(보고와 일치). fixture 가 2f07fb0 원본과 같음, gate-guard·state-lib 무변경. 워커의 일반 모드 실행에서 난 무결성 위반은 실행 중 메인이 같은 저장소에 커밋한 탓 — **워커가 테스트를 돌리는 동안 메인이 그 저장소를 고치지 않는다**(회수 규칙에 더할 관찰) |
| 11-21 21:4x | 워커가 넘긴 판단 — 실패 시 stderr | 명세의 "조용히 통과"와 core §4 "실패를 드러내기"가 엇갈림 → 명세 보강: 조용히 = 모델에게 보이는 stdout 이 없다. 실패는 stderr 한 줄로 남기고 "한 번"을 소비하지 않는다. 정상 경로의 stderr 는 기존과 바이트까지 같다 |
| 11-21 21:5x | task 03 구현 — Opus 워커(165k 토큰, 28 tool, 14분) 회수 | `hooks/gate-guard.sh` +65줄: 함수 `worker_notice()` — auto 분기에서 `reread_gate` 통과 직후에만 호출(그 앞의 차단·L0·ask·Post·Bash 경로는 이미 종료, lazy 분기는 부르지 않음). 기억 = `<상태 디렉토리>/<sid>.worker-notice`(한 줄에 TASK_PATH 하나, 빈 줄 = 폴더 없음), 잠금 = `<sidecar>.lock` 에 `flock -x -w 2`, 쓰기 = temp + mv, JSON 은 잠금 전에 만들고 기록 성공 뒤에만 출력. 실패(생성·잠금·쓰기) = stdout 없이 exit 0 + stderr 경고 한 줄. `baseline.manifest` 의 예상 실패 34행 삭제(main 원본과 동일해짐), **`tests.lock` 재생성 사유: manifest 해시 1행 변경**. 워커 뮤테이션: 알림을 차단 판정 앞으로 옮기면 6개 빨강 / **잠금을 빼도 빨강이 되지 않음**(wn_14 가 못 잡는다 — 따로 지연을 넣은 실험에서는 잠금 없으면 알림 4개, 있으면 1개) |
| 11-21 22:0x | 메인 재실행 — `bash hooks/tests/run.sh` | exit 0, 313초: **409 passed, 0 failed**, 무결성 위반 없음(보고와 일치). diff 3파일(gate-guard +65 · manifest −34 · lock ±1). 커밋 |
| 11-21 22:0x~22:2x | wn_14 보강 — 테스트 워커 후속(누적 285k) 회수 | 새 사례 `test_wn_14b`(mktemp 래퍼로 "확인 → 기록" 사이를 1.5초 넓히고 8개 동시 호출): 잠금을 뺀 변종 10/10 빨강 · 원본 10/10 초록. 감사 중 **wn_13c 가 아무것도 시험하지 않던 결함** 발견·수정(jq 래퍼가 테스트의 입력 빌더에도 걸려 훅이 빈 입력으로 통과). wn_13b 같은 폴더 대조, stdout 바이트 판정 보강. **`tests.lock` 재생성 사유: 사례 1개 추가(18 files, 410 tests) + wn_13b·13c 수정.** 남은 빈틈(지워도 통과하는 줄) 7곳을 목록으로 보고 |
| 11-21 22:3x | 메인 재실행 — `bash hooks/tests/run.sh` | exit 0, 269초: **410 passed, 0 failed**, 무결성 위반 없음. 커밋 f66b1f5 |
| 11-21 22:1x~22:4x | **리뷰 루프 1** — 기준 2f07fb0 → 6b0a43c 의 읽기 전용 사본(`scratchpad/review-harness-1/mirror`) · Opus 리뷰어(197k 토큰, 23 tool, 5분) ∥ codex(인라인 226KB) → 종합 → codex 감사 | codex 지적 3 · Opus 지적 3·질문 5. 감사: 종합의 S2(출력 실패를 명세 완화로 처리)는 사용자 합의 없이 안 됨 → 구현으로 해결(잠금 안에서 출력, 실패 시 기록 되돌림) · S1 은 확인 후 열기 사이 틈 → 읽기 전용으로 열기 · S6 은 결론 서술도 함께 낮출 것 · blind 순서는 기록으로 확인(테스트 커밋 6b8ade1 이 구현 커밋 6b0a43c 보다 앞, 테스트 작성 시점의 gate-guard 에는 알림 기능이 없었다) |
| 11-21 22:4x | 사용자 결정(선택 질문): lazy 모드는 메인이 직접 | 명세 ② 구현 주체의 예외에 ⑤ lazy 추가 |
| 11-21 22:5x | 문서 워커 후속 2 회수(누적 161k) → a27d077 | S4 lazy 예외(core §5 구현 주체 줄 + 변경 이력·README 이력·HISTORY) · S5 §2 "워커 결과(탐색·조사·검증·완료 문서)는 핵심 1~2개 교차 확인 후 채택(구현 워커는 §5 회수)" · S6 README 실측 절의 열 제목·한계·결론을 사실대로(본체 초안은 메인). core 147줄 15116자. 메인이 토큰 행("구현 4" → 워커 4 의 역할)과 명세 0절 표를 같은 사실로 맞춤 |
| 11-21 23:0x | 테스트 워커 후속 2 회수(리뷰 루프 1 의 S1·S2·S3) | 사례 410 → 420. S1·S2 사례 4개(wn_16·16b 잠금 파일 심링크 / wn_17·17b 출력 실패)는 지금 구현에서 빨강 — 예상 실패로 등록. S3 사례 7개(임시 파일·mv 실패, 사이드카 자리가 심링크·디렉토리·FIFO·읽기 불가)는 초록이고 각 줄을 지운 변종에서 빨강 확인. 기존·새 실패 사례 전부에 "경고 한 줄" 단언, 정상 경로에 "경고 0줄" 대조. **`tests.lock` 재생성 사유: 사례 10개 추가(420 tests) · wn_02·13·13b·13c 단언 보강 · wn_13c 의 효과 없던 TMPDIR 부분 삭제.** 테스트로 닿지 않는 방어선 5곳(gate-guard 413행 `state_ensure_dir` 재확인 · 431행 mktemp 뒤 `exit 1`(다음 줄이 같이 실패) · 436행 `mv -T` · 428행 grep rc 2 · 426행 검사의 디렉토리 분기 — 뒤의 `cat` 이 같이 실패해 결과가 같다) |
| 11-21 23:1x | 메인 재실행 — `bash hooks/tests/run.sh --baseline` | exit 0: 4 expected-failure confirmed · 416 green · 0 unexpected, 무결성 위반 없음(보고와 일치). 커밋 |
| 11-21 23:2x | 구현 워커 후속 회수(누적 210k) — S1·S2 | `worker_notice` 의 임계구역만 +34/−19. S1: 잠금 파일은 없을 때만 `set -C` 의 `>`(O_EXCL — 심링크를 따라가지 않는다)로 만들고 **읽기 전용(`9<`)으로 연다**, 열기 전·후에 심링크·비정규 여부를 보고 `/proc` 이 있으면 연 fd 와 그 자리가 같은 파일인지(`-ef`) 확인. S2: JSON 출력을 잠금 안으로 옮기고, 출력이 실패하면 같은 잠금 안에서 마지막 줄만 지운다(`sed '$d'` → temp → mv). 경고는 rc 별 한 줄. 워커 뮤테이션: S1 을 되돌리면 wn_16·16b 빨강, 되돌리기를 빼면 wn_17·17b 빨강. **`tests.lock` 재생성 사유: 예상 실패 묶음(5행) 삭제로 manifest 해시 1행 변경.** 남은 한계: 출력 실패 + 되돌리기도 실패(rc 21)면 한 번이 소비된다(경고 문구에 밝힘, 테스트로 닿지 않음) · `/proc` 없는 환경은 경로 재검사만 · 검사와 열기 사이에 FIFO 심링크로 바뀌는 이론상 경합 |
| 11-21 23:3x | 메인 재실행 — `bash hooks/tests/run.sh` | exit 0, 344초: **420 passed, 0 failed**, 무결성 위반 없음. manifest 가 main 원본과 같음. 커밋 → 리뷰 루프 2 |
| 11-22 00:0x | **리뷰 루프 2** — 기준 2f07fb0 → 훅 수정 커밋의 읽기 전용 사본(`scratchpad/review-harness-2/mirror`) · Opus 리뷰어(160k 토큰, 20 tool, 5분) ∥ codex(인라인) | 루프 1 의 S1·S3·S4·S5·S6 해소 판정(양쪽). S2(출력 실패)는 codex 미해소·Opus 해소(한 경로 예외). 새 지적: codex 4(되돌리기도 실패하면 한 번 소비 · 끝 개행 없는 사이드카에서 되돌리기가 다른 폴더 기록을 지움 · wn_14b 의 지연 의존 · root 에서 wn_19d 가 건너뛰어지고 통과로 집계) / Opus 3(SIGPIPE 면 되돌리기를 건너뜀 · "마지막 줄만 되돌린다"를 고정하는 사례 없음 · 실패 원인을 한 문구로 묶음) + 질문 5 |
| 11-22 00:1x | **정지 규칙 적용(core §3)** — S2 를 한 번 고쳤는데 그 수정(되돌리기)에서 새 결함 3건 | 되돌리기를 다듬지 않고 순서를 다시 설계: 기록할 내용을 미리 준비 → 알림 출력 → 마지막에 기록 확정(이름 바꾸기). 되돌리기가 없어진다. 마지막 확정만 실패하면 알림은 이미 나갔고 다음에 한 번 더 뜬다 — 명세 실패 정책 문장이 바뀌므로 사용자에게 질문 |
| 11-22 00:2x | 사용자 답(선택 질문 2): 실패 방향 "안 뜨는 경우를 2번으로 하고 막을 수 없어?" / 정책 파일 "정책 파일도 워커가" | 첫 답은 뜻을 다시 확인 중(둘을 동시에 막을 수는 없고, 안 뜨는 경우를 없애는 것이 1번이라고 설명). 정책 파일은 명세 ② 구현 주체에 반영(대상 = core §1 의 L1 전체) + 테스트·리뷰 반영 워커도 구현 워커임을 명시(Opus 질문 1) → 문서 워커에게 위임 |
| 11-22 00:5x | 문서 워커 후속 3 회수(리뷰 루프 2 의 문서 2건) | core §5 구현 주체의 대상을 따로 나열하지 않고 "L1(§1 — 실행 정책 파일 포함)"으로(예외 목록의 "docs/** 기록"은 L0 이라 뺌) · 회수 줄 머리에 "L1을 쓰는 워커는 테스트 설계·리뷰 반영 포함 모두 구현 워커". README 원칙 5·실측 절·이력, HISTORY, core 변경 이력 맞춤. core 147줄 15147자(+31). 메인 교차 확인: diff 3파일, 훅·playbooks 무변경 |
| 11-22 01:0x | 사용자: "진행하자"(실패 방향 — 안 뜨는 일은 없게, 드물게 한 번 더 뜨는 것은 수용) | 명세 ② 실패 정책에 순서(준비 → 출력 → 확정, 한 잠금 안)와 방향, "빠지지 않는다"의 뜻(생략된 호출은 한 번을 소비하지 않아 다음 쓰기에서 뜬다), 단계별 경고를 적음 |
| 11-22 01:1x | 리뷰 루프 2 종합 → codex 감사(`scratchpad/review-harness-2/synthesis.md`·`results/codex-audit.md`) | 감사 4건 전부 수용: ①wn_14b 지연 의존을 후보로 미룬 것은 근거 부족 → 지금 고친다(장벽 또는 동등한 경합 확인) ②건너뜀 별도 집계만으로는 공백 — 환경에 기대지 않는 실패 주입으로 ③기존 wn_18b(mv 실패 시 stdout 없음)가 새 순서와 충돌 — 기대값을 바꾸고 "출력 성공·확정 실패·재호출" 사례 추가 ④잠금 대기 실패의 생략은 남는다 — 명세에 뜻을 명시, `trap` 은 잠금 서브셸 안에만 |
| 11-22 02:2x~02:4x | 테스트 워커 후속 3 회수(이번 390k 토큰, 20 tool, 15분) — 리뷰 루프 2 사례, 구현 전 | 사례 420 → 426. 새 사례 wn_19e·20·20b·21·21b·22, wn_18b 기대값을 새 순서로, wn_14b 를 장벽 방식으로(둘째 호출 도착 또는 5초 뒤 풀림 — 동시 체류 최대 1 을 단언), wn_19d 를 권한 무관 주입으로, 경고의 단계 낱말 단언. 러너: `skip_test` 표식 → 건너뜀을 통과와 따로 센다(`lib.sh`·`run.sh`). 지금 구현에서 빨강 7개를 예상 실패로 등록. **`tests.lock` 재생성 사유: 사례 6개 추가(426 tests) · wn_18b·14b·19d 재작성 · 단계 낱말 단언 · skip_test · 러너 건너뜀 집계.** 임시 구현(새 순서)에서 426 초록, 변종(되돌리기 유지 · trap 없음 · 출력 전 확정 · 줄 경계 미보존 · 경고 묶음 · 잠금 없음) 전부 빨강. 닿지 않는 곳: trap 이 뒤로 번지지 않음(훅 밖에서 관찰 불가) · 확인 단계 실패의 단계 낱말(명세에 없음 — 메인 결정: "준비"로 묶는다) · 다른 사례 파일의 root `return 0`(decision-reread 9곳·detect-layer 2곳 — 범위 밖, NEXT 후보) · root 경로는 실제 root 로 돌려 보지 못함 |
| 11-22 02:5x | 메인 재실행 — `bash hooks/tests/run.sh --baseline` | exit 0: **7 expected-failure confirmed · 419 green · 0 unexpected · 0 skipped**(보고와 일치). diff 5파일 전부 `hooks/tests/` 안. 커밋 |
| 11-22 02:4x~02:5x | 구현 워커 후속 2 회수(누적 248k 토큰, 13 tool, 12분) — 순서 재설계 | `hooks/gate-guard.sh` +33/−21, 머리 주석 2줄 외 전부 `worker_notice` 안. 잠금 서브셸 안 `trap '' PIPE` → 확인 → 준비(임시 파일 = 기존 내용 + 끝 개행 보탬 + 이번 한 줄) → 출력 → 확정(`mv -fT`). 되돌리기 삭제. rc 별 경고(1 잠금 · 2 준비 · 3 출력 · 4 확정 · 그 밖 예상 밖). 예상 실패 7행 삭제(manifest 가 main 원본과 같음), **`tests.lock` 재생성 사유: manifest 해시 1행 변경.** 뮤테이션: trap 제거 → wn_20·22 빨강 / 출력 전 확정 → 8개 빨강 / 줄 경계 보탬 제거 → wn_21·21b 빨강. 남은 한계: 잠금 대기 실패의 생략·확정 실패의 중복(명세가 받아들임) · `/proc` 없는 환경 · 예상 밖 rc 분기는 테스트로 닿지 않음 |
| 11-22 03:0x | 메인 재실행 — `bash hooks/tests/run.sh` | exit 0: **426 passed, 0 failed, 0 skipped**, 무결성 위반 없음(보고와 일치). diff 3파일(gate-guard · manifest −8 · lock ±1). 커밋 → 리뷰 루프 3 |
| 11-22 03:1x~03:3x | **리뷰 루프 3(마지막)** — 기준 2f07fb0 → c5ab13e 의 읽기 전용 사본(`scratchpad/review-harness-3/mirror`) · Opus 리뷰어(158k 토큰, 20 tool, 5분 — 사본 복사본에서 변형 실험) ∥ codex(인라인 281KB) → 종합 → codex 감사 | T1~T7·T9 양쪽 해소, T8 미해소. 지적: 공통 1(wn_14b 장벽 5초가 flock 대기 2초보다 길어 "확인이 잠금 밖" 변형이 살아남음 — Opus 실험으로 확인) · Opus 1(stdout·stderr 가 함께 끊기면 경고 echo 에서 SIGPIPE, exit 141 — 실험으로 확인) · codex 1(JSON 이 일부만 나간 뒤 실패하면 잘린 JSON) + 질문 5. 감사 3건 수용: ①부분 출력을 "고치지 않음"으로 닫은 근거(PIPE_BUF 원자성)는 증명이 아니다 → 한 번의 write 인지 실측하고, 보장 범위를 명세에 적는다 ②wn_14b 는 제한만 줄일 것이 아니라 경합 조건을 관측하지 못하면 실패로 ③경고를 통째로 버리거나 함수 전체에 trap 을 걸지 말고 경고 출력에만 한정 |
| 11-22 03:1x~03:2x | 테스트 워커 후속 4 회수(누적 427k 토큰, 15 tool, 14분) — 리뷰 루프 3 사례 | 사례 426 → 428. wn_14b 재작성(둘째 호출의 잠금 시도 또는 준비 도착을 관측한 뒤에만 풀고, 10초 안에 관측하지 못하면 실패) — 10회 반복: 현재 구현 10/10 초록 · 잠금 없음 10/10 빨강 · 확인이 잠금 밖 10/10 빨강. wn_23(stdout·stderr 둘 다 끊긴 파이프 → exit 0) 은 지금 구현에서 빨강(exit 141) — 예상 실패 등록. wn_24(알림 길이 < 4096). wn_21·21b 에 단계 낱말 단언. **U3 실측**: strace — 훅의 stdout 으로 가는 write(2) 는 한 번, 313바이트. 경고를 통째로 버리는 변형은 기존 사례 4개(wn_13b·17b·20·22)가 빨강으로 잡는다. **`tests.lock` 재생성 사유: wn_14b 재작성 · wn_23·24 추가 · wn_21·21b 단언(428 tests).** 닿지 않는 곳: "한 번의 write"(실측으로만) · SIGPIPE 무시의 범위 · wn_23 의 stderr 경고 |
| 11-22 03:3x | 메인 재실행 — `bash hooks/tests/run.sh --baseline` | exit 0: **1 expected-failure confirmed · 427 green · 0 unexpected · 0 skipped**(보고와 일치). diff 3파일 전부 `hooks/tests/`. 커밋. 명세 ② 실패 정책에 출력 실패의 보장 범위(파이프 = 전부 아니면 전무, 그 밖의 부분 쓰기는 범위 밖)와 "stdout·stderr 가 함께 끊겨도 통과"를 적음 — 합의한 의도 안의 세부 확정으로 판단, 사용자에게 보고 |
| 11-22 03:3x | 구현 워커 후속 3 회수(누적 265k 토큰, 11 tool, 9분) — U2 | `hooks/gate-guard.sh` +17/−13, 전부 `worker_notice` 안: 경고 출력 세 곳을 각각 `( trap '' PIPE; … ) \|\| true` 로 감쌈(문구·판정 불변, 경고를 버리지 않음). 예상 실패 1행 삭제(manifest 가 main 원본과 같음), **`tests.lock` 재생성 사유: manifest 해시 1행 변경.** 뮤테이션: 감싼 것을 풀면 wn_23 빨강(exit 141) / 경고를 `2>/dev/null` 로 버리면 18개 빨강 / **`trap` 한 줄만 빼면 초록**(서브셸 + `\|\| true` 가 죽음을 흡수 — 실제 방어선은 그쪽이고 trap 은 테스트로 구별되지 않는 보조). 남은 한계: `worker_notice` 밖의 기존 경고·차단 메시지는 stderr 가 끊기면 여전히 죽을 수 있다(범위 밖 — NEXT 후보) |
| 11-22 03:4x | 메인 재실행 1차 — `bash hooks/tests/run.sh` | **exit 1 — INTEGRITY VIOLATION**(배포본 `~/.claude` 의 core.md·playbooks/review*.md·templates 해시가 실행 중에 바뀜). 원인: 다른 세션이 03:40 에 PR #9(review-reproduction-impact)를 병합하고 03:41 에 `deploy.sh` 를 실행(`pgrep` 으로 확인, `harness-wt-review` 워크트리). 테스트가 바꾼 것이 아님 |
| 11-22 03:4x | 메인 재실행 2차 | exit 0: **428 passed, 0 failed, 0 skipped**, 무결성 위반 없음(보고와 일치). diff 3파일. 커밋 bf48f89 |
| 11-22 03:5x | 원격 main 이 앞서감(2f07fb0 → e267751, PR #9: 리뷰 지적의 재현·영향 등급 — `playbooks/review.md`·`review-triage.md`·새 `review-reproduction.md`·core §8 한 줄·templates) → 브랜치에 병합(06af9c2) | 충돌 없음(자동 병합: README·core). core 147줄 그대로, 우리 변경과 겹치는 문장 없음(그쪽은 §8 표의 review 행). 병합 뒤 `bash hooks/tests/run.sh`: **428 passed, 0 failed, 0 skipped**. 참고: 새 규칙(코드 동작 지적은 재현 뒤 채택)은 이 작업의 루프 3 뒤에 들어왔다 — 루프 3 의 U1·U2 는 리뷰어 실험으로, U3 은 strace 실측으로 재현이 있었다 |
| 11-22 03:5x | **수정 후 재점검**(codex — 루프 3 판정표 + diff c5ab13e..bf48f89 + 실측) | U1~U4 모두 해소, 새 결함 없음. **리뷰 종료**(루프 3 회, 미해결 없음). 후보 K1~K7 은 NEXT 로 |
| 11-22 04:0x | 사이클 마감 — 완료 요약(Opus 워커 110k 토큰, 14 tool, 2분 — 스니펫은 실파일·`git show` 에서 추출) · `docs/plans/NEXT.md` N13 · `docs/measurement-log.md` 1행 | 메인 교차 확인: 요약의 코드 블록 51줄 중 48줄이 현재 파일·기준 파일과 글자까지 같고, 나머지 3줄은 diff 머리와 지워진 옛 줄(run.sh). **CS 이슈 후보 3**(①알림을 "한 번만" 내는 순서 — 기록 먼저면 빠질 수 있고 출력 먼저면 겹칠 수 있다 ②닫힌 파이프와 SIGPIPE — 경고를 쓰다 죽는 훅 ③테스트가 건너뛴 것을 통과로 세는 것 · 시간에 기대는 경합 사례) — study-note 아카이브는 이 작업 명세의 범위 밖이라 보류, 사용자 확인 뒤 진행. 남은 것: push · PR · 병합 · `deploy.sh` · 새 세션 확인(각각 사용자 확인) |
| 11-22 04:2x | 사용자: "진행하자 … 별도 하네스 수정(리뷰 쪽)과 충돌 없이 깔끔하게 되는지도 확인하고 합쳐서 진행하고 스터디 노트도 아카이브 진행하자" | push · PR · 병합 · `deploy.sh` · study-note 아카이브 승인. main 이 다시 앞서감(PR #10 — 문서 2파일) → 병합: `docs/plans/NEXT.md` 머리 줄 충돌 1(양쪽의 "마지막 갱신" — 두 사실을 합쳐 해결) |
| 11-22 04:3x | 두 변경의 정합 검토(codex — 합쳐진 core.md · review 3문서 · 템플릿 2 전문) | **실제 충돌 1**: `review-reproduction.md` §1·§2 가 메인이 재현 테스트를 쓰고 작업 트리로 옮긴다고 적음 ↔ core §5 구현 주체. 읽기에 따라 1(저장소 밖 worktree 의 테스트가 L1 인가). 충돌 아님 2("메인은 리뷰어가 아니다" ↔ main-synthesis · "지금 고친다 = 채택" 용어 대응). → 명세 ② 에 정합 조항 추가(재현은 메인도 가능, 작업 트리로 옮기는 것은 구현 워커), 문서 워커에게 위임 |
| 11-22 04:4x | 문서 워커 후속 4 회수(누적 185k 토큰) — 리뷰 재현 규칙과의 정합 | core §5 구현 주체 줄의 "메인이 직접 해도 되는 것"에 "리뷰 지적의 재현(저장소 밖 임시 worktree — `review-reproduction.md` §2. 채택한 재현 테스트를 작업 트리로 옮기는 것은 구현 워커)" · 변경 이력 v4.8 · `review-reproduction.md` §2 한 구절("core §5 구현 주체(중간↑ = 구현 워커)가 작업 트리로 옮겨") · HISTORY. core 147줄 15404자(+120). 재현 절차·`review.md`·`review-triage.md` 무변경. 남은 것: 저장소 밖 임시 worktree 의 쓰기가 L1 인지는 core §1·C1 의 읽기에 달림(범위 밖 — NEXT). 메인 재실행: `bash hooks/tests/run.sh` **428 passed, 0 failed, 0 skipped**. 커밋 |

## 리뷰 ledger

### 루프 1 (O = Opus 리뷰어, C = codex) — 종합·감사 원문: 세션 scratchpad `review-harness-1/`

| # | 지적 | 출처 | 판정 | 처리 |
|---|------|------|------|------|
| S1 | 알림 잠금 파일을 심링크 확인 없이 `>>` 로 연다 — 바깥에 파일이 생길 수 있음 | C1 | 지금 고친다 | 잠금 파일을 만들 때만 배타 생성, 여는 것은 읽기 전용(심링크여도 바깥에 쓰지 않는다). 사례 추가 |
| S2 | 기록 뒤 출력이 실패하면 "한 번"이 소비되고 알림은 안 보임 | C2 | 지금 고친다(감사로 방향 변경) | 잠금 안에서 출력, 실패하면 기록을 되돌리고 stderr 한 줄. 명세는 바꾸지 않는다 |
| S3 | 실패 정책·사이드카 보호의 줄을 지워도 통과(임시 파일 실패 주입 무효 · 사이드카 심링크 · stderr 한 줄 · 읽기 실패) | C3·O-F3 | 지금 고친다 | 사례 추가(이름에 기대는 것은 fix verification test 로 분류) |
| S4 | lazy 모드에서 누가 구현하는지 없음 | O-F1 | 지금 고친다(사용자 결정) | 예외에 lazy 추가 — 명세·core·README |
| S5 | §2 교차 확인이 explorer 로만 좁혀짐(날조 방어선 축소) | O-F2 | 지금 고친다 | 범위를 워커 결과 전반으로 되돌림 |
| S6 | README "메인의 초안" — 열 제목·결론 서술과 어긋남 | O-OQ4·감사 | 지금 고친다 | 본체 초안은 메인이 썼다는 사실과 그에 맞춘 결론 |
| K1 | `/clear` 뒤 같은 세션 ID 면 알림이 다시 뜨지 않음 | O-OQ1 | 후보 | session-mode-guard 를 건드려야 함 — NEXT |
| K2 | 이월된 DEBT=1 동안 알림이 빠짐 | O-OQ2 | 후보 | 명세 세부대로 — NEXT 에 관찰로 |
| K3 | 다른 훅들의 잠금 파일도 같은 `>>` 관례 | 메인(S1 에서 파생) | 후보 | 이번 대상은 gate-guard 의 새 코드 — NEXT |
| — | `review.md:70` "spec-우선" · README 강도표 리뷰 행 동기화 · TASK_PATH 개행 | O-OQ3·5·C-OQ | 판정 끝 | 사용자 결정(그대로) · 정합 우선 · 들어올 수 없음 |

### 루프 2 — 종합·감사 원문: 세션 scratchpad `review-harness-2/`

정지 규칙: S2 의 수정(되돌리기)에서 새 결함 3건 → 되돌리기를 없애고 순서를 재설계(준비 → 출력 → 확정).

| # | 지적 | 출처 | 판정 | 처리 |
|---|------|------|------|------|
| T1 | 출력과 되돌리기가 함께 실패하면 한 번 소비 | C1 | 지금 고친다 | 재설계 — 되돌리기 경로가 없어진다 |
| T2 | 끝 개행 없는 사이드카에서 되돌리기가 다른 폴더 기록을 지움 | C2 | 지금 고친다 | 재설계 + 준비 단계가 줄 경계 보존. 사례 |
| T3 | SIGPIPE 면 되돌리기를 건너뛰고 경고가 원인을 잘못 말함 | O-F1 | 지금 고친다 | 잠금 서브셸 안 `trap '' PIPE`. 사례 |
| T4 | 출력 실패 때 다른 폴더 기록 보존을 고정하는 사례 없음 | O-F2 | 지금 고친다 | 사이드카 바이트 비교 사례 |
| T5 | 실패 원인을 한 경고 문구로 묶음(rc 3 포함) | O-F3·질문 | 지금 고친다 | 단계별 문구(잠금 / 준비 / 출력 / 확정) |
| T6 | 건너뛴 사례가 통과로 집계(root 의 wn_19d, /dev/full 없는 wn_17) | C4·O 질문 | 지금 고친다(감사로 강화) | 환경에 기대지 않는 실패 주입 + 러너가 건너뜀을 따로 센다 |
| T7 | "구현 워커"의 범위 · 정책 파일이 대상인지 | O 질문 | 지금 고친다(사용자 결정) | c709cee |
| T8 | wn_14b 가 1.5초 지연에 기댐 | C3 | 지금 고친다(감사로 방향 변경 — 처음 판정은 후보) | 장벽 또는 동등한 경합 확인 |
| T9 | 기존 wn_18b 기대값이 새 순서와 충돌 | 감사 | 지금 고친다 | 기대값 변경 + 확정 실패 뒤 재호출 사례 |
| K5 | `/proc` 없는 환경에서 fd 동일성 검사 생략 | C 질문 | 후보 | 배포 대상은 Linux, 경로 재검사는 남음 — NEXT |
| — | 느린 stdout 이 다른 호출의 잠금 대기를 넘기면 그 호출은 알림 생략 | C 질문·감사 | 판정 끝 | 명세에 뜻 명시(한 번을 소비하지 않아 다음 쓰기에서 뜬다) |

### 루프 3 — 종합·감사 원문: 세션 scratchpad `review-harness-3/`

| # | 지적 | 출처 | 판정 | 처리 |
|---|------|------|------|------|
| U1 | wn_14b 가 "확인이 잠금 밖" 변형을 못 잡음(장벽 제한 > flock 대기) | C2·O-F1·감사 | 지금 고친다 | 둘째 호출이 확인·잠금에 도달한 것을 관측한 뒤 장벽을 풀고, 관측하지 못하면 실패. 두 변형(잠금 없음 / 확인이 잠금 밖) 빨강 실측 |
| U2 | stdout·stderr 가 함께 끊기면 경고 출력에서 SIGPIPE, exit 141 | O-F2·감사 | 지금 고친다 | 경고 출력에만 한정해 SIGPIPE 를 견딘다(정상 실패 경로의 경고는 유지). 사례 |
| U3 | JSON 일부만 나간 뒤 실패하면 잘린 JSON 이 stdout 에 남음 | C1·감사 | 지금 고친다(감사로 방향 변경 — 처음 판정은 판정 끝) | 알림 출력이 한 번의 write 인지 실측 → 명세에 보장 범위를 적는다(파이프: 전부 아니면 전무 / 파이프가 아닌 stdout 의 부분 쓰기는 범위 밖) |
| U4 | wn_21·21b 가 출력 실패의 단계 낱말을 단언하지 않음 | O 질문 | 지금 고친다 | 단언 추가 |
| K6 | baseline 에서 예상 실패 사례가 건너뛰면 MISMATCH 문구가 "unexpected-pass" | O 질문 | 후보 | 막는 쪽이라 안전 — NEXT |
| K7 | 강제 종료 시 임시 파일 잔재 · rm 실패 | C 질문·O 질문 | 후보 | 다른 사이드카와 같은 관례 — NEXT |
| — | 일반 모드는 전부 건너뛰어도 exit 0 | O 질문 | 판정 끝 | 회수 규칙이 메인에게 건너뜀 수를 세게 한다 |

## 생략한 검증

- 없음(11-22 기준 — 배포 뒤 확인 2건은 "남은 것"에: `deploy.sh` smoke · 새 세션에서 알림이 메인에게만 보이는지).

## 완료 요약 (2026-11-22)

- 범위: 중간↑ stakes 의 L1(실행 정책 파일 포함)은 Opus 워커가 쓰고 메인은 PM — 문서 규칙(core §0.2·§2·§4·§5·§6, README, HISTORY, 측정 로그 템플릿) + gate-guard 의 메인 직접 쓰기 알림(차단 아님) + 테스트·러너.
- 커밋(2f07fb0..bf48f89, 14개): 7d1fb9a · ad5395e(문서) · 6b8ade1 → 6b0a43c → f66b1f5(훅 사례 → 구현 → 동시 호출 보강) · 1dd9385 · afeb28d · a27d077(루프 1) · c709cee · f764be8 · c5ab13e(루프 2) · 6d43fd9 · bf48f89(루프 3). 06af9c2 는 main e267751(PR #9) 병합 — 충돌 없음, 이 요약의 diff 에서 뺐다.
- 파일(`git diff 2f07fb0 bf48f89 --stat` — 11 files, +2293/−17): `src/core.md` +17 · `README.md` +25 · `HISTORY.md` +1 · `templates/measurement-log.md` ±1 · `hooks/gate-guard.sh` +103 · 새 `hooks/tests/cases/worker-notice.sh` 1238줄 · 새 `hooks/tests/fixtures/legacy-2f07fb0/`(gate-guard·state-lib 기준 사본) · `hooks/tests/lib.sh` +4 · `run.sh` +12 · `tests.lock`.

### 무엇을 바꿨나

- **문서 규칙**: core §5 에 "구현 주체"(중간↑ L1 = Opus 워커, 메인 직접 = 낮음·긴급·사용자 확인 조작·lazy)와 "구현 워커 회수"(테스트 재실행으로 통과·실패·건너뜀 계수, diff 범위 대조, 동시 워커는 마지막 상태 재확인) 두 줄을 새로 넣고, 워커 위임 줄에 리뷰 역할(리뷰어가 찾고 메인이 판정)을 적었다. §4 강도표 중간 테스트 설계 = 구현자와 다른 워커. §0.2 는 상시 주입 문서 크기에 대한 원칙으로 한정. README 강도표 사본·원칙 5·실측 절을 맞췄다.
- **훅 알림**: `gate-guard` 의 auto 분기에서 `reread_gate` 통과 뒤 `worker_notice` — PreToolUse · 메인(`agent_id` 없음) · DEBT≠1 일 때, 세션·작업 폴더마다 한 번 `additionalContext` JSON 을 낸다. 기억 = `<sid>.worker-notice` 사이드카. 한 잠금 안에서 준비 → 출력 → 확정 순서, 실패하면 stdout 없이 통과하고 stderr 에 단계별 경고 한 줄.
- **테스트·러너**: 사례 52개(`worker-notice.sh`), `skip_test` 표식과 러너의 건너뜀 별도 집계(건너뜀 ≠ 통과).

### 핵심 diff

core §4 강도표 — before(`git show 2f07fb0:src/core.md` 88행) / after(`src/core.md:88`):

```
| 테스트 설계 | 구현자 | 분리 패스(spec 먼저) | 별도 워커 — 구현 diff 미열람 계약 |
| 테스트 설계 | 구현자 | 구현자와 다른 워커 — 명세에서 출발 | 별도 워커 — 구현 diff 미열람 계약 |
```

core §5 — before(`git show 2f07fb0:src/core.md` 97행. 구현 주체·회수 줄은 없었다):

```
- **워커 위임(기본 Opus·high — 사용 모델 측정로그 기록)**: 독립 모듈 병렬 구현 · 테스트 설계·리뷰·독립 검증 · 완료 문서·diff 조사(실파일 재읽기 강제).
```

after(`src/core.md:97-99`):

```
- **구현 주체**: stakes 중간·높음의 L1(§1 — 실행 정책 파일 포함) 작성·수정은 Opus 워커가 한다 — 메인은 직접 쓰지 않는다. 메인이 직접 해도 되는 것 = 낮은 stakes 작업 · 긴급 수정 · 사용자 확인이 필요한 조작(서버·DB 조작·발행) · lazy 모드의 작업(매 diff를 메인이 쓰고 설명 — `implementation-lazymode.md`). **위임의 목적은 품질(생성≠검증)과 메인 컨텍스트 보호** — 토큰 증가는 받아들이고, 비용을 이유로 메인이 직접 구현하지 않는다(근거 = README "실측" 절).
- **워커 위임(기본 Opus·high — 사용 모델 측정로그 기록)**: 구현(위) · 테스트 설계(강도표) · 리뷰(중간↑ — 리뷰어 = Opus 워커 ∥ codex가 결함을 찾고, 메인은 그 지적을 명세에 비추어 기각 / 지금 고친다 / 후보로 판정한다. 메인은 리뷰어가 아니다 — `review.md` §1) · 독립 검증 · 완료 문서·diff 조사(실파일 재읽기 강제).
- **구현 워커 회수(메인이 직접 — L1을 쓰는 워커는 테스트 설계·리뷰 반영 포함 모두 구현 워커)**: 워커가 보고한 테스트를 다시 돌려 통과·실패·건너뜀 수를 센다(건너뜀 ≠ 통과) · 보고와 실제 diff 범위 대조(범위 밖 파일·커밋 메시지 규칙) · 같은 저장소에 워커를 동시에 넣으면 파일 범위를 나누고, 모두 끝난 마지막 상태에서 빌드·테스트를 다시 확인.
```

`worker_notice` 임계구역 — 확인 → ① 준비 → ② 출력 → ③ 확정(새 코드, `hooks/gate-guard.sh:433-466`):

```bash
  (
    # 닫힌 파이프로 출력해도 SIGPIPE 로 죽지 않고 printf 가 실패를 돌려주게 — 이 잠금 서브셸 안에만(훅의 다른 부분과 무관).
    trap '' PIPE
    if [ ! -e "$notice_lock" ] && [ ! -L "$notice_lock" ]; then
      ( set -C; : > "$notice_lock" ) 2>/dev/null || true   # 경합으로 다른 호출이 먼저 만들었으면 그것을 쓴다
    fi
    { [ -f "$notice_lock" ] && [ ! -L "$notice_lock" ]; } || exit 1   # 심링크·비정규 — 열지 않는다(FIFO 막힘도 피함)
    exec 9<"$notice_lock" || exit 1
    { [ -f "$notice_lock" ] && [ ! -L "$notice_lock" ]; } || exit 1   # 검사와 열기 사이에 바뀐 자리
    if [ -e /proc/self/fd/9 ]; then [ "$notice_lock" -ef /proc/self/fd/9 ] || exit 1; fi   # 연 fd = 그 자리의 파일
    flock -x -w 2 9 || exit 1
    # 확인 — 사이드카를 읽지 못하는 실패(심링크·디렉토리·FIFO·읽기 불가)는 준비 실패로 묶는다.
    if [ -e "$notice_sidecar" ] || [ -L "$notice_sidecar" ]; then
      { [ -f "$notice_sidecar" ] && [ ! -L "$notice_sidecar" ]; } || exit 2   # 심링크·비정규 — 그 너머로 읽거나 쓰지 않는다
      grep -qxF -- "$task_path" "$notice_sidecar"; seen_rc=$?
      [ "$seen_rc" = 0 ] && exit 10
      [ "$seen_rc" = 1 ] || exit 2                    # rc 2 = 읽기 실패("없음"으로 보지 않는다)
    fi
    # ① 준비
    temporary_file=$(mktemp "$state_dir/.worker-notice.XXXXXX") || exit 2
    if [ -e "$notice_sidecar" ]; then
      cat -- "$notice_sidecar" > "$temporary_file" || { rm -f -- "$temporary_file"; exit 2; }
      # 끝 개행이 없으면 먼저 보탠다 — 이번 줄이 기존 마지막 줄에 붙어 두 기록이 함께 깨지지 않게(줄 경계 보존).
      if [ -s "$notice_sidecar" ]; then
        last_byte=$(tail -c 1 -- "$notice_sidecar") || { rm -f -- "$temporary_file"; exit 2; }
        if [ -n "$last_byte" ]; then printf '\n' >> "$temporary_file" || { rm -f -- "$temporary_file"; exit 2; }; fi
      fi
    fi
    printf '%s\n' "$task_path" >> "$temporary_file" || { rm -f -- "$temporary_file"; exit 2; }
    # ② 출력
    printf '%s\n' "$notice_json" || { rm -f -- "$temporary_file"; exit 3; }
    # ③ 확정
    mv -fT -- "$temporary_file" "$notice_sidecar" || { rm -f -- "$temporary_file"; exit 4; }
  ) 2>/dev/null || record_rc=$?
```

경고 구간 — 경고 출력만 SIGPIPE 를 견딘다(새 코드, `hooks/gate-guard.sh:467-480`):

```bash
  # 경고 출력만 SIGPIPE 를 견딘다 — stdout·stderr 가 함께 끊긴 파이프면 경고를 쓰다 죽어(exit 141) 통과가 깨진다.
  #   이 서브셸 안에만 trap 을 건다(함수·훅 전체로 번지지 않게). 경고를 2>/dev/null 로 버리지는 않는다 —
  #   stderr 가 살아 있는 정상 실패 경로의 경고 한 줄은 그대로 나가야 한다.
  (
    trap '' PIPE
    case "$record_rc" in
      0|10) ;;
      1) echo "[gate-guard] 경고: 구현 주체 알림 생략 — 잠금 실패($notice_lock). 다음 쓰기에서 다시 시도(통과)." >&2 ;;
      2) echo "[gate-guard] 경고: 구현 주체 알림 생략 — 준비 실패(사이드카 $notice_sidecar 읽기 또는 임시 파일). 기록은 그대로(통과)." >&2 ;;
      3) echo "[gate-guard] 경고: 구현 주체 알림 생략 — 출력 실패(stdout). 기록은 그대로라 다음 쓰기에서 다시 뜬다(통과)." >&2 ;;
      4) echo "[gate-guard] 경고: 구현 주체 알림은 나갔으나 확정 실패($notice_sidecar 이름 바꾸기) — 다음 쓰기에서 한 번 더 뜬다(통과)." >&2 ;;
      *) echo "[gate-guard] 경고: 구현 주체 알림 — 예상 밖 실패(rc $record_rc). 기록 여부 불명(통과)." >&2 ;;
    esac
  ) || true
```

`run.sh` 건너뜀 집계(`git diff 2f07fb0 bf48f89 -- hooks/tests/run.sh` 에서 발췌):

```diff
@@ -136,7 +137,11 @@ for casefile in cases/*.sh; do
       "$t"
     } 2>&1 )
     rc=$?
-    if [ "$rc" = "0" ]; then
+    if [ "$rc" = "0" ] && printf '%s\n' "$out" | grep -q '^SKIP_TEST '; then
+      reason=$(printf '%s\n' "$out" | grep '^SKIP_TEST ' | tail -1 | awk '{print $3}')
+      SKIPS+=("$t ${reason:-unknown}")
+      [ "$MODE" = "normal" ] && echo "SKIP $t (${reason:-unknown})"
+    elif [ "$rc" = "0" ]; then
       PASS=$((PASS+1))
     else
       aid=$(printf '%s\n' "$out" | grep -E '^FAIL_ASSERT ' | tail -1 | awk '{print $3}')
-  echo "── $PASS passed, ${#FAILS[@]} failed"
+  echo "── $PASS passed, ${#FAILS[@]} failed, ${#SKIPS[@]} skipped"
-  echo "── baseline OK: $(printf '%s\n' "$expected" | grep -c .) expected-failure confirmed, $PASS green, 0 unexpected"
+  echo "── baseline OK: $(printf '%s\n' "$expected" | grep -c .) expected-failure confirmed, $PASS green, 0 unexpected, ${#SKIPS[@]} skipped"
+  if [ "${#SKIPS[@]}" -gt 0 ]; then printf '  skipped: %s\n' "${SKIPS[@]}"; fi
```

### 검증

- 테스트: 376 green(착수 전) → 409(사례 33, 구현 전 예상 실패 33) → 410 → 420 → 426 → **428 passed, 0 failed, 0 skipped**(bf48f89, 메인 재실행). main 병합(06af9c2) 뒤에도 428/0/0. 재실행 1회는 다른 세션의 `deploy.sh`(03:41) 때문에 무결성 위반으로 실패 — 테스트가 바꾼 것이 아님을 `pgrep` 으로 확인하고 다시 돌렸다.
- 가정 실증(task 01): 가정 1 맞음(메인 입력에 `agent_id` 없음, 서브 에이전트에 있음) · 가정 2 틀림 → 통과 시 일반 stdout·stderr 는 모델에게 안 보이고 `additionalContext` 만 보여 알림을 JSON 으로 냈다.
- 설계 선검증(codex): 모호 6 · 위험 5 → 명세 ② "훅 알림의 세부" 절 추가.
- 리뷰 루프 1: codex 3 · Opus 3(+질문 5) → S1~S6 지금 고친다, K1~K3 후보.
- 리뷰 루프 2: codex 4 · Opus 3(+질문 5) → T1~T9 지금 고친다, K5 후보. **정지 규칙 1회 적용** — S2 의 되돌리기 수정에서 새 결함 3건 → 되돌리기를 없애고 준비 → 출력 → 확정으로 재설계(사용자 결정: 빠지지 않게, 한 번 더는 수용).
- 리뷰 루프 3: 공통 1 · Opus 1 · codex 1(+질문 5) → U1~U4 지금 고친다, K6·K7 후보. U3 은 strace 로 알림이 한 번의 write(2)·313바이트임을 실측하고 보장 범위를 명세에 적었다.
- 수정 후 재점검(codex, c5ab13e..bf48f89): U1~U4 해소, 새 결함 없음 → 리뷰 종료(3루프, 미해결 없음).
- 뮤테이션(워커 실측): 잠금 제거·확인을 잠금 밖으로·출력 전 확정·trap 제거·줄 경계 보탬 제거·경고 감싸기 해제가 각각 빨강. 단 경고 구간의 `trap` 한 줄만 빼면 초록 — 실제 방어선은 서브셸 + `|| true` 다.
- 생략한 검증: 기록 없음(절 비어 있음).

### 남은 것

- 배포·새 세션 확인 미실시: 브랜치 push · PR · 병합 · `deploy.sh` · 새 세션에서 메인 Edit 에 알림이 보이고 워커 Edit 에 안 보이는지 · core 새 문장 주입 — 각각 사용자 확인 대기.
- 리뷰 후보(K4 는 ledger 에 없음 — 결번): K1 `/clear` 뒤 같은 세션 ID 면 재알림 없음 · K2 이월된 DEBT=1 동안 알림 없음 · K3 다른 훅 잠금 파일의 `>>` 관례 · K5 `/proc` 없는 환경의 fd 동일성 검사 생략 · K6 baseline 에서 예상 실패 사례가 건너뛰면 "unexpected-pass" 문구 · K7 강제 종료 시 임시 파일 잔재·rm 실패.
- 그 밖의 NEXT 후보(log): `capture-decision` 이 작업 폴더가 바뀔 때 세션 전체 질문·답을 옮겨 적음(원인 미확인) · 기존 lazy Bash 소프트 리마인더(일반 stdout)가 모델에게 안 보일 가능성 · `decision-reread.sh` 9곳·`detect-layer.sh` 2곳의 root `return 0` 이 통과로 집계 · `worker_notice` 밖의 경고·차단 메시지는 stderr 가 끊기면 SIGPIPE 로 죽을 수 있음.
- log 에 남긴 관찰(NEXT 후보 표시는 없음): 워커가 테스트를 돌리는 동안 메인이 그 저장소를 고치지 않는다(회수 규칙에 더할 것) · 테스트 중 다른 세션의 배포가 무결성 위반을 낸다 · §8 "각 ≤80줄"을 원래 넘던 `open-source.md`·`review.md`.

### 알려진 한계 (명세가 받아들인 것)

- 잠금 대기 실패(2초) 등으로 한 호출에서 알림이 생략될 수 있다 — 그 호출은 한 번을 소비하지 않아 같은 폴더의 다음 쓰기에서 뜬다.
- 출력 뒤 확정(mv)만 실패하면 다음 호출에서 한 번 더 뜬다(빠지는 것보다 중복을 택함).
- 파이프가 아닌 stdout(파일 리디렉션의 디스크 풀 등)에서 JSON 일부만 쓰이는 경우는 보장 범위 밖 — 파이프에서는 PIPE_BUF 이하 한 번의 write 라 전부 아니면 전무.
- 훅은 stakes 를 모른다 — "낮은 stakes 제외"는 알림 문장 안의 안내이고, 낮은 stakes 작업에서도 폴더당 한 번은 뜬다.
- Bash 로 쓰는 경우는 판별하지 않는다(절차 규칙).
