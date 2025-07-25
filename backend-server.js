require('dotenv').config();
const express = require('express');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();
const axios = require('axios');

const app = express();

// Enhanced CORS configuration for web development - Allow all origins for testing
app.use(cors({
  origin: '*', // Allow all origins for now
  credentials: false, // Disable credentials when using wildcard
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With'],
}));

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
  console.log('=== Chat API Called ===');
  console.log('Request method:', req.method);
  console.log('Request headers:', req.headers);
  console.log('Request body:', req.body);
  console.log('Request origin:', req.headers.origin);
  
  const { message } = req.body;
  
  // Check if API key is configured
  if (!OPENROUTER_API_KEY || OPENROUTER_API_KEY === 'your_api_key_here') {
    // Provide a fallback response for demo purposes
    const demoResponses = [
      "That's a great question! I'm here to help you learn English. What would you like to practice today?",
      "Excellent! Let's work on improving your English skills. Would you like to focus on grammar, vocabulary, or conversation?",
      "I understand what you're saying. English can be challenging, but with practice, you'll get better! What specific area would you like help with?",
      "Good job on expressing yourself! Remember, making mistakes is part of learning. Keep practicing!",
      "That's an interesting point! In English, we would typically say... Would you like me to explain the grammar rule behind this?"
    ];
    const randomResponse = demoResponses[Math.floor(Math.random() * demoResponses.length)];
    return res.json({ reply: `[Demo Mode] ${randomResponse}` });
  }
  
  try {
    const response = await axios.post(
      OPENROUTER_BASE_URL,
      {
        model: 'deepseek/deepseek-chat-v3-0324:free',
        messages: [
          { role: 'system', content: 'You are a friendly, encouraging English conversation partner. Always respond in 3 parts: 1) If there are grammar/language errors, start with "Great question! A better way to phrase this would be: [corrected version]" 2) Answer their question clearly and helpfully in a natural, conversational way 3) End with an engaging follow-up question to encourage more speaking practice. Never use asterisks, bullet points, formatting, or numbered lists. Speak naturally as if talking face-to-face. Keep responses conversational and 80-100 words total.' },
          { role: 'user', content: message }
        ],
        max_tokens: 300,
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
    console.error('Chat API Error:', err.response?.data || err.message);
    console.error('Full error details:', err.response?.status, err.response?.statusText);
    
    // Always provide intelligent demo responses instead of generic fallbacks
    const lowerMessage = message.toLowerCase();
    let demoResponse;
    
    // Provide contextual responses based on the actual message content
    if (lowerMessage.includes('pickleball')) {
      demoResponse = "Great question! A better way to phrase this would be: 'I need to keep practicing pickleball. I want to become a stronger player. Are there any exercises I can follow?' Pickleball is such a fun sport! To get stronger, focus on footwork drills, paddle control exercises, and core strengthening. Regular practice with varied opponents also helps tremendously. What specific aspect of your pickleball game would you most like to improve - your serve, volleys, or court positioning?";
    } else if (lowerMessage.includes('hello') || lowerMessage.includes('hi')) {
      demoResponse = "Hello there! It's so nice to meet you! I'm here to be your English conversation partner and help you practice speaking naturally. I love chatting about anything and everything. What's something interesting that happened to you today, or is there a particular topic you'd like to talk about?";
    } else if (lowerMessage.includes('grammar')) {
      demoResponse = "That's fantastic that you want to work on grammar! Grammar is like the foundation of a house - it helps everything else make sense. I'm here to help you practice in a natural way through our conversations. What kind of grammar questions do you have, or would you like to try describing something and I'll help you polish it up?";
    } else if (lowerMessage.includes('vocabulary') || lowerMessage.includes('words')) {
      demoResponse = "I love helping with vocabulary! New words are like collecting treasures - each one opens up new ways to express yourself. The best way to learn them is by using them in real conversations like we're having right now. Is there a specific topic you're interested in, or some words you've heard recently that you'd like to understand better?";
    } else if (lowerMessage.includes('help') || lowerMessage.includes('learn')) {
      demoResponse = "I'm absolutely delighted to help you with your English! Learning a language is such an exciting journey, and I'm here to make it fun and natural. We can chat about your hobbies, dreams, daily life, or anything that interests you. What would you like to start talking about today?";
    } else if (lowerMessage.includes('practice')) {
      demoResponse = "Great question! A better way to phrase this would be: 'I want to practice speaking English.' Practicing is the key to becoming fluent, and I'm so glad you're taking this step! The more we chat naturally like this, the more confident you'll become. Tell me, what motivated you to start learning English, or what's your favorite thing about the language so far?";
    } else {
      demoResponse = "That's really interesting! I love having natural conversations like this because it's exactly how you'll use English in real life. Every time you share something with me, you're building your confidence and fluency. What else would you like to chat about, or is there something specific about English that you're curious about?";
    }
    
    res.json({ reply: `[Demo Mode] ${demoResponse}` });
  }
});

