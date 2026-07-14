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
///
/// Takes a pre-grouped map (`subjectId -> sorted lessons`) so the caller
/// can use the lightweight per-subject endpoint instead of fetching
/// the full 808KB curriculum just to find the next lesson.
LessonRef? nextUnlockedLesson({
  required Map<String, List<ApiLesson>> bySubject,
  required Set<String> completed,
}) {
  for (final subjectId in subjectOrder) {
    final subjectLessons = bySubject[subjectId];
    if (subjectLessons == null) continue;
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
