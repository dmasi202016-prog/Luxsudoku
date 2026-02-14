# 스도쿠 웹 앱 배포 가이드

## 1. Firebase Hosting (추천)

### 설치
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
```

### 설정
`firebase.json`:
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### 배포
```bash
flutter build web --release
firebase deploy --only hosting
```

## 2. GitHub Pages

### 설정
1. GitHub 저장소 생성
2. `build/web` 폴더 내용을 `gh-pages` 브랜치에 푸시

```bash
cd build/web
git init
git add .
git commit -m "Deploy to GitHub Pages"
git branch -M gh-pages
git remote add origin <your-repo-url>
git push -u origin gh-pages
```

### base href 수정
GitHub Pages에서는 서브 경로를 사용하므로:
```bash
flutter build web --release --base-href="/repository-name/"
```

## 3. Netlify

### 방법 1: 드래그 앤 드롭
1. https://app.netlify.com/ 접속
2. "Sites" 섹션으로 이동
3. `build/web` 폴더를 드래그 앤 드롭

### 방법 2: Netlify CLI
```bash
npm install -g netlify-cli
flutter build web --release
cd build/web
netlify deploy --prod
```

### netlify.toml 설정
```toml
[build]
  publish = "build/web"
  command = "flutter build web --release"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

## 4. Vercel

```bash
npm install -g vercel
flutter build web --release
cd build/web
vercel --prod
```

## 5. 일반 웹 서버 (Apache/Nginx)

### Nginx 설정
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    root /path/to/sudoku_app/build/web;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
        
        # MIME types
        types {
            application/javascript js mjs;
            application/wasm wasm;
        }
        
        # Caching
        location ~* \.(jpg|jpeg|png|gif|ico|css|js|wasm)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

### Apache 설정
`.htaccess`:
```apache
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /
    RewriteRule ^index\.html$ - [L]
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /index.html [L]
</IfModule>

<IfModule mod_mime.c>
    AddType application/javascript .js .mjs
    AddType application/wasm .wasm
</IfModule>

<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType application/wasm "access plus 1 year"
</IfModule>
```

## 6. 로컬 테스트용 올바른 서버

Python으로 로컬 테스트 시:

### 방법 1: http.server with custom MIME types
```python
# serve.py
import http.server
import socketserver

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        super().end_headers()
    
    extensions_map = {
        '.manifest': 'text/cache-manifest',
        '.html': 'text/html',
        '.png': 'image/png',
        '.jpg': 'image/jpg',
        '.svg': 'image/svg+xml',
        '.css': 'text/css',
        '.js': 'application/javascript',
        '.mjs': 'application/javascript',
        '.wasm': 'application/wasm',
        '.json': 'application/json',
        '.xml': 'application/xml',
    }

PORT = 8000
Handler = MyHTTPRequestHandler

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Server running at http://localhost:{PORT}")
    httpd.serve_forever()
```

실행:
```bash
cd build/web
python serve.py
```

### 방법 2: Flutter 개발 서버 (가장 쉬움)
```bash
flutter run -d web-server --web-port=8080
```

### 방법 3: Node.js http-server
```bash
npm install -g http-server
cd build/web
http-server -p 8000 -c-1
```

## 주의사항

1. **HTTPS 필요**: Service Worker는 HTTPS에서만 작동 (localhost 제외)
2. **CORS 설정**: API를 사용한다면 CORS 헤더 설정 필요
3. **캐싱 전략**: 정적 자산은 적극적으로 캐싱, index.html은 캐싱 안 함
4. **압축**: gzip 또는 brotli 압축 활성화 권장

## 빌드 최적화

```bash
# 릴리즈 빌드 (최적화됨)
flutter build web --release

# WASM 지원 (실험적)
flutter build web --release --wasm

# 특정 렌더러 지정
flutter build web --release --web-renderer canvaskit
flutter build web --release --web-renderer html
```

## 문제 해결

### 하얀 화면
- 브라우저 캐시 지우기
- base href 확인
- 개발자 도구 콘솔에서 에러 확인

### Service Worker 문제
- HTTPS 사용 확인
- 캐시 지우기
- 시크릿 모드에서 테스트

### 느린 로딩
- `--web-renderer html` 사용 고려 (CanvasKit보다 가벼움)
- CDN 사용
- 이미지 최적화
