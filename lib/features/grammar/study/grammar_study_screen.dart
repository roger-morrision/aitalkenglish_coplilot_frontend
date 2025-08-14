import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class GrammarCategory {
  final String id;
  final String name;
  final int displayOrder;
  final List<GrammarTopic> topics;

  GrammarCategory({
    required this.id,
    required this.name,
    required this.displayOrder,
    this.topics = const [],
  });

  factory GrammarCategory.fromJson(Map<String, dynamic> json) {
    try {
      return GrammarCategory(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        displayOrder: int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
        topics: (json['topics'] as List<dynamic>?)?.map((e) => GrammarTopic.fromJson(e)).toList() ?? [],
      );
    } catch (e) {
      print('Error parsing GrammarCategory: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class GrammarTopic {
  final String id;
  final String categoryId;
  final String title;
  final String description;
  final String level;
  final int displayOrder;
  final List<GrammarExercise> exercises;

  GrammarTopic({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.level,
    required this.displayOrder,
    this.exercises = const [],
  });

  factory GrammarTopic.fromJson(Map<String, dynamic> json) {
    try {
      return GrammarTopic(
        id: json['id']?.toString() ?? '',
        categoryId: json['category_id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        level: json['level']?.toString() ?? '',
        displayOrder: int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
        exercises: (json['exercises'] as List<dynamic>?)?.map((e) => GrammarExercise.fromJson(e)).toList() ?? [],
      );
    } catch (e) {
      print('Error parsing GrammarTopic: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class GrammarExercise {
  final String id;
  final String topicId;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String difficulty;
  final int displayOrder;
  
  // Progress information
  final bool hasUserCompleted;
  final Map<String, dynamic>? userResult;

  GrammarExercise({
    required this.id,
    required this.topicId,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    required this.displayOrder,
    this.hasUserCompleted = false,
    this.userResult,
  });

  factory GrammarExercise.fromJson(Map<String, dynamic> json) {
    try {
      List<String> options = [];
      if (json['options'] is String) {
        // Parse JSON string
        final optionsData = jsonDecode(json['options']);
        if (optionsData is List) {
          options = List<String>.from(optionsData);
        }
      } else if (json['options'] is List) {
        options = List<String>.from(json['options']);
      }
      
      return GrammarExercise(
        id: json['id']?.toString() ?? '',
        topicId: json['topic_id']?.toString() ?? '',
        question: json['question']?.toString() ?? '',
        options: options,
        correctIndex: int.tryParse(json['correct_index']?.toString() ?? '0') ?? 0,
        difficulty: json['difficulty']?.toString() ?? 'easy',
        displayOrder: int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
        hasUserCompleted: json['hasUserCompleted'] == true,
        userResult: json['userResult'] as Map<String, dynamic>?,
      );
    } catch (e) {
      print('Error parsing GrammarExercise: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class GrammarStudyScreen extends StatefulWidget {
  const GrammarStudyScreen({super.key});

  @override
  State<GrammarStudyScreen> createState() => _GrammarStudyScreenState();
}

class _GrammarStudyScreenState extends State<GrammarStudyScreen> {
  GrammarCategory? selectedCategory;
  GrammarTopic? selectedTopic;
  bool showingTopicExplanation = false;
  int userLevel = 1;
  int completedExercises = 0;

  List<GrammarCategory> categories = [];
  List<GrammarTopic> topics = [];
  List<GrammarExercise> exercises = [];
  bool loading = false;
  String? error;

  String? userId;

  // Exercise quiz state
  Map<String, int?> exerciseAnswers = {}; // exerciseId -> selectedAnswerIndex
  bool showResults = false;
  double? score;
  int? correctAnswers;
  int? totalQuestions;

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
      final results = await ApiService.getUserGrammarStudyResults(userId!);
      completedExercises = results.length;
      setState(() {});
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
      print('Loading grammar categories...');
      final data = await ApiService.getGrammarCategories();
      print('Raw categories data: $data');
      categories = data.map((e) => GrammarCategory.fromJson(e)).toList();
      print('Parsed ${categories.length} categories');
    } catch (e) {
      print('Error loading categories: $e');
      error = e.toString();
    }
    setState(() {
      loading = false;
    });
  }

  Future<void> _fetchTopics(String categoryId) async {
    setState(() {
      loading = true;
      error = null;
      topics = [];
      exercises = [];
    });
    try {
      print('Loading topics for category: $categoryId');
      final data = await ApiService.getGrammarTopics(categoryId);
      print('Raw topics data: $data');
      topics = data.map((e) => GrammarTopic.fromJson(e)).toList();
      print('Parsed ${topics.length} topics');
    } catch (e) {
      print('Error loading topics: $e');
      error = e.toString();
    }
    setState(() {
      loading = false;
    });
  }

  Future<void> _fetchExercises(String topicId) async {
    setState(() {
      loading = true;
      error = null;
      exercises = [];
      // Reset quiz state when loading new exercises
      exerciseAnswers.clear();
      showResults = false;
      score = null;
      correctAnswers = null;
      totalQuestions = null;
    });
    try {
      if (userId != null) {
        // Fetch exercises with user progress
        final data = await ApiService.getGrammarExercisesWithProgress(userId!, topicId);
        exercises = data.map((e) => GrammarExercise.fromJson(e)).toList();
        
        // Check if user has already completed all exercises in this topic
        _checkAndRestoreCompletedQuiz();
      } else {
        // Fallback to exercises without progress
        final data = await ApiService.getGrammarExercises(topicId);
        exercises = data.map((e) => GrammarExercise.fromJson(e)).toList();
      }
    } catch (e) {
      error = e.toString();
      // Fallback to basic exercises if progress fetch fails
      try {
        final data = await ApiService.getGrammarExercises(topicId);
        exercises = data.map((e) => GrammarExercise.fromJson(e)).toList();
      } catch (fallbackError) {
        error = fallbackError.toString();
      }
    }
    setState(() {
      loading = false;
    });
  }

  void _checkAndRestoreCompletedQuiz() {
    // Check if all exercises have been completed
    if (exercises.isNotEmpty && exercises.every((ex) => ex.hasUserCompleted)) {
      // Restore the previous quiz results
      int correct = 0;
      exerciseAnswers.clear();
      
      for (final exercise in exercises) {
        if (exercise.userResult != null) {
          final selectedAnswer = exercise.userResult!['selectedAnswer'] as int?;
          final isCorrect = exercise.userResult!['isCorrect'] as bool? ?? false;
          
          if (selectedAnswer != null) {
            exerciseAnswers[exercise.id] = selectedAnswer;
            if (isCorrect) {
              correct++;
            }
          }
        }
      }
      
      // Only show results if we have answers for all exercises
      if (exerciseAnswers.length == exercises.length) {
        setState(() {
          showResults = true;
          correctAnswers = correct;
          totalQuestions = exercises.length;
          score = correct / exercises.length;
        });
      }
    }
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
      showingTopicExplanation = true;
      exercises = [];
    });
  }

  void _startExercises() {
    setState(() {
      showingTopicExplanation = false;
    });
    _fetchExercises(selectedTopic!.id);
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
                    if (selectedTopic != null && !showingTopicExplanation) {
                      // Go back from exercises to topic explanation
                      showingTopicExplanation = true;
                      exercises = [];
                    } else if (selectedTopic != null && showingTopicExplanation) {
                      // Go back from topic explanation to topic list
                      selectedTopic = null;
                      showingTopicExplanation = false;
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
            // Breadcrumb navigation
            _buildBreadcrumb(),
            const SizedBox(height: 16),
            if (loading) const Center(child: CircularProgressIndicator()),
            if (error != null)
              Text(error!, style: TextStyle(color: Colors.red)),
            if (!loading && error == null)
              if (selectedCategory == null)
                Expanded(child: _buildCategoryList())
              else if (selectedTopic == null)
                Expanded(child: _buildTopicList())
              else if (showingTopicExplanation)
                Expanded(child: _buildTopicExplanation())
              else
                Expanded(child: _buildExerciseList()),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    if (selectedCategory == null) {
      return Container(); // No breadcrumb for category list
    }

    List<Widget> breadcrumbItems = [];

    // Add "Grammar Categories" link if we're not at the top level
    breadcrumbItems.add(
      GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = null;
            selectedTopic = null;
            topics = [];
            exercises = [];
          });
        },
        child: Text(
          'Grammar Categories',
          style: TextStyle(
            color: Colors.deepPurple,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );

    // Add separator
    breadcrumbItems.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Icon(Icons.keyboard_arrow_right, color: Colors.grey),
      ),
    );

    // Add current category (clickable if we're in topic/exercise view)
    breadcrumbItems.add(
      GestureDetector(
        onTap: selectedTopic != null ? () {
          setState(() {
            selectedTopic = null;
            showingTopicExplanation = false;
            exercises = [];
          });
        } : null,
        child: Text(
          selectedCategory!.name,
          style: TextStyle(
            color: selectedTopic != null ? Colors.deepPurple : Colors.black,
            decoration: selectedTopic != null ? TextDecoration.underline : null,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );

    // Add current topic if selected
    if (selectedTopic != null) {
      breadcrumbItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(Icons.keyboard_arrow_right, color: Colors.grey),
        ),
      );

      breadcrumbItems.add(
        GestureDetector(
          onTap: !showingTopicExplanation ? () {
            setState(() {
              showingTopicExplanation = true;
              exercises = [];
            });
          } : null,
          child: Text(
            selectedTopic!.title,
            style: TextStyle(
              color: !showingTopicExplanation ? Colors.deepPurple : Colors.black,
              decoration: !showingTopicExplanation ? TextDecoration.underline : null,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

      // Add "Exercises" indicator if we're in exercise view
      if (!showingTopicExplanation) {
        breadcrumbItems.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.keyboard_arrow_right, color: Colors.grey),
          ),
        );

        breadcrumbItems.add(
          Text(
            'Exercises',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.home_outlined, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: breadcrumbItems,
            ),
          ),
        ],
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
                subtitle: Text('Level: ${cat.topics.isNotEmpty ? cat.topics.first.level : 'Unknown'}'),
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
                title: Text(topic.title),
                subtitle: Text(topic.description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(topic.level),
                      backgroundColor: _getLevelColor(topic.level),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
                onTap: () => _selectTopic(topic),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTopicExplanation() {
    if (selectedTopic == null) {
      return const Center(child: Text('No topic selected.'));
    }

    final topic = selectedTopic!;

    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getGrammarTopicExplanation(topic.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading explanation: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}), // Trigger rebuild
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final explanationData = snapshot.data ?? {};
        final explanation = explanationData['explanation'] ?? 'Explanation coming soon...';
        final examples = List<String>.from(explanationData['examples'] ?? [
          'Example sentences will be available soon.',
          'Check back later for detailed examples.',
        ]);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topic header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade100, Colors.deepPurple.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.school, color: Colors.deepPurple, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            topic.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(topic.level),
                          backgroundColor: _getLevelColor(topic.level),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      topic.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Explanation section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'How to use this grammar',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Examples section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.format_quote, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Examples',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...examples
                        .map<Widget>((example) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, 
                                         color: Colors.green.shade600, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        example,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Start exercises button
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startExercises,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.quiz_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Start Exercises',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseList() {
    if (exercises.isEmpty) {
      return const Center(child: Text('No exercises found.'));
    }
    
    return Column(
      children: [
        // Submit/Reset Buttons at the top
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              if (!showResults) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canSubmit() ? _submitAnswers : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Submit All Answers (${_getAnsweredCount()}/${exercises.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Quiz Results 📊',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Score: ${correctAnswers!}/${totalQuestions!} (${(score! * 100).toInt()}%)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: score! >= 0.7 ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                        ),
                        if (score! >= 0.7) ...[
                          const SizedBox(height: 4),
                          Text(
                            '🎉 Great job!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          Text(
                            '💪 Keep practicing!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _resetQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  child: const Text(
                    'Retake Quiz',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Exercises List
        Expanded(
          child: ListView(
            children: exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final ex = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Question ${index + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    GrammarExerciseWidget(
                      exercise: ex,
                      onAnswerChanged: (int? answer) {
                        setState(() {
                          exerciseAnswers[ex.id] = answer;
                        });
                      },
                      selectedAnswer: exerciseAnswers[ex.id],
                      showResults: showResults,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  bool _canSubmit() {
    return exerciseAnswers.length == exercises.length && 
           exerciseAnswers.values.every((answer) => answer != null);
  }

  int _getAnsweredCount() {
    return exerciseAnswers.values.where((answer) => answer != null).length;
  }

  void _submitAnswers({bool isRestoring = false}) {
    if (!_canSubmit()) return;

    int correct = 0;
    int total = exercises.length;

    for (final exercise in exercises) {
      final selectedAnswer = exerciseAnswers[exercise.id];
      if (selectedAnswer == exercise.correctIndex) {
        correct++;
      }
    }

    setState(() {
      showResults = true;
      correctAnswers = correct;
      totalQuestions = total;
      score = correct / total;
    });

    // Only save results and show snackbar for new submissions
    if (!isRestoring) {
      // Save results to backend
      _saveQuizResults();

      // Show completion message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quiz completed! You scored ${correct}/${total} (${((correct / total) * 100).toInt()}%)',
          ),
          backgroundColor: correct >= total * 0.7 ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _resetQuiz() {
    setState(() {
      exerciseAnswers.clear();
      showResults = false;
      score = null;
      correctAnswers = null;
      totalQuestions = null;
    });

    // Clear previous results from backend
    _clearPreviousResults();
  }

  Future<void> _clearPreviousResults() async {
    if (userId == null || selectedTopic == null) return;

    try {
      final result = await ApiService.clearUserTopicProgress(userId!, selectedTopic!.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Previous quiz results cleared successfully',
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );

      // Refresh exercises to remove any previous completion status
      _fetchExercises(selectedTopic!.id);
      
    } catch (e) {
      print('Error clearing previous results: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to clear previous results, but you can still retake the quiz'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _saveQuizResults() async {
    if (userId == null || selectedTopic == null || selectedCategory == null) return;

    try {
      // Save individual exercise results
      for (final exercise in exercises) {
        final selectedAnswer = exerciseAnswers[exercise.id];
        final isCorrect = selectedAnswer == exercise.correctIndex;
        
        await ApiService.saveGrammarStudyResult(
          userId: userId!,
          categoryId: selectedCategory!.id,
          topicId: selectedTopic!.id,
          exerciseId: exercise.id,
          isCorrect: isCorrect,
          selectedAnswer: selectedAnswer ?? -1,
        );
      }
    } catch (e) {
      print('Error saving quiz results: $e');
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'easy':
        return Colors.green.shade100;
      case 'medium':
        return Colors.orange.shade100;
      case 'hard':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}

class GrammarExerciseWidget extends StatefulWidget {
  final GrammarExercise exercise;
  final void Function(int? selectedAnswer) onAnswerChanged;
  final int? selectedAnswer;
  final bool showResults;
  const GrammarExerciseWidget({
    required this.exercise,
    required this.onAnswerChanged,
    this.selectedAnswer,
    this.showResults = false,
    super.key,
  });

  @override
  State<GrammarExerciseWidget> createState() => _GrammarExerciseWidgetState();
}

class _GrammarExerciseWidgetState extends State<GrammarExerciseWidget> {
  @override
  Widget build(BuildContext context) {
    final correctIndex = widget.exercise.correctIndex;
    final selectedIndex = widget.selectedAnswer;
    final showResults = widget.showResults;
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.exercise.question,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(widget.exercise.difficulty),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.exercise.difficulty,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(widget.exercise.options.length, (i) {
            final isCorrect = i == correctIndex;
            final isSelected = i == selectedIndex;
            Color? color;
            if (showResults) {
              if (isSelected && isCorrect)
                color = Colors.green.shade200;
              else if (isSelected && !isCorrect)
                color = Colors.red.shade200;
              else if (isCorrect)
                color = Colors.green.shade50;
            } else if (isSelected) {
              color = Colors.blue.shade100;
            }
            return ListTile(
              title: Text(widget.exercise.options[i]),
              tileColor: color,
              leading: Radio<int>(
                value: i,
                groupValue: selectedIndex,
                onChanged: showResults
                    ? null
                    : (val) => widget.onAnswerChanged(val),
              ),
              onTap: showResults ? null : () => widget.onAnswerChanged(i),
              trailing: showResults && isCorrect
                  ? Icon(Icons.check_circle, color: Colors.green.shade600)
                  : showResults && isSelected && !isCorrect
                      ? Icon(Icons.cancel, color: Colors.red.shade600)
                      : null,
            );
          }),
          if (showResults && selectedIndex != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explanation:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The correct answer is "${widget.exercise.options[correctIndex]}" (option ${correctIndex + 1}).',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Difficulty: ${widget.exercise.difficulty}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green.shade200;
      case 'medium':
        return Colors.orange.shade200;
      case 'hard':
        return Colors.red.shade200;
      default:
        return Colors.grey.shade200;
    }
  }
}
