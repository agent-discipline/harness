# log — lazymode 게이트 질문의 자기완결 재발 방지 + 사전 점검 정식화

## 수정 이유 (착수 전 기록)

### 무엇이 일어났나

- 2026-11-14, 다른 프로젝트(Rust 학습 lab, lazy 모드)의 diff 게이트에서 재질문을 **코드 없이 서술로만** 냈다(테스트 시나리오·수정 내용을 말로 설명). 사용자: "너 왜자꾸 코드를 안보여주고 질문해?"
- 같은 세션에서 앞선 재질문·사전 점검 힌트들도 "위에서 보여 줬으니" 근거 코드를 다시 붙이지 않은 경우가 반복됐다.
- 사용자의 정의: lazy 게이트는 **보여 준 코드를 다시 읽고 이해했는지** 묻는 것 — 사용자가 IDE를 켜거나 대화를 스크롤하지 않고, **메시지에 보인 코드를 신뢰해 답하는 구조**여야 한다. 사용자는 이것을 습관 문제가 아니라 하네스 개선 대상으로 판단.

### 재발 이력 (같은 결함 3회째)

| 날짜 | 지적 | 그때의 조치 |
|---|---|---|
| 2026-09-03 | 재질문이 "파일:줄을 다시 보라"만 던짐 | playbook §4 "fail 재질문 = 자기완결 패킷" 추가 |
| 2026-09-07 | 같은 지적 재발 | §3.1 "자기완결 플로우 브리핑" 보강 |
| 2026-11-14 | 재질문·힌트에 코드 누락 재발 | 이 작업 |

### 원인 (실파일 확인)

1. **규칙은 있는데 요약 뒤에 안 보인다.** playbook은 core §8 트리거 문서라 세션 초반에 한 번 읽힌다. 긴 lazy 세션은 대화 요약(compaction)을 거치고, 그 뒤엔 playbook 본문이 컨텍스트에 없다. 매 턴 들어오는 것은 `hooks/reinject-mode.sh`의 한 줄뿐인데(52행), 그 줄은 "before/after 스니펫 기록 → 주관식 → 판정 워커 → gate-pass" 흐름만 말하고 **자기완결 규칙이 없다.**
2. **규칙의 적용 범위가 좁다.** §4 44행은 "fail 재질문"만 대상이다. 판정 전 사전 점검 힌트, 보충 질문, 후속 질문은 문언상 빠져 있고 — 이번 누락은 주로 거기서 났다.
3. **사전 점검이 규칙에 없다.** 판정 워커에 보내기 전 답을 실코드와 대조해 힌트로 다듬게 하는 단계를 실제로 쓰고 있지만(개인 메모리에만 있음), playbook에 없어서 그 단계의 메시지 형식(자기완결)·시도 산정·워커 전달 방식이 정의되지 않았다.

### 왜 이 방법인가

- 메시지 내용을 훅으로 검사하는 장치는 만들지 않는다 — 어시스턴트 메시지의 "코드가 충분한가"는 결정론적으로 판정할 수 없다(core §0.5 강제는 훅, 판단은 문서).
- 대신 **매 턴 보이는 재주입 줄**에 규칙을 넣는다(요약 뒤에도 보이는 유일한 상시 채널) + playbook에서 규칙의 적용 범위를 모든 게이트 메시지로 넓히고 한 곳에 둔다 + 사전 점검을 정식 절차로.

## 타임라인

