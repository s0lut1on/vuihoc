import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isVietnamese = locale.languageCode == 'vi';
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppColors.grayBg,
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout(context, isVietnamese)
            : _buildMobileLayout(context, isVietnamese),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isVietnamese) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isVietnamese),
          const SizedBox(height: 32),
          _buildStatsCards(isVietnamese),
          const SizedBox(height: 32),
          _buildChildProgress(isVietnamese),
          const SizedBox(height: 32),
          _buildSettings(isVietnamese),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isVietnamese) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDesktopNav(context, isVietnamese),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildStatsCards(isVietnamese),
                    const SizedBox(height: 32),
                    _buildChildProgress(isVietnamese),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 1,
                child: _buildSettings(isVietnamese),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNav(BuildContext context, bool isVietnamese) {
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
          ],
        ),
        Row(
          children: [
            TextButton(
              onPressed: () => context.go('/home'),
              child: Text(
                isVietnamese ? 'Về trang chủ' : 'Back to Home',
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

  Widget _buildHeader(BuildContext context, bool isVietnamese) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isVietnamese ? 'Khu vực cha mẹ' : 'Parent Dashboard',
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.darkPurple),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.darkPurple),
          onPressed: () => context.go('/home'),
        ),
      ],
    );
  }

  Widget _buildStatsCards(bool isVietnamese) {
    return Row(
      children: [
        Expanded(
          child: _statCard('📚', '12',
              isVietnamese ? 'Bài đã học' : 'Lessons learned', Colors.blue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard('⭐', '36',
              isVietnamese ? 'Sao tích lũy' : 'Stars earned', Colors.amber),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard('🔥', '5 ngày',
              isVietnamese ? 'Liên tiếp học' : 'Study streak', Colors.orange),
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

  Widget _buildChildProgress(bool isVietnamese) {
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
            isVietnamese ? 'Tiến độ học tập' : 'Learning Progress',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkPurple),
          ),
          const SizedBox(height: 16),
          _progressRow(
              isVietnamese ? 'Số học' : 'Numbers', 0.75, AppColors.primaryPink),
          const SizedBox(height: 12),
          _progressRow(
              isVietnamese ? 'Hình học' : 'Geometry', 0.40, Colors.green),
          const SizedBox(height: 12),
          _progressRow(
              isVietnamese ? 'Đo lường' : 'Measurement', 0.20, Colors.orange),
          const SizedBox(height: 12),
          _progressRow(isVietnamese ? 'Tư duy' : 'Logic', 0.10, Colors.blue),
        ],
      ),
    );
  }

  Widget _progressRow(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text('${(progress * 100).toInt()}%',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(bool isVietnamese) {
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
            isVietnamese ? 'Cài đặt' : 'Settings',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkPurple),
          ),
          const SizedBox(height: 16),
          _settingTile(Icons.language, isVietnamese ? 'Ngôn ngữ' : 'Language',
              isVietnamese ? 'Tiếng Việt' : 'Vietnamese'),
          _settingTile(
              Icons.timer,
              isVietnamese ? 'Thời gian học' : 'Study Time',
              '15 ${isVietnamese ? 'phút/ngày' : 'min/day'}'),
          _settingTile(Icons.notifications,
              isVietnamese ? 'Thông báo' : 'Notifications', 'On'),
          _settingTile(Icons.logout, isVietnamese ? 'Đăng xuất' : 'Logout', ''),
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
