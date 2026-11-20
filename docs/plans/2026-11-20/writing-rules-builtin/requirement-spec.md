# 요구사항 명세서 — 글쓰기 규칙을 하네스에 넣기

> 작성일: 2026-11-20 · 작업 폴더: `docs/plans/2026-11-20/writing-rules-builtin/`

---

## 0. 요구사항 원문 (인터뷰 기록)

- 원문(2026-11-20):
  - "그렇다면 rules를 하네스에 빌트인하는 방식으로 가고 … rules에 대해서는 아직 보류하고 하네스에 rules를 담아서 의사결정 라우팅처리를 할 수 있도록 만드는게 베스트겠네."
  - "그리고 그렇다면 rules의 writing 관련해서 어떻게 문서를 하네스로 빌트인해야겠네."
  - "번역체들을 어떻게 다듬고 글을 어떻게 써서 문서를 어떻게 써야하는지에 대한 내용을 빌트인하는게 맞겠네."
  - "이거 하고 글쓰기 규칙, 문서 작성법을 하네스에 빌트인해보자."
- 메인 제안(2026-11-20) → 사용자 "진행하자":
  - 네 문서를 `playbooks/writing/`에 그대로 옮기고 요약본(`korean-wording.md`)은 없앤다.
  - 사례 표(`wording-table.md`)에 줄을 덧붙이는 일은 게이트 없이 할 수 있게 둔다.
  - rules의 `writing/`은 "하네스로 옮겼다"는 안내만 남기고 지운다.
- 조사(메인, 실파일):
  - rules `writing/`: `principles.md`(120줄) · `wording-table.md`(248줄) · `work-records.md`(77줄) · `diagrams.md`(75줄), 그리고 저장소 루트의 `ROUTING.md`(38줄 — 쓰려는 문서의 종류별로 읽을 문서를 가리키는 표).
  - 네 문서의 서로를 가리키는 링크는 같은 폴더 기준 상대 링크다(`principles.md` ↔ `wording-table.md`). `ROUTING.md`만 `writing/…` 경로로 가리킨다.
  - 하네스에서 `korean-wording.md`를 가리키는 곳은 `src/core.md` 8절 표의 한 행과 변경 이력의 v4.4 줄뿐이다. 훅과 테스트는 이 파일을 보지 않는다.
  - `hooks/deploy.sh`는 `playbooks/`를 통째로 `~/.claude/playbooks/`에 복사한다(하위 폴더 포함).
  - gate-guard는 SPEC=0이거나 MODE=UNSET일 때만 L1 쓰기를 막는다. 합의된 작업이 진행 중인 세션에서는 `playbooks/` 파일 쓰기가 막히지 않고, 다른 프로젝트의 세션에서는 하네스 저장소가 "저장소 밖"이라 L0로 통과한다.

---

## 1. 목표·대상 (필수)

rules 저장소의 글쓰기 규칙을 하네스 저장소(`agent-discipline/harness`)로 옮겨, 하네스만 설치해도 글쓰기 규칙이 함께 따라오게 한다.

1. rules의 `writing/` 네 문서와 `ROUTING.md`를 하네스 `playbooks/writing/`으로 옮긴다(내용은 그대로, 경로만 맞춤).
2. `playbooks/korean-wording.md`를 지운다.
3. `src/core.md` 8절 표의 `korean-wording.md` 행을 `playbooks/writing/ROUTING.md`를 가리키는 한 행으로 바꾼다.
4. 사례 표에 줄을 덧붙이는 일은 새 작업으로 보지 않는다는 절차 한 줄을 넣는다.
5. rules 저장소에서 `writing/`과 `ROUTING.md`를 지우고 README에 옮긴 곳을 적는다.

끝의 기준: 배포 뒤 `~/.claude/playbooks/writing/`에 다섯 문서가 있고, core.md의 표가 그 길목을 가리키며, 옮긴 문서 안의 링크가 깨지지 않는다.

## 2. 경계·불변식 (필수)

- **I1 내용 보존**: 네 문서의 규칙·표·출처는 한 글자도 바꾸지 않는다. 바꾸는 것은 ①문서 사이의 경로 표기(옮긴 뒤에도 맞게) ②"이 저장소"처럼 rules 저장소를 가리키던 표현 ③`ROUTING.md` 머리 문단(하네스 안의 문서라는 것) 뿐이다. 바꾼 줄은 log에 전부 적는다. (2026-11-20 대조 반영으로 추가: ④지운 요약본에만 있던 규칙 — 글쓴 모델에게 자기 글을 검토시키지 않는다, 이미 쓴 커밋 메시지·인용·로그 문자열은 고치지 않는다 — 과 사례를 덧붙일 원본의 위치는 `ROUTING.md`의 사례 표 문단 아래에 옮겨 적는다. 네 문서의 본문은 여전히 그대로 둔다.)
- **I2 정본은 하나**: 옮긴 뒤 글쓰기 규칙의 정본은 하네스 `playbooks/writing/`이다. 요약본을 따로 두지 않는다.
- **I3 상시 맥락은 늘리지 않는다**: `src/core.md`의 줄 수는 늘지 않는다(8절 표의 한 행을 한 행으로 바꾸고, 절차 한 줄은 기존 줄에 붙인다). 매 세션에 들어가는 것은 종전대로 CLAUDE.md와 core.md뿐이다.
- **I4 길목**: core.md 8절의 새 행은 "사람이 읽을 문서를 쓰거나 고칠 때, 작업 기록을 쓸 때, 문서에 그림을 넣을 때 `playbooks/writing/ROUTING.md`의 표에서 읽을 문서를 찾는다"는 뜻을 담는다. 종전 `korean-wording.md` 행이 담던 트리거(사람이 읽을 한국어 문서, 작업 원본은 낱말 규칙에서 제외)는 `ROUTING.md`와 `principles.md`가 이미 갖고 있으므로 행에서 되풀이하지 않는다.
- **I5 사례 표의 덧붙이기**: `playbooks/writing/wording-table.md`에 사례 줄을 덧붙이는 일은 새 작업(명세·작업 폴더)으로 보지 않는다. 원본은 하네스 저장소의 파일이고, `~/.claude`의 배포본은 다음 배포 때 따라온다. 훅 코드는 바꾸지 않는다.
- **I6 8절 머리의 길이 규칙**: "각 ≤80줄"에 `writing/`은 예외라고 적는다(principles 120줄, wording-table 248줄 — 사례 대장은 자란다).
- **I7 훅과 테스트 불변**: `hooks/**`는 고치지 않는다. 테스트 376개는 그대로 통과한다.
- **I8 rules 저장소**: `writing/`과 `ROUTING.md`를 지우고, README의 "현재 상태"와 "에이전트에게 전달하는 방식"에 글쓰기 규칙을 하네스로 옮겼다는 것과 새 위치를 적는다. rules 저장소의 `docs/plans/`(과거 작업 기록)는 고치지 않는다.

