import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/spaced_repetition_service.dart';
import '../../services/notification_service.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _vocabulary = [];
  List<Map<String, dynamic>> _reviewWords = [];
  int _currentIndex = 0;
  bool _showDefinition = false;
  bool _isLoading = true;
  late AnimationController _flipController;
  late AnimationController _slideController;
  late Animation<double> _flipAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));
    
    _loadVocabulary();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadVocabulary() async {
    try {
      final vocab = await ApiService.getVocab();
      final reviewWords = SpacedRepetitionService.getWordsForReview(vocab.cast<Map<String, dynamic>>());
      
      setState(() {
        _vocabulary = vocab.cast<Map<String, dynamic>>();
        _reviewWords = reviewWords.isNotEmpty ? reviewWords : _vocabulary.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vocabulary: $e')),
        );
      }
    }
  }

  void _flipCard() {
    if (!_showDefinition) {
      _flipController.forward();
      setState(() => _showDefinition = true);
    }
  }

  void _nextCard(int quality) async {
    if (_currentIndex < _reviewWords.length - 1) {
      await _slideController.forward();
      
      // Update spaced repetition data
      final currentWord = _reviewWords[_currentIndex];
      final updatedData = SpacedRepetitionService.calculateNextReview(
        quality,
        currentWord['repetitions'] ?? 0,
        currentWord['easeFactor'] ?? 2.5,
        currentWord['interval'] ?? 1,
      );
      
      // Schedule next review notification
      await NotificationService.scheduleReviewReminder(
        reviewTime: updatedData['nextReview'],
        wordOrTopic: currentWord['word'] ?? '',
      );
      
      setState(() {
        _currentIndex++;
        _showDefinition = false;
      });
      
      _flipController.reset();
      _slideController.reset();
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Great Job!'),
        content: const Text('You\'ve completed today\'s flashcard review. Keep up the excellent work!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentIndex = 0;
                _showDefinition = false;
              });
            },
            child: const Text('Review Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        title: const Text('Flashcard Review'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVocabulary,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviewWords.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Progress indicator
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Card ${_currentIndex + 1} of ${_reviewWords.length}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.deepPurple.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (_currentIndex + 1) / _reviewWords.length,
                            backgroundColor: Colors.deepPurple.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                          ),
                        ],
                      ),
                    ),
                    
                    // Flashcard
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildFlashcard(),
                        ),
                      ),
                    ),
                    
                    // Action buttons
                    if (_showDefinition) _buildActionButtons(),
                    
                    const SizedBox(height: 16),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 80,
            color: Colors.deepPurple.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'No words to review!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some vocabulary words first',
            style: TextStyle(
              fontSize: 16,
              color: Colors.deepPurple.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go to Vocabulary'),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcard() {
    final currentWord = _reviewWords[_currentIndex];
    
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final isShowingFront = _flipAnimation.value < 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_flipAnimation.value * 3.14159),
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: isShowingFront
                  ? _buildCardFront(currentWord)
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(3.14159),
                      child: _buildCardBack(currentWord),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardFront(Map<String, dynamic> word) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.quiz,
          size: 48,
          color: Colors.deepPurple.shade300,
        ),
        const SizedBox(height: 24),
        Text(
          word['word'] ?? '',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          'Tap to reveal meaning',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildCardBack(Map<String, dynamic> word) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            word['word'] ?? '',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 50,
            height: 2,
            color: Colors.deepPurple.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            word['meaning'] ?? '',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black87,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'How well did you know this word?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _nextCard(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, size: 20),
                  SizedBox(height: 4),
                  Text('Didn\'t Know', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _nextCard(3),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline, size: 20),
                  SizedBox(height: 4),
                  Text('Sort of', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _nextCard(5),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 20),
                  SizedBox(height: 4),
                  Text('Easy!', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
