import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../services/auth_service.dart';

class ProfileWidget extends ConsumerWidget {
  const ProfileWidget({super.key});

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

    return currentUserAsync.when(
      data: (userData) {
        final name = userData?['name'] as String? ?? (l10n?.guestUser ?? 'Guest');
        final picture = userData?['picture'] as String? ?? '';
        final isGuest = name == (l10n?.guestUser ?? 'Guest') ||
            (userData?['email'] as String? ?? '').startsWith('guest_');

        return PopupMenuButton<String>(
          offset: const Offset(0, 40),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAvatar(name, picture, isGuest),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkPurple,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.mutedPurple,
                  ),
                ],
              ),
            ),
          ),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                context.go('/profile');
                break;
              case 'settings':
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n?.comingSoon ?? 'Coming soon')),
                );
                break;
              case 'logout':
                _handleLogout(context, ref);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n?.profile ?? 'Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  const Icon(Icons.settings_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n?.settings ?? 'Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(l10n?.logout ?? 'Logout', style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => _buildGuestAvatar(l10n?.guestUser ?? 'Guest'),
    );
  }

  Widget _buildAvatar(String name, String picture, bool isGuest) {
    if (picture.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(picture),
        onBackgroundImageError: (_, __) {},
      );
    }

    final color = _avatarColor(name);
    return CircleAvatar(
      radius: 16,
      backgroundColor: color,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildGuestAvatar(String guestName) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[400],
      child: const Text(
        '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
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
