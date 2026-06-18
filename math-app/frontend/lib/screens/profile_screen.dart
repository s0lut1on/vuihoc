import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../services/user_api.dart';
import '../widgets/bubble_button.dart';
import '../widgets/kid_card.dart';
import '../widgets/kid_nav_bar.dart';
import '../widgets/mascot.dart';

class ProfileScreen extends ConsumerWidget {
  final VoidCallback? onBack;
  const ProfileScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentUserAsync = ref.watch(currentUserProvider);
    final userAsync = ref.watch(userProvider);

    final name = currentUserAsync.value?['name'] as String? ??
        (l10n?.guestUser ?? 'Bé ẩn danh');
    final email = currentUserAsync.value?['email'] as String? ?? '';
    final picture = currentUserAsync.value?['picture'] as String? ?? '';
    final isGuest = email.startsWith('guest_');

    final stats = userAsync.valueOrNull;
    final lessons = stats?.totalLessons ?? 0;
    final stars = stats?.totalStars ?? 0;
    final streak = stats?.streakDays ?? 0;

    return Scaffold(
      backgroundColor: AppColors.pinkBg,
      body: SafeArea(
        child: Column(
          children: [
            KidNavBar(
              trailing: GestureDetector(
                onTap: () => context.go('/home'),
                child: const Icon(Icons.close,
                    color: AppColors.deepPurple, size: 24),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  children: [
                    _buildAvatar(name, picture, isGuest),
                    const SizedBox(height: 16),
                    Text(name, style: AppTheme.display(size: 32)),
                    const SizedBox(height: 4),
                    Text(
                      email.isNotEmpty
                          ? email
                          : (isGuest ? (l10n?.guestUser ?? 'Học thử') : ''),
                      style:
                          AppTheme.body(size: 14, color: AppColors.mutedPurple),
                    ),
                    const SizedBox(height: 24),
                    // 3 stat cards
                    Row(
                      children: [
                        Expanded(
                            child: _StatCard(
                                emoji: '📚',
                                value: lessons,
                                label: l10n?.profileStatLessons ?? 'Bài học',
                                color: AppColors.purple,
                                bg: AppColors.pinkSoft)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _StatCard(
                                emoji: '⭐',
                                value: stars,
                                label: l10n?.profileStatStars ?? 'Sao',
                                color: AppColors.orangeText,
                                bg: AppColors.orangeSoft)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _StatCard(
                                emoji: '🔥',
                                value: streak,
                                label: l10n?.profileStatStreak ?? 'Ngày',
                                color: AppColors.red,
                                bg: AppColors.cream)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTtsTile(context, ref),
                    const SizedBox(height: 8),
                    _buildGradeTile(context, ref),
                    const SizedBox(height: 24),
                    BubbleButton(
                      label: l10n?.logout ?? 'Đăng xuất',
                      emoji: '👋',
                      onPressed: () => _handleLogout(context, ref),
                      minWidth: 200,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String picture, bool isGuest) {
    if (picture.isNotEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.pink, width: 4),
          boxShadow: const [
            BoxShadow(
                color: AppColors.pinkDark, offset: Offset(0, 6), blurRadius: 0)
          ],
        ),
        child: ClipOval(
          child: Image.network(picture,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const BigMascot(size: 100)),
        ),
      );
    }
    return const BigMascot(size: 110);
  }

  Widget _buildTtsTile(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isEnabled = ref.watch(ttsEnabledProvider);
    return KidCard(
      onTap: () {
        ref.read(ttsEnabledProvider.notifier).state = !isEnabled;
        LocalStorageService.saveTtsEnabled(!isEnabled);
      },
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isEnabled ? AppColors.pinkSoft : AppColors.grayBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(isEnabled ? Icons.volume_up : Icons.volume_off,
                color: AppColors.deepPurple, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n?.settingsTtsTitle ?? 'Đọc câu hỏi',
                    style: AppTheme.display(size: 16)),
                Text(l10n?.settingsTtsSubtitle ?? 'Tự đọc to bài tập',
                    style:
                        AppTheme.body(size: 12, color: AppColors.mutedPurple)),
              ],
            ),
          ),
          Switch(
              value: isEnabled,
              activeThumbColor: AppColors.pink,
              onChanged: (v) {
                ref.read(ttsEnabledProvider.notifier).state = v;
                LocalStorageService.saveTtsEnabled(v);
              }),
        ],
      ),
    );
  }

  Widget _buildGradeTile(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(userProvider).valueOrNull;
    final grade = user?.grade ?? 1;
    final isVi =
        l10n != null && Localizations.localeOf(context).languageCode == 'vi';

    return KidCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: AppColors.pinkSoft,
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.school_outlined,
                color: AppColors.deepPurple, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(isVi ? 'Lớp học' : 'Grade',
                style: AppTheme.display(size: 16)),
          ),
          ...[1, 2, 3].map((g) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: g == grade
                      ? null
                      : () async {
                          try {
                            final updated = await UserApi.updateGrade(g);
                            // Push the new User straight into the
                            // StateNotifier so the UI updates immediately.
                            // Without this, userProvider stays at the
                            // previous value (often null for guest users)
                            // and the chip stays on grade 1.
                            if (context.mounted) {
                              ref.read(userProvider.notifier).setUser(updated);
                              // Invalidate everything that depends on grade
                              // so subjects / curriculum / sub-subjects /
                              // progress all reload for the new grade.
                              // NOTE: do NOT invalidate userProvider here —
                              // that creates a fresh StateNotifier that
                              // doesn't know about our setUser call, and
                              // the UI would flicker back to grade 1.
                              ref.invalidate(curriculumProvider(g));
                              ref.invalidate(subjectsProvider(g));
                              ref.invalidate(rawProgressProvider);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(isVi
                                    ? 'Đã chuyển sang lớp $g'
                                    : 'Grade $g'),
                              ));
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    isVi ? 'Chuyển lớp thất bại' : 'Failed'),
                              ));
                            }
                          }
                        },
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: g == grade ? AppColors.pink : AppColors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color:
                              g == grade ? AppColors.pink : AppColors.divider,
                          width: 2),
                    ),
                    child: Text('$g',
                        style: AppTheme.display(
                            size: 14,
                            color: g == grade
                                ? AppColors.white
                                : AppColors.deepPurple)),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    AuthService().signOut();
    ref.invalidate(currentUserProvider);
    ref.invalidate(userProvider);
    ref.invalidate(userIdProvider);
    if (context.mounted) {
      context.go('/login');
    }
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final int value;
  final String label;
  final Color color;
  final Color bg;
  const _StatCard(
      {required this.emoji,
      required this.value,
      required this.label,
      required this.color,
      required this.bg});
  @override
  Widget build(BuildContext context) {
    return KidCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      color: bg,
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text('$value', style: AppTheme.display(size: 24, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTheme.body(size: 11, color: AppColors.mutedPurple),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
