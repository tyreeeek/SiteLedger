/**
 * Test all backend endpoints to verify they're working
 * Run with: node test-all-endpoints.js <your-auth-token>
 */

const axios = require('axios');

const API_BASE = 'https://api.siteledger.ai/api';
const AUTH_TOKEN = process.argv[2];

if (!AUTH_TOKEN) {
  console.error('❌ Please provide auth token: node test-all-endpoints.js <token>');
  process.exit(1);
}

const api = axios.create({
  baseURL: API_BASE,
  headers: {
    'Authorization': `Bearer ${AUTH_TOKEN}`,
    'Content-Type': 'application/json'
  }
});

async function testEndpoints() {
  console.log('🧪 Testing SiteLedger API Endpoints\n');
  
  // Test 1: AI Insights
  try {
    console.log('1️⃣ Testing AI Insights...');
    const insights = await api.post('/ai-insights');
    console.log('✅ AI Insights: SUCCESS');
    console.log('   Generated insights:', insights.data.insights?.length || 0, 'items');
  } catch (error) {
    console.log('❌ AI Insights: FAILED');
    console.log('   Error:', error.response?.data?.error || error.message);
  }
  
  // Test 2: Get Jobs (needed for other tests)
  let testJobId = null;
  try {
    console.log('\n2️⃣ Testing Jobs endpoint...');
    const jobs = await api.get('/jobs');
    console.log('✅ Jobs: SUCCESS');
    console.log('   Found', jobs.data.length, 'jobs');
    testJobId = jobs.data[0]?.id;
  } catch (error) {
    console.log('❌ Jobs: FAILED');
    console.log('   Error:', error.response?.data?.error || error.message);
  }
  
  // Test 3: Get Receipts
  try {
    console.log('\n3️⃣ Testing Receipts endpoint...');
    const receipts = await api.get('/receipts');
    console.log('✅ Receipts: SUCCESS');
    console.log('   Found', receipts.data.length, 'receipts');
  } catch (error) {
    console.log('❌ Receipts: FAILED');
    console.log('   Error:', error.response?.data?.error || error.message);
  }
  
  // Test 4: Get Documents
  try {
    console.log('\n4️⃣ Testing Documents endpoint...');
    const documents = await api.get('/documents');
    console.log('✅ Documents: SUCCESS');
    console.log('   Found', documents.data.length, 'documents');
  } catch (error) {
    console.log('❌ Documents: FAILED');
    console.log('   Error:', error.response?.data?.error || error.message);
  }
  
  // Test 5: Get Workers
  try {
    console.log('\n5️⃣ Testing Workers endpoint...');
    const workers = await api.get('/workers');
    console.log('✅ Workers: SUCCESS');
    console.log('   Found', workers.data.length, 'workers');
  } catch (error) {
    console.log('❌ Workers: FAILED');
    console.log('   Error:', error.response?.data?.error || error.message);
  }
  
  // Test 6: Get AI Automation Settings
  try {
    console.log('\n6️⃣ Testing AI Automation Settings...');
    const settings = await api.get('/preferences/ai-automation');
    console.log('✅ AI Automation Settings: SUCCESS');
    console.log('   Automation level:', settings.data.automationLevel || 'not set');
  } catch (error) {
    console.log('❌ AI Automation Settings: FAILED');
    console.log('   Error:', error.response?.data?.error || error.message);
  }
  
  // Test 7: Get Notification Preferences
  try {
    console.log('\n7️⃣ Testing Notification Preferences...');
    const prefs = await api.get('/preferences/notifications');
    console.log('✅ Notification Preferences: SUCCESS');
    console.log('   Email notifications:', prefs.data.emailNotifications !== undefined ? 'configured' : 'not set');
  } catch (error) {
    console.log('❌ Notification Preferences: FAILED');
    console.log('   Error:', error.response?.data?.error || error.message);
  }
  
  // Test 8: Job-specific AI insights
  if (testJobId) {
    try {
      console.log('\n8️⃣ Testing Job-specific AI Insights...');
      const jobInsights = await api.post(`/ai-insights/job/${testJobId}`);
      console.log('✅ Job AI Insights: SUCCESS');
      console.log('   Insights generated for job:', testJobId.substring(0, 8) + '...');
    } catch (error) {
      console.log('❌ Job AI Insights: FAILED');
      console.log('   Error:', error.response?.data?.error || error.message);
    }
  }
  
  console.log('\n✅ Testing complete!');
}

testEndpoints().catch(err => {
  console.error('\n❌ Fatal error:', err.message);
  process.exit(1);
});
