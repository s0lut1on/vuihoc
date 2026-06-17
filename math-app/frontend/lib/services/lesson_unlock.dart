import '../models/lesson_model.dart';

/// Subjects iterated in this fixed order when looking for the next lesson.
/// Mirrors the order used in [nextLessonProvider].
const subjectOrder = <String>[
  'numbers',
  'geometry',
  'measurement',
  'logic',
  'vietnamese',
  'english',
];

/// Pick the next unlocked-but-not-yet-completed lesson for the user.
///
/// Returns `{subjectId, lessonId}` for the first match, or `null` when the
/// user has finished every available lesson.
///
/// Unlocking rule: within a subject, lesson N is unlocked iff lesson N-1 has
/// been completed. The first lesson of every subject is always unlocked.
LessonRef? nextUnlockedLesson({
  required List<ApiLesson> lessons,
  required Set<String> completed,
}) {
  if (lessons.isEmpty) return null;
  for (final subjectId in subjectOrder) {
    final subjectLessons = [...lessons.where((l) => l.subjectId == subjectId)]
      ..sort((a, b) => a.order.compareTo(b.order));
    for (var i = 0; i < subjectLessons.length; i++) {
      final lesson = subjectLessons[i];
      final isUnlocked = i == 0 || completed.contains(subjectLessons[i - 1].id);
      if (isUnlocked && !completed.contains(lesson.id)) {
        return LessonRef(subjectId: subjectId, lessonId: lesson.id);
      }
    }
  }
  return null;
}

class LessonRef {
  final String subjectId;
  final String lessonId;
  const LessonRef({required this.subjectId, required this.lessonId});
}
