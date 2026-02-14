# 🚀 Android 빠른 시작 가이드

## 1단계: 앱 정보 설정 (5분)

### pubspec.yaml 확인
```yaml
name: sudoku_app
description: Luxe Sudoku - 프리미엄 스도쿠 게임
version: 1.0.0+1
```

### android/app/build.gradle 수정
```gradle
android {
    defaultConfig {
        applicationId "com.yourname.sudoku"  // ⚠️ 본인 이름으로 변경!
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

## 2단계: 서명 키 생성 (5분)

```powershell
cd c:\Cusor_game\sudoku_app\android
keytool -genkey -v -keystore sudoku-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sudoku
```

**중요:** 비밀번호를 안전하게 보관하세요!

### key.properties 파일 생성
`android/key.properties` 파일:
```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=sudoku
storeFile=sudoku-release-key.jks
```

### android/app/build.gradle에 서명 설정 추가

파일 상단에 추가:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

`android {` 블록 안에 추가:
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

## 3단계: 빌드 (5분)

```powershell
cd c:\Cusor_game\sudoku_app
flutter clean
flutter pub get
flutter build appbundle --release
```

**결과 파일:** `build\app\outputs\bundle\release\app-release.aab`

## 4단계: Play Console 설정 (30분)

### 개발자 계정
1. https://play.google.com/console
2. $25 결제
3. 개인정보 입력

### 앱 생성
1. "앱 만들기" 클릭
2. 이름: **Luxe Sudoku**
3. 언어: 한국어
4. 무료 선택

### 필수 정보 입력

#### 간단한 설명 (80자)
```
세련된 디자인의 스도쿠 퍼즐 게임. 3가지 난이도로 두뇌를 훈련하세요!
```

#### 전체 설명 (복사해서 사용)
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
9x9 격자를 1부터 9까지의 숫자로 채우세요.

🏆 리더보드
최단 시간 기록에 도전하세요!

지금 다운로드하고 스도쿠의 세계에 빠져보세요! 🧩
```

#### 그래픽 준비
- 앱 아이콘: 512x512 PNG
- 스크린샷: 최소 2장

## 5단계: AAB 업로드 및 제출 (10분)

1. **프로덕션** 탭
2. **새 릴리스 만들기**
3. `app-release.aab` 업로드
4. 릴리스 노트:
   ```
   🎉 Luxe Sudoku 첫 출시!
   
   • 3가지 난이도의 무한 퍼즐
   • 힌트 및 실행 취소 기능
   • 타이머 및 리더보드
   • 다크 모드 지원
   ```
5. **프로덕션으로 출시** 클릭

## 6단계: 심사 대기 (1-3일)

✅ 완료! 이메일로 심사 결과를 받게 됩니다.

---

## 문제 해결

### Java가 없다는 오류
```powershell
# JDK 설치 확인
java -version

# 없다면 설치: https://adoptium.net/
```

### 빌드 오류
```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

### 서명 오류
- key.properties 파일 경로 확인
- 비밀번호가 정확한지 확인

---

## 체크리스트

- [ ] applicationId 변경
- [ ] 키스토어 생성
- [ ] key.properties 작성
- [ ] build.gradle 서명 설정
- [ ] AAB 빌드 성공
- [ ] Play Console 계정 생성
- [ ] 앱 정보 입력
- [ ] 스크린샷 업로드
- [ ] AAB 업로드
- [ ] 심사 제출

---

**예상 소요 시간:** 1-2시간  
**예상 비용:** $25 (일회성)  
**심사 기간:** 1-3일

시작하시겠습니까? 🚀
