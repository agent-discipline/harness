# 요구사항 명세서 — 쓰지 않는 것 정리

> 작성일: 2026-11-20 · 작업 폴더: `docs/plans/2026-11-20/cleanup-unused/`

---

## 0. 요구사항 원문 (인터뷰 기록)

- 원문(2026-11-20, 하네스 전체 지도를 본 뒤): "우선 지금 안쓰는거 삭제하고, 아카이브 어차피 커밋기록에 남으면 필요 없으니 지우고, 우선 한번 정리부터 하자."
- Q/A(질문 도구, 2026-11-20):
  - `docs/` 최상위의 옛 문서(HISTORY.md, phase1·2, analysis/ — archive v2 사본과 내용 동일) → "docs는 남긴다"
  - `docs/plans`의 옛 작업 폴더 → "그대로 둔다"
  - 읽는 곳이 없는 훅 `capture-prompt.sh` → "이번에 함께 지운다"
- 조사(메인, 2026-11-20 실파일):
  - `archive/`를 가리키는 현재 파일은 루트 `HISTORY.md` 두 줄(9행, 22행)뿐이다. 훅·테스트·배포 스크립트는 `archive/`를 읽지 않는다.
  - 저장소의 `settings.json` 사본은 `scope-guard.sh`·`template-guard.sh`를 PostToolUse에 등록하고 있으나 두 파일은 `hooks/`에도 `~/.claude/hooks/`에도 없다(v4에서 삭제 — `hooks/tests/cases/misc-guards.sh:2`). 실제 `~/.claude/settings.json`에는 이 등록이 없다.
  - `capture-prompt.sh`를 부르는 곳: `settings.json` 사본 22행, `~/.claude/settings.json` 29행, 테스트 4개 파일(`misc-guards.sh`, `cwd-resolution.sh`, `sidecar-docsroot.sh`, `decision-reread.sh`). `.prompt`·`.turn` 사이드카를 읽는 훅은 없다.
  - README 167행의 테스트 수 "258 tests"는 낡은 값이다(현재 368).

---

## 1. 목표·대상 (필수)

하네스 저장소(`agent-discipline/harness`)에서 쓰지 않는 것을 지운다.

1. `archive/` 폴더 전체 삭제(v1 `2026-06-10-opus-harness`, v2 `2026-06-20-harness-v2`).
2. `settings.json` 사본에서 없는 훅 둘(`scope-guard.sh`, `template-guard.sh`)의 등록 삭제.
3. `capture-prompt.sh` 제거: 훅 파일, `settings.json` 사본의 등록, `~/.claude/settings.json`의 등록, core.md 6절 활성 훅 목록의 이름, README 구조 절의 줄, 이 훅을 대상으로 한 테스트.
4. README의 낡은 숫자(테스트 수)와 `archive/`를 가리키는 서술 정리.

끝의 기준: 테스트 전체 통과, 배포와 smoke 통과, 실제 세션에서 UserPromptSubmit이 오류 없이 돌고 재주입 줄이 종전대로 나온다.

## 2. 경계·불변식 (필수)

- **I1 남는 훅의 동작은 바뀌지 않는다.** `capture-prompt.sh` 말고는 `hooks/*.sh`의 코드를 고치지 않는다. `gate-guard.sh`가 상태 디렉토리의 사이드카(`.prompt`·`.turn` 포함) 쓰기를 거부하는 동작도 그대로 둔다.
- **I2 테스트가 지키던 계약은 빠지지 않는다.** `capture-prompt.sh`를 실행해 `state-lib.sh`의 계약(사이드카 위치 해소, 로드 실패 시 아무것도 만들지 않음, rc 2·3 처리)을 확인하던 테스트는, 같은 계약을 다른 테스트가 이미 확인하면 지우고, 아니면 남는 훅(`detect-layer.sh` 등)으로 옮긴다. 지운 테스트마다 "어느 테스트가 같은 계약을 확인하는가"를 log에 적는다. `capture-prompt.sh` 고유 동작(프롬프트 내용 기록)만 확인하던 테스트는 지운다.
- **I3 매 턴 주입은 그대로다.** UserPromptSubmit에는 `reinject-mode.sh`만 남고, 출력은 종전과 같다.
- **I4 삭제 대상 밖의 파일은 지우지 않는다.** `docs/`(최상위 옛 문서, `docs/plans`의 모든 작업 폴더)는 그대로 둔다.
- **I5 이력 문서의 과거 서술은 고치지 않는다.** 루트 `HISTORY.md`와 `docs/plans`의 기록이 `archive/`나 `capture-prompt`를 말하는 것은 당시 기록이라 그대로 둔다(`HISTORY.md` 머리에 "archive/는 2026-11-20에 삭제, 커밋 기록에서 볼 수 있음" 한 줄만 덧붙인다).

## 3. 기준소스 (필수)

- 하네스 저장소 `main`(`c123f35`)의 현재 파일.
- 실제 훅 등록은 `~/.claude/settings.json`.

