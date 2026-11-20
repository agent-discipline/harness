# log — cleanup-unused

## 타임라인

| 시각 | 사건 | 결과/결정 |
|------|------|----------|
| 11-20 13:00 | 사용자 요청 — 쓰지 않는 것과 `archive/` 삭제 | 하네스 전체 지도를 그린 뒤 나온 정리 항목에서 출발 |
| 11-20 13:05 | 메인 조사(실파일) | `archive/` 참조는 루트 `HISTORY.md` 두 줄뿐 · `settings.json` 사본에 없는 훅 둘 등록 · `capture-prompt.sh`는 테스트 4개 파일이 실행 · `docs/` 최상위 옛 문서 6개는 archive v2 사본과 동일(`runbooks/hook-failure.md`만 다름) |
| 11-20 13:10 | 인터뷰(질문 도구 3건) | 옛 docs는 남김 · `docs/plans`는 그대로 · `capture-prompt.sh`는 이번에 함께 지움 |
| 11-20 13:15 | 브랜치 `chore/cleanup-unused`(기준 `c123f35`), 명세 작성 | 합의 대기 |
| 11-20 13:13~13:20 | 사용자 합의("합의, auto로 진행") → `set-state spec-approved`·`mode auto` | 명세 Write 때 상태 초기화 확인(SPEC=0·MODE=UNSET → 다시 기록) |
| 11-20 13:21 | **압축 뒤 미독 차단 — 실제 세션 첫 관측**(v4.5 보류 항목) | 이 세션은 11-19에 압축을 겪음. 새 작업 폴더의 명세서·log를 Write만 하고 Read 하지 않은 채 `README.md`(L1) Edit을 시도 → gate-guard가 `[gate-guard] 압축 뒤 작업 기록 미독 — 다음 파일을 Read 한 뒤 다시 시도:`와 세 파일 경로로 차단. 세 파일을 Read(명세서·log는 `limit 5` 부분 읽기) 한 뒤 같은 Edit이 통과. README 한계 ⑩(Write는 읽은 것으로 세지 않음)과 ①(부분 읽기 인정) 그대로 동작 |
| 11-20 13:21 | 부수 관측 | 명세 작성 전에 한 범위 질문 3건의 답은 직전 작업 폴더(`2026-11-19/decision-archive-compact-reread/decisions.md`)에 기록됨. `TASK_PATH`가 새 명세 Write 전까지 직전 작업을 가리키기 때문. 이 작업의 `decisions.md`에는 합의 질문 1건만 있음 |
| 11-20 13:22 | 가정 1 확인 | `~/.claude/hooks`·`skills`·`agents`·`playbooks`·`core.md`에 `.prompt`·`.turn`을 읽는 코드 없음(주석 1곳뿐) — 성립 |
| 11-20 13:25~13:33 | task 01(메인) — `git rm -r archive`, `settings.json` 사본의 `scope-guard`·`template-guard` 등록 삭제, README 테스트 수 삭제, `HISTORY.md` 머리 한 줄 | 테스트 368 통과(변화 없음). 커밋 `221f076` |
| 11-20 13:35 | task 02 — 구현 워커(Opus) 착수, 기준 `221f076` | `capture-prompt.sh` 제거와 테스트 대응표 |
| 11-20 13:35~13:50 | task 02 — 구현 워커(Opus, 132k 토큰), 기준 `221f076` | 커밋 `4fb66bb`. 훅 파일·사본 등록·core.md 108행의 이름·README 162행 삭제. lock 재생성(사유: 테스트 삭제·이동) → **363 통과**(368에서 5개 삭제). 첫 실행은 무결성 위반으로 실패 — 원인은 실행 중 메인이 `docs/plans/NEXT.md`를 고친 것(테스트가 만든 변경 아님), 재실행 통과 |
| 11-20 13:50 | 테스트 대응표(I2) | 삭제 5: cp_01~03(훅 고유 동작 — 대응 없음) · cr_12 → cr_13(detect-layer, 조상 기록·하위 미생성) · sd_18 → sd_23(detect-layer, state-lib 없을 때 무생성). 이동 5(detect-layer로): sd_05(루트 폴백·`.gitignore`·index) · sd_07 일부(rc 2 무생성) · sd_17 일부(심링크 무기록) · sd_28(rc 2 경고) · sd_31(rc 3 경고 후 진행). 유지 1: dr_pv_01(준비 단계를 `write_sidecar`로 교체). 워커가 훅 복사본을 6가지로 고장 내 옮긴 테스트가 매번 실패함을 확인. `lib.sh`의 `SIDECAR`는 쓰는 곳 2곳이 남아 유지 |
| 11-20 13:52~13:58 | task 03 — 듀얼 1패스. Opus 워커(116k) ∥ codex. base `c123f35`(archive 삭제분은 본문 제외), `$OUT` `/tmp/claude-1000/cu-rv-Y9k3`, 미러 `/tmp/claude-1000/cu-mr-ZOGZ` | 두 리뷰가 같은 2건 지적(ledger R1·R2), 기각 0. open question 2건(Q1 배포 순서, Q2 사본의 detect-layer 등록 누락) |
| 11-20 14:00~14:10 | 수정(메인) → lock 재생성(사유: sd_23 확인 추가) → 전체 실행 | **363 통과**, 커밋 `10d5132` |
| 11-20 14:12 | codex 종합 감사 + post-fix 재점검(수정 반영 미러 `/tmp/claude-1000/cu-mr2-9rgt`) | R1·R2 해소 확인, 주변 새 결함 없음, Q2 범위 밖 판정 타당. 지적 1건(A1): Q1 반영으로 순서를 바꾸려면 명세 §5도 고쳐야 함 → 명세 §5와 task 04 행 수정 |
| 11-20 14:15 | task 04 — `~/.claude/settings.json` 백업(`settings.json.bak-2026-11-20-cleanup`) 뒤 `capture-prompt.sh` 등록 1항목 삭제 | 백업과의 차이는 그 항목뿐(JSON 비교로 확인) |
| 11-20 14:16~14:24 | `deploy.sh` → smoke 통과 | 백업 `~/.claude/.deploy-backup-2673382`. `~/.claude/hooks/capture-prompt.sh` 없음, `core.md` 동기 확인 |

