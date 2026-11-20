# decisions — 선택 질문과 답 (훅이 자동 기록)

## 2026-11-20 20:17:53 (toolu_019yaeNgfCViLPKDBkJG4iZf)

### A 나누기
- 질문: 분기 A (task 01): 작업을 task로 나누는 것을 언제 의무로 할까요?
- 선택지: 한 문장으로 안 되면 항상 (Recommended) / 중간 이상만
- 답: 한 문장으로 안 되면 항상 (Recommended)

### B 검증
- 질문: 분기 B (task 02): task마다 어떤 검증을 할까요?
- 선택지: task마다 그 강도대로 + 마지막 확인 (Recommended) / task마다 셀프체크, 리뷰는 마지막에 한 번
- 답: task마다 그 강도대로 + 마지막 확인 (Recommended)

### C 진행 중
- 질문: 분기 C (task 03): 합의 뒤에 생긴 결정 가운데 무엇을 멈추고 여쭐까요?
- 선택지: 네 가지만 묻는다 (Recommended) / 전부 기록하고 진행 / 그때그때 묻는다
- 답: 네 가지만 묻는다 (Recommended)

### D·E 허가
- 질문: 분기 D·E (task 04): 커밋과 push의 전체 허가를 어떤 선택지로 두고, 어떻게 강제할까요?
- 선택지: 선택지 셋 + 절차로만 (Recommended) / 선택지 셋 + 훅까지 / 선택지 둘 + 절차로만
- 답: 선택지 셋 + 절차로만 (Recommended)

## 2026-11-20 20:18:52 (toolu_01NtMXifinoz53jBM52CSpKk)

### 명세 합의
- 질문: 분기의 답을 모두 받았습니다(A 한 문장으로 안 되면 항상 / B task마다 그 강도대로 + 마지막 확인 / C 네 가지만 묻는다 / D·E 선택지 셋 + 절차로만). 이 답으로 명세를 고정하고 task 01부터 순서대로 진행할까요? 이 작업부터 새 방식을 적용합니다.
- 선택지: 합의, auto로 진행 (Recommended) / 수정할 것이 있다
- 답: 합의, auto로 진행 (Recommended)

### 허가 범위
- 질문: 이 작업의 커밋과 push 허가 범위를 골라 주세요(task 04가 넣으려는 선택을 이 작업부터 적용합니다). 강제 push, main에 직접 push, 삭제는 어느 쪽을 고르셔도 따로 여쭙니다.
- 선택지: 브랜치의 커밋·push·PR 생성까지 (Recommended) / 병합까지 / 매번 묻기
- 답: 브랜치의 커밋·push·PR 생성까지 (Recommended)
