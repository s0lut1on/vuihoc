import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../models/persona_model.dart';
import '../providers/app_providers.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_switcher.dart';
import '../services/review_api.dart';
import '../services/progress_api.dart';
import '../services/connectivity_service.dart';
import '../services/wrong_answer_storage.dart';
import '../widgets/offline_banner.dart';
import 'achievement_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';

import '../services/user_api.dart';
import '../utils/url_launcher.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  int? _optimisticGrade;
  final Stream<bool> _connectivityStream =
      ConnectivityService().onConnectivityChanged;

  String _resolveSubjectTitle(AppLocalizations l10n, String subjectId) {
    switch (subjectId) {
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
        return subjectId;
    }
  }

  static const List<String> _subjectIds = [
    'math',
    'vietnamese',
    'english'
  ];

  static const List<Map<String, dynamic>> _subjects = [
    {
      'icon': '🔢',
      'nameVi': 'Toán học',
      'nameEn': 'Math',
      'color': 0xFFFFE8F0
    },
    {
      'icon': '🇻🇳',
      'nameVi': 'Tiếng Việt',
      'nameEn': 'Vietnamese',
      'color': 0xFFFFEBEE
    },
    {
      'icon': '🇬🇧',
      'nameVi': 'Tiếng Anh',
      'nameEn': 'English',
      'color': 0xFFE8EAF6
    },
  ];

  @override
  Widget build(BuildContext context) {
    final persona = ref.watch(personaProvider) ?? Persona.achiever;
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) => _buildScaffold(context, ref, persona, user),
      loading: () => const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryPink)),
      ),
      error: (err, _) {
        // Silently recover from user load error and show home with defaults
        return _buildScaffold(context, ref, persona, null);
      },
    );
  }

  Widget _buildScaffold(
      BuildContext context, WidgetRef ref, Persona persona, dynamic user) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> pages = [
      isDesktop
          ? _buildDesktopHomePage(context, ref, persona, user)
          : _buildMobileHomePage(context, ref, persona, user),
      AchievementScreen(onBack: () { setState(() => _selectedIndex = 0); }),
      LeaderboardScreen(onBack: () { setState(() => _selectedIndex = 0); }),
      ProfileScreen(onBack: () { setState(() => _selectedIndex = 0); }),
    ];

    return Scaffold(
      backgroundColor: AppColors.grayBg,
      appBar: isDesktop
          ? AppBar(
              backgroundColor: AppColors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: _buildDesktopNavBar(context, ref, user, l10n),
            )
          : null,
      body: Column(
        children: [
          StreamBuilder<bool>(
            stream: _connectivityStream,
            initialData: true,
            builder: (context, snapshot) {
              if (snapshot.data == false) return const OfflineBanner();
              return const SizedBox.shrink();
            },
          ),
          Expanded(child: SafeArea(top: false, child: pages[_selectedIndex])),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              selectedItemColor: AppColors.primaryPink,
              unselectedItemColor: AppColors.mutedPurple,
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  label: l10n.homeNavSubjects,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.emoji_events_outlined),
                  activeIcon: const Icon(Icons.emoji_events),
                  label: l10n.achievementsTitle,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.leaderboard_outlined),
                  activeIcon: const Icon(Icons.leaderboard),
                  label: l10n.leaderboardTitle,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: l10n.profile,
                ),
              ],
            ),
    );
  }

  Widget _buildDesktopNavBar(
      BuildContext context, WidgetRef ref, dynamic user, AppLocalizations l10n) {
    final gems = user?.gems ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('🐸', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Text(
              l10n.appTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.darkPurple,
              ),
            ),
          ],
        ),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              child: Text(l10n.achievementsTitle,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkPurple)),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 2),
              child: Text(l10n.leaderboardTitle,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkPurple)),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 3),
              child: Text(l10n.profile,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkPurple)),
            ),
            TextButton(
              onPressed: () {
                openExternalUrl('https://web.facebook.com/profile.php?id=100064784463812');
              },
              child: Text(l10n.contactLabel,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkPurple)),
            ),
            const SizedBox(width: 16),
            Text('💎 $gems',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryPink)),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => context.push('/parent-dashboard'),
              child: const Icon(Icons.admin_panel_settings,
                  color: AppColors.mutedPurple, size: 28),
            ),
            const SizedBox(width: 12),
            const LanguageSwitcher(),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileHomePage(
      BuildContext context, WidgetRef ref, Persona persona, dynamic user) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileHeader(context, ref, user),
          const SizedBox(height: 12),
          _buildGradeSelector(context, ref, user),
          const SizedBox(height: 24),
          _buildContinueCard(context, ref, persona),
          const SizedBox(height: 16),
          _buildReviewCard(context, ref),
          const SizedBox(height: 16),
          _buildAchievementsCard(context, ref),
          const SizedBox(height: 16),
          _buildLeaderboardCard(context, ref),
          const SizedBox(height: 32),
          Text(
            l10n.homeSubjects,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildSubjectGrid(context, ref),
        ],
      ),
    );
  }

  Widget _buildDesktopHomePage(
      BuildContext context, WidgetRef ref, Persona persona, dynamic user) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeContinueStrugglerLabel,
            style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.darkPurple),
          ),
          const SizedBox(height: 16),
          _buildGradeSelector(context, ref, user),
          const SizedBox(height: 24),
          _buildDesktopStatsRow(context, ref, persona, user),
          const SizedBox(height: 24),
          _buildReviewCard(context, ref),
          const SizedBox(height: 16),
          _buildAchievementsCard(context, ref),
          const SizedBox(height: 16),
          _buildLeaderboardCard(context, ref),
          const SizedBox(height: 32),
          Text(
            l10n.homeSubjects,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.darkPurple),
          ),
          const SizedBox(height: 16),
          _buildDesktopSubjectRow(context, ref),
        ],
      ),
    );
  }

  Widget _buildDesktopNav(
      BuildContext context, WidgetRef ref, dynamic user) {
    final gems = user?.gems ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const LanguageSwitcher(),
            const SizedBox(width: 16),
            Text('💎 $gems',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryPink)),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => context.push('/parent-dashboard'),
              child: const Icon(Icons.admin_panel_settings,
                  color: AppColors.mutedPurple, size: 28),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.primaryPink),
              child: const Center(
                  child: Text('🐸', style: TextStyle(fontSize: 24))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopStatsRow(
      BuildContext context, WidgetRef ref, Persona persona, dynamic user) {
    final l10n = AppLocalizations.of(context)!;
    final streakData = ref.watch(streakProvider).valueOrNull;
    final streak = streakData?['current_streak'] ?? user?.streakDays ?? 0;
    final completed = ref.watch(userProgressProvider).valueOrNull ?? {};
    final totalStars = ref.watch(totalStarsProvider).valueOrNull ?? 0;
    final nextLesson = ref.watch(nextLessonProvider).valueOrNull;
    final nextRoute = nextLesson != null
        ? '/lesson/${nextLesson['subjectId']}/${nextLesson['lessonId']}'
        : '/lesson/numbers/lesson_n1';
    String label;
    String topic;
    switch (persona) {
      case Persona.achiever:
        label = l10n.homeContinueAchieverLabel;
        topic = l10n.homeContinueAchieverTopic;
      case Persona.gamer:
        label = l10n.homeContinueGamerLabel;
        topic = l10n.homeContinueGamerTopic;
      case Persona.struggler:
        label = l10n.homeContinueStrugglerLabel;
        topic = l10n.homeContinueStrugglerTopic;
      case Persona.silent:
        label = l10n.homeContinueSilentLabel;
        topic = l10n.homeContinueSilentTopic;
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 140,
            decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${completed.length}',
                    style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPink)),
                Text(l10n.homeLessonsLearned,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF666666))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Container(
            height: 140,
            decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$totalStars ⭐',
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4CAF50))),
                Text(l10n.homeStarsEarned,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF666666))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: GestureDetector(
            onTap: () => context.go(nextRoute),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                  color: AppColors.primaryPink,
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('▶️', style: const TextStyle(fontSize: 32)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.white)),
                  Text(topic,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Container(
            height: 140,
            decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🔥', style: const TextStyle(fontSize: 32)),
                Text(l10n.homeDayStreak(streak),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPink)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSubjectRow(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: List.generate(_subjects.length, (index) {
        final subject = _subjects[index];
        final subjectId = _subjectIds[index];
        return Expanded(
          child: GestureDetector(
            onTap: () => context.push('/subject/$subjectId'),
            child: Container(
              height: 220,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Color(subject['color'] as int),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(subject['icon'] as String,
                      style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    _resolveSubjectTitle(l10n, subjectId),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkPurple),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ==================== MOBILE SHARED ====================
  Widget _buildMobileHeader(BuildContext context, WidgetRef ref, dynamic user) {
    final l10n = AppLocalizations.of(context)!;
    final name = user?.name ?? l10n.homeDefaultName;
    final avatar = user?.avatar ?? '🐸';
    final streakData = ref.watch(streakProvider).valueOrNull;
    final streak = streakData?['current_streak'] ?? user?.streakDays ?? 0;
    final gems = user?.gems ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.primaryPink),
              child: Center(
                  child: Text(avatar, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkPurple)),
                Text(l10n.homeDayStreak(streak),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primaryPink)),
              ],
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => context.push('/parent-dashboard'),
              child: const Icon(Icons.admin_panel_settings,
                  color: AppColors.mutedPurple, size: 28),
            ),
            const SizedBox(width: 12),
            const LanguageSwitcher(),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                openExternalUrl('https://web.facebook.com/profile.php?id=100064784463812');
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.contactLabel,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkPurple)),
            ),
            const SizedBox(width: 12),
            const Text('💎', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 4),
            Text('$gems',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryPink)),
          ],
        ),
      ],
    );
  }

  Widget _buildContinueCard(
      BuildContext context, WidgetRef ref, Persona persona) {
    final l10n = AppLocalizations.of(context)!;
    final nextLesson = ref.watch(nextLessonProvider).valueOrNull;
    final nextRoute = nextLesson != null
        ? '/lesson/${nextLesson['subjectId']}/${nextLesson['lessonId']}'
        : '/lesson/numbers/lesson_n1';
    String label;
    String topic;
    switch (persona) {
      case Persona.achiever:
        label = l10n.homeContinueAchieverLabel;
        topic = l10n.homeContinueAchieverTopic;
      case Persona.gamer:
        label = l10n.homeContinueGamerLabel;
        topic = l10n.homeContinueGamerTopic;
      case Persona.struggler:
        label = l10n.homeContinueStrugglerLabel;
        topic = l10n.homeContinueStrugglerTopic;
      case Persona.silent:
        label = l10n.homeContinueSilentLabel;
        topic = l10n.homeContinueSilentTopic;
    }

    return GestureDetector(
      onTap: () => context.go(nextRoute),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.primaryPink,
            borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const Text('▶️', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.white.withValues(alpha: 0.9))),
                  const SizedBox(height: 4),
                  Text(topic,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<int>(
      future: _reviewCount(ref),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => context.go('/review'),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF9800)),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.reviewCardLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkPurple.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.reviewCardTopic,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: const Color(0xFFFF9800),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<int> _reviewCount(WidgetRef ref) async {
    final userId = ref.read(userIdProvider) ?? '';
    if (userId.isEmpty) return 0;
    try {
      final remote = await ProgressApi.getReviewSession(userId);
      final dueCount = remote.fold<int>(0, (sum, e) => sum + ((e['wrong_count'] as int?) ?? 0)) ~/ 2 + 1;
      return remote.length;
    } catch (_) {
      return 0;
    }
  }

  Widget _buildSubjectGrid(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _subjects.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        final subjectId = _subjectIds[index];
        return GestureDetector(
          onTap: () => context.push('/subject/$subjectId'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Color(subject['color'] as int),
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(subject['icon'] as String,
                    style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Text(
                  _resolveSubjectTitle(l10n, subjectId),
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.darkPurple),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementsCard(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/achievements'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF9C27B0)),
        ),
        child: Row(
          children: [
            const Text('🏅', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Huy chương',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkPurple,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Xem huy chương của bạn',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkPurple,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.darkPurple),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardCard(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/leaderboard'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4CAF50)),
        ),
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bảng xếp hạng',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkPurple,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Top bạn bè tuần này',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkPurple,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.darkPurple),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeSelector(BuildContext context, WidgetRef ref, dynamic user) {
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(userProvider);
    final liveUser = userAsync.value ?? user;
    final grade = _optimisticGrade ?? liveUser?.grade ?? 1;
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [1, 2, 3].map((g) {
        final isSelected = g == grade;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: ElevatedButton(
              onPressed: () async {
                if (isSelected) return;
                setState(() => _optimisticGrade = g);
                try {
                  await UserApi.updateGrade(g);
                  await ref.read(userProvider.notifier).refreshUser();
                  ref.invalidate(curriculumProvider(g));
                  if (mounted) {
                    setState(() => _optimisticGrade = null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isVi ? 'Đã chuyển sang lớp $g!' : 'Switched to Grade $g!',
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: AppColors.primaryPink,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _optimisticGrade = null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isVi ? 'Lỗi: $e' : 'Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? AppColors.primaryPink : AppColors.white,
                foregroundColor: isSelected ? AppColors.white : AppColors.darkPurple,
                elevation: isSelected ? 4 : 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryPink : const Color(0xFFE0E0E0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
              ),
              child: Text(
                isVi ? 'Lớp $g' : 'Grade $g',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