## 리뷰 ledger (中↑ — 듀얼 리뷰가 돈 작업 필수)

- review packet: base `c123f35` · `$OUT` `/tmp/claude-1000/cu-rv-Y9k3` · 미러 `/tmp/claude-1000/cu-mr-ZOGZ`(1패스) · `/tmp/claude-1000/cu-mr2-9rgt`(감사·재점검)

| id | first_seen_loop | source | 근거(file:line) | disposition | status | fixed_in_loop |
|----|-----------------|--------|-----------------|-------------|--------|---------------|
| R1 | 1 | codex · opus F2 | hooks/tests/cases/sidecar-docsroot.sh:292-302 — 삭제한 sd_18의 대체 sd_23이 `*.events`만 확인(lock·상태파일 미확인, I2) | 채택 | fixed | 1 |
| R2 | 1 | codex · opus F1 | README.md:195 — v3→v4 마이그레이션 안내에 `scope-guard`·`template-guard` 잔존(§5 grep) | 채택 | fixed | 1 |
| A1 | 감사 | codex | spec §5 — 배포 순서를 바꾸면서 명세 미갱신 | 채택 | fixed | 1 |
| Q1 | 1 | opus | 배포와 실제 설정 수정 사이에 없는 훅을 부르는 구간 | open question → 순서 변경으로 반영 | fixed | 1 |
| Q2 | 1 | opus | settings.json 사본에 `detect-layer` 등록 없음(이번 diff 이전부터) | 범위 밖(감사 동의) — NEXT | — | — |

- 종료 조건(中): 채택 전부 fixed · post-fix 재점검 신규 0 · 안전선(스모크=배포 smoke, 테스트 363, diff 확인, 되돌리기=git revert와 설정 백업, 공개 계약 영향 없음).

## 생략한 검증 (긴급 경로 빚 — DEBT=1인 동안 정본)

- 없음.

## 완료 요약 (마감 시)

- **지운 것**: `archive/`(138개 파일, 20,976줄) · `hooks/capture-prompt.sh`(80줄)와 그 등록(사본·실제 설정) · 사본 `settings.json`의 없는 훅 등록 둘 · README의 옛 마이그레이션 안내와 낡은 테스트 수. `archive/` 밖의 변경은 10개 파일 +45 −183.
- **core.md 108행**(실파일 diff에서 복사):
  - before: `` `reinject-mode`·`capture-prompt` · `task-mode-guard`(spec|log 리셋) ``
  - after: `` `reinject-mode` · `task-mode-guard`(spec|log 리셋) ``
- **테스트**: 368 → 363. 지운 5개와 옮긴 5개의 대응은 타임라인 13:50 행.
- **검증**: 테스트 363 통과, 듀얼 1패스(채택 3·기각 0), 배포 smoke 통과, 실제 설정은 등록 1항목만 차이.
- **실제 세션 확인**: 배포 뒤 다음 턴의 재주입 줄 — 아래 타임라인 마지막 행에 기록.
- **아카이브**: CS 이슈 0건(삭제 작업).