| 시각 | 사건 | 결과/결정 |
|------|------|----------|
| 2026-11-14 | 사용자 지적 → 원인 조사(playbook §3.1·§4, reinject-mode.sh 52행) → 인터뷰 3문(범위: 재주입+playbook · 사전 점검 정식화: 넣는다 · 모드: auto) → requirement-spec.md 작성 | 명세 초안 |
| 2026-11-14 | 사용자 합의 → set-state spec-approved · mode auto. 브랜치 feat/lazymode-self-contained-gate(main f43c4a7). 사용자 요청: 작업 후 push까지 | L1 진입 |
| 2026-11-14 | 사용자 "수정 이유 문서부터" → 이 log의 '수정 이유' 절을 코드 수정 전에 작성 | 착수 전 기록 |
| 2026-11-14 | task 01: misc-guards.sh에 rm_07(lazy 줄에 '자기완결'·'파일:줄'·'사전 점검' + 한 줄)·rm_08(auto 줄에 '자기완결' 없음) 추가. tests.lock 재생성 사유: 신규 케이스 2건(258→260) → 현 코드 run.sh **259 passed, 1 failed**(rm_07 reinject-lazy-selfcontained-rule) | red 확인 |
| 2026-11-14 | task 02: reinject-mode.sh lazy 줄에 "사전 점검(실코드 대조·정답 비노출 힌트, 시도 미산정)" 단계 + "★ 질문·재질문·힌트는 매번 자기완결 — 근거 코드를 파일:줄과 함께 그 메시지에 다시 붙인다(앞서 보였어도)" 추가(한 줄 유지) → run.sh **260 passed, 0 failed** | green |
| 2026-11-14 | task 03: playbook §1에 자기완결 규칙(모든 게이트 메시지 — 단일 출처) · §3.1 흐름에 ②' 사전 점검 + 브리핑은 §1 참조 · §4 사전 점검 절차 + 패킷에 튜터 공급 표시 · fail 재질문은 §1 참조로 축약. 57줄. 커밋 02fd18a | 구현 완료 |
| 2026-11-14 | task 04 리뷰 loop1 착수: packet base f43c4a7, `$OUT`=scratchpad/rv.9wX7, mirror=rv.9wX7/mirror.7PHx. 보안 스캔: hooks/tests/cases/git-guard.sh 가짜 토큰 픽스처(ghp_SECRETTOKEN…·ghp_CFGLEAK…)·codex-scan.sh PEM 패턴 문자열 매칭 — 테스트 픽스처·탐지 패턴이라 오탐 판정, 통과. Opus 워커 ∥ codex(medium, read-only) 병렬 | 회수 대기 |
| 2026-11-14 | loop1 회수: Opus — F1 1건(playbook:41 사전 점검 '새 형태 재질문' 문장이 R4 밖 + 상한 없음 → §1 '무한 차단 없음'과 충돌) + Q 3건 · codex — 미러 모드 `bwrap: loopback: Failed RTM_NEWADDR` 로 파일 미열람(NEXT N1 재발) → 1회 재시도를 인라인 입력(spec+diff+related+변경 파일·lib.sh·src/core.md 전문, 87KB)으로 → F1 'log.md 누락' + open Q 2 | 종합 |
| 2026-11-14 | ② 종합 → ③ codex 감사(인라인): "log 기각 사유 과도 — 패킷 제외는 결함 아님, 단 존재·기록은 메인이 실파일로 확인해 구분" · "UNSET은 문구 부재가 아니라 출력 전체 비교" → 반영 | 감사 반영 |
| 2026-11-14 | ④ 수정: playbook:41 문장 삭제 · rm_07에 '다시 붙인다' 단언 · rm_09(UNSET+DEBT=0 → 출력 없음). tests.lock 사유: fix verification test(rm_09 추가·rm_07 보강, 260→261). run.sh **261 passed**. 기준 훅(f43c4a7)으로 바꿔 돌리면 260 passed·rm_07만 실패 → rm_08·rm_09가 기준 동작에서도 통과(auto·UNSET 불변 증명). 커밋 7115858 | loop2로 |
| 2026-11-14 | loop2(packet base f43c4a7, `$OUT`=scratchpad/rv2.IOv4, mirror=rv2.IOv4/mirror.M89t; codex는 처음부터 인라인): Opus finding 0 + open Q 3(사전 점검 횟수 상한·§3.2·rm_09 부정 단언) · codex L2-01(rm_07 `grep -c .`는 빈 줄 미계수). ③ 감사: "`wc -l`도 `$(...)` 캡처가 끝 개행을 지워 끝 빈 줄을 못 봄 — stdout을 파일로 받아야" | 종합·감사 |
| 2026-11-14 | 수정: rm_07·rm_09 출력을 파일로 받아 바이트 그대로 검사(한 줄 = wc -l 1 + 마지막 바이트 개행 / UNSET = 0바이트) + rm_09에 같은 상태 DEBT=1 → 빚 줄 출력(상태 해석 확인). tests.lock 사유: fix verification test 보강(261 유지). run.sh 261 passed. 변이 확인: lazy echo 뒤 빈 줄 → rm_07 FAIL · UNSET이 개행만 출력 → rm_09 FAIL(훅 원복 확인). 커밋 60d1922 | loop3로 |
| 2026-11-14 | loop3(packet base f43c4a7, `$OUT`=scratchpad/rv3.nKFN, mirror=rv3.nKFN/mirror.LUUM; codex 인라인): Opus finding 0 · codex finding 0. 대칭 부담: 렌즈별 근거를 양쪽 모두 제출(R1·R2·R3·R4·R5·과잉 구현 — Opus·codex 각 file:line) → **종료 조건 충족**(open 0 · 신규 채택 0 · 대칭 부담) | 리뷰 종료 |
| 2026-11-14 | 배포: deploy.sh dry-run → 대상 4파일(reinject-mode.sh·misc-guards.sh·tests.lock·implementation-lazymode.md), DEST-only 0 → 실배포 → 내장 smoke 통과, diff 0, 백업 ~/.claude/.deploy-backup-700875. 추가 smoke: 배포 위치 `~/.claude/hooks/tests/run.sh` **261 passed**(HOOKS_DIR=배포 훅). 임시 상태파일로 직접 호출 시도는 gate-guard가 상태파일 경로 쓰기 차단(정상 보호) | 배포 완료 |
| 2026-11-14 | 사이클 마감: NEXT N1(codex bwrap 재발 기록)·N1b 신설(사전 점검 상한·§1 '메인은 verdict만' 문구 — 사용자 결정 대기) · 측정 로그 1행. 아카이브: 원 식별자 = claude-code-harness · reinject-mode · misc-guards · lazymode. CS 이슈 1건 = `$(...)`가 끝 개행을 지워 출력 형태 단언이 무력 → study-note shell/quoting-expansion-layers와 같은 원리(확장 계층), 해결이 다름 → ⓒ 방안 비교 append. 노출 스캔 0건 | 아카이브: issue/shell/quoting-expansion-layers ⓒ 5586e56b (archive/2026-11-14, push 대기) |
| 2026-11-14 | 완료 요약: 메인 작성(워커 위임 생략 — 변경 4파일·수 줄이고 스니펫은 실파일에서 기계적 복사) | 완료 |

