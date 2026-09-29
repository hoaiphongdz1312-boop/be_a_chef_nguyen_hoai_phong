import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/config.dart';
import '../data/models/learner.dart';
import '../data/repositories/learner_repository.dart';
import '../services/face_detector_service.dart';
import '../services/face_embedding_service.dart';
import '../services/face_math.dart';
import '../widgets/camera_view.dart';

/// Đăng ký học viên: nhập tên và tự chụp 3–5 mẫu khuôn mặt.
///
/// Một mẫu chỉ được nhận khi khung hình có đúng 1 mặt, đủ lớn và nhìn thẳng.
/// Khi lưu, vector trung bình của các mẫu được ghi vào DB.
/// Trả về [Learner] vừa tạo qua `Navigator.pop`.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _samples = <Float32List>[];
  FaceEmbeddingService? _embedder;
  String? _loadError;
  String _hint = 'Đưa khuôn mặt vào khung hình';
  DateTime _lastSampleAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _saving = false;

  bool get _enoughSamples => _samples.length >= AppConfig.minRegisterSamples;
  bool get _fullSamples => _samples.length >= AppConfig.maxRegisterSamples;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    FaceEmbeddingService.instance().then(
      (e) => mounted ? setState(() => _embedder = e) : null,
      onError: (Object e) {
        debugPrint('[Register] không nạp được model: $e');
        if (mounted) setState(() => _loadError = 'Không nạp được model nhận diện.');
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onFrame(FaceFrame frame) async {
    final embedder = _embedder;
    if (embedder == null || _fullSamples || _saving) return;

    final issue = checkFaceQuality(frame.faces, frame.uprightSize.width);
    if (issue != null) {
      _setHint(issue.message);
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastSampleAt) < AppConfig.registerSampleInterval) return;

    final embedding = await embedder.embedFace(
      frame.image,
      frame.rotation,
      frame.faces.single.boundingBox,
    );
    if (!mounted) return;
    setState(() {
      _samples.add(embedding);
      _lastSampleAt = DateTime.now();
      _hint = _fullSamples
          ? 'Đã chụp đủ ảnh'
          : 'Giữ yên, hơi đổi góc mặt một chút';
    });
  }

  void _setHint(String hint) {
    if (mounted && hint != _hint) setState(() => _hint = hint);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || !_enoughSamples) return;
    setState(() => _saving = true);
    try {
      final learner = await LearnerRepository().insert(
        name: name,
        embedding: averageEmbedding(_samples),
        sampleCount: _samples.length,
      );
      if (mounted) Navigator.of(context).pop<Learner>(learner);
    } catch (e) {
      debugPrint('[Register] lỗi lưu: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không lưu được học viên, thử lại nhé.')),
      );
    }
  }

  void _retake() => setState(() {
        _samples.clear();
        _hint = 'Đưa khuôn mặt vào khung hình';
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSave =
        _nameController.text.trim().isNotEmpty && _enoughSamples && !_saving;

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký học viên')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Tên học viên',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loadError != null
                    ? Center(child: Text(_loadError!))
                    : FaceCameraView(
                        onFrame: _onFrame,
                        faceColor: _fullSamples ? Colors.green : null,
                      ),
              ),
              const SizedBox(height: 12),
              Text(_hint, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _samples.length / AppConfig.maxRegisterSamples,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text(
                'Đã chụp ${_samples.length}/${AppConfig.maxRegisterSamples} ảnh '
                '(tối thiểu ${AppConfig.minRegisterSamples})',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _samples.isEmpty || _saving ? null : _retake,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Chụp lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: canSave ? _save : null,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
