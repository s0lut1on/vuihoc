import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/build_info.dart';
import '../l10n/app_localizations.dart';
import '../models/lesson_model.dart';
import '../providers/app_providers.dart';
import '../services/local_storage_service.dart';
import '../services/daily_limit.dart';
import '../widgets/bubble_button.dart';
import '../widgets/kid_card.dart';
import '../widgets/kid_nav_bar.dart';
import '../widgets/mascot.dart';
import '../widgets/pricing_banner.dart';
import '../widgets/subject_tile.dart';
import '../widgets/streak_badge.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(userProvider).value;
    final streakAsync = ref.watch(streakProvider);
    // React to grade changes — this refetches the curriculum for the
    // new grade, which in turn refreshes the lesson counts shown in
    // each SubjectTile and the Continue card.
    final userGrade = user?.grade ?? 1;
    final curriculumAsync = ref.watch(curriculumProvider(userGrade));
    final languageSubjectsAsync = ref.watch(languageSubjectsProvider(userGrade));
    return Scaffold(
      backgroundColor: AppColors.pinkBg,
      body: SafeArea(
        child: Column(
          children: [
            KidNavBar(
              activeLabel: 'Chủ đề',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreakBadge(
                    days:
                        (streakAsync.valueOrNull?['current_streak'] as int?) ??
                            0,
                    onTap: () => context.go('/achievements'),
                  ),
                  const SizedBox(width: 8),
                  const _NavRight(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(48, 16, 48, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phase C: dismissible pricing banner (visible when
                    // daily limit hit + not Premium + last dismiss > 24h ago).
                    const PricingBanner(),
                    // Continue card + 2 stats
                    LayoutBuilder(builder: (context, c) {
                      final wide = c.maxWidth > 900;
                      final continueCard = _ContinueCard(user: user);
                      if (wide) {
                        return Row(
                          children: [
                            Expanded(flex: 2, child: continueCard),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _StreakCard(streakAsync.valueOrNull)),
                            const SizedBox(width: 16),
                            Expanded(child: _StarsCard(user)),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          continueCard,
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                  child: _StreakCard(streakAsync.valueOrNull)),
                              const SizedBox(width: 12),
                              Expanded(child: _StarsCard(user)),
                            ],
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 12),
                    // 4-up stat row
                    LayoutBuilder(builder: (context, c) {
                      final cards = [
                        _Stat(
                            emoji: '🏆',
                            value: '3',
                            label: l10n.parentDashboardSubjectMath,
                            valueColor: AppColors.purple,
                            gradient: const [
                              AppColors.cream,
                              AppColors.pinkSoft
                            ]),
                        _Stat(
                            emoji: '💎',
                            value: '45',
                            label: 'Viên ngọc',
                            valueColor: AppColors.green,
                            gradient: const [
                              AppColors.greenSoft,
                              AppColors.cream
                            ]),
                        _Stat(
                            emoji: '⏱️',
                            value: '2.5h',
                            label: 'Tuần này',
                            valueColor: const Color(0xFF2563EB),
                            gradient: const [Color(0xFFDBEAFE), AppColors.sky]),
                      ];
                      return Row(
                        children: [
                          for (var i = 0; i < cards.length; i++) ...[
                            Expanded(child: cards[i]),
                            if (i != cards.length - 1)
                              const SizedBox(width: 12),
                          ],
                        ],
                      );
                    }),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text('${l10n.homeSubjects} 🎯',
                            style: AppTheme.display(size: 26)),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.emoji_events,
                              color: AppColors.purple),
                          onSelected: (v) {
                            if (v == 'achievements')
                              context.go('/achievements');
                            if (v == 'leaderboard') context.go('/leaderboard');
                            if (v == 'profile') context.go('/profile');
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'achievements',
                                child: Text('Huy chương')),
                            PopupMenuItem(
                                value: 'leaderboard',
                                child: Text('Bảng xếp hạng')),
                            PopupMenuItem(
                                value: 'profile', child: Text('Hồ sơ')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(builder: (context, c) {
                      final cols =
                          c.maxWidth > 1100 ? 4 : (c.maxWidth > 700 ? 3 : 2);
                      return _subjectsGrid(cols, curriculumAsync, languageSubjectsAsync, userGrade);
                    }),
                    const SizedBox(height: 24),
                    const _BuildVersionFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subjectsGrid(int cols, AsyncValue<List<ApiLesson>> curriculum, AsyncValue<List<Map<String, dynamic>>> languageSubjects, int userGrade) {
    final subjects = _buildSubjects(curriculum.valueOrNull ?? const [], languageSubjects.valueOrNull ?? const [], userGrade);
    return GridView.count(
      crossAxisCount: cols,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: subjects,
    );
  }

  List<Widget> _buildSubjects(List<ApiLesson> lessons, List<Map<String, dynamic>> languageSubjects, int userGrade) {
    // Group curriculum lessons by subject_id so the tiles show real
    // per-grade counts. When the user changes grade in Profile, this
    // rebuilds with the new grade's curriculum (curriculumProvider is
    // a family keyed on grade).
    final bySubject = <String, int>{};
    for (final l in lessons) {
      bySubject[l.subjectId] = (bySubject[l.subjectId] ?? 0) + 1;
    }
    // Merge language subjects (Vietnamese / English) counts from the
    // language API. Keys are 'vietnamese' and 'english' matching tile ids.
    for (final s in languageSubjects) {
      final id = s['id'] as String?;
      final count = s['lesson_count'] as int?;
      if (id != null && count != null) {
        bySubject[id] = count;
      }
    }
    // Each subject has a `gradeMin` — the lowest grade that can take
    // it. Tiles below the user's grade are hidden entirely; tiles at
    // or above the user's grade are shown. Lesson counts come from the
    // backend (live curriculum).
    final all = [
      _SubjectMeta(
          id: 'numbers',
          emoji: '🔢',
          nameVi: 'Số học',
          nameEn: 'Numbers',
          gradeMin: 1,
          path: '/subject/numbers'),
      _SubjectMeta(
          id: 'geometry',
          emoji: '📐',
          nameVi: 'Hình học',
          nameEn: 'Geometry',
          gradeMin: 1,
          path: '/subject/geometry'),
      _SubjectMeta(
          id: 'measurement',
          emoji: '📏',
          nameVi: 'Đo lường',
          nameEn: 'Measurement',
          gradeMin: 1,
          path: '/subject/measurement'),
      _SubjectMeta(
          id: 'logic',
          emoji: '🧩',
          nameVi: 'Tư duy',
          nameEn: 'Logic',
          gradeMin: 1,
          path: '/subject/logic'),
      // Grade 2 unlocks: algebra (extends Numbers with variables & equations).
      _SubjectMeta(
          id: 'algebra',
          emoji: '🅰️',
          nameVi: 'Đại số',
          nameEn: 'Algebra',
          gradeMin: 2,
          path: '/subject/algebra'),
      // Grade 3 unlocks: trigonometry (extends Geometry with sin/cos/tan).
      _SubjectMeta(
          id: 'trigonometry',
          emoji: '📐',
          nameVi: 'Lượng giác',
          nameEn: 'Trigonometry',
          gradeMin: 3,
          path: '/subject/trigonometry'),
      // Grade 4 unlocks: statistics (Thống kê — data tables, charts, mean).
      _SubjectMeta(
          id: 'statistics',
          emoji: '📊',
          nameVi: 'Thống kê',
          nameEn: 'Statistics',
          gradeMin: 4,
          path: '/subject/statistics'),
      _SubjectMeta(
          id: 'vietnamese',
          emoji: '🇻🇳',
          nameVi: 'Tiếng Việt',
          nameEn: 'Vietnamese',
          gradeMin: 1,
          path: '/subject/vietnamese'),
      _SubjectMeta(
          id: 'english',
          emoji: '🇬🇧',
          nameVi: 'Tiếng Anh',
          nameEn: 'English',
          gradeMin: 1,
          path: '/subject/english'),
    ];
    return [
      for (final s in all.where((s) => s.gradeMin <= userGrade))
        if ((bySubject[s.id] ?? 0) > 0)
          SubjectTile(
              id: s.id,
              emoji: s.emoji,
              nameVi: s.nameVi,
              nameEn: s.nameEn,
              lessonCount: bySubject[s.id] ?? 0,
              gradeMin: s.gradeMin,
              onTap: () => context.go(s.path)),
    ];
  }
}

/// Lightweight metadata for the home-screen subject grid. Kept here
/// (not in a model file) because this list is the single source of
/// truth for what subjects are in the home grid; backend models don't
/// duplicate this decision.
class _SubjectMeta {
  final String id;
  final String emoji;
  final String nameVi;
  final String nameEn;
  final int gradeMin;
  final String path;
  const _SubjectMeta({
    required this.id,
    required this.emoji,
    required this.nameVi,
    required this.nameEn,
    required this.gradeMin,
    required this.path,
  });
}

class _NavRight extends ConsumerWidget {
  const _NavRight();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => context.push('/achievements'),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('🏅', style: TextStyle(fontSize: 22)),
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/leaderboard'),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('🏆', style: TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: const MiniMascot(size: 40),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final dynamic user;
  const _ContinueCard({this.user});
  @override
  Widget build(BuildContext context) {
    return KidCard(
      gradient: const [AppColors.pinkSoft, AppColors.cream],
      onTap: () => context.go('/subject/numbers'),
      child: Row(
        children: [
          const BigMascot(size: 80, wiggle: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user?.name ?? 'Bé An'} ơi!',
                    style: AppTheme.display(size: 22)),
                const SizedBox(height: 4),
                Text('Tiếp tục: Phép cộng 2 chữ số',
                    style:
                        AppTheme.body(size: 14, color: AppColors.mutedPurple)),
                const SizedBox(height: 8),
                BubbleButton(
                  label: 'Học tiếp thôi! 🚀',
                  minWidth: 140,
                  height: 44,
                  fontSize: 14,
                  onPressed: () => context.go('/subject/numbers'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  const _StreakCard(this.data);
  @override
  Widget build(BuildContext context) {
    final days = (data?['current_streak'] as int?) ?? 0;
    return _Stat(
      emoji: '🔥',
      value: '$days',
      label: 'Ngày liên tiếp',
      valueColor: AppColors.red,
    );
  }
}

class _StarsCard extends StatelessWidget {
  final dynamic user;
  const _StarsCard(this.user);
  @override
  Widget build(BuildContext context) {
    return _Stat(
      emoji: '⭐',
      value: '${user?.totalStars ?? 0}',
      label: 'Sao tích lũy',
      valueColor: AppColors.orange,
    );
  }
}

class _Stat extends StatelessWidget {
  final String emoji, value, label;
  final Color? valueColor;
  final List<Color>? gradient;
  const _Stat({
    required this.emoji,
    required this.value,
    required this.label,
    this.valueColor,
    this.gradient,
  });
  @override
  Widget build(BuildContext context) {
    return KidCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      gradient: gradient,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTheme.display(
                  size: 30, color: valueColor ?? AppColors.pink)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTheme.body(size: 12, color: AppColors.mutedPurple)),
        ],
      ),
    );
  }
}

/// Subtle build-identifier strip at the bottom of the home screen. Lets
/// the user (and us, when triaging a bug report) verify which build is
/// actually deployed — critical when the CDN edge or browser cache is
/// serving an older bundle than `main`.
class _BuildVersionFooter extends StatelessWidget {
  const _BuildVersionFooter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐸', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 6),
            Text(
              'HocVui $kBuildVersion',
              style: AppTheme.body(
                  size: 11,
                  color: AppColors.mutedPurple,
                  weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
