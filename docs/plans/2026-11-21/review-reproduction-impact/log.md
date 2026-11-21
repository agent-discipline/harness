# log — review-reproduction-impact (리뷰 지적에 재현 · 영향 등급 요구, 메인은 실행 재현으로 채택)

> 명세: `requirement-spec.md`(합의 2026-11-21 · SPEC=1 · auto) · 브랜치 `feat/review-reproduction-impact`(origin/main 2f07fb0 · worktree `harness-wt-review` — 원 작업 트리에 다른 세션의 implementation-by-workers 작업 폴더가 있어 분리)

| 시각(KST) | 사건 | 결과 |
|-----------|------|------|
| 11-21 22:1x | 사용자(seat-reservation-lab 세션): "저 리뷰받을 때 정말 재현이 되는지 그리고 사용자 시나리오나 공격에 의해 해당 문제가 정말 이슈가 되는지 니가 다 판단하면서 재들이 리뷰를 하는거야?" → 메인 답: 아니다 — 리뷰어는 정적 읽기만 · 재현과 실제 영향은 메인 종합 몫인데 메인도 코드 읽기로 판정 → "하네스쪽 리뷰쪽도 수정해야되면 원본쪽부터 수정하고 우리하네스에 적용" · 순서 결정(seat-reservation-lab NEXT N00e ②) · 다른 세션 작업과 겹쳐 '별도 브랜치에서 지금 시작' | 작업 폴더 생성. 발단 기록: `lab/backend-labs-commerce/seat-reservation-lab/docs/plans/2026-11-21/adr-018-default-switch/log.md`(리뷰 3루프 · 정지 규칙 · 재현 확인 · 재합의 6) |
| 11-21 22:2x | 기존 규칙 확인: review-triage (2) '실행 우선 · 못 했으면 코드로만 확인'은 이미 있음(권고 — ledger 칸 없음) · (3) '전부터 있던 안내가 이번 변경으로 틀린 말' = 만들었다 · 빈 곳 = 리뷰어 출력의 재현 · 등급 · 채택 조건 강제 · 등급의 쓰임 · 명세의 가로지르는 계약 → 인터뷰 AskUserQuestion 2회(8문항) · 사용자 '하네스 워크트리 분기해서 · 다른 작업중' → 이미 worktree에서 진행 중임을 답 · 명세 합의 '합의, auto로 진행' · set-state spec-approved · mode auto | SPEC=1 · MODE=auto |
| 11-21 22:3x | task 01 대어 보기(메인 — seat-reservation-lab adr-018-default-switch ledger 전부를 새 규칙 초안으로) → 아래 표 · 가정 1: 코드 동작 지적 6건 모두 테스트 하나로 재현 방법이 정해짐(재현 5 · 잠재 1 · 막힘 0) → 성립 | 표 작성 |
| 11-21 22:4x | task 02 수정 1차: review.md · review-triage.md에 재현 · 등급 · 보고 규칙 · 템플릿 2개 → review-triage.md 82줄(core §8 ≤80 초과) → 사용자 '문서를 분리하는게 나으려나?' → 재합의 9 '분리 + 판정 한 줄은 제자리' → 새 playbooks/review-reproduction.md(43줄) · triage 76줄 · review.md 116줄(변동 없음) · core §8 표 1줄 · README 목록 · hooks 376/0 → 커밋 63b84d4 | 커밋 |
| 11-21 22:5x | 리뷰 루프 1 packet(OUT=/tmp/claude-1000/-home-jun-project-lab-backend-labs-commerce/0961cd42-5c49-4146-8c52-81561cdbcc92/scratchpad/hr-rv1 · base 2f07fb0 · docs/plans 제외) · 스캔: 가짜 토큰(hooks 테스트 픽스처 — 오탐) · 개인 메일 1파일(docs/analysis — 미러에서 뺌) · GitHub 아이디(미러에서 <user>로 가림) → codex high ∥ Opus 리뷰 ∥ 읽기 시험(Opus — 새 문서 3개만 · 예시 4) 착수 | 리뷰 1 |
| 11-21 23:0x | 읽기 시험 회수(Opus): 예시 4개 처리 · 막힘/두 갈래 12 — T1 '수정 전 코드 = task base SHA'는 틀림(이번 변경이 만든 결함은 base에 없다 — ADR-018도 리뷰받은 커밋 4a7a9cf24에서 돌림 → '리뷰한 코드, 리뷰 지적 수정 전') · T2 잠재가 (2)의 '실측 반증 → 기각'으로 갈 수 있음 · T3 설계 문서는 재현 해당 없음인데 자격 ⑤가 예외 없음 · T4 이번 변경이 기존 테스트를 무력화한 경우 · T7 리뷰어 '재현 불가'의 ledger 처리 · T10 '두 번째'를 세는 범위 · T11 리뷰어 심각도 미정의(후보) · T5 · T6 · T8 · T9 · T12(기존 규칙으로 처리되거나 시험 입력 부족 — 기각/정리) | 반영 대기(리뷰와 함께) |
| 11-21 23:1x | 리뷰 루프 1 회수: codex high F6(높음 2) ∥ Opus(128,719 토큰) F11(높음 2) + OQ 3 · 읽기 시험 12 → 겹침 합쳐 채택 11 묶음(아래 ledger) · 후보 3 · 수정 커밋(아래) · hooks 376/0 · 줄 수 review 116 · triage 76 · reproduction 48 | 수정 |
| 11-21 23:2x | 수정 커밋 284fa62 · 리뷰 루프 2 packet(OUT=/tmp/claude-1000/-home-jun-project-lab-backend-labs-commerce/0961cd42-5c49-4146-8c52-81561cdbcc92/scratchpad/hr-rv2 · 리뷰한 SHA 284fa62) → codex high F4(높음 2) + OQ 1 ∥ Opus(137,373 토큰) F8 + OQ 4 ∥ 읽기 시험 2(Opus 73,649 — 예시 5 · 커밋 선택 S2로 맞게 판정 · 충돌 4 · 막힘 8) → 채택 묶음 9(H12~H20) · 판단 2: '재현 수단 없음'은 명세에 없는 네 번째 예외라 삭제(open question으로) · 출력 계약 정본은 Q/A 9대로 review.md · 명세 R2를 Q/A 2에 맞춤 · R5'(task 01 규칙 문장) 기록 → 커밋 9cd2171 · hooks 376/0 | 수정 |
| 11-21 23:4x | 리뷰 루프 3(상한 · OUT=/tmp/claude-1000/-home-jun-project-lab-backend-labs-commerce/0961cd42-5c49-4146-8c52-81561cdbcc92/scratchpad/hr-rv3 · 리뷰한 SHA 9cd2171): codex high F4(높음 3) ∥ Opus(121,556 토큰) F9 + OQ 2 → 신규 채택 약 10 · 종료 조건 불충족(review unresolved) · repro 값 표기 불일치가 같은 유형 세 번째(H3 → H17 → 이번) → §6대로 구조(review.md §2 재현 값 표 하나) · 사용자 결정 '구조 표 + 나머지 고치고 재점검 1회로 마감'(user override) · 메인 판단: 정책 문서 지적 = 예외 ①(읽기 시험이면 실행) · 정책 문서의 틀린 지시 = 계약 등급 → 커밋 a749edf(review.md 131줄 — 표 15줄) · hooks 376/0 → post-fix 재점검(codex) ∥ 읽기 시험 3 | 마감 중 |
| 11-21 23:5x | 마감 점검: 읽기 시험 3(Opus 74,007 — 中 상황 예시 5 · J · L · M · N 규칙대로 판정 · 새 규칙 쪽 충돌 3: open question의 impact 미정 강제 · 리뷰어 재현 불가 → 미정 순서 · stub 대체) ∥ codex post-fix 3(채택 repro를 미실행으로 통과 가능 · 예외 ②③ 리뷰어 칸 · 기각 지적 테스트를 작업 트리로) → 6건 반영 · 커밋 ba2f428 · hooks 376/0 · 추가 리뷰 없음(사용자 결정 '재점검 1회로 마감') · 읽기 시험의 K(문서 지적이 (4) 출구에 안 맞음)와 문서 지적의 (2) 적용은 원래 있던 triage 빈곳 → 후보 | 리뷰 마감(user override) |

