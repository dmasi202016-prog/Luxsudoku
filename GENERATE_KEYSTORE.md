# 🔑 키스토어 생성 가이드

## 키스토어 생성 (1회만 실행)

### 새 터미널을 열고 다음 명령 실행:

```powershell
cd c:\Cusor_game\sudoku_app\android
keytool -genkey -v -keystore sudoku-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sudoku
```

### 질문에 답변:

1. **키 저장소 비밀번호 입력**: 강력한 비밀번호 입력 (예: MyStr0ngP@ssw0rd!)
2. **새 비밀번호 다시 입력**: 동일한 비밀번호 재입력
3. **이름과 성을 입력하십시오**: 본인 이름 (예: 홍길동)
4. **조직 단위 이름을 입력하십시오**: Enter 또는 개인/회사명
5. **조직 이름을 입력하십시오**: Enter 또는 개인/회사명
6. **구/군/시 이름을 입력하십시오**: 서울 (또는 본인 도시)
7. **시/도 이름을 입력하십시오**: Enter
8. **이 조직의 두 자리 국가 코드를 입력하십시오**: KR
9. **CN=..., 이(가) 맞습니까?**: yes
10. **<sudoku>에 대한 키 비밀번호를 입력하십시오**: Enter (키 저장소와 동일한 비밀번호 사용)

### 완료!

`android` 폴더에 `sudoku-release-key.jks` 파일이 생성됩니다.

⚠️ **매우 중요**: 
- 이 파일과 비밀번호를 안전하게 보관하세요!
- 분실하면 앱 업데이트를 할 수 없습니다!
- 백업을 여러 곳에 보관하세요!

---

## key.properties 파일 생성

`android/key.properties` 파일을 생성하고 다음 내용 입력:

```properties
storePassword=위에서_입력한_비밀번호
keyPassword=위에서_입력한_비밀번호
keyAlias=sudoku
storeFile=sudoku-release-key.jks
```

### 예시:
```properties
storePassword=MyStr0ngP@ssw0rd!
keyPassword=MyStr0ngP@ssw0rd!
keyAlias=sudoku
storeFile=sudoku-release-key.jks
```

⚠️ **보안 주의사항**:
- `key.properties` 파일은 절대 Git에 커밋하지 마세요!
- `.gitignore`에 추가되어 있는지 확인하세요!

---

## .gitignore 확인

`android/.gitignore` 파일에 다음이 포함되어 있는지 확인:

```
key.properties
*.jks
*.keystore
```

---

## 다음 단계

키스토어 생성 후:

```powershell
# 빌드 테스트
cd c:\Cusor_game\sudoku_app
flutter build appbundle --release

# 성공하면 다음 위치에 파일 생성:
# build\app\outputs\bundle\release\app-release.aab
```

이제 이 AAB 파일을 Google Play Console에 업로드하면 됩니다! 🚀
