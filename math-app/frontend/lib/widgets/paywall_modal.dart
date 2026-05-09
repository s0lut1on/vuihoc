import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class PaywallModal extends StatelessWidget {
  final VoidCallback onClose;

  const PaywallModal({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Bạn đã học đủ bài hôm nay',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.darkPurple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tài khoản miễn phí được học tối đa 50 bài mỗi ngày. Nâng cấp để học không giới hạn.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onClose,
              child: const Text('Đã hiểu'),
            ),
            TextButton(
              onPressed: onClose,
              child: Text(
                'Đóng',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
