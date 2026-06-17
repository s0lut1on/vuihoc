import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/lesson_model.dart';
import '../providers/app_providers.dart';
import '../services/content_api.dart';
import '../services/language_api.dart';
import '../widgets/bubble_button.dart';
import '../widgets/kid_card.dart';
import '../widgets/kid_progress_bar.dart';
import '../widgets/lesson_tile.dart';
import '../widgets/mascot.dart';
import '../widgets/unlock_animation_overlay.dart';

class SubjectScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String? subSubjectId;

  const SubjectScreen({super.key, required this.subjectId, this.subSubjectId});

  @override
  ConsumerState<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends ConsumerState<SubjectScreen> {
  List<ApiLesson> _lessons = [];
  List<Map<String, dynamic>> _subSubjects = [];
  bool _loading = true;
  String? _subjectTitle;
  int _lessonCount = 0;
  Set<String> _previousUnlockState = {};
  String? _showOverlayFor;

  static const Map<String, Map<String, dynamic>> _subjectMeta = {
    'math': {
      'icon': '🧮',
      'color': 0xFFFFE8F0,
      'gradient': [0xFFFFE8F0, 0xFFFFF3E0]
    },
    'numbers': {
      'icon': '🔢',
      'color': 0xFFFFE8F0,
      'gradient': [0xFFFFE8F0, 0xFFFFF3E0]
    },
    'geometry': {
      'icon': '📐',
      'color': 0xFFE8F5E9,
      'gradient': [0xFFE8F5E9, 0xFFFFF8E1]
    },
    'measurement': {
      'icon': '📏',
      'color': 0xFFFFF3E0,
      'gradient': [0xFFFFF3E0, 0xFFFFE0EC]
    },
    'logic': {
      'icon': '🧩',
      'color': 0xFFE3F2FD,
      'gradient': [0xFFE3F2FD, 0xFFE0F2FE]
    },
    'vietnamese': {
      'icon': '🇻🇳',
      'color': 0xFFFFEBEE,
      'gradient': [0xFFFFEBEE, 0xFFFFE0EC]
    },
    'english': {
      'icon': '🇬🇧',
      'color': 0xFFE8EAF6,
      'gradient': [0xFFE8EAF6, 0xFFE0F2FE]
    },
  };

  static const List<Map<String, dynamic>> _mathSubSubjects = [
    {
      'id': 'numbers',
      'icon': '🔢',
      'nameVi': 'Số học',
      'nameEn': 'Numbers',
      'color': 0xFFFFE8F0
    },
    {
      'id': 'geometry',
      'icon': '📐',
      'nameVi': 'Hình học',
      'nameEn': 'Geometry',
      'color': 0xFFE8F5E9
    },
    {
      'id': 'measurement',
      'icon': '📏',
      'nameVi': 'Đo lường',
      'nameEn': 'Measurement',
      'color': 0xFFFFF3E0
    },
    {
      'id': 'logic',
      'icon': '🧩',
      'nameVi': 'Tư duy',
      'nameEn': 'Logic',
      'color': 0xFFE3F2FD
    },
  ];

  static UnlockTheme _themeForSubSubject(String id) {
    switch (id) {
      case 'geometry':
      case 'patterns':
        return UnlockTheme.space;
      case 'numbers':
      case 'counting':
      case 'counting_1_10':
        return UnlockTheme.jungle;
      case 'measurement':
      case 'time':
        return UnlockTheme.farm;
      case 'logic':
        return UnlockTheme.ocean;
      case 'vn_alphabet':
      case 'vietnamese':
        return UnlockTheme.castle;
      default:
        return UnlockTheme.space;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      List<ApiLesson> lessons = [];
      List<Map<String, dynamic>> subSubjects = [];
      int lessonCount = 0;
      final userGrade = ref.read(userProvider).value?.grade ?? 1;
      final l10n = AppLocalizations.of(context)!;

      if (widget.subjectId == 'math') {
        subSubjects = _mathSubSubjects;
        lessonCount = subSubjects.length;
      } else if (widget.subjectId == 'vietnamese' ||
          widget.subjectId == 'english') {
        if (widget.subSubjectId != null) {
          final curriculum = await LanguageApi.getCurriculum(
              grade: userGrade, subjectId: widget.subjectId);
          final subject = curriculum.firstWhere(
            (s) => s['subject_id'] == widget.subjectId,
            orElse: () => {},
          );
          final subSubjectsList =
              (subject['sub_subjects'] as List<dynamic>?) ?? [];
          final subSubject = subSubjectsList.firstWhere(
            (ss) => ss['sub_subject_id'] == widget.subSubjectId,
            orElse: () => {},
          );
          final rawLessons = (subSubject['lessons'] as List<dynamic>?) ?? [];
          lessons = rawLessons.map((l) {
            final lesson = l as Map<String, dynamic>;
            lesson['subject_id'] = widget.subjectId;
            return ApiLesson.fromJson(lesson);
          }).toList();
          lessonCount = lessons.length;
        } else {
          final apiSubSubjects = await LanguageApi.getSubSubjects(
              subjectId: widget.subjectId, grade: userGrade);
          Map<String, bool> unlockMap = {};
          Map<String, int> completedMap = {};
          Map<String, int> totalMap = {};

          final userId = ref.read(userProvider).value?.id;
          if (userId != null) {
            final detailed = await LanguageApi.getDetailedProgress(
                userId: userId, subjectId: widget.subjectId);
            if (detailed != null) {
              final subjects = detailed['subjects'] as List<dynamic>? ?? [];
              for (final s in subjects) {
                final ssList = s['sub_subjects'] as List<dynamic>? ?? [];
                for (final ss in ssList) {
                  final id = ss['id'] as String? ?? '';
                  unlockMap[id] = ss['is_unlocked'] == true;
                  completedMap[id] = ss['completed_lessons'] as int? ?? 0;
                  totalMap[id] = ss['total_lessons'] as int? ?? 0;
                }
              }
            }
          }

          subSubjects = apiSubSubjects.map((ss) {
            final id = ss['id'] as String;
            final isUnlocked = unlockMap[id] ?? true;
            final completed = completedMap[id] ?? 0;
            final total = totalMap[id] ?? 0;
            return {
              'id': id,
              'icon': ss['icon'] as String? ?? '📚',
              'nameVi': ss['name_vi'] as String,
              'nameEn': ss['name_en'] as String,
              'color': int.parse((ss['color'] as String? ?? '#FFE0E0')
                  .replaceFirst('#', '0xFF')),
              'isUnlocked': isUnlocked,
              'completed': completed,
              'total': total,
            };
          }).toList();

          final currentUnlocked = subSubjects
              .where((s) => s['isUnlocked'] == true)
              .map((s) => s['id'] as String)
              .toSet();
          final newlyUnlocked =
              currentUnlocked.difference(_previousUnlockState);
          if (newlyUnlocked.isNotEmpty) {
            _showOverlayFor = newlyUnlocked.first;
          }
          _previousUnlockState = currentUnlocked;

          lessonCount = subSubjects.length;
        }
      } else {
        lessons = await ContentApi.getCurriculum(grade: userGrade);
        lessons =
            lessons.where((l) => l.subjectId == widget.subjectId).toList();
        lessonCount = lessons.length;
      }

      lessons.sort((a, b) => a.order.compareTo(b.order));
      setState(() {
        _lessons = lessons;
        _subSubjects = subSubjects;
        _loading = false;
        _subjectTitle = _resolveTitle(l10n);
        _lessonCount = lessonCount;
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

  bool _isGroupingSubject() =>
      widget.subjectId == 'math' ||
      ((widget.subjectId == 'vietnamese' || widget.subjectId == 'english') &&
          widget.subSubjectId == null);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final meta = _subjectMeta[widget.subjectId] ??
        {
          'icon': '📚',
          'color': 0xFFE0E0E0,
          'gradient': const [0xFFFFE8F0, 0xFFFFF3E0]
        };
    final completedAsync = ref.watch(userProgressProvider);

    final completedSet = completedAsync.when(
      data: (set) => set,
      loading: () => <String>{},
      error: (_, __) => <String>{},
    );

    final isGrouping = _isGroupingSubject();

    if (_showOverlayFor != null) {
      final sub = _subSubjects.firstWhere(
        (s) => s['id'] == _showOverlayFor,
        orElse: () => _subSubjects.first,
      );
      final overlayColor = Color(sub['color'] as int);
      final theme = _themeForSubSubject(sub['id'] as String);
      final animEnabled = ref.read(unlockAnimationsEnabledProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _showOverlayFor != null) {
          if (!animEnabled) {
            setState(() => _showOverlayFor = null);
            return;
          }
          showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.transparent,
            builder: (_) => UnlockAnimationOverlay(
              titleVi: sub['nameVi'] as String,
              titleEn: sub['nameEn'] as String,
              accentColor: overlayColor,
              theme: theme,
              onDismiss: () {
                setState(() => _showOverlayFor = null);
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.pinkBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              meta: meta,
              title: _subjectTitle ?? _resolveTitle(l10n),
              count: _lessonCount,
              isGrouping: isGrouping,
              onBack: () => widget.subSubjectId != null
                  ? context.go('/subject/${widget.subjectId}')
                  : context.go('/home'),
            ),
            Expanded(
              child: isGrouping
                  ? _buildSubSubjectList(context, l10n)
                  : _loading
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: AppColors.pink))
                      : _lessons.isEmpty
                          ? Center(
                              child: Text(l10n.lessonNotFound,
                                  style: AppTheme.display(
                                      size: 20, color: AppColors.mutedPurple)))
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 16, 24, 32),
                              itemCount: _lessons.length,
                              itemBuilder: (context, index) {
                                final lesson = _lessons[index];
                                final isCompleted =
                                    completedSet.contains(lesson.id);
                                final isUnlocked = index == 0 ||
                                    completedSet
                                        .contains(_lessons[index - 1].id);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _KidLessonRow(
                                    lesson: lesson,
                                    isCompleted: isCompleted,
                                    isUnlocked: isUnlocked,
                                    onTap: isUnlocked
                                        ? () {
                                            final route = widget.subjectId ==
                                                        'vietnamese' ||
                                                    widget.subjectId ==
                                                        'english'
                                                ? '/language-lesson/${widget.subjectId}/${lesson.id}'
                                                : '/lesson/${widget.subjectId}/${lesson.id}';
                                            context.go(route);
                                          }
                                        : null,
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubSubjectList(BuildContext context, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context);
    final isVi = locale.languageCode == 'vi';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: _subSubjects.map((sub) {
          final title =
              isVi ? sub['nameVi'] as String : sub['nameEn'] as String;
          final isUnlocked = sub['isUnlocked'] as bool? ?? true;
          final completed = sub['completed'] as int? ?? 0;
          final total = sub['total'] as int? ?? 0;
          final completionPct = total > 0 ? (completed / total) : 0.0;
          final targetRoute = widget.subjectId == 'math'
              ? '/subject/${sub['id']}'
              : '/subject/${widget.subjectId}/${sub['id']}';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: KidCard(
              padding: const EdgeInsets.all(16),
              color: Color(sub['color'] as int)
                  .withValues(alpha: isUnlocked ? 1.0 : 0.6),
              onTap: isUnlocked ? () => context.push(targetRoute) : null,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.pinkSoft,
                            offset: Offset(0, 4),
                            blurRadius: 0)
                      ],
                    ),
                    child: Center(
                      child: isUnlocked
                          ? Text(sub['icon'] as String,
                              style: const TextStyle(fontSize: 32))
                          : const Icon(Icons.lock,
                              color: AppColors.mutedText, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTheme.display(size: 18)),
                        if (isUnlocked && total > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                  child: KidProgressBar(
                                      value: completionPct.toDouble(),
                                      color: AppColors.deepPurple,
                                      height: 10)),
                              const SizedBox(width: 8),
                              Text('$completed/$total',
                                  style: AppTheme.body(
                                      size: 12, color: AppColors.mutedPurple)),
                            ],
                          ),
                        ] else if (!isUnlocked) ...[
                          const SizedBox(height: 2),
                          Text(
                              isVi
                                  ? 'Hoàn thành chủ đề trước để mở khóa'
                                  : 'Complete previous topic to unlock',
                              style: AppTheme.body(
                                  size: 12, color: AppColors.mutedText)),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isUnlocked ? Icons.chevron_right : Icons.lock,
                    color:
                        isUnlocked ? AppColors.deepPurple : AppColors.mutedText,
                    size: 24,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Map<String, dynamic> meta;
  final String title;
  final int count;
  final bool isGrouping;
  final VoidCallback onBack;
  const _Header({
    required this.meta,
    required this.title,
    required this.count,
    required this.isGrouping,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final gradient =
        (meta['gradient'] as List?)?.map((e) => Color(e as int)).toList() ??
            const [AppColors.pinkSoft, AppColors.cream];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), offset: Offset(0, 4), blurRadius: 12)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _circleBtn(Icons.arrow_back, onBack),
              const Spacer(),
              const MiniMascot(size: 36),
              const SizedBox(width: 8),
              _circleBtn(Icons.search, () {}),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(meta['icon'] as String,
                  style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.display(size: 26)),
                    Text(
                      isGrouping ? '$count chủ đề nhỏ' : '$count bài học',
                      style:
                          AppTheme.body(size: 13, color: AppColors.mutedPurple),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
                color: AppColors.pinkSoft, offset: Offset(0, 3), blurRadius: 0)
          ],
        ),
        child: Icon(icon, color: AppColors.deepPurple, size: 20),
      ),
    );
  }
}

class _KidLessonRow extends StatelessWidget {
  final ApiLesson lesson;
  final bool isCompleted;
  final bool isUnlocked;
  final VoidCallback? onTap;
  const _KidLessonRow({
    required this.lesson,
    required this.isCompleted,
    required this.isUnlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isVi = locale.languageCode == 'vi';
    final title = isVi ? lesson.titleVi : lesson.titleEn;
    final difficultyLabel = lesson.difficulty == 1
        ? (isVi ? 'Dễ' : 'Easy')
        : lesson.difficulty == 2
            ? (isVi ? 'Vừa' : 'Medium')
            : (isVi ? 'Khó' : 'Hard');
    final diffColor = lesson.difficulty == 1
        ? AppColors.green
        : lesson.difficulty == 2
            ? AppColors.orangeText
            : AppColors.red;
    final diffBg = lesson.difficulty == 1
        ? AppColors.greenSoft
        : lesson.difficulty == 2
            ? AppColors.orangeSoft
            : const Color(0xFFFEE2E2);
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.55,
      child: KidCard(
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.greenSoft : AppColors.pinkSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: isCompleted
                    ? const Text('✅', style: TextStyle(fontSize: 24))
                    : !isUnlocked
                        ? const Icon(Icons.lock,
                            color: AppColors.mutedText, size: 24)
                        : Text('${lesson.order}',
                            style: AppTheme.display(
                                size: 22, color: AppColors.pink)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.display(size: 16)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: diffBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(difficultyLabel,
                            style: AppTheme.body(
                                size: 11,
                                color: diffColor,
                                weight: FontWeight.w800)),
                      ),
                      if (lesson.isPremium) ...[
                        const SizedBox(width: 6),
                        const Text('⭐', style: TextStyle(fontSize: 14)),
                      ],
                      if (isCompleted) ...[
                        const SizedBox(width: 6),
                        const Text('⭐⭐⭐', style: TextStyle(fontSize: 11)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              isUnlocked ? Icons.chevron_right : Icons.lock,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}
