import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement_model.dart';
import '../services/achievement_service.dart';
import '../providers/app_providers.dart';

class AchievementScreen extends ConsumerStatefulWidget {
  const AchievementScreen({super.key});

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
    setState(() {
      _badges = rows.map(Achievement.fromJson).toList();
      _loading = false;
    });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Huy chương')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _badges.isEmpty
              ? const Center(child: Text('Chưa có huy chương nào'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _badges.length,
                  itemBuilder: (context, index) {
                    final b = _badges[index];
                    return Card(
                      child: ListTile(
                        leading:
                            Text(b.icon, style: const TextStyle(fontSize: 32)),
                        title: Text(b.name),
                        subtitle: Text(b.description),
                        trailing: b.isNew
                            ? Chip(
                                label: const Text('MỚI'),
                                backgroundColor: Colors.orange.shade100)
                            : b.isEarned
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : const Icon(Icons.lock_outline,
                                    color: Colors.grey),
                        onTap: b.isNew ? () => _markRead(b.badgeType) : null,
                      ),
                    );
                  },
                ),
    );
  }
}
