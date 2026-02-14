# Luxe Sudoku - Android 배포 정보

## 🎉 최신 빌드 완료!

### 🔧 v1.0.0 업데이트 내용
1. ✅ **Start game 버튼 수정**: 한 번 클릭으로 음악 재생 + 게임 시작
2. ✅ **햅틱 진동 활성화**: VIBRATE 권한 추가로 진동 기능 정상 작동
3. ✅ **광고 보상 최적화**: 광고 시청 시 힌트 1개만 지급
4. ✅ **IAP 설정 문서**: 상세한 In-App Purchase 설정 가이드 추가 (`IAP_SETUP_GUIDE.md`)

## 앱 정보
- **앱 이름**: Luxe Sudoku
- **패키지명**: com.luxesudoku.game
- **버전**: 1.0.0 (Build 1)
- **빌드 날짜**: 2026-02-11 (버그 수정 버전)

## 주요 기능
- ✨ Gold 테마의 럭셔리한 UI
- 🎯 5단계 난이도 (Very Easy, Easy, Medium, Hard, Expert)
- 💾 5개의 게임 저장 슬롯
- ⏱️ 타이머 및 시간 기록
- 💡 힌트 기능 (난이도별 최대 3회)
- ↩️ Undo/Redo 기능 (최대 50개 액션)
- 🏆 난이도별 리더보드 (Top 10)
- ✅ 실시간 에러 검증
- 🎨 다크 모드 지원
- 📱 반응형 디자인 (모바일/태블릿)

## 빌드 파일 위치

### 1. Android App Bundle (Google Play Store용)
```
c:\Cusor_game\sudoku_app\build\app\outputs\bundle\release\app-release.aab
크기: 58.5 MB
```

### 2. APK (직접 설치용)
```
c:\Cusor_game\sudoku_app\build\app\outputs\flutter-apk\app-release.apk
크기: 66.1 MB
```

## Google Play Store 업로드 절차

### 1. Google Play Console 접속
https://play.google.com/console

### 2. 새 앱 만들기
1. "앱 만들기" 클릭
2. 앱 이름: Luxe Sudoku
3. 기본 언어: 한국어
4. 앱 또는 게임: 게임
5. 무료 또는 유료: 무료

### 3. 앱 정보 입력

#### 스토어 등록정보
- **앱 이름**: Luxe Sudoku
- **간단한 설명**: 
  ```
  Gold 테마의 럭셔리한 스도쿠 게임. 5단계 난이도, 힌트, 리더보드 지원.
  ```
- **전체 설명**:
  ```
  ✨ Luxe Sudoku - 프리미엄 스도쿠 경험

  Gold 테마의 럭셔리한 디자인으로 스도쿠를 즐기세요!
  
  🎮 주요 기능:
  • 5단계 난이도 (Very Easy ~ Expert)
  • 게임 저장/불러오기 (5개 슬롯)
  • 타이머 및 기록 관리
  • 힌트 시스템
  • Undo/Redo 기능
  • 리더보드 (난이도별 Top 10)
  • 실시간 에러 검증
  • 다크 모드 지원
  
  🌟 특징:
  • 깔끔하고 우아한 Gold 테마 UI
  • 부드러운 애니메이션
  • 직관적인 조작
  • 오프라인 플레이 가능
  
  초보자부터 전문가까지 모두 즐길 수 있는 스도쿠 게임입니다!
  ```

#### 스크린샷
- 최소 2개, 최대 8개 필요
- 권장 크기: 1080x1920 픽셀
- 게임 화면, 메뉴, 리더보드 등 캡처

#### 앱 아이콘
- 크기: 512x512 픽셀
- PNG 형식
- 투명 배경 권장

#### 기능 그래픽
- 크기: 1024x500 픽셀
- 스토어 상단에 표시될 이미지

### 4. 앱 콘텐츠 입력
- **카테고리**: 게임 > 퍼즐
- **콘텐츠 등급**: 만 3세 이상
- **개인정보처리방침 URL**: (선택사항)

### 5. AAB 파일 업로드
1. "프로덕션" 트랙 선택
2. "새 릴리스 만들기" 클릭
3. `app-release.aab` 파일 업로드
4. 릴리스 노트 작성:
   ```
   초기 릴리스 (v1.0.0)
   - Gold 테마 스도쿠 게임 출시
   - 5단계 난이도 제공
   - 힌트, 저장/불러오기, 리더보드 기능
   ```
5. "검토" → "프로덕션으로 출시"

### 6. 검토 대기
- Google의 검토 과정: 보통 1~3일 소요
- 승인되면 Play Store에 게시됨

## 직접 설치 (테스트용)

### APK 설치 방법
1. APK 파일을 Android 기기로 전송
2. 기기의 "설정" → "보안" → "알 수 없는 출처" 허용
3. APK 파일 실행하여 설치

### ADB를 통한 설치
```powershell
adb install c:\Cusor_game\sudoku_app\build\app\outputs\flutter-apk\app-release.apk
```

## 앱 서명 키 관리

### 키스토어 파일 위치
```
c:\Cusor_game\sudoku_app\android\sudoku-release-key.jks
```

⚠️ **매우 중요**: 
- 키스토어 파일과 비밀번호를 안전하게 보관하세요
- 분실 시 앱 업데이트 불가능
- 백업 권장 위치:
  - 외장 하드
  - 클라우드 스토리지 (암호화)
  - USB 드라이브

### 키 정보
- 키스토어 파일: `sudoku-release-key.jks`
- 별칭(alias): `sudoku`
- 유효기간: 10000일 (약 27년)

## 업데이트 배포

### 버전 업데이트
1. `pubspec.yaml`에서 버전 변경:
   ```yaml
   version: 1.0.1+2  # 버전명+빌드번호
   ```

2. 변경사항 적용 후 빌드:
   ```powershell
   cd c:\Cusor_game\sudoku_app
   flutter clean
   flutter build appbundle --release
   ```

3. 새 AAB를 Play Console에 업로드

## 성능 최적화

### 현재 빌드 크기
- AAB: 58.5 MB (다운로드 크기는 더 작음)
- APK: 66.1 MB

### 최적화 팁
- 사용하지 않는 에셋 제거
- 이미지 압축
- ProGuard/R8 활성화 (이미 적용됨)
- Tree-shaking (이미 적용됨)

## 문의 및 지원
- 버그 리포트: GitHub Issues
- 피드백: Play Store 리뷰

---

**배포 완료!** 🎉

이제 Google Play Store에 앱을 업로드하거나, APK를 직접 설치하여 테스트할 수 있습니다.
