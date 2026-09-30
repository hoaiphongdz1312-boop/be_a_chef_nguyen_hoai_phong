import 'dart:async';

import 'package:flutter/material.dart';

import '../core/config.dart';
import '../data/models/learner.dart';
import '../data/repositories/learner_repository.dart';
import '../services/face_detector_service.dart';
import '../services/face_embedding_service.dart';
import '../services/face_math.dart';
import '../widgets/camera_view.dart';
import '../widgets/learner_picker_sheet.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

/// Màn mở app: quét mặt → "Xin chào `tên`!" → Dashboard.
///
/// Mỗi khung hình đạt chuẩn (1 mặt, đủ lớn, nhìn thẳng) được so khớp với tất
/// cả học viên. Chỉ cho vào khi [AppConfig.requiredConsecutiveMatches] khung
/// LIÊN TIẾP cùng khớp một người (đạt ngưỡng và bỏ xa người thứ hai).
/// Khung không khớp tính là một lần thất bại. Thất bại [AppConfig.maxScanAttempts] lần hoặc
/// bấm "Chọn thủ công" thì cho chọn tên từ danh sách.
class SplashScanScreen extends StatefulWidget {
  const SplashScanScreen({super.key});

  @override
  State<SplashScanScreen> createState() => _SplashScanScreenState();
}

/// - picking: đang mở bảng chọn thủ công (camera vẫn hiện, bỏ qua frame).
/// - away: đang ở màn Đăng ký → gỡ camera để không mở 2 camera cùng lúc.
enum _Phase { loading, empty, scanning, picking, away, greeting, error }

class _SplashScanScreenState extends State<SplashScanScreen> {
  final _repo = LearnerRepository();
  _Phase _phase = _Phase.loading;
  List<Learner> _learners = const [];
  FaceEmbeddingService? _embedder;
  Learner? _greeted;

