require('dotenv').config();
const express = require('express');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();
const axios = require('axios');

const app = express();
app.use(cors());
app.use(express.json());

// SQLite setup
const db = new sqlite3.Database('./aitalk.db');
db.serialize(() => {
  db.run('CREATE TABLE IF NOT EXISTS vocab (id INTEGER PRIMARY KEY, word TEXT, meaning TEXT, mastered INTEGER DEFAULT 0)');
  db.run('CREATE TABLE IF NOT EXISTS progress (id INTEGER PRIMARY KEY, metric TEXT, value INTEGER)');
  db.run('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, email TEXT UNIQUE, password TEXT, name TEXT)');
  db.run('CREATE TABLE IF NOT EXISTS lessons (id INTEGER PRIMARY KEY, title TEXT, content TEXT, difficulty TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)');
  db.run('CREATE TABLE IF NOT EXISTS user_streaks (id INTEGER PRIMARY KEY, user_id INTEGER, streak_count INTEGER, last_activity DATE)');
  db.run('CREATE TABLE IF NOT EXISTS badges (id INTEGER PRIMARY KEY, user_id INTEGER, badge_name TEXT, earned_at DATETIME DEFAULT CURRENT_TIMESTAMP)');
  db.run('CREATE TABLE IF NOT EXISTS leaderboard (id INTEGER PRIMARY KEY, user_id INTEGER, score INTEGER, updated_at DATETIME DEFAULT CURRENT_TIMESTAMP)');
});

// OpenAI setup
const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
const OPENROUTER_BASE_URL = 'https://openrouter.ai/api/v1/chat/completions';

// Chat endpoint
app.post('/chat', async (req, res) => {
  const { message } = req.body;
  try {
    const response = await axios.post(
      OPENROUTER_BASE_URL,
      {
        model: 'google/gemini-pro',
        messages: [
          { role: 'system', content: 'You are a patient, encouraging English tutor.' },
          { role: 'user', content: message }
        ],
      },
      {
        headers: {
          'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );
    res.json({ reply: response.data.choices[0].message.content });
  } catch (err) {
    console.log('OpenRouter API error, using fallback response:', err.message);
    // Fallback responses for demo purposes
    const fallbackResponses = [
      `That's a great question! "${message}" - Let me help you with that. As your English tutor, I encourage you to keep practicing. Can you try expanding on that thought?`,
      `I see you wrote: "${message}". That's excellent practice! Remember, the key to learning English is consistent conversation. What would you like to talk about next?`,
      `"${message}" - Perfect! I love seeing you engage with English. Let's work on building your confidence. Can you tell me more about this topic?`,
      `Wonderful input: "${message}". As your AI tutor, I'm here to help you improve. Try using some descriptive words to make your sentences more interesting!`,
      `Great job with: "${message}". Keep up the good work! Remember, every conversation helps you get better at English. What else would you like to discuss?`
    ];
    const fallbackReply = fallbackResponses[Math.floor(Math.random() * fallbackResponses.length)];
    res.json({ reply: fallbackReply });
  }
});

// Grammar correction endpoint
app.post('/grammar', async (req, res) => {
  const { sentence } = req.body;
  try {
    const response = await axios.post(
      OPENROUTER_BASE_URL,
      {
        model: 'google/gemini-pro',
        messages: [
          { role: 'system', content: 'Correct grammar and explain mistakes.' },
          { role: 'user', content: sentence }
        ],
      },
      {
        headers: {
          'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );
    res.json({ correction: response.data.choices[0].message.content });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Vocabulary endpoints
app.get('/vocab', (req, res) => {
  db.all('SELECT * FROM vocab', [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});
app.post('/vocab', (req, res) => {
  const { word, meaning } = req.body;
  db.run('INSERT INTO vocab (word, meaning) VALUES (?, ?)', [word, meaning], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ id: this.lastID });
  });
});
app.put('/vocab/:id', (req, res) => {
  const { mastered } = req.body;
  db.run('UPDATE vocab SET mastered = ? WHERE id = ?', [mastered, req.params.id], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ updated: this.changes });
  });
});

app.delete('/vocab/:id', (req, res) => {
  db.run('DELETE FROM vocab WHERE id = ?', [req.params.id], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ deleted: this.changes });
  });
});

// User Authentication endpoints
app.post('/auth/register', (req, res) => {
  const { email, password, name } = req.body;
  db.run('INSERT INTO users (email, password, name) VALUES (?, ?, ?)', [email, password, name], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ id: this.lastID, message: 'User registered successfully' });
  });
});

