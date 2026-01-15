// AI Insights Generation Service
// Generates business insights using OpenRouter API with Meta Llama model

const axios = require('axios');
const logger = require('../config/logger');

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
const AI_MODEL_NAME = process.env.AI_MODEL_NAME || 'meta-llama/llama-3.3-70b-instruct:free';
const OPENAI_BASE_URL = process.env.OPENAI_BASE_URL || 'https://openrouter.ai/api/v1';

if (!OPENROUTER_API_KEY) {
  logger.error('OPENROUTER_API_KEY is not set in environment variables');
}

class AIInsightsService {
  /**
   * Generate business insights from job, receipt, and timesheet data
   */
  static async generateInsights(userId, jobs, receipts, timesheets) {
    try {
      if (!OPENROUTER_API_KEY) {
        throw new Error('OpenRouter API key is not configured');
      }

      // Calculate key metrics
      const totalJobs = jobs.length;
      const activeJobs = jobs.filter(j => j.status === 'active').length;
      const completedJobs = jobs.filter(j => j.status === 'completed').length;
      
      const totalRevenue = jobs.reduce((sum, j) => sum + parseFloat(j.project_value || 0), 0);
      const totalPaid = jobs.reduce((sum, j) => sum + parseFloat(j.amount_paid || 0), 0);
      const outstandingPayments = totalRevenue - totalPaid;
      
      const totalReceiptExpenses = receipts.reduce((sum, r) => sum + parseFloat(r.amount || 0), 0);
      
      const totalLaborHours = timesheets.reduce((sum, t) => sum + parseFloat(t.hours || 0), 0);
      const avgHourlyRate = timesheets.length > 0 
        ? timesheets.reduce((sum, t) => sum + (parseFloat(t.hourly_rate || 0)), 0) / timesheets.length 
        : 0;
      const totalLaborCost = totalLaborHours * avgHourlyRate;
      
      const grossProfit = totalRevenue - totalLaborCost - totalReceiptExpenses;
      const profitMargin = totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0;
      
      // Prepare context for AI
      const context = {
        totalJobs,
        activeJobs,
        completedJobs,
        totalRevenue: totalRevenue.toFixed(2),
        totalPaid: totalPaid.toFixed(2),
        outstandingPayments: outstandingPayments.toFixed(2),
        totalReceiptExpenses: totalReceiptExpenses.toFixed(2),
        totalLaborHours: totalLaborHours.toFixed(2),
        avgHourlyRate: avgHourlyRate.toFixed(2),
        totalLaborCost: totalLaborCost.toFixed(2),
        grossProfit: grossProfit.toFixed(2),
        profitMargin: profitMargin.toFixed(2)
      };
      
      // AI prompt
      const prompt = `You are a business analyst for a construction contractor. Analyze the following business metrics and provide actionable insights:

Total Jobs: ${context.totalJobs} (Active: ${context.activeJobs}, Completed: ${context.completedJobs})
Total Revenue: $${context.totalRevenue}
Total Paid: $${context.totalPaid}
Outstanding Payments: $${context.outstandingPayments}
Total Labor Cost: $${context.totalLaborCost} (${context.totalLaborHours} hours @ $${context.avgHourlyRate}/hr)
Total Receipt Expenses: $${context.totalReceiptExpenses}
Gross Profit: $${context.grossProfit}
Profit Margin: ${context.profitMargin}%

Provide 5-7 specific, actionable business insights in JSON format:
{
  "insights": [
    {
      "title": "Insight Title",
      "description": "Detailed description of the insight",
      "severity": "info|warning|critical",
      "actionItems": ["Action 1", "Action 2"]
    }
  ],
  "summary": "Overall business health summary in 2-3 sentences"
}`;

      // Call OpenRouter API
      const response = await axios.post(
        `${OPENAI_BASE_URL}/chat/completions`,
        {
          model: AI_MODEL_NAME,
          messages: [
            {
              role: 'system',
              content: 'You are a business analyst specializing in construction contracting. Provide clear, actionable insights in JSON format.'
            },
            {
              role: 'user',
              content: prompt
            }
          ],
          temperature: 0.7,
          max_tokens: 2000
        },
        {
          headers: {
            'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://siteledger.ai',
            'X-Title': 'SiteLedger AI Insights'
          },
          timeout: 30000
        }
      );

      const aiResponse = response.data.choices[0].message.content;
      
      // Parse JSON from AI response
      let insights;
      try {
        // Try to extract JSON if wrapped in markdown code blocks
        const jsonMatch = aiResponse.match(/```json\n?([\s\S]*?)\n?```/) || 
                         aiResponse.match(/```\n?([\s\S]*?)\n?```/) ||
                         [null, aiResponse];
        insights = JSON.parse(jsonMatch[1] || aiResponse);
      } catch (parseError) {
        // Fallback if JSON parsing fails
        insights = {
          insights: [
            {
              title: 'AI Analysis Available',
              description: aiResponse,
              severity: 'info',
              actionItems: ['Review the analysis', 'Take appropriate action']
            }
          ],
          summary: 'AI generated insights are available for review.'
        };
      }
      
      return {
        success: true,
        metrics: context,
        ...insights,
        generatedAt: new Date().toISOString()
      };
      
    } catch (error) {
      logger.error('Error generating AI insights:', { error: error.message, stack: error.stack });
      throw new Error(`Failed to generate insights: ${error.response?.data?.error?.message || error.message}`);
    }
  }
  