### task 01 — 대어 보기 (새 규칙 초안 · 그때 처리)

| 지적 | 재현 방법 | 등급 | 실제 재현(수정 전 코드) | 새 규칙 갈래 | 그때 처리 | 다르면 무엇이 틀렸나 |
|---|---|---|---|---|---|---|
| R1-1 키 없는 설정 → API 404 | 키를 뺀 yml로 기동 → POST hold-groups | 계약 | 실행 — 404(FixTest ①) | (3) 만들었다 → (4) §1 어긋남 → 채택 | 채택 | 같음 |
| R1-2 migrate 앞 checkTable 분기 미실행 | — | 검증 | 코드로만 확인 — 테스트 공백 | (4) 명세 D3 확인 안 함 → 채택 | 채택(부분) | 같음 |
| R1-3 · O2-F1 낡은 주석 · yml 되돌림 주석 | — | 문서 | 코드로만 확인 — 문서 · 주석 | (3) 안내가 틀린 말 → 채택 | 채택 | 같음 |
| R1-4 · O3-F2 README 상태 · 옛 하네스 목록 | — | 문서 | 코드로만 확인 — 문서 | (3) → 채택 | 채택 | 같음 |
| R1-5 current + 기본 refund 첫 거부 안내 없음 | 키 없음 + current + PG로 기동 → 메시지 | 계약 | 실행 — 실패(FixTest ③) | (3) → (4) §1 · D2 → 채택 | 후보 → 감사가 잡아 채택 | **그때 처리**: 기존 테스트 깨짐을 걱정해 등급(안내 문구)으로 미룸 — R4가 막는다 |
| C2-F1 target 14 첫 거부 안내 없음 | target 14로 기동 | 계약 | 실행 — 실패(FixTest ④) | 채택 + 같은 유형 두 번째 → 구조를 묻는다 | 채택 · 정지 규칙(네 번째에) | 같음(새 규칙은 두 번째에 묻게 해 한 루프 빠름 — 그때는 루프 2에서 물음, 시점은 같음) |
| O2-F2 Flyway 끔 @PostConstruct 순서 | Flyway 끔 + 마이그레이션된 DB + current로 기동 | 계약 | 재현 안 됨 — 잠재(GapTest ⑥ 통과 — 지금 빈 순서) | 잠재 → (3) 요구가 이번에 생김 → (4) D7 어긋남 → 채택 · 수정 검증은 순서에 기대지 않고 계약을 직접 확인 | 수용(이월) → 사용자 '계약 문제' → 채택 · @DependsOn 넣었다 뺌 | **그때 처리**: '수용'은 등급(안내)으로 정함 — R4 · R3. 수정 검증 테스트가 재현 조건(순서)에 기대 @DependsOn을 검증하지 못함(post-fix 지적) — 규칙 문장에 반영 |
| O2-F3 → O3-F1 Adr017 ③ 그린 위장 | — | 검증 | 코드로만 확인 — 테스트 공백 | (4) 기존 계약 테스트가 목표를 확인 안 함 → 채택(루프 2에서) | 루프 2 '기록만' → 루프 3 채택 | **그때 처리**: triage (2) '테스트 지적'은 이미 (4)로 고친다 — 지키지 않음. 등급 칸 '검증'이 눈에 띄게 함 |
| ADR-015 current 안내(루프 1 OQ3 '다단 거부') | 기본 확정 + lazy로 기동 → 메시지 | 계약 | 실행 — 실패(GapTest ⑦) | (3) 전부터 있던 안내가 이번 변경으로 틀린 말 → 채택 | OQ '의도'로 닫음 → 사용자 '계약 문제' → 채택 | **그때 처리**: triage (3)에 이미 있음 — OQ를 '의도'로 닫을 때 (3)을 보지 않음 |
| enabled=on 조건 불일치 | enabled=on으로 기동 → POST | 계약 | 실행 — 404(GapTest ⑧) | (3) 원래 있던 것 → 후보(A) · 보고는 '원래 있던 계약 결함 — 이 PR에서 고칠지' | 후보(B) · '크리티컬하지 않다'로 보고 → 사용자 '계약 문제' → 채택 | **보고**: 갈래는 맞았으나 등급으로 '남겨도 된다'고 말함 — R4가 막는다(갈래 근거로 말하고 고를 수 있게) |
| C2-F2 · C3-F1 NEXT 기록 없음 | — | 문서 | 해당 없음 — packet 정책(NEXT 제외) | (1) 전에 판정 → 기각 | 기각 | 같음 |
| 메인 보고 '크리티컬하지 않으니 병합 가능' | — | (보고) | — | R4 금지 | 사용자가 정정 | **보고 규칙 없음** — R4 신설 이유 |

