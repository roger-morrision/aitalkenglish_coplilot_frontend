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
  db.run('CREATE TABLE IF NOT EXISTS app_settings (id INTEGER PRIMARY KEY, setting_key TEXT UNIQUE, setting_value TEXT)');
  
  // Initialize default AI model setting
  db.run('INSERT OR IGNORE INTO app_settings (setting_key, setting_value) VALUES (?, ?)', 
    ['selected_ai_model', 'deepseek/deepseek-chat-v3-0324:free']);
});

// OpenAI setup
const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
const OPENROUTER_BASE_URL = 'https://openrouter.ai/api/v1/chat/completions';

// Available AI Models
const AVAILABLE_MODELS = [
  {
    id: 'deepseek/deepseek-chat-v3-0324:free',
    name: 'DeepSeek V3 (Free)',
    description: 'High-quality conversations and analysis',
    provider: 'DeepSeek',
    tier: 'Free'
  },
  {
    id: 'meta-llama/llama-3.2-3b-instruct:free',
    name: 'Llama 3.2 3B (Free)', 
    description: 'Fast responses with good quality',
    provider: 'Meta',
    tier: 'Free'
  },
  {
    id: 'microsoft/phi-3-mini-128k-instruct:free',
    name: 'Phi-3 Mini (Free)',
    description: 'Efficient small model for basic tasks',
    provider: 'Microsoft',
    tier: 'Free'
  },
  {
    id: 'google/gemma-2-9b-it:free',
    name: 'Gemma 2 9B (Free)',
    description: 'Google\'s open model with good performance',
    provider: 'Google',
    tier: 'Free'
  }
];

// Helper function to get selected AI model
async function getSelectedModel() {
  return new Promise((resolve, reject) => {
    db.get('SELECT setting_value FROM app_settings WHERE setting_key = ?', ['selected_ai_model'], (err, row) => {
      if (err) {
        console.error('Error getting selected model:', err);
        resolve('deepseek/deepseek-chat-v3-0324:free'); // Default fallback
      } else {
        resolve(row ? row.setting_value : 'deepseek/deepseek-chat-v3-0324:free');
      }
    });
  });
}

// App Settings endpoints
app.get('/settings/models', (req, res) => {
  res.json({
    available: AVAILABLE_MODELS,
    message: 'Available AI models for selection'
  });
});

app.get('/settings/current-model', (req, res) => {
  db.get('SELECT setting_value FROM app_settings WHERE setting_key = ?', ['selected_ai_model'], (err, row) => {
    if (err) return res.status(500).json({ error: err.message });
    
    const currentModelId = row ? row.setting_value : 'deepseek/deepseek-chat-v3-0324:free';
    const currentModel = AVAILABLE_MODELS.find(model => model.id === currentModelId);
    
    res.json({
      selected_model: currentModelId,
      model_info: currentModel || AVAILABLE_MODELS[0]
    });
  });
});

app.post('/settings/select-model', (req, res) => {
  const { model_id } = req.body;
  
  // Validate that the model exists in our available models
  const selectedModel = AVAILABLE_MODELS.find(model => model.id === model_id);
  if (!selectedModel) {
    return res.status(400).json({ 
      error: 'Invalid model selection',
      available_models: AVAILABLE_MODELS.map(m => m.id)
    });
  }
  
  db.run('INSERT OR REPLACE INTO app_settings (setting_key, setting_value) VALUES (?, ?)', 
    ['selected_ai_model', model_id], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    
    res.json({ 
      success: true,
      selected_model: model_id,
      model_info: selectedModel,
      message: `AI model updated to ${selectedModel.name}`
    });
  });
});

// Voice Settings endpoints
app.get('/settings/voice', (req, res) => {
  db.all('SELECT * FROM app_settings WHERE setting_key IN (?, ?)', 
    ['voice_autoplay_enabled', 'voice_input_enabled'], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    
    const settings = {
      voice_autoplay_enabled: true, // default values
      voice_input_enabled: true
    };
    
    rows.forEach(row => {
      settings[row.setting_key] = row.setting_value === 'true';
    });
    
    res.json({
      voice_autoplay_enabled: settings.voice_autoplay_enabled,
      voice_input_enabled: settings.voice_input_enabled,
      message: 'Voice settings retrieved successfully'
    });
  });
});

