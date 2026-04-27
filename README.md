# iOSAppHackingLab

[![Self Check](https://github.com/jungyeons/iOSAppHackingLab/actions/workflows/self-check.yml/badge.svg)](https://github.com/jungyeons/iOSAppHackingLab/actions/workflows/self-check.yml)

iOS 앱 해킹 공부를 위해 SwiftUI로 만든 로컬 실습 앱입니다. 실제 서비스나 타인 앱을 대상으로 하지 않고, 의도적으로 취약하게 만든 앱 안에서만 관찰하고 실험하도록 구성했습니다.

Public portfolio repository: https://github.com/jungyeons/iOSAppHackingLab

## 실행

```bash
cd /Users/jungyeons/Documents/Projects/AppWhitehackLab
swift run
```

현재는 Xcode 없이도 빌드 가능한 Swift Package 형태의 macOS SwiftUI 앱입니다. Xcode가 설치되면 같은 학습 흐름을 iOS Simulator 타깃으로 확장할 수 있습니다.

## 현재 기능

- 랩별 진행률 체크
- 랩별 학습 노트 저장
- 취약 패턴과 안전한 구현 패턴 비교
- Markdown 학습 리포트 생성
- UserDefaults와 Keychain 저장 방식 비교
- 민감 로그와 redacted event log 비교
- 증거 캡처 체크리스트와 포트폴리오용 takeaway 정리
- `--self-check` 내장 검증 모드
- GitHub Actions 기반 self-check CI

## 포함된 랩

- Insecure Local Storage: `UserDefaults` 평문 저장과 Keychain 저장 비교
- Weak Static Secret: 하드코딩된 XOR 키로 payload 인코딩
- Sensitive Debug Logging: 민감한 토큰 로그와 redacted 로그 비교
- Tamperable Entitlement: 로컬 boolean 값을 권한처럼 신뢰

## 프로젝트 구조

```text
Sources/iOSAppHackingLab/
  Models/        랩 메타데이터와 체크리스트
  Store/         진행률, 노트, 취약 동작, 리포트 생성
  Security/      Keychain 비교 구현
  Views/         SwiftUI 화면과 랩별 액션 UI
docs/
  ARCHITECTURE.md
  LEARNING_ROADMAP.md
  SECURITY_SCOPE.md
```

## 연습 순서

1. 앱에서 각 랩의 버튼을 눌러 데이터를 생성합니다.
2. 소스에서 관련 키워드를 검색합니다.
3. 저장 위치, 로그, 하드코딩된 값을 직접 확인합니다.
4. 왜 취약한지 적고 더 안전한 설계를 생각합니다.
5. 앱에서 Markdown 리포트를 생성해 학습 기록으로 남깁니다.

## 유용한 명령

```bash
rg "lab\\.|weakKey|NSLog" .
swift run
swift run iOSAppHackingLab --self-check
```

## 안전 범위

이 저장소는 로컬 학습용입니다. 타인 앱, 실서비스, 실제 사용자 데이터, 권한이 없는 기기나 계정은 범위 밖입니다. 자세한 범위는 `docs/SECURITY_SCOPE.md`에 정리했습니다.

## 다음 단계

- Xcode 기반 iOS 시뮬레이터 타깃 추가
- Frida/LLDB 관찰용 심화 랩 추가
- 샘플 스크린샷과 포트폴리오용 프로젝트 설명 보강
