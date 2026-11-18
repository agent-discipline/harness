# 요구사항 명세서 — 한국어 문서 낱말 규칙을 하네스에 추가

> 작성일: 2026-11-18 · 요청 세션: resume 저장소 세션 · 사용자 원문: "위 작업 후 작성 규칙을 하네스에 적용하고 우리 클로드 코드 하네스로 하네스 동기화 시키고 추가적으로 에이전트쪽 하네스도 동기화 시켜놔야겠네 우선 adr 수정 마무리하고 하네스에 해당 규칙도 추가해놓자 룰즈에도 표를 만들고 이후 한번에 정리를 할 거지만 같이 맞춰놓을 필요는 있으니"

1. 목표·대상: `playbooks/korean-wording.md` 신설(조건부 문서, 51줄) + `src/core.md` §8 트리거 표 1행 + 변경 이력 1행. 이후 `hooks/deploy.sh`로 `~/.claude` 배포.
2. 경계·불변식: 훅, 게이트, 상태 전이, 기존 규칙 문장은 바꾸지 않는다. 상시 문서(core.md)에는 §8 트리거 1행과 변경 이력 1행(버전마다 한 줄 남기는 기존 관례)만 더한다. 규칙 정본은 rules 저장소이고 플레이북은 요약이다.
3. 기준소스: `agent-discipline/rules/writing/principles.md` 낱말 절, `writing/wording-table.md`.
4. 금지영역: hooks/, settings.json, CLAUDE.md, 기존 playbook 본문.
5. 검증 방법: `hooks/tests/run.sh` 통과, `deploy.sh --dry-run`의 차이가 위 2개 파일뿐인지 확인, 배포 뒤 `diff -q src/core.md ~/.claude/core.md`.
6. stakes: 정책 파일 변경이라 core §2 기준 높음(확정 전 교차 검증 1회). 변경 내용은 조건부 문서 추가와 표 1행이라 영향 범위는 작다.

자율성: auto
load-bearing 가정: 배포는 사용자 확인 뒤에 한다 — 상시 문서가 바뀌면 지금 돌고 있는 다른 세션(좌석 랩 ADR-018 등)에도 다음 주입부터 적용된다.
