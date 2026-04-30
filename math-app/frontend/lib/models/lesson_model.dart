enum Subject { numbers, geometry, measurement, logic, practical }

/// API model for a lesson from the backend content service.
class ApiLesson {
  final String id;
  final String subjectId;
  final String titleVi;
  final String titleEn;
  final int order;
  final bool isPremium;
  final int difficulty; // 1-3
  final List<ApiExercise> exercises;

  const ApiLesson({
    required this.id,
    required this.subjectId,
    required this.titleVi,
    required this.titleEn,
    required this.order,
    this.isPremium = false,
    this.difficulty = 1,
    this.exercises = const [],
  });

  factory ApiLesson.fromJson(Map<String, dynamic> json) {
    return ApiLesson(
      id: json['id'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? '',
      titleVi: json['title_vi'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      isPremium: json['is_premium'] as bool? ?? false,
      difficulty: json['difficulty'] as int? ?? 1,
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => ApiExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// API model for an exercise within a lesson.
class ApiExercise {
  final String id;
  final String questionVi;
  final String questionEn;
  final List<String> options;
  final int correctIndex;
  final String? hintVi;
  final String? hintEn;
  final String? visualAsset;

  const ApiExercise({
    required this.id,
    required this.questionVi,
    required this.questionEn,
    required this.options,
    required this.correctIndex,
    this.hintVi,
    this.hintEn,
    this.visualAsset,
  });

  factory ApiExercise.fromJson(Map<String, dynamic> json) {
    return ApiExercise(
      id: json['id'] as String? ?? '',
      questionVi: json['question_vi'] as String? ?? '',
      questionEn: json['question_en'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? []).cast<String>(),
      correctIndex: json['correct'] as int? ?? 0,
      hintVi: json['hint_vi'] as String?,
      hintEn: json['hint_en'] as String?,
      visualAsset: json['visual'] as String?,
    );
  }
}

/// UI model for a lesson (simplified, no exercises).
class Lesson {
  final String id;
  final String subjectId;
  final String titleVi;
  final String titleEn;
  final int order;
  final bool isPremium;
  final int difficulty; // 1-3

  const Lesson({
    required this.id,
    required this.subjectId,
    required this.titleVi,
    required this.titleEn,
    required this.order,
    this.isPremium = false,
    this.difficulty = 1,
  });
}

/// UI model for an exercise.
class Exercise {
  final String id;
  final String questionVi;
  final String questionEn;
  final List<String> options;
  final int correctIndex;
  final String? hintVi;
  final String? hintEn;
  final String? visualAsset;

  const Exercise({
    required this.id,
    required this.questionVi,
    required this.questionEn,
    required this.options,
    required this.correctIndex,
    this.hintVi,
    this.hintEn,
    this.visualAsset,
  });
}

class SubjectProgress {
  final String subjectId;
  final int completedLessons;
  final int totalLessons;
  final int currentStreak;
  final int bestStreak;

  const SubjectProgress({
    required this.subjectId,
    required this.completedLessons,
    required this.totalLessons,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  double get progressPercent =>
      totalLessons == 0 ? 0 : completedLessons / totalLessons;
}
