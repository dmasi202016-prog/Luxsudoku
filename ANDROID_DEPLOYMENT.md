# Android (Google Play Store) 배포 가이드

## 1단계: 앱 서명 키 생성

### 키스토어 생성
```powershell
cd c:\Cusor_game\sudoku_app\android
keytool -genkey -v -keystore sudoku-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sudoku
```

질문에 답변:
- **비밀번호**: 안전한 비밀번호 입력 (잊어버리면 안 됨!)
- **이름**: 본인 이름
- **조직**: 개인 또는 회사명
- **도시, 주, 국가 코드**: KR 등

### key.properties 파일 생성
`android/key.properties` 파일 생성:
```properties
storePassword=위에서_입력한_비밀번호
keyPassword=위에서_입력한_비밀번호
keyAlias=sudoku
storeFile=sudoku-release-key.jks
```

⚠️ **중요**: `key.properties`와 `.jks` 파일은 절대 Git에 커밋하지 마세요!

## 2단계: 앱 정보 설정

### pubspec.yaml 수정
```yaml
name: sudoku_app
description: Luxe Sudoku Game
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
```

### android/app/build.gradle 수정

`applicationId` 수정 (고유한 ID):
```gradle
android {
    defaultConfig {
        applicationId "com.yourname.sudoku"  // 변경 필요
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

서명 설정 추가 (`android {` 블록 안에):
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
    }
}
```

### android/app/src/main/AndroidManifest.xml
앱 이름과 아이콘 확인:
```xml
<application
    android:label="Luxe Sudoku"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">
```

## 3단계: 앱 아이콘 및 메타데이터

### 앱 아이콘 생성
1. https://icon.kitchen/ 또는 https://appicon.co/ 방문
2. 아이콘 이미지 업로드 (1024x1024 PNG 권장)
3. Android 아이콘 다운로드
4. `android/app/src/main/res/mipmap-*` 폴더에 복사

### 스크린샷 준비
- 휴대폰 스크린샷 5-8장
- 크기: 1080x1920 또는 실제 기기 크기
- 게임 플레이 화면 포함

## 4단계: 릴리즈 APK/AAB 빌드

### AAB 빌드 (Play Store 권장)
```powershell
cd c:\Cusor_game\sudoku_app
flutter build appbundle --release
```

빌드 결과: `build\app\outputs\bundle\release\app-release.aab`

### APK 빌드 (테스트용)
```powershell
flutter build apk --release
```

빌드 결과: `build\app\outputs\flutter-apk\app-release.apk`

## 5단계: Google Play Console 설정

### 개발자 계정 생성
1. https://play.google.com/console 접속
2. Google 계정으로 로그인
3. 개발자 등록 ($25 일회성 결제)
4. 개인정보 입력 및 약관 동의

### 앱 생성
1. **"앱 만들기"** 클릭
2. 앱 이름: **Luxe Sudoku**
3. 기본 언어: **한국어**
4. 앱 또는 게임: **게임**
5. 무료/유료: **무료**

### 스토어 등록정보 작성

#### 앱 세부정보
- **앱 이름**: Luxe Sudoku
- **간단한 설명** (80자):
  ```
  세련된 디자인의 스도쿠 퍼즐 게임. 3가지 난이도로 두뇌를 훈련하세요!
  ```
- **전체 설명** (4000자):
  ```
  🎮 Luxe Sudoku - 프리미엄 스도쿠 경험

  깔끔하고 현대적인 디자인의 스도쿠 게임으로 논리적 사고력을 키워보세요!

  ✨ 주요 기능
  • 3가지 난이도 (쉬움, 보통, 어려움)
  • 무한 퍼즐 자동 생성
  • 실행 취소/다시 실행
  • 힌트 시스템
  • 실시간 검증
  • 타이머 및 리더보드
  • 다크 모드 지원
  • 광고 없음

  🎯 게임 방법
  9x9 격자를 1부터 9까지의 숫자로 채우세요. 각 행, 열, 3x3 박스에는 1-9가 중복 없이 들어가야 합니다.

  🏆 리더보드
  최단 시간 기록에 도전하고 자신의 실력을 확인하세요!

  📱 반응형 디자인
  모든 화면 크기에 최적화되어 스마트폰과 태블릿 모두에서 완벽하게 작동합니다.

  지금 다운로드하고 스도쿠의 세계에 빠져보세요! 🧩
  ```

#### 그래픽
- **앱 아이콘**: 512x512 PNG (32비트)
- **기능 그래픽**: 1024x500 PNG
- **휴대폰 스크린샷**: 최소 2장 (최대 8장)
- **7인치 태블릿 스크린샷**: 선택사항
- **10인치 태블릿 스크린샷**: 선택사항

#### 앱 카테고리
- **카테고리**: 퍼즐
- **태그**: 스도쿠, 퍼즐, 두뇌 게임, 논리

#### 연락처 정보
- **이메일**: 본인 이메일
- **웹사이트**: 선택사항
- **전화번호**: 선택사항

### 콘텐츠 등급
1. **설문조사 시작**
2. 폭력, 선정성 등 모두 **"아니요"** 선택
3. 등급 자동 산정 (전체 이용가)

### 대상 고객 및 콘텐츠
- **대상 연령**: 전체
- **광고 포함 여부**: 아니요

### 개인정보처리방침
개인정보를 수집하지 않는 경우: "이 앱은 사용자 데이터를 수집하지 않습니다" 선택

## 6단계: 프로덕션 트랙에 업로드

### 내부 테스트 (선택사항)
1. **내부 테스트** 탭 선택
2. **새 릴리스 만들기**
3. AAB 파일 업로드
4. 릴리스 이름: "버전 1.0.0"
5. 릴리스 노트 작성
6. **검토** → **프로덕션 시작**

### 프로덕션 배포
1. **프로덕션** 탭 선택
2. **새 릴리스 만들기**
3. AAB 파일 업로드 (`app-release.aab`)
4. 릴리스 이름: **버전 1.0.0**
5. 릴리스 노트 (한국어):
   ```
   🎉 Luxe Sudoku 첫 출시!
   
   • 3가지 난이도의 무한 퍼즐
   • 힌트 및 실행 취소 기능
   • 타이머 및 리더보드
   • 다크 모드 지원
   ```
6. **검토** 클릭
7. 모든 정보 확인
8. **프로덕션으로 출시** 클릭

## 7단계: 심사 대기

- 심사 기간: 보통 1-3일
- 이메일로 심사 결과 통지
- 승인되면 Play Store에 자동 게시

## 업데이트 배포

### 버전 업데이트
1. `pubspec.yaml`의 버전 업데이트:
   ```yaml
   version: 1.0.1+2  # 1.0.1은 버전명, 2는 빌드 번호
   ```

2. `android/app/build.gradle`:
   ```gradle
   versionCode 2       // 이전보다 1 증가
   versionName "1.0.1"
   ```

3. 빌드 및 업로드:
   ```powershell
   flutter build appbundle --release
   ```

4. Play Console에서 새 릴리스 생성

## 문제 해결

### 빌드 오류
```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

### 서명 오류
- `key.properties` 경로 확인
- 비밀번호 정확한지 확인

### APK 크기 줄이기
```powershell
flutter build appbundle --release --target-platform android-arm,android-arm64,android-x64
```

## 유용한 명령어

```powershell
# 디버그 APK 설치
flutter install

# 연결된 기기 확인
flutter devices

# 기기에서 실행
flutter run --release

# 빌드 크기 분석
flutter build appbundle --release --analyze-size
```

## 체크리스트

- [ ] Apple Developer 계정 생성
- [ ] 키스토어 생성 및 백업
- [ ] 앱 아이콘 준비
- [ ] 스크린샷 준비
- [ ] 스토어 설명 작성
- [ ] AAB 빌드
- [ ] Play Console에 업로드
- [ ] 모든 정보 입력 완료
- [ ] 프로덕션 제출

## 다음 단계

Play Store 배포 후:
1. 앱 링크 공유
2. 사용자 피드백 수집
3. 정기적인 업데이트
4. 버그 수정 및 기능 추가