## 리뷰 ledger (中↑ — 듀얼 리뷰가 돈 작업 필수)

- review packet loop3: base f43c4a7 / `$OUT`=scratchpad/rv3.nKFN / mirror=rv3.nKFN/mirror.LUUM (codex 인라인)
- review packet loop2: base f43c4a7 / `$OUT`=scratchpad/rv2.IOv4 / mirror=rv2.IOv4/mirror.M89t (codex 인라인)
- review packet loop1: base f43c4a7 / `$OUT`=scratchpad/rv.9wX7 / mirror=rv.9wX7/mirror.7PHx (codex는 인라인 재시도)

| id | first_seen_loop | source | 근거(file:line) | disposition | status | fixed_in_loop |
|----|-----------------|--------|-----------------|-------------|--------|---------------|
| L1-01 | 1 | opus | playbooks/implementation-lazymode.md:41 | 채택 | fixed | 1 |
| L1-02 | 1 | codex | docs/plans/2026-11-14/lazymode-self-contained-gate/log.md (누락) | 범위 밖 — review.md ⓪이 모든 log.md를 패킷에서 의도적으로 제외. 실파일 존재·red/green 기록은 메인이 확인(이 log 타임라인 task 01·02 행) | — | — |
| L1-03 | 1 | opus+감사 | hooks/tests/cases/misc-guards.sh (UNSET 미검증, R1) | 채택(fix verification test) | fixed | 1 |
| L2-01 | 2 | codex+감사 | hooks/tests/cases/misc-guards.sh:195 (한 줄 검사가 빈 줄·끝 개행을 못 봄, R2·§4) | 채택 | fixed | 2 |
| L2-Q1 | 2 | opus | playbooks/implementation-lazymode.md:41 (사전 점검 횟수 상한 없음) | open question — R4 범위 밖, 상한 추가는 승인 범위 변경 → 사용자 결정으로 보고 | — | — |
| L2-Q3 | 2 | opus | misc-guards.sh rm_09 (부정 단언만) | 채택(테스트 보강) | fixed | 2 |
| L1-04 | 1 | codex | hooks/tests/cases/misc-guards.sh:186-195 (지시 문구 단언 약함) | 채택(테스트 보강) | fixed | 1 |

- verified(loop3 — 신규 채택 0): R1 hook 출력 / reinject-mode.sh:52·55·58 / lazy 줄만 변경·auto·UNSET 불변 / opus·codex · R2 한 줄·요소 유지 / misc-guards.sh:195-199 / 파일 캡처 바이트 검사 / opus·codex · R3 단일 출처 / implementation-lazymode.md:18·31·41·46 / 본문 1곳 + 참조 / opus·codex · R4 사전 점검 / implementation-lazymode.md:41-42 / 대조·비노출 힌트·미산정·튜터 공급 표시 / opus·codex · R5 금지영역 / diff 범위 / 4파일+spec만 / opus·codex · 과잉 구현 / diff 전체 / 각 줄 R1~R4·§5 대응 / opus

