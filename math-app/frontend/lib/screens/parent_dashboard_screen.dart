import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../services/language_api.dart';
import '../services/local_storage_service.dart';
import '../widgets/language_switcher.dart';
import '../widgets/mascot.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  List<Map<String, dynamic>> _subjects = [];
  bool _loading = true;
  final _emailCtrl = TextEditingController();
  String _emailFrequency = 'never';
  bool _emailInitialized = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEmailPrefs() async {
    final email = await LocalStorageService.getParentEmail();
    final freq = await LocalStorageService.getEmailFrequency();
    if (mounted) {
      setState(() {
        _emailCtrl.text = email;
        _emailFrequency = freq;
        _emailInitialized = true;
      });
    }
  }

  Future<void> _saveEmail() async {
    await LocalStorageService.saveParentEmail(_emailCtrl.text.trim());
  }

  Future<void> _saveFrequency(String freq) async {
    setState(() => _emailFrequency = freq);
    await LocalStorageService.saveEmailFrequency(freq);
  }

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadEmailPrefs();
  }

  Future<void> _loadProgress() async {
    final user = ref.read(userProvider).value;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await LanguageApi.getDetailedProgress(userId: user.id);
      if (data != null) {
        final subjects = data['subjects'] as List<dynamic>? ?? [];
        setState(() {
          _subjects = subjects.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppColors.pinkBg,
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout(context, l10n)
            : _buildMobileLayout(context, l10n),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, l10n),
          const SizedBox(height: 32),
          _buildStatsCards(l10n),
          const SizedBox(height: 32),
          _buildChildProgress(l10n),
          const SizedBox(height: 32),
          _buildSettings(l10n),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDesktopNav(context, l10n),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildStatsCards(l10n),
                    const SizedBox(height: 32),
                    _buildChildProgress(l10n),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 1,
                child: _buildSettings(l10n),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNav(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('🐸', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Text(
              l10n.appTitle,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkPurple),
            ),
          ],
        ),
        Row(
          children: [
            const LanguageSwitcher(),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.go('/home'),
              child: Text(
                l10n.parentDashboardBackToHome,
                style: const TextStyle(color: AppColors.darkPurple),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.darkPurple),
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const BigMascot(size: 56, emoji: '👨‍👩‍👧'),
            const SizedBox(width: 12),
            Text(
              l10n.parentDashboardTitle,
              style: AppTheme.display(size: 28),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => context.go('/home'),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                    color: AppColors.pinkSoft,
                    offset: Offset(0, 3),
                    blurRadius: 0)
              ],
            ),
            child:
                const Icon(Icons.close, color: AppColors.deepPurple, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(AppLocalizations l10n) {
    // Calculate real totals from subjects data
    int totalCompleted = 0;
    int totalStars = 0;
    for (final s in _subjects) {
      totalCompleted += s['completed_lessons'] as int? ?? 0;
      totalStars += s['stars_earned'] as int? ?? 0;
    }

    return Row(
      children: [
        Expanded(
          child: _statCard('📚', '$totalCompleted',
              l10n.parentDashboardLessonsLearned, Colors.blue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard('⭐', '$totalStars', l10n.parentDashboardStarsEarned,
              Colors.amber),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
              '🔥', '5', l10n.parentDashboardStudyStreak, Colors.orange),
        ),
      ],
    );
  }

  Widget _statCard(String icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildChildProgress(AppLocalizations l10n) {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryPink),
        ),
      );
    }

    if (_subjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.parentDashboardProgress,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkPurple),
            ),
            const SizedBox(height: 16),
            _progressRow(
                l10n.parentDashboardSubjectMath, 0.0, AppColors.primaryPink),
            const SizedBox(height: 12),
            _progressRow(
                l10n.parentDashboardSubjectVietnamese, 0.0, Colors.red),
            const SizedBox(height: 12),
            _progressRow(
                l10n.parentDashboardSubjectEnglish, 0.0, Colors.indigo),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.parentDashboardProgress,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkPurple),
          ),
          const SizedBox(height: 16),
          ..._subjects.map((subject) {
            final isVi = Localizations.localeOf(context).languageCode == 'vi';
            final label = isVi
                ? (subject['subject_vi'] as String? ?? '')
                : (subject['subject_en'] as String? ?? '');
            final color = _parseColor(subject['color'] as String? ?? '#FFEBEE');
            final pct = subject['completion_pct'] as double? ?? 0.0;
            return Column(
              children: [
                _progressRow(label, pct, color),
                const SizedBox(height: 12),
                // Sub-subject breakdown
                ...((subject['sub_subjects'] as List<dynamic>? ?? [])
                    .cast<Map<String, dynamic>>()
                    .map((ss) {
                  final ssLabel = isVi
                      ? (ss['name_vi'] as String? ?? '')
                      : (ss['name_en'] as String? ?? '');
                  final ssColor =
                      _parseColor(ss['color'] as String? ?? '#FFEBEE');
                  final ssPct = ss['completion_pct'] as double? ?? 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: _progressRow(ssLabel, ssPct, ssColor, isSub: true),
                  );
                })),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primaryPink;
    }
  }

  Widget _progressRow(String label, double progress, Color color,
      {bool isSub = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: isSub ? 13 : 14,
                    fontWeight: isSub ? FontWeight.w500 : FontWeight.w600,
                    color: isSub ? AppColors.darkText : AppColors.darkPurple)),
            Text('${(progress * 100).toInt()}%',
                style: TextStyle(
                    fontSize: isSub ? 12 : 14,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: isSub ? 6 : 8,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(AppLocalizations l10n) {
    final unlockEnabled = ref.watch(unlockAnimationsEnabledProvider);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.parentDashboardSettings,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkPurple),
          ),
          const SizedBox(height: 16),
          _settingTile(Icons.language, l10n.parentDashboardLanguage,
              l10n.parentDashboardLanguageValue),
          _settingTile(Icons.timer, l10n.parentDashboardStudyTime,
              l10n.parentDashboardStudyTimeValue),
          _settingTile(
              Icons.notifications, l10n.parentDashboardNotifications, 'On'),
          const Divider(),
          // Unlock-anim toggle (Plan 8)
          _UnlockAnimationToggle(
            enabled: unlockEnabled,
            onChanged: (v) {
              ref.read(unlockAnimationsEnabledProvider.notifier).state = v;
              LocalStorageService.saveUnlockAnimationsEnabled(v);
            },
          ),
          // Parent email preferences (Plan 5)
          if (_emailInitialized)
            _EmailPreferencesTile(
              emailController: _emailCtrl,
              onEmailSaved: _saveEmail,
              frequency: _emailFrequency,
              onFrequencyChanged: _saveFrequency,
            ),
          _settingTile(Icons.logout, l10n.parentDashboardLogout, ''),
        ],
      ),
    );
  }

  Widget _settingTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryPink),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: value.isNotEmpty
          ? Text(
              value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedText),
            )
          : const Icon(Icons.chevron_right, color: AppColors.mutedText),
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _UnlockAnimationToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _UnlockAnimationToggle(
      {required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Hiệu ứng ăn mừng khi mở khóa',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkPurple,
              ),
            ),
          ),
          Switch(
            value: enabled,
            thumbColor: WidgetStateProperty.all(AppColors.primaryPink),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _EmailPreferencesTile extends StatelessWidget {
  final TextEditingController emailController;
  final Future<void> Function() onEmailSaved;
  final String frequency;
  final ValueChanged<String> onFrequencyChanged;
  const _EmailPreferencesTile({
    required this.emailController,
    required this.onEmailSaved,
    required this.frequency,
    required this.onFrequencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📧', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Báo cáo hàng tuần cho phụ huynh',
                        style: AppTheme.body(
                            size: 14,
                            color: AppColors.deepPurple,
                            weight: FontWeight.w800)),
                    Text('Tổng kết bài học, streak, điểm yếu',
                        style: AppTheme.body(
                            size: 11, color: AppColors.mutedPurple)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'email@example.com',
              prefixIcon:
                  Icon(Icons.email_outlined, color: AppColors.mutedPurple),
            ),
            onChanged: (_) => onEmailSaved(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _freqChip('never', 'Tắt', frequency, onFrequencyChanged),
              const SizedBox(width: 8),
              _freqChip('weekly', 'Hàng tuần', frequency, onFrequencyChanged),
            ],
          ),
          if (frequency == 'weekly' && emailController.text.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('⚠️ Nhập email để nhận báo cáo',
                  style: AppTheme.body(size: 11, color: AppColors.red)),
            ),
        ],
      ),
    );
  }

  Widget _freqChip(
      String value, String label, String selected, ValueChanged<String> onTap) {
    final isOn = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isOn ? AppColors.pink : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: isOn ? AppColors.pink : AppColors.divider, width: 2),
        ),
        child: Text(label,
            style: AppTheme.body(
                size: 12,
                color: isOn ? AppColors.white : AppColors.deepPurple,
                weight: FontWeight.w800)),
      ),
    );
  }
}
