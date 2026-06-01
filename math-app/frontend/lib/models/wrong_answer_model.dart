/// A wrong-answer entry stored locally for review.
class WrongAnswer {
  final String exerciseId;
  final String lessonId;
  final String subjectId;
  final String questionVi;
  final String questionEn;
  final String? hintVi;
  final String? hintEn;
  final List<String> options;
  final int correctIndex;
  final int wrongCount;
  final DateTime lastWrongAt;

  const WrongAnswer({
    required this.exerciseId,
    required this.lessonId,
    required this.subjectId,
    required this.questionVi,
    required this.questionEn,
    this.hintVi,
    this.hintEn,
    required this.options,
    required this.correctIndex,
    required this.wrongCount,
    required this.lastWrongAt,
  });

  factory WrongAnswer.fromJson(Map<String, dynamic> json) {
    return WrongAnswer(
      exerciseId: json['exerciseId'] as String,
      lessonId: json['lessonId'] as String,
      subjectId: json['subjectId'] as String,
      questionVi: json['questionVi'] as String,
      questionEn: json['questionEn'] as String,
      hintVi: json['hintVi'] as String?,
      hintEn: json['hintEn'] as String?,
      options: (json['options'] as List<dynamic>).cast<String>(),
      correctIndex: json['correctIndex'] as int,
      wrongCount: json['wrongCount'] as int,
      lastWrongAt: DateTime.parse(json['lastWrongAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'lessonId': lessonId,
      'subjectId': subjectId,
      'questionVi': questionVi,
      'questionEn': questionEn,
      'hintVi': hintVi,
      'hintEn': hintEn,
      'options': options,
      'correctIndex': correctIndex,
      'wrongCount': wrongCount,
      'lastWrongAt': lastWrongAt.toIso8601String(),
    };
  }

  WrongAnswer increment() => WrongAnswer(
        exerciseId: exerciseId,
        lessonId: lessonId,
        subjectId: subjectId,
        questionVi: questionVi,
        questionEn: questionEn,
        hintVi: hintVi,
        hintEn: hintEn,
        options: options,
        correctIndex: correctIndex,
        wrongCount: wrongCount + 1,
        lastWrongAt: DateTime.now(),
      );
}
