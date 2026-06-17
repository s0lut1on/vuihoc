import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/achievement_model.dart';
import '../services/achievement_service.dart';
import '../providers/app_providers.dart';
import '../widgets/mascot.dart';

class AchievementScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const AchievementScreen({super.key, this.onBack});

  @override
  ConsumerState<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends ConsumerState<AchievementScreen> {
  List<Achievement> _badges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = ref.read(userIdProvider);
    if (userId == null || userId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final rows = await AchievementService.getAchievements(userId);
    final badges = rows.map(Achievement.fromJson).toList();
    setState(() {
      _badges = badges;
      _loading = false;
    });
    final newBadges = badges.where((b) => b.isNew).toList();
    if (newBadges.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🏅 ${newBadges.length} huy chương mới!'),
        duration: const Duration(seconds: 3),
        backgroundColor: AppColors.orange,
      ));
    }
  }

  Future<void> _markRead(String badgeType) async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    await AchievementService.markRead(userId, badgeType);
    setState(() {
      final idx = _badges.indexWhere((b) => b.badgeType == badgeType);
      if (idx >= 0) {
        _badges[idx] = Achievement(
          badgeType: _badges[idx].badgeType,
          earnedAt: _badges[idx].earnedAt,
          isNew: false,
          name: _badges[idx].name,
          description: _badges[idx].description,
          icon: _badges[idx].icon,
          threshold: _badges[idx].threshold,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final earned = _badges.where((b) => b.isEarned).length;
    return Scaffold(
      backgroundColor: AppColors.pinkBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(context, earned, _badges.length),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.pink))
                  : _badges.isEmpty
                      ? Center(
                          child: Text('Chưa có huy chương nào',
                              style: AppTheme.display(
                                  size: 20, color: AppColors.mutedPurple)))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _badges.length,
                          itemBuilder: (context, i) => _BadgeTile(
                            badge: _badges[i],
                            onTap: _badges[i].isNew
                                ? () => _markRead(_badges[i].badgeType)
                                : null,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext ctx, int earned, int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [AppColors.orangeSoft, AppColors.pinkSoft],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _circleBtn(Icons.arrow_back, () {
                if (widget.onBack != null)
                  widget.onBack!();
                else if (ctx.canPop())
                  ctx.pop();
                else
                  ctx.go('/home');
              }),
              const Spacer(),
              const BigMascot(size: 48, emoji: '🏅'),
              const SizedBox(width: 8),
              _circleBtn(Icons.close, () => ctx.go('/home')),
            ],
          ),
          const SizedBox(height: 16),
          Text('Huy chương của bé', style: AppTheme.display(size: 28)),
          const SizedBox(height: 4),
          Text('Đã có: $earned / $total',
              style: AppTheme.body(size: 14, color: AppColors.mutedPurple)),
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

class _BadgeTile extends StatelessWidget {
  final Achievement badge;
  final VoidCallback? onTap;
  const _BadgeTile({required this.badge, this.onTap});
  @override
  Widget build(BuildContext context) {
    final earned = badge.isEarned;
    final isNew = badge.isNew;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: earned ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: earned ? AppColors.cream : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isNew ? AppColors.pink : AppColors.divider,
                width: isNew ? 3 : 2),
            boxShadow: [
              BoxShadow(
                color: earned ? AppColors.pinkSoft : Colors.transparent,
                offset: const Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(badge.icon, style: const TextStyle(fontSize: 48)),
                  if (isNew)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.pink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('MỚI',
                            style: AppTheme.body(
                                size: 9,
                                color: AppColors.white,
                                weight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(badge.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTheme.display(
                      size: 11,
                      color:
                          earned ? AppColors.deepPurple : AppColors.mutedText)),
              const SizedBox(height: 2),
              Text(badge.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTheme.body(size: 9, color: AppColors.mutedPurple)),
            ],
          ),
        ),
      ),
    );
  }
}