## 3. 기준소스 (필수)

- 옮길 내용: rules 저장소 `main`(`9bcf101`)의 `writing/*.md`, `ROUTING.md`.
- 하네스: `main`(`399367f`)의 `src/core.md`, `playbooks/`, `README.md`.

## 4. 금지영역 (필수)

- `hooks/**`, `settings.json`, `~/.claude/settings.json`, `templates/`, `agents/`.
- 네 문서의 규칙 내용(I1). 고치고 싶은 곳이 보여도 이번에는 옮기기만 하고 NEXT에 적는다.
- study-note 저장소(문서의 "출처"가 가리키는 원본)는 건드리지 않는다.
- 두 저장소 모두 push·PR·병합은 사용자 확인 뒤. `main`에 직접 커밋하지 않는다.
- 배포는 `hooks/deploy.sh` 경유만.

## 5. 검증 방법 (필수)

- 옮긴 문서와 원본의 차이를 `diff`로 뽑아, 바뀐 줄이 I1이 허용한 세 종류뿐인지 확인한다.
- 옮긴 다섯 문서 안의 모든 링크와 경로 표기가 실제 파일을 가리키는지 스크립트로 확인한다.
- 하네스 전체에서 `korean-wording`을 grep 해 남은 곳이 변경 이력 줄뿐인지 확인한다. core.md 줄 수(143)가 늘지 않았는지 확인한다.
- `bash hooks/tests/run.sh` 전체 통과(376).
- 배포 → smoke → `~/.claude/playbooks/writing/`에 다섯 파일, `~/.claude/playbooks/korean-wording.md` 없음.
- 다른 모델의 확인 1회(Opus 워커): 옮긴 문서를 원본과 대조하고, core.md의 새 행만 읽고도 문서를 쓸 때 무엇을 읽어야 하는지 찾아갈 수 있는지 본다.

## 6. stakes (필수)

- 판정: **낮음** — 근거: 문서를 그대로 옮기고 표의 한 행을 바꾼다. 훅과 테스트를 고치지 않고, 전부 git으로 되돌릴 수 있다. 틀릴 수 있는 곳은 깨진 링크와 길목 문구이고 둘 다 스크립트와 한 번의 대조로 확인된다.
- core 4절은 정책 문서를 실행물 규칙으로 보라고 하고 2절은 하네스·정책 변경을 높음으로 보라고 한다. 이번 변경은 새 규칙을 만들지 않고 이미 쓰던 문서의 위치를 옮기는 것이라 낮음으로 판정했고, 그래도 다른 모델의 대조 1회는 넣었다. 사용자가 올리라고 하면 듀얼 1패스로 올린다.

---

## 7. 자율성 (모드 — stakes와 별개 축)

- [ ] auto (기본 권장 — 합의 후 Claude 자율 실행)
- [ ] lazy (매 diff 이해 게이트 — 학습·OSS 기여)

## 8. load-bearing 가정 (1~2개)

1. `deploy.sh`가 `playbooks/` 아래의 하위 폴더(`writing/`)까지 복사한다 — `--dry-run`으로 착수 직후 확인한다.

## 9. task 분해

| task | 목표 | 의존 | acceptance |
|------|------|------|-----------|
| 01 | 하네스: 다섯 문서 옮기기, 경로 맞춤, `korean-wording.md` 삭제, core.md 8절, README 구조 절 | — | diff·링크·grep·테스트 통과 |
| 02 | 다른 모델의 대조 1회와 반영 | 01 | 지적 반영 |
| 03 | 배포와 배포본 확인 | 02 | smoke 통과, 다섯 파일 확인 |
| 04 | rules 저장소: `writing/`·`ROUTING.md` 삭제, README 갱신 | 03 | rules README가 새 위치를 가리킴 |

---

## 승인 상태

- [x] 필수 6칸 전부 기입 (빈 칸 없음)
- [ ] 사용자 합의 → SPEC=1 (훅 기록 — Claude 직접 편집 금지)
- [ ] 자율성 선택 → MODE 기록