- 명세 템플릿 새 줄(가로지르는 계약)이 있었다면: '기본값 true → 함께 맞아야 하는 경로 = 다른 기동 검사의 current 안내 · 보상 검사 · yml 주석 · 컨트롤러 등록 조건 · test 프로필'을 인터뷰에서 물었을 것 — ADR-015 안내 · yml 주석 · 컨트롤러 조건이 리뷰 전에 범위에 들었을 가능성이 크다(추정 — 반사실이라 확인 불가).
- 규칙 문장 수정 목록(→ task 02): ① 잠재 결함이 (4)에 어긋나면 고치되 수정 검증 테스트는 재현 조건(순서 · 시각)이 아니라 계약을 직접 확인 ② open question을 '의도'로 닫을 때도 (3) '안내가 틀린 말'을 본다 ③ 보고: 남기는 결함은 갈래 근거로 말하고 등급으로 '괜찮다'고 하지 않는다 ④ 같은 유형 · 같은 등급의 결함이 두 번째로 채택되면 구조를 묻는다(core §3 정지 규칙의 리뷰판).

## 리뷰 ledger

| id | loop | source | 근거 | repro | impact | disposition | status |
|----|------|--------|------|-------|--------|-------------|--------|
| H1 | 1 | codex F1 · opus F1 · 읽기 T1 | review-reproduction.md:13 · review.md:14 | 실행 — 읽기 시험(예시 A · B가 base에서 재현 불가로 막힘) · ADR-018 실측(리뷰한 커밋 4a7a9cf24에서 재현) | 검증 | 채택 — 수정 전 코드 = 리뷰한 커밋 | fixed(1) |
| H2 | 1 | codex F2 · opus F2 · F3 · 읽기 T2 | review-reproduction.md:13 · 16 · review-triage.md:19 · 31 | 실행 — 읽기 시험(예시 B 두 갈래) | 계약 | 채택 — 채택 조건 셋 · 그림 (2) 주석 | fixed(1) |
| H3 | 1 | codex F5 · opus F6 · 읽기 T7 | review.md:75 | 코드로만 확인 — 문서(값 목록에 없음) | 계약 | 채택 — 미실행 · 재현 수단 없음 값 | fixed(1) |
| H4 | 1 | codex F6 · opus F7 · 읽기 T3 | review-reproduction.md:8 · review.md:74 | 실행 — 읽기 시험(예시 D 자격 미달) | 가용성 | 채택 — 문서 지적 '해당 없음' · 메인 보충 표시 | fixed(1) |
| H5 | 1 | codex F3 · opus F4 | review-reproduction.md:42 · review-triage.md:69 · core.md:69 | 코드로만 확인 — 문서(세 문장 대조) | 계약 | 채택 — §6 정본 · core §3 관계 · triage §4 가리킴 | fixed(1) |
| H6 | 1 | codex F4 · opus F10 | review-reproduction.md:37 | 코드로만 확인 — 문서 | 계약 | 채택 — 후보마다 묻지 않음 · triage §2 | fixed(1) |
| H7 | 1 | opus F5 | review-reproduction.md:33 · review-triage.md:59 | 코드로만 확인 — 문서 | 계약 | 채택 — B = 표현 · 기록만 · 쓰임에 반복 유형 | fixed(1) |
| H8 | 1 | opus F8 | review.md:61 · review-reproduction.md:3 · core.md:124 | 코드로만 확인 — 문서 | 검증 | 채택 — 프롬프트에 6등급 이름 · 트리거 ① | fixed(1) |
| H9 | 1 | opus F9 | review-triage.md:43 | 코드로만 확인 — 문서(spec §2 가로지르는 계약 목록) | 계약 | 채택 — §2 표 repro 조건 | fixed(1) |
| H10 | 1 | opus F11 | review-reproduction.md:14 · core.md:98 | 코드로만 확인 — 문서 | 검증 | 채택 — 브리핑에 기대 실패 · 판정 주지 않음 | fixed(1) |
| H11 | 1 | 읽기 T4 | review-triage.md:32 | 실행 — 읽기 시험(예시 C 막힘) | 검증 | 채택 — 기존 테스트 무력화도 (4) | fixed(1) |
| H12 | 2 | codex F1 · opus F3 · 읽기2 | review-reproduction.md:15 · review.md:14 · log.md:25 | 코드로만 확인 — 문서(packet = 작업트리 포함) | 검증 | 채택 — packet 전 커밋 · 리뷰한 SHA 칸 | fixed(2) |
| H13 | 2 | codex F2 | review.md:63 | 코드로만 확인 — 문서 | 검증 | 채택 — 허용 근거에 실행 결과 | fixed(2) |
| H14 | 2 | codex F3 · opus F4 · 읽기2 | review-reproduction.md:9 · review.md:74 | 실행 — 읽기 시험 2(예시 H 등급 보충) | 계약 | 채택 — open question을 메인이 확인해 다시 가름 · 없으면 재질의/기각 | fixed(2) |
| H15 | 2 | codex F4 · opus F7 | review-reproduction.md:46 · review-triage.md:69 | 코드로만 확인 — 문서 | 계약 | 채택 — 목표 밖은 후보 + 보고에 원인 · triage §4는 처음 것만 | fixed(2) |
| H16 | 2 | codex OQ1 | spec R2 ↔ Q/A 2 | 코드로만 확인 — 명세 | 계약 | 채택 — 명세 R2를 Q/A 2에 맞춤(사용자 답이 기준) | fixed(2) |
| H17 | 2 | opus F1 · F5 · F8 · 읽기2 | review.md:61 · 63 · 75 · core.md:124 · README:142 | 실행 — 읽기 시험 2(문서 지적 repro 값 세 갈래) | 계약 | 채택 — 출력 계약 · repro 값 정본 review.md · 표현 통일 | fixed(2) |
| H18 | 2 | opus F2 | review-reproduction.md:19 | 코드로만 확인 — 문서(명세 R2에 없는 예외) | 검증 | 채택 — '재현 수단 없음' 삭제 → open question | fixed(2) |
| H19 | 2 | opus F6 | review-triage.md:31 · 33 | 코드로만 확인 — 명세 | 계약 | 채택 — 명세 R5'로 범위 기록(task 01 산출) | fixed(2) |
| H20 | 2 | 읽기2 · opus OQ1 · OQ2 | review-reproduction.md:46 · 15 | 실행 — 읽기 시험 2 | 계약 | 채택 — '같은 유형' 정의 · 재현 테스트를 수정 검증으로 · 만든 worktree만 정리 | fixed(2) |
| H-OQ | 1 | opus OQ1~3 · 읽기 T5 · T6 · T8 · T9 · T10 · T12 | — | 미실행 — 정리 | — | OQ1 정책 문서 = 읽기 시험이면 실행(반영) · OQ2 이미 답했으면 묻지 않음(반영) · OQ3 worktree 위치(H1에 반영) · T10 '같은 작업 안'(H5에 반영) · T5 · T6 · T8 · T9 · T12 기존 규칙으로 처리 · 시험 입력 부족 | 정리 |

