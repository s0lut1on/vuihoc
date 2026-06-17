import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/leaderboard_model.dart';
import '../models/leaderboard_privacy.dart';
import '../providers/app_providers.dart';
import '../services/user_api.dart';
import '../widgets/bubble_button.dart';
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
  final _classroomCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _classroomCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await UserApi.getLeaderboard();
      setState(() {
        _entries = rows.map(LeaderboardEntry.fromJson).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    try {
      await UserApi.joinClassroom(_classroomCtrl.text.trim());
      _load();
    } catch (_) {}
  }

  Future<void> _leave() async {
    try {
      await UserApi.leaveClassroom();
      _load();
    } catch (_) {}
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
            _buildJoinCard(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.pink))
                  : _entries.isEmpty
                      ? Center(
                          child: Text('Chưa có dữ liệu bảng xếp hạng',
                              style: AppTheme.display(
                                  size: 20, color: AppColors.mutedPurple)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: _entries.length,
                          itemBuilder: (context, i) =>
                              _Row(entry: _entries[i], rank: i + 1),
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
      leaderboard: _entries.map((e) => {'id': e.id, 'weekly_stars': e.weeklyStars}).toList(),
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
                  Text('Tuần này của bé', style: AppTheme.body(size: 12, color: AppColors.mutedPurple)),
                  Text(
                    'Top ${rank.percentile}%',
                    style: AppTheme.display(size: 28, color: AppColors.pink),
                  ),
                  Text(
                    'Hạng ${rank.rank} / ${rank.totalUsers} bạn cùng lớp 🎉',
                    style: AppTheme.body(size: 12, color: AppColors.mutedPurple),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: KidCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏫 Mã lớp học', style: AppTheme.display(size: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: _classroomCtrl,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Nhập mã 6 ký tự',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BubbleButton(
                  label: 'Tham gia',
                  emoji: '🚀',
                  height: 44,
                  minWidth: 120,
                  fontSize: 14,
                  onPressed: _join,
                ),
                const SizedBox(width: 8),
                BubbleButton.secondary(
                  label: 'Rời lớp',
                  height: 44,
                  minWidth: 100,
                  fontSize: 14,
                  onPressed: _leave,
                ),
              ],
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
  const _Row({required this.entry, required this.rank});
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: KidCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: medal.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: medal, width: 2),
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
                  Text(anonymizeName(entry.name), style: AppTheme.display(size: 16)),
                  const SizedBox(height: 2),
                  Text('${entry.weeklyStars} ⭐ tuần này',
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