  /**
   * Generate insights for a specific job
   */
  static async generateJobInsights(job, receipts, timesheets) {
    try {
      const jobReceipts = receipts.filter(r => r.job_id === job.id);
      const jobTimesheets = timesheets.filter(t => t.job_id === job.id);
      
      const receiptExpenses = jobReceipts.reduce((sum, r) => sum + parseFloat(r.amount || 0), 0);
      const laborHours = jobTimesheets.reduce((sum, t) => sum + parseFloat(t.hours || 0), 0);
      const avgRate = jobTimesheets.length > 0 
        ? jobTimesheets.reduce((sum, t) => sum + parseFloat(t.hourly_rate || 0), 0) / jobTimesheets.length 
        : 0;
      const laborCost = laborHours * avgRate;
      
      const projectValue = parseFloat(job.project_value || 0);
      const amountPaid = parseFloat(job.amount_paid || 0);
      const profit = projectValue - laborCost - receiptExpenses;
      const profitMargin = projectValue > 0 ? (profit / projectValue) * 100 : 0;
      
      const prompt = `Analyze this construction job:

Job: ${job.job_name}
Client: ${job.client_name}
Status: ${job.status}
Project Value: $${projectValue.toFixed(2)}
Amount Paid: $${amountPaid.toFixed(2)}
Outstanding: $${(projectValue - amountPaid).toFixed(2)}
Labor Cost: $${laborCost.toFixed(2)} (${laborHours} hours)
Material Expenses: $${receiptExpenses.toFixed(2)}
Current Profit: $${profit.toFixed(2)}
Profit Margin: ${profitMargin.toFixed(2)}%

Provide 3-5 specific insights about this job in JSON format:
{
  "insights": [
    {
      "title": "Insight Title",
      "description": "Specific insight about this job",
      "severity": "info|warning|critical",
      "recommendation": "What to do next"
    }
  ],
  "overall": "Overall job health assessment"
}`;

      const response = await axios.post(
        `${OPENAI_BASE_URL}/chat/completions`,
        {
          model: AI_MODEL_NAME,
          messages: [
            { role: 'system', content: 'You are a construction project analyst. Provide insights in JSON format.' },
            { role: 'user', content: prompt }
          ],
          temperature: 0.7,
          max_tokens: 1500
        },
        {
          headers: {
            'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://siteledger.ai',
            'X-Title': 'SiteLedger AI Insights'
          },
          timeout: 30000
        }
      );

      const aiResponse = response.data.choices[0].message.content;
      const jsonMatch = aiResponse.match(/```json\n?([\s\S]*?)\n?```/) || [null, aiResponse];
      const insights = JSON.parse(jsonMatch[1] || aiResponse);
      
      return {
        success: true,
        jobId: job.id,
        jobName: job.job_name,
        ...insights,
        generatedAt: new Date().toISOString()
      };
    } catch (error) {
      logger.error('Error generating job insights:', { error: error.message, jobId: job?.id });
      throw new Error(`Failed to generate job insights: ${error.response?.data?.error?.message || error.message}`);
    }
  }
}

module.exports = AIInsightsService;
