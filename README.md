# iOSAppHackingLab

iOS 앱 해킹 공부를 위해 SwiftUI로 만든 로컬 실습 앱입니다. 실제 서비스나 타인 앱을 대상으로 하지 않고, 의도적으로 취약하게 만든 앱 안에서만 관찰하고 실험하도록 구성했습니다.

## 실행

```bash
cd /Users/jungyeons/Documents/Projects/AppWhitehackLab
swift run
```

## 현재 기능

- 랩별 진행률 체크
- 랩별 학습 노트 저장
- 취약 패턴과 안전한 구현 패턴 비교
- Markdown 학습 리포트 생성

## 포함된 랩

- Insecure Local Storage: `UserDefaults`에 평문 계정 정보 저장
- Weak Static Secret: 하드코딩된 XOR 키로 payload 인코딩
- Sensitive Debug Logging: 민감한 토큰을 `NSLog`로 출력
- Tamperable Entitlement: 로컬 boolean 값을 권한처럼 신뢰

## 연습 순서

1. 앱에서 각 랩의 버튼을 눌러 데이터를 생성합니다.
2. 소스에서 관련 키워드를 검색합니다.
3. 저장 위치, 로그, 하드코딩된 값을 직접 확인합니다.
4. 왜 취약한지 적고 더 안전한 설계를 생각합니다.

## 유용한 명령

```bash
rg "lab\\.|weakKey|NSLog" .
swift run
```

## 다음 단계

- Keychain 기반 안전 저장 예시 추가
- Xcode 기반 iOS 시뮬레이터 타깃 추가
- Frida/LLDB 관찰용 심화 랩 추가
- 샘플 스크린샷과 포트폴리오용 프로젝트 설명 보강