## 4. 금지영역 (필수)

- `~/.claude/settings.json`은 `capture-prompt.sh` 등록 한 항목만 지운다. 고치기 전 백업. 다른 항목(다른 프로그램이 넣은 훅 포함)은 건드리지 않는다. (사용자 확인: 질문 도구 "이번에 함께 지운다"의 설명에 이 변경이 들어 있음.)
- 배포는 `hooks/deploy.sh` 경유만.
- `docs/` 아래는 이 작업 폴더 말고는 쓰지 않는다(NEXT.md와 측정 로그의 마감 갱신 제외).
- `.mcp.json`, `playbooks/`, `templates/`, `agents/`는 건드리지 않는다.
- 이미 쌓인 세션 사이드카 파일(`*.prompt`, `*.turn`)은 지우지 않는다(30일 정리에 맡김).
- push·PR·병합은 사용자 확인 뒤. `main`에 직접 커밋하지 않는다(브랜치 `chore/cleanup-unused`).

## 5. 검증 방법 (필수)

- `bash hooks/tests/run.sh` 전체 통과(테스트 파일이 바뀌므로 lock 재생성, 사유 기록).
- 삭제 뒤 `grep`으로 남은 참조 확인: `hooks/`, `src/`, `playbooks/`, `templates/`, `settings.json`, `README.md`에 `capture-prompt`, `scope-guard`, `template-guard`, `archive/20`이 없어야 한다(이력 문서와 테스트 파일의 삭제 매핑 주석 제외).
- `settings.json` 사본이 유효한 JSON이고, 등록한 훅 파일이 모두 `hooks/`에 있다.
- 듀얼 1패스 리뷰(Opus 워커 ∥ codex): 지운 테스트의 계약이 다른 곳에서 확인되는지(I2)를 중심으로.
- `~/.claude/settings.json` 수정(백업 뒤 `capture-prompt.sh` 등록만 삭제) → 배포 → smoke → 실제 세션의 다음 턴에서 재주입 줄 확인, `~/.claude/hooks/capture-prompt.sh`가 배포본에서 사라졌는지 확인. (2026-11-20 리뷰 반영으로 순서 변경: 배포가 `hooks/`를 통째로 바꾸므로, 등록을 먼저 지우지 않으면 그 사이의 턴이 없는 훅을 부른다.)

## 6. stakes (필수)

- 판정: **중간** — 근거: 훅 등록과 정책 문서(core.md 한 낱말)를 고치지만, 지우는 훅은 기록만 하고 읽는 곳이 없으며 차단 동작이 없다. 전부 git으로 되돌릴 수 있다. core 3절 표의 "config" 줄에 해당한다. `archive/` 삭제와 사본 정리만 보면 낮음이나, 실제 설정 변경과 테스트 삭제가 섞여 중간으로 잡는다.
- core 2절은 하네스·정책 변경을 높음으로 보라고 한다. 이번 변경은 새 규칙이나 새 차단을 넣지 않고 읽히지 않는 기록 훅 하나를 빼는 것이라 중간으로 판정했다. 사용자가 높음을 원하면 듀얼 리뷰 루프로 올린다.

---

## 7. 자율성 (모드 — stakes와 별개 축)

- [ ] auto (기본 권장 — 합의 후 Claude 자율 실행)
- [ ] lazy (매 diff 이해 게이트 — 학습·OSS 기여)

## 8. load-bearing 가정 (1~2개)

1. `.prompt`·`.turn` 사이드카를 읽는 코드가 저장소와 `~/.claude` 어디에도 없다 — 착수 직후 `grep`으로 다시 확인한다(훅, 스크립트, 스킬 폴더 포함).
2. UserPromptSubmit에 훅이 하나만 남아도 Claude Code가 종전처럼 부른다 — 배포 뒤 실제 세션의 다음 턴으로 확인한다.

## 9. task 분해

| task | 목표 | 의존 | acceptance |
|------|------|------|-----------|
| 01 | `archive/` 삭제, `settings.json` 사본의 낡은 등록 둘 삭제, README 숫자와 서술, `HISTORY.md` 머리 한 줄 | — | 테스트 전체 통과(변화 없음), grep 확인 |
| 02 | `capture-prompt.sh` 제거: 훅 파일, 사본 등록, core.md, README, 테스트 정리(I2 표) | 01 | 테스트 전체 통과, 지운 테스트의 계약 대응표 |
| 03 | 듀얼 1패스 리뷰 | 02 | open finding 0 |
| 04 | `~/.claude/settings.json` 수정(백업) → 배포 → 실제 세션 확인 | 03 | smoke 통과, 다음 턴 재주입 정상 |

---

## 승인 상태

- [x] 필수 6칸 전부 기입 (빈 칸 없음)
- [ ] 사용자 합의 → SPEC=1 (훅 기록 — Claude 직접 편집 금지)
- [ ] 자율성 선택 → MODE 기록
