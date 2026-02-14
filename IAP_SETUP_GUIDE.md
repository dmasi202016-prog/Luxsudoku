# In-App Purchase (IAP) 설정 가이드

## 개요

Luxe Sudoku 앱의 Premium Unlock과 힌트 구매 기능은 Google Play의 In-App Purchase (IAP) 시스템을 사용합니다.
**개발 및 테스트 환경에서는 IAP가 작동하지 않으며**, Google Play Console에 앱을 업로드하고 상품을 등록한 후에만 정상적으로 작동합니다.

## 왜 지금 작동하지 않나요?

현재 앱에서 Premium Unlock이나 힌트 구매 버튼을 눌러도 반응이 없는 이유:

1. **Google Play에 앱이 등록되지 않음**: IAP는 Google Play Console에 등록된 앱에서만 작동합니다.
2. **상품(Product)이 등록되지 않음**: 판매할 상품이 Google Play Console에 등록되어 있지 않습니다.
3. **Release 버전이 업로드되지 않음**: 최소 Internal Testing 트랙에 APK/AAB가 업로드되어야 합니다.

## IAP 설정 단계

### 1. Google Play Console에 앱 업로드

먼저 `app-release.aab` 파일을 Google Play Console의 **Internal Testing** 트랙에 업로드합니다.

```
위치: sudoku_app/build/app/outputs/bundle/release/app-release.aab
```

### 2. In-App Products 등록

Google Play Console > 앱 > 수익 창출 > In-app products로 이동하여 다음 상품들을 등록합니다:

#### Premium Unlock (Non-consumable)

- **Product ID**: `premium_unlock`
- **Name**: Premium Unlock
- **Description**: Remove all ads and get unlimited hints
- **Price**: $3.99 USD (또는 원하는 가격)
- **Status**: Active

#### Hint Packs (Consumable)

1. **5 Hints Pack**
   - Product ID: `hints_5`
   - Name: 5 Hints
   - Description: Get 5 hints to help solve puzzles
   - Price: $0.99 USD
   - Status: Active

2. **20 Hints Pack** (Best Value)
   - Product ID: `hints_20`
   - Name: 20 Hints
   - Description: Get 20 hints (Best Value!)
   - Price: $2.99 USD
   - Status: Active

3. **50 Hints Pack**
   - Product ID: `hints_50`
   - Name: 50 Hints
   - Description: Get 50 hints for unlimited puzzle solving
   - Price: $4.99 USD
   - Status: Active

### 3. License Testers 설정 (테스트용)

실제 돈을 지불하지 않고 IAP를 테스트하려면:

1. Google Play Console > 설정 > License Testing로 이동
2. 테스트 계정(Gmail)을 추가
3. License Response를 "RESPOND_NORMALLY"로 설정
4. 해당 Gmail 계정으로 Android 기기에 로그인
5. Internal Testing 트랙에서 앱 다운로드
6. IAP 테스트 (실제 결제되지 않음)

### 4. Internal Testing 트랙 설정

1. Google Play Console > 테스트 > Internal testing
2. 새 릴리스 만들기
3. `app-release.aab` 업로드
4. 릴리스 노트 작성
5. 검토 후 게시
6. 테스터 이메일 추가
7. 테스터에게 opt-in URL 공유

## 테스트 방법

### Internal Testing으로 IAP 테스트

1. **테스터 계정 설정**
   - Google Play Console에서 License Testing에 테스터 Gmail 추가
   - Internal Testing 트랙에 테스터 추가

2. **앱 설치**
   - 테스터는 opt-in URL을 통해 앱 다운로드
   - 또는 Play Store에서 "Luxe Sudoku" 검색 후 설치

3. **IAP 테스트**
   - Shop 화면에서 Premium Unlock 또는 힌트 구매 시도
   - Google Play 결제 창이 표시됨
   - License Tester로 등록된 계정은 "Test purchase" 표시와 함께 무료로 구매 가능
   - 실제 결제는 발생하지 않음

