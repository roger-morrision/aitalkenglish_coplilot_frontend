import 'dart:math';

class SpacedRepetitionService {
  // SM2 Algorithm implementation
  static Map<String, dynamic> calculateNextReview(int quality, int repetitions, double easeFactor, int interval) {
    // Quality: 0-5 (0=complete blackout, 5=perfect response)
    // EF (Ease Factor): Initially 2.5
    // Interval: Days until next review
    
    if (quality >= 3) {
      // Correct response
      if (repetitions == 0) {
        interval = 1;
      } else if (repetitions == 1) {
        interval = 6;
      } else {
        interval = (interval * easeFactor).round();
      }
      repetitions++;
    } else {
      // Incorrect response - restart
      repetitions = 0;
      interval = 1;
    }
    
    // Update ease factor
    easeFactor = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (easeFactor < 1.3) easeFactor = 1.3;
    
    return {
      'repetitions': repetitions,
      'easeFactor': easeFactor,
      'interval': interval,
      'nextReview': DateTime.now().add(Duration(days: interval)),
    };
  }
  
  // Get words due for review
  static List<Map<String, dynamic>> getWordsForReview(List<Map<String, dynamic>> vocabulary) {
    final now = DateTime.now();
    return vocabulary.where((word) {
      final nextReview = word['nextReview'] != null 
          ? DateTime.parse(word['nextReview']) 
          : now.subtract(Duration(days: 1)); // If no next review, it's due
      return nextReview.isBefore(now) || nextReview.isAtSameMomentAs(now);
    }).toList();
  }
  
  // Leitner system boxes (simpler alternative)
  static int getLeitnerBox(int correctCount, int incorrectCount) {
    if (correctCount == 0) return 1;
    if (incorrectCount > correctCount) return max(1, correctCount - incorrectCount + 1);
    if (correctCount >= 5) return 5;
    return min(5, correctCount + 1);
  }
  
  static int getLeitnerIntervalDays(int box) {
    switch (box) {
      case 1: return 1;
      case 2: return 3;
      case 3: return 7;
      case 4: return 14;
      case 5: return 30;
      default: return 1;
    }
  }
}
