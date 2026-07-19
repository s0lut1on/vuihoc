import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/kid_card.dart';
import '../widgets/mascot.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedTab = 0;
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _exercises = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final api = ApiService();
      final subjectsResp = await api.get('/content/subjects');
      final subjectsData = subjectsResp['data'] as List<dynamic>? ?? [];
      _subjects = subjectsData.map((e) => e as Map<String, dynamic>).toList();

      final lessonsResp = await api.get('/content/curriculum');
      final lessonsData = lessonsResp['data'] as List<dynamic>? ?? [];
      _lessons = [];
      for (final subject in lessonsData) {
        final subjectLessons = subject['lessons'] as List<dynamic>? ?? [];
        for (final lesson in subjectLessons) {
          _lessons.add({
            ...lesson as Map<String, dynamic>,
            'subject_id': subject['subject_id'],
          });
        }
      }

      _exercises = [];
      for (final lesson in _lessons) {
        final exs = lesson['exercises'] as List<dynamic>? ?? [];
        for (final ex in exs) {
          _exercises.add({
            ...ex as Map<String, dynamic>,
            'lesson_id': lesson['id'],
          });
        }
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Row(
        children: [
          _Sidebar(
            selected: _selectedTab,
            onSelect: (i) => setState(() => _selectedTab = i),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _SubjectsTab(subjects: _subjects, onRefresh: _loadData);
      case 1:
        return _LessonsTab(lessons: _lessons, subjects: _subjects, onRefresh: _loadData);
      case 2:
        return _ExercisesTab(exercises: _exercises, lessons: _lessons, onRefresh: _loadData);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _Sidebar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _Sidebar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('📚', 'Subjects'),
      ('📝', 'Lessons'),
      ('❓', 'Exercises'),
    ];
    return Container(
      width: 220,
      color: AppColors.deepPurple,
      child: Column(
        children: [
          const SizedBox(height: 24),
          const BigMascot(size: 48, emoji: '⚙️'),
          const SizedBox(height: 8),
          Text('Admin', style: AppTheme.display(size: 20, color: AppColors.white)),
          const SizedBox(height: 32),
          for (var i = 0; i < items.length; i++) ...[
            _SidebarItem(
              icon: items[i].$1,
              label: items[i].$2,
              selected: selected == i,
              onTap: () => onSelect(i),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('🏠', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text('Home', style: AppTheme.body(size: 14, color: AppColors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.pink.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Text(label, style: AppTheme.body(size: 14, color: AppColors.white)),
          ],
        ),
      ),
    );
  }
}

class _SubjectsTab extends StatelessWidget {
  final List<Map<String, dynamic>> subjects;
  final VoidCallback onRefresh;
  const _SubjectsTab({required this.subjects, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subjects', style: AppTheme.display(size: 28)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: subjects.length,
              itemBuilder: (ctx, i) {
                final s = subjects[i];
                return KidCard(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(s['icon'] ?? '📚', style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['name_vi'] ?? '', style: AppTheme.display(size: 16)),
                            Text('ID: ${s['id']}', style: AppTheme.body(size: 12, color: AppColors.mutedPurple)),
                          ],
                        ),
                      ),
                      Text('${s['lesson_count'] ?? 0} lessons',
                          style: AppTheme.body(size: 12, color: AppColors.mutedPurple)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonsTab extends StatelessWidget {
  final List<Map<String, dynamic>> lessons;
  final List<Map<String, dynamic>> subjects;
  final VoidCallback onRefresh;
  const _LessonsTab({required this.lessons, required this.subjects, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lessons', style: AppTheme.display(size: 28)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: lessons.length,
              itemBuilder: (ctx, i) {
                final l = lessons[i];
                return KidCard(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l['title_vi'] ?? '', style: AppTheme.display(size: 16)),
                            Text('ID: ${l['id']}', style: AppTheme.body(size: 12, color: AppColors.mutedPurple)),
                          ],
                        ),
                      ),
                      Text('Grade ${l['grade'] ?? 1}',
                          style: AppTheme.body(size: 12, color: AppColors.mutedPurple)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercisesTab extends StatelessWidget {
  final List<Map<String, dynamic>> exercises;
  final List<Map<String, dynamic>> lessons;
  final VoidCallback onRefresh;
  const _ExercisesTab({required this.exercises, required this.lessons, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Exercises', style: AppTheme.display(size: 28)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (ctx, i) {
                final e = exercises[i];
                return KidCard(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e['question_vi'] ?? '', style: AppTheme.display(size: 14)),
                            Text('ID: ${e['id']}', style: AppTheme.body(size: 12, color: AppColors.mutedPurple)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
