import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/lesson.dart';

class PersonalizedLessonScreen extends StatefulWidget {
  const PersonalizedLessonScreen({super.key});

  @override
  State<PersonalizedLessonScreen> createState() => _PersonalizedLessonScreenState();
}

class _PersonalizedLessonScreenState extends State<PersonalizedLessonScreen> {
  List<Lesson> _availableLessons = [];
  List<Lesson> _personalizedLessons = [];
  bool _isLoading = true;
  String _selectedDifficulty = 'Intermediate';
  String _selectedTopic = 'General';
  String _selectedSkill = 'All Skills';
  int _selectedDuration = 15; // minutes

  final List<String> _difficulties = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _topics = [
    'General', 'Business', 'Travel', 'Technology', 'Health', 
    'Education', 'Entertainment', 'Sports', 'Food', 'Culture'
  ];
  final List<String> _skills = [
    'All Skills', 'Grammar', 'Vocabulary', 'Reading', 'Listening', 'Speaking', 'Writing'
  ];
  final List<int> _durations = [5, 10, 15, 20, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final lessons = await ApiService.getLessons();
      setState(() {
        _availableLessons = lessons;
        _isLoading = false;
      });
      _generatePersonalizedLessons();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading lessons: $e')),
        );
      }
    }
  }

  void _generatePersonalizedLessons() {
    // Filter lessons based on user preferences
    final filteredLessons = _availableLessons.where((lesson) {
      bool matchesDifficulty = lesson.difficulty == _selectedDifficulty;
      bool matchesTopic = _selectedTopic == 'General' || lesson.topic == _selectedTopic;
      bool matchesSkill = _selectedSkill == 'All Skills' || lesson.skillType == _selectedSkill;
      bool matchesDuration = lesson.estimatedDuration <= _selectedDuration;
      
      return matchesDifficulty && matchesTopic && matchesSkill && matchesDuration;
    }).toList();

    setState(() {
      _personalizedLessons = filteredLessons;
    });
  }

  Widget _buildPreferencesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Personalize Your Learning',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Difficulty Selection
            _buildDropdownField(
              'Difficulty Level',
              _selectedDifficulty,
              _difficulties,
              Icons.trending_up,
              (value) => setState(() {
                _selectedDifficulty = value!;
                _generatePersonalizedLessons();
              }),
            ),
            
            const SizedBox(height: 12),
            
            // Topic Selection
            _buildDropdownField(
              'Topic',
              _selectedTopic,
              _topics,
              Icons.topic,
              (value) => setState(() {
                _selectedTopic = value!;
                _generatePersonalizedLessons();
              }),
            ),
            
            const SizedBox(height: 12),
            
            // Skill Focus
            _buildDropdownField(
              'Skill Focus',
              _selectedSkill,
              _skills,
              Icons.school,
              (value) => setState(() {
                _selectedSkill = value!;
                _generatePersonalizedLessons();
              }),
            ),
            
            const SizedBox(height: 12),
            
            // Duration Selection
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                const Text('Max Duration:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedDuration,
                    isExpanded: true,
                    items: _durations.map((duration) {
                      return DropdownMenuItem<int>(
                        value: duration,
                        child: Text('$duration minutes'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() {
                      _selectedDuration = value!;
                      _generatePersonalizedLessons();
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> options,
    IconData icon,
    void Function(String?) onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 20),
        const SizedBox(width: 8),
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _startLesson(lesson),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(lesson.difficulty).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getSkillIcon(lesson.skillType),
                      color: _getDifficultyColor(lesson.difficulty),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildChip(lesson.difficulty, _getDifficultyColor(lesson.difficulty)),
                  const SizedBox(width: 8),
                  _buildChip(lesson.topic, Colors.blue),
                  const SizedBox(width: 8),
                  _buildChip('${lesson.estimatedDuration} min', Colors.orange),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${lesson.rating}/5',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.people, color: Colors.grey.shade600, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${lesson.completedBy} completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getSkillIcon(String skillType) {
    switch (skillType.toLowerCase()) {
      case 'grammar':
        return Icons.edit;
      case 'vocabulary':
        return Icons.book;
      case 'reading':
        return Icons.menu_book;
      case 'listening':
        return Icons.headphones;
      case 'speaking':
        return Icons.mic;
      case 'writing':
        return Icons.create;
      default:
        return Icons.school;
    }
  }

  void _startLesson(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailScreen(lesson: lesson),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Personalized Lessons'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLessons,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPreferencesCard(),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Recommended for You (${_personalizedLessons.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_personalizedLessons.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No lessons match your preferences',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters above',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _personalizedLessons
                          .map((lesson) => _buildLessonCard(lesson))
                          .toList(),
                    ),
                ],
              ),
            ),
    );
  }
}

class LessonDetailScreen extends StatelessWidget {
  final Lesson lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Start lesson logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Starting lesson...')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Start Lesson'),
            ),
          ],
        ),
      ),
    );
  }
}
