# decisions — 선택 질문과 답 (훅이 자동 기록)

## 2026-11-20 13:13:00 (toolu_01GftP7YwvNc5UK9vAezzpF4)

### 명세 합의
- 질문: 하네스 정리 작업의 명세입니다. 지우는 것: archive/ 전체, settings.json 사본의 없는 훅 등록 둘, capture-prompt.sh(훅 파일, 사본과 실제 ~/.claude/settings.json의 등록, core.md 훅 목록, 관련 테스트). 건드리지 않는 것: docs/ 전체, 남는 훅의 코드. stakes는 중간(리뷰는 Opus와 codex 한 번씩)으로 잡았습니다. 이대로 진행할까요?
- 선택지: 합의, auto로 진행 (Recommended) / 합의, stakes는 높음으로 / capture-prompt는 빼고 진행
- 답: 합의, auto로 진행 (Recommended)

## 2026-11-20 13:55:33 (toolu_01BuBSqLk7ssRSZjtt9WAyny)

### 정리 push
- 질문: 하네스 정리 작업이 끝났습니다(브랜치 chore/cleanup-unused, 커밋 4개, 테스트 363개 통과, 배포 완료). 원격에 어떻게 올릴까요?
- 선택지: push + PR + 병합 (Recommended) / push + PR까지만 / 지금은 올리지 않기
- 답: push + PR + 병합 (Recommended)

## 2026-11-20 14:21:21 (toolu_01RsuV992sMgivjeS9kxDyjP)

### 질문 기록
- 질문: 인터뷰 질문이 직전 작업 폴더의 decisions.md에 기록되는 문제를 어떻게 고칠까요? 원인은 작업 폴더가 명세서를 쓸 때에야 생기는데 인터뷰는 그 전에 한다는 것입니다.
- 선택지: 순서를 바꾼다 (Recommended) / 훅이 복사한다 / 둘 다
- 답: 순서를 바꾼다 (Recommended)

### 남은 기록
- 질문: 세션을 새로 열었을 때 직전 세션의 작업 폴더(명세서, log, decisions.md)에 커밋되지 않은 변경이 있으면, 훅이 그 사실을 알리고 제가 이어갈지 여쭙니다. 이어가지 않는다고 하실 때 그 변경을 어떻게 할까요? 되돌리면 그 파일에 기록된 질문과 답이 지워집니다.
- 선택지: 세 가지 중에 고르게 한다 (Recommended) / 이어가기 아니면 되돌리기
- 답: 세 가지 중에 고르게 한다 (Recommended)

### 검증 강도
- 질문: 이 작업의 검증 강도를 어떻게 잡을까요? 훅 코드를 고치는 작업이고, 어제 v4.5는 높음으로 잡아 리뷰가 3회 돌았습니다.
- 선택지: 중간 (Recommended) / 높음
- 답: 중간 (Recommended)
