# Hướng dẫn chạy và đóng góp cho Be A Chef

Tài liệu này dành cho người mới, bắt đầu từ **một máy Windows chưa cài gì**. Làm lần lượt từ trên xuống.

## 1. Phiên bản nhóm đang dùng

Lấy từ `flutter --version` và `flutter doctor -v` trên máy build chính:

| Thành phần | Phiên bản |
|---|---|
| Flutter | **3.47.4** (channel stable, revision `9584c6713b`) |
| Dart | **3.13.3** (pubspec yêu cầu `sdk: ^3.13.3`) |
| Android SDK Platform | **android-37** (bắt buộc, vì `compileSdk = 37`) và android-36 |
| Android SDK Build-Tools | **36.0.0** |
| Android NDK | **28.2.13676358** (mặc định của Flutter 3.47, Gradle tự tải nếu thiếu) |
| Gradle | 9.3.1 (wrapper tự tải) |
| Android Gradle Plugin (AGP) | 9.1.0 |
| Kotlin Gradle Plugin | 2.4.0 |
| JDK | JDK đi kèm Android Studio (JBR, OpenJDK 25) |
| `minSdk` / `compileSdk` | 26 / 37 |

Nên dùng **đúng Flutter 3.47.x**. Bản khác vẫn có thể chạy, nhưng dễ lệch AGP/Gradle (xem mục 8).

## 2. Những thứ KHÔNG có trong repo và cách tự tải

| Thứ cần có | Vì sao không có trong repo | Cách lấy |
|---|---|---|
| Flutter SDK | Công cụ cài trên máy | Tải zip tại <https://docs.flutter.dev/get-started/install/windows>, giải nén ra thư mục **không dấu, không khoảng trắng** (vd. `D:\flutter`), thêm `D:\flutter\bin` vào biến môi trường `Path` |
| Android Studio + Android SDK + JDK | Công cụ cài trên máy | <https://developer.android.com/studio>, xem mục 3 |
| Git | Công cụ cài trên máy | <https://git-scm.com/download/win> |
| Package Dart (`camera`, `tflite_flutter`, …) | Nằm trong pub cache | `flutter pub get` |
| `android/local.properties` | Chứa đường dẫn riêng từng máy, bị `.gitignore` | Tự sinh khi chạy `flutter pub get` hoặc mở project trong Android Studio |
| Gradle wrapper jar, `gradlew`, `gradlew.bat` | Bị `android/.gitignore` | Tự sinh khi build lần đầu (`flutter run` / `flutter build apk`) |
| Gradle, AGP, thư viện Android, NDK | Tải qua mạng | Tự tải lần build đầu (cần mạng, vài GB, 5–15 phút) |
| Thư mục `build/`, `.dart_tool/` | File sinh ra khi build | Tự sinh |
| File APK | Không commit file build | Tự build (mục 6) hoặc tải ở trang Releases |
| Keystore ký bản release (`*.jks`, `key.properties`) | Bí mật, **không bao giờ commit** | Hỏi trưởng nhóm. Nếu không có, bản release đang ký bằng debug key |

Model `assets/models/mobilefacenet.tflite` (~5 MB) và `assets/data/lessons.json` **có sẵn trong repo**, không cần tải thêm.

## 3. Cài Android Studio

1. Cài **Android Studio** bản mới nhất, chọn cài kèm *Android SDK* và *Android Virtual Device*.
2. Mở Android Studio → **Plugins** → Marketplace → cài **Flutter** (plugin **Dart** sẽ được cài kèm) → Restart.
3. **Settings → Languages & Frameworks → Android SDK**:
   - Tab **SDK Platforms**: tick **Android API 37** (và API 36).
   - Tab **SDK Tools** (bật *Show Package Details*):
     - **Android SDK Build-Tools** → `36.0.0`
     - **Android SDK Command-line Tools (latest)** (bắt buộc để `flutter doctor` accept license)
     - **Android SDK Platform-Tools**
     - **Android Emulator**
     - (tùy chọn) **NDK (Side by side)** → `28.2.13676358`
   - Bấm **Apply** và chờ tải xong.
4. **JDK**: dùng bản đi kèm Android Studio (thư mục `jbr`), không cần cài JDK riêng.
   Kiểm tra ở **Settings → Build, Execution, Deployment → Build Tools → Gradle → Gradle JDK** = *jbr* / *Embedded JDK*.
   Nếu Flutter dùng nhầm JDK khác: `flutter config --jdk-dir "<thư mục Android Studio>\jbr"`.

## 4. Kiểm tra bằng `flutter doctor`

```bash
flutter doctor --android-licenses
```

Gõ `y` cho tất cả câu hỏi. Sau đó:

```bash
flutter doctor -v
```

