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

  // Initialize default AI model setting
  db.run(
    "INSERT OR IGNORE INTO app_settings (setting_key, setting_value) VALUES (?, ?)",
    ["selected_ai_model", "deepseek/deepseek-chat-v3-0324:free"]
  );
});

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
// Grammar categories, topics, and exercises tables
db.run(`CREATE TABLE IF NOT EXISTS grammar_categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT
  )`);

db.run(`CREATE TABLE IF NOT EXISTS grammar_topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    FOREIGN KEY (category_id) REFERENCES grammar_categories(id) ON DELETE CASCADE
  )`);

db.run(`CREATE TABLE IF NOT EXISTS grammar_exercises (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    question TEXT NOT NULL,
    options TEXT NOT NULL,
    answer TEXT NOT NULL,
    explanation TEXT,
    FOREIGN KEY (topic_id) REFERENCES grammar_topics(id) ON DELETE CASCADE
  )`);
app.post("/user/:userId/track-message", (req, res) => {
  const { userId } = req.params;
  const { message_content, message_type } = req.body;

  // --- Grammar Data Endpoints ---

  // Get all grammar categories
  app.get("/grammar/categories", (req, res) => {
    db.all("SELECT * FROM grammar_categories", [], (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(rows);
    });
  });

  // Create a grammar category
  app.post("/grammar/categories", (req, res) => {
    const { name, description } = req.body;
    if (!name)
      return res.status(400).json({ error: "Category name is required" });
    db.run(
      "INSERT INTO grammar_categories (name, description) VALUES (?, ?)",
      [name, description || null],
      function (err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ id: this.lastID });
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

// --- Grammar Data Endpoints ---

// Get all grammar categories
app.get("/grammar/categories", (req, res) => {
  db.all("SELECT * FROM grammar_categories", [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

// Create a grammar category
app.post("/grammar/categories", (req, res) => {
  const { name, description } = req.body;
  if (!name)
    return res.status(400).json({ error: "Category name is required" });
  db.run(
    "INSERT INTO grammar_categories (name, description) VALUES (?, ?)",
    [name, description || null],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ id: this.lastID });
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

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// --- Grammar Data Seeder Endpoint (for development/demo) ---
// Call this endpoint ONCE to populate the DB with sample grammar data
app.post("/seed-grammar-data", (req, res) => {
  // Sample categories, topics, and exercises
  const categories = [
    { name: "Tenses", description: "English verb tenses" },
    { name: "Articles", description: "Definite and indefinite articles" },
    { name: "Prepositions", description: "Common English prepositions" },
    { name: "Conditionals", description: "Conditional sentences" },
    { name: "Passive Voice", description: "Passive constructions" },
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
        "INSERT INTO grammar_categories (name, description) VALUES (?, ?)",
        [cat.name, cat.description],
        function (err) {
          if (err) return res.status(500).json({ error: err.message });
          catIds[i] = this.lastID;
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
