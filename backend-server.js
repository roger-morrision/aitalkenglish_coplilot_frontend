require("dotenv").config();
const express = require("express");
const cors = require("cors");
const sqlite3 = require("sqlite3").verbose();
const axios = require("axios");

const app = express();

// Register middleware BEFORE any routes
app.use(
  cors({
    origin: "*", // Allow all origins for now
    credentials: false, // Disable credentials when using wildcard
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: [
      "Content-Type",
      "Authorization",
      "Accept",
      "Origin",
      "X-Requested-With",
    ],
  })
);
app.use(express.json());

// Save a grammar study result for a user
app.post("/user/:userId/grammar-study", (req, res) => {
  const { userId } = req.params;
  if (!req.body || typeof req.body !== "object") {
    console.error(
      "[grammar-study] req.body is missing or not an object",
      req.body
    );
    return res
      .status(400)
      .json({ error: "Request body is missing or invalid JSON" });
  }
  const { category_id, topic_id, exercise_id, is_correct } = req.body;
  if (
    category_id === undefined ||
    topic_id === undefined ||
    exercise_id === undefined ||
    typeof is_correct !== "boolean"
  ) {
    console.error("[grammar-study] Missing or invalid fields", req.body);
    return res.status(400).json({
      error:
        "category_id, topic_id, exercise_id, and is_correct (boolean) are required",
    });
  }
  db.run(
    `INSERT OR REPLACE INTO user_grammar_study (user_id, category_id, topic_id, exercise_id, is_correct, answered_at)
     VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)`,
    [userId, category_id, topic_id, exercise_id, is_correct ? 1 : 0],
    function (err) {
      if (err) {
        console.error("[grammar-study] DB error", err);
        return res.status(500).json({ error: err.message });
      }
      res.json({ success: true, message: "Grammar study result saved" });
    }
  );
});

// Get all grammar study results for a user
app.get("/user/:userId/grammar-study", (req, res) => {
  const { userId } = req.params;
  db.all(
    `SELECT * FROM user_grammar_study WHERE user_id = ? ORDER BY answered_at DESC`,
    [userId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ results: rows });
    }
  );
});

// Enhanced CORS configuration for web development - Allow all origins for testing
app.use(
  cors({
    origin: "*", // Allow all origins for now
    credentials: false, // Disable credentials when using wildcard
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: [
      "Content-Type",
      "Authorization",
      "Accept",
      "Origin",
      "X-Requested-With",
    ],
  })
);

app.use(express.json());