// Grammar & Vocabulary suggestions endpoint
app.post('/suggestions', async (req, res) => {
  console.log('=== Suggestions API Called ===');
  console.log('Request method:', req.method);
  console.log('Request headers:', req.headers);
  console.log('Request body:', req.body);
  console.log('Request origin:', req.headers.origin);
  
  // Handle both 'text' and 'message' field names for compatibility
  const { text, message } = req.body;
  const inputText = text || message;
  
  console.log('Processing message:', inputText);
  
  // Check if we have valid input
  if (!inputText) {
    return res.status(400).json({ 
      error: 'No text provided. Please send either "text" or "message" field.' 
    });
  }
  
  // Check if API key is configured
  if (!OPENROUTER_API_KEY || OPENROUTER_API_KEY === 'your_api_key_here') {
    return res.status(500).json({ 
      error: 'AI service not configured. Please configure OpenRouter API key.' 
    });
  }

  console.log('Using OpenRouter API for intelligent suggestions');
  
  try {
    // Use OpenRouter API with specific prompt for comprehensive analysis
    const response = await axios.post(OPENROUTER_BASE_URL, {
      model: "deepseek/deepseek-chat-v3-0324:free",
      messages: [
        {
          role: "system",
          content: `You are an expert English teacher. Analyze the student's message and provide detailed feedback in exactly this JSON format (no markdown, no code blocks):
{
  "grammar_fix": "If there are grammar errors, list each error and correction clearly. If no errors: 'No grammar errors found.'",
  "better_versions": ["improved version 1 with better vocabulary", "improved version 2 with different structure", "improved version 3 with formal tone"],
  "vocabulary": [
    {"word": "relevant_word_1", "meaning": "clear definition", "example": "practical example sentence"},
    {"word": "relevant_word_2", "meaning": "clear definition", "example": "practical example sentence"},
    {"word": "relevant_word_3", "meaning": "clear definition", "example": "practical example sentence"}
  ]
}

Focus on:
- Grammar: Check for verb tenses, word order, prepositions, articles, subject-verb agreement
- Better versions: Provide natural, fluent alternatives with varied vocabulary and structures
- Vocabulary: Choose words that are relevant to the topic and useful for English learners`
        },
        {
          role: "user",
          content: `Please analyze this English text: "${inputText}"`
        }
      ],
      max_tokens: 800,
      temperature: 0.3
    }, {
      headers: {
        'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });

    const aiResponse = response.data.choices[0].message.content;
    console.log('AI Response received:', aiResponse);
    
    // Clean the response - remove any markdown formatting
    let cleanResponse = aiResponse.trim();
    if (cleanResponse.startsWith('```json')) {
      cleanResponse = cleanResponse.replace(/^```json\s*/, '').replace(/\s*```$/, '');
    } else if (cleanResponse.startsWith('```')) {
      cleanResponse = cleanResponse.replace(/^```\s*/, '').replace(/\s*```$/, '');
    }
    
    // Parse the JSON response
    try {
      const suggestions = JSON.parse(cleanResponse);
      console.log('Successfully parsed AI suggestions:', suggestions);
      
      // Validate the response structure
      if (!suggestions.grammar_fix || !suggestions.better_versions || !suggestions.vocabulary) {
        throw new Error('Invalid AI response structure');
      }
      
      res.setHeader('Content-Type', 'application/json');
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.status(200).json(suggestions);
      
    } catch (parseError) {
      console.error('Failed to parse AI response as JSON:', parseError);
      console.error('AI response was:', cleanResponse);
      
      return res.status(500).json({
        error: 'AI model returned invalid format. Please try again.',
        details: 'The AI response could not be parsed properly.'
      });
    }
    
  } catch (err) {
    console.error('OpenRouter API Error:', err.message);
    console.error('Full error:', err.response?.data || err);
    
    // Handle specific API errors
    if (err.response?.status === 429) {
      return res.status(429).json({
        error: 'AI model rate limit reached. Please try again in a few minutes.',
        details: 'The free AI service has reached its usage limit.'
      });
    } else if (err.response?.status === 402) {
      return res.status(402).json({
        error: 'AI model quota exceeded. Service requires payment.',
        details: 'The AI service quota has been exhausted.'
      });
    } else if (err.code === 'ECONNABORTED' || err.message.includes('timeout')) {
      return res.status(504).json({
        error: 'AI model request timeout. Please try again.',
        details: 'The AI service took too long to respond.'
      });
    } else {
      return res.status(500).json({
        error: 'AI service temporarily unavailable. Please try again later.',
        details: err.response?.data?.error?.message || err.message
      });
    }
  }
});

// Grammar correction endpoint
app.post('/grammar', async (req, res) => {
  const { sentence } = req.body;
  
  // Check if API key is configured
  if (!OPENROUTER_API_KEY || OPENROUTER_API_KEY === 'your_api_key_here') {
    // Simple grammar correction for demo
    let corrected = sentence;
    
    // Basic corrections for common errors
    corrected = corrected.replace(/\bi\b/g, 'I');
    corrected = corrected.replace(/their is/gi, 'there is');
    corrected = corrected.replace(/alot/gi, 'a lot');
    corrected = corrected.replace(/\bwont\b/gi, 'won\'t');
    corrected = corrected.replace(/\bdont\b/gi, 'don\'t');
    
    return res.json({ correction: `[Demo Mode] ${corrected}` });
  }
  
  try {
    const response = await axios.post(
      OPENROUTER_BASE_URL,
      {
        model: 'deepseek/deepseek-chat-v3-0324:free',
        messages: [
          { role: 'system', content: 'You are a grammar teacher. Correct the given text and briefly explain any errors.' },
          { role: 'user', content: sentence }
        ],
        max_tokens: 300,
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
    console.error('Grammar API Error:', err.message);
    
    // Provide demo grammar correction
    let corrected = sentence;
    let explanation = "";
    
    // Common grammar corrections
    if (sentence.includes(' are ') && (sentence.includes('I ') || sentence.includes('He ') || sentence.includes('She '))) {
      corrected = sentence.replace(/I are/gi, 'I am').replace(/He are/gi, 'He is').replace(/She are/gi, 'She is');
      explanation = " (Corrected subject-verb agreement)";
    } else if (sentence.includes('their is')) {
      corrected = sentence.replace(/their is/gi, 'there is');
      explanation = " (Changed 'their' to 'there')";
    } else if (sentence.includes('alot')) {
      corrected = sentence.replace(/alot/gi, 'a lot');
      explanation = " ('A lot' should be two words)";
    } else {
      // Basic capitalization
      corrected = sentence.replace(/\bi\b/g, 'I');
      if (corrected !== sentence) {
        explanation = " (Capitalized 'I')";
      }
    }
    
    res.json({ correction: `[Demo Mode] ${corrected}${explanation}` });
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
        model: 'deepseek/deepseek-chat-v3-0324:free',
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
