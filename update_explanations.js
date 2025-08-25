const axios = require('axios');

const baseURL = 'http://localhost:3000';

// Complete explanations for all grammar topics
const allExplanations = {
  // Grammar Foundations
  'present_simple': {
    explanation: 'The present simple tense is used to express general facts, habits, and routines. It describes actions that happen regularly or states that are generally true. Form: Subject + base verb (+ s for third person singular).',
    examples: [
      'I work in an office every day. (routine)',
      'She plays tennis on weekends. (habit)', 
      'The sun rises in the east. (general truth)',
      'Water boils at 100°C. (scientific fact)',
      'He speaks three languages. (ability/state)'
    ]
  },
  
  'articles': {
    explanation: 'Articles (a, an, the) are used before nouns to specify whether we are talking about something specific or general. "A/an" are indefinite articles for non-specific items. "The" is the definite article for specific items. Use "an" before vowel sounds.',
    examples: [
      'I need a pen. (any pen)',
      'Can you pass me the salt? (specific salt on table)',
      'She is an engineer. (profession)',
      'The book you recommended was excellent. (specific book)',
      'I saw an elephant at the zoo. (vowel sound)'
    ]
  },
  
  'plural_nouns': {
    explanation: 'Plural nouns indicate more than one person, place, or thing. Regular plurals add -s or -es. Irregular plurals have special forms like child→children, man→men, foot→feet. Some nouns are the same in singular and plural (sheep, fish).',
    examples: [
      'Regular: cat → cats, box → boxes',
      'Irregular: child → children, mouse → mice',
      'Same form: one sheep → two sheep',
      'Y to I: baby → babies, city → cities',
      'F to V: leaf → leaves, knife → knives'
    ]
  },
  
  'pronouns': {
    explanation: 'Personal pronouns replace nouns to avoid repetition. Subject pronouns (I, you, he, she, it, we, they) perform actions. Object pronouns (me, you, him, her, it, us, them) receive actions. Possessive pronouns show ownership.',
    examples: [
      'Subject: I like coffee. They are students.',
      'Object: Call me later. I saw them yesterday.',
      'Possessive: This is my book. The house is ours.',
      'Reflexive: I did it myself. They helped themselves.',
      'Demonstrative: This is good. Those are expensive.'
    ]
  },

  // Elementary Grammar
  'past_simple': {
    explanation: 'The past simple tense describes completed actions in the past, past habits, or a series of completed actions. Form: Subject + past form of verb (regular: verb + ed, irregular: specific forms). Use specific time expressions.',
    examples: [
      'I visited Paris last year. (completed action)',
      'She worked there for five years. (completed period)',
      'He ate, showered, and left. (sequence of actions)',
      'They were happy yesterday. (past state)',
      'We didn\'t see the movie. (negative past)'
    ]
  },
  
  'future_simple': {
    explanation: 'Future simple with "will" expresses future predictions, promises, spontaneous decisions, and offers. Form: Subject + will + base verb. Use "won\'t" for negatives. Often used with time expressions like tomorrow, next week.',
    examples: [
      'I will call you tomorrow. (future plan)',
      'It will rain later. (prediction)',
      'I\'ll help you with that. (spontaneous offer)',
      'She won\'t be late. (negative future)',
      'Will you come to the party? (future question)'
    ]
  },
  
  'prepositions': {
    explanation: 'Prepositions show relationships between words, indicating time, place, direction, or manner. Common prepositions include: in, on, at, by, with, for, from, to, under, over. The choice often depends on specific contexts and fixed expressions.',
    examples: [
      'Time: at 3 PM, on Monday, in July',
      'Place: at home, on the table, in the room',
      'Direction: to school, from work, into the house',
      'Method: by car, with a knife, on foot',
      'Purpose: for you, to help, in order to'
    ]
  },

  // Intermediate Grammar  
  'present_perfect': {
    explanation: 'Present perfect connects past actions to the present moment. Use it for: experiences (ever/never), unfinished time periods, recent past with present relevance. Form: have/has + past participle. Often used with since, for, already, yet, just.',
    examples: [
      'I have visited Japan twice. (life experience)',
      'She has worked here since 2020. (continues now)',
      'They have just arrived. (recent past)',
      'Have you finished your homework yet? (up to now)',
      'We haven\'t seen him recently. (recent time period)'
    ]
  },
  
  'past_continuous': {
    explanation: 'Past continuous describes ongoing actions in the past, often interrupted by another action. Also used for temporary situations in the past. Form: was/were + verb-ing. Often combined with past simple.',
    examples: [
      'I was reading when you called. (interrupted action)',
      'They were living in Paris last year. (temporary past)',
      'While she was cooking, he was watching TV. (simultaneous actions)',
      'It was raining all morning. (duration in past)',
      'What were you doing at 8 PM? (specific past time)'
    ]
  },
  
  'comparatives_superlatives': {
    explanation: 'Comparatives compare two things. Superlatives describe the extreme among three or more. Short adjectives: add -er/-est. Long adjectives: use more/most. Irregular forms: good→better→best, bad→worse→worst.',
    examples: [
      'Comparative: taller than, more interesting than',
      'Superlative: the tallest, the most interesting',
      'Irregular: better than, the best in class',
      'Equal comparison: as tall as, not as big as',
      'Different: less expensive, the least popular'
    ]
  },
  
  'modal_verbs': {
    explanation: 'Modal verbs express ability, possibility, permission, obligation, and advice. They don\'t change form and are followed by base verbs. Common modals: can, could, may, might, must, should, will, would.',
    examples: [
      'Ability: I can swim. I could run fast when young.',
      'Permission: May I leave? You can go now.',
      'Possibility: It might rain. That could be true.',
      'Obligation: You must wear a seatbelt.',
      'Advice: You should see a doctor.'
    ]
  },

  // Upper-Intermediate Grammar
  'perfect_continuous': {
    explanation: 'Perfect continuous tenses combine perfect and continuous aspects, emphasizing duration and connection to another time. Present perfect continuous: ongoing actions from past to now. Past perfect continuous: ongoing actions before a past time.',
    examples: [
      'Present: I have been working here for 5 years.',
      'Past: She had been waiting for an hour when he arrived.',
      'Future: By tomorrow, I will have been studying for 10 hours.',
      'Emphasis on duration: How long have you been learning English?',
      'Recent activity: You\'ve been working hard lately.'
    ]
  },
  
  'relative_clauses': {
    explanation: 'Relative clauses provide additional information about nouns using relative pronouns: who (people), which (things), that (people/things), where (places), when (time), whose (possession). Defining clauses are essential; non-defining clauses add extra information.',
    examples: [
      'Defining: The man who called is my brother.',
      'Non-defining: My car, which is red, needs repair.',
      'Object: The book that you lent me was great.',
      'Place: The place where we met is closed.',
      'Possession: The woman whose bag was stolen called police.'
    ]
  },
  
  'gerunds_infinitives': {
    explanation: 'Gerunds (-ing forms) and infinitives (to + base verb) can function as nouns. Some verbs are followed by gerunds (enjoy, avoid), others by infinitives (want, decide), and some by both with different meanings (remember, stop).',
    examples: [
      'Gerund after verb: I enjoy reading books.',
      'Infinitive after verb: I want to travel.',
      'Different meanings: I stopped smoking (quit) vs I stopped to smoke (purpose)',
      'Subject: Swimming is good exercise.',
      'Object: I like to dance and dancing.'
    ]
  },

  // Advanced Grammar
  'conditionals': {
    explanation: 'Conditionals express hypothetical situations. Zero: general truths (if + present, present). First: real future possibilities (if + present, will). Second: unreal present (if + past, would). Third: unreal past (if + past perfect, would have).',
    examples: [
      'Zero: If you heat water to 100°C, it boils.',
      'First: If it rains tomorrow, we will stay home.',
      'Second: If I were rich, I would travel the world.',
      'Third: If I had studied harder, I would have passed.',
      'Mixed: If I were you, I would have accepted the job.'
    ]
  },
  
  'passive_voice': {
    explanation: 'Passive voice emphasizes the action or result rather than the performer. Form: object + be + past participle (+ by + agent). Use when the doer is unknown, unimportant, obvious, or when emphasizing the action/result.',
    examples: [
      'Simple: The letter was sent yesterday.',
      'Continuous: The house is being painted.',
      'Perfect: The work has been completed.',
      'Modal: This should be done immediately.',
      'Unknown doer: My bike was stolen last night.'
    ]
  },
  
  'reported_speech': {
    explanation: 'Reported speech tells what someone said without using exact words. Change tense (usually back one step), pronouns, and time/place expressions. Use reporting verbs: say, tell, ask, explain, suggest.',
    examples: [
      'Statement: "I am tired" → She said she was tired.',
      'Question: "Where do you live?" → He asked where I lived.',
      'Command: "Close the door!" → He told me to close the door.',
      'Time change: "tomorrow" → the next day, "yesterday" → the day before',
      'No tense change with universal truths or recent speech.'
    ]
  },
  
  'subjunctive_mood': {
    explanation: 'Subjunctive mood expresses hypothetical, formal, or unreal situations. Common in formal requests, suggestions, and after certain expressions. Often uses base form of verb regardless of subject.',
    examples: [
      'Suggestion: I suggest that he leave early.',
      'Formal: It is important that she be on time.',
      'Wish: I wish I were taller.',
      'If only: If only it were summer!',
      'Fixed expressions: God save the Queen! Long live the king!'
    ]
  },

  // Business English Grammar
  'formal_language': {
    explanation: 'Formal language structures are used in professional and academic contexts. Features include: complex sentences, passive voice, formal vocabulary, indirect language, and specific phrases for politeness and clarity.',
    examples: [
      'Polite requests: Would you be so kind as to...',
      'Formal openings: I am writing to inquire about...',
      'Professional closings: I look forward to hearing from you.',
      'Passive voice: The matter will be addressed promptly.',
      'Conditional politeness: I would appreciate if you could...'
    ]
  },
  
  'email_structure': {
    explanation: 'Professional email grammar follows specific patterns: formal greetings, clear subject lines, structured paragraphs, appropriate tone, and professional closings. Use formal language for business correspondence.',
    examples: [
      'Subject: Re: Meeting Request for Project Discussion',
      'Opening: Dear Mr. Smith, / Good morning,',
      'Purpose: I am writing to follow up on...',
      'Request: Could you please provide...',
      'Closing: Best regards, / Sincerely,'
    ]
  },

  // Academic English Grammar
  'complex_sentences': {
    explanation: 'Complex sentences contain independent and dependent clauses connected by subordinating conjunctions (because, although, since, while). Used in academic writing for sophisticated arguments and detailed explanations.',
    examples: [
      'Cause: The experiment failed because the temperature was too high.',
      'Contrast: Although it was expensive, the investment proved worthwhile.',
      'Time: While the data shows improvement, further research is needed.',
      'Condition: Provided that funding is secured, the project will proceed.',
      'Relative: The theory, which was proposed in 1990, remains controversial.'
    ]
  }
};