// SQLite setup
const db = new sqlite3.Database("./aitalk.db");
db.serialize(() => {
  // Table for detailed grammar study progress and results
  db.run(`CREATE TABLE IF NOT EXISTS user_grammar_study (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    category_id TEXT NOT NULL,
    topic_id TEXT NOT NULL,
    exercise_id TEXT NOT NULL,
    is_correct INTEGER NOT NULL,
    answered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, exercise_id)
  )`);
  db.run(
    "CREATE TABLE IF NOT EXISTS vocab (id INTEGER PRIMARY KEY, word TEXT, meaning TEXT, mastered INTEGER DEFAULT 0)"
  );
  db.run(
    "CREATE TABLE IF NOT EXISTS progress (id INTEGER PRIMARY KEY, metric TEXT, value INTEGER)"
  );
  db.run(
    "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, email TEXT UNIQUE, password TEXT, name TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)"
  );
  db.run(
    "CREATE TABLE IF NOT EXISTS lessons (id INTEGER PRIMARY KEY, title TEXT, content TEXT, difficulty TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)"
  );
  db.run(
    "CREATE TABLE IF NOT EXISTS user_streaks (id INTEGER PRIMARY KEY, user_id INTEGER, streak_count INTEGER, last_activity DATE)"
  );
  db.run(
    "CREATE TABLE IF NOT EXISTS badges (id INTEGER PRIMARY KEY, user_id INTEGER, badge_name TEXT, earned_at DATETIME DEFAULT CURRENT_TIMESTAMP)"
  );
  db.run(
    "CREATE TABLE IF NOT EXISTS leaderboard (id INTEGER PRIMARY KEY, user_id INTEGER, score INTEGER, updated_at DATETIME DEFAULT CURRENT_TIMESTAMP)"
  );
  db.run(
    "CREATE TABLE IF NOT EXISTS app_settings (id INTEGER PRIMARY KEY, setting_key TEXT UNIQUE, setting_value TEXT)"
  );

  // User-specific settings table
  db.run(`CREATE TABLE IF NOT EXISTS user_settings (
    id INTEGER PRIMARY KEY,
    user_id TEXT NOT NULL,
    setting_key TEXT NOT NULL,
    setting_value TEXT NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, setting_key)
  )`);

  // User progress tracking table
  db.run(`CREATE TABLE IF NOT EXISTS user_progress (
    id INTEGER PRIMARY KEY,
    user_id TEXT NOT NULL UNIQUE,
    streak INTEGER DEFAULT 0,
    total_messages INTEGER DEFAULT 0,
    vocabulary_level INTEGER DEFAULT 1,
    grammar_level INTEGER DEFAULT 1,
    speaking_level INTEGER DEFAULT 1,
    writing_level INTEGER DEFAULT 1,
    lessons_completed INTEGER DEFAULT 0,
    badges_earned INTEGER DEFAULT 0,
    last_activity DATETIME DEFAULT CURRENT_TIMESTAMP,
    skill_progress TEXT DEFAULT '{}',
    weekly_stats TEXT DEFAULT '{}',
    achievements TEXT DEFAULT '[]',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  // User achievements table
  db.run(`CREATE TABLE IF NOT EXISTS user_achievements (
    id INTEGER PRIMARY KEY,
    user_id TEXT NOT NULL,
    achievement_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    icon_name TEXT NOT NULL,
    achievement_type TEXT NOT NULL,
    earned_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, achievement_id)
  )`);

  // Grammar study data tables
  db.run(`CREATE TABLE IF NOT EXISTS grammar_categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    display_order INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS grammar_topics (
    id TEXT PRIMARY KEY,
    category_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    level TEXT NOT NULL,
    display_order INTEGER DEFAULT 0,
    explanation TEXT,
    examples TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES grammar_categories (id)
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS grammar_exercises (
    id TEXT PRIMARY KEY,
    topic_id TEXT NOT NULL,
    question TEXT NOT NULL,
    options TEXT NOT NULL,
    correct_index INTEGER NOT NULL,
    difficulty TEXT NOT NULL,
    display_order INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES grammar_topics (id)
  )`);

  // User progress tracking for grammar exercises
  db.run(`CREATE TABLE IF NOT EXISTS user_grammar_progress (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    exercise_id TEXT NOT NULL,
    topic_id TEXT NOT NULL,
    category_id TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL,
    selected_answer INTEGER NOT NULL,
    attempts INTEGER DEFAULT 1,
    first_attempt_correct BOOLEAN NOT NULL,
    completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, exercise_id),
    FOREIGN KEY (exercise_id) REFERENCES grammar_exercises (id),
    FOREIGN KEY (topic_id) REFERENCES grammar_topics (id),
    FOREIGN KEY (category_id) REFERENCES grammar_categories (id)
  )`);

  // Initialize default AI model setting
  db.run(
    "INSERT OR IGNORE INTO app_settings (setting_key, setting_value) VALUES (?, ?)",
    ["selected_ai_model", "deepseek/deepseek-chat-v3-0324:free"]
  );

  // Add new columns to grammar_topics table if they don't exist
  db.all("PRAGMA table_info(grammar_topics)", (err, columns) => {
    if (err) {
      console.error("Error checking table structure:", err);
      return;
    }
    
    const hasExplanation = columns.some(col => col.name === 'explanation');
    const hasExamples = columns.some(col => col.name === 'examples');
    
    if (!hasExplanation) {
      db.run("ALTER TABLE grammar_topics ADD COLUMN explanation TEXT", (err) => {
        if (err) console.error("Error adding explanation column:", err);
        else console.log("Added explanation column to grammar_topics table");
      });
    }
    
    if (!hasExamples) {
      db.run("ALTER TABLE grammar_topics ADD COLUMN examples TEXT", (err) => {
        if (err) console.error("Error adding examples column:", err);
        else console.log("Added examples column to grammar_topics table");
      });
    }
  });

  // Initialize grammar study data
  initializeGrammarData();
});

// Grammar study data initialization
function initializeGrammarData() {
  // Check if data already exists
  db.get("SELECT COUNT(*) as count FROM grammar_categories", (err, row) => {
    if (err) {
      console.error("Error checking grammar data:", err);
      return;
    }
    
    if (row.count > 0) {
      console.log("Grammar data already exists, skipping initialization");
      return;
    }

    console.log("Initializing grammar study data...");
    
    // Grammar categories data
    const categories = [
      { id: 'foundations', name: 'Grammar Foundations', order: 1 },
      { id: 'elementary', name: 'Elementary Grammar', order: 2 },
      { id: 'intermediate', name: 'Intermediate Grammar', order: 3 },
      { id: 'upper_intermediate', name: 'Upper-Intermediate Grammar', order: 4 },
      { id: 'advanced', name: 'Advanced Grammar', order: 5 },
      { id: 'business', name: 'Business English Grammar', order: 6 },
      { id: 'academic', name: 'Academic English Grammar', order: 7 }
    ];

    // Grammar topics data
    const topics = [
      // Foundations
      { id: 'present_simple', category_id: 'foundations', title: 'Present Simple Tense', description: 'Learn the basic present tense for daily actions and facts.', level: 'easy', order: 1 },
      { id: 'articles', category_id: 'foundations', title: 'Articles (a/an/the)', description: 'Master the use of definite and indefinite articles.', level: 'easy', order: 2 },
      { id: 'plural_nouns', category_id: 'foundations', title: 'Plural Nouns', description: 'Learn regular and irregular plural forms.', level: 'easy', order: 3 },
      { id: 'pronouns', category_id: 'foundations', title: 'Personal Pronouns', description: 'Subject and object pronouns in sentences.', level: 'easy', order: 4 },
      
      // Elementary
      { id: 'past_simple', category_id: 'elementary', title: 'Past Simple Tense', description: 'Express completed actions in the past.', level: 'easy', order: 1 },
      { id: 'future_simple', category_id: 'elementary', title: 'Future Simple (will)', description: 'Talk about future plans and predictions.', level: 'easy', order: 2 },
      { id: 'prepositions', category_id: 'elementary', title: 'Common Prepositions', description: 'Learn prepositions of time, place, and direction.', level: 'easy', order: 3 },
      
      // Intermediate
      { id: 'present_perfect', category_id: 'intermediate', title: 'Present Perfect Tense', description: 'Connect past actions to the present moment.', level: 'medium', order: 1 },
      { id: 'past_continuous', category_id: 'intermediate', title: 'Past Continuous Tense', description: 'Describe ongoing actions in the past.', level: 'medium', order: 2 },
      { id: 'comparatives_superlatives', category_id: 'intermediate', title: 'Comparatives & Superlatives', description: 'Compare people, places, and things.', level: 'medium', order: 3 },
      { id: 'modal_verbs', category_id: 'intermediate', title: 'Modal Verbs', description: 'Express ability, possibility, and obligation.', level: 'medium', order: 4 },
      
      // Upper-Intermediate
      { id: 'perfect_continuous', category_id: 'upper_intermediate', title: 'Perfect Continuous Tenses', description: 'Combine perfect and continuous aspects.', level: 'medium', order: 1 },
      { id: 'relative_clauses', category_id: 'upper_intermediate', title: 'Relative Clauses', description: 'Join sentences with relative pronouns.', level: 'medium', order: 2 },
      { id: 'gerunds_infinitives', category_id: 'upper_intermediate', title: 'Gerunds and Infinitives', description: 'Learn when to use -ing forms and to + verb.', level: 'medium', order: 3 },
      
      // Advanced
      { id: 'conditionals', category_id: 'advanced', title: 'Conditional Sentences', description: 'Master all types of conditional structures.', level: 'hard', order: 1 },
      { id: 'passive_voice', category_id: 'advanced', title: 'Passive Voice', description: 'Transform active sentences to passive structures.', level: 'hard', order: 2 },
      { id: 'reported_speech', category_id: 'advanced', title: 'Reported Speech', description: 'Convert direct speech to indirect speech.', level: 'hard', order: 3 },
      { id: 'subjunctive_mood', category_id: 'advanced', title: 'Subjunctive Mood', description: 'Express hypothetical and formal situations.', level: 'hard', order: 4 },
      
      // Business
      { id: 'formal_language', category_id: 'business', title: 'Formal Language Structures', description: 'Professional communication patterns.', level: 'medium', order: 1 },
      { id: 'email_structure', category_id: 'business', title: 'Email Grammar Patterns', description: 'Professional email communication.', level: 'medium', order: 2 },
      
      // Academic
      { id: 'complex_sentences', category_id: 'academic', title: 'Complex Sentence Structures', description: 'Advanced academic writing patterns.', level: 'hard', order: 1 }
    ];

    // Insert categories
    const insertCategory = db.prepare("INSERT OR IGNORE INTO grammar_categories (id, name, display_order) VALUES (?, ?, ?)");
    categories.forEach(cat => {
      insertCategory.run(cat.id, cat.name, cat.order);
    });
    insertCategory.finalize();

    // Insert topics
    const insertTopic = db.prepare("INSERT OR IGNORE INTO grammar_topics (id, category_id, title, description, level, display_order) VALUES (?, ?, ?, ?, ?, ?)");
    topics.forEach(topic => {
      insertTopic.run(topic.id, topic.category_id, topic.title, topic.description, topic.level, topic.order);
    });
    insertTopic.finalize();

    // Insert sample exercises (you can expand this with all the exercises from grammar_data.dart)
    const insertExercise = db.prepare("INSERT OR IGNORE INTO grammar_exercises (id, topic_id, question, options, correct_index, difficulty, display_order) VALUES (?, ?, ?, ?, ?, ?, ?)");
    
    // Sample exercises for present simple
    const sampleExercises = [
      { id: 'ps1', topic_id: 'present_simple', question: 'She ____ to school every day.', options: JSON.stringify(['go', 'goes', 'going', 'gone']), correct_index: 1, difficulty: 'easy', order: 1 },
      { id: 'ps2', topic_id: 'present_simple', question: 'I ____ coffee in the morning.', options: JSON.stringify(['drink', 'drinks', 'drank', 'drunk']), correct_index: 0, difficulty: 'easy', order: 2 },
      { id: 'art1', topic_id: 'articles', question: 'I saw ____ elephant at the zoo.', options: JSON.stringify(['a', 'an', 'the', 'no article']), correct_index: 1, difficulty: 'easy', order: 1 },
      { id: 'art2', topic_id: 'articles', question: 'Can you pass me ____ salt?', options: JSON.stringify(['a', 'an', 'the', 'no article']), correct_index: 2, difficulty: 'easy', order: 2 }
    ];

    sampleExercises.forEach(ex => {
      insertExercise.run(ex.id, ex.topic_id, ex.question, ex.options, ex.correct_index, ex.difficulty, ex.order);
    });
    insertExercise.finalize();

    console.log("Grammar study data initialized successfully");
  });
}

// OpenAI setup
const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
const OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1/chat/completions";

// Available AI Models
const AVAILABLE_MODELS = [
  {
    id: "deepseek/deepseek-chat-v3-0324:free",
    name: "DeepSeek V3 (Free)",
    description: "High-quality conversations and analysis",
    provider: "DeepSeek",
    tier: "Free",
  },
  {
    id: "meta-llama/llama-3.2-3b-instruct:free",
    name: "Llama 3.2 3B (Free)",
    description: "Fast responses with good quality",
    provider: "Meta",
    tier: "Free",
  },
  {
    id: "microsoft/phi-3-mini-128k-instruct:free",
    name: "Phi-3 Mini (Free)",
    description: "Efficient small model for basic tasks",
    provider: "Microsoft",
    tier: "Free",
  },
  {
    id: "google/gemma-2-9b-it:free",
    name: "Gemma 2 9B (Free)",
    description: "Google's open model with good performance",
    provider: "Google",
    tier: "Free",
  },
];

// Helper function to get selected AI model
async function getSelectedModel() {
  return new Promise((resolve, reject) => {
    db.get(
      "SELECT setting_value FROM app_settings WHERE setting_key = ?",
      ["selected_ai_model"],
      (err, row) => {
        if (err) {
          console.error("Error getting selected model:", err);
          resolve("deepseek/deepseek-chat-v3-0324:free"); // Default fallback
        } else {
          resolve(
            row ? row.setting_value : "deepseek/deepseek-chat-v3-0324:free"
          );
        }
      }
    );
  });
}

// App Settings endpoints
app.get("/settings/models", (req, res) => {
  res.json({
    available: AVAILABLE_MODELS,
    message: "Available AI models for selection",
  });
});

app.get("/settings/current-model", (req, res) => {
  db.get(
    "SELECT setting_value FROM app_settings WHERE setting_key = ?",
    ["selected_ai_model"],
    (err, row) => {
      if (err) return res.status(500).json({ error: err.message });

      const currentModelId = row
        ? row.setting_value
        : "deepseek/deepseek-chat-v3-0324:free";
      const currentModel = AVAILABLE_MODELS.find(
        (model) => model.id === currentModelId
      );

      res.json({
        selected_model: currentModelId,
        model_info: currentModel || AVAILABLE_MODELS[0],
      });
    }
  );
});

app.post("/settings/select-model", (req, res) => {
  const { model_id } = req.body;

  // Validate that the model exists in our available models
  const selectedModel = AVAILABLE_MODELS.find((model) => model.id === model_id);
  if (!selectedModel) {
    return res.status(400).json({
      error: "Invalid model selection",
      available_models: AVAILABLE_MODELS.map((m) => m.id),
    });
  }

  db.run(
    "INSERT OR REPLACE INTO app_settings (setting_key, setting_value) VALUES (?, ?)",
    ["selected_ai_model", model_id],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });

      res.json({
        success: true,
        selected_model: model_id,
        model_info: selectedModel,
        message: `AI model updated to ${selectedModel.name}`,
      });
    }
  );
});

// Voice Settings endpoints
app.get("/settings/voice", (req, res) => {
  db.all(
    "SELECT * FROM app_settings WHERE setting_key IN (?, ?)",
    ["voice_autoplay_enabled", "voice_input_enabled"],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });

      const settings = {
        voice_autoplay_enabled: true, // default values
        voice_input_enabled: true,
      };

      rows.forEach((row) => {
        settings[row.setting_key] = row.setting_value === "true";
      });

      res.json({
        voice_autoplay_enabled: settings.voice_autoplay_enabled,
        voice_input_enabled: settings.voice_input_enabled,
        message: "Voice settings retrieved successfully",
      });
    }
  );
});

app.post("/settings/voice", (req, res) => {
  const { voice_autoplay_enabled, voice_input_enabled } = req.body;

  // Validate boolean values
  if (
    typeof voice_autoplay_enabled !== "boolean" ||
    typeof voice_input_enabled !== "boolean"
  ) {
    return res
      .status(400)
      .json({ error: "Voice settings must be boolean values" });
  }

  // Update settings in database
  const stmt = db.prepare(
    "INSERT OR REPLACE INTO app_settings (setting_key, setting_value) VALUES (?, ?)"
  );

  stmt.run("voice_autoplay_enabled", voice_autoplay_enabled.toString());
  stmt.run("voice_input_enabled", voice_input_enabled.toString());
  stmt.finalize();

  res.json({
    success: true,
    voice_autoplay_enabled,
    voice_input_enabled,
    message: "Voice settings updated successfully",
  });
});

// User-specific settings endpoints
app.get("/user/:userId/settings", (req, res) => {
  const { userId } = req.params;

  db.all(
    "SELECT setting_key, setting_value FROM user_settings WHERE user_id = ?",
    [userId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });

      // Convert rows to key-value object
      const settings = {};
      rows.forEach((row) => {
        // Parse boolean values
        if (row.setting_value === "true" || row.setting_value === "false") {
          settings[row.setting_key] = row.setting_value === "true";
        } else {
          settings[row.setting_key] = row.setting_value;
        }
      });

      // Set default values if not found
      const defaultSettings = {
        voice_autoplay_enabled: true,
        voice_input_enabled: true,
        notifications_enabled: true,
        daily_reminder: true,
        selected_ai_model: "deepseek/deepseek-chat-v3-0324:free",
      };

      res.json({
        settings: { ...defaultSettings, ...settings },
        message: "User settings retrieved successfully",
      });
    }
  );
});

app.post("/user/:userId/settings", (req, res) => {
  const { userId } = req.params;
  const settings = req.body;

  if (!settings || typeof settings !== "object") {
    return res
      .status(400)
      .json({ error: "Settings must be provided as an object" });
  }

  const stmt = db.prepare(
    "INSERT OR REPLACE INTO user_settings (user_id, setting_key, setting_value, updated_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)"
  );

  try {
    db.serialize(() => {
      for (const [key, value] of Object.entries(settings)) {
        stmt.run(userId, key, value.toString());
      }
    });
    stmt.finalize();

    res.json({
      success: true,
      settings,
      message: "User settings updated successfully",
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// User progress endpoints
app.get("/user/:userId/progress", (req, res) => {
  const { userId } = req.params;

  db.get(
    "SELECT * FROM user_progress WHERE user_id = ?",
    [userId],
    (err, row) => {
      if (err) return res.status(500).json({ error: err.message });

      if (!row) {
        // Return default progress for new users
        const defaultProgress = {
          user_id: userId,
          streak: 0,
          total_messages: 0,
          vocabulary_level: 1,
          grammar_level: 1,
          speaking_level: 1,
          writing_level: 1,
          lessons_completed: 0,
          badges_earned: 0,
          last_activity: new Date().toISOString(),
          skill_progress: JSON.stringify({
            vocabulary: 0,
            grammar: 0,
            speaking: 0,
            writing: 0,
          }),
          weekly_stats: JSON.stringify({
            messagesThisWeek: 0,
            lessonsThisWeek: 0,
            streakThisWeek: 0,
          }),
          achievements: JSON.stringify([]),
        };

        return res.json({
          progress: defaultProgress,
          message: "Default progress returned for new user",
        });
      }

      // Parse JSON fields
      try {
        row.skill_progress = JSON.parse(row.skill_progress || "{}");
        row.weekly_stats = JSON.parse(row.weekly_stats || "{}");
        row.achievements = JSON.parse(row.achievements || "[]");
      } catch (parseError) {
        console.error("Error parsing progress JSON fields:", parseError);
        row.skill_progress = {};
        row.weekly_stats = {};
        row.achievements = [];
      }

      res.json({
        progress: row,
        message: "User progress retrieved successfully",
      });
    }
  );
});

app.post("/user/:userId/progress", (req, res) => {
  const { userId } = req.params;
  const progressData = req.body;

  if (!progressData || typeof progressData !== "object") {
    return res
      .status(400)
      .json({ error: "Progress data must be provided as an object" });
  }

  // Ensure JSON fields are stringified
  const skillProgress = JSON.stringify(progressData.skill_progress || {});
  const weeklyStats = JSON.stringify(progressData.weekly_stats || {});
  const achievements = JSON.stringify(progressData.achievements || []);

  const query = `
    INSERT OR REPLACE INTO user_progress (
      user_id, streak, total_messages, vocabulary_level, grammar_level, 
      speaking_level, writing_level, lessons_completed, badges_earned,
      last_activity, skill_progress, weekly_stats, achievements, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
  `;

  const values = [
    userId,
    progressData.streak || 0,
    progressData.total_messages || 0,
    progressData.vocabulary_level || 1,
    progressData.grammar_level || 1,
    progressData.speaking_level || 1,
    progressData.writing_level || 1,
    progressData.lessons_completed || 0,
    progressData.badges_earned || 0,
    progressData.last_activity || new Date().toISOString(),
    skillProgress,
    weeklyStats,
    achievements,
  ];

  db.run(query, values, function (err) {
    if (err) return res.status(500).json({ error: err.message });

    res.json({
      success: true,
      progress: progressData,
      message: "User progress updated successfully",
    });
  });
});

// User achievements endpoints
app.get("/user/:userId/achievements", (req, res) => {
  const { userId } = req.params;

  db.all(
    "SELECT * FROM user_achievements WHERE user_id = ? ORDER BY earned_date DESC",
    [userId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });

      res.json({
        achievements: rows,
        message: "User achievements retrieved successfully",
      });
    }
  );
});

app.post("/user/:userId/achievements", (req, res) => {
  const { userId } = req.params;
  const { achievement_id, title, description, icon_name, achievement_type } =
    req.body;

  if (
    !achievement_id ||
    !title ||
    !description ||
    !icon_name ||
    !achievement_type
  ) {
    return res.status(400).json({
      error:
        "Missing required fields: achievement_id, title, description, icon_name, achievement_type",
    });
  }

  db.run(
    "INSERT OR IGNORE INTO user_achievements (user_id, achievement_id, title, description, icon_name, achievement_type) VALUES (?, ?, ?, ?, ?, ?)",
    [userId, achievement_id, title, description, icon_name, achievement_type],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });

      if (this.changes === 0) {
        return res.json({
          success: false,
          message: "Achievement already exists for this user",
        });
      }

      res.json({
        success: true,
        achievement_id: this.lastID,
        message: "Achievement added successfully",
      });
    }
  );
});

// Track message interaction for progress
app.post("/user/:userId/track-message", (req, res) => {
  const { userId } = req.params;
  const { message_content, message_type } = req.body;

  // --- Grammar Data Endpoints ---

  // Get all grammar categories
  app.get("/grammar/categories", (req, res) => {
    db.all("SELECT * FROM grammar_categories ORDER BY display_order", [], (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ categories: rows });
    });
  });

  // Create a grammar category
  app.post("/grammar/categories", (req, res) => {
    const { name, description } = req.body;
    if (!name)
      return res.status(400).json({ error: "Category name is required" });
    const id = name.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
    db.run(
      "INSERT INTO grammar_categories (id, name, description) VALUES (?, ?, ?)",
      [id, name, description || null],
      function (err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ id: id });
      }
    );
  });

  // Get all topics for a category
  app.get("/grammar/categories/:categoryId/topics", (req, res) => {
    const { categoryId } = req.params;
    db.all(
      "SELECT * FROM grammar_topics WHERE category_id = ?",
      [categoryId],
      (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
      }
    );
  });

  // Create a topic for a category
  app.post("/grammar/categories/:categoryId/topics", (req, res) => {
    const { categoryId } = req.params;
    const { name, description } = req.body;
    if (!name) return res.status(400).json({ error: "Topic name is required" });
    db.run(
      "INSERT INTO grammar_topics (category_id, name, description) VALUES (?, ?, ?)",
      [categoryId, name, description || null],
      function (err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ id: this.lastID });
      }
    );
  });

  // Get all exercises for a topic
  app.get("/grammar/topics/:topicId/exercises", (req, res) => {
    const { topicId } = req.params;
    db.all(
      "SELECT * FROM grammar_exercises WHERE topic_id = ?",
      [topicId],
      (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        // Parse options from JSON string
        const exercises = rows.map((ex) => ({
          ...ex,
          options: JSON.parse(ex.options),
        }));
        res.json(exercises);
      }
    );
  });

  // Create an exercise for a topic
  app.post("/grammar/topics/:topicId/exercises", (req, res) => {
    const { topicId } = req.params;
    const { question, options, answer, explanation } = req.body;
    if (!question || !options || !answer)
      return res
        .status(400)
        .json({ error: "Question, options, and answer are required" });
    db.run(
      "INSERT INTO grammar_exercises (topic_id, question, options, answer, explanation) VALUES (?, ?, ?, ?, ?)",
      [topicId, question, JSON.stringify(options), answer, explanation || null],
      function (err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ id: this.lastID });
      }
    );
  });
  if (!message_content || !message_type) {
    return res
      .status(400)
      .json({ error: "message_content and message_type are required" });
  }

  // Get current progress
  db.get(
    "SELECT * FROM user_progress WHERE user_id = ?",
    [userId],
    (err, currentProgress) => {
      if (err) return res.status(500).json({ error: err.message });

      // Calculate skill improvements based on message
      const wordCount = message_content.trim().split(" ").length;
      let skillGains = {};

      switch (message_type) {
        case "chat":
          skillGains.speaking = Math.ceil(wordCount / 10);
          skillGains.vocabulary = Math.ceil(wordCount / 15);
          break;
        case "grammar":
          skillGains.grammar = Math.ceil(wordCount / 8);
          skillGains.writing = Math.ceil(wordCount / 12);
          break;
        case "vocabulary":
          skillGains.vocabulary = Math.ceil(wordCount / 5);
          break;
        case "lesson":
          skillGains.grammar = 1;
          skillGains.vocabulary = 1;
          skillGains.writing = 1;
          break;
      }

      // Update or create progress record
      if (!currentProgress) {
        // Create new progress record
        const newProgress = {
          user_id: userId,
          streak: 1,
          total_messages: 1,
          vocabulary_level: 1,
          grammar_level: 1,
          speaking_level: 1,
          writing_level: 1,
          lessons_completed: 0,
          badges_earned: 0,
          last_activity: new Date().toISOString(),
          skill_progress: JSON.stringify(skillGains),
          weekly_stats: JSON.stringify({ messagesThisWeek: 1 }),
          achievements: JSON.stringify([]),
        };

        const query = `
        INSERT INTO user_progress (
          user_id, streak, total_messages, vocabulary_level, grammar_level,
          speaking_level, writing_level, lessons_completed, badges_earned,
          last_activity, skill_progress, weekly_stats, achievements, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
      `;

        db.run(
          query,
          [
            newProgress.user_id,
            newProgress.streak,
            newProgress.total_messages,
            newProgress.vocabulary_level,
            newProgress.grammar_level,
            newProgress.speaking_level,
            newProgress.writing_level,
            newProgress.lessons_completed,
            newProgress.badges_earned,
            newProgress.last_activity,
            newProgress.skill_progress,
            newProgress.weekly_stats,
            newProgress.achievements,
          ],
          function (err) {
            if (err) return res.status(500).json({ error: err.message });

            res.json({
              success: true,
              progress: newProgress,
              message: "Message tracked and progress initialized",
            });
          }
        );
      } else {
        // Update existing progress
        const existingSkillProgress = JSON.parse(
          currentProgress.skill_progress || "{}"
        );
        const existingWeeklyStats = JSON.parse(
          currentProgress.weekly_stats || "{}"
        );

        // Add skill gains to existing progress
        Object.keys(skillGains).forEach((skill) => {
          existingSkillProgress[skill] =
            (existingSkillProgress[skill] || 0) + skillGains[skill];
        });

        // Update weekly stats
        existingWeeklyStats.messagesThisWeek =
          (existingWeeklyStats.messagesThisWeek || 0) + 1;

        // Calculate streak (simplified - assumes daily usage)
        const lastActivity = new Date(currentProgress.last_activity);
        const today = new Date();
        const daysDiff = Math.floor(
          (today - lastActivity) / (1000 * 60 * 60 * 24)
        );

        let newStreak = currentProgress.streak;
        if (daysDiff === 1) {
          newStreak++; // Continue streak
        } else if (daysDiff > 1) {
          newStreak = 1; // Reset streak
        }
        // If same day, keep current streak

        const updateQuery = `
        UPDATE user_progress SET 
          streak = ?, total_messages = ?, last_activity = ?,
          skill_progress = ?, weekly_stats = ?, updated_at = CURRENT_TIMESTAMP
        WHERE user_id = ?
      `;

        db.run(
          updateQuery,
          [
            newStreak,
            currentProgress.total_messages + 1,
            new Date().toISOString(),
            JSON.stringify(existingSkillProgress),
            JSON.stringify(existingWeeklyStats),
            userId,
          ],
          function (err) {
            if (err) return res.status(500).json({ error: err.message });

            res.json({
              success: true,
              progress: {
                ...currentProgress,
                streak: newStreak,
                total_messages: currentProgress.total_messages + 1,
                skill_progress: existingSkillProgress,
                weekly_stats: existingWeeklyStats,
              },
              message: "Message tracked and progress updated",
            });
          }
        );
      }
    }
  );
});

// LEGACY ENDPOINT REMOVED - Use /chat-with-suggestions instead
// This endpoint has been consolidated to save AI tokens

// Combined chat and suggestions endpoint to reduce API calls
app.post("/chat-with-suggestions", async (req, res) => {
  console.log("=== Combined Chat & Suggestions API Called ===");
  console.log("Request method:", req.method);
  console.log("Request headers:", req.headers);
  console.log("Request body:", req.body);
  console.log("Request origin:", req.headers.origin);

  const { message, include_suggestions = true } = req.body;

  // Check if API key is configured
  if (!OPENROUTER_API_KEY || OPENROUTER_API_KEY === "your_api_key_here") {
    // Provide a fallback response for demo purposes
    const demoResponses = [
      "That's a great question! I'm here to help you learn English. What would you like to practice today?",
      "Excellent! Let's work on improving your English skills. Would you like to focus on grammar, vocabulary, or conversation?",
      "I understand what you're saying. English can be challenging, but with practice, you'll get better! What specific area would you like help with?",
      "Good job on expressing yourself! Remember, making mistakes is part of learning. Keep practicing!",
      "That's an interesting point! In English, we would typically say... Would you like me to explain the grammar rule behind this?",
    ];
    const randomResponse =
      demoResponses[Math.floor(Math.random() * demoResponses.length)];

    const result = { reply: `[Demo Mode] ${randomResponse}` };

    if (include_suggestions) {
      result.suggestions = {
        grammar_fix: "Demo mode - no grammar analysis available",
        better_versions: [
          "Demo response alternative 1",
          "Demo response alternative 2",
          "Demo response alternative 3",
        ],
        vocabulary: [
          {
            word: "practice",
            meaning: "to repeat an activity to improve skill",
            example: "You should practice speaking English every day",
          },
        ],
      };
    }

    return res.json(result);
  }

  try {
    // Get the currently selected AI model
    const selectedModel = await getSelectedModel();
    console.log("Combined API using model:", selectedModel);

    // Enhanced system prompt that combines chat and suggestions
    const systemPrompt = include_suggestions
      ? `You are an English language learning tutor. For each student message, provide BOTH a conversational response AND detailed learning analysis in JSON format.

Your response must be valid JSON with exactly this structure:

{
  "reply": "Your conversational response to the student (50-80 words, engaging and encouraging)",
  "suggestions": {
    "grammar_errors": [
      {"error": "specific incorrect phrase or word", "correction": "correct version", "explanation": "why this is wrong and rule explanation", "type": "grammar error type (e.g., subject-verb agreement, article usage, etc.)"}
    ],
    "spelling_errors": [
      {"error": "misspelled word", "correction": "correct spelling", "explanation": "spelling rule or common mistake explanation"}
    ],
    "better_versions": ["3 different improved ways to express the same message as the student"],
    "vocabulary": [
      {"word": "word1", "meaning": "definition", "example": "example sentence"},
      {"word": "word2", "meaning": "definition", "example": "example sentence"}
    ]
  }
}

Guidelines for reply:
1. If their English has errors, start with "A better way to say this would be: [corrected version]"
2. Then engage with their topic naturally
3. End with a follow-up question to encourage practice
4. Keep responses 50-80 words
5. Focus only on English learning topics

Guidelines for suggestions:
- Analyze their English carefully for grammar, spelling, and style issues
- For "grammar_errors": List each specific grammar mistake with detailed explanations point by point
- For "spelling_errors": List each spelling mistake with corrections
- For "better_versions": Create 3 alternative ways to express the EXACT SAME meaning as the student's original message, but with improved grammar, vocabulary, or style
- These should be different from your chat response - they are improved versions of the STUDENT'S message, not new responses
- Include relevant vocabulary with definitions and examples
- If no errors found, use empty arrays for grammar_errors and spelling_errors

DO NOT include any text before or after the JSON. Return ONLY valid JSON.`
      : `You are an English language learning tutor, NOT a general AI assistant. Your ONLY job is to help users practice and improve their English. Always stay focused on English learning topics.

When responding:
1. If their English has errors, start with "A better way to say this would be: [corrected version]"
2. Then engage with their topic in a natural, conversational way
3. End with a follow-up question to encourage more English practice
4. Keep responses 50-80 words
5. Never discuss AI, language models, or technical topics - focus only on English learning

Be encouraging, friendly, and always redirect conversations toward English practice.`;

    // Make a single API call to OpenRouter
    const response = await axios.post(
      OPENROUTER_BASE_URL,
      {
        model: selectedModel,
        messages: [
          { role: "system", content: systemPrompt },
          {
            role: "user",
            content: include_suggestions
              ? `Analyze and respond to: "${message}"`
              : message,
          },
        ],
        max_tokens: include_suggestions ? 800 : 300,
        temperature: include_suggestions ? 0.5 : 0.7,
      },
      {
        headers: {
          Authorization: `Bearer ${OPENROUTER_API_KEY}`,
          "Content-Type": "application/json",
        },
        timeout: 30000,
      }
    );

    console.log(
      "Combined API Success - AI Response:",
      response.data.choices[0].message.content
    );

    const aiResponse = response.data.choices[0].message.content;

    if (include_suggestions) {
      // Parse JSON response for combined mode
      try {
        let cleanResponse = aiResponse.trim();
        if (cleanResponse.startsWith("```json")) {
          cleanResponse = cleanResponse
            .replace(/^```json\s*/, "")
            .replace(/\s*```$/, "");
        } else if (cleanResponse.startsWith("```")) {
          cleanResponse = cleanResponse
            .replace(/^```\s*/, "")
            .replace(/\s*```$/, "");
        }

        const parsedResponse = JSON.parse(cleanResponse);

        // Validate the response structure
        if (parsedResponse.reply && parsedResponse.suggestions) {
          res.json(parsedResponse);
        } else {
          // Fallback if structure is incorrect
          res.json({
            reply: parsedResponse.reply || aiResponse,
            suggestions: parsedResponse.suggestions || {
              grammar_errors: [],
              spelling_errors: [],
              better_versions: ["Please try again for better suggestions"],
              vocabulary: [],
            },
          });
        }
      } catch (parseError) {
        console.error("Failed to parse combined response:", parseError);
        // Fallback to basic response
        res.json({
          reply: aiResponse,
          suggestions: {
            grammar_errors: [],
            spelling_errors: [],
            better_versions: ["Please try sending your message again"],
            vocabulary: [],
          },
        });
      }
    } else {
      // Simple chat mode
      res.json({ reply: aiResponse });
    }
  } catch (err) {
    console.error("Combined API Error Details:");
    console.error("- Error message:", err.message);
    console.error("- Response status:", err.response?.status);
    console.error("- Response data:", err.response?.data);

    // Handle specific API errors with intelligent fallbacks
    if (err.response?.status === 429) {
      const result = {
        reply:
          "I'm experiencing high demand right now, but I'm still here to chat! Your message is interesting and I'd love to continue our conversation. What would you like to explore further?",
      };

      if (include_suggestions) {
        result.suggestions = {
          grammar_errors: [],
          spelling_errors: [],
          better_versions: [
            "The AI service is temporarily busy. Please try again in a moment.",
            "Your message was received successfully!",
            "Chat responses are still working normally.",
          ],
          vocabulary: [
            {
              word: "temporarily",
              meaning: "for a limited time; not permanently",
              example: "The service is temporarily unavailable",
            },
          ],
        };
      }

      return res.json(result);
    } else {
      const result = {
        reply:
          "I'm having some technical difficulties right now, but I'm still here to help you practice English! Let's keep chatting - what would you like to talk about?",
      };

      if (include_suggestions) {
        result.suggestions = {
          grammar_fix: "Could not analyze grammar at this time",
          better_versions: [
            "The suggestions feature is having technical difficulties",
            "Your conversation can continue normally",
            "Try disabling suggestions in the menu to improve performance",
          ],
          vocabulary: [],
        };
      }

      return res.json(result);
    }
  }
});