4. **확인 사항**
   - Premium unlock 후 광고가 제거되는지 확인
   - 힌트 구매 후 힌트 개수가 증가하는지 확인
   - 앱 재시작 후에도 구매 내역이 유지되는지 확인

## Production 배포 시 주의사항

### 1. Product Status 확인
모든 IAP 상품이 **Active** 상태인지 확인

### 2. 가격 설정
- 국가별 가격이 올바르게 설정되었는지 확인
- Google Play가 자동으로 환율을 적용하지만, 주요 시장은 수동 조정 권장

### 3. 상품 설명
- 각 언어별로 명확하고 매력적인 설명 작성
- 한국어 번역 추가 권장

### 4. Subscription vs Consumable
- Premium Unlock: **Non-consumable** (한 번 구매하면 영구 소유)
- Hint Packs: **Consumable** (여러 번 구매 가능)

## 코드 위치

IAP 관련 코드는 다음 위치에 있습니다:

```
lib/core/services/iap_service.dart          # IAP 서비스 구현
lib/core/constants/monetization_constants.dart  # Product IDs와 가격
lib/features/shop/presentation/shop_screen.dart # Shop UI
lib/core/providers/monetization_providers.dart  # Premium 및 힌트 상태 관리
```

### Product IDs (변경 금지)

```dart
// lib/core/constants/monetization_constants.dart
static const String premiumUnlockId = 'premium_unlock';
static const String hints5PackId = 'hints_5';
static const String hints20PackId = 'hints_20';
static const String hints50PackId = 'hints_50';
```

**중요**: 이 Product ID들은 Google Play Console에 등록한 ID와 정확히 일치해야 합니다.

## 문제 해결

### IAP가 초기화되지 않음

**증상**: Shop 화면에서 "In-app purchases are not available" 메시지

**원인**:
- 앱이 Google Play에서 다운로드되지 않음 (사이드로드)
- Google Play Services가 설치되지 않음
- 앱이 Internal Testing 이상에 업로드되지 않음

**해결**:
- Google Play Console의 Internal Testing 트랙에 앱 업로드
- Play Store를 통해 앱 설치
- Google Play Services 업데이트

### 상품이 로드되지 않음

**증상**: Shop 화면에서 상품 목록이 표시되지 않음

**원인**:
- Product ID 불일치
- Google Play Console에 상품이 등록되지 않음
- 상품이 Active 상태가 아님

**해결**:
- Google Play Console에서 모든 상품이 Active 상태인지 확인
- Product ID가 코드와 일치하는지 확인
- 앱 버전 코드가 Play Console에 업로드된 버전과 일치하는지 확인

### 구매가 완료되지 않음

**증상**: 결제 창이 나타나지만 구매가 완료되지 않음

**원인**:
- 네트워크 문제
- Google Play 서비스 오류
- 결제 방법 문제

**해결**:
- 인터넷 연결 확인
- Google Play 캐시 삭제
- 결제 방법 확인/추가

## 웹 버전 (Web) 제한사항

IAP는 **모바일 앱에서만 작동**합니다. 웹 버전에서는:
- IAP 버튼이 비활성화됨
- "Not available on web" 메시지 표시
- 광고 시청 기능도 제한됨

## 추가 리소스

- [Google Play Billing 공식 문서](https://developer.android.com/google/play/billing)
- [Flutter in_app_purchase 패키지](https://pub.dev/packages/in_app_purchase)
- [Google Play Console](https://play.google.com/console)

## 요약

✅ **현재 상태**: IAP가 작동하지 않는 것은 정상입니다. Google Play에 앱을 업로드하기 전이기 때문입니다.

✅ **다음 단계**: 
1. Google Play Console에 앱 등록
2. Internal Testing 트랙에 AAB 업로드
3. In-app products 등록
4. License Testers 설정
5. 테스트 후 Production 배포

✅ **예상 일정**: Google Play Console 설정 후 1-2일 내에 IAP 테스트 가능

---

**질문이나 문제가 있으시면 Google Play Console의 지원 센터를 참고하거나, Flutter의 in_app_purchase 패키지 문서를 확인하세요.**