## 생략한 검증

- 없음 (완료 요약 워커 위임만 생략 — 위 행)

## 완료 요약

**목표 대비**: lazy 게이트의 질문·재질문·힌트가 근거 코드를 다시 붙인 자기완결이어야 한다는 규칙을 요약 뒤에도 매 턴 보이게(R1·R2), playbook에 단일 출처로(R3), 사전 점검을 정식 절차로(R4) — 달성. 테스트 261 pass(repo·배포 위치), 듀얼 리뷰 3루프 종료, deploy 완료.

before `hooks/reinject-mode.sh:52` (f43c4a7)
```bash
    echo "[게이트] MODE=lazy (SPEC=${SPEC:-0}). 상태파일: $STATE (PENDING_GATE=${PENDING:-0}). 매 diff 이해 게이트 — before/after 스니펫 기록 → 사용자 주관식 설명 → 판정 워커 → 통과 시 set-state.sh gate-pass. (implementation-lazymode.md)"
```
after `hooks/reinject-mode.sh:52`
```bash
    echo "[게이트] MODE=lazy (SPEC=${SPEC:-0}). 상태파일: $STATE (PENDING_GATE=${PENDING:-0}). 매 diff 이해 게이트 — before/after 스니펫 기록 → 사용자 주관식 설명 → 사전 점검(실코드 대조·정답 비노출 힌트, 시도 미산정) → 판정 워커 → 통과 시 set-state.sh gate-pass. ★ 질문·재질문·힌트는 매번 자기완결 — 근거 코드를 파일:줄과 함께 그 메시지에 다시 붙인다(앞서 보였어도). (implementation-lazymode.md §1·§4)"
```

after `playbooks/implementation-lazymode.md:18` (신규 — 단일 출처)
```markdown
- **자기완결 (모든 게이트 메시지 — 이 규칙의 단일 출처)**: 최초 질문·사전 점검 힌트(§4)·fail 재질문·보충/후속 질문 전부, 답에 필요한 코드(diff + 연관 메서드의 내부 분기·호출 사슬)를 `파일:줄`과 함께 **그 메시지에 인라인**한다 — 앞서 보였어도 다시 붙인다. 가상 시나리오는 최소 코드 스케치로. 사용자는 IDE·스크롤 없이 **보인 코드를 신뢰해** 답한다. "파일:줄을 다시 보라"만 던지지 않는다. (실측 재발 2026-09-03·09-07·11-14 — 마지막은 대화 요약 뒤 이 문서가 다시 읽히지 않아서 → reinject 줄에 상시 상기.)
```
after `playbooks/implementation-lazymode.md:41-42` (신규 사전 점검 + 패킷 표시)
```markdown
- **사전 점검(메인, 판정 전)**: 사용자 답을 실코드와 대조 → 틀림·누락이 있으면 **정답 비노출 힌트**(형식은 §1 자기완결)로 되돌려 다듬게 한다. 시도(x/2)로 세지 않는다.
- **패킷 입력**: 실제 diff/코드 + 문서 before/after 스니펫(그라운드 트루스) + 게이트 질문 + 사용자 답변(사전 점검 왕복 포함 — 튜터가 공급한 힌트·설명은 **"튜터 공급"으로 표시**, 워커는 그것을 사용자 공로로 치지 않는다) + 루브릭.
```
before `playbooks/implementation-lazymode.md:44` (f43c4a7) → after `:46`
```markdown
- **fail 재질문 = 자기완결 패킷(메인 책임)**: 원래 질문 전체 재게시 + 답에 필요한 코드 스니펫 전부를 그 메시지에 인라인(호출 체인 구조만이 아니라 각 메서드 내부 분기까지) + 이전 답변의 맞은/틀린 부분 표시 + 힌트. "파일:줄을 다시 보라"만 던지지 않는다 — 사용자가 대화를 오가며 조립하게 하지 않는다(2026-09-03·09-07 실측 지적).
```
```markdown
- **fail 재질문(메인 책임)**: 원래 질문 전체 재게시 + 이전 답변의 맞은/틀린 부분 표시 + 힌트 — 코드 인라인은 §1 자기완결.
```

**알려진 한계**: 규칙 준수 자체는 훅이 판정하지 못한다(메시지 내용 검사 금지 — spec §4). 재주입은 상기일 뿐 — 재발 여부는 다음 lazy 세션에서 관측(NEXT N1b와 함께). 사전 점검 횟수 상한 없음(N1b).