### 후보

| id | 지적 | 멈춘 질문과 근거 | 우선순위 | NEXT |
|----|------|------------------|----------|------|
| C1 | 리뷰어 심각도(높음 · 중간 · 낮음)가 어디에도 정의돼 있지 않음(읽기 T11) | (3) 원래 있던 것 | B | 예 |
| C2 | templates/requirement-spec.md:84-85 깨진 표 조각(opus 후보) | (3) 원래 있던 것 | B | 예 |
| C3 | core.md 변경 이력에 이번 변경 줄 없음(opus 후보) | (4) 명세에 없던 요구 | B | 마감 때 판단 |
| C4 | review.md 종료식이 open question을 세지 않음 ↔ triage '남아 있으면 끝나지 않음'(opus2 OQ3) | (3) 원래 있던 것 | A | 예 |
| C5 | S/A 고르는 기준 · (1) '근거가 지금도 맞다' 확인 방법(읽기2) | (3) 원래 있던 것 | B | 예 |
| C6 | 문서 지적이 (4)의 두 출구(어긋남 · 명세에 없던 요구)에 안 맞음 · 문서 지적에 (2) '일어나는가'를 어떻게 적용하나(읽기3 K) | (3) 원래 있던 것 | A | 예 |
| C7 | 정책 문서 리뷰가 3루프 모두 신규 채택 — 종료식을 못 채움(NEXT N3와 같은 관측 · 이번에도) | (3) 원래 있던 것 | A | N3에 더함 |

