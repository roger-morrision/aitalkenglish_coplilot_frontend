import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class GrammarCategory {
  final int id;
  final String name;
  final String? description;
  GrammarCategory({required this.id, required this.name, this.description});
  factory GrammarCategory.fromJson(Map<String, dynamic> json) =>
      GrammarCategory(
        id: json['id'],
        name: json['name'],
        description: json['description'],
      );
}

class GrammarTopic {
  final int id;
  final int categoryId;
  final String name;
  final String? description;
  GrammarTopic({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
  });
  factory GrammarTopic.fromJson(Map<String, dynamic> json) => GrammarTopic(
    id: json['id'],
    categoryId: json['category_id'],
    name: json['name'],
    description: json['description'],
  );
}

class GrammarExercise {
  final int id;
  final int topicId;
  final String question;
  final List<String> options;
  final String answer;
  final String? explanation;
  GrammarExercise({
    required this.id,
    required this.topicId,
    required this.question,
    required this.options,
    required this.answer,
    this.explanation,
  });
  factory GrammarExercise.fromJson(Map<String, dynamic> json) =>
      GrammarExercise(
        id: json['id'],
        topicId: json['topic_id'],
        question: json['question'],
        options: List<String>.from(json['options']),
        answer: json['answer'],
        explanation: json['explanation'],
      );
}

class GrammarStudyScreen extends StatefulWidget {
  const GrammarStudyScreen({super.key});

  @override
  State<GrammarStudyScreen> createState() => _GrammarStudyScreenState();
}

class _GrammarStudyScreenState extends State<GrammarStudyScreen> {
  GrammarCategory? selectedCategory;
  GrammarTopic? selectedTopic;
  int userLevel = 1;
  int completedExercises = 0;

  List<GrammarCategory> categories = [];
  List<GrammarTopic> topics = [];
  List<GrammarExercise> exercises = [];
  bool loading = false;
  String? error;

  final String apiBase = 'http://localhost:3000';

  String? userId;

  @override
  void initState() {
    super.initState();
    _initUserAndLoad();
  }

