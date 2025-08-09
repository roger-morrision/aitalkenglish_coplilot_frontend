// Grammar topics, categories, and exercises for the study module

class GrammarCategory {
  final String id;
  final String name;
  final List<GrammarTopic> topics;

  GrammarCategory({required this.id, required this.name, required this.topics});
}

class GrammarTopic {
  final String id;
  final String title;
  final String description;
  final String level; // easy, medium, hard
  final List<GrammarExercise> exercises;

  GrammarTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.exercises,
  });
}

class GrammarExercise {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String difficulty; // easy, medium, hard

  GrammarExercise({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
  });
}

// Example data (expand as needed)
final List<GrammarCategory> grammarCategories = [
  GrammarCategory(
    id: 'basic',
    name: 'Basic Grammar',
    topics: [
      GrammarTopic(
        id: 'present_simple',
        title: 'Present Simple',
        description: 'Usage and rules for the Present Simple tense.',
        level: 'easy',
        exercises: [
          GrammarExercise(
            id: 'ex1',
            question: 'She ____ to school every day.',
            options: ['go', 'goes', 'going', 'gone'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'ex2',
            question: 'I ____ coffee in the morning.',
            options: ['drink', 'drinks', 'drank', 'drunk'],
            correctIndex: 0,
            difficulty: 'easy',
          ),
        ],
      ),
      GrammarTopic(
        id: 'articles',
        title: 'Articles (a/an/the)',
        description: 'How to use articles correctly in English.',
        level: 'easy',
        exercises: [
          GrammarExercise(
            id: 'ex3',
            question: 'I saw ____ elephant at the zoo.',
            options: ['a', 'an', 'the', 'no article'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'ex4',
            question: 'Can you pass me ____ salt?',
            options: ['a', 'an', 'the', 'no article'],
            correctIndex: 2,
            difficulty: 'easy',
          ),
        ],
      ),
      GrammarTopic(
        id: 'plural_nouns',
        title: 'Plural Nouns',
        description: 'Forming and using plural nouns.',
        level: 'easy',
        exercises: [
          GrammarExercise(
            id: 'ex5',
            question: 'There are many ____ in the park.',
            options: ['child', 'childs', 'children', 'childes'],
            correctIndex: 2,
            difficulty: 'easy',
          ),
        ],
      ),
    ],
  ),
  GrammarCategory(
    id: 'intermediate',
    name: 'Intermediate Grammar',
    topics: [
      GrammarTopic(
        id: 'present_perfect',
        title: 'Present Perfect',
        description: 'Usage and rules for the Present Perfect tense.',
        level: 'medium',
        exercises: [
          GrammarExercise(
            id: 'ex6',
            question: 'They ____ finished their homework.',
            options: ['has', 'have', 'had', 'having'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
        ],
      ),
      GrammarTopic(
        id: 'past_continuous',
        title: 'Past Continuous',
        description: 'How to use the Past Continuous tense.',
        level: 'medium',
        exercises: [
          GrammarExercise(
            id: 'ex7',
            question: 'I ____ TV when she called.',
            options: ['watched', 'was watching', 'am watching', 'watch'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
        ],
      ),
      GrammarTopic(
        id: 'comparatives_superlatives',
        title: 'Comparatives & Superlatives',
        description: 'Comparing things using adjectives.',
        level: 'medium',
        exercises: [
          GrammarExercise(
            id: 'ex8',
            question: 'This is the ____ book I have ever read.',
            options: ['good', 'better', 'best', 'well'],
            correctIndex: 2,
            difficulty: 'medium',
          ),
        ],
      ),
    ],
  ),
  GrammarCategory(
    id: 'advanced',
    name: 'Advanced Grammar',
    topics: [
      GrammarTopic(
        id: 'conditionals',
        title: 'Conditionals',
        description: 'Zero, first, second, and third conditionals.',
        level: 'hard',
        exercises: [
          GrammarExercise(
            id: 'ex9',
            question: 'If I ____ you, I would apologize.',
            options: ['am', 'was', 'were', 'be'],
            correctIndex: 2,
            difficulty: 'hard',
          ),
        ],
      ),
      GrammarTopic(
        id: 'passive_voice',
        title: 'Passive Voice',
        description: 'How to form and use the passive voice.',
        level: 'hard',
        exercises: [
          GrammarExercise(
            id: 'ex10',
            question: 'The cake ____ by my mom.',
            options: ['was made', 'made', 'is make', 'was making'],
            correctIndex: 0,
            difficulty: 'hard',
          ),
        ],
      ),
      GrammarTopic(
        id: 'reported_speech',
        title: 'Reported Speech',
        description: 'How to use reported (indirect) speech.',
        level: 'hard',
        exercises: [
          GrammarExercise(
            id: 'ex11',
            question: 'She said that she ____ busy.',
            options: ['is', 'was', 'were', 'be'],
            correctIndex: 1,
            difficulty: 'hard',
          ),
        ],
      ),
    ],
  ),
];
