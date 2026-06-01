import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Color _avatarColor(String name) {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.blueGrey,
    ];
    int hash = 0;
    for (final code in name.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentUserAsync = ref.watch(currentUserProvider);
    final userAsync = ref.watch(userProvider);

    final name = currentUserAsync.value?['name'] as String? ??
        (l10n?.guestUser ?? 'Guest');
    final email = currentUserAsync.value?['email'] as String? ?? '';
    final picture = currentUserAsync.value?['picture'] as String? ?? '';
    final isGuest = email.startsWith('guest_');

    final stats = userAsync.valueOrNull;
    final lessons = stats?.totalLessons ?? 0;
    final stars = stats?.totalStars ?? 0;
    final streak = stats?.streakDays ?? 0;

    return Scaffold(
      backgroundColor: AppColors.lightPinkBg,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkPurple),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          l10n?.profileTitle ?? 'Profile',
          style: const TextStyle(
            color: AppColors.darkPurple,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildAvatar(name, picture, isGuest),
            const SizedBox(height: 16),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.darkPurple,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              email.isNotEmpty
                  ? email
                  : (isGuest ? (l10n?.guestUser ?? 'Guest') : ''),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedPurple,
                  ),
            ),
            const SizedBox(height: 24),
            _buildStatsRow(context, lessons, stars, streak),
            const SizedBox(height: 32),
            _buildMenuTile(
              icon: Icons.settings_outlined,
              title: l10n?.settings ?? 'Settings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n?.comingSoon ?? 'Coming soon')),
                );
              },
            ),
            _buildTtsTile(context, ref),
            const SizedBox(height: 8),
            _buildMenuTile(
              icon: Icons.logout,
              title: l10n?.logout ?? 'Logout',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () => _handleLogout(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String picture, bool isGuest) {
    if (picture.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('ProfileScreen avatar picture URL: $picture');
      }
      return CircleAvatar(
        radius: 50,
        child: ClipOval(
          child: Image.network(
            picture,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              if (kDebugMode) {
                debugPrint(
                    'ProfileScreen avatar image error for $name: $error');
              }
              return _buildInitialAvatar(name, 50);
            },
          ),
        ),
      );
    }
    return _buildInitialAvatar(name, 50);
  }

  Widget _buildInitialAvatar(String name, double radius) {
    final color = _avatarColor(name);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatsRow(
      BuildContext context, int lessons, int stars, int streak) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(Icons.menu_book_outlined, lessons.toString(),
              l10n?.profileStatLessons ?? 'Lessons'),
          _buildStatItem(Icons.star_outline, stars.toString(),
              l10n?.profileStatStars ?? 'Stars'),
          _buildStatItem(Icons.local_fire_department_outlined,
              streak.toString(), l10n?.profileStatStreak ?? 'Streak'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryPink, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkPurple,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.mutedPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildTtsTile(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isEnabled = ref.watch(ttsEnabledProvider);
    return ListTile(
      leading: Icon(
        isEnabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
        color: AppColors.darkPurple,
      ),
      title: Text(
        l10n?.settingsTtsTitle ?? 'Read question aloud',
        style: const TextStyle(
          color: AppColors.darkPurple,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        l10n?.settingsTtsSubtitle ?? 'Auto-read questions during lessons',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.mutedPurple,
        ),
      ),
      trailing: Switch(
        value: isEnabled,
        activeThumbColor: AppColors.primaryPink,
        onChanged: (value) {
          ref.read(ttsEnabledProvider.notifier).state = value;
          LocalStorageService.saveTtsEnabled(value);
        },
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.darkPurple),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppColors.darkPurple,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.mutedPurple),
      onTap: onTap,
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
