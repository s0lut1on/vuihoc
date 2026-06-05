import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/lesson_model.dart';
import '../providers/app_providers.dart';
import '../services/content_api.dart';
import '../services/language_api.dart';

class SubjectScreen extends ConsumerStatefulWidget {
  final String subjectId;

  const SubjectScreen({super.key, required this.subjectId});

  @override
  ConsumerState<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends ConsumerState<SubjectScreen> {
  List<ApiLesson> _lessons = [];
  bool _loading = true;
  String? _subjectTitle;

  static const Map<String, Map<String, dynamic>> _subjectMeta = {
    'math': {'icon': '🔢', 'color': 0xFFFFE8F0},
    'numbers': {'icon': '🔢', 'color': 0xFFFFE8F0},
    'geometry': {'icon': '📐', 'color': 0xFFE8F5E9},
    'measurement': {'icon': '📏', 'color': 0xFFFFF3E0},
    'logic': {'icon': '🧩', 'color': 0xFFE3F2FD},
    'vietnamese': {'icon': '🇻🇳', 'color': 0xFFFFEBEE},
    'english': {'icon': '🇬🇧', 'color': 0xFFE8EAF6},
  };

  static const List<Map<String, dynamic>> _mathSubSubjects = [
    {'id': 'numbers', 'icon': '🔢', 'nameVi': 'Số học', 'nameEn': 'Numbers', 'color': 0xFFFFE8F0},
    {'id': 'geometry', 'icon': '📐', 'nameVi': 'Hình học', 'nameEn': 'Geometry', 'color': 0xFFE8F5E9},
    {'id': 'measurement', 'icon': '📏', 'nameVi': 'Đo lường', 'nameEn': 'Measurement', 'color': 0xFFFFF3E0},
    {'id': 'logic', 'icon': '🧩', 'nameVi': 'Tư duy', 'nameEn': 'Logic', 'color': 0xFFE3F2FD},
  ];

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      List<ApiLesson> lessons;
      final userGrade = ref.read(userProvider).value?.grade ?? 1;
      if (widget.subjectId == 'math') {
        // Math is a grouping subject — no lessons directly under it
        setState(() {
          _lessons = [];
          _loading = false;
          final l10n = AppLocalizations.of(context)!;
          _subjectTitle = _resolveTitle(l10n);
        });
        return;
      }
      if (widget.subjectId == 'vietnamese' || widget.subjectId == 'english') {
        final curriculum = await LanguageApi.getCurriculum(grade: userGrade);
        final subject = curriculum.firstWhere(
          (s) => s['subject_id'] == widget.subjectId,
          orElse: () => {},
        );
        final rawLessons = (subject['lessons'] as List<dynamic>?) ?? [];
        lessons = rawLessons.map((l) {
          final lesson = l as Map<String, dynamic>;
          lesson['subject_id'] = widget.subjectId;
          return ApiLesson.fromJson(lesson);
        }).toList();
      } else {
        lessons = await ContentApi.getCurriculum(grade: userGrade);
        lessons = lessons.where((l) => l.subjectId == widget.subjectId).toList();
      }
      lessons.sort((a, b) => a.order.compareTo(b.order));
      setState(() {
        _lessons = lessons;
        _loading = false;
        final l10n = AppLocalizations.of(context)!;
        _subjectTitle = _resolveTitle(l10n);
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _resolveTitle(AppLocalizations l10n) {
    switch (widget.subjectId) {
      case 'math':
        return l10n.parentDashboardSubjectMath;
      case 'numbers':
        return l10n.parentDashboardSubjectNumbers;
      case 'geometry':
        return l10n.parentDashboardSubjectGeometry;
      case 'measurement':
        return l10n.parentDashboardSubjectMeasurement;
      case 'logic':
        return l10n.parentDashboardSubjectLogic;
      case 'vietnamese':
        return l10n.parentDashboardSubjectVietnamese;
      case 'english':
        return l10n.parentDashboardSubjectEnglish;
      default:
        return widget.subjectId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final meta =
        _subjectMeta[widget.subjectId] ?? {'icon': '📚', 'color': 0xFFE0E0E0};
    final completedAsync = ref.watch(userProgressProvider);

    final completedSet = completedAsync.when(
      data: (set) => set,
      loading: () => <String>{},
      error: (_, __) => <String>{},
    );

    return Scaffold(
      backgroundColor: AppColors.grayBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Color(meta['color'] as int),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: AppColors.darkPurple),
                        onPressed: () => context.go('/home'),
                      ),
                      const Spacer(),
                    ],
                  ),
                  if (widget.subjectId != 'math') ...[
                    Text(meta['icon'] as String,
                        style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    _subjectTitle ?? _resolveTitle(l10n),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkPurple,
                    ),
                  ),
                  Text(
                    widget.subjectId == 'math'
                        ? '${_mathSubSubjects.length} ${_mathSubSubjects.length == 1 ? (l10n.homeDayStreak(0).contains('ng') ? 'chủ đề' : 'subjects') : (l10n.homeDayStreak(0).contains('ng') ? 'chủ đề' : 'subjects')}'
                        : _lessons.isEmpty
                            ? l10n.lessonNotFound
                            : '${_lessons.length} ${l10n.homeDayStreak(0).contains('ng') ? 'bai hoc' : 'lessons'}',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.darkText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            widget.subjectId == 'math'
                ? _buildSubSubjectGrid(context, l10n)
                : Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primaryPink))
                        : _lessons.isEmpty
                            ? Center(
                                child: Text(
                                  l10n.lessonNotFound,
                                  style: const TextStyle(
                                      fontSize: 18, color: AppColors.primaryPink),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 8),
                                itemCount: _lessons.length,
                                itemBuilder: (context, index) {
                                  final lesson = _lessons[index];
                                  final isCompleted =
                                      completedSet.contains(lesson.id);
                                  final isUnlocked = index == 0 ||
                                      completedSet.contains(_lessons[index - 1].id);
                                  return _LessonCard(
                                    lesson: lesson,
                                    subjectId: widget.subjectId,
                                    isCompleted: isCompleted,
                                    isUnlocked: isUnlocked,
                                    onTap: isUnlocked
                                        ? () {
                                            final route = widget.subjectId ==
                                                        'vietnamese' ||
                                                    widget.subjectId == 'english'
                                                ? '/language-lesson/${widget.subjectId}/${lesson.id}'
                                                : '/lesson/${widget.subjectId}/${lesson.id}';
                                            context.go(route);
                                          }
                                        : null,
                                  );
                                },
                              ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubSubjectGrid(BuildContext context, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context);
    final isVi = locale.languageCode == 'vi';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: _mathSubSubjects.map((sub) {
          final title = isVi ? sub['nameVi'] as String : sub['nameEn'] as String;
          return GestureDetector(
            onTap: () => context.push('/subject/${sub['id']}'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Color(sub['color'] as int),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        sub['icon'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkPurple,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.darkPurple, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final ApiLesson lesson;
  final String subjectId;
  final bool isCompleted;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const _LessonCard({
    required this.lesson,
    required this.subjectId,
    this.isCompleted = false,
    this.isUnlocked = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isVi = locale.languageCode == 'vi';
    final title = isVi ? lesson.titleVi : lesson.titleEn;
    final difficultyLabel = lesson.difficulty == 1
        ? (isVi ? 'De' : 'Easy')
        : lesson.difficulty == 2
            ? (isVi ? 'Vua' : 'Medium')
            : (isVi ? 'Kho' : 'Hard');

    final Color bgColor =
        isUnlocked ? AppColors.white : const Color(0xFFF5F5F5);
    final Color borderColor = isUnlocked
        ? (isCompleted ? AppColors.successGreen : AppColors.divider)
        : AppColors.divider;

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.5,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: isCompleted ? 2 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.successGreen.withValues(alpha: 0.1)
                      : AppColors.primaryPink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_circle,
                          color: AppColors.successGreen, size: 24)
                      : !isUnlocked
                          ? const Icon(Icons.lock,
                              color: AppColors.darkText, size: 24)
                          : Text(
                              '${lesson.order}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryPink,
                              ),
                            ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isUnlocked
                            ? AppColors.darkPurple
                            : AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: lesson.difficulty == 1
                                ? Colors.green.shade50
                                : lesson.difficulty == 2
                                    ? Colors.orange.shade50
                                    : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            difficultyLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: lesson.difficulty == 1
                                  ? AppColors.successGreen
                                  : lesson.difficulty == 2
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                        ),
                        if (lesson.isPremium) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                        ],
                        if (isCompleted) ...[
                          const SizedBox(width: 8),
                          Row(
                            children: List.generate(3, (i) {
                              return Icon(
                                Icons.star,
                                size: 14,
                                color: i < 3 ? Colors.amber : AppColors.divider,
                              );
                            }),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isUnlocked)
                const Icon(Icons.chevron_right, color: AppColors.divider),
            ],
          ),
        ),
      ),
    );
  }
}