  Future<void> _initUserAndLoad() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      await _fetchCategories();
      await _fetchCompletedExercises();
    } else {
      setState(() {
        error = 'User not logged in.';
      });
    }
  }

  Future<void> _fetchCompletedExercises() async {
    if (userId == null) return;
    try {
      final res = await http.get(
        Uri.parse('$apiBase/user/$userId/grammar-study'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final results = data['results'] as List?;
        completedExercises = results?.length ?? 0;
        setState(() {});
      }
    } catch (e) {
      // ignore error
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await http.get(Uri.parse('$apiBase/grammar/categories'));
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        categories = data.map((e) => GrammarCategory.fromJson(e)).toList();
      } else {
        error = 'Failed to load categories';
      }
    } catch (e) {
      error = e.toString();
    }
    setState(() {
      loading = false;
    });
  }

  Future<void> _fetchTopics(int categoryId) async {
    setState(() {
      loading = true;
      error = null;
      topics = [];
      exercises = [];
    });
    try {
      final res = await http.get(
        Uri.parse('$apiBase/grammar/categories/$categoryId/topics'),
      );
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        topics = data.map((e) => GrammarTopic.fromJson(e)).toList();
      } else {
        error = 'Failed to load topics';
      }
    } catch (e) {
      error = e.toString();
    }
    setState(() {
      loading = false;
    });
  }

  Future<void> _fetchExercises(int topicId) async {
    setState(() {
      loading = true;
      error = null;
      exercises = [];
    });
    try {
      final res = await http.get(
        Uri.parse('$apiBase/grammar/topics/$topicId/exercises'),
      );
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        exercises = data.map((e) => GrammarExercise.fromJson(e)).toList();
      } else {
        error = 'Failed to load exercises';
      }
    } catch (e) {
      error = e.toString();
    }
    setState(() {
      loading = false;
    });
  }

  void _selectCategory(GrammarCategory category) {
    setState(() {
      selectedCategory = category;
      selectedTopic = null;
      topics = [];
      exercises = [];
    });
    _fetchTopics(category.id);
  }

  void _selectTopic(GrammarTopic topic) {
    setState(() {
      selectedTopic = topic;
      exercises = [];
    });
    _fetchExercises(topic.id);
  }

  void _onExerciseCompleted({
    required GrammarExercise exercise,
    required bool isCorrect,
  }) async {
    setState(() {
      completedExercises++;
      if (completedExercises % 3 == 0) {
        userLevel++;
      }
    });
    // Save to backend
    if (userId != null && selectedCategory != null && selectedTopic != null) {
      try {
        await http.post(
          Uri.parse('$apiBase/user/$userId/grammar-study'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'category_id': selectedCategory!.id,
            'topic_id': selectedTopic!.id,
            'exercise_id': exercise.id,
            'is_correct': isCorrect,
          }),
        );
      } catch (e) {
        // ignore error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canGoBack = selectedCategory != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grammar Study'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    if (selectedTopic != null) {
                      // Go back from exercise to topic list
                      selectedTopic = null;
                    } else if (selectedCategory != null) {
                      // Go back from topic list to category list
                      selectedCategory = null;
                    }
                  });
                },
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Level: ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text('$userLevel'),
                  backgroundColor: Colors.deepPurple.shade100,
                ),
                const SizedBox(width: 16),
                Text(
                  'Completed: $completedExercises',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (loading) const Center(child: CircularProgressIndicator()),
            if (error != null)
              Text(error!, style: TextStyle(color: Colors.red)),
            if (!loading && error == null)
              if (selectedCategory == null)
                Expanded(child: _buildCategoryList())
              else if (selectedTopic == null)
                Expanded(child: _buildTopicList())
              else
                Expanded(child: _buildExerciseList()),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories found.'));
    }
    return ListView(
      children: categories
          .map(
            (cat) => Card(
              child: ListTile(
                title: Text(cat.name),
                subtitle: cat.description != null
                    ? Text(cat.description!)
                    : null,
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _selectCategory(cat),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTopicList() {
    if (topics.isEmpty) {
      return const Center(child: Text('No topics found.'));
    }
    return ListView(
      children: topics
          .map(
            (topic) => Card(
              child: ListTile(
                title: Text(topic.name),
                subtitle: topic.description != null
                    ? Text(topic.description!)
                    : null,
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _selectTopic(topic),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildExerciseList() {
    if (exercises.isEmpty) {
      return const Center(child: Text('No exercises found.'));
    }
    return ListView(
      children: exercises
          .map(
            (ex) => Card(
              child: GrammarExerciseWidget(
                exercise: ex,
                onCompleted: (bool isCorrect) =>
                    _onExerciseCompleted(exercise: ex, isCorrect: isCorrect),
              ),
            ),
          )
          .toList(),
    );
  }
}

class GrammarExerciseWidget extends StatefulWidget {
  final GrammarExercise exercise;
  final void Function(bool isCorrect) onCompleted;
  const GrammarExerciseWidget({
    required this.exercise,
    required this.onCompleted,
    super.key,
  });

  @override
  State<GrammarExerciseWidget> createState() => _GrammarExerciseWidgetState();
}

class _GrammarExerciseWidgetState extends State<GrammarExerciseWidget> {
  int? selectedIndex;
  bool answered = false;

  @override
  Widget build(BuildContext context) {
    // Find correct index by matching answer string
    int correctIndex = widget.exercise.options.indexOf(widget.exercise.answer);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.exercise.question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ...List.generate(widget.exercise.options.length, (i) {
            final isCorrect = i == correctIndex;
            final isSelected = i == selectedIndex;
            Color? color;
            if (answered) {
              if (isSelected && isCorrect)
                color = Colors.green.shade200;
              else if (isSelected && !isCorrect)
                color = Colors.red.shade200;
              else if (isCorrect)
                color = Colors.green.shade50;
            }
            return ListTile(
              title: Text(widget.exercise.options[i]),
              tileColor: color,
              leading: Radio<int>(
                value: i,
                groupValue: selectedIndex,
                onChanged: answered
                    ? null
                    : (val) => setState(() => selectedIndex = val),
              ),
              onTap: answered ? null : () => setState(() => selectedIndex = i),
            );
          }),
          if (!answered)
            ElevatedButton(
              onPressed: selectedIndex == null
                  ? null
                  : () {
                      setState(() => answered = true);
                      final isCorrect = selectedIndex == correctIndex;
                      widget.onCompleted(isCorrect);
                      if (isCorrect) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Correct!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Try again!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: const Text('Submit'),
            ),
          if (answered && widget.exercise.explanation != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Explanation: ${widget.exercise.explanation!}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
        ],
      ),
    );
  }
}
