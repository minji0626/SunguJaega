# 홈페이지 수정 방법

이 사이트는 GitHub Pages로 배포되는 정적 HTML 사이트입니다.
루트의 `*.html` 파일은 **직접 고치지 말고**, `_build` 폴더의 원본을 고친 뒤 빌드합니다.

## 폴더 구성
| 경로 | 내용 |
|---|---|
| `_build/site.json` | 센터 이름·전화·팩스·주소·이메일·상담시간 (여기만 고치면 전 페이지 반영) |
| `_build/template.html` | 모든 페이지 공통 머리글·바닥글·메타 태그 |
| `_build/partials/contact-band.html` | 페이지 하단 연락처 띠 |
| `_build/pages/*.html` | 페이지별 본문 (맨 위 `title`, `description` 등은 검색 결과에 표시되는 문구) |
| `assets/style.css`, `assets/main.js` | 디자인과 동작 |
| `images/` | 사진 (`care-visit-*.jpg`: 첫 화면, `og-image.jpg`: 카카오톡 공유 미리보기) |

`_`로 시작하는 폴더는 GitHub Pages가 공개하지 않습니다.

## 수정 후 빌드
저장소 루트에서 실행합니다.

```powershell
powershell -ExecutionPolicy Bypass -File _build\build.ps1
```

생성된 루트의 HTML 파일까지 함께 커밋·푸시하면 반영됩니다.

## 사진 교체 시 주의
- 가로 1600px 이하, JPG(품질 75~80) 기준 200KB 이하를 권장합니다.
- 휴대폰 원본 사진이나 PNG를 그대로 올리면 페이지가 매우 느려집니다.

## 지도
- `location.html`은 네이버 지도 API(NCP)로 주소를 좌표로 바꿔 표시합니다.
- NCP 콘솔에서 해당 Application의 **Web 서비스 URL에 `https://sungujaega.com`이 등록**되어 있어야 하고,
  **Geocoding API**가 사용 설정되어 있어야 지도가 나옵니다. 둘 중 하나라도 빠지면 안내 문구와 지도 앱 버튼만 표시됩니다.
- 좌표를 직접 지정하려면 `_build/pages/location.html`의 `#naverMap`에 `data-lat`, `data-lng`를 추가하세요.