// Grammar & Vocabulary suggestions endpoint (kept for backward compatibility)
// LEGACY ENDPOINT REMOVED - Use /chat-with-suggestions instead
// This endpoint has been consolidated to save AI tokens

// LEGACY ENDPOINT REMOVED - Use /chat-with-suggestions instead
// This endpoint has been consolidated to save AI tokens

// Vocabulary endpoints
app.get("/vocab", (req, res) => {
  db.all("SELECT * FROM vocab", [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});
app.post("/vocab", (req, res) => {
  const { word, meaning } = req.body;
  db.run(
    "INSERT INTO vocab (word, meaning) VALUES (?, ?)",
    [word, meaning],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ id: this.lastID });
    }
  );
});
app.put("/vocab/:id", (req, res) => {
  const { mastered } = req.body;
  db.run(
    "UPDATE vocab SET mastered = ? WHERE id = ?",
    [mastered, req.params.id],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ updated: this.changes });
    }
  );
});

app.delete("/vocab/:id", (req, res) => {
  db.run("DELETE FROM vocab WHERE id = ?", [req.params.id], function (err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ deleted: this.changes });
  });
});

// User Authentication endpoints
app.post("/auth/register", (req, res) => {
  const { email, password, name } = req.body;
  db.run(
    "INSERT INTO users (email, password, name) VALUES (?, ?, ?)",
    [email, password, name],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ id: this.lastID, message: "User registered successfully" });
    }
  );
});

