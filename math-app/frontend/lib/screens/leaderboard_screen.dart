import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard_model.dart';
import '../services/user_api.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const LeaderboardScreen({super.key, this.onBack});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  List<LeaderboardEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _join(String code) async {
    try {
      await UserApi.joinClassroom(code);
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
      appBar: AppBar(
        title: const Text('Bảng xếp hạng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildJoinCard(),
                Expanded(
                  child: _entries.isEmpty
                      ? const Center(
                          child: Text('Chưa có dữ liệu bảng xếp hạng'))
                      : ListView.builder(
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final e = _entries[index];
                            return ListTile(
                              leading: CircleAvatar(child: Text(e.avatar)),
                              title: Text(e.name),
                              subtitle: Text('${e.weeklyStars} ⭐ tuần này'),
                              trailing: Text('#${index + 1}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildJoinCard() {
    final controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Mã lớp học',
                  hintText: 'Nhập mã 6 ký tự',
                ),
                maxLength: 6,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => _join(controller.text.trim()),
                    child: const Text('Tham gia'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _leave,
                    child: const Text('Rời lớp'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
