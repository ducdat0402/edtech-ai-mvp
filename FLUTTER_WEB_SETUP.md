# Hướng dẫn Flutter Web – Giao diện như app

Trang web chạy từ cùng codebase Flutter, dùng API backend hiện có.

---

## Bước 1: Chuẩn bị môi trường

- Đã cài **Flutter SDK** và chạy được `flutter doctor`.
- Backend đang chạy (Render): `https://edtech-ai-backend-tbq7.onrender.com/api/v1`.

Kiểm tra Flutter có bật web:

```bash
flutter config --enable-web
flutter doctor
```

---

## Bước 2: Cấu hình API cho web

File `mobile/lib/core/config/api_config.dart` đang trỏ production:

```dart
static const String baseUrl =
  'https://edtech-ai-backend-tbq7.onrender.com/api/v1';
```

Web sẽ dùng luôn URL này, **không cần sửa** nếu backend đã deploy đúng.

---

## Bước 3: CORS trên Backend (Render)

Backend đang dùng: `origin: process.env.CORS_ORIGIN || '*'` → mặc định cho phép mọi domain.

- **Nếu để `*`:** Web (Vercel/Netlify/…) gọi API được, không cần làm gì.
- **Nếu muốn giới hạn domain (khuyến nghị khi lên production):**

Trên **Render** → Service backend → **Environment** → thêm:

- **Key:** `CORS_ORIGIN`
- **Value:** URL trang web của bạn, ví dụ:
  - `https://edtech-mobile.vercel.app`
  - hoặc nhiều domain: `https://edtech-mobile.vercel.app,https://yourdomain.com`

Sau đó **Save** và đợi redeploy.

---

## Bước 4: Build Flutter Web

Mở terminal tại thư mục **mobile**:

```bash
cd mobile
flutter pub get
flutter build web
```

Build xong sẽ có thư mục:

```
mobile/build/web/
```

Trong đó có: `index.html`, `main.dart.js`, `flutter.js`, `assets/`, v.v.

**Lưu ý:** Lần đầu build có thể mất vài phút. Nếu có lỗi (ví dụ package không support web), báo lỗi cụ thể để xử lý.

---

## Bước 5: Chạy thử trên máy (tùy chọn)

```bash
cd mobile
flutter run -d chrome
```

Mở app trên Chrome để test trước khi deploy.

---

## Bước 6: Deploy lên hosting

Chọn **một** trong các cách dưới đây. **Render có hỗ trợ** (Static Site) — không bắt buộc dùng Vercel.

### Cách A: Render (Static Site) – cùng dashboard với backend

Nếu bạn đã dùng Render cho backend, có thể host luôn Flutter Web trên Render.

