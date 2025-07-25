import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<Map<String, dynamic>> _progressData = [];
  int _streak = 5;
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
      // Mock data for now
      setState(() {
        _progressData = [
          {'label': 'Vocabulary', 'value': 75},
          {'label': 'Grammar', 'value': 60},
          {'label': 'Speaking', 'value': 80},
          {'label': 'Listening', 'value': 70},
        ];
        _badges = [
          {'name': 'First Word', 'description': 'Added your first vocabulary word'},
          {'name': '5-Day Streak', 'description': 'Maintained a 5-day learning streak'},
          {'name': 'Grammar Master', 'description': 'Completed 10 grammar exercises'},
        ];
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load progress data.';
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
      appBar: AppBar(
        title: const Text('Your Progress'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Streak Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange, size: 40),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current Streak', style: Theme.of(context).textTheme.titleMedium),
                              Text('$_streak days', style: Theme.of(context).textTheme.headlineSmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress Chart
                  Text('Progress Overview', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 100,
                            barTouchData: BarTouchData(enabled: false),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: _progressData.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: (item['value'] ?? 0).toDouble(),
                                    color: Colors.deepPurple,
                                    width: 20,
                                  ),
                                ],
                              );
                            }).toList(),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    if (value.toInt() < _progressData.length) {
                                      return Text(
                                        _progressData[value.toInt()]['label'],
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Badges Section
                  Text('Badges Earned', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _badges.length,
                      itemBuilder: (context, index) {
                        final badge = _badges[index];
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                                  const SizedBox(height: 4),
                                  Text(
                                    badge['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: Text(
                                      badge['description'],
                                      style: const TextStyle(fontSize: 10),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Leaderboard Section
                  Text('Leaderboard', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: _leaderboard.asMap().entries.map((entry) {
                        final index = entry.key;
                        final user = entry.value;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: index == 0 ? const Color(0xFFFFD700) : Colors.grey,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(user['user']),
                          subtitle: Text('${user['streak']} day streak'),
                          trailing: Text('${user['score']} pts'),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