app.post("/auth/login", (req, res) => {
  const { email, password } = req.body;
  db.get(
    "SELECT * FROM users WHERE email = ? AND password = ?",
    [email, password],
    (err, row) => {
      if (err) return res.status(500).json({ error: err.message });
      if (!row) return res.status(401).json({ error: "Invalid credentials" });
      res.json({
        user: { id: row.id, email: row.email, name: row.name },
        message: "Login successful",
      });
    }
  );
});

// Enhanced Lesson endpoints
app.get("/lessons", (req, res) => {
  db.all("SELECT * FROM lessons ORDER BY created_at DESC", [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.post("/lessons", (req, res) => {
  const { title, content, difficulty } = req.body;
  db.run(
    "INSERT INTO lessons (title, content, difficulty) VALUES (?, ?, ?)",
    [title, content, difficulty],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ id: this.lastID });
    }
  );
});

app.put("/lessons/:id", (req, res) => {
  const { title, content, difficulty } = req.body;
  db.run(
    "UPDATE lessons SET title = ?, content = ?, difficulty = ? WHERE id = ?",
    [title, content, difficulty, req.params.id],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ updated: this.changes });
    }
  );
});

app.delete("/lessons/:id", (req, res) => {
  db.run("DELETE FROM lessons WHERE id = ?", [req.params.id], function (err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ deleted: this.changes });
  });
});

// Gamification endpoints
app.get("/streak/:userId", (req, res) => {
  db.get(
    "SELECT * FROM user_streaks WHERE user_id = ?",
    [req.params.userId],
    (err, row) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(row || { user_id: req.params.userId, streak_count: 0 });
    }
  );
});

app.post("/streak/:userId", (req, res) => {
  const { streak_count } = req.body;
  const userId = req.params.userId;
  db.run(
    'INSERT OR REPLACE INTO user_streaks (user_id, streak_count, last_activity) VALUES (?, ?, DATE("now"))',
    [userId, streak_count],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true });
    }
  );
});

app.get("/badges/:userId", (req, res) => {
  db.all(
    "SELECT * FROM badges WHERE user_id = ?",
    [req.params.userId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(rows);
    }
  );
});

app.post("/badges", (req, res) => {
  const { user_id, badge_name } = req.body;
  db.run(
    "INSERT INTO badges (user_id, badge_name) VALUES (?, ?)",
    [user_id, badge_name],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ id: this.lastID });
    }
  );
});

app.get("/leaderboard", (req, res) => {
  db.all(
    `SELECT u.name, l.score, s.streak_count 
          FROM leaderboard l 
          JOIN users u ON l.user_id = u.id 
          LEFT JOIN user_streaks s ON l.user_id = s.user_id 
          ORDER BY l.score DESC LIMIT 10`,
    [],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(rows);
    }
  );
});

app.post("/leaderboard", (req, res) => {
  const { user_id, score } = req.body;
  db.run(
    "INSERT OR REPLACE INTO leaderboard (user_id, score) VALUES (?, ?)",
    [user_id, score],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true });
    }
  );
});

// Enhanced Lesson planning endpoint with AI
app.get("/lesson", (req, res) => {
  res.json({
    lesson:
      "Today: Practice introductions, review 5 new words, and chat with the AI tutor.",
  });
});

