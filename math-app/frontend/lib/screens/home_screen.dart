import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../models/persona_model.dart';
import '../providers/app_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const List<Map<String, dynamic>> _subjects = [
    {
      'icon': '🔢',
      'nameVi': 'So hoc',
      'nameEn': 'Numbers',
      'color': 0xFFFFE8F0
    },
    {
      'icon': '📐',
      'nameVi': 'Hinh hoc',
      'nameEn': 'Geometry',
      'color': 0xFFE8F5E9
    },
    {
      'icon': '📏',
      'nameVi': 'Do luong',
      'nameEn': 'Measurement',
      'color': 0xFFFFF3E0
    },
    {'icon': '🧩', 'nameVi': 'Tu duy', 'nameEn': 'Logic', 'color': 0xFFE3F2FD},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isVietnamese = locale.languageCode == 'vi';
    final persona = ref.watch(personaProvider) ?? Persona.achiever;
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) => _buildScaffold(context, ref, isVietnamese, persona, user),
      loading: () => const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryPink)),
      ),
      error: (err, _) {
        // Silently recover from user load error and show home with defaults
        return _buildScaffold(context, ref, isVietnamese, persona, null);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, WidgetRef ref, bool isVietnamese,
      Persona persona, dynamic user) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppColors.grayBg,
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout(context, ref, isVietnamese, persona, user)
            : _buildMobileLayout(context, ref, isVietnamese, persona, user),
      ),
    );
  }

  // ==================== MOBILE ====================
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref,
      bool isVietnamese, Persona persona, dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileHeader(context, user, isVietnamese),
          const SizedBox(height: 24),
          _buildContinueCard(context, isVietnamese, persona),
          const SizedBox(height: 32),
          Text(
            isVietnamese ? 'Các chủ đề' : 'Subjects',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildSubjectGrid(context, isVietnamese),
        ],
      ),
    );
  }

  // ==================== DESKTOP ====================
  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref,
      bool isVietnamese, Persona persona, dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDesktopNav(context, user, isVietnamese),
          const SizedBox(height: 32),
          Text(
            isVietnamese ? 'Hom nay hoc gi?' : "What to learn today?",
            style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.darkPurple),
          ),
          const SizedBox(height: 24),
          _buildDesktopStatsRow(context, isVietnamese, persona, user),
          const SizedBox(height: 32),
          Text(
            isVietnamese ? 'Các chủ đề' : 'Subjects',
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.darkPurple),
          ),
          const SizedBox(height: 16),
          _buildDesktopSubjectRow(context, isVietnamese),
        ],
      ),
    );
  }

  Widget _buildDesktopNav(
      BuildContext context, dynamic user, bool isVietnamese) {
    final gems = user?.gems ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('🐸', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            const Text(
              'Học Toán Vui',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkPurple),
            ),
            const SizedBox(width: 32),
            TextButton(
              onPressed: () {},
              child: Text(
                isVietnamese ? 'Chủ đề' : 'Subjects',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkPurple),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                isVietnamese ? 'Bảng giá' : 'Pricing',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkPurple),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                isVietnamese ? 'Liên hệ' : 'Contact',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkPurple),
              ),
            ),
          ],
        ),
        Row(
          children: [
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
      BuildContext context, bool isVietnamese, Persona persona, dynamic user) {
    final streak = user?.streakDays ?? 0;
    String label;
    String topic;
    switch (persona) {
      case Persona.achiever:
        label = isVietnamese ? 'Tiep tuc gianh 3 sao!' : 'Grab 3 stars!';
        topic = isVietnamese ? 'Phep cong 1 - 10' : 'Addition 1 - 10';
      case Persona.gamer:
        label = isVietnamese ? 'Kiem them 50 diem!' : 'Earn 50 points!';
        topic = isVietnamese ? 'Dem vui - Cap do 2' : 'Fun counting - Level 2';
      case Persona.struggler:
        label = isVietnamese ? 'Hom nay minh hoc gi?' : 'What today?';
        topic = isVietnamese ? 'Nhan biet so 1 - 5' : 'Numbers 1 - 5';
      case Persona.silent:
        label = isVietnamese ? 'Be san sang chua?' : 'Ready?';
        topic = isVietnamese ? 'Bắt đầu nhé' : 'Start gently';
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
                const Text('12',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPink)),
                Text(isVietnamese ? 'Bài đã học' : 'Lessons learned',
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
                const Text('3 ⭐',
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4CAF50))),
                Text(isVietnamese ? 'Sao tích lũy' : 'Stars earned',
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF666666))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: GestureDetector(
            onTap: () => context.go('/lesson/numbers/lesson_001'),
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
                Text(
                    '$streak ${isVietnamese ? 'ngày liên tiếp' : 'day streak'}',
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

  Widget _buildDesktopSubjectRow(BuildContext context, bool isVietnamese) {
    return Row(
      children: _subjects.map((subject) {
        return Expanded(
          child: GestureDetector(
            onTap: () => context.push('/subject/${subject['nameVi']}'),
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
                    isVietnamese ? subject['nameVi'] : subject['nameEn'],
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
      }).toList(),
    );
  }

  // ==================== MOBILE SHARED ====================
  Widget _buildMobileHeader(
      BuildContext context, dynamic user, bool isVietnamese) {
    final name = user?.name ?? (isVietnamese ? 'bé yêu' : 'Little friend');
    final avatar = user?.avatar ?? '🐸';
    final streak = user?.streakDays ?? 0;
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
                Text('🔥 $streak day streak',
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
      BuildContext context, bool isVietnamese, Persona persona) {
    String label;
    String topic;
    switch (persona) {
      case Persona.achiever:
        label = isVietnamese ? 'Tiep tuc gianh 3 sao!' : 'Grab 3 stars!';
        topic = isVietnamese ? 'Phep cong 1 - 10' : 'Addition 1 - 10';
      case Persona.gamer:
        label = isVietnamese ? 'Kiem them 50 diem!' : 'Earn 50 points!';
        topic = isVietnamese ? 'Dem vui - Cap do 2' : 'Fun counting - Level 2';
      case Persona.struggler:
        label = isVietnamese ? 'Hom nay minh hoc gi?' : 'What today?';
        topic = isVietnamese ? 'Nhan biet so 1 - 5' : 'Numbers 1 - 5';
      case Persona.silent:
        label = isVietnamese ? 'Be san sang chua?' : 'Ready?';
        topic = isVietnamese ? 'Bắt đầu nhé' : 'Start gently';
    }

    return GestureDetector(
      onTap: () => context.go('/lesson/numbers/lesson_001'),
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

  Widget _buildSubjectGrid(BuildContext context, bool isVietnamese) {
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
        return GestureDetector(
          onTap: () => context.push('/subject/${subject['nameVi']}'),
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
                  isVietnamese ? subject['nameVi'] : subject['nameEn'],
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
}
