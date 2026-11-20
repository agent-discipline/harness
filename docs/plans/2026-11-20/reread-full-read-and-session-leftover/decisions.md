# decisions — 선택 질문과 답 (훅이 자동 기록)

## 2026-11-20 14:23:29 (toolu_014cwi81F1HytnhR9R9Nqrc1)

### 명세 합의
- 질문: 훅 보완 작업의 명세입니다. ① offset·limit을 붙인 부분 읽기는 압축 뒤 재독으로 세지 않는다 ② 새 작업은 log.md를 먼저 만들고 인터뷰한다(core.md 절차, 훅 코드 불변) ③ 새 세션 시작 때 직전 세션 작업 폴더에 커밋되지 않은 변경이 있으면 훅이 한 줄로 알리고, 제가 이어가기/기록만 커밋/되돌리기를 여쭙다. stakes는 중간. 이대로 진행할까요?
- 선택지: 합의, auto로 진행 (Recommended) / 알림은 resume에도 / 수정할 것이 있다
- 답: 합의, auto로 진행 (Recommended)

## 2026-11-20 15:07:38 (toolu_014kDaL6mRW8Q48RE19Nt1Vh)

### v4.6 push
- 질문: 훅 보완 작업(v4.6)이 끝났습니다. 브랜치 fix/reread-full-read-and-session-leftover, 커밋 5개, 테스트 376개 통과, 배포 완료. 실제 세션에서 부분 읽기로는 차단이 풀리지 않고 전체 읽기로 풀리는 것을 확인했습니다. 원격에 어떻게 올릴까요?
- 선택지: push + PR + 병합 (Recommended) / push + PR까지만 / 지금은 올리지 않기
- 답: push + PR + 병합 (Recommended)