app.post("/lesson/generate", async (req, res) => {
  const { level, topic } = req.body;
  try {
    const response = await axios.post(
      OPENROUTER_BASE_URL,
      {
        model: "deepseek/deepseek-chat-v3-0324:free",
        messages: [
          {
            role: "system",
            content:
              "You are an English lesson planner. Create structured lesson plans.",
          },
          {
            role: "user",
            content: `Create a ${level} level English lesson about ${topic}. Include objectives, activities, and exercises.`,
          },
        ],
      },
      {
        headers: {
          Authorization: `Bearer ${OPENROUTER_API_KEY}`,
          "Content-Type": "application/json",
        },
      }
    );
    res.json({ lesson: response.data.choices[0].message.content });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Progress tracking endpoint
app.get("/progress", (req, res) => {
  db.all("SELECT * FROM progress", [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});
app.post("/progress", (req, res) => {
  const { metric, value } = req.body;
  db.run(
    "INSERT INTO progress (metric, value) VALUES (?, ?)",
    [metric, value],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ id: this.lastID });
    }
  );
});

// CONVERSATION HISTORY API ENDPOINTS

// Create conversation history tables
db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS conversations (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active INTEGER DEFAULT 0
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL,
    content TEXT NOT NULL,
    is_user INTEGER NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    metadata TEXT,
    FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE
  )`);

  // Indexes for performance
  db.run(
    "CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id)"
  );
  db.run(
    "CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at DESC)"
  );
  db.run(
    "CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id)"
  );
  db.run(
    "CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp DESC)"
  );
});

// Get user's conversation history
app.get("/conversations/:userId", (req, res) => {
  const { userId } = req.params;

  const query = `
    SELECT 
      c.*,
      COUNT(m.id) as message_count,
      (
        SELECT content 
        FROM messages m2 
        WHERE m2.conversation_id = c.id 
        ORDER BY m2.timestamp DESC 
        LIMIT 1
      ) as last_message_content,
      (
        SELECT is_user 
        FROM messages m2 
        WHERE m2.conversation_id = c.id 
        ORDER BY m2.timestamp DESC 
        LIMIT 1
      ) as last_message_is_user
    FROM conversations c
    LEFT JOIN messages m ON c.id = m.conversation_id
    WHERE c.user_id = ?
    GROUP BY c.id
    ORDER BY c.updated_at DESC
  `;

  db.all(query, [userId], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });

    const conversations = rows.map((row) => {
      const lastContent = row.last_message_content;
      const lastIsUser = row.last_message_is_user;

      let lastMessagePreview = "No messages yet";
      if (lastContent) {
        const preview =
          lastContent.length > 50
            ? `${lastContent.substring(0, 50)}...`
            : lastContent;
        lastMessagePreview = lastIsUser === 1 ? `You: ${preview}` : preview;
      }

      return {
        id: row.id,
        title: row.title,
        lastMessagePreview,
        updatedAt: row.updated_at,
        messageCount: row.message_count,
        isActive: row.is_active === 1,
      };
    });

    res.json(conversations);
  });
});

// Get specific conversation with messages
app.get("/conversations/details/:conversationId", (req, res) => {
  const { conversationId } = req.params;

  // Get conversation
  db.get(
    "SELECT * FROM conversations WHERE id = ?",
    [conversationId],
    (err, conversation) => {
      if (err) return res.status(500).json({ error: err.message });
      if (!conversation)
        return res.status(404).json({ error: "Conversation not found" });

      // Get messages
      db.all(
        "SELECT * FROM messages WHERE conversation_id = ? ORDER BY timestamp ASC",
        [conversationId],
        (err, messages) => {
          if (err) return res.status(500).json({ error: err.message });

          const result = {
            id: conversation.id,
            userId: conversation.user_id,
            title: conversation.title,
            createdAt: conversation.created_at,
            updatedAt: conversation.updated_at,
            isActive: conversation.is_active === 1,
            messages: messages.map((msg) => ({
              id: msg.id,
              conversationId: msg.conversation_id,
              content: msg.content,
              isUser: msg.is_user === 1,
              timestamp: msg.timestamp,
              metadata: msg.metadata ? JSON.parse(msg.metadata) : null,
            })),
          };

          res.json(result);
        }
      );
    }
  );
});

// Save/Create conversation
app.post("/conversations", (req, res) => {
  const { conversation_id, user_id, title, messages = [] } = req.body;

  db.serialize(() => {
    db.run("BEGIN TRANSACTION");

    // Insert or update conversation
    db.run(
      `INSERT OR REPLACE INTO conversations (id, user_id, title, updated_at) 
       VALUES (?, ?, ?, CURRENT_TIMESTAMP)`,
      [conversation_id, user_id, title],
      function (err) {
        if (err) {
          db.run("ROLLBACK");
          return res.status(500).json({ error: err.message });
        }

        // Clear existing messages for this conversation
        db.run(
          "DELETE FROM messages WHERE conversation_id = ?",
          [conversation_id],
          (err) => {
            if (err) {
              db.run("ROLLBACK");
              return res.status(500).json({ error: err.message });
            }

            // Insert new messages
            const stmt = db.prepare(`
            INSERT INTO messages (id, conversation_id, content, is_user, timestamp, metadata) 
            VALUES (?, ?, ?, ?, ?, ?)
          `);

            messages.forEach((msg) => {
              stmt.run(
                msg.id,
                conversation_id,
                msg.content,
                msg.is_user ? 1 : 0,
                msg.timestamp,
                msg.metadata ? JSON.stringify(msg.metadata) : null
              );
            });

            stmt.finalize();

            db.run("COMMIT");
            res.json({ success: true, conversation_id });
          }
        );
      }
    );
  });
});

// Update conversation title
app.put("/conversations/:conversationId/title", (req, res) => {
  const { conversationId } = req.params;
  const { title } = req.body;

  db.run(
    "UPDATE conversations SET title = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
    [title, conversationId],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });

      if (this.changes === 0) {
        return res.status(404).json({ error: "Conversation not found" });
      }

      res.json({ success: true, message: "Title updated successfully" });
    }
  );
});

// Delete conversation
app.delete("/conversations/:conversationId", (req, res) => {
  const { conversationId } = req.params;

  db.serialize(() => {
    db.run("BEGIN TRANSACTION");

    // Delete messages first
    db.run(
      "DELETE FROM messages WHERE conversation_id = ?",
      [conversationId],
      (err) => {
        if (err) {
          db.run("ROLLBACK");
          return res.status(500).json({ error: err.message });
        }

        // Delete conversation
        db.run(
          "DELETE FROM conversations WHERE id = ?",
          [conversationId],
          function (err) {
            if (err) {
              db.run("ROLLBACK");
              return res.status(500).json({ error: err.message });
            }

            db.run("COMMIT");
            res.json({
              success: true,
              message: "Conversation deleted successfully",
            });
          }
        );
      }
    );
  });
});

// Set active conversation
app.post("/conversations/:conversationId/activate", (req, res) => {
  const { conversationId } = req.params;
  const { user_id } = req.body;

  db.serialize(() => {
    db.run("BEGIN TRANSACTION");

    // Deactivate all conversations for user
    db.run(
      "UPDATE conversations SET is_active = 0 WHERE user_id = ?",
      [user_id],
      (err) => {
        if (err) {
          db.run("ROLLBACK");
          return res.status(500).json({ error: err.message });
        }

        // Activate selected conversation
        db.run(
          "UPDATE conversations SET is_active = 1, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
          [conversationId],
          function (err) {
            if (err) {
              db.run("ROLLBACK");
              return res.status(500).json({ error: err.message });
            }

            db.run("COMMIT");
            res.json({ success: true, message: "Conversation activated" });
          }
        );
      }
    );
  });
});

// Search conversations
app.get("/conversations/:userId/search", (req, res) => {
  const { userId } = req.params;
  const { q: query } = req.query;

  if (!query) {
    return res.status(400).json({ error: "Search query is required" });
  }

  const searchQuery = `
    SELECT DISTINCT
      c.*,
      COUNT(m.id) as message_count
    FROM conversations c
    LEFT JOIN messages m ON c.id = m.conversation_id
    WHERE c.user_id = ? AND (
      c.title LIKE ? OR 
      EXISTS (
        SELECT 1 FROM messages m2 
        WHERE m2.conversation_id = c.id AND m2.content LIKE ?
      )
    )
    GROUP BY c.id
    ORDER BY c.updated_at DESC
  `;

  const searchTerm = `%${query}%`;

  db.all(searchQuery, [userId, searchTerm, searchTerm], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });

    const conversations = rows.map((row) => ({
      id: row.id,
      title: row.title,
      lastMessagePreview: `Found: ${query}`,
      updatedAt: row.updated_at,
      messageCount: row.message_count,
      isActive: row.is_active === 1,
    }));

    res.json(conversations);
  });
});

// Create a grammar category
app.post("/grammar/categories", (req, res) => {
  const { name, description } = req.body;
  if (!name)
    return res.status(400).json({ error: "Category name is required" });
  const id = name.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
  db.run(
    "INSERT INTO grammar_categories (id, name, description) VALUES (?, ?, ?)",
    [id, name, description || null],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ id: id });
    }
  );
});

// Get all topics for a category
app.get("/grammar/categories/:categoryId/topics", (req, res) => {
  const { categoryId } = req.params;
  db.all(
    "SELECT * FROM grammar_topics WHERE category_id = ?",
    [categoryId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(rows);
    }
  );
});

// Create a topic for a category
app.post("/grammar/categories/:categoryId/topics", (req, res) => {
  const { categoryId } = req.params;
  const { name, description } = req.body;
  if (!name) return res.status(400).json({ error: "Topic name is required" });
  db.run(
    "INSERT INTO grammar_topics (category_id, name, description) VALUES (?, ?, ?)",
    [categoryId, name, description || null],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ id: this.lastID });
    }
  );
});

// Get all exercises for a topic
app.get("/grammar/topics/:topicId/exercises", (req, res) => {
  const { topicId } = req.params;
  db.all(
    "SELECT * FROM grammar_exercises WHERE topic_id = ?",
    [topicId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      // Parse options from JSON string
      const exercises = rows.map((ex) => ({
        ...ex,
        options: JSON.parse(ex.options),
      }));
      res.json(exercises);
    }
  );
});

// Create an exercise for a topic
app.post("/grammar/topics/:topicId/exercises", (req, res) => {
  const { topicId } = req.params;
  const { question, options, answer, explanation } = req.body;
  if (!question || !options || !answer)
    return res
      .status(400)
      .json({ error: "Question, options, and answer are required" });
  db.run(
    "INSERT INTO grammar_exercises (topic_id, question, options, answer, explanation) VALUES (?, ?, ?, ?, ?)",
    [topicId, question, JSON.stringify(options), answer, explanation || null],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ id: this.lastID });
    }
  );
});

// ===========================================
// GRAMMAR STUDY MODULE API ENDPOINTS
// ===========================================

// Get all grammar categories
app.get("/grammar/categories", (req, res) => {
  db.all(
    "SELECT * FROM grammar_categories ORDER BY display_order",
    (err, rows) => {
      if (err) {
        console.error("Error fetching grammar categories:", err);
        return res.status(500).json({ error: err.message });
      }
      res.json({ categories: rows });
    }
  );
});

// Get topics for a specific category
app.get("/grammar/categories/:categoryId/topics", (req, res) => {
  const { categoryId } = req.params;
  db.all(
    "SELECT * FROM grammar_topics WHERE category_id = ? ORDER BY display_order",
    [categoryId],
    (err, rows) => {
      if (err) {
        console.error("Error fetching grammar topics:", err);
        return res.status(500).json({ error: err.message });
      }
      res.json({ topics: rows });
    }
  );
});

// Get exercises for a specific topic
app.get("/grammar/topics/:topicId/exercises", (req, res) => {
  const { topicId } = req.params;
  db.all(
    "SELECT * FROM grammar_exercises WHERE topic_id = ? ORDER BY display_order",
    [topicId],
    (err, rows) => {
      if (err) {
        console.error("Error fetching grammar exercises:", err);
        return res.status(500).json({ error: err.message });
      }
      
      // Parse options JSON for each exercise
      const exercises = rows.map(row => ({
        ...row,
        options: JSON.parse(row.options)
      }));
      
      res.json({ exercises });
    }
  );
});

// Get complete grammar data structure (categories with topics and exercises)
app.get("/grammar/complete", (req, res) => {
  db.all(
    "SELECT * FROM grammar_categories ORDER BY display_order",
    (err, categories) => {
      if (err) {
        console.error("Error fetching grammar categories:", err);
        return res.status(500).json({ error: err.message });
      }

      let completed = 0;
      const result = categories.map(category => ({
        ...category,
        topics: []
      }));

      if (categories.length === 0) {
        return res.json({ categories: result });
      }

      categories.forEach((category, catIndex) => {
        db.all(
          "SELECT * FROM grammar_topics WHERE category_id = ? ORDER BY display_order",
          [category.id],
          (err, topics) => {
            if (err) {
              console.error("Error fetching topics for category:", category.id, err);
              completed++;
              if (completed === categories.length) {
                res.json({ categories: result });
              }
              return;
            }

            let topicsCompleted = 0;
            result[catIndex].topics = topics.map(topic => ({
              ...topic,
              exercises: []
            }));

            if (topics.length === 0) {
              completed++;
              if (completed === categories.length) {
                res.json({ categories: result });
              }
              return;
            }

            topics.forEach((topic, topicIndex) => {
              db.all(
                "SELECT * FROM grammar_exercises WHERE topic_id = ? ORDER BY display_order",
                [topic.id],
                (err, exercises) => {
                  if (err) {
                    console.error("Error fetching exercises for topic:", topic.id, err);
                  } else {
                    // Parse options JSON for each exercise
                    result[catIndex].topics[topicIndex].exercises = exercises.map(ex => ({
                      ...ex,
                      options: JSON.parse(ex.options)
                    }));
                  }

                  topicsCompleted++;
                  if (topicsCompleted === topics.length) {
                    completed++;
                    if (completed === categories.length) {
                      res.json({ categories: result });
                    }
                  }
                }
              );
            });
          }
        );
      });
    }
  );
});

// Admin endpoints for managing grammar data (for future admin portal)

// Add new category
app.post("/grammar/categories", (req, res) => {
  const { id, name, display_order = 0 } = req.body;
  
  if (!id || !name) {
    return res.status(400).json({ error: "Category id and name are required" });
  }

  db.run(
    "INSERT INTO grammar_categories (id, name, display_order) VALUES (?, ?, ?)",
    [id, name, display_order],
    function (err) {
      if (err) {
        console.error("Error adding grammar category:", err);
        return res.status(500).json({ error: err.message });
      }
      res.json({ success: true, id: id, message: "Category added successfully" });
    }
  );
});

// Add new topic
app.post("/grammar/topics", (req, res) => {
  const { id, category_id, title, description, level, display_order = 0 } = req.body;
  
  if (!id || !category_id || !title || !description || !level) {
    return res.status(400).json({ error: "All topic fields are required" });
  }

  db.run(
    "INSERT INTO grammar_topics (id, category_id, title, description, level, display_order) VALUES (?, ?, ?, ?, ?, ?)",
    [id, category_id, title, description, level, display_order],
    function (err) {
      if (err) {
        console.error("Error adding grammar topic:", err);
        return res.status(500).json({ error: err.message });
      }
      res.json({ success: true, id: id, message: "Topic added successfully" });
    }
  );
});

// Add new exercise
app.post("/grammar/exercises", (req, res) => {
  const { id, topic_id, question, options, correct_index, difficulty, display_order = 0 } = req.body;
  
  if (!id || !topic_id || !question || !options || correct_index === undefined || !difficulty) {
    return res.status(400).json({ error: "All exercise fields are required" });
  }

  const optionsJson = Array.isArray(options) ? JSON.stringify(options) : options;

  db.run(
    "INSERT INTO grammar_exercises (id, topic_id, question, options, correct_index, difficulty, display_order) VALUES (?, ?, ?, ?, ?, ?, ?)",
    [id, topic_id, question, optionsJson, correct_index, difficulty, display_order],
    function (err) {
      if (err) {
        console.error("Error adding grammar exercise:", err);
        return res.status(500).json({ error: err.message });
      }
      res.json({ success: true, id: id, message: "Exercise added successfully" });
    }
  );
});

// Update existing category
app.put("/grammar/categories/:id", (req, res) => {
  const { id } = req.params;
  const { name, display_order } = req.body;
  
  db.run(
    "UPDATE grammar_categories SET name = ?, display_order = ? WHERE id = ?",
    [name, display_order, id],
    function (err) {
      if (err) {
        console.error("Error updating grammar category:", err);
        return res.status(500).json({ error: err.message });
      }
      res.json({ success: true, updated: this.changes, message: "Category updated successfully" });
    }
  );
});

// Delete category (and all related topics and exercises)
app.delete("/grammar/categories/:id", (req, res) => {
  const { id } = req.params;
  
  db.serialize(() => {
    db.run("DELETE FROM grammar_exercises WHERE topic_id IN (SELECT id FROM grammar_topics WHERE category_id = ?)", [id]);
    db.run("DELETE FROM grammar_topics WHERE category_id = ?", [id]);
    db.run("DELETE FROM grammar_categories WHERE id = ?", [id], function (err) {
      if (err) {
        console.error("Error deleting grammar category:", err);
        return res.status(500).json({ error: err.message });
      }
      res.json({ success: true, deleted: this.changes, message: "Category and related data deleted successfully" });
    });
  });
});

// ===========================================
// USER PROGRESS TRACKING API ENDPOINTS
// ===========================================

// Save user's exercise result
app.post("/user/:userId/grammar/exercise/:exerciseId/result", (req, res) => {
  const { userId, exerciseId } = req.params;
  const { isCorrect, selectedAnswer, topicId, categoryId } = req.body;

  if (typeof isCorrect !== 'boolean' || selectedAnswer === undefined) {
    return res.status(400).json({ 
      error: "isCorrect (boolean) and selectedAnswer (number) are required" 
    });
  }

  // First check if user has already completed this exercise
  db.get(
    "SELECT * FROM user_grammar_progress WHERE user_id = ? AND exercise_id = ?",
    [userId, exerciseId],
    (err, existingProgress) => {
      if (err) {
        console.error("Error checking existing progress:", err);
        return res.status(500).json({ error: err.message });
      }

      if (existingProgress) {
        // Update existing progress
        db.run(
          `UPDATE user_grammar_progress 
           SET is_correct = ?, selected_answer = ?, attempts = attempts + 1, 
               updated_at = CURRENT_TIMESTAMP
           WHERE user_id = ? AND exercise_id = ?`,
          [isCorrect, selectedAnswer, userId, exerciseId],
          function (err) {
            if (err) {
              console.error("Error updating progress:", err);
              return res.status(500).json({ error: err.message });
            }
            res.json({ 
              success: true, 
              message: "Progress updated",
              isFirstAttempt: false,
              previouslyCorrect: existingProgress.is_correct === 1
            });
          }
        );
      } else {
        // Insert new progress record
        db.run(
          `INSERT INTO user_grammar_progress 
           (user_id, exercise_id, topic_id, category_id, is_correct, selected_answer, first_attempt_correct)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [userId, exerciseId, topicId, categoryId, isCorrect, selectedAnswer, isCorrect],
          function (err) {
            if (err) {
              console.error("Error saving progress:", err);
              return res.status(500).json({ error: err.message });
            }
            res.json({ 
              success: true, 
              message: "Progress saved",
              isFirstAttempt: true,
              id: this.lastID
            });
          }
        );
      }
    }
  );
});

