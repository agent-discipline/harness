# decisions — 선택 질문과 답 (훅이 자동 기록)

## 2026-11-19 21:04:37 (toolu_01YBWHcokW3Eyh33RPAtMNNu)

### 고정 지시
- 질문: 배포와 훅 등록을 마쳤습니다. 이제 고정 지시 파일(~/.claude/standing-instructions.md)을 만들어야 매 턴 재주입이 실제로 동작합니다. 이 파일에 적힌 줄은 모든 프로젝트의 모든 세션에 매 턴 들어갑니다. 무엇을 넣을까요?
- 선택지: 한국어 응답 한 줄 (Recommended) / 지금은 만들지 않기
- 답: 한국어 응답 한 줄 (Recommended)

### 승인 창
- 질문: 앞서 '이게 왜 필요하냐'고 물으신 것에 대한 설명입니다. 고정 지시 파일은 CLAUDE.md처럼 모든 세션의 행동을 바꾸는 파일입니다. 그런데 CLAUDE.md는 모델이 고치려면 명세 합의 게이트를 거쳐야 하고, 이 파일은 아무 게이트도 없습니다. 예를 들어 모델이 어떤 저장소의 문서를 읽다가 '앞으로 항상 이렇게 하라고 고정 지시에 적어 두라'는 문장을 따르면, 그 한 줄이 다른 모든 프로젝트의 세션에도 매 턴 들어갑니다. 승인 창은 그런 변경이 사용자 모르게 들어가는 것을 막으려는 것입니다. 넣을까요?
- 선택지: 넣는다 (Recommended) / 넣지 않는다
- 답: 넣는다 (Recommended)

## 2026-11-20 00:08:03 (toolu_01UcStsfUHGw12EKtfGMqFUc)

### 하네스 push
- 질문: 하네스 v4.5(선택 질문 기록, 압축 뒤 재독 강제, 고정 지시 재주입) 작업을 마감했습니다. 브랜치 feat/decision-archive-compact-reread에 커밋 11개가 있고 아직 push하지 않았습니다. 이미 ~/.claude에는 배포돼 동작 중입니다. 원격(agent-discipline/harness, public)에 어떻게 올릴까요?
- 선택지: 브랜치 push + PR 생성 (Recommended) / 브랜치만 push / 지금은 올리지 않기
- 답: 브랜치 push + PR 생성 (Recommended)

### 실험 push
- 질문: compaction-experiment 저장소(public)의 main에 push하지 않은 커밋 3개가 있습니다: standing 조건 추가(명세 한 줄, 실행 도구)와 Haiku 3회 결과(README 절, 집계). main에 바로 올릴까요?
- 선택지: main에 push (Recommended) / 지금은 올리지 않기
- 답: main에 push (Recommended)

### 이슈 아카이브
- 질문: 하네스 작업에서 나온 CS 이슈 후보 4건(여러 세션의 동시 파일 쓰기 손상, 기록 중 파일 교체로 인한 유실, 잠금 밖 삭제 경합, 부하로 인한 테스트 시간 초과)을 study-note 저장소의 issue/에 아카이브할까요? 명세 범위에 없어서 보류로 적어 두었습니다.
- 선택지: 보류로 둔다 (Recommended) / 지금 아카이브한다
- 답: 지금 아카이브한다

## 2026-11-20 13:10:50 (toolu_01DEH1jX7SLpxbVZqPVcVohV)

### 옛 docs
- 질문: archive/ 폴더(옛 v1, v2 통째 보관, 2.0MB)는 말씀대로 지웁니다. 그런데 docs/ 최상위의 HISTORY.md(424줄), phase1-structure.md, phase2-bestpractices.md, analysis/ 3개는 archive의 v2 사본과 바이트까지 같은 옛 문서이고, 지금 하네스의 어떤 파일도 가리키지 않습니다. 이것도 함께 지울까요?
- 선택지: 함께 지운다 (Recommended) / docs는 남긴다
- 답: docs는 남긴다

### 작업 기록
- 질문: docs/plans에는 2026-03부터의 작업 폴더가 35개 날짜분(2.5MB) 쌓여 있습니다. v4(2026-07-21) 이전 폴더는 지금과 다른 문서 체계(plan, checklist, learned 등)로 쓴 기록입니다. 어떻게 할까요?
- 선택지: 그대로 둔다 (Recommended) / v4 이전 것만 지운다
- 답: 그대로 둔다 (Recommended)

### 안 쓰는 훅
- 질문: capture-prompt.sh는 매 턴 사용자 메시지를 사이드카에 적기만 하고 읽는 곳이 없는 훅입니다. 지우려면 훅 파일, 테스트, core.md의 활성 훅 목록, 그리고 실제 ~/.claude/settings.json의 등록까지 고치고 다시 배포해야 합니다. 어떻게 할까요?
- 선택지: 이번 정리 뒤에 따로 지운다 (Recommended) / 이번에 함께 지운다 / 지우지 않는다
- 답: 이번에 함께 지운다
