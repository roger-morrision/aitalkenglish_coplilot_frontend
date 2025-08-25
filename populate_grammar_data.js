const axios = require('axios');

const baseURL = 'http://localhost:3000';

async function populateGrammarData() {
  console.log('🚀 Starting grammar data population...');
  
  try {
    // 1. Update explanations for all topics
    console.log('📝 Updating grammar explanations...');
    const explanationsResponse = await axios.post(`${baseURL}/admin/update-grammar-explanations`);
    console.log('✅ Explanations updated:', explanationsResponse.data);
    
    // 2. Generate exercises for all topics
    console.log('💫 Generating exercises for all topics...');
    const exercisesResponse = await axios.post(`${baseURL}/admin/generate-exercises`);
    console.log('✅ Exercises generated:', exercisesResponse.data);
    
    // 3. Verify data by getting complete grammar structure
    console.log('🔍 Verifying complete grammar data...');
    const verifyResponse = await axios.get(`${baseURL}/grammar/complete`);
    const categories = verifyResponse.data.categories;
    
    console.log('\n📊 Grammar Data Summary:');
    console.log(`📁 Categories: ${categories.length}`);
    
    let totalTopics = 0;
    let totalExercises = 0;
    
    categories.forEach(category => {
      console.log(`\n📂 ${category.name}:`);
      console.log(`   📄 Topics: ${category.topics.length}`);
      totalTopics += category.topics.length;
      
      category.topics.forEach(topic => {
        console.log(`     ▶ ${topic.title}: ${topic.exercises.length} exercises`);
        totalExercises += topic.exercises.length;
      });
    });
    
    console.log(`\n🎯 Total Summary:`);
    console.log(`📁 Categories: ${categories.length}`);
    console.log(`📄 Topics: ${totalTopics}`);
    console.log(`💡 Exercises: ${totalExercises}`);
    
    console.log('\n🎉 Grammar data population completed successfully!');
    
  } catch (error) {
    console.error('❌ Error populating grammar data:');
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    } else if (error.request) {
      console.error('Request error:', error.request);
    } else {
      console.error('Error:', error.message);
    }
  }
}

// Run the population script
populateGrammarData();