// Get user's progress for a specific topic
app.get("/user/:userId/grammar/topic/:topicId/progress", (req, res) => {
  const { userId, topicId } = req.params;

  db.all(
    `SELECT ugp.*, ge.question, ge.options, ge.correct_index 
     FROM user_grammar_progress ugp
     JOIN grammar_exercises ge ON ugp.exercise_id = ge.id
     WHERE ugp.user_id = ? AND ugp.topic_id = ?
     ORDER BY ge.display_order`,
    [userId, topicId],
    (err, rows) => {
      if (err) {
        console.error("Error fetching topic progress:", err);
        return res.status(500).json({ error: err.message });
      }
      res.json({ progress: rows });
    }
  );
});

// Get user's progress for a specific category
app.get("/user/:userId/grammar/category/:categoryId/progress", (req, res) => {
  const { userId, categoryId } = req.params;

  db.all(
    `SELECT ugp.*, ge.question, gt.title as topic_title
     FROM user_grammar_progress ugp
     JOIN grammar_exercises ge ON ugp.exercise_id = ge.id
     JOIN grammar_topics gt ON ugp.topic_id = gt.id
     WHERE ugp.user_id = ? AND ugp.category_id = ?
     ORDER BY gt.display_order, ge.display_order`,
    [userId, categoryId],
    (err, rows) => {
      if (err) {
        console.error("Error fetching category progress:", err);
        return res.status(500).json({ error: err.message });
      }
      res.json({ progress: rows });
    }
  );
});

// Get user's overall grammar study statistics
app.get("/user/:userId/grammar/stats", (req, res) => {
  const { userId } = req.params;

  // Get comprehensive stats
  db.all(
    `SELECT 
       COUNT(*) as total_attempted,
       SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as total_correct,
       SUM(CASE WHEN first_attempt_correct = 1 THEN 1 ELSE 0 END) as first_attempt_correct,
       COUNT(DISTINCT category_id) as categories_touched,
       COUNT(DISTINCT topic_id) as topics_touched,
       AVG(attempts) as avg_attempts
     FROM user_grammar_progress 
     WHERE user_id = ?`,
    [userId],
    (err, stats) => {
      if (err) {
        console.error("Error fetching user stats:", err);
        return res.status(500).json({ error: err.message });
      }

      // Get category-wise breakdown
      db.all(
        `SELECT 
           ugp.category_id,
           gc.name as category_name,
           COUNT(*) as exercises_attempted,
           SUM(CASE WHEN ugp.is_correct = 1 THEN 1 ELSE 0 END) as exercises_correct,
           COUNT(DISTINCT ugp.topic_id) as topics_attempted
         FROM user_grammar_progress ugp
         JOIN grammar_categories gc ON ugp.category_id = gc.id
         WHERE ugp.user_id = ?
         GROUP BY ugp.category_id, gc.name
         ORDER BY gc.display_order`,
        [userId],
        (err, categoryStats) => {
          if (err) {
            console.error("Error fetching category stats:", err);
            return res.status(500).json({ error: err.message });
          }

          res.json({
            overall: stats[0] || {
              total_attempted: 0,
              total_correct: 0,
              first_attempt_correct: 0,
              categories_touched: 0,
              topics_touched: 0,
              avg_attempts: 0
            },
            byCategory: categoryStats
          });
        }
      );
    }
  );
});

// Get exercises with user's previous results for a topic
app.get("/user/:userId/grammar/topic/:topicId/exercises-with-progress", (req, res) => {
  const { userId, topicId } = req.params;

  db.all(
    `SELECT 
       ge.*,
       ugp.is_correct as user_was_correct,
       ugp.selected_answer as user_selected_answer,
       ugp.attempts as user_attempts,
       ugp.first_attempt_correct,
       ugp.completed_at as user_completed_at
     FROM grammar_exercises ge
     LEFT JOIN user_grammar_progress ugp ON ge.id = ugp.exercise_id AND ugp.user_id = ?
     WHERE ge.topic_id = ?
     ORDER BY ge.display_order`,
    [userId, topicId],
    (err, exercises) => {
      if (err) {
        console.error("Error fetching exercises with progress:", err);
        return res.status(500).json({ error: err.message });
      }

      // Parse options JSON and add progress info
      const exercisesWithProgress = exercises.map(exercise => ({
        ...exercise,
        options: JSON.parse(exercise.options),
        hasUserCompleted: exercise.user_was_correct !== null,
        userResult: exercise.user_was_correct !== null ? {
          isCorrect: exercise.user_was_correct === 1,
          selectedAnswer: exercise.user_selected_answer,
          attempts: exercise.user_attempts,
          firstAttemptCorrect: exercise.first_attempt_correct === 1,
          completedAt: exercise.user_completed_at
        } : null
      }));

      res.json({ exercises: exercisesWithProgress });
    }
  );
});

// Clear user progress for a specific topic (reset quiz)
app.delete("/user/:userId/grammar/topic/:topicId/progress", (req, res) => {
  const { userId, topicId } = req.params;

  if (!userId || !topicId) {
    return res.status(400).json({ error: "userId and topicId are required" });
  }

  // Delete all progress records for this user and topic
  db.run(
    `DELETE FROM user_grammar_progress 
     WHERE user_id = ? AND exercise_id IN (
       SELECT id FROM grammar_exercises WHERE topic_id = ?
     )`,
    [userId, topicId],
    function (err) {
      if (err) {
        console.error("Error clearing user progress:", err);
        return res.status(500).json({ error: err.message });
      }

      console.log(`Cleared ${this.changes} progress records for user ${userId} in topic ${topicId}`);
      res.json({ 
        success: true, 
        deletedCount: this.changes,
        message: `Cleared progress for ${this.changes} exercises` 
      });
    }
  );
});

// ===========================================
// GRAMMAR EXPLANATIONS API ENDPOINTS
// ===========================================

// Update explanations and examples for all topics
app.post("/admin/update-grammar-explanations", (req, res) => {
  console.log("Updating grammar explanations for all topics...");
  
  const explanations = {
    'present_simple': {
      'explanation': 'The present simple tense is used to express general facts, habits, and routines. It describes actions that happen regularly or states that are generally true. Form: Subject + base verb (+ s for third person singular).',
      'examples': [
        'I work in an office. (general fact)',
        'She plays tennis every weekend. (routine)',
        'The sun rises in the east. (general truth)',
        'They live in London. (current state)',
      ]
    },
    'present_continuous': {
      'explanation': 'The present continuous tense is used to describe actions happening right now, temporary situations, or planned future actions. Form: Subject + am/is/are + verb-ing.',
      'examples': [
        'I am writing an email right now. (happening now)',
        'She is working late this week. (temporary)',
        'We are meeting tomorrow at 3 PM. (planned future)',
        'They are watching a movie. (current action)',
      ]
    },
    'past_simple': {
      'explanation': 'The past simple tense is used to describe completed actions in the past, past habits, or a series of completed actions. Form: Subject + past form of verb (regular: verb + ed, irregular: specific forms).',
      'examples': [
        'I visited Paris last year. (completed action)',
        'She worked at that company for five years. (past habit)',
        'He ate breakfast, took a shower, and left for work. (series of actions)',
        'They were happy when they heard the news. (past state)',
      ]
    },
    'articles': {
      'explanation': 'Articles (a, an, the) are used before nouns to specify whether we are talking about something specific or general. "A/an" are indefinite articles for non-specific items. "The" is the definite article for specific items.',
      'examples': [
        'I saw a cat in the garden. (any cat)',
        'Can you pass me the salt? (specific salt)',
        'She is an engineer. (profession)',
        'The book you lent me was great. (specific book)',
      ]
    },
    'prepositions_time': {
      'explanation': 'Prepositions of time (in, on, at) show when something happens. Use "at" for specific times, "on" for days and dates, "in" for months, years, and longer periods.',
      'examples': [
        'I wake up at 7 AM. (specific time)',
        'The meeting is on Monday. (day)',
        'She was born in 1995. (year)',
        'We go on vacation in summer. (season)',
      ]
    },
    'prepositions_place': {
      'explanation': 'Prepositions of place (in, on, at, under, over, etc.) show where something is located. Use "at" for specific points, "on" for surfaces, "in" for enclosed spaces.',
      'examples': [
        'The book is on the table. (surface)',
        'She lives in New York. (city/enclosed space)',
        'Meet me at the station. (specific point)',
        'The cat is under the chair. (position)',
      ]
    },
    'common_prepositions': {
      'explanation': 'Common prepositions include words like by, with, for, from, about, etc. Each has specific uses and meanings. They often depend on the verb or adjective they follow.',
      'examples': [
        'I go to work by bus. (method)',
        'She wrote the letter with a pen. (instrument)',
        'This gift is for you. (recipient)',
        'Tell me about your trip. (topic)',
      ]
    },
    'modal_can_could': {
      'explanation': 'Can/could express ability, permission, or possibility. "Can" is for present ability/permission, "could" for past ability or polite requests.',
      'examples': [
        'I can swim. (present ability)',
        'Could you help me? (polite request)',
        'When I was young, I could run fast. (past ability)',
        'You can go now. (permission)',
      ]
    },
    'modal_will_would': {
      'explanation': 'Will/would express future actions, willingness, or habits. "Will" for future and willingness, "would" for polite requests and past habits.',
      'examples': [
        'I will call you tomorrow. (future)',
        'Would you like some coffee? (polite offer)',
        'When I was a child, I would play outside. (past habit)',
        'He will help you if you ask. (willingness)',
      ]
    },
    'modal_should_must': {
      'explanation': 'Should/must express obligation and advice. "Should" gives advice or recommendations, "must" expresses strong obligation or necessity.',
      'examples': [
        'You should see a doctor. (advice)',
        'Students must wear uniforms. (strong obligation)',
        'I must finish this today. (necessity)',
        'You should try this restaurant. (recommendation)',
      ]
    },
    'countable_uncountable': {
      'explanation': 'Countable nouns can be counted (book/books), uncountable nouns cannot (water, information). Use different quantifiers: much/many, little/few, some/any.',
      'examples': [
        'I have many books. (countable)',
        'There is much water in the glass. (uncountable)',
        'Few people came to the party. (countable)',
        'I have little time. (uncountable)',
      ]
    },
    'quantifiers': {
      'explanation': 'Quantifiers (some, any, much, many, few, little) indicate quantity. Choice depends on whether the noun is countable/uncountable and if the sentence is positive/negative/question.',
      'examples': [
        'I have some apples. (positive, countable)',
        'Is there any milk? (question, uncountable)',
        'She doesn\'t have many friends. (negative, countable)',
        'There isn\'t much traffic today. (negative, uncountable)',
      ]
    },
    'comparatives': {
      'explanation': 'Comparatives compare two things. For short adjectives: add -er (tall → taller). For long adjectives: use "more" (beautiful → more beautiful). Irregular: good → better.',
      'examples': [
        'She is taller than her sister. (short adjective)',
        'This movie is more interesting than the last one. (long adjective)',
        'Today is better than yesterday. (irregular)',
        'My car is faster than yours. (short adjective)',
      ]
    },
    'superlatives': {
      'explanation': 'Superlatives describe the extreme degree among three or more things. For short adjectives: add -est (tall → tallest). For long adjectives: use "most" (beautiful → most beautiful).',
      'examples': [
        'She is the tallest in the class. (short adjective)',
        'This is the most beautiful place I\'ve seen. (long adjective)',
        'He is the best player on the team. (irregular)',
        'That was the worst movie ever. (irregular)',
      ]
    },
    'conditionals_zero_first': {
      'explanation': 'Zero conditional (if + present, present) expresses general truths. First conditional (if + present, will + base verb) expresses real future possibilities.',
      'examples': [
        'If you heat water to 100°C, it boils. (zero - general truth)',
        'If it rains tomorrow, we will stay home. (first - real possibility)',
        'If you study hard, you will pass the exam. (first)',
        'If I press this button, the light turns on. (zero)',
      ]
    },
    'conditionals_second_third': {
      'explanation': 'Second conditional (if + past simple, would + base verb) expresses unreal present situations. Third conditional (if + past perfect, would have + past participle) expresses unreal past situations.',
      'examples': [
        'If I were rich, I would travel the world. (second - unreal present)',
        'If I had studied harder, I would have passed. (third - unreal past)',
        'If she spoke French, she would get the job. (second)',
        'If we had left earlier, we would have caught the train. (third)',
      ]
    },
    'passive_voice': {
      'explanation': 'Passive voice emphasizes the action or result rather than who performs it. Form: Object + be + past participle (+ by + agent). Use when the doer is unknown, unimportant, or obvious.',
      'examples': [
        'The book was written by Shakespeare. (emphasis on book)',
        'The window was broken. (doer unknown)',
        'English is spoken worldwide. (general statement)',
        'The project will be completed next month. (emphasis on completion)',
      ]
    },
    'question_formation': {
      'explanation': 'Questions are formed differently based on type: Yes/No questions (auxiliary + subject + main verb), Wh-questions (question word + auxiliary + subject + main verb), or question tags.',
      'examples': [
        'Do you like coffee? (yes/no question)',
        'Where do you live? (wh-question)',
        'You are coming, aren\'t you? (question tag)',
        'What time does the movie start? (wh-question)',
      ]
    },
    'reported_speech': {
      'explanation': 'Reported speech tells what someone said without using their exact words. Change pronouns, time expressions, and often tense. Use reporting verbs like "said," "told," "asked."',
      'examples': [
        'Direct: "I am tired." → Reported: She said she was tired.',
        'Direct: "Where do you live?" → Reported: He asked where I lived.',
        'Direct: "I will call you tomorrow." → Reported: She said she would call me the next day.',
        'Direct: "Don\'t go there!" → Reported: He told me not to go there.',
      ]
    },
    'phrasal_verbs': {
      'explanation': 'Phrasal verbs combine a verb with a preposition or adverb to create new meanings. Some are separable (turn off the light/turn the light off), others are inseparable (look after).',
      'examples': [
        'Please turn off the lights. (separable)',
        'I need to look after my sister. (inseparable)',
        'The meeting was put off until next week. (postponed)',
        'She came across an old photo. (found by chance)',
      ]
    },
    'relative_clauses': {
      'explanation': 'Relative clauses give additional information about nouns. Use relative pronouns: who (people), which (things), that (people/things), where (places), when (time). Defining clauses are essential; non-defining clauses add extra information.',
      'examples': [
        'The man who lives next door is a doctor. (defining)',
        'My car, which is red, is parked outside. (non-defining)',
        'The book that you recommended was great. (defining)',
        'London, where I was born, is a big city. (non-defining)',
      ]
    }
  };

  let topicsUpdated = 0;
  const topicIds = Object.keys(explanations);
  
  topicIds.forEach((topicId, index) => {
    const data = explanations[topicId];
    db.run(
      `UPDATE grammar_topics 
       SET explanation = ?, examples = ? 
       WHERE id = ?`,
      [data.explanation, JSON.stringify(data.examples), topicId],
      function (err) {
        if (err) {
          console.error(`Error updating topic ${topicId}:`, err);
        } else {
          topicsUpdated++;
          console.log(`Updated topic ${topicId} with explanation and examples`);
        }
        
        // Send response when all topics are processed
        if (index === topicIds.length - 1) {
          res.json({ 
            success: true, 
            message: `Updated explanations for ${topicsUpdated} topics`,
            topicsUpdated 
          });
        }
      }
    );
  });
});

