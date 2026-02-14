# iOS (App Store) 배포 가이드

## ⚠️ 중요: Windows 사용자를 위한 안내

iOS 앱은 **반드시 macOS에서** 빌드해야 합니다. Windows 사용자는 다음 방법 중 하나를 선택하세요:

### 방법 1: 클라우드 빌드 서비스 (추천)
- **Codemagic** (무료 플랜 500분/월)
- **App Center** (Microsoft)
- **GitHub Actions** (macOS runner 사용)

### 방법 2: Mac 접근
- Mac 컴퓨터 빌려서 사용
- Mac 렌탈 서비스
- 친구/지인의 Mac 사용

### 방법 3: 먼저 Android 배포
- Google Play Store에 먼저 출시
- iOS는 나중에 Mac 접근 시 배포

---

## 필수 요구사항

### 1. Apple Developer 계정
- **비용**: $99/년
- **등록**: https://developer.apple.com/programs/enroll/
- **필요 서류**: 신분증, 결제 카드

### 2. macOS 환경
- macOS 12.0 이상
- Xcode 14.0 이상
- Flutter SDK

### 3. Apple ID
- 2단계 인증 활성화 필수

---

## Codemagic을 이용한 배포 (Windows에서 가능)

### 1단계: Codemagic 설정

1. **계정 생성**
   - https://codemagic.io 접속
   - GitHub/GitLab/Bitbucket 계정으로 로그인

2. **저장소 연결**
   - Git 저장소에 프로젝트 푸시
   - Codemagic에서 저장소 연결

3. **워크플로우 설정**

`codemagic.yaml` 파일 생성 (프로젝트 루트):

```yaml
workflows:
  ios-release:
    name: iOS Release
    environment:
      groups:
        - app_store_credentials
      flutter: stable
      xcode: latest
      cocoapods: default
    scripts:
      - name: Set up keychain
        script: |
          keychain initialize
      - name: Fetch signing files
        script: |
          app-store-connect fetch-signing-files "com.yourname.sudoku" --type IOS_APP_STORE
      - name: Add certificates to keychain
        script: |
          keychain add-certificates
      - name: Set up code signing settings on Xcode project
        script: |
          xcode-project use-profiles
      - name: Get Flutter packages
        script: |
          flutter packages pub get
      - name: Build iOS
        script: |
          flutter build ipa --release --export-options-plist=/Users/builder/export_options.plist
    artifacts:
      - build/ios/ipa/*.ipa
    publishing:
      app_store_connect:
        api_key: $APP_STORE_CONNECT_KEY_IDENTIFIER
        key_id: $APP_STORE_CONNECT_KEY_ID
        issuer_id: $APP_STORE_CONNECT_ISSUER_ID
```

### 2단계: App Store Connect 설정

1. **App Store Connect 접속**
   - https://appstoreconnect.apple.com
   - Apple Developer 계정으로 로그인

2. **새 앱 생성**
   - **"나의 앱"** → **"+"** → **"새로운 앱"**
   - 플랫폼: **iOS**
   - 이름: **Luxe Sudoku**
   - 기본 언어: **한국어**
   - 번들 ID: **com.yourname.sudoku** (고유해야 함)
   - SKU: **sudoku-app-001**

3. **앱 정보 입력**
   - 개인정보 처리방침 URL (필수)
   - 카테고리: **게임 > 퍼즐**
   - 부제목 (선택)
   - 프로모션 텍스트 (선택)

---

## Mac에서 직접 빌드하는 방법

### 1단계: Xcode 프로젝트 설정

```bash
cd c:\Cusor_game\sudoku_app  # Windows 경로 (Mac에서는 적절히 변경)
open ios/Runner.xcworkspace
```

### 2단계: Bundle Identifier 설정

Xcode에서:
1. **Runner** 선택
2. **Signing & Capabilities** 탭
3. **Bundle Identifier**: `com.yourname.sudoku` (고유하게 변경)
4. **Team**: Apple Developer 팀 선택
5. **Automatically manage signing** 체크

