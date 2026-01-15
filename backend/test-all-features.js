const axios = require('axios');

const API_URL = 'https://api.siteledger.ai/api';

async function testAllFeatures() {
  console.log('Testing SiteLedger API endpoints...\n');
  
  // Test 1: Health check
  try {
    const health = await axios.get('https://api.siteledger.ai/health');
    console.log('✅ Health check:', health.data);
  } catch (error) {
    console.log('❌ Health check failed:', error.message);
  }
  
  // Test 2: Use pre-generated token
  const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIyOGYxYzRiNi04Yzg1LTQ3NTEtYmFhMy1lYmU0YTFkMDMwMTMiLCJpYXQiOjE3NjY5NjA1OTksImV4cCI6MTc2Njk2NDE5OX0.9X7pE23Mz4V_5Vl8_wHBjejrUCCa9DLZX8Vuenno1UU';
  console.log('✅ Using test token for authentication\n');
  
  const headers = { Authorization: `Bearer ${token}` };
  
  // Test 3: Get jobs
  let jobId;
  try {
    const jobs = await axios.get(`${API_URL}/jobs`, { headers });
    console.log(`✅ Get jobs: ${jobs.data.length} jobs found`);
    if (jobs.data.length > 0) {
      jobId = jobs.data[0].id;
      console.log(`   First job ID: ${jobId}\n`);
    }
  } catch (error) {
    console.log('❌ Get jobs failed:', error.response?.data || error.message, '\n');
  }
  
  // Test 4: AI Insights (general)
  try {
    console.log('Testing general AI insights...');
    const insights = await axios.post(`${API_URL}/ai-insights`, {}, { headers, timeout: 35000 });
    console.log('✅ General AI insights:', insights.data.insights?.length || 0, 'insights generated\n');
  } catch (error) {
    console.log('❌ General AI insights failed:', error.response?.data?.error || error.message, '\n');
  }
  
  // Test 5: AI Insights (job-specific)
  if (jobId) {
    try {
      console.log(`Testing job-specific AI insights for job ${jobId}...`);
      const jobInsights = await axios.post(`${API_URL}/ai-insights/job/${jobId}`, {}, { headers, timeout: 35000 });
      console.log('✅ Job AI insights:', jobInsights.data.insights?.length || 0, 'insights generated\n');
    } catch (error) {
      console.log('❌ Job AI insights failed:', error.response?.data?.error || error.message, '\n');
    }
  }
  
  // Test 6: Receipt creation
  try {
    console.log('Testing receipt creation...');
    const receipt = await axios.post(`${API_URL}/receipts`, {
      vendor: 'Test Vendor',
      amount: 100.50,
      date: '2025-12-28',
      category: 'materials',
      notes: 'Test receipt'
    }, { headers });
    console.log('✅ Receipt created:', receipt.data.id, '\n');
  } catch (error) {
    console.log('❌ Receipt creation failed:', error.response?.data || error.message, '\n');
  }
  
  // Test 7: Worker creation
  try {
    console.log('Testing worker creation...');
    const worker = await axios.post(`${API_URL}/workers`, {
      email: `test_worker_${Date.now()}@example.com`,
      name: 'Test Worker',
      hourlyRate: 25
    }, { headers });
    console.log('✅ Worker created:', worker.data.id, '\n');
  } catch (error) {
    console.log('❌ Worker creation failed:', error.response?.data || error.message, '\n');
  }
  
  // Test 8: Settings - AI automation
  try {
    console.log('Testing settings update (AI automation)...');
    const settings = await axios.put(`${API_URL}/preferences/ai-automation`, {
      automationLevel: 'full',
      autoGenerateInsights: true
    }, { headers });
    console.log('✅ Settings updated:', settings.data, '\n');
  } catch (error) {
    console.log('❌ Settings update failed:', error.response?.data || error.message, '\n');
  }
  
  // Test 9: Settings - Theme
  try {
    console.log('Testing settings update (theme)...');
    const theme = await axios.put(`${API_URL}/preferences/theme`, {
      theme: 'dark'
    }, { headers });
    console.log('✅ Theme updated:', theme.data, '\n');
  } catch (error) {
    console.log('❌ Theme update failed:', error.response?.data || error.message, '\n');
  }
  
  console.log('\nTesting complete!');
}

testAllFeatures().catch(console.error);