Cần thấy dấu `[√]` ở **Flutter** và **Android toolchain** (có dòng *All Android licenses accepted*).
Dấu `[!]` ở *Visual Studio* chỉ ảnh hưởng tới việc build app Windows, bỏ qua được.

## 5. Chuẩn bị điện thoại thật (nên dùng)

App cần camera trước để nhận diện, nên **chạy trên máy thật sẽ chuẩn hơn máy ảo**.

1. **Cài đặt → Giới thiệu điện thoại** → bấm **Số hiệu bản tạo (Build number)** 7 lần để bật **Tùy chọn nhà phát triển**.
2. Vào **Tùy chọn nhà phát triển** → bật **Gỡ lỗi USB (USB debugging)**.
3. Cắm cáp USB (loại truyền dữ liệu, không phải cáp chỉ sạc) → trên điện thoại chọn **Cho phép gỡ lỗi USB** (tick "Luôn cho phép").
4. Kiểm tra: `flutter devices` phải hiện tên điện thoại.

> **Xiaomi / Redmi / POCO (MIUI, HyperOS)**: vào **Cài đặt → Giới thiệu điện thoại → Phiên bản MIUI/HyperOS**,
> bấm 7 lần để bật chế độ nhà phát triển. Trong **Cài đặt bổ sung → Tùy chọn nhà phát triển**, bật thêm:
> - **Cài đặt qua USB (Install via USB)**: nếu không bật, cài app sẽ lỗi `INSTALL_FAILED_USER_RESTRICTED`.
> - **Gỡ lỗi USB (Cài đặt bảo mật) / USB debugging (Security settings)**: cần để cấp quyền và thao tác từ máy tính.
>
> Hai mục này đòi **đăng nhập tài khoản Mi** và **lắp SIM**. Khi cài app lần đầu, điện thoại hiện hộp thoại
> xác nhận trong vài giây, phải bấm **Cài đặt** kịp.

**Máy ảo (emulator)**: **Device Manager** → *Create Virtual Device* → chọn Pixel bất kỳ → system image **API 26 trở lên**
(nên dùng API 34+) → **Show Advanced Settings** → **Front camera: `Webcam0`** (dùng webcam laptop) hoặc `Emulated`.

## 6. Clone và chạy

```bash
git clone <URL repo>
```

```bash
cd Nau_An_VIP
```

```bash
flutter pub get
```

Trong Android Studio: **File → Open** → chọn **thư mục gốc của project** (thư mục chứa `pubspec.yaml`),
**không** chọn thư mục `android/`. Đợi Android Studio index xong, chọn thiết bị ở ô **device selector** trên toolbar
→ bấm **Run ▶** (`main.dart`).

Hoặc chạy bằng dòng lệnh:

```bash
flutter run
```

Build APK release:

```bash
flutter build apk --release
```

File ra ở `build/app/outputs/flutter-apk/app-release.apk`.

## 7. Ổ C đầy: chuyển cache sang ổ khác

Pub cache và Gradle cache có thể chiếm nhiều GB. Đặt **biến môi trường người dùng** (Start → gõ *environment variables*
→ *Edit environment variables for your account* → **New**):

| Biến | Ví dụ giá trị | Chứa gì |
|---|---|---|
| `PUB_CACHE` | `D:\dev-cache\pub` | Package Dart/Flutter |
| `GRADLE_USER_HOME` | `D:\dev-cache\gradle` | Gradle wrapper, thư viện Android |

Sau khi đặt: **đóng hẳn** Android Studio và mọi cửa sổ terminal rồi mở lại, chạy `flutter pub get`.
Cache cũ ở `%LOCALAPPDATA%\Pub\Cache` và `%USERPROFILE%\.gradle` có thể xóa bằng tay để lấy lại dung lượng.
Android SDK cũng có thể đặt ở ổ khác ngay lúc cài (vd. `D:\dev\android-sdk`), rồi chạy
`flutter config --android-sdk D:\dev\android-sdk`.

## 8. Lỗi thường gặp

