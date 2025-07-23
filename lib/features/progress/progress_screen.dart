import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../services/lesson_db_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<dynamic> _progressList = [];
  int _streak = 0;
  List<Map<String, dynamic>> _badges = [];
  List<Map<String, dynamic>> _leaderboard = [
    {'user': 'You', 'score': 120, 'streak': 5},
    {'user': 'Alice', 'score': 110, 'streak': 4},
    {'user': 'Bob', 'score': 90, 'streak': 3},
  ];
  bool _loading = false;
  String? _error;

  Future<void> _fetchProgress() async {
    setState(() => _loading = true);
    try {
      final progress = await LocalDbService.getProgress();
      final streak = await LessonDbService.getCurrentStreak();
      final badges = await LessonDbService.getBadges();
      setState(() {
        _progressList = progress;
        _streak = streak;
        _badges = badges;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load progress.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress & Achievements')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Text('Current Streak: $_streak days', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Badges:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _badges.map((b) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      CircleAvatar(child: Text(b['icon'] ?? '🏅')),
                      Text(b['name'] ?? '', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Text('Leaderboard:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: ListView.builder(
                itemCount: _leaderboard.length,
                itemBuilder: (ctx, i) {
                  final entry = _leaderboard[i];
                  return ListTile(
                    leading: Text('#${i + 1}'),
                    title: Text(entry['user']),
                    subtitle: Text('Score: ${entry['score']} | Streak: ${entry['streak']}'),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _progressList.isEmpty
                        ? const Center(child: Text('No progress data yet.'))
                        : BarChart(
                            BarChartData(
                              barGroups: _progressList.map((item) {
                                return BarChartGroupData(
                                  x: _progressList.indexOf(item),
                                  barRods: [
                                    BarChartRodData(y: (item['value'] ?? 0).toDouble(), colors: [Colors.deepPurple]),
                                  ],
                                  showingTooltipIndicators: [0],
                                );
                              }).toList(),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= _progressList.length) return const SizedBox();
                                      return Text(_progressList[idx]['metric'] ?? '');
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