## 생략한 검증

## 완료 요약 (2026-11-21)

- 범위: 리뷰 지적에 재현 · 영향 등급(6) 요구 · 코드 동작 지적은 리뷰한 커밋에서 실행 재현(또는 예외 셋 · 잠재 뒤 (3)(4)) 뒤 채택 · ledger repro · impact 열 · 재현 값 표(review.md §2 — 리뷰어 출력 ↔ ledger) · 보고 규칙(등급으로 '남겨도 된다' 금지) · 같은 유형 반복 규칙 · 명세 템플릿 ② 가로지르는 계약.
- 파일: 새 `playbooks/review-reproduction.md`(48줄) · `review.md`(116 → 131 — 표 15줄) · `review-triage.md`(75 → 77) · `templates/requirement-spec.md` · `templates/log.md` · `src/core.md` §8 한 줄 · README 목록.
- 커밋: 63b84d4 · 284fa62 · 9cd2171 · a749edf · ba2f428(정책) + docs.
- 검증: 대어 보기(ADR-018 지적 12 — 다른 처리 6은 모두 그때 처리 잘못 · 규칙 문장 4 고침 · 가정 1 성립) · 읽기 시험 3회(막힘 12 → 8 → 새 규칙 쪽 3) · 듀얼 리뷰 3루프(채택 11 묶음 → 9 → 약 10) + post-fix(3) · hooks 376/0 · 같은 유형 세 번째(repro 값 표기)에서 §6을 이 작업에 적용해 구조(표)로 고침.
- 리뷰 상태: 3루프 상한에서 신규 채택이 남아 review unresolved → 사용자 결정 '구조 표 + 나머지 고치고 재점검 1회로 마감'(user override) · 재점검 지적 3 반영 뒤 추가 리뷰 없음.
- 남은 것(후보): C1 리뷰어 심각도 정의 · C2 템플릿 깨진 표 · C3 core 변경 이력 줄 · C4 종료식과 open question · C5 S/A 기준 · C6 문서 지적의 (2)(4) · C7 정책 문서 리뷰 종료(N3).
- CS 이슈 아카이브: 해당 없음(하네스 정책 작업).