// Get grammar topic with explanation and examples
app.get("/grammar/topics/:topicId/explanation", (req, res) => {
  const { topicId } = req.params;
  
  db.get(
    `SELECT id, title, description, level, explanation, examples
     FROM grammar_topics 
     WHERE id = ?`,
    [topicId],
    (err, topic) => {
      if (err) {
        console.error("Error fetching topic explanation:", err);
        return res.status(500).json({ error: err.message });
      }
      
      if (!topic) {
        return res.status(404).json({ error: "Topic not found" });
      }
      
      // Parse examples JSON
      let examples = [];
      if (topic.examples) {
        try {
          examples = JSON.parse(topic.examples);
        } catch (e) {
          console.error("Error parsing examples JSON:", e);
          examples = [];
        }
      }
      
      res.json({
        ...topic,
        examples: examples
      });
    }
  );
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// Endpoint to generate exercises for all topics (development use)
app.post("/admin/generate-exercises", (req, res) => {
  console.log("Generating exercises for all topics...");
  
  // Get all topics first
  db.all("SELECT * FROM grammar_topics ORDER BY category_id, display_order", (err, topics) => {
    if (err) {
      console.error("Error fetching topics:", err);
      return res.status(500).json({ error: err.message });
    }
    
    console.log(`Found ${topics.length} topics`);
    let exercisesInserted = 0;
    let topicsProcessed = 0;
    
    const exercises = {
      // Grammar Foundations
      "present_simple": [
        {
          question: "I ___ to work every day.",
          options: ["go", "goes", "going", "went"],
          correctIndex: 0,
          difficulty: "easy"
        },
        {
          question: "She ___ coffee in the morning.",
          options: ["drink", "drinks", "drinking", "drank"],
          correctIndex: 1,
          difficulty: "easy"
        },
        {
          question: "They ___ English at school.",
          options: ["studies", "study", "studying", "studied"],
          correctIndex: 1,
          difficulty: "easy"
        }
      ],
      
      "articles": [
        {
          question: "I need ___ umbrella.",
          options: ["a", "an", "the", "no article"],
          correctIndex: 1,
          difficulty: "easy"
        },
        {
          question: "___ sun is shining today.",
          options: ["A", "An", "The", "No article"],
          correctIndex: 2,
          difficulty: "easy"
        },
        {
          question: "Can you pass me ___ salt?",
          options: ["a", "an", "the", "no article"],
          correctIndex: 2,
          difficulty: "easy"
        }
      ],
      
      "plural_nouns": [
        {
          question: "The plural of 'child' is ___.",
          options: ["childs", "children", "childes", "child"],
          correctIndex: 1,
          difficulty: "easy"
        },
        {
          question: "Three ___ are playing in the park.",
          options: ["woman", "womans", "women", "womens"],
          correctIndex: 2,
          difficulty: "easy"
        },
        {
          question: "I bought two ___.",
          options: ["boxs", "boxes", "boxies", "box"],
          correctIndex: 1,
          difficulty: "easy"
        }
      ],
      
      "pronouns": [
        {
          question: "___ am a student.",
          options: ["I", "Me", "My", "Mine"],
          correctIndex: 0,
          difficulty: "easy"
        },
        {
          question: "Can you help ___?",
          options: ["I", "me", "my", "mine"],
          correctIndex: 1,
          difficulty: "easy"
        },
        {
          question: "This book is ___.",
          options: ["I", "me", "my", "mine"],
          correctIndex: 3,
          difficulty: "easy"
        }
      ],
      
      // Elementary Grammar
      "past_simple": [
        {
          question: "I ___ to the store yesterday.",
          options: ["go", "goes", "went", "going"],
          correctIndex: 2,
          difficulty: "easy"
        },
        {
          question: "She ___ a movie last night.",
          options: ["watch", "watches", "watched", "watching"],
          correctIndex: 2,
          difficulty: "easy"
        },
        {
          question: "They ___ home late.",
          options: ["come", "comes", "came", "coming"],
          correctIndex: 2,
          difficulty: "easy"
        }
      ],
      
      "future_simple": [
        {
          question: "I ___ see you tomorrow.",
          options: ["will", "would", "shall", "should"],
          correctIndex: 0,
          difficulty: "easy"
        },
        {
          question: "She ___ call you later.",
          options: ["will", "would", "shall", "should"],
          correctIndex: 0,
          difficulty: "easy"
        },
        {
          question: "We ___ travel next month.",
          options: ["will", "would", "shall", "should"],
          correctIndex: 0,
          difficulty: "easy"
        }
      ],
      
      "prepositions": [
        {
          question: "I will see you ___ Monday.",
          options: ["in", "on", "at", "by"],
          correctIndex: 1,
          difficulty: "easy"
        },
        {
          question: "The meeting is ___ 3 o'clock.",
          options: ["in", "on", "at", "by"],
          correctIndex: 2,
          difficulty: "easy"
        },
        {
          question: "The book is ___ the table.",
          options: ["in", "on", "at", "under"],
          correctIndex: 1,
          difficulty: "easy"
        },
        {
          question: "I live ___ New York.",
          options: ["in", "on", "at", "by"],
          correctIndex: 0,
          difficulty: "easy"
        }
      ],
      
      // Intermediate Grammar
      "present_perfect": [
        {
          question: "I ___ finished my homework.",
          options: ["have", "has", "had", "having"],
          correctIndex: 0,
          difficulty: "medium"
        },
        {
          question: "She ___ visited Paris before.",
          options: ["have", "has", "had", "having"],
          correctIndex: 1,
          difficulty: "medium"
        },
        {
          question: "They ___ never seen this movie.",
          options: ["have", "has", "had", "having"],
          correctIndex: 0,
          difficulty: "medium"
        }
      ],
      
      "past_continuous": [
        {
          question: "I ___ reading when you called.",
          options: ["am", "was", "were", "is"],
          correctIndex: 1,
          difficulty: "medium"
        },
        {
          question: "They ___ playing football at 3 PM.",
          options: ["was", "were", "are", "is"],
          correctIndex: 1,
          difficulty: "medium"
        },
        {
          question: "She ___ cooking dinner when I arrived.",
          options: ["was", "were", "is", "are"],
          correctIndex: 0,
          difficulty: "medium"
        }
      ],
      
      "comparatives_superlatives": [
        {
          question: "This book is ___ than that one.",
          options: ["good", "better", "best", "more good"],
          correctIndex: 1,
          difficulty: "medium"
        },
        {
          question: "She is the ___ student in the class.",
          options: ["smart", "smarter", "smartest", "most smart"],
          correctIndex: 2,
          difficulty: "medium"
        },
        {
          question: "Today is ___ than yesterday.",
          options: ["hot", "hotter", "hottest", "more hot"],
          correctIndex: 1,
          difficulty: "medium"
        }
      ],
      
      "modal_verbs": [
        {
          question: "You ___ drive carefully.",
          options: ["must", "can", "may", "might"],
          correctIndex: 0,
          difficulty: "medium"
        },
        {
          question: "I ___ swim when I was five.",
          options: ["can", "could", "may", "might"],
          correctIndex: 1,
          difficulty: "medium"
        },
        {
          question: "___ I borrow your pen?",
          options: ["Must", "Can", "May", "Should"],
          correctIndex: 2,
          difficulty: "medium"
        }
      ],
      
      // Upper-Intermediate Grammar
      "perfect_continuous": [
        {
          question: "I ___ working here for five years.",
          options: ["have been", "has been", "had been", "will have been"],
          correctIndex: 0,
          difficulty: "hard"
        },
        {
          question: "She ___ studying English since 2020.",
          options: ["have been", "has been", "had been", "will have been"],
          correctIndex: 1,
          difficulty: "hard"
        },
        {
          question: "They ___ waiting for two hours when the bus arrived.",
          options: ["have been", "has been", "had been", "will have been"],
          correctIndex: 2,
          difficulty: "hard"
        }
      ],
      
      "relative_clauses": [
        {
          question: "The book ___ I read was interesting.",
          options: ["who", "which", "what", "where"],
          correctIndex: 1,
          difficulty: "hard"
        },
        {
          question: "The person ___ called you is my friend.",
          options: ["who", "which", "what", "where"],
          correctIndex: 0,
          difficulty: "hard"
        },
        {
          question: "The place ___ we met is a coffee shop.",
          options: ["who", "which", "what", "where"],
          correctIndex: 3,
          difficulty: "hard"
        }
      ],
      
      "gerunds_infinitives": [
        {
          question: "I enjoy ___ books.",
          options: ["read", "to read", "reading", "reads"],
          correctIndex: 2,
          difficulty: "hard"
        },
        {
          question: "I want ___ English.",
          options: ["learn", "to learn", "learning", "learns"],
          correctIndex: 1,
          difficulty: "hard"
        },
        {
          question: "She decided ___ home.",
          options: ["go", "to go", "going", "goes"],
          correctIndex: 1,
          difficulty: "hard"
        }
      ],
      
      // Advanced Grammar
      "conditionals": [
        {
          question: "If it rains, I ___ stay home.",
          options: ["will", "would", "shall", "should"],
          correctIndex: 0,
          difficulty: "hard"
        },
        {
          question: "If I were rich, I ___ travel the world.",
          options: ["will", "would", "shall", "should"],
          correctIndex: 1,
          difficulty: "hard"
        },
        {
          question: "If you heat water to 100°C, it ___.",
          options: ["boil", "boils", "will boil", "would boil"],
          correctIndex: 1,
          difficulty: "hard"
        }
      ],
      
      "passive_voice": [
        {
          question: "The cake ___ by Mary.",
          options: ["made", "was made", "is making", "makes"],
          correctIndex: 1,
          difficulty: "hard"
        },
        {
          question: "English ___ all over the world.",
          options: ["speaks", "is spoken", "speaking", "spoke"],
          correctIndex: 1,
          difficulty: "hard"
        },
        {
          question: "The letter ___ yesterday.",
          options: ["sent", "was sent", "sending", "sends"],
          correctIndex: 1,
          difficulty: "hard"
        }
      ],
      
      "reported_speech": [
        {
          question: "He said he ___ come tomorrow.",
          options: ["will", "would", "shall", "should"],
          correctIndex: 1,
          difficulty: "hard"
        },
        {
          question: "She told me she ___ tired.",
          options: ["is", "was", "were", "are"],
          correctIndex: 1,
          difficulty: "hard"
        },
        {
          question: "They said they ___ the movie.",
          options: ["like", "liked", "likes", "liking"],
          correctIndex: 1,
          difficulty: "hard"
        }
      ],
      
      "subjunctive_mood": [
        {
          question: "I suggest that he ___ early.",
          options: ["leave", "leaves", "left", "leaving"],
          correctIndex: 0,
          difficulty: "hard"
        },
        {
          question: "It's important that she ___ on time.",
          options: ["is", "be", "was", "being"],
          correctIndex: 1,
          difficulty: "hard"
        },
        {
          question: "I wish I ___ speak French.",
          options: ["can", "could", "may", "might"],
          correctIndex: 1,
          difficulty: "hard"
        }
      ],
      
      // Business English Grammar
      "formal_language": [
        {
          question: "We would like to ___ our sincere apologies.",
          options: ["offer", "give", "make", "present"],
          correctIndex: 0,
          difficulty: "medium"
        },
        {
          question: "Please find ___ the requested documents.",
          options: ["attach", "attached", "attachment", "attaching"],
          correctIndex: 1,
          difficulty: "medium"
        },
        {
          question: "We ___ to inform you of the policy change.",
          options: ["write", "are writing", "wrote", "have written"],
          correctIndex: 1,
          difficulty: "medium"
        }
      ],
      
      "email_structure": [
        {
          question: "Dear ___ Smith, (formal business email)",
          options: ["Mr", "Mr.", "Mister", "mister"],
          correctIndex: 1,
          difficulty: "medium"
        },
        {
          question: "I am writing to ___ about the meeting.",
          options: ["inquire", "inquiring", "inquiry", "inquired"],
          correctIndex: 0,
          difficulty: "medium"
        },
        {
          question: "Thank you for your ___ consideration.",
          options: ["kind", "kindly", "kindness", "kinds"],
          correctIndex: 0,
          difficulty: "medium"
        }
      ],
      
      // Academic English Grammar
      "complex_sentences": [
        {
          question: "Although it was raining, ___ went to the park.",
          options: ["but we", "we", "however we", "so we"],
          correctIndex: 1,
          difficulty: "hard"
        },
        {
          question: "The research ___ that students benefit from online learning.",
          options: ["indicate", "indicates", "indicating", "indicated"],
          correctIndex: 1,
          difficulty: "hard"
        },
        {
          question: "___, this study has several limitations.",
          options: ["However", "Therefore", "Moreover", "Furthermore"],
          correctIndex: 0,
          difficulty: "hard"
        }
      ]
    };
    
    // Process each topic
    topics.forEach((topic, topicIndex) => {
      const topicExercises = exercises[topic.id] || [];
      
      if (topicExercises.length > 0) {
        console.log(`Generating ${topicExercises.length} exercises for topic: ${topic.title}`);
        
        topicExercises.forEach((exercise, exerciseIndex) => {
          const exerciseId = `${topic.id}_ex_${exerciseIndex + 1}`;
          
          db.run(
            `INSERT OR REPLACE INTO grammar_exercises 
             (id, topic_id, question, options, correct_index, difficulty, display_order) 
             VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [
              exerciseId,
              topic.id,
              exercise.question,
              JSON.stringify(exercise.options),
              exercise.correctIndex,
              exercise.difficulty,
              exerciseIndex + 1
            ],
            function(err) {
              if (err) {
                console.error(`Error inserting exercise for ${topic.id}:`, err);
              } else {
                exercisesInserted++;
                console.log(`Inserted exercise: ${exerciseId}`);
              }
              
              // Check if all exercises are processed
              if (topicIndex === topics.length - 1 && 
                  exerciseIndex === topicExercises.length - 1) {
                setTimeout(() => {
                  console.log(`Finished generating exercises. Total inserted: ${exercisesInserted}`);
                  res.json({ 
                    message: "Exercises generated successfully", 
                    totalExercises: exercisesInserted,
                    topicsProcessed: topics.length 
                  });
                }, 100);
              }
            }
          );
        });
      } else {
        console.log(`No exercises defined for topic: ${topic.title} (${topic.id})`);
        topicsProcessed++;
        
        if (topicsProcessed === topics.length) {
          res.json({ 
            message: "Exercise generation completed", 
            totalExercises: exercisesInserted,
            topicsProcessed: topics.length 
          });
        }
      }
    });
    
    if (topics.length === 0) {
      res.json({ message: "No topics found in database" });
    }
  });
});

// --- Grammar Data Seeder Endpoint (for development/demo) ---
// Call this endpoint ONCE to populate the DB with sample grammar data
app.post("/seed-grammar-data", (req, res) => {
  // Sample categories, topics, and exercises
  const categories = [
    { id: "tenses", name: "Tenses", description: "English verb tenses" },
    { id: "articles", name: "Articles", description: "Definite and indefinite articles" },
    { id: "prepositions", name: "Prepositions", description: "Common English prepositions" },
    { id: "conditionals", name: "Conditionals", description: "Conditional sentences" },
    { id: "passive_voice", name: "Passive Voice", description: "Passive constructions" },
  ];

  const topics = [
    // Tenses
    {
      category: 0,
      name: "Present Simple",
      description: "Usage of present simple tense",
    },
    {
      category: 0,
      name: "Past Simple",
      description: "Usage of past simple tense",
    },
    {
      category: 0,
      name: "Future Simple",
      description: "Usage of future simple tense",
    },
    // Articles
    { category: 1, name: "A vs An", description: "When to use 'a' and 'an'" },
    { category: 1, name: "The", description: "Usage of 'the'" },
    // Prepositions
    {
      category: 2,
      name: "In/On/At (Time)",
      description: "Prepositions of time",
    },
    {
      category: 2,
      name: "In/On/At (Place)",
      description: "Prepositions of place",
    },
    // Conditionals
    {
      category: 3,
      name: "Zero Conditional",
      description: "Facts and general truths",
    },
    {
      category: 3,
      name: "First Conditional",
      description: "Real future possibilities",
    },
    // Passive Voice
    {
      category: 4,
      name: "Forming the Passive",
      description: "How to form passive sentences",
    },
  ];

  const exercises = [
    // Present Simple
    {
      topic: 0,
      question: "She ___ to school every day.",
      options: ["go", "goes", "going", "gone"],
      answer: "goes",
      explanation: "Use 'goes' for third person singular in present simple.",
    },
    {
      topic: 0,
      question: "I ___ coffee in the morning.",
      options: ["drink", "drinks", "drank", "drinking"],
      answer: "drink",
      explanation: "Use base form 'drink' for 'I' in present simple.",
    },
    // Past Simple
    {
      topic: 1,
      question: "They ___ to Paris last year.",
      options: ["go", "goes", "went", "gone"],
      answer: "went",
      explanation: "'Went' is the past simple of 'go'.",
    },
    // Future Simple
    {
      topic: 2,
      question: "I ___ call you tomorrow.",
      options: ["will", "would", "am", "can"],
      answer: "will",
      explanation: "'Will' is used for future simple.",
    },
    // A vs An
    {
      topic: 3,
      question: "He is ___ honest man.",
      options: ["a", "an", "the", "no article"],
      answer: "an",
      explanation: "Use 'an' before vowel sounds.",
    },
    // The
    {
      topic: 4,
      question: "___ sun rises in the east.",
      options: ["A", "An", "The", "No article"],
      answer: "The",
      explanation: "Use 'the' for unique things like 'the sun'.",
    },
    // In/On/At (Time)
    {
      topic: 5,
      question: "My birthday is ___ July.",
      options: ["in", "on", "at", "by"],
      answer: "in",
      explanation: "Use 'in' for months.",
    },
    // In/On/At (Place)
    {
      topic: 6,
      question: "She is ___ the bus.",
      options: ["in", "on", "at", "by"],
      answer: "on",
      explanation: "Use 'on' for public transport.",
    },
    // Zero Conditional
    {
      topic: 7,
      question: "If you heat ice, it ___.",
      options: ["melts", "melt", "will melt", "is melting"],
      answer: "melts",
      explanation: "Zero conditional: present simple in both clauses.",
    },
    // First Conditional
    {
      topic: 8,
      question: "If it rains, I ___ at home.",
      options: ["stay", "will stay", "stayed", "stays"],
      answer: "will stay",
      explanation: "First conditional: present simple + will + base verb.",
    },
    // Passive Voice
    {
      topic: 9,
      question: "The cake ___ by Mary.",
      options: ["was made", "made", "is making", "makes"],
      answer: "was made",
      explanation: "Past simple passive: was/were + past participle.",
    },
  ];

  // Insert categories, then topics, then exercises
  db.serialize(() => {
    // Insert categories
    const catIds = [];
    let catDone = 0;
    categories.forEach((cat, i) => {
      db.run(
        "INSERT INTO grammar_categories (id, name, description) VALUES (?, ?, ?)",
        [cat.id, cat.name, cat.description],
        function (err) {
          if (err) return res.status(500).json({ error: err.message });
          catIds[i] = cat.id;  // Use the id instead of lastID
          catDone++;
          if (catDone === categories.length) insertTopics();
        }
      );
    });

    function insertTopics() {
      const topicIds = [];
      let topicDone = 0;
      topics.forEach((topic, i) => {
        db.run(
          "INSERT INTO grammar_topics (category_id, name, description) VALUES (?, ?, ?)",
          [catIds[topic.category], topic.name, topic.description],
          function (err) {
            if (err) return res.status(500).json({ error: err.message });
            topicIds[i] = this.lastID;
            topicDone++;
            if (topicDone === topics.length) insertExercises(topicIds);
          }
        );
      });
    }

    function insertExercises(topicIds) {
      let exDone = 0;
      exercises.forEach((ex, i) => {
        db.run(
          "INSERT INTO grammar_exercises (topic_id, question, options, answer, explanation) VALUES (?, ?, ?, ?, ?)",
          [
            topicIds[ex.topic],
            ex.question,
            JSON.stringify(ex.options),
            ex.answer,
            ex.explanation,
          ],
          function (err) {
            if (err) return res.status(500).json({ error: err.message });
            exDone++;
            if (exDone === exercises.length) {
              res.json({ success: true, message: "Grammar data seeded!" });
            }
          }
        );
      });
    }
  });
});