| Triệu chứng | Nguyên nhân | Cách sửa |
|---|---|---|
| `uses-sdk:minSdkVersion 24 cannot be smaller than version 26 declared in library [:tflite_flutter]` | `minSdk` bị đặt lại về mặc định | Trong `android/app/build.gradle.kts` giữ `minSdk = 26`. Máy ảo/máy thật phải chạy Android 8.0+ |
| `INSTALL_FAILED_OLDER_SDK` | Thiết bị dưới Android 8.0 | Dùng máy/emulator API 26 trở lên |
| `Dependency ... requires compileSdk 37` / `android-37` not found | Chưa cài SDK Platform 37 | Cài **Android API 37** trong SDK Manager (mục 3) |
| `Minimum supported Gradle version is ...` / `The Android Gradle plugin supports only Kotlin Gradle plugin version ...` | Lệch phiên bản Gradle/AGP/Kotlin với Flutter đang cài | Dùng đúng Flutter 3.47.x; kiểm tra `android/gradle/wrapper/gradle-wrapper.properties` (Gradle 9.3.1) và `android/settings.gradle.kts` (AGP 9.1.0, Kotlin 2.4.0). Sau đó chạy `flutter clean` → `flutter pub get` |
| `Inconsistent JVM Target Compatibility` | Plugin đặt Java target khác Kotlin | Đã xử lý trong `android/build.gradle.kts`; đừng xóa khối `subprojects { tasks.withType<KotlinJvmCompile>... }` |
| `Unsupported class file major version` | Gradle chạy bằng JDK không hợp | Dùng JDK đi kèm Android Studio: `flutter config --jdk-dir "<Android Studio>\jbr"` |
| `Android license status unknown` / `Some Android licenses not accepted` | Chưa accept license SDK | Cài *Command-line Tools* rồi chạy `flutter doctor --android-licenses`, gõ `y` hết |
| Camera **đen** hoặc hiện cảnh 3D giả lập trên emulator | AVD chưa gán camera trước | Device Manager → ✏️ sửa AVD → *Show Advanced Settings* → **Front camera = Webcam0** → *Cold Boot Now*. Tắt app khác đang dùng webcam (Zoom, Meet…). Tốt nhất là thử trên máy thật |
| App báo không có quyền camera | Đã từ chối quyền trước đó | Cài đặt → Ứng dụng → Be A Chef → Quyền → bật **Camera** |
| Android Studio không thấy thiết bị / không hiện nút Run cho Flutter | Mở nhầm thư mục `android/` hoặc chưa cài plugin Flutter | Mở **thư mục gốc** có `pubspec.yaml`; cài plugin Flutter; *File → Invalidate Caches → Restart* |
| `INSTALL_FAILED_USER_RESTRICTED` (Xiaomi) | Chưa bật *Cài đặt qua USB* | Xem ghi chú Xiaomi ở mục 5 |
| `Could not close incremental caches ... compileDebugKotlin` | Project và `PUB_CACHE` nằm **khác ổ đĩa** (vd. project ở `C:`, pub cache ở `D:`), Kotlin incremental không xử lý được | Để project cùng ổ với `PUB_CACHE` (vd. clone vào `D:\...`), hoặc thêm `kotlin.incremental=false` vào `android/gradle.properties` |
| Build lần đầu rất lâu hoặc báo lỗi tải | Đang tải Gradle/thư viện; mạng chặn | Chờ; kiểm tra mạng/proxy; chạy lại `flutter run` |

## 9. Quy trình đóng góp

### Nhánh

- `main`: luôn build được, là nguồn để build bản release.
- Tạo nhánh mới từ `main` cho mỗi việc:
  - `feat/<mo-ta-ngan>`: tính năng mới (vd. `feat/liveness-scan`)
  - `fix/<mo-ta-ngan>`: sửa lỗi (vd. `fix/camera-black-screen`)
  - `docs/<mo-ta-ngan>`: tài liệu

### Commit

Dùng [Conventional Commits](https://www.conventionalcommits.org/). Tiêu đề ngắn, có thể viết tiếng Việt:

```text
feat: gắn kiểm tra nháy mắt vào màn quét mặt
fix: camera không mở lại sau khi quay về từ màn đăng ký
docs: bổ sung ảnh chụp màn hình
test: thêm test cho recommendation_service
refactor: tách xử lý ảnh YUV sang image_utils
chore: nâng phiên bản camera
```

### Trước khi đẩy code

```bash
flutter analyze
```

```bash
flutter test
```

Không được có **error**; toàn bộ test phải pass. Thêm package bằng `flutter pub add <tên>` (không tự gõ version),
và đọc README của package trên pub.dev để cấu hình Android (`minSdk`, quyền trong `AndroidManifest.xml`).

### Pull Request

1. Push nhánh, mở PR vào `main`.
2. Mô tả: làm gì, vì sao, cách kiểm tra; có thay đổi giao diện thì đính kèm ảnh chụp màn hình.
3. Ghi rõ đã thử trên thiết bị nào (máy thật/emulator, phiên bản Android).
4. Cần ít nhất **1 thành viên review** trước khi merge. Trưởng nhóm merge và build release.

### Quy ước code

- Comment tiếng Việt ở những chỗ quan trọng.
- Dùng `debugPrint`, không dùng `print`.
- Hằng số (ngưỡng nhận diện, số mẫu, đường dẫn asset…) để trong `lib/core/config.dart`.
- Lỗi có thể gặp (thiếu quyền, không có camera, lỗi DB…) phải bắt bằng `try/catch` và báo bằng `SnackBar` tiếng Việt,
  không để app crash. Kiểm tra `mounted` trước khi dùng `context` sau `await`.