app.post('/settings/voice', (req, res) => {
  const { voice_autoplay_enabled, voice_input_enabled } = req.body;
  
  // Validate boolean values
  if (typeof voice_autoplay_enabled !== 'boolean' || typeof voice_input_enabled !== 'boolean') {
    return res.status(400).json({ error: 'Voice settings must be boolean values' });
  }
  
  // Update settings in database
  const stmt = db.prepare('INSERT OR REPLACE INTO app_settings (setting_key, setting_value) VALUES (?, ?)');
  
  stmt.run('voice_autoplay_enabled', voice_autoplay_enabled.toString());
  stmt.run('voice_input_enabled', voice_input_enabled.toString());
  stmt.finalize();
  
  res.json({
    success: true,
    voice_autoplay_enabled,
    voice_input_enabled,
    message: 'Voice settings updated successfully'
  });
});

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
    // Get the currently selected AI model
    const selectedModel = await getSelectedModel();
    console.log('Chat API using model:', selectedModel);
    
    // Use the same configuration as the working suggestions endpoint
    const response = await axios.post(
      OPENROUTER_BASE_URL,
      {
        model: selectedModel,
        messages: [
          { 
            role: 'system', 
            content: 'You are an English language learning tutor, NOT a general AI assistant. Your ONLY job is to help users practice and improve their English. Always stay focused on English learning topics. If users ask about other topics (like technology, science, etc.), gently redirect them back to English learning while still being helpful. \n\nWhen responding:\n1. If their English has errors, start with "A better way to say this would be: [corrected version]"\n2. Then engage with their topic in a natural, conversational way\n3. End with a follow-up question to encourage more English practice\n4. Keep responses 50-80 words\n5. Never discuss AI, language models, or technical topics - focus only on English learning\n\nBe encouraging, friendly, and always redirect conversations toward English practice.' 
          },
          { role: 'user', content: message }
        ],
        max_tokens: 300,
        temperature: 0.7
      },
      {
        headers: {
          'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
          'Content-Type': 'application/json',
        },
        timeout: 30000
      }
    );
    
    console.log('Chat API Success - AI Response:', response.data.choices[0].message.content);
    res.json({ reply: response.data.choices[0].message.content });
  } catch (err) {
    console.error('Chat API Error Details:');
    console.error('- Error message:', err.message);
    console.error('- Response status:', err.response?.status);
    console.error('- Response data:', err.response?.data);
    console.error('- Full error:', err);
    
    // Handle specific API errors with intelligent fallbacks
    if (err.response?.status === 429) {
      // Rate limit - provide intelligent contextual response
      const lowerMessage = message.toLowerCase();
      let contextualResponse;
      
      if (lowerMessage.includes('english') || lowerMessage.includes('learn')) {
        contextualResponse = "I'd love to help you with your English learning! The AI service is currently busy, but I can still chat with you. Your question about improving English naturally is great - practicing with real conversations like this is one of the best ways to improve. What specific area of English would you like to focus on right now?";
      } else if (lowerMessage.includes('speak') || lowerMessage.includes('speaking')) {
        contextualResponse = "Speaking practice is so important! Even though our AI service is temporarily busy, I can still help you practice. The key to natural speaking is regular conversation and not being afraid to make mistakes. What topics do you enjoy talking about most?";
      } else {
        contextualResponse = "I'm experiencing high demand right now, but I'm still here to chat! Your message is interesting and I'd love to continue our conversation. What would you like to explore further?";
      }
      
      return res.json({ reply: `[Temporary AI Limit] ${contextualResponse}` });
      
    } else if (err.response?.status === 402) {
      return res.json({ reply: "[AI Service Quota] I'm temporarily unable to access the full AI service, but I'm still here to help you practice English! Let's keep chatting - what would you like to talk about?" });
      
    } else if (err.code === 'ECONNABORTED' || err.message.includes('timeout')) {
      return res.json({ reply: "[Connection Timeout] The AI service is taking longer than usual to respond. While we wait, let's continue our conversation! What interesting things have you been learning lately?" });
      
    } else {
      // Provide intelligent contextual responses instead of generic fallbacks
      const lowerMessage = message.toLowerCase();
      let demoResponse;
      
      // Provide contextual responses based on the actual message content
      if (lowerMessage.includes('english') && lowerMessage.includes('natural')) {
        demoResponse = "A better way to say this would be: 'How can I speak English more naturally in a short time? Is talking with AI a better option, and which AI app is best suited?' Speaking English naturally comes from practice and exposure! Talking with AI can definitely help because you can practice anytime without feeling embarrassed. What specific situations do you want to feel more confident in when speaking English?";
      } else if (lowerMessage.includes('pickleball')) {
        demoResponse = "A better way to phrase this would be: 'I need to keep practicing pickleball. I want to become a stronger player. Are there any exercises I can follow?' Pickleball is such a fun sport! To get stronger, focus on footwork drills, paddle control exercises, and core strengthening. Regular practice with varied opponents also helps tremendously. What specific aspect of your pickleball game would you most like to improve?";
      } else if (lowerMessage.includes('hello') || lowerMessage.includes('hi')) {
        demoResponse = "Hello there! It's so nice to meet you! I'm here to be your English conversation partner and help you practice speaking naturally. I love chatting about anything and everything. What's something interesting that happened to you today, or is there a particular topic you'd like to talk about?";
      } else if (lowerMessage.includes('help') || lowerMessage.includes('learn')) {
        demoResponse = "I'm absolutely delighted to help you with your English! Learning a language is such an exciting journey, and I'm here to make it fun and natural. We can chat about your hobbies, dreams, daily life, or anything that interests you. What would you like to start talking about today?";
      } else {
        demoResponse = "That's really interesting! I love having natural conversations like this because it's exactly how you'll use English in real life. Every time you share something with me, you're building your confidence and fluency. What else would you like to chat about, or is there something specific about English that you're curious about?";
      }
      
      return res.json({ reply: `[Demo Mode] ${demoResponse}` });
    }
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
    // Get the currently selected AI model
    const selectedModel = await getSelectedModel();
    console.log('Suggestions API using model:', selectedModel);
    
    // Use the selected model for suggestions
    const response = await axios.post(OPENROUTER_BASE_URL, {
      model: selectedModel,
      messages: [
        {
          role: "system",
          content: `You are an English teacher. Analyze the student's message and provide feedback in JSON format ONLY.

IMPORTANT: Your response must be valid JSON with exactly this structure:

{
  "grammar_fix": "Describe grammar errors and corrections, or 'No grammar errors found'",
  "better_versions": ["improved version 1", "improved version 2", "improved version 3"],
  "vocabulary": [
    {"word": "word1", "meaning": "definition", "example": "example sentence"},
    {"word": "word2", "meaning": "definition", "example": "example sentence"}
  ]
}

DO NOT include any text before or after the JSON. DO NOT use markdown formatting. Return ONLY valid JSON.`
        },
        {
          role: "user",
          content: `Analyze: "${inputText}"`
        }
      ],
      max_tokens: 600,
      temperature: 0.3
    }, {
      headers: {
        'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });

    console.log('OpenRouter API Response Status:', response.status);
    console.log('OpenRouter API Response Data:', JSON.stringify(response.data, null, 2));
    
    if (!response.data || !response.data.choices || !response.data.choices[0]) {
      throw new Error('Invalid API response structure');
    }

    const aiResponse = response.data.choices[0].message.content;
    console.log('Suggestions API Success - AI Response:', aiResponse);
    
    // Clean the response - remove any markdown formatting
    let cleanResponse = aiResponse.trim();
    if (cleanResponse.startsWith('```json')) {
      cleanResponse = cleanResponse.replace(/^```json\s*/, '').replace(/\s*```$/, '');
    } else if (cleanResponse.startsWith('```')) {
      cleanResponse = cleanResponse.replace(/^```\s*/, '').replace(/\s*```$/, '');
    }
    
    // Handle case where AI returns text description instead of JSON
    if (!cleanResponse.startsWith('{') || !cleanResponse.endsWith('}')) {
      console.log('AI returned non-JSON response:', cleanResponse);
      
      // Extract meaningful information from the text response
      const grammarFix = cleanResponse.includes('error') && cleanResponse.includes('correction') 
        ? cleanResponse 
        : 'The AI provided feedback in an unexpected format. Please try again.';
      
      return res.status(200).json({
        grammar_fix: grammarFix,
        better_versions: [
          "Please try your message again for better suggestions.",
          "The AI analysis needs to be reformatted.",
          "Consider rephrasing your input for clearer feedback."
        ],
        vocabulary: [
          {
            word: "reformatted",
            meaning: "arranged in a different format",
            example: "The data was reformatted for better clarity."
          }
        ]
      });
    }
    
    // Parse the JSON response
    try {
      const suggestions = JSON.parse(cleanResponse);
      console.log('Successfully parsed AI suggestions:', suggestions);
      
      // Normalize the grammar_fix field to always be a string
      let grammarFix = '';
      if (Array.isArray(suggestions.grammar_fix)) {
        // Convert array of error objects to readable string
        grammarFix = suggestions.grammar_fix.map(item => {
          if (typeof item === 'object' && item.error && item.correction) {
            return `"${item.error}" should be "${item.correction}"`;
          }
          return item.toString();
        }).join('; ');
      } else if (typeof suggestions.grammar_fix === 'string') {
        grammarFix = suggestions.grammar_fix;
      } else {
        grammarFix = suggestions.grammar_fix?.toString() || 'No grammar errors found';
      }
      
      // Validate the response structure
      if (!suggestions.better_versions || !suggestions.vocabulary) {
        throw new Error('Invalid AI response structure');
      }
      
      const normalizedResponse = {
        grammar_fix: grammarFix,
        better_versions: suggestions.better_versions,
        vocabulary: suggestions.vocabulary
      };
      
      res.setHeader('Content-Type', 'application/json');
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.status(200).json(normalizedResponse);
      
    } catch (parseError) {
      console.error('Failed to parse AI response as JSON:', parseError);
      console.error('AI response was:', cleanResponse);
      
      // Try to extract useful information from the malformed response
      let grammarFix = 'Grammar analysis unavailable';
      let betterVersions = ['Please try rephrasing your message'];
      let vocabulary = [{
        word: 'retry',
        meaning: 'to try again',
        example: 'Please retry your request.'
      }];
      
      // Look for error/correction patterns in the response
      if (cleanResponse.includes('error') && cleanResponse.includes('correction')) {
        // Extract text between error and correction
        const match = cleanResponse.match(/error:?\s*([^,}]+).*correction:?\s*([^,}]+)/i);
        if (match) {
          const errorText = match[1].trim();
          const correctionText = match[2].trim();
          grammarFix = `Error: "${errorText}" should be "${correctionText}"`;
          betterVersions = [correctionText, `Try using: ${correctionText}`, `Correct form: ${correctionText}`];
        }
      }
      
      return res.status(200).json({
        grammar_fix: grammarFix,
        better_versions: betterVersions,
        vocabulary: vocabulary
      });
    }
    
  } catch (err) {
    console.error('Suggestions API Error Details:');
    console.error('- Error message:', err.message);
    console.error('- Response status:', err.response?.status);
    console.error('- Response data:', err.response?.data);
    console.error('- Full error:', err);
    
    // Handle specific API errors with intelligent fallbacks
    if (err.response?.status === 429) {
      return res.status(200).json({
        grammar_fix: "Rate limit reached - unable to check grammar right now",
        better_versions: [
          "The AI service is temporarily busy. Please try again in a moment.",
          "Your message was received successfully.",
          "Rate limit will reset shortly."
        ],
        vocabulary: [
          {
            word: "patience",
            meaning: "the ability to wait calmly",
            example: "Please have patience while the service recovers."
          }
        ]
      });
    } else if (err.response?.status === 402) {
      return res.status(200).json({
        grammar_fix: "AI service quota exceeded",
        better_versions: [
          "The AI analysis service has reached its daily limit.",
          "Basic conversation mode is still available.",
          "Suggestions will resume when quota resets."
        ],
        vocabulary: [
          {
            word: "quota",
            meaning: "a limited quantity of something",
            example: "The daily quota for API calls has been reached."
          }
        ]
      });
    } else if (err.code === 'ECONNABORTED' || err.message.includes('timeout')) {
      return res.status(200).json({
        grammar_fix: "Connection timeout - analysis unavailable",
        better_versions: [
          "The AI service is taking longer than usual to respond.",
          "Your conversation can continue without suggestions.",
          "Suggestions will work again when connection improves."
        ],
        vocabulary: [
          {
            word: "timeout",
            meaning: "when a process takes too long to complete",
            example: "The request failed due to a network timeout."
          }
        ]
      });
    } else {
      // Provide intelligent contextual suggestions as fallback
      const lowerMessage = inputText.toLowerCase();
      
      if (lowerMessage.includes('food') || lowerMessage.includes('meal')) {
        return res.status(200).json({
          grammar_fix: "Grammar help temporarily unavailable",
          better_versions: [
            "What foods should I eat for each meal to stay healthy?",
            "Which foods are best for maintaining good health?",
            "What dietary choices help keep the body youthful?"
          ],
          vocabulary: [
            {
              word: "nutrition",
              meaning: "the process of providing food necessary for health",
              example: "Good nutrition is essential for staying healthy."
            },
            {
              word: "balanced",
              meaning: "having different elements in correct proportions",
              example: "A balanced diet includes vegetables, proteins, and grains."
            }
          ]
        });
      } else {
        return res.status(200).json({
          grammar_fix: "AI suggestions temporarily unavailable",
          better_versions: [
            "Your message was understood clearly.",
            "Continue practicing - you're doing great!",
            "Suggestions will be available again soon."
          ],
          vocabulary: [
            {
              word: "practice",
              meaning: "to do something repeatedly to improve skill",
              example: "Regular practice helps improve English fluency."
            }
          ]
        });
      }
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
    // Get the currently selected AI model
    const selectedModel = await getSelectedModel();
    console.log('Grammar API using model:', selectedModel);
    
    const response = await axios.post(
      OPENROUTER_BASE_URL,
      {
        model: selectedModel,
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
