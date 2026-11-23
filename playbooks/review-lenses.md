# playbook: 리뷰 판단 렌즈와 자원·속도 점검

> 트리거: 리뷰어 프롬프트를 쓸 때(`review.md` §1 ①) · 신규 채택 0인 루프에서 렌즈마다 판정할 때(`review.md` §2 대칭 부담) · 개발 단계의 설계 자문(설계할 때도 이 렌즈를 먼저 대 본다) · 과잉 구현 렌즈의 세부는 `build-less.md`.
> 리뷰 절차·finding 자격 조건·ledger의 정본은 `review.md`이고, 이 문서는 무엇을 찾나만 적는다. 2026-11-23에 `review.md` §3·§4에서 옮기고 동시성 렌즈를 더했다(사용자 판단 — 리뷰 포인트를 따로 된 문서로 모아 정리한다, `docs/plans/2026-11-22/service-communication-http-default/` task 10).
> 사례 칸은 하네스 기록에서 그 렌즈가 잡았거나 잡았어야 할 지적 하나다(경로는 harness 저장소 기준, 직접 열어 확인한 줄만). 하네스 기록에 맞는 사례가 없는 렌즈는 "—"로 둔다(하네스는 DB가 없는 셸·문서 저장소다).

## 1. 판단 렌즈 (리뷰는 diff 기반, 판단은 이 레벨로 — 설계 시에도 선적용)

> diff 정확성(아래 처음 4렌즈)만 보면 **"빠진 능력"을 못 잡는다** — 완전성·운영성 렌즈는 diff 안에 *없는 것*을 본다(codex 가 약한 지점, 독립 리뷰어가 메우는 관점).

| 렌즈 | 무엇을 찾나 (판단 질문) | 하네스 기록의 사례 |
|------|----------|----------|
| **API 단위** | 전체 프로세스에서 발생 가능한 예외와 전파 경로가 처리되나 — 입력 오류·권한·의존 실패·타임아웃·부분 실패. 예외가 계약된 형태로 드러나나(조용한 실패 없음) | `docs/plans/2026-07-19/harness-v3-restructure/tasks/03a-state-schema/review-log.md:32` — flock 실패를 `'E'`와 `return 0`으로 덮고 타임아웃이 없었다(T3a-P0c, 채택 — `-w 2`와 rc 전파로 고침) |
| **메서드 내부** | 알고리즘 설계가 입력 규모·서버 자원·속도에 적절한가(§2 체크리스트) · 정상/예외 흐름이 분리되어 있나 · 예외 처리가 기존 전략과 일관된가 | `docs/plans/2026-11-19/decision-archive-compact-reread/log.md:51` — 고정 지시 파일을 크기 제한 없이 읽었다(H3, 채택 — 64KB 상한) |
| **네이밍** | 메서드/함수명이 도메인을 직관적으로 드러내나 — 이름만 읽고 행동·부작용을 예측할 수 있나 | — |
| **리포지토리/쿼리** | ORM이 생성하는 쿼리·SQL이 사용 DB의 실행계획·옵티마이저를 고려해 처리되나 — N+1·인덱스 사용·페이징·불필요한 전체 적재 (JPA는 대표 예시 — 표현은 ORM 범용) | — |
| **완전성·운영성 (diff에 *없는 것*)** | CRUD·기능에 빠진 경로가 없나 — 생성만 있고 조회/수정/복구가 없나 · **public/필터 경로(useYn='Y' 등)가 관리자를 가두지 않나** — 숨김·비활성·소프트삭제 데이터의 admin 조회·복구 경로가 있나 · 운영자가 배포 후 상태를 관찰·되돌릴 수 있나 · 통합 단절(이 변경이 옮긴 소스를 다른 경로가 옛 소스로 계속 읽나) | `HISTORY.md:27` — MR !29: 숨김 데이터를 admin이 조회하지 못했다 |
| **통합·부작용 (이 변경 밖)** | 이 변경이 공유 자원·라이브 데이터·다른 경로에 미치는 부작용 — 공유 테이블 컬럼 무단 덮어쓰기, 식별자/소스 전환이 미처리 경로(비번재설정·부트스트랩·배치)와 단절되나 | `HISTORY.md:27` — MR !38: 비밀번호 재설정 경로 단절(H1)·공유 컬럼 USER_GB 덮어쓰기(M1) |
| **설계 품질·취향** | 응집·경계·이름·냄새가 좋은 설계인가 — DDD 용어 일관성·도메인 경계(기술 트랜잭션 ≠ Aggregate) · 이름붙은 코드냄새 · 슬롭↔오버킬 사이에서 판단을 commit했나. 냄새 목록·8앵커·슬롭↔오버킬 예시 카탈로그: `design-taste.md`. **순수 취향·선호는 finding 아님**(`review.md` §2) — 단정 가능한 냄새·불변식·경계 위반만 | `docs/plans/2026-06-27/design-taste-lens/review-log.md:22` — Fowler 냄새 목록과 슬롭/오버킬이 세 문서에 겹쳤다(F1, 단일 출처 위반 — 채택) |
| **과잉 구현 (core §4 덜 만드는 순서 — 세부 `build-less.md`)** | diff가 더 짧아질 수 있나 — `delete:` 죽은 코드·추측성 기능(쓰는 곳이 없다는 근거는 저장소 전체 검색의 명령과 결과 — `build-less.md` §3) · `reuse:` 이 코드베이스에 이미 있는 것을 다시 만듦(있는 곳 file:line. `review.md` §2 자격 ①이 앞선다 — 이번 diff가 새로 쓴 코드만 대상이고, 기존 코드끼리의 중복은 이 지적이 아니다) · `stdlib:`/`native:` 표준·플랫폼이 이미 제공 · `yagni:` 구현 1개인 추상화·아무도 안 바꾸는 config · `shrink:` 같은 로직 더 짧게(finding마다 대체안 명시). **core §4 "줄이지 않는 것"의 항목은 이 렌즈 대상이 아니다**(목록 정본 = core §4 — 여기서 재열거하지 않는다). `review.md` §2 자격조건 그대로 — 유지보수·정확성 리스크 없는 `shrink:`는 finding이 아니라 open question | `docs/plans/2026-11-21/implementation-by-workers/log.md:27` — 테스트 wn_13c의 효과 없던 TMPDIR 부분을 지웠다(`delete:`의 꼴 — 리뷰가 아니라 테스트 워커가 찾음) |
| **동시성·여러 프로세스** | 확인한 뒤 쓰기 전에 다른 프로세스·세션이 끼어들 수 있는 곳 · 프로세스마다 같은 일을 되풀이하는 곳 · 프로세스 안에만 둔 상태를 여럿이 나눠 써야 하는 곳 · 잠금 밖에서 읽거나 지우는 곳을 찾는다. 문서 리뷰는 "해당 없음: 문서" 한 줄로 판정한다 | `docs/measurement-log.md:50` — v4.5 리뷰가 동시 기록 손상과 잠금 밖 삭제 경합을 재현해 채택했다(렌즈 없이 찾음) |

