# ContentVault

ContentVault는 Flutter로 구축된 멀티플랫폼 콘텐츠 아카이브 앱으로, 사용자가 다양한 플랫폼(YouTube, X/Twitter, 웹 기사)에서 콘텐츠를 저장, 정리, 검색할 수 있으며 AI 기반 조직화 기능을 제공합니다.

## 기술 스택

- **프레임워크**: Flutter 3.16+ (Dart)
- **상태 관리**: Riverpod 2.0
- **로컬 데이터베이스**: Drift (SQLite)
- **네비게이션**: go_router
- **의존성 주입**: get_it
- **네트워크**: dio with retrofit
- **UI 컴포넌트**: Material 3
- **테스팅**: flutter_test, mockito, integration_test

## 주요 기능

- 다양한 플랫폼에서 콘텐츠 저장
- AI 기반 콘텐츠 조직화
- 강력한 검색 기능
- 오프라인 지원
- 크로스 플랫폼 (iOS, Android, Web, Desktop)

## 설치 및 실행

### 요구사항

- Flutter SDK 3.16.0 이상
- Dart SDK 3.2.0 이상
- Android Studio / VS Code (권장)

### 설치 방법

1. 저장소 클론
```bash
git clone <repository-url>
cd flutter-contentvault
```

2. 의존성 설치
```bash
flutter pub get
```

3. 코드 생성 (필요시)
```bash
flutter packages pub run build_runner build
```

4. 앱 실행
```bash
flutter run
```

## 프로젝트 구조

```
lib/
├── core/
│   ├── api/              # API 클라이언트 및 인터셉터
│   ├── database/         # Drift 데이터베이스 및 DAO
│   ├── di/               # 의존성 주입
│   ├── error/            # 에러 처리
│   ├── router/           # go_router 설정
│   ├── theme/            # 앱 테마 및 색상
│   └── utils/            # 유틸리티 및 헬퍼
├── features/
│   ├── save/             # 콘텐츠 저장 기능
│   ├── search/           # 검색 기능
│   ├── viewer/           # 콘텐츠 뷰어 기능
│   ├── ai/               # AI 처리 기능
│   └── settings/         # 설정 기능
├── shared/
│   ├── widgets/          # 재사용 가능한 위젯
│   ├── extensions/       # Dart 확장
│   └── constants/        # 앱 상수
└── main.dart
```

## 개발 규칙

자세한 개발 규칙은 `.cursor/rules/contentvault.mdc` 파일을 참조하세요.

## 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 LICENSE 파일을 참조하세요. 