#!/usr/bin/env node

/**
 * Test script for AI Insights generation
 * Usage: node test-ai-insights.js
 */

const axios = require('axios');

const OLLAMA_BASE_URL = process.env.OLLAMA_BASE_URL || 'http://127.0.0.1:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || 'qwen2.5:1.5b';

async function testOllamaHealth() {
  console.log('\n=== Testing Ollama Health ===');
  try {
    const response = await axios.get(`${OLLAMA_BASE_URL}/api/tags`, {
      timeout: 5000,
    });
    console.log('✅ Ollama is running');
    console.log(`   Models available: ${response.data.models.map(m => m.name).join(', ')}`);
    return true;
  } catch (error) {
    console.error('❌ Ollama health check failed:', error.message);
    return false;
  }
}

async function testSimpleGeneration() {
  console.log('\n=== Testing Simple Generation ===');
  const startTime = Date.now();

  try {
    const response = await axios.post(
      `${OLLAMA_BASE_URL}/api/chat`,
      {
        model: OLLAMA_MODEL,
        messages: [
          {
            role: 'user',
            content: 'Say "Hello from Ollama" in exactly 5 words.',
          },
        ],
        stream: false,
      },
      {
        headers: {
          'Content-Type': 'application/json',
        },
        timeout: 30000,
      }
    );

    const duration = Date.now() - startTime;
    console.log(`✅ Simple generation succeeded in ${duration}ms`);
    console.log(`   Response: ${response.data.message.content}`);
    return true;
  } catch (error) {
    const duration = Date.now() - startTime;
    console.error(`❌ Simple generation failed after ${duration}ms`);
    console.error(`   Error: ${error.message}`);
    if (error.code === 'ECONNABORTED') {
      console.error('   ⚠️  Request timed out');
    }
    return false;
  }
}

async function testInsightsGeneration() {
  console.log('\n=== Testing Business Insights Generation ===');
  const startTime = Date.now();

  const prompt = `Analyze these construction business metrics and respond ONLY with valid JSON:

Jobs: 5 total (3 active, 2 done)
Revenue: $50000, Paid: $30000
Labor: 200 hrs @ $25/hr = $5000
Materials: $10000
Profit: $35000 (70% margin)

Return JSON with 3-5 insights:
{
  "insights": [
    {"title": "Short title", "description": "Brief detail", "severity": "info", "actionItems": ["Action 1"]}
  ],
  "summary": "1-2 sentence summary"
}`;

  try {
    const response = await axios.post(
      `${OLLAMA_BASE_URL}/api/chat`,
      {
        model: OLLAMA_MODEL,
        messages: [
          {
            role: 'system',
            content: 'You are a business analyst. Respond only with valid JSON.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        stream: false,
      },
      {
        headers: {
          'Content-Type': 'application/json',
        },
        timeout: 120000, // 2 minutes
      }
    );

    const duration = Date.now() - startTime;
    const content = response.data.message.content;

    console.log(`✅ Insights generation succeeded in ${duration}ms`);
    console.log(`   Response length: ${content.length} characters`);

    // Try to parse JSON
    try {
      // Extract JSON from response (handle markdown code blocks)
      let jsonContent = content;
      const jsonMatch = content.match(/```(?:json)?\s*(\{[\s\S]*\})\s*```/);
      if (jsonMatch) {
        jsonContent = jsonMatch[1];
        console.log('   ℹ️  Extracted JSON from markdown code block');
      }

      const parsed = JSON.parse(jsonContent);
      console.log('   ✅ Response is valid JSON');
      console.log(`   Insights count: ${parsed.insights?.length || 0}`);
      console.log(`   Has summary: ${!!parsed.summary}`);

      if (parsed.insights && parsed.insights.length > 0) {
        console.log('\n   Sample insight:');
        console.log(`   - Title: ${parsed.insights[0].title}`);
        console.log(`   - Severity: ${parsed.insights[0].severity}`);
      }

      return true;
    } catch (parseError) {
      console.warn('   ⚠️  Response is not valid JSON');
      console.log('   Raw response preview:', content.substring(0, 200));
      return false;
    }
  } catch (error) {
    const duration = Date.now() - startTime;
    console.error(`❌ Insights generation failed after ${duration}ms`);
    console.error(`   Error: ${error.message}`);

    if (error.code === 'ECONNABORTED') {
      console.error('   ⚠️  Request timed out (exceeded 120s)');
      console.error('   💡 Model may need more memory or use a smaller model');
    }

    return false;
  }
}

async function checkSystemResources() {
  console.log('\n=== System Resources ===');
  try {
    const { execSync } = require('child_process');

    // Memory info
    const memInfo = execSync('free -h').toString();
    console.log('Memory usage:');
    console.log(memInfo);

    // Swap info
    const swapInfo = execSync('swapon --show 2>/dev/null || echo "No swap"').toString();
    console.log('Swap:');
    console.log(swapInfo);

    // Load average
    const loadAvg = execSync('uptime').toString().trim();
    console.log('Load:', loadAvg);

  } catch (error) {
    console.log('Could not fetch system resources (may not be on server)');
  }
}

async function main() {
  console.log('╔═══════════════════════════════════════════════════╗');
  console.log('║     SiteLedger AI Insights Test Suite            ║');
  console.log('╚═══════════════════════════════════════════════════╝');
  console.log(`\nOllama URL: ${OLLAMA_BASE_URL}`);
  console.log(`Model: ${OLLAMA_MODEL}`);

  // Run tests
  const healthOk = await testOllamaHealth();
  if (!healthOk) {
    console.log('\n❌ Cannot proceed - Ollama is not responding');
    process.exit(1);
  }

  await checkSystemResources();
  await testSimpleGeneration();
  await testInsightsGeneration();

  console.log('\n╔═══════════════════════════════════════════════════╗');
  console.log('║                Test Suite Complete                ║');
  console.log('╚═══════════════════════════════════════════════════╝\n');
}

main().catch(error => {
  console.error('\n💥 Fatal error:', error);
  process.exit(1);
});