app.post('/auth/login', (req, res) => {
  const { email, password } = req.body;
  db.get('SELECT * FROM users WHERE email = ? AND password = ?', [email, password], (err, row) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!row) return res.status(401).json({ error: 'Invalid credentials' });
    res.json({ user: { id: row.id, email: row.email, name: row.name }, message: 'Login successful' });
  });
});

// Enhanced Lesson endpoints
app.get('/lessons', (req, res) => {
  db.all('SELECT * FROM lessons ORDER BY created_at DESC', [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.post('/lessons', (req, res) => {
  const { title, content, difficulty } = req.body;
  db.run('INSERT INTO lessons (title, content, difficulty) VALUES (?, ?, ?)', [title, content, difficulty], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ id: this.lastID });
  });
});

app.put('/lessons/:id', (req, res) => {
  const { title, content, difficulty } = req.body;
  db.run('UPDATE lessons SET title = ?, content = ?, difficulty = ? WHERE id = ?', [title, content, difficulty, req.params.id], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ updated: this.changes });
  });
});

app.delete('/lessons/:id', (req, res) => {
  db.run('DELETE FROM lessons WHERE id = ?', [req.params.id], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ deleted: this.changes });
  });
});

// Gamification endpoints
app.get('/streak/:userId', (req, res) => {
  db.get('SELECT * FROM user_streaks WHERE user_id = ?', [req.params.userId], (err, row) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(row || { user_id: req.params.userId, streak_count: 0 });
  });
});

app.post('/streak/:userId', (req, res) => {
  const { streak_count } = req.body;
  const userId = req.params.userId;
  db.run('INSERT OR REPLACE INTO user_streaks (user_id, streak_count, last_activity) VALUES (?, ?, DATE("now"))', 
    [userId, streak_count], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

app.get('/badges/:userId', (req, res) => {
  db.all('SELECT * FROM badges WHERE user_id = ?', [req.params.userId], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.post('/badges', (req, res) => {
  const { user_id, badge_name } = req.body;
  db.run('INSERT INTO badges (user_id, badge_name) VALUES (?, ?)', [user_id, badge_name], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ id: this.lastID });
  });
});

app.get('/leaderboard', (req, res) => {
  db.all(`SELECT u.name, l.score, s.streak_count 
          FROM leaderboard l 
          JOIN users u ON l.user_id = u.id 
          LEFT JOIN user_streaks s ON l.user_id = s.user_id 
          ORDER BY l.score DESC LIMIT 10`, [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.post('/leaderboard', (req, res) => {
  const { user_id, score } = req.body;
  db.run('INSERT OR REPLACE INTO leaderboard (user_id, score) VALUES (?, ?)', [user_id, score], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true });
  });
});

// Enhanced Lesson planning endpoint with AI
app.get('/lesson', (req, res) => {
  res.json({ lesson: 'Today: Practice introductions, review 5 new words, and chat with the AI tutor.' });
});

app.post('/lesson/generate', async (req, res) => {
  const { level, topic } = req.body;
  try {
    const response = await axios.post(
      OPENROUTER_BASE_URL,
      {
        model: 'google/gemini-pro',
        messages: [
          { role: 'system', content: 'You are an English lesson planner. Create structured lesson plans.' },
          { role: 'user', content: `Create a ${level} level English lesson about ${topic}. Include objectives, activities, and exercises.` }
        ],
      },
      {
        headers: {
          'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );
    res.json({ lesson: response.data.choices[0].message.content });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Progress tracking endpoint
app.get('/progress', (req, res) => {
  db.all('SELECT * FROM progress', [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});
app.post('/progress', (req, res) => {
  const { metric, value } = req.body;
  db.run('INSERT INTO progress (metric, value) VALUES (?, ?)', [metric, value], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ id: this.lastID });
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
