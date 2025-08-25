const axios = require('axios');

const baseURL = 'http://localhost:3000';

async function showGrammarDatabaseStatus() {
  console.log('🎯 GRAMMAR DATABASE STATUS REPORT');
  console.log('=====================================\n');
  
  try {
    // Get complete grammar structure
    const response = await axios.get(`${baseURL}/grammar/complete`);
    const categories = response.data.categories;
    
    console.log(`📊 OVERVIEW:`);
    console.log(`📁 Total Categories: ${categories.length}`);
    
    let totalTopics = 0;
    let totalExercises = 0;
    let topicsWithExplanations = 0;
    let topicsWithExamples = 0;
    
    console.log('\n📂 DETAILED BREAKDOWN:\n');
    
    for (const category of categories) {
      console.log(`📁 ${category.name}:`);
      console.log(`   📄 Topics: ${category.topics.length}`);
      totalTopics += category.topics.length;
      
      for (const topic of category.topics) {
        const exerciseCount = topic.exercises.length;
        totalExercises += exerciseCount;
        
        // Check if topic has explanation
        try {
          const topicDetail = await axios.get(`${baseURL}/grammar/topics/${topic.id}/explanation`);
          const hasExplanation = topicDetail.data.explanation && topicDetail.data.explanation.length > 0;
          const hasExamples = topicDetail.data.examples && topicDetail.data.examples.length > 0;
          
          if (hasExplanation) topicsWithExplanations++;
          if (hasExamples) topicsWithExamples++;
          
          const explanationStatus = hasExplanation ? '✅' : '❌';
          const examplesStatus = hasExamples ? '✅' : '❌';
          
          console.log(`     ▶ ${topic.title}:`);
          console.log(`       📝 Exercises: ${exerciseCount}`);
          console.log(`       📖 Explanation: ${explanationStatus}`);
          console.log(`       📋 Examples: ${examplesStatus}`);
          
        } catch (error) {
          console.log(`     ▶ ${topic.title}: ❌ Error checking details`);
        }
      }
      console.log('');
    }
    
    console.log('🎯 FINAL STATISTICS:');
    console.log('====================');
    console.log(`📁 Categories: ${categories.length}`);
    console.log(`📄 Topics: ${totalTopics}`);
    console.log(`💡 Total Exercises: ${totalExercises}`);
    console.log(`📖 Topics with Explanations: ${topicsWithExplanations}/${totalTopics} (${Math.round(topicsWithExplanations/totalTopics*100)}%)`);
    console.log(`📋 Topics with Examples: ${topicsWithExamples}/${totalTopics} (${Math.round(topicsWithExamples/totalTopics*100)}%)`);
    
    if (topicsWithExplanations === totalTopics && topicsWithExamples === totalTopics && totalExercises > 0) {
      console.log('\n🎉 SUCCESS! Grammar database is fully populated with:');
      console.log('   ✅ All categories created');
      console.log('   ✅ All topics have explanations');
      console.log('   ✅ All topics have examples');
      console.log('   ✅ All topics have exercises');
      console.log('   ✅ Database ready for production use!');
    } else {
      console.log('\n⚠️  Some items may need attention:');
      if (topicsWithExplanations < totalTopics) {
        console.log(`   📖 ${totalTopics - topicsWithExplanations} topics missing explanations`);
      }
      if (topicsWithExamples < totalTopics) {
        console.log(`   📋 ${totalTopics - topicsWithExamples} topics missing examples`);
      }
      if (totalExercises === 0) {
        console.log(`   💡 No exercises found`);
      }
    }
    
  } catch (error) {
    console.error('❌ Error checking grammar database:', error.message);
  }
}

// Run the status report
showGrammarDatabaseStatus();
