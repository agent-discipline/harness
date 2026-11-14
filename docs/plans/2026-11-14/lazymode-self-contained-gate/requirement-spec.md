# 요구사항 명세서 — lazymode 게이트 질문의 자기완결 재발 방지 + 사전 점검 정식화

> 작성일: 2026-11-14 · 작업 폴더: `docs/plans/2026-11-14/lazymode-self-contained-gate/`

---

## 0. 요구사항 원문 (인터뷰 기록)

- 원문(사용자, index-lab 2단계 diff 04 게이트 중): "너 왜자꾸 코드를 안보여주고 질문해?" → "재질문이나 그런걸할때 자꾸 위에 설명했으니 해당 코드 내용 갈취해서 계속 보여주는 부분을 빼먹는데 이건 하네스를 개선해야되는 부분일 꺼 같은데, 결국 레이지란 내가 정확히 이해했는지를 물어보는거고 그 내용을 보여줌으로써 다시한번 읽고 이해하고 답하라는 의미인데 … 내가 ide를 켜서 직접 코드를 보게하는게 아닌 저가 보여준 부분을 신뢰하고 그부분을 기반으로 답변하도록 해야하는거 아니야? 이부분은 하네스 개선이 필요할꺼 같은데"
- 조사 결과(실파일): 규칙 자체는 이미 있다 — `playbooks/implementation-lazymode.md` §3.1(30행 "자기완결 플로우 브리핑") · §4(44행 "fail 재질문 = 자기완결 패킷", 2026-09-03·09-07 실측 지적). 이번이 **3번째 재발**. 매 턴 재주입(`hooks/reinject-mode.sh` 52행 lazy 줄)에는 이 규칙이 없고, 대화 요약(compaction) 뒤 playbook은 다시 읽히지 않는다. 또 §4 규칙은 "fail 재질문"만 대상이라 사전 점검 힌트·후속 질문은 문언상 빠져 있다.
- Q/A:
  - Q1 개선 범위 → **재주입 + playbook**(권장안): reinject lazy 줄에 자기완결 규칙 추가 + playbook 규칙을 사전 점검 힌트·후속 질문까지 확장 + 훅 테스트 케이스.
  - Q2 사전 점검(판정 워커 전에 답을 실코드와 대조, 틀린 곳을 힌트로 코칭, 시도 미산정 — 현재 개인 메모리에만 있음)을 playbook에 정식화? → **넣는다**.
  - Q3 모드 → **auto**.

---

## 1. 목표·대상 (필수)

claude-code-harness의 `hooks/reinject-mode.sh`(lazy 재주입 줄)와 `playbooks/implementation-lazymode.md`(§1·§3.1·§4)를 고쳐, lazy 게이트의 **모든 질문·재질문·사전 점검 힌트가 근거 코드(파일:줄)를 그 메시지에 다시 붙인 자기완결 형태**여야 함을 요약 뒤에도 매 턴 상기시키고, **사전 점검 단계**를 정식 절차로 넣는다. 테스트 green + deploy + 신규 세션 smoke로 끝.

## 2. 경계·불변식 (필수)

- **R1** lazy 상태에서 reinject 출력에 자기완결 규칙(질문·재질문·힌트마다 근거 코드 파일:줄 재게시 — 사용자가 IDE·스크롤 없이 답한다)이 포함된다. auto·UNSET 출력은 바뀌지 않는다.
- **R2** reinject lazy 출력은 여전히 **한 줄**이고 기존 요소(MODE·SPEC·상태파일·PENDING_GATE·흐름·playbook 이름)를 유지한다 — 기존 테스트 `test_rm_05` 그대로 green.
- **R3** playbook: 자기완결 규칙이 **모든 게이트 메시지**(최초 질문·사전 점검 힌트·fail 재질문·후속 질문)에 적용됨을 한 곳(§1 게이트 형식)에 두고, §3.1·§4의 기존 문언은 그 한 곳을 가리키게 한다(단일 출처 — 중복 서술 금지).
- **R4** playbook §4에 사전 점검 절차: 판정 전 메인이 답을 실코드와 대조 → 틀린/빠진 곳을 **정답 비노출 힌트**(+ 근거 코드 인라인)로 되돌려 다듬게 함 → 시도(x/2)로 세지 않음 → 판정 워커 패킷에 **튜터가 공급한 내용(힌트·설명)을 표시**해 넘기고 워커는 그것을 사용자 공로로 치지 않는다.
- **R5** core.md·다른 playbook·다른 훅은 무변경. 상태파일 스키마(SCHEMA=4) 무변경.