## 2. 자원·속도 체크리스트 (메서드 내부 렌즈 — 프로파일링 없이 diff만으로 판단)

1. 입력 크기 상한이 spec·validation·pagination·limit·batch로 명시·강제되나?
2. 시간복잡도가 입력 크기로 설명 가능한가 — unbounded 입력에 O(n²)+·중첩 스캔·반복 정렬이 새로 생겼나?
3. 루프 안에서 DB 쿼리·리포지토리 호출·네트워크·파일 I/O·외부 API 호출이 발생하나?
4. 대량 데이터를 한 번에 메모리 적재·복사하나 — streaming/cursor/pagination/chunking 없는 전체 조회·전체 read?
5. fan-out·병렬·async·blocking 호출이 입력 크기만큼 무제한 증가하나 — timeout·동시성 상한·backpressure 있나?
6. 루프마다 불변 작업을 반복하나 — regex compile·파서 생성·직렬화·권한 조회·config fetch?
7. 정상·예외 경로 모두에서 자원이 해제되나 — connection·stream·lock·temp file·트랜잭션 범위 누수?
8. 같은 결과를 더 비싼 알고리즘으로 바꿨나 — 기존 pagination/batching/cache/인덱스 친화 접근을 제거·우회했나?

- **finding 증거 형식**: file:line / 도달 경로(어떤 API·입력이 닿나) / 복잡도 추정(N×M, N번 원격 호출 등) / 입력 규모 가정(상한 또는 "상한 없음" 근거) / 현실적 영향(latency·memory·DB 부하·자원 고갈·timeout 중 무엇) / 완화 부재 사유(limit·batch·cache·timeout이 왜 불충분한지) / 수정 방향(클래스 수준 — batch query·streaming·bounded concurrency·상한 강제. 특정 구현 강요 금지).
- **지적한다**: unbounded 입력에 superlinear 작업·per-item I/O·무제한 fan-out을 신설/악화 · 기존 limit/pagination/batching/cache 제거·우회 · 상한 없이 입력 전체에 비례하는 메모리 적재 · production request path에서 입력 크기만큼 자원(thread·connection·트랜잭션 시간) 점유가 file:line으로 보일 때.
- **넘어간다**: 상한이 작고 코드로 강제되며 그 규모에서 복잡도가 합리적 · one-time migration/admin/startup 경로로 빈도·규모 제한이 spec/code에 보임 · 상수배 미세 최적화·취향 수준 · 입력 규모가 diff/spec에서 증명 안 돼 근거를 댈 수 없음(→ open question).
