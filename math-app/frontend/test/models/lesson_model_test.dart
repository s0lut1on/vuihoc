import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/lesson_model.dart';

void main() {
  group('SubjectProgress', () {
    test('progressPercent returns 0 when totalLessons is 0', () {
      const progress = SubjectProgress(
        subjectId: 'numbers',
        completedLessons: 0,
        totalLessons: 0,
      );
      expect(progress.progressPercent, equals(0));
    });

    test('progressPercent calculates correctly', () {
      const progress = SubjectProgress(
        subjectId: 'numbers',
        completedLessons: 3,
        totalLessons: 10,
      );
      expect(progress.progressPercent, closeTo(0.3, 0.001));
    });

    test('progressPercent is 1 when all lessons completed', () {
      const progress = SubjectProgress(
        subjectId: 'geometry',
        completedLessons: 5,
        totalLessons: 5,
      );
      expect(progress.progressPercent, equals(1.0));
    });
  });

  group('Lesson', () {
    test('default difficulty is 1', () {
      const lesson = Lesson(
        id: 'l1',
        subjectId: 'numbers',
        titleVi: 'Dem den 10',
        titleEn: 'Count to 10',
        order: 1,
      );
      expect(lesson.difficulty, equals(1));
      expect(lesson.isPremium, isFalse);
    });

    test('fields are assigned correctly', () {
      const lesson = Lesson(
        id: 'l2',
        subjectId: 'geometry',
        titleVi: 'Hinh hoc',
        titleEn: 'Geometry',
        order: 2,
        difficulty: 2,
        isPremium: true,
      );
      expect(lesson.id, 'l2');
      expect(lesson.subjectId, 'geometry');
      expect(lesson.titleVi, 'Hinh hoc');
      expect(lesson.titleEn, 'Geometry');
      expect(lesson.difficulty, 2);
      expect(lesson.isPremium, isTrue);
    });
  });

  group('Exercise', () {
    test('exercise has correct options and answer', () {
      const exercise = Exercise(
        id: 'ex1',
        questionVi: '3 + 5 = ?',
        questionEn: '3 + 5 = ?',
        options: ['7', '8', '9'],
        correctIndex: 1,
        hintVi: 'Dem tiep 5 buoc tu so 3',
        hintEn: 'Count 5 more steps from 3',
      );
      expect(exercise.options, equals(['7', '8', '9']));
      expect(exercise.correctIndex, equals(1));
      expect(exercise.options[exercise.correctIndex], equals('8'));
    });

    test('optional fields default to null', () {
      const exercise = Exercise(
        id: 'ex2',
        questionVi: 'So nao lon hon?',
        questionEn: 'Which is larger?',
        options: ['1', '2'],
        correctIndex: 1,
      );
      expect(exercise.hintVi, isNull);
      expect(exercise.hintEn, isNull);
      expect(exercise.visualAsset, isNull);
    });
  });

  group('Subject enum', () {
    test('enum values are correct', () {
      expect(Subject.values.length, equals(5));
      expect(Subject.values, contains(Subject.numbers));
      expect(Subject.values, contains(Subject.geometry));
      expect(Subject.values, contains(Subject.measurement));
      expect(Subject.values, contains(Subject.logic));
      expect(Subject.values, contains(Subject.practical));
    });
  });
}
