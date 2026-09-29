import 'dart:convert';

/// Một món ăn / bài học nấu ăn.
class Lesson {
  const Lesson({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.durationMinutes,
    required this.ingredients,
    required this.steps,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String description;

  /// Độ khó 1 (dễ) – 3 (khó).
  final int difficulty;
  final int durationMinutes;
  final List<String> ingredients;
  final List<String> steps;

  /// Thứ tự hiển thị (theo thứ tự trong lessons.json).
  final int sortOrder;

  int get stepCount => steps.length;

  /// Đọc từ một phần tử trong assets/data/lessons.json.
  factory Lesson.fromJson(Map<String, dynamic> json, int sortOrder) {
    return Lesson(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as int,
      durationMinutes: json['duration_minutes'] as int,
      ingredients: List<String>.from(json['ingredients'] as List),
      steps: List<String>.from(json['steps'] as List),
      sortOrder: sortOrder,
    );
  }

  /// Danh sách nguyên liệu và các bước lưu dạng chuỗi JSON trong SQLite.
  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'difficulty': difficulty,
        'duration_minutes': durationMinutes,
        'ingredients': jsonEncode(ingredients),
        'steps': jsonEncode(steps),
        'sort_order': sortOrder,
      };

  factory Lesson.fromMap(Map<String, Object?> map) {
    return Lesson(
      id: map['id']! as String,
      name: map['name']! as String,
      description: map['description']! as String,
      difficulty: map['difficulty']! as int,
      durationMinutes: map['duration_minutes']! as int,
      ingredients: List<String>.from(jsonDecode(map['ingredients']! as String) as List),
      steps: List<String>.from(jsonDecode(map['steps']! as String) as List),
      sortOrder: map['sort_order']! as int,
    );
  }

  /// Parse toàn bộ nội dung file lessons.json.
  static List<Lesson> listFromJson(String source) {
    final list = jsonDecode(source) as List;
    return [
      for (var i = 0; i < list.length; i++)
        Lesson.fromJson(list[i] as Map<String, dynamic>, i),
    ];
  }
}