### 3단계: 앱 정보 설정

#### ios/Runner/Info.plist
```xml
<key>CFBundleDisplayName</key>
<string>Luxe Sudoku</string>
<key>CFBundleName</key>
<string>Luxe Sudoku</string>
<key>CFBundleVersion</key>
<string>1</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
```

#### pubspec.yaml
```yaml
name: sudoku_app
version: 1.0.0+1
```

### 4단계: 앱 아이콘 설정

1. **아이콘 생성**
   - 1024x1024 PNG 파일 준비
   - https://appicon.co/ 에서 iOS 아이콘 생성

2. **아이콘 추가**
   - Xcode에서 `Runner > Assets.xcassets > AppIcon` 선택
   - 각 크기별 이미지 드래그 앤 드롭

### 5단계: 스크린샷 준비

필수 크기 (최소 2장씩):
- **6.5인치 디스플레이**: 1242 x 2688 px
- **5.5인치 디스플레이**: 1242 x 2208 px

선택사항:
- **12.9인치 iPad Pro**: 2048 x 2732 px

### 6단계: 빌드 및 Archive

```bash
# Flutter 빌드
flutter clean
flutter pub get
flutter build ios --release

# Xcode에서 Archive
# Product > Archive
```

또는 명령줄:
```bash
flutter build ipa --release
```

빌드 결과: `build/ios/ipa/sudoku_app.ipa`

### 7단계: App Store Connect에 업로드

#### 방법 1: Xcode Organizer
1. Xcode → **Window** → **Organizer**
2. **Archives** 탭
3. 최신 아카이브 선택
4. **Distribute App** 클릭
5. **App Store Connect** 선택
6. **Upload** 선택
7. 서명 옵션 선택
8. **Upload** 클릭

#### 방법 2: Transporter App
1. Mac App Store에서 **Transporter** 설치
2. `.ipa` 파일을 Transporter로 드래그
3. **전달** 클릭

#### 방법 3: 명령줄 (altool)
```bash
xcrun altool --upload-app --type ios --file build/ios/ipa/sudoku_app.ipa \
  --username "your@email.com" \
  --password "app-specific-password"
```

### 8단계: App Store 정보 입력

App Store Connect에서:

#### 1. 앱 정보
- **이름**: Luxe Sudoku
- **부제**: 세련된 스도쿠 퍼즐 게임
- **카테고리**: 게임 > 퍼즐

#### 2. 가격 및 판매 가능 여부
- **가격**: 무료
- **국가**: 모든 국가 선택

#### 3. 버전 정보
- **스크린샷**: 각 크기별 업로드
- **프로모션 텍스트** (170자):
  ```
  🎮 깔끔한 디자인의 프리미엄 스도쿠
  ✨ 3가지 난이도, 무한 퍼즐
  🏆 리더보드 및 타이머
  🌙 다크 모드 지원
  ```

- **설명** (4000자):
  ```
  Luxe Sudoku - 프리미엄 스도쿠 경험

  세련되고 현대적인 디자인의 스도쿠 게임으로 논리적 사고력을 키워보세요!

  ✨ 주요 기능
  
  🎯 3가지 난이도
  • 쉬움: 초보자를 위한 30-35개 빈 칸
  • 보통: 적당한 도전 40-45개 빈 칸
  • 어려움: 전문가를 위한 50-55개 빈 칸

  🎮 게임 기능
  • 무한 퍼즐 자동 생성
  • 실행 취소/다시 실행
  • 스마트 힌트 시스템
  • 실시간 오류 검증
  • 타이머 및 기록
  • 리더보드

  🎨 디자인
  • 깔끔하고 미니멀한 UI
  • 다크 모드 완벽 지원
  • 반응형 레이아웃
  • 부드러운 애니메이션

  📱 최적화
  • 모든 iPhone 크기 지원
  • iPad 최적화
  • 오프라인 플레이 가능
  • 광고 없음

  🏆 도전과 성취
  • 최단 시간 기록 도전
  • 난이도별 리더보드
  • 게임 통계 추적

  지금 다운로드하고 스도쿠의 세계에 빠져보세요! 🧩
  ```

