import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/lesson_db_service.dart';
import '../../services/progress_service.dart';
import '../../models/lesson.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  List<Lesson> _lessons = [];
  bool _loading = false;
  String? _error;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  Future<void> _loadLessons() async {
    setState(() => _loading = true);
    try {
      final lessons = await LessonDbService.getLessons();
      setState(() {
        _lessons = lessons;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load lessons.';
      });
    }
  }

  Future<void> _addLesson() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (title.isEmpty || desc.isEmpty) return;
    setState(() => _loading = true);
    try {
      await LessonDbService.addLesson(Lesson(title: title, description: desc, scheduledAt: DateTime.now()));
      _titleController.clear();
      _descController.clear();
      await _loadLessons();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to add lesson.';
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _completeLesson(int id) async {
    await LessonDbService.completeLesson(id);
    
    // Track lesson completion progress
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final currentProgress = await ProgressService.loadProgress(user.uid);
        final updatedProgress = currentProgress.copyWith(
          lessonsCompleted: currentProgress.lessonsCompleted + 1,
          lastActivity: DateTime.now(),
        );
        await ProgressService.saveProgress(updatedProgress);
      }
    } catch (e) {
      print('Error tracking lesson completion: $e');
    }
    
    await _loadLessons();
  }

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'Lesson title'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _descController,
                    decoration: const InputDecoration(hintText: 'Description'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addLesson,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const CircularProgressIndicator(),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            Expanded(
              child: ListView.builder(
                itemCount: _lessons.length,
                itemBuilder: (ctx, i) {
                  final lesson = _lessons[i];
                  return Card(
                    color: lesson.completed ? Colors.green[100] : Colors.blue[50],
                    child: ListTile(
                      title: Text(lesson.title),
                      subtitle: Text(lesson.description),
                      trailing: lesson.completed
                          ? const Icon(Icons.check, color: Colors.green)
                          : IconButton(
                              icon: const Icon(Icons.done),
                              onPressed: () => _completeLesson(lesson.id!),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
