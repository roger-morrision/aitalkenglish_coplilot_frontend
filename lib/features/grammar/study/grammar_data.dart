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

// Comprehensive grammar study data with extensive categories, topics, and exercises
final List<GrammarCategory> grammarCategories = [
  // BEGINNER LEVEL
  GrammarCategory(
    id: 'foundations',
    name: 'Grammar Foundations',
    topics: [
      GrammarTopic(
        id: 'present_simple',
        title: 'Present Simple Tense',
        description: 'Learn the basic present tense for daily actions and facts.',
        level: 'easy',
        exercises: [
          GrammarExercise(
            id: 'ps1',
            question: 'She ____ to school every day.',
            options: ['go', 'goes', 'going', 'gone'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'ps2',
            question: 'I ____ coffee in the morning.',
            options: ['drink', 'drinks', 'drank', 'drunk'],
            correctIndex: 0,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'ps3',
            question: 'The sun ____ in the east.',
            options: ['rise', 'rises', 'rising', 'rose'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'ps4',
            question: 'They ____ soccer on weekends.',
            options: ['play', 'plays', 'playing', 'played'],
            correctIndex: 0,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'ps5',
            question: 'My brother ____ in London.',
            options: ['live', 'lives', 'living', 'lived'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
        ],
      ),
      GrammarTopic(
        id: 'articles',
        title: 'Articles (a/an/the)',
        description: 'Master the use of definite and indefinite articles.',
        level: 'easy',
        exercises: [
          GrammarExercise(
            id: 'art1',
            question: 'I saw ____ elephant at the zoo.',
            options: ['a', 'an', 'the', 'no article'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'art2',
            question: 'Can you pass me ____ salt?',
            options: ['a', 'an', 'the', 'no article'],
            correctIndex: 2,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'art3',
            question: 'She is ____ honest person.',
            options: ['a', 'an', 'the', 'no article'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'art4',
            question: '____ book on the table is mine.',
            options: ['A', 'An', 'The', 'No article'],
            correctIndex: 2,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'art5',
            question: 'I need ____ umbrella for the rain.',
            options: ['a', 'an', 'the', 'no article'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
        ],
      ),
      GrammarTopic(
        id: 'plural_nouns',
        title: 'Plural Nouns',
        description: 'Learn regular and irregular plural forms.',
        level: 'easy',
        exercises: [
          GrammarExercise(
            id: 'pn1',
            question: 'There are many ____ in the park.',
            options: ['child', 'childs', 'children', 'childes'],
            correctIndex: 2,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'pn2',
            question: 'I have two ____ at home.',
            options: ['cat', 'cats', 'cates', 'catss'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'pn3',
            question: 'The ____ are running in the field.',
            options: ['mouse', 'mouses', 'mice', 'mices'],
            correctIndex: 2,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'pn4',
            question: 'She bought three ____ for dinner.',
            options: ['fish', 'fishs', 'fishes', 'fishies'],
            correctIndex: 0,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'pn5',
            question: 'The ____ are very sharp.',
            options: ['knife', 'knifes', 'knives', 'knifess'],
            correctIndex: 2,
            difficulty: 'easy',
          ),
        ],
      ),
      GrammarTopic(
        id: 'pronouns',
        title: 'Personal Pronouns',
        description: 'Subject and object pronouns in sentences.',
        level: 'easy',
        exercises: [
          GrammarExercise(
            id: 'pr1',
            question: '____ is my best friend.',
            options: ['Him', 'He', 'His', 'Her'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'pr2',
            question: 'Can you help ____?',
            options: ['I', 'me', 'my', 'mine'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'pr3',
            question: '____ are going to the movies.',
            options: ['Us', 'We', 'Our', 'Ours'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'pr4',
            question: 'I gave ____ the book.',
            options: ['she', 'her', 'hers', 'herself'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'pr5',
            question: '____ car is parked outside.',
            options: ['They', 'Them', 'Their', 'Theirs'],
            correctIndex: 2,
            difficulty: 'easy',
          ),
        ],
      ),
    ],
  ),

  // ELEMENTARY LEVEL
  GrammarCategory(
    id: 'elementary',
    name: 'Elementary Grammar',
    topics: [
      GrammarTopic(
        id: 'past_simple',
        title: 'Past Simple Tense',
        description: 'Express completed actions in the past.',
        level: 'easy',
        exercises: [
          GrammarExercise(
            id: 'past1',
            question: 'I ____ to the store yesterday.',
            options: ['go', 'went', 'gone', 'going'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'past2',
            question: 'She ____ her homework last night.',
            options: ['finish', 'finished', 'finishing', 'finishes'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'past3',
            question: 'They ____ a movie on Saturday.',
            options: ['watch', 'watched', 'watching', 'watches'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'past4',
            question: 'We ____ at the beach for three hours.',
            options: ['stay', 'stayed', 'staying', 'stays'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'past5',
            question: 'He ____ his keys in the car.',
            options: ['leave', 'left', 'leaving', 'leaves'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
        ],
      ),
      GrammarTopic(
        id: 'future_simple',
        title: 'Future Simple (will)',
        description: 'Talk about future plans and predictions.',
        level: 'easy',
        exercises: [
          GrammarExercise(
            id: 'fut1',
            question: 'I ____ call you tomorrow.',
            options: ['will', 'would', 'shall', 'should'],
            correctIndex: 0,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'fut2',
            question: 'She ____ arrive at 3 PM.',
            options: ['will', 'would', 'wills', 'willing'],
            correctIndex: 0,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'fut3',
            question: 'They ____ not come to the party.',
            options: ['will', 'would', 'shall', 'should'],
            correctIndex: 0,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'fut4',
            question: '____ you help me with this?',
            options: ['Will', 'Would', 'Shall', 'Should'],
            correctIndex: 0,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'fut5',
            question: 'It ____ rain tomorrow.',
            options: ['will', 'would', 'shall', 'should'],
            correctIndex: 0,
            difficulty: 'easy',
          ),
        ],
      ),
      GrammarTopic(
        id: 'prepositions',
        title: 'Common Prepositions',
        description: 'Learn prepositions of time, place, and direction.',
        level: 'easy',
        exercises: [
          GrammarExercise(
            id: 'prep1',
            question: 'The book is ____ the table.',
            options: ['in', 'on', 'at', 'by'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'prep2',
            question: 'I will meet you ____ 3 o\'clock.',
            options: ['in', 'on', 'at', 'by'],
            correctIndex: 2,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'prep3',
            question: 'She lives ____ New York.',
            options: ['in', 'on', 'at', 'by'],
            correctIndex: 0,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'prep4',
            question: 'The cat is hiding ____ the bed.',
            options: ['under', 'over', 'above', 'below'],
            correctIndex: 0,
            difficulty: 'easy',
          ),
          GrammarExercise(
            id: 'prep5',
            question: 'We arrived ____ Monday morning.',
            options: ['in', 'on', 'at', 'by'],
            correctIndex: 1,
            difficulty: 'easy',
          ),
        ],
      ),
    ],
  ),

  // INTERMEDIATE LEVEL
  GrammarCategory(
    id: 'intermediate',
    name: 'Intermediate Grammar',
    topics: [
      GrammarTopic(
        id: 'present_perfect',
        title: 'Present Perfect Tense',
        description: 'Connect past actions to the present moment.',
        level: 'medium',
        exercises: [
          GrammarExercise(
            id: 'pp1',
            question: 'They ____ finished their homework.',
            options: ['has', 'have', 'had', 'having'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'pp2',
            question: 'She ____ never been to Paris.',
            options: ['has', 'have', 'had', 'having'],
            correctIndex: 0,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'pp3',
            question: 'I ____ already seen that movie.',
            options: ['has', 'have', 'had', 'having'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'pp4',
            question: 'We ____ lived here for five years.',
            options: ['has', 'have', 'had', 'having'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'pp5',
            question: 'He ____ just arrived at the airport.',
            options: ['has', 'have', 'had', 'having'],
            correctIndex: 0,
            difficulty: 'medium',
          ),
        ],
      ),
      GrammarTopic(
        id: 'past_continuous',
        title: 'Past Continuous Tense',
        description: 'Describe ongoing actions in the past.',
        level: 'medium',
        exercises: [
          GrammarExercise(
            id: 'pc1',
            question: 'I ____ TV when she called.',
            options: ['watched', 'was watching', 'am watching', 'watch'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'pc2',
            question: 'They ____ dinner at 7 PM.',
            options: ['had', 'were having', 'are having', 'have'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'pc3',
            question: 'She ____ while I was studying.',
            options: ['sang', 'was singing', 'is singing', 'sings'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'pc4',
            question: 'What ____ you doing yesterday at 3 PM?',
            options: ['was', 'were', 'are', 'is'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'pc5',
            question: 'It ____ raining when we left.',
            options: ['was', 'were', 'is', 'are'],
            correctIndex: 0,
            difficulty: 'medium',
          ),
        ],
      ),
      GrammarTopic(
        id: 'comparatives_superlatives',
        title: 'Comparatives & Superlatives',
        description: 'Compare people, places, and things.',
        level: 'medium',
        exercises: [
          GrammarExercise(
            id: 'comp1',
            question: 'This is the ____ book I have ever read.',
            options: ['good', 'better', 'best', 'well'],
            correctIndex: 2,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'comp2',
            question: 'She is ____ than her sister.',
            options: ['tall', 'taller', 'tallest', 'more tall'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'comp3',
            question: 'This exercise is ____ difficult than the previous one.',
            options: ['more', 'most', 'much', 'many'],
            correctIndex: 0,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'comp4',
            question: 'He is the ____ student in the class.',
            options: ['smart', 'smarter', 'smartest', 'most smart'],
            correctIndex: 2,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'comp5',
            question: 'This car is ____ expensive than that one.',
            options: ['less', 'least', 'little', 'few'],
            correctIndex: 0,
            difficulty: 'medium',
          ),
        ],
      ),
      GrammarTopic(
        id: 'modal_verbs',
        title: 'Modal Verbs',
        description: 'Express ability, possibility, and obligation.',
        level: 'medium',
        exercises: [
          GrammarExercise(
            id: 'mod1',
            question: 'You ____ wear a helmet while riding a bike.',
            options: ['can', 'could', 'should', 'would'],
            correctIndex: 2,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'mod2',
            question: 'I ____ swim when I was five years old.',
            options: ['can', 'could', 'should', 'would'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'mod3',
            question: '____ you help me carry this box?',
            options: ['Can', 'Could', 'Should', 'Would'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'mod4',
            question: 'Students ____ not use phones during exams.',
            options: ['can', 'could', 'must', 'might'],
            correctIndex: 2,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'mod5',
            question: 'It ____ rain later today.',
            options: ['can', 'could', 'must', 'might'],
            correctIndex: 3,
            difficulty: 'medium',
          ),
        ],
      ),
    ],
  ),

  // UPPER-INTERMEDIATE LEVEL
  GrammarCategory(
    id: 'upper_intermediate',
    name: 'Upper-Intermediate Grammar',
    topics: [
      GrammarTopic(
        id: 'perfect_continuous',
        title: 'Perfect Continuous Tenses',
        description: 'Combine perfect and continuous aspects.',
        level: 'medium',
        exercises: [
          GrammarExercise(
            id: 'perfcont1',
            question: 'I ____ working here for three years.',
            options: ['have been', 'has been', 'had been', 'will have been'],
            correctIndex: 0,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'perfcont2',
            question: 'She ____ studying English since childhood.',
            options: ['have been', 'has been', 'had been', 'will have been'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'perfcont3',
            question: 'They ____ waiting for an hour when the bus arrived.',
            options: ['have been', 'has been', 'had been', 'will have been'],
            correctIndex: 2,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'perfcont4',
            question: 'By next year, we ____ living here for a decade.',
            options: ['have been', 'has been', 'had been', 'will have been'],
            correctIndex: 3,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'perfcont5',
            question: 'How long ____ you been learning to drive?',
            options: ['have', 'has', 'had', 'will have'],
            correctIndex: 0,
            difficulty: 'medium',
          ),
        ],
      ),
      GrammarTopic(
        id: 'relative_clauses',
        title: 'Relative Clauses',
        description: 'Join sentences with relative pronouns.',
        level: 'medium',
        exercises: [
          GrammarExercise(
            id: 'rel1',
            question: 'The man ____ lives next door is a doctor.',
            options: ['who', 'which', 'that', 'whose'],
            correctIndex: 0,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'rel2',
            question: 'The book ____ I bought yesterday is interesting.',
            options: ['who', 'which', 'that', 'whose'],
            correctIndex: 2,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'rel3',
            question: 'She is the student ____ essay won the prize.',
            options: ['who', 'which', 'that', 'whose'],
            correctIndex: 3,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'rel4',
            question: 'The city ____ we visited was beautiful.',
            options: ['who', 'which', 'where', 'when'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'rel5',
            question: 'This is the house ____ I grew up.',
            options: ['who', 'which', 'where', 'when'],
            correctIndex: 2,
            difficulty: 'medium',
          ),
        ],
      ),
      GrammarTopic(
        id: 'gerunds_infinitives',
        title: 'Gerunds and Infinitives',
        description: 'Learn when to use -ing forms and to + verb.',
        level: 'medium',
        exercises: [
          GrammarExercise(
            id: 'ger1',
            question: 'I enjoy ____ books in my free time.',
            options: ['read', 'reading', 'to read', 'reads'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'ger2',
            question: 'She decided ____ a new job.',
            options: ['find', 'finding', 'to find', 'finds'],
            correctIndex: 2,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'ger3',
            question: 'We finished ____ the project yesterday.',
            options: ['complete', 'completing', 'to complete', 'completes'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'ger4',
            question: 'He promised ____ on time.',
            options: ['arrive', 'arriving', 'to arrive', 'arrives'],
            correctIndex: 2,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'ger5',
            question: 'They avoided ____ in the traffic jam.',
            options: ['drive', 'driving', 'to drive', 'drives'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
        ],
      ),
    ],
  ),

  // ADVANCED LEVEL
  GrammarCategory(
    id: 'advanced',
    name: 'Advanced Grammar',
    topics: [
      GrammarTopic(
        id: 'conditionals',
        title: 'Conditional Sentences',
        description: 'Master all types of conditional structures.',
        level: 'hard',
        exercises: [
          GrammarExercise(
            id: 'cond1',
            question: 'If I ____ you, I would apologize.',
            options: ['am', 'was', 'were', 'be'],
            correctIndex: 2,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'cond2',
            question: 'If she ____ harder, she will pass the exam.',
            options: ['study', 'studies', 'studied', 'studying'],
            correctIndex: 1,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'cond3',
            question: 'If they ____ earlier, they would have caught the train.',
            options: ['left', 'had left', 'leave', 'have left'],
            correctIndex: 1,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'cond4',
            question: 'Unless you ____ now, you\'ll be late.',
            options: ['leave', 'left', 'will leave', 'leaving'],
            correctIndex: 0,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'cond5',
            question: 'I wish I ____ speak French fluently.',
            options: ['can', 'could', 'will', 'would'],
            correctIndex: 1,
            difficulty: 'hard',
          ),
        ],
      ),
      GrammarTopic(
        id: 'passive_voice',
        title: 'Passive Voice',
        description: 'Transform active sentences to passive structures.',
        level: 'hard',
        exercises: [
          GrammarExercise(
            id: 'pass1',
            question: 'The cake ____ by my mom.',
            options: ['was made', 'made', 'is make', 'was making'],
            correctIndex: 0,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'pass2',
            question: 'The report ____ completed by tomorrow.',
            options: ['will be', 'will', 'is being', 'has been'],
            correctIndex: 0,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'pass3',
            question: 'The house ____ built in 1995.',
            options: ['is', 'was', 'has been', 'had been'],
            correctIndex: 1,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'pass4',
            question: 'The problem ____ being discussed right now.',
            options: ['is', 'was', 'has been', 'had been'],
            correctIndex: 0,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'pass5',
            question: 'The movie ____ seen by millions of people.',
            options: ['is', 'was', 'has been', 'had been'],
            correctIndex: 2,
            difficulty: 'hard',
          ),
        ],
      ),
      GrammarTopic(
        id: 'reported_speech',
        title: 'Reported Speech',
        description: 'Convert direct speech to indirect speech.',
        level: 'hard',
        exercises: [
          GrammarExercise(
            id: 'rep1',
            question: 'She said that she ____ busy.',
            options: ['is', 'was', 'were', 'be'],
            correctIndex: 1,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'rep2',
            question: 'He told me that he ____ the next day.',
            options: ['will come', 'would come', 'comes', 'came'],
            correctIndex: 1,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'rep3',
            question: 'They said they ____ the movie the previous week.',
            options: ['see', 'saw', 'had seen', 'have seen'],
            correctIndex: 2,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'rep4',
            question: 'She asked me if I ____ her.',
            options: ['help', 'helped', 'would help', 'will help'],
            correctIndex: 2,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'rep5',
            question: 'He wondered where I ____.',
            options: ['live', 'lived', 'am living', 'have lived'],
            correctIndex: 1,
            difficulty: 'hard',
          ),
        ],
      ),
      GrammarTopic(
        id: 'subjunctive_mood',
        title: 'Subjunctive Mood',
        description: 'Express hypothetical and formal situations.',
        level: 'hard',
        exercises: [
          GrammarExercise(
            id: 'subj1',
            question: 'I suggest that he ____ more carefully.',
            options: ['drive', 'drives', 'drove', 'driving'],
            correctIndex: 0,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'subj2',
            question: 'It\'s important that she ____ on time.',
            options: ['arrive', 'arrives', 'arrived', 'arriving'],
            correctIndex: 0,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'subj3',
            question: 'If I ____ a millionaire, I would travel the world.',
            options: ['am', 'was', 'were', 'be'],
            correctIndex: 2,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'subj4',
            question: 'I wish it ____ raining.',
            options: ['stop', 'stops', 'stopped', 'would stop'],
            correctIndex: 3,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'subj5',
            question: 'The teacher demanded that all students ____ their homework.',
            options: ['submit', 'submits', 'submitted', 'submitting'],
            correctIndex: 0,
            difficulty: 'hard',
          ),
        ],
      ),
    ],
  ),

  // BUSINESS ENGLISH
  GrammarCategory(
    id: 'business',
    name: 'Business English Grammar',
    topics: [
      GrammarTopic(
        id: 'formal_language',
        title: 'Formal Language Structures',
        description: 'Professional communication patterns.',
        level: 'medium',
        exercises: [
          GrammarExercise(
            id: 'form1',
            question: 'I would like to ____ your attention to the quarterly results.',
            options: ['bring', 'take', 'draw', 'pull'],
            correctIndex: 2,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'form2',
            question: 'Please ____ hesitate to contact me if you have questions.',
            options: ['not', 'don\'t', 'do not', 'never'],
            correctIndex: 2,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'form3',
            question: 'We ____ appreciate your prompt response.',
            options: ['would', 'will', 'should', 'could'],
            correctIndex: 0,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'form4',
            question: 'I am writing to ____ about the new policy.',
            options: ['inform', 'tell', 'say', 'speak'],
            correctIndex: 0,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'form5',
            question: 'Could you please ____ me know your availability?',
            options: ['make', 'tell', 'let', 'give'],
            correctIndex: 2,
            difficulty: 'medium',
          ),
        ],
      ),
      GrammarTopic(
        id: 'email_structure',
        title: 'Email Grammar Patterns',
        description: 'Professional email communication.',
        level: 'medium',
        exercises: [
          GrammarExercise(
            id: 'email1',
            question: 'Thank you for ____ back to me so quickly.',
            options: ['get', 'getting', 'got', 'to get'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'email2',
            question: 'I ____ forward to hearing from you.',
            options: ['look', 'am looking', 'looked', 'will look'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'email3',
            question: 'Please find the document ____.',
            options: ['attach', 'attached', 'attaching', 'attachment'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'email4',
            question: 'I would be ____ to discuss this further.',
            options: ['please', 'pleased', 'pleasure', 'pleasant'],
            correctIndex: 1,
            difficulty: 'medium',
          ),
          GrammarExercise(
            id: 'email5',
            question: 'Should you have any questions, please ____ me know.',
            options: ['make', 'tell', 'let', 'give'],
            correctIndex: 2,
            difficulty: 'medium',
          ),
        ],
      ),
    ],
  ),

  // ACADEMIC ENGLISH
  GrammarCategory(
    id: 'academic',
    name: 'Academic English Grammar',
    topics: [
      GrammarTopic(
        id: 'complex_sentences',
        title: 'Complex Sentence Structures',
        description: 'Advanced academic writing patterns.',
        level: 'hard',
        exercises: [
          GrammarExercise(
            id: 'complex1',
            question: '____ the research was thorough, the conclusions were limited.',
            options: ['Although', 'However', 'Therefore', 'Moreover'],
            correctIndex: 0,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'complex2',
            question: 'The study indicates that ____ more research is needed.',
            options: ['farther', 'further', 'father', 'furthermore'],
            correctIndex: 1,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'complex3',
            question: '____ the data suggests significant correlation.',
            options: ['Nevertheless', 'Furthermore', 'However', 'Therefore'],
            correctIndex: 1,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'complex4',
            question: 'The hypothesis ____ that climate change affects migration.',
            options: ['suggests', 'suggesting', 'is suggested', 'suggestion'],
            correctIndex: 0,
            difficulty: 'hard',
          ),
          GrammarExercise(
            id: 'complex5',
            question: '____ careful analysis, the results were inconclusive.',
            options: ['Despite', 'Although', 'However', 'Therefore'],
            correctIndex: 0,
            difficulty: 'hard',
          ),
        ],
      ),
    ],
  ),
];