  String _hint = 'Nhìn thẳng vào camera';
  int _failures = 0;
  final _streak =
      ConsecutiveMatchCounter<int>(AppConfig.requiredConsecutiveMatches);
  DateTime _nextAttemptAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _phase = _Phase.loading);
    try {
      final results = await Future.wait([
        FaceEmbeddingService.instance(),
        _repo.getAll(),
      ]);
      if (!mounted) return;
      final embedder = results[0] as FaceEmbeddingService;
      // Bỏ qua embedding có số chiều khác model hiện tại (nếu đổi model).
      final learners = [
        for (final l in results[1] as List<Learner>)
          if (l.embedding.length == embedder.embeddingSize) l,
      ];
      setState(() {
        _embedder = embedder;
        _learners = learners;
        _failures = 0;
        _streak.reset();
        _hint = 'Nhìn thẳng vào camera';
        _phase = learners.isEmpty ? _Phase.empty : _Phase.scanning;
      });
    } catch (e) {
      debugPrint('[Scan] lỗi khởi động: $e');
      if (mounted) setState(() => _phase = _Phase.error);
    }
  }

  Future<void> _onFrame(FaceFrame frame) async {
    final embedder = _embedder;
    if (_phase != _Phase.scanning || embedder == null) return;
    if (DateTime.now().isBefore(_nextAttemptAt)) return;

    final issue = checkFaceQuality(frame.faces, frame.uprightSize.width);
    if (issue != null) {
      // Mặt rời khung / có người khác chen vào → xác nhận lại từ đầu.
      _streak.reset();
      _setHint(issue.message);
      return;
    }

    final embedding = await embedder.embedFace(
      frame.image,
      frame.rotation,
      frame.faces.single.boundingBox,
    );
    if (!mounted || _phase != _Phase.scanning) return;

    final match = findBestMatch(
      embedding,
      _learners,
      (l) => l.embedding,
      threshold: AppConfig.matchThreshold,
      margin: AppConfig.matchMargin,
    );
    // Độ giống chỉ ghi ra debug log, không hiện trên UI.
    // Dùng log này để chỉnh ngưỡng trong config.dart nếu cần.
    debugPrint('[Scan] giống nhất: ${match?.candidate.name} '
        'score=${match?.score.toStringAsFixed(3)} '
        'thứ hai=${match?.secondScore?.toStringAsFixed(3)} '
        'ngưỡng=${AppConfig.matchThreshold} → '
        '${match?.accepted == true ? 'KHỚP' : 'không khớp'}');

    if (match != null && match.accepted) {
      // Phải khớp CÙNG một người ở nhiều khung hình liên tiếp mới cho vào,
      // một khung hình vượt ngưỡng do ngẫu nhiên là chưa đủ.
      if (_streak.add(match.candidate.id)) {
        _greet(match.candidate);
      } else {
        _setHint('Giữ yên, đang xác nhận… '
            '(${_streak.count}/${AppConfig.requiredConsecutiveMatches})');
      }
      return;
    }

    _streak.reset();
    _failures++;
    if (_failures >= AppConfig.maxScanAttempts) {
      _pickManually();
    } else {
      _nextAttemptAt = DateTime.now().add(AppConfig.scanRetryDelay);
      _setHint('Chưa nhận ra bạn, thử lại '
          '(${_failures + 1}/${AppConfig.maxScanAttempts})');
    }
  }

  void _setHint(String hint) {
    if (mounted && hint != _hint) setState(() => _hint = hint);
  }

  Future<void> _pickManually() async {
    setState(() => _phase = _Phase.picking);
    final learner = await showLearnerPicker(context, _learners);
    if (!mounted) return;
    if (learner != null) {
      _greet(learner);
    } else {
      // Đóng bảng chọn → quét lại từ đầu.
      setState(() {
        _failures = 0;
        _streak.reset();
        _hint = 'Nhìn thẳng vào camera';
        _phase = _Phase.scanning;
      });
    }
  }

  Future<void> _register() async {
    final previous = _phase;
    setState(() => _phase = _Phase.away);
    final learner = await Navigator.of(context).push<Learner>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (!mounted) return;
    if (learner != null) {
      _greet(learner);
    } else {
      setState(() {
        _failures = 0;
        _streak.reset();
        _phase = previous;
      });
    }
  }

  void _greet(Learner learner) {
    setState(() {
      _greeted = learner;
      _phase = _Phase.greeting;
    });
    Timer(AppConfig.greetingDuration, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardScreen(learner: learner)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: switch (_phase) {
          _Phase.loading || _Phase.away =>
            const Center(child: CircularProgressIndicator()),
          _Phase.error => _CenterMessage(
              icon: Icons.error_outline,
              title: 'Không khởi động được',
              text: 'Không nạp được dữ liệu hoặc model nhận diện.',
              action: FilledButton(onPressed: _load, child: const Text('Thử lại')),
            ),
          _Phase.empty => _CenterMessage(
              icon: Icons.restaurant_menu,
              title: 'Chào mừng đến ${AppConfig.appName}!',
              text: 'Chưa có học viên nào. Đăng ký khuôn mặt để bắt đầu học nấu ăn.',
              action: FilledButton.icon(
                onPressed: _register,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Đăng ký học viên'),
              ),
            ),
          _Phase.greeting => _CenterMessage(
              icon: Icons.waving_hand_outlined,
              title: 'Xin chào ${_greeted!.name}!',
              text: 'Cùng vào bếp nào.',
            ),
          _Phase.scanning || _Phase.picking => _buildScanner(context),
        },
      ),
    );
  }

  Widget _buildScanner(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(AppConfig.appName, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Quét khuôn mặt để vào bài học của bạn',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Expanded(child: FaceCameraView(onFrame: _onFrame)),
          const SizedBox(height: 12),
          Text(_hint,
              style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _phase == _Phase.scanning ? _pickManually : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Chọn thủ công'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _phase == _Phase.scanning ? _register : null,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Đăng ký mới'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage({
    required this.icon,
    required this.title,
    required this.text,
    this.action,
  });

  final IconData icon;
  final String title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
