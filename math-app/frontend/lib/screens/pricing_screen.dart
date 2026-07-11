import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../utils/url_launcher.dart';
import '../widgets/bubble_button.dart';
import '../widgets/kid_nav_bar.dart';
import '../widgets/mascot.dart';

/// Bảng giá (Pricing) — Free vs Premium tier comparison.
/// Prices mirror the marketing site /pricing page so the two stay in sync:
///   - Free: 0 đ (50 bài/ngày)
///   - Premium: 199K/tháng, 1,99 triệu/năm (tiết kiệm 17%)
///
/// Online payment is not yet integrated. Upgrade requests go to
/// contact@sekklings.com (admin flips the flag in the DB).
class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildFreeCard(context),
                    const SizedBox(height: 16),
                    _buildPremiumCard(context),
                    const SizedBox(height: 16),
                    _buildCompareTable(context),
                    const SizedBox(height: 24),
                    _buildUpgradeCta(context),
                    const SizedBox(height: 16),
                    _buildFooterNote(context),
                    const SizedBox(height: 16),
                    _buildBuildVersionFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const BigMascot(size: 90, emoji: '⭐'),
        const SizedBox(height: 8),
        Text('Bảng giá HocVui', style: AppTheme.display(size: 30)),
        const SizedBox(height: 4),
        Text(
          'Học vui mỗi ngày, miễn phí hoặc nâng cấp Premium',
          textAlign: TextAlign.center,
          style: AppTheme.body(size: 14, color: AppColors.mutedPurple),
        ),
      ],
    );
  }

  Widget _buildFreeCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.pinkSoft, width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.pinkSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('🎁', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Text('Miễn phí', style: AppTheme.display(size: 22)),
              const Spacer(),
              const _CurrentBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('0', style: AppTheme.display(size: 40)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('đ',
                    style: AppTheme.body(size: 18, color: AppColors.mutedPurple)),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/ mãi mãi',
                    style: AppTheme.body(size: 13, color: AppColors.mutedPurple)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _feature('50 bài học mỗi ngày', check: true),
          _feature('Đầy đủ 4 phong cách học', check: true),
          _feature('Song ngữ Việt–Anh', check: true),
          _feature('Dashboard phụ huynh cơ bản', check: true),
          _feature('Google Sign-In + Guest', check: true),
          _feature('Không giới hạn thời gian', check: true),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.pinkBg, Color(0xFFFFF8E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.pink, width: 3),
        boxShadow: const [
          BoxShadow(color: AppColors.pinkDark, offset: Offset(0, 6), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.pink,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('👑', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Text('Premium', style: AppTheme.display(size: 22)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.pink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Phổ biến',
                    style: AppTheme.body(
                        size: 12, color: AppColors.white, weight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('199K', style: AppTheme.display(size: 40)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/ tháng',
                    style: AppTheme.body(size: 16, color: AppColors.mutedPurple)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('hoặc 1,99 triệu / năm (tiết kiệm 17%)',
                style: AppTheme.body(size: 13, color: AppColors.pinkDark)),
          ),
          const SizedBox(height: 14),
          _feature('Không giới hạn bài học mỗi ngày', check: true, premium: true),
          _feature('Báo cáo tiến bộ hàng tuần qua email', check: true, premium: true),
          _feature('Xuất dữ liệu học tập (CSV)', check: true, premium: true),
          _feature('Nhiều hồ sơ bé trong 1 tài khoản', check: true, premium: true),
          _feature('Hỗ trợ ưu tiên 24/7', check: true, premium: true),
          _feature('Sớm nhận nội dung mới', check: true, premium: true),
        ],
      ),
    );
  }

  Widget _buildCompareTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pinkSoft, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text('So sánh chi tiết', style: AppTheme.display(size: 18)),
          ),
          const SizedBox(height: 8),
          _compareRow('Bài học / ngày', '50', 'Không giới hạn'),
          _compareRow('4 phong cách học', '✓', '✓'),
          _compareRow('Song ngữ Việt–Anh', '✓', '✓'),
          _compareRow('Dashboard phụ huynh', 'Cơ bản', 'Nâng cao + email'),
          _compareRow('Nhiều hồ sơ bé', '—', '✓'),
          _compareRow('Hỗ trợ ưu tiên', '—', '✓'),
          _compareRow('Sớm nhận nội dung mới', '—', '✓'),
        ],
      ),
    );
  }

  Widget _compareRow(String label, String free, String premium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style: AppTheme.body(size: 13, color: AppColors.deepPurple)),
          ),
          Expanded(
            flex: 2,
            child: Text(free,
                textAlign: TextAlign.center,
                style: AppTheme.body(
                    size: 12,
                    color: free == '—'
                        ? AppColors.mutedText
                        : AppColors.deepPurple,
                    weight: free == '✓' ? FontWeight.w800 : FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text(premium,
                textAlign: TextAlign.center,
                style: AppTheme.body(
                    size: 12, color: AppColors.pinkDark, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeCta(BuildContext context) {
    return BubbleButton(
      label: 'Nâng cấp ngay 🚀',
      minWidth: double.infinity,
      height: 56,
      fontSize: 17,
      onPressed: () => openExternalUrl('mailto:contact@sekklings.com?subject=N%C3%A2ng%20c%E1%BA%A5p%20HocVui%20Premium'),
    );
  }

  Widget _buildFooterNote(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orangeSoft, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Thanh toán online chưa tích hợp. Bé đang dùng gói Premium? Liên hệ contact@sekklings.com — admin sẽ kích hoạt trong 24h.',
              style: AppTheme.body(size: 12, color: AppColors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildVersionFooter() {
    return Center(
      child: Text(
        'HocVui • Học vui mỗi ngày',
        style: AppTheme.body(size: 11, color: AppColors.mutedText),
      ),
    );
  }

  Widget _feature(String text, {required bool check, bool premium = false}) {
    final color = premium ? AppColors.pinkDark : AppColors.deepPurple;
    final iconBg = premium ? AppColors.pink : AppColors.pinkSoft;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(check ? '✓' : '—',
                style: TextStyle(
                    fontSize: 12,
                    color: premium ? AppColors.white : AppColors.pinkDark,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTheme.body(size: 13, color: color, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.successGreen, width: 1),
      ),
      child: Text('Đang dùng',
          style: AppTheme.body(size: 12, color: AppColors.successGreen, weight: FontWeight.w800)),
    );
  }
}