- **키워드** (100자):
  ```
  스도쿠,퍼즐,두뇌게임,논리게임,숫자퍼즐,sudoku,puzzle
  ```

- **지원 URL**: 본인 웹사이트 또는 GitHub
- **마케팅 URL**: 선택사항

#### 4. 앱 검토 정보
- **연락처**: 본인 이메일 및 전화번호
- **데모 계정**: 필요 없음
- **메모**: 
  ```
  이 앱은 스도쿠 퍼즐 게임입니다. 
  모든 기능은 즉시 사용 가능하며 추가 로그인이나 설정이 필요하지 않습니다.
  ```

#### 5. 버전 릴리스
- **자동 출시**: 승인 즉시 출시
- **수동 출시**: 승인 후 수동 출시

### 9단계: 심사 제출

1. 모든 정보 입력 확인
2. **심사에 제출** 클릭
3. 수출 규정 준수 확인
4. 제출 완료

### 10단계: 심사 대기

- **대기 중 심사**: 보통 24-48시간
- **심사 중**: 보통 24시간
- **승인**: 자동 또는 수동 출시
- **거절**: 피드백 확인 후 재제출

---

## GitHub Actions를 이용한 자동 배포

`.github/workflows/ios.yml`:

```yaml
name: iOS Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.7'
          
      - name: Install dependencies
        run: flutter pub get
        
      - name: Build iOS
        run: flutter build ios --release --no-codesign
        
      - name: Build IPA
        run: |
          cd build/ios/iphoneos
          mkdir Payload
          cp -r Runner.app Payload
          zip -r app.ipa Payload
          
      - name: Upload to App Store
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: build/ios/iphoneos/app.ipa
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
```

---

## 업데이트 배포

### 버전 증가
```yaml
# pubspec.yaml
version: 1.0.1+2  # 1.0.1 = 버전명, 2 = 빌드 번호
```

### 빌드 및 제출
```bash
flutter build ipa --release --build-number=2
```

App Store Connect에서 새 버전 생성 및 제출

---

## 문제 해결

### 서명 오류
```bash
# 인증서 목록 확인
security find-identity -v -p codesigning

# Xcode에서 자동 서명 다시 시도
```

### 빌드 오류
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
flutter build ios --release
```

### TestFlight 배포
심사 전 베타 테스트:
1. App Store Connect → TestFlight
2. 내부 또는 외부 테스터 추가
3. 빌드 선택 및 테스터에게 전송

---

## 체크리스트

- [ ] Apple Developer 계정 ($99/년)
- [ ] Mac 또는 클라우드 빌드 서비스
- [ ] Xcode 설치 (Mac의 경우)
- [ ] Bundle ID 설정
- [ ] 앱 아이콘 준비 (1024x1024)
- [ ] 스크린샷 준비 (각 크기별)
- [ ] 앱 설명 작성
- [ ] 개인정보 처리방침 URL (필수)
- [ ] 빌드 및 Archive
- [ ] App Store Connect 정보 입력
- [ ] 심사 제출

---

## Windows 사용자 추천 순서

1. ✅ **먼저 Android 배포** (Windows에서 가능)
2. ⏳ **iOS는 나중에** (Mac 접근 시 또는 클라우드 서비스 이용)
3. 🚀 **동시 진행**: Android 심사 중 iOS 준비

---

## 비용 요약

| 항목 | 비용 | 주기 |
|------|------|------|
| Apple Developer | $99 | 연간 |
| Google Play Console | $25 | 일회성 |
| Codemagic (무료) | $0 | 500분/월 |
| Codemagic (Pro) | $39 | 월간 |

---

## 다음 단계

1. Android 배포 완료
2. 사용자 피드백 수집
3. iOS 배포 준비 (Mac 또는 클라우드)
4. 정기 업데이트 및 유지보수
