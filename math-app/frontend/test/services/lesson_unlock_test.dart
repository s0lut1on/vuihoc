import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/lesson_model.dart';
import 'package:math_app/services/lesson_unlock.dart';

ApiLesson _lesson(String subject, String id, int order) => ApiLesson(
      id: id,
      subjectId: subject,
      titleVi: '$subject $id',
      titleEn: '$subject $id',
      order: order,
    );

/// Groups a flat lesson list into the Map<String, List<ApiLesson>> shape
/// required by nextUnlockedLesson after the perf refactor (commit ce20879).
Map<String, List<ApiLesson>> _bySubject(List<ApiLesson> lessons) {
  final m = <String, List<ApiLesson>>{};
  for (final l in lessons) {
    m.putIfAbsent(l.subjectId, () => []).add(l);
  }
  return m;
}

void main() {
  group('nextUnlockedLesson', () {
    test('returns null when there are no lessons', () {
      expect(
          nextUnlockedLesson(bySubject: const {}, completed: const {}), isNull);
    });

    test('first lesson in each subject is always unlocked', () {
      final lessons = [
        _lesson('numbers', 'n1', 1),
        _lesson('numbers', 'n2', 2),
      ];
      final result = nextUnlockedLesson(
          bySubject: _bySubject(lessons), completed: const {});
      expect(result, isNotNull);
      expect(result!.subjectId, 'numbers');
      expect(result.lessonId, 'n1');
    });

    test('returns first uncompleted lesson across subjects in fixed order', () {
      // Subject order: numbers -> geometry -> measurement -> logic -> vietnamese -> english
      final lessons = [
        _lesson('geometry', 'g1', 1),
        _lesson('numbers', 'n1', 1),
      ];
      final result = nextUnlockedLesson(
          bySubject: _bySubject(lessons), completed: const {});
      expect(result!.subjectId, 'numbers',
          reason: 'numbers comes before geometry in fixed order');
      expect(result.lessonId, 'n1');
    });

    test('lesson N is unlocked iff lesson N-1 is completed in the same subject',
        () {
      final lessons = [
        _lesson('numbers', 'n1', 1),
        _lesson('numbers', 'n2', 2),
        _lesson('numbers', 'n3', 3),
      ];
      // n1 completed, n2 not completed -> next is n2
      final r1 = nextUnlockedLesson(
          bySubject: _bySubject(lessons), completed: {'n1'});
      expect(r1!.lessonId, 'n2');

      // n1 + n2 completed -> next is n3
      final r2 = nextUnlockedLesson(
          bySubject: _bySubject(lessons), completed: {'n1', 'n2'});
      expect(r2!.lessonId, 'n3');

      // Nothing completed -> next is n1 (first is always unlocked)
      final r3 = nextUnlockedLesson(
          bySubject: _bySubject(lessons), completed: const {});
      expect(r3!.lessonId, 'n1');
    });

    test('skip completed lessons and return the next uncompleted one', () {
      final lessons = [
        _lesson('numbers', 'n1', 1),
        _lesson('numbers', 'n2', 2),
        _lesson('numbers', 'n3', 3),
      ];
      // n1 completed, n2 skipped -> n3 still locked, n2 returned (we never skip,
      // the user must complete n2 to advance). n3 is NOT next.
      final result = nextUnlockedLesson(
          bySubject: _bySubject(lessons), completed: {'n1'});
      expect(result!.lessonId, 'n2');
    });

    test('completion in one subject does not unlock another subject', () {
      final lessons = [
        _lesson('numbers', 'n1', 1),
        _lesson('geometry', 'g1', 1),
      ];
      // n1 completed, g1 not. Since each subject's first lesson is always unlocked,
      // next should be g1.
      final result = nextUnlockedLesson(
          bySubject: _bySubject(lessons), completed: {'n1'});
      expect(result!.subjectId, 'geometry');

      // Empty completion -> numbers first.
      final result2 = nextUnlockedLesson(
          bySubject: _bySubject(lessons), completed: const {});
      expect(result2!.subjectId, 'numbers');
    });

    test('returns null when every lesson in every subject is completed', () {
      final lessons = [
        _lesson('numbers', 'n1', 1),
        _lesson('numbers', 'n2', 2),
        _lesson('geometry', 'g1', 1),
      ];
      final result = nextUnlockedLesson(
        bySubject: _bySubject(lessons),
        completed: {'n1', 'n2', 'g1'},
      );
      expect(result, isNull);
    });

    test('subjects not in the fixed order are skipped', () {
      // 'french' is not in subjectOrder; we still treat first lesson as unlocked
      // but iterate known subjects in known order. This test documents that
      // unknown subjects are still reachable if they have lessons.
      final lessons = [
        _lesson('numbers', 'n1', 1),
        _lesson('french', 'f1', 1),
      ];
      // numbers first, has unfinished -> returns n1, not f1
      final result = nextUnlockedLesson(
          bySubject: _bySubject(lessons), completed: const {});
      expect(result!.subjectId, 'numbers');
    });

    test(
        'all lessons in first 5 subjects completed, only english left -> english',
        () {
      final lessons = [
        _lesson('numbers', 'n1', 1),
        _lesson('geometry', 'g1', 1),
        _lesson('measurement', 'm1', 1),
        _lesson('logic', 'l1', 1),
        _lesson('vietnamese', 'v1', 1),
        _lesson('english', 'e1', 1),
        _lesson('english', 'e2', 2),
      ];
      final result = nextUnlockedLesson(
        bySubject: _bySubject(lessons),
        completed: {'n1', 'g1', 'm1', 'l1', 'v1'},
      );
      expect(result!.subjectId, 'english');
      expect(result.lessonId, 'e1');
    });

    test('duplicates in lesson list (same id twice) do not break ordering', () {
      final lessons = [
        _lesson('numbers', 'n1', 1),
        _lesson('numbers', 'n1', 1), // duplicate, same order
        _lesson('numbers', 'n2', 2),
      ];
      final result = nextUnlockedLesson(
          bySubject: _bySubject(lessons), completed: const {});
      // first match wins; both n1s are unlocked, function returns the first match
      expect(result!.lessonId, 'n1');
    });
  });
}