1. Vào [dashboard.render.com](https://dashboard.render.com) → **New** → **Static Site**.
2. **Connect repository** (GitHub repo `edtech-ai-mvp`).
3. Cấu hình:
   - **Name:** `edtech-web` (tùy chọn).
   - **Build Command:**  
     `cd mobile && flutter pub get && flutter build web`  
     (Render không cài sẵn Flutter nên build thường **không chạy được** trên Render. Xem bước 4.)
   - **Publish Directory:** `mobile/build/web`.

4. **Cách đơn giản (khuyến nghị):** Build trên máy rồi deploy thư mục tĩnh:
   - Trên máy: `cd mobile && flutter build web`.
   - Trên Render: tạo **Static Site** → chọn **Deploy from Git** nhưng **Build Command** để trống hoặc `echo "No build"`, **Publish Directory** để `mobile/build/web` — **hoặc** dùng **Manual Deploy**: sau khi build xong, zip thư mục `mobile/build/web`, vào Render Static Site → **Manual Deploy** → upload file zip.

   Thực tế Render Static Site với Git thường cần build trên máy vì môi trường không có Flutter. Cách chắc chắn:
   - **Build trên máy:** `cd mobile && flutter build web`.
   - Tạo repo hoặc branch chỉ chứa nội dung `build/web`, rồi connect Static Site tới repo đó, Publish Directory = `.`  
   **Hoặc** dùng **Vercel/Netlify** (có sẵn Flutter hoặc drag & drop dễ hơn).

5. Sau khi deploy xong, Render cho link dạng `https://edtech-web.onrender.com`.
6. Trên **backend** (Render): vào Environment → thêm hoặc sửa **CORS_ORIGIN** = `https://edtech-web.onrender.com` (đúng URL static site của bạn).

**Lưu ý:** Render Static Site **không** chạy lệnh Flutter (không có Flutter SDK). Nên bạn cần **build trên máy** (`flutter build web`), rồi:
- **Cách 1:** Đẩy nội dung `build/web` lên một branch/repo riêng và connect Static Site tới đó, Publish Directory = root.
- **Cách 2:** Dùng Vercel/Netlify (kéo thả `build/web` hoặc build trên máy rồi drag & drop).

---

### Cách B: Vercel – trình tự chi tiết

Vercel **không** cài sẵn Flutter, nên cách ổn định nhất: **build trên máy** rồi **kéo thả** thư mục lên Vercel.

---

#### Bước 1: Build Flutter Web trên máy

Mở terminal (PowerShell hoặc CMD) tại thư mục dự án:

```bash
cd d:\work\edtech-ai-mvp\mobile
flutter pub get
flutter build web
```

Đợi đến khi có dòng `Built build/web` (hoặc thấy thư mục **`build/web`** xuất hiện trong `mobile`).

Kiểm tra: vào thư mục `d:\work\edtech-ai-mvp\mobile\build\web` — phải có file `index.html`, `main.dart.js`, `flutter.js`, thư mục `assets`, v.v.

---

#### Bước 2: Đăng nhập Vercel

1. Mở trình duyệt, vào **https://vercel.com**
2. Chọn **Sign Up** hoặc **Log In**
3. Đăng nhập bằng **GitHub** (nên dùng GitHub để sau này có thể deploy từ repo nếu cần)

---

#### Bước 3: Deploy lên Vercel (dùng Vercel CLI – không cần kéo thả)

Trên giao diện Vercel **không còn** mục kéo thả thư mục; chỉ có Import từ Git. Cách đơn giản nhất là dùng **Vercel CLI** để deploy thư mục `build/web` từ máy bạn.

**3.1 – Cài Vercel CLI (chỉ làm một lần)**

Mở terminal (PowerShell hoặc CMD):

```bash
npm install -g vercel
```

**3.2 – Đăng nhập Vercel**

```bash
vercel login
```

Làm theo hướng dẫn (mở link trong trình duyệt, xác nhận email).

**3.3 – Deploy thư mục `build/web`**

```bash
cd d:\work\edtech-ai-mvp\mobile\build\web
vercel
```

- Lần đầu: hỏi **Set up and deploy?** → gõ **Y**.
- **Which scope?** → chọn tài khoản của bạn (Enter).
- **Link to existing project?** → **N** (tạo project mới).
- **Project name?** → Enter (dùng tên mặc định) hoặc gõ tên ví dụ `edtech-web`.
- **In which directory is your code located?** → Enter (đang ở trong `build/web` rồi).

Sau vài giây sẽ có link dạng **https://edtech-web-xxx.vercel.app**.

---

#### Bước 4: Lấy link production (lần đầu có thể chỉ là Preview)

- Lần chạy `vercel` đầu thường tạo **Preview**. Để deploy lên **production** (link chính), chạy thêm:

```bash
cd d:\work\edtech-ai-mvp\mobile\build\web
vercel --prod
```

- Terminal sẽ in link dạng **https://edtech-web-xxx.vercel.app**. Mở link đó trong trình duyệt.

---

#### Bước 5: Cấu hình CORS trên Render (backend)

Để trang Vercel gọi được API backend trên Render:

1. Vào **https://dashboard.render.com** → chọn **service backend** (EdTech API).
2. Tab **Environment** → tìm biến **CORS_ORIGIN**.
3. Sửa (hoặc thêm) **CORS_ORIGIN** = đúng URL trang Vercel, ví dụ:  
   `https://edtech-mobile-xxxx.vercel.app`  
   (không dấu `/` ở cuối, đúng tên project Vercel đã tạo).
4. **Save Changes** → Render sẽ tự redeploy backend. Đợi vài phút.

Sau đó mở lại trang Vercel và thử **Đăng nhập** — sẽ gọi API bình thường.

---

#### Lần sau muốn cập nhật web (deploy lại)

1. Sửa code Flutter rồi build lại:
   ```bash
   cd d:\work\edtech-ai-mvp\mobile
   flutter build web
   ```
2. Deploy lại bằng CLI:
   ```bash
   cd d:\work\edtech-ai-mvp\mobile\build\web
   vercel --prod
   ```
   Vercel sẽ dùng đúng project đã tạo lần trước và cập nhật link production.

---

### Cách C: Netlify

1. Đăng nhập [netlify.com](https://netlify.com).
2. **Add new site** → **Deploy manually**.
3. Kéo thả thư mục **`mobile/build/web`** vào vùng **Drag and drop** (sau khi đã chạy `flutter build web`).
4. Netlify sẽ cho link dạng `https://random-name.netlify.app`.

**Build trên Netlify (tùy chọn):**

- Root: `mobile`
- Build command: `flutter build web`
- Publish directory: `mobile/build/web`  
(Lưu ý: Netlify mặc định không có Flutter SDK, nên build trên máy rồi drag & drop thường đơn giản hơn.)

---

### Cách D: Firebase Hosting

1. Cài Firebase CLI: `npm install -g firebase-tools`
2. Đăng nhập: `firebase login`
3. Trong repo (thư mục gốc `edtech-ai-mvp`):

```bash
firebase init hosting
```

- Chọn **Create a new project** hoặc project có sẵn.
- **Public directory:** gõ `mobile/build/web`
- **Single-page app:** Yes
- **Overwrite index.html:** No (trừ khi bạn muốn thay)

4. Mỗi lần deploy:

```bash
cd mobile
flutter build web
cd ..
firebase deploy
```

5. Link dạng: `https://your-project.web.app`

---

## Bước 7: Kiểm tra sau khi deploy

1. Mở link web (Vercel/Netlify/Firebase).
2. Đăng ký / Đăng nhập → phải gọi được API (backend Render).
3. Nếu lỗi CORS: kiểm tra lại **Bước 3** (CORS_ORIGIN trên Render) và bật đúng domain.

---

## Tóm tắt lệnh nhanh (build + deploy thủ công)

```bash
# Trong repo
cd mobile
flutter pub get
flutter build web
# Sau đó: upload thư mục mobile/build/web lên Vercel (kéo thả) hoặc Netlify / Firebase
```

---

## Xử lý lỗi thường gặp

| Lỗi | Cách xử lý |
|-----|------------|
| CORS / blocked by CORS | Đặt `CORS_ORIGIN` trên Render = đúng URL web (hoặc tạm để `*`). |
| Trang trắng | Mở Console (F12) xem lỗi; thường do base href. Build với: `flutter build web --base-href "/"` (hoặc base-href đúng với path deploy). |
| 404 khi refresh trang | Hosting cần cấu redirect mọi path về `index.html` (Vercel/Netlify thường tự làm với SPA). |
| Package không support web | Trong code dùng `kIsWeb` (Flutter) để ẩn tính năng chỉ dùng mobile (camera, một số plugin). |

Nếu bạn chọn xong hosting (Vercel / Netlify / Firebase), có thể làm đúng từng bước trong file này để có web giao diện như app.
