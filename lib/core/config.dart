/// Hằng số cấu hình của app.
///
/// App không có màn Cài đặt: muốn đổi giá trị nào thì sửa trực tiếp ở đây.
abstract final class AppConfig {
  static const String appName = 'Be A Chef';

  /// Đường dẫn asset.
  static const String faceModelAsset = 'assets/models/mobilefacenet.tflite';
  static const String lessonsAsset = 'assets/data/lessons.json';

  /// Tên file SQLite trong thư mục database của app.
  static const String databaseName = 'be_a_chef.db';

  // ---------------------------------------------------------------------------
  // Nhận diện khuôn mặt
  // ---------------------------------------------------------------------------

  /// Ngưỡng độ giống cosine (trên vector đã chuẩn hóa L2) để coi là cùng người.
  /// Độ giống chỉ được in ra debug log, không hiện trên UI.
  static const double matchThreshold = 0.70;

  /// Chuẩn hóa pixel cho MobileFaceNet: (giá trị − mean) / std.
  /// Lấy theo mã nguồn gốc của model (MCarlomagno/FaceRecognitionAuth).
  static const double modelInputMean = 128.0;
  static const double modelInputStd = 128.0;

  /// Nới rộng khung mặt của ML Kit trước khi cắt (tỉ lệ mỗi phía).
  static const double faceCropMargin = 0.10;

  /// Mặt phải chiếm tối thiểu tỉ lệ này của bề ngang ảnh (đã xoay đứng).
  static const double minFaceWidthRatio = 0.30;

  /// Góc đầu tối đa (độ) để coi là "nhìn thẳng".
  /// Y: quay trái/phải; Z: nghiêng đầu sang vai.
  static const double maxHeadEulerY = 12.0;
  static const double maxHeadEulerZ = 12.0;

  // ---------------------------------------------------------------------------
  // Đăng ký học viên
  // ---------------------------------------------------------------------------

  /// Số ảnh mặt cần chụp khi đăng ký (lưu được khi đạt tối thiểu).
  static const int minRegisterSamples = 3;
  static const int maxRegisterSamples = 5;

  /// Khoảng cách tối thiểu giữa 2 lần tự chụp mẫu.
  static const Duration registerSampleInterval = Duration(milliseconds: 700);

  // ---------------------------------------------------------------------------
  // Quét mặt khi mở app
  // ---------------------------------------------------------------------------

  /// Số lần nhận diện thất bại trước khi chuyển sang chọn thủ công.
  static const int maxScanAttempts = 3;

  /// Nghỉ giữa 2 lần thử để người dùng kịp chỉnh tư thế.
  static const Duration scanRetryDelay = Duration(milliseconds: 1500);

  /// Thời gian hiện lời chào trước khi vào dashboard.
  static const Duration greetingDuration = Duration(milliseconds: 1500);
}