## 3. 기준소스 (필수)

이 repo main(f43c4a7)의 `hooks/reinject-mode.sh` · `playbooks/implementation-lazymode.md` · `hooks/tests/`(run.sh + cases/misc-guards.sh) · core.md v4.3(§1 lazy·§5 판정 워커·§8) · 사용자 원문(§0).

## 4. 금지영역 (필수)

- core.md·CLAUDE.md·다른 playbooks·templates·agents·다른 훅 수정 금지.
- reinject 출력의 줄 수 증가(여러 줄) 금지 — 매 턴 컨텍스트 비용(core §0.2).
- 훅으로 메시지 내용을 검사·차단하는 장치 추가 금지(어시스턴트 메시지 의미 판정은 결정론적이지 않음 — core §0.5 "강제는 훅, 판단은 문서").
- `~/.claude` 직접 편집 금지 — 배포는 deploy.sh만(core §6).

## 5. 검증 방법 (필수)

- 테스트 먼저: `hooks/tests/cases/misc-guards.sh`에 lazy 재주입 줄에 자기완결 문구가 있는지·auto 줄에는 없는지 케이스 추가 → 현 코드에서 red 확인 → 수정 → `bash hooks/tests/run.sh` 전체 green.
- playbook: R3 단일 출처 확인(같은 규칙 서술이 두 곳 이상 남지 않음 — grep) · 80줄 이하(core §8).
- 리뷰: stakes 높음(하네스 정책 변경) → 듀얼 리뷰(Opus 워커 ∥ codex, `playbooks/review.md`) 루프.
- 배포: deploy.sh(manifest diff → 백업+원자 교체) → 신규 세션 smoke(lazy 상태에서 reinject 줄 확인).

## 6. stakes (필수)

- 판정: **높음** — 근거: core §2 "하네스/정책 변경은 높음 stakes"(모든 세션·프로젝트의 lazy 게이트 동작이 바뀜). 변경 자체는 작고 복구(백업 복원) 쉬움.

---

## 7. 자율성

- [x] auto (사용자 선택)
- [ ] lazy

## 8. load-bearing 가정

- **A1** UserPromptSubmit 훅의 stdout은 요약(compaction) 뒤에도 매 턴 모델 컨텍스트에 들어간다 → 이 세션에서 관측됨(매 턴 `[게이트] MODE=lazy …` 줄). 재주입 문구가 실제로 보이는지는 배포 후 신규 세션 smoke에서 확인.

## 9. task 분해

| task | 목표 | 의존 | acceptance |
|------|------|------|-----------|
| 01 | 테스트 케이스 추가(red) | — | 신규 케이스가 현 코드에서 실패 |
| 02 | reinject lazy 줄 수정 | 01 | 전체 suite green, R1·R2 |
| 03 | playbook §1·§3.1·§4 개정 | — | R3·R4, ≤80줄 |
| 04 | 듀얼 리뷰 → 수정 | 02·03 | ledger 기록 |
| 05 | 배포 + smoke + 사이클 마감(NEXT·아카이브 판정) | 04 | smoke 통과, push는 사용자 확인 |

---

## 승인 상태

- [x] 필수 6칸 전부 기입
- [ ] 사용자 합의 → SPEC=1
- [ ] 자율성 선택 → MODE 기록 (auto 선택됨 — 합의 후 기록)
