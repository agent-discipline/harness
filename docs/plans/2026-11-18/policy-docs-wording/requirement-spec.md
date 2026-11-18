# 요구사항 명세서 — 정책 문서의 낱말을 매칭표에 맞춤

> 작성일: 2026-11-18 · 사용자 원문: "스터디노트를 수정하면서 추가적인 매핑표를 만들면서 이걸 한번에 하네스 정책 문서에 반영해서 처리하는 게 맞겠네" → (study-note 완료 뒤) "하네스 정책 문서 반영하자"

1. 목표·대상: `src/core.md`, `playbooks/review.md`, `playbooks/issue-archive.md`, `playbooks/implementation-lazymode.md`, `README.md`에서 rules 매칭표(`writing/wording-table.md`)에 있는 낱말 13곳을 통용어로 바꾼다. 무음 -> 조용한, 귀속 -> ~에서 나온 / 근거, 가시화 -> 드러내기, 부적용 -> 해당 없음, 지배한다 -> 정한다.
2. 경계·불변식: 규칙의 뜻, 조항 번호, 절 구조, 훅이 찾는 문자열은 바꾸지 않는다. 하네스가 정의한 용어(stakes, 날조, churn, 절단선, 이연, 위장, 승격, 하한)는 정책 용어라 대상이 아니다. 훅 스크립트(주석 포함)는 건드리지 않는다.
3. 기준소스: `agent-discipline/rules/writing/wording-table.md`, `playbooks/korean-wording.md`.
4. 금지영역: hooks/, settings.json, CLAUDE.md, templates/, agents/.
5. 검증 방법: `hooks/tests/run.sh` 261 통과, 바꾼 줄 diff 전부 확인, codex 교차 검증 1회(뜻이 바뀐 문장이 있는지), `deploy.sh` 뒤 소스와 `~/.claude` 일치.
6. stakes: 정책 파일 변경이라 높음(core §2). 낱말 13곳, 뜻 변경 없음.

자율성: auto
load-bearing 가정: 훅과 테스트가 이 낱말들을 문자열로 찾지 않는다(착수 직후 grep으로 확인).