async function updateAllExplanations() {
  console.log('🚀 Updating explanations for ALL grammar topics...');
  
  try {
    const topicIds = Object.keys(allExplanations);
    let updated = 0;
    let failed = 0;
    
    for (const topicId of topicIds) {
      try {
        const data = allExplanations[topicId];
        
        // First check if topic exists
        const checkResponse = await axios.get(`${baseURL}/grammar/topics/${topicId}/explanation`);
        
        if (checkResponse.status === 200) {
          // Update the topic with explanation and examples
          const updateResponse = await axios.put(`${baseURL}/grammar/topics/${topicId}`, {
            explanation: data.explanation,
            examples: JSON.stringify(data.examples)
          });
          
          console.log(`✅ Updated ${topicId}`);
          updated++;
        }
      } catch (error) {
        if (error.response?.status === 404) {
          console.log(`⚠️  Topic ${topicId} not found in database`);
        } else {
          console.log(`❌ Failed to update ${topicId}:`, error.message);
        }
        failed++;
      }
    }
    
    console.log(`\n📊 Update Summary:`);
    console.log(`✅ Successfully updated: ${updated} topics`);
    console.log(`❌ Failed/Not found: ${failed} topics`);
    
    // Verify by checking a few topics
    console.log('\n🔍 Verification - checking sample topics:');
    const sampleTopics = ['present_simple', 'articles', 'plural_nouns'];
    
    for (const topicId of sampleTopics) {
      try {
        const response = await axios.get(`${baseURL}/grammar/topics/${topicId}/explanation`);
        const hasExplanation = response.data.explanation ? '✅' : '❌';
        const hasExamples = response.data.examples?.length > 0 ? '✅' : '❌';
        console.log(`${topicId}: Explanation ${hasExplanation}, Examples ${hasExamples}`);
      } catch (error) {
        console.log(`${topicId}: ❌ Error checking`);
      }
    }
    
  } catch (error) {
    console.error('❌ Error during explanation update:', error.message);
  }
}

// Manual update using direct database query since PUT endpoint might not exist
async function updateExplanationsDirectly() {
  console.log('🚀 Updating explanations using direct database approach...');
  
  try {
    const updates = [];
    
    for (const [topicId, data] of Object.entries(allExplanations)) {
      updates.push({
        id: topicId,
        explanation: data.explanation,
        examples: data.examples
      });
    }
    
    // Send batch update request
    const response = await axios.post(`${baseURL}/admin/batch-update-explanations`, {
      updates: updates
    });
    
    console.log('✅ Batch update response:', response.data);
    
  } catch (error) {
    console.error('❌ Batch update failed:', error.response?.data || error.message);
    
    // Fallback: try individual updates
    console.log('🔄 Trying individual updates as fallback...');
    await updateAllExplanations();
  }
}

// Run the explanation updates
updateExplanationsDirectly();
