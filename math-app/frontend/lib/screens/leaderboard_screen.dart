import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/leaderboard_model.dart';
import '../models/leaderboard_privacy.dart';
import '../providers/app_providers.dart';
import '../services/progress_api.dart';
import '../services/user_api.dart';
import '../widgets/kid_card.dart';
import '../widgets/mascot.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const LeaderboardScreen({super.key, this.onBack});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  List<LeaderboardEntry> _entries = [];
  bool _loading = true;
  LeaderboardEntry? _myEntry;
  bool _myEntryInList = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await UserApi.getGlobalLeaderboard();
      final myId = ref.read(userIdProvider) ?? '';
      setState(() {
        _entries = rows.map(LeaderboardEntry.fromJson).toList();
        _loading = false;
      });
      // Fetch current user's own score
      if (myId.isNotEmpty) {
        final inList = _entries.any((e) => e.id == myId);
        _myEntryInList = inList;
        if (!inList) {
          final scoreData = await ProgressApi.getUserScore(myId);
          if (scoreData != null && mounted) {
            setState(() {
              _myEntry = LeaderboardEntry(
                id: myId,
                name: scoreData['name'] as String? ?? 'Bạn',
                avatar: scoreData['avatar'] as String? ?? '🐸',
                totalScore: scoreData['total_score'] as int? ?? 0,
                weeklyStars: 0,
                lessonsCompleted: scoreData['lessons_completed'] as int? ?? 0,
              );
            });
          }
        }
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pinkBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            _buildThisWeekCard(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.pink))
                  : _entries.isEmpty && _myEntry == null
                      ? Center(
                          child: Text(
                              'Chưa có dữ liệu bảng xếp hạng toàn trường',
                              style: AppTheme.display(
                                  size: 20, color: AppColors.mutedPurple)))
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                itemCount: _entries.length,
                                itemBuilder: (context, i) {
                                  final myId = ref.read(userIdProvider) ?? '';
                                  return _Row(
                                    entry: _entries[i],
                                    rank: i + 1,
                                    isMe: _entries[i].id == myId,
                                  );
                                },
                              ),
                            ),
                            if (_myEntry != null && !_myEntryInList)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                                child: Column(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Text('· · ·',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: AppColors.mutedPurple)),
                                    ),
                                    _Row(
                                      entry: _myEntry!,
                                      rank: _entries.length + 1,
                                      isMe: true,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [AppColors.pinkSoft, AppColors.cream],
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
              const BigMascot(size: 48, emoji: '🏆'),
              const SizedBox(width: 8),
              _circleBtn(Icons.close, () => ctx.go('/home')),
            ],
          ),
          const SizedBox(height: 12),
          Text('Bảng xếp hạng', style: AppTheme.display(size: 28)),
          const SizedBox(height: 4),
          Text('Cùng bạn bè thi đua nào!',
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

  Widget _buildThisWeekCard() {
    if (_loading) return const SizedBox.shrink();
    if (_entries.isEmpty) return const SizedBox.shrink();
    final myId = ref.read(userIdProvider) ?? '';
    final rank = computeRank(
      leaderboard: _entries
          .map((e) => {'id': e.id, 'weekly_stars': e.totalScore})
          .toList(),
      userId: myId,
    );
    if (rank == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: KidCard(
        gradient: const [AppColors.pinkSoft, AppColors.cream],
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xếp hạng của bé',
                      style: AppTheme.body(
                          size: 12, color: AppColors.mutedPurple)),
                  Text(
                    'Top ${rank.percentile}%',
                    style: AppTheme.display(size: 28, color: AppColors.pink),
                  ),
                  Text(
                    'Hạng ${rank.rank} / ${rank.totalUsers} 🎉',
                    style:
                        AppTheme.body(size: 12, color: AppColors.mutedPurple),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isMe;
  const _Row({required this.entry, required this.rank, this.isMe = false});
  @override
  Widget build(BuildContext context) {
    Color medal;
    String medalStr;
    switch (rank) {
      case 1:
        medal = const Color(0xFFFFD93D);
        medalStr = '🥇';
        break;
      case 2:
        medal = const Color(0xFFD1D5DB);
        medalStr = '🥈';
        break;
      case 3:
        medal = const Color(0xFFCD7F32);
        medalStr = '🥉';
        break;
      default:
        medal = AppColors.divider;
        medalStr = '$rank';
    }
    final scoreLabel = entry.totalScore > 0
        ? '${entry.totalScore} điểm'
        : '${entry.weeklyStars} ⭐';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: KidCard(
        padding: const EdgeInsets.all(12),
        gradient: isMe ? const [AppColors.pinkSoft, AppColors.pinkSoft] : null,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: medal.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(
                    color: isMe ? AppColors.pink : medal, width: 2),
              ),
              child: rank <= 3
                  ? Text(medalStr, style: const TextStyle(fontSize: 22))
                  : Text('$rank', style: AppTheme.display(size: 16)),
            ),
            const SizedBox(width: 12),
            Text(entry.avatar, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isMe ? '${entry.name} (Bạn)' : entry.name,
                      style: AppTheme.display(size: 16)),
                  const SizedBox(height: 2),
                  Text(scoreLabel,
                      style: AppTheme.body(
                          size: 12, color: AppColors.mutedPurple)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}