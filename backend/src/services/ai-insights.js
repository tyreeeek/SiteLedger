// AI Insights Generation Service - ENHANCED VERSION
// Generates comprehensive, detailed business insights using rule-based analysis

const logger = require('../config/logger');

logger.info('✅ Enhanced AI Insights Service initialized with comprehensive analysis');

// Helper function for currency formatting
const formatCurrency = (amount) => {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount);
};

class AIInsightsService {
  /**
   * Generate comprehensive business insights from job, receipt, and timesheet data
   */
  static async generateInsights(userId, jobs, receipts, timesheets) {
    try {
      // Calculate key metrics
      const totalJobs = jobs.length;
      const activeJobs = jobs.filter(j => j.status === 'in-progress' || j.status === 'active').length;
      const completedJobs = jobs.filter(j => j.status === 'completed').length;
      const notStartedJobs = jobs.filter(j => j.status === 'not-started').length;
      
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
      const laborPercent = totalRevenue > 0 ? (totalLaborCost / totalRevenue) * 100 : 0;
      const materialsPercent = totalRevenue > 0 ? (totalReceiptExpenses / totalRevenue) * 100 : 0;
      const paymentCollectionRate = totalRevenue > 0 ? (totalPaid / totalRevenue) * 100 : 0;
      
      // Worker analysis
      const uniqueWorkers = new Set(timesheets.map(t => t.user_id)).size;
      const avgHoursPerWorker = uniqueWorkers > 0 ? totalLaborHours / uniqueWorkers : 0;
      
      // Per-job metrics
      const avgJobValue = totalJobs > 0 ? totalRevenue / totalJobs : 0;
      const avgJobProfit = totalJobs > 0 ? grossProfit / totalJobs : 0;
      
      // Recent activity
      const recentReceipts = receipts.filter(r => {
        const date = new Date(r.date);
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        return date >= thirtyDaysAgo;
      }).length;
      
      const recentTimesheets = timesheets.filter(t => {
        const date = new Date(t.date);
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        return date >= thirtyDaysAgo;
      }).length;
      
      // Generate comprehensive insights
      logger.info('Generating comprehensive rule-based insights from business data...');
      
      const insights = [];
      
      // FINANCIAL HEALTH (5-8 insights)
      if (profitMargin < 10) {
        insights.push({
          title: "🔴 CRITICAL: Low Profit Margin",
          description: `Current profit margin of ${profitMargin.toFixed(1)}% is below minimum sustainable level. Gross profit: ${formatCurrency(grossProfit)} from ${formatCurrency(totalRevenue)} revenue.`,
          severity: "critical",
          actionItems: [
            "URGENT: Review all active job costs and identify areas for reduction",
            "Increase project pricing by 15-20% for new bids to ensure profitability",
            `Analyze labor efficiency (${laborPercent.toFixed(1)}% of revenue) and material costs (${materialsPercent.toFixed(1)}%)`
          ]
        });
      } else if (profitMargin < 15) {
        insights.push({
          title: "⚠️ Below-Average Profit Margin",
          description: `Profit margin of ${profitMargin.toFixed(1)}% is below industry standard (15-20%). Profit: ${formatCurrency(grossProfit)} on ${formatCurrency(totalRevenue)} revenue.`,
          severity: "warning",
          actionItems: [
            `Review material costs (${materialsPercent.toFixed(1)}%) and labor costs (${laborPercent.toFixed(1)}%) for optimization`,
            "Consider 10% price increase for new projects",
            "Identify top 3 most profitable jobs and replicate their efficiency"
          ]
        });
      } else if (profitMargin >= 25) {
        insights.push({
          title: "🌟 EXCELLENT: Strong Profit Margin",
          description: `Outstanding ${profitMargin.toFixed(1)}% profit margin (${formatCurrency(grossProfit)} profit) exceeds industry standards. Strong business performance!`,
          severity: "info",
          actionItems: [
            `Consider reinvesting ${formatCurrency(grossProfit * 0.2)} (20%) in equipment upgrades or marketing`,
            `Build 3-6 month cash reserve of ${formatCurrency(totalLaborCost * 0.5)} for slow periods`,
            "Document successful project processes to maintain this performance"
          ]
        });
      } else {
        insights.push({
          title: "✅ HEALTHY: Good Profit Margin",
          description: `Profit margin of ${profitMargin.toFixed(1)}% (${formatCurrency(grossProfit)}) is within healthy industry range (15-25%). Good financial management.`,
          severity: "info",
          actionItems: [
            "Maintain current pricing strategy and cost controls",
            "Monitor monthly to ensure consistency",
            "Consider 5% price increase for particularly complex projects"
          ]
        });
      }
      
      // REVENUE & PAYMENT ANALYSIS
      insights.push({
        title: "💰 REVENUE BREAKDOWN",
        description: `Total revenue: ${formatCurrency(totalRevenue)} across ${totalJobs} jobs (avg: ${formatCurrency(avgJobValue)}/job). Collected: ${formatCurrency(totalPaid)} (${paymentCollectionRate.toFixed(1)}%). Outstanding: ${formatCurrency(outstandingPayments)}.`,
        severity: "info",
        actionItems: [
          `${completedJobs} completed jobs, ${activeJobs} in progress, ${notStartedJobs} not started`,
          `Average job value: ${formatCurrency(avgJobValue)}, Average job profit: ${formatCurrency(avgJobProfit)}`,
          "Track monthly revenue trends to identify seasonal patterns"
        ]
      });
      
      if (outstandingPayments > totalRevenue * 0.35) {
        insights.push({
          title: "🔴 CRITICAL: High Outstanding Payments",
          description: `${formatCurrency(outstandingPayments)} in unpaid invoices (${(outstandingPayments/totalRevenue*100).toFixed(1)}% of revenue). SERIOUS cash flow risk!`,
          severity: "critical",
          actionItems: [
            `URGENT: Contact clients with balances over ${formatCurrency(outstandingPayments/10)}`,
            "Implement strict payment terms: 50% deposit, 50% on completion for new jobs",
            "Consider factoring or business line of credit for cash flow stability",
            "Review and potentially pause work for clients with overdue payments"
          ]
        });
      } else if (outstandingPayments > totalRevenue * 0.2) {
        insights.push({
          title: "⚠️ Elevated Outstanding Payments",
          description: `${formatCurrency(outstandingPayments)} outstanding (${(outstandingPayments/totalRevenue*100).toFixed(1)}% of revenue). Monitor cash flow closely.`,
          severity: "warning",
          actionItems: [
            "Send payment reminders for invoices over 30 days",
            `Require deposits (30-50%) for projects over ${formatCurrency(avgJobValue)}`,
            "Review client payment histories before accepting new jobs"
          ]
        });
      } else {
        insights.push({
          title: "✅ STRONG: Payment Collection",
          description: `Excellent payment collection: ${paymentCollectionRate.toFixed(1)}% of revenue collected (${formatCurrency(totalPaid)}). Outstanding: ${formatCurrency(outstandingPayments)}.`,
          severity: "info",
          actionItems: [
            "Continue current payment collection practices",
            "Maintain clear payment terms and follow-up procedures",
            "Build client relationships for repeat business"
          ]
        });
      }
      
      // LABOR COST ANALYSIS (3-4 insights)
      if (laborPercent > 45) {
        insights.push({
          title: "🔴 CRITICAL: Excessive Labor Costs",
          description: `Labor costs are ${laborPercent.toFixed(1)}% of revenue (${formatCurrency(totalLaborCost)} for ${totalLaborHours.toFixed(0)} hours). Unsustainable - should be 20-35%!`,
          severity: "critical",
          actionItems: [
            `URGENT: Analyze ${uniqueWorkers} worker(s) productivity - averaging ${avgHoursPerWorker.toFixed(1)} hours per worker`,
            "Review if jobs are taking 30-50% longer than estimated",
            "Consider worker training, better tools, or revised time estimates",
            "Increase project quotes by 20% to account for actual labor costs"
          ]
        });
      } else if (laborPercent > 35) {
        insights.push({
          title: "⚠️ High Labor Costs",
          description: `Labor at ${laborPercent.toFixed(1)}% of revenue (${formatCurrency(totalLaborCost)}, ${totalLaborHours.toFixed(0)} hours @ ${formatCurrency(avgHourlyRate)}/hr). Target: 20-35%.`,
          severity: "warning",
          actionItems: [
            `Analyze worker efficiency: ${uniqueWorkers} worker(s), avg ${avgHoursPerWorker.toFixed(1)} hrs each`,
            "Compare estimated vs actual hours on recent jobs",
            "Consider task automation or workflow improvements"
          ]
        });
      } else if (laborPercent < 15) {
        insights.push({
          title: "💡 Low Labor Utilization",
          description: `Labor only ${laborPercent.toFixed(1)}% of revenue. ${uniqueWorkers} worker(s) totaling ${totalLaborHours.toFixed(0)} hours. Possible underutilization.`,
          severity: "info",
          actionItems: [
            `Consider taking on more projects to utilize ${uniqueWorkers} worker(s) more fully`,
            `Review if hourly rates of ${formatCurrency(avgHourlyRate)}/hr are competitive`,
            "Opportunity to increase profit margin on labor-intensive work"
          ]
        });
      } else {
        insights.push({
          title: "✅ OPTIMAL: Labor Cost Efficiency",
          description: `Labor costs at ${laborPercent.toFixed(1)}% (${formatCurrency(totalLaborCost)}) are within optimal range (20-35%). ${uniqueWorkers} worker(s), ${totalLaborHours.toFixed(0)} total hours.`,
          severity: "info",
          actionItems: [
            "Maintain current labor efficiency practices",
            `Average ${avgHoursPerWorker.toFixed(1)} hours per worker at ${formatCurrency(avgHourlyRate)}/hr`,
            "Document successful project workflows for future jobs"
          ]
        });
      }
      
      // MATERIAL COST ANALYSIS
      if (materialsPercent > 40) {
        insights.push({
          title: "⚠️ High Material Costs",
          description: `Material expenses at ${materialsPercent.toFixed(1)}% of revenue (${formatCurrency(totalReceiptExpenses)}, ${receipts.length} receipts). Target: 25-35%.`,
          severity: "warning",
          actionItems: [
            `Review ${receipts.length} receipts for bulk purchasing opportunities`,
            "Compare pricing across 3+ suppliers for top 5 materials",
            "Consider material waste reduction programs",
            `${recentReceipts} receipts in last 30 days - analyze spending patterns`
          ]
        });
      } else if (materialsPercent > 0) {
        insights.push({
          title: `📊 MATERIAL COSTS: ${materialsPercent.toFixed(1)}% of Revenue`,
          description: `Material expenses: ${formatCurrency(totalReceiptExpenses)} across ${receipts.length} receipts (${materialsPercent.toFixed(1)}% of ${formatCurrency(totalRevenue)} revenue).`,
          severity: "info",
          actionItems: [
            `Recent activity: ${recentReceipts} receipts in last 30 days`,
            `Average receipt amount: ${formatCurrency(totalReceiptExpenses / Math.max(receipts.length, 1))}`,
            "Monitor material costs to maintain current efficiency"
          ]
        });
      }
      
      // WORKER PRODUCTIVITY
      insights.push({
        title: "👷 WORKFORCE ANALYSIS",
        description: `${uniqueWorkers} active worker(s) logged ${totalLaborHours.toFixed(0)} total hours (avg: ${avgHoursPerWorker.toFixed(1)} hrs/worker) at ${formatCurrency(avgHourlyRate)}/hr average rate.`,
        severity: "info",
        actionItems: [
          `Recent activity: ${recentTimesheets} timesheets in last 30 days`,
          avgHoursPerWorker > 160 ? "⚠️ High hours per worker - monitor for burnout" : avgHoursPerWorker < 40 ? "💡 Low utilization - consider more job assignments" : "✅ Good worker utilization",
          `Total labor cost: ${formatCurrency(totalLaborCost)} (${laborPercent.toFixed(1)}% of revenue)`
        ]
      });
      
      // PROJECT PORTFOLIO
      if (activeJobs === 0 && notStartedJobs === 0) {
        insights.push({
          title: "⚠️ NO ACTIVE JOBS",
          description: `All ${totalJobs} jobs are completed. No projects in pipeline. URGENT: Focus on business development.`,
          severity: "warning",
          actionItems: [
            "URGENT: Reach out to past clients for repeat business",
            "Increase marketing efforts and bid on new projects",
            "Consider seasonal factors affecting project pipeline"
          ]
        });
      } else if (activeJobs > 10) {
        insights.push({
          title: `⚠️ HIGH PROJECT LOAD: ${activeJobs} Active Jobs`,
          description: `Managing ${activeJobs} concurrent projects with ${uniqueWorkers} worker(s). Risk of overextension and quality issues.`,
          severity: "warning",
          actionItems: [
            `Review project schedules and deadlines for all ${activeJobs} jobs`,
            `Ensure ${uniqueWorkers} worker(s) aren't overallocated`,
            `Consider pausing new bids until ${Math.floor(activeJobs * 0.3)} jobs complete`,
            "Delegate project management responsibilities"
          ]
        });
      } else if (activeJobs > 0) {
        insights.push({
          title: "📋 PROJECT PORTFOLIO BALANCED",
          description: `${activeJobs} active jobs, ${notStartedJobs} scheduled, ${completedJobs} completed. Good project pipeline management.`,
          severity: "info",
          actionItems: [
            `Current workload appears manageable for ${uniqueWorkers} worker(s)`,
            "Continue monitoring capacity before accepting new projects",
            "Plan for business development to maintain pipeline"
          ]
        });
      }
      
      // BUSINESS GROWTH
      const avgRevenuePerCompleted = completedJobs > 0 ? jobs.filter(j => j.status === 'completed').reduce((sum, j) => sum + parseFloat(j.project_value || 0), 0) / completedJobs : 0;
      if (completedJobs >= 5) {
        insights.push({
          title: "📈 BUSINESS PERFORMANCE METRICS",
          description: `${completedJobs} completed jobs averaging ${formatCurrency(avgRevenuePerCompleted)} revenue each. Total completed value: ${formatCurrency(avgRevenuePerCompleted * completedJobs)}.`,
          severity: "info",
          actionItems: [
            `Completion rate: ${totalJobs > 0 ? (completedJobs/totalJobs*100).toFixed(0) : 0}% of all jobs`,
            "Analyze your top 3 most profitable completed jobs",
            "Use successful project patterns to optimize future work"
          ]
        });
      }
      
      // OVERALL BUSINESS HEALTH SUMMARY
      let healthScore = 0;
      if (profitMargin >= 15) healthScore += 30;
      else if (profitMargin >= 10) healthScore += 20;
      else healthScore += 10;
      
      if (paymentCollectionRate >= 75) healthScore += 25;
      else if (paymentCollectionRate >= 60) healthScore += 15;
      else healthScore += 5;
      
      if (laborPercent >= 20 && laborPercent <= 35) healthScore += 25;
      else if (laborPercent >= 15 && laborPercent <= 40) healthScore += 15;
      else healthScore += 5;
      
      if (activeJobs > 0 && activeJobs <= 8) healthScore += 20;
      else if (activeJobs > 8) healthScore += 10;
      else healthScore += 5;
      
      let healthEmoji = healthScore >= 80 ? '🌟' : healthScore >= 60 ? '✅' : healthScore >= 40 ? '⚠️' : '🔴';
      let healthLabel = healthScore >= 80 ? 'EXCELLENT' : healthScore >= 60 ? 'HEALTHY' : healthScore >= 40 ? 'NEEDS ATTENTION' : 'CRITICAL';
      
      const summary = `${healthEmoji} BUSINESS HEALTH: ${healthLabel} (Score: ${healthScore}/100) | ${totalJobs} Total Jobs (${activeJobs} active, ${completedJobs} completed) | Revenue: ${formatCurrency(totalRevenue)} | Collected: ${formatCurrency(totalPaid)} (${paymentCollectionRate.toFixed(0)}%) | Profit: ${formatCurrency(grossProfit)} (${profitMargin.toFixed(1)}% margin) | Labor: ${formatCurrency(totalLaborCost)} (${laborPercent.toFixed(0)}%, ${totalLaborHours.toFixed(0)}hrs) | Materials: ${formatCurrency(totalReceiptExpenses)} (${materialsPercent.toFixed(0)}%) | ${uniqueWorkers} worker(s) | ${insights.length} actionable insights generated`;
      
      return {
        success: true,
        metrics: {
          totalJobs,
          activeJobs,
          completedJobs,
          notStartedJobs,
          totalRevenue,
          totalPaid,
          outstandingPayments,
          totalReceiptExpenses,
          totalLaborHours,
          avgHourlyRate,
          totalLaborCost,
          grossProfit,
          profitMargin,
          laborPercent,
          materialsPercent,
          paymentCollectionRate,
          uniqueWorkers,
          avgHoursPerWorker,
          avgJobValue,
          avgJobProfit,
          healthScore
        },
        insights,
        summary,
        generatedAt: new Date().toISOString()
      };
      
    } catch (error) {
      logger.error('Error generating AI insights:', { error: error.message, stack: error.stack });
      throw new Error(`Failed to generate insights: ${error.message}`);
    }
  }
  
  /**
   * Generate comprehensive insights for a specific job with detailed analysis
   * Returns format: { summary, recommendations[], risks[], metrics }
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
      const balanceDue = projectValue - amountPaid;
      const profit = projectValue - laborCost - receiptExpenses;
      const profitMargin = projectValue > 0 ? (profit / projectValue) * 100 : 0;
      const laborPercent = projectValue > 0 ? (laborCost / projectValue) * 100 : 0;
      const materialsPercent = projectValue > 0 ? (receiptExpenses / projectValue) * 100 : 0;
      const paymentProgress = projectValue > 0 ? (amountPaid / projectValue) * 100 : 0;
      
      // Worker analysis
      const uniqueWorkers = new Set(jobTimesheets.map(t => t.user_id)).size;
      const avgHoursPerWorker = uniqueWorkers > 0 ? laborHours / uniqueWorkers : 0;
      
      // Timeline analysis
      const timesheetDates = jobTimesheets.map(t => new Date(t.date)).filter(d => !isNaN(d));
      const startDate = job.start_date ? new Date(job.start_date) : (timesheetDates.length > 0 ? new Date(Math.min(...timesheetDates)) : null);
      const endDate = job.end_date ? new Date(job.end_date) : null;
      const today = new Date();
      
      let daysElapsed = 0;
      let daysRemaining = 0;
      let projectDuration = 0;
      
      if (startDate) {
        daysElapsed = Math.floor((today - startDate) / (1000 * 60 * 60 * 24));
        if (endDate) {
          daysRemaining = Math.floor((endDate - today) / (1000 * 60 * 60 * 24));
          projectDuration = Math.floor((endDate - startDate) / (1000 * 60 * 60 * 24));
        }
      }
      
      // Cost efficiency
      const costPerDay = daysElapsed > 0 ? (laborCost + receiptExpenses) / daysElapsed : 0;
      const avgCostPerHour = laborHours > 0 ? (laborCost + receiptExpenses) / laborHours : 0;
      
      // Generate comprehensive insights
      const recommendations = [];
      const risks = [];
      
      // Financial Analysis (8-10 insights)
      if (profitMargin < 10) {
        risks.push(`⚠️ LOW PROFIT MARGIN: Current profit margin is only ${profitMargin.toFixed(1)}% (${formatCurrency(profit)}). Industry standard is 15-20% for construction projects.`);
        recommendations.push(`💡 Review labor costs (${laborPercent.toFixed(1)}% of project value) and material expenses (${materialsPercent.toFixed(1)}%) to identify cost reduction opportunities.`);
      } else if (profitMargin >= 25) {
        recommendations.push(`✅ EXCELLENT PROFIT MARGIN: ${profitMargin.toFixed(1)}% profit margin (${formatCurrency(profit)}) exceeds industry standards. Consider competitive pricing for future bids.`);
      } else {
        recommendations.push(`✅ HEALTHY PROFIT MARGIN: ${profitMargin.toFixed(1)}% profit margin (${formatCurrency(profit)}) is within healthy range (15-25%).`);
      }
      
      // Labor Cost Analysis
      if (laborPercent > 40) {
        risks.push(`⚠️ HIGH LABOR COSTS: Labor represents ${laborPercent.toFixed(1)}% of project value (${formatCurrency(laborCost)}). Optimal range is 20-35%.`);
        recommendations.push(`💡 Analyze worker productivity: ${laborHours.toFixed(1)} total hours across ${uniqueWorkers} worker(s) averaging ${avgHoursPerWorker.toFixed(1)} hours each.`);
        recommendations.push(`💡 Consider task automation, better tools, or workflow optimization to reduce labor hours.`);
      } else if (laborPercent < 20) {
        recommendations.push(`✅ EFFICIENT LABOR UTILIZATION: Labor costs are ${laborPercent.toFixed(1)}% of project value, showing excellent efficiency.`);
      } else {
        recommendations.push(`✅ OPTIMAL LABOR COSTS: Labor at ${laborPercent.toFixed(1)}% of project value is within ideal range (20-35%).`);
      }
      
      // Materials Analysis
      if (materialsPercent > 40) {
        risks.push(`⚠️ HIGH MATERIAL COSTS: Material expenses are ${materialsPercent.toFixed(1)}% of project value (${formatCurrency(receiptExpenses)} across ${jobReceipts.length} receipts).`);
        recommendations.push(`💡 Review recent receipts for bulk purchasing opportunities or alternative suppliers with better pricing.`);
      } else if (materialsPercent > 0) {
        recommendations.push(`✅ MATERIAL COSTS CONTROLLED: Materials at ${materialsPercent.toFixed(1)}% (${formatCurrency(receiptExpenses)}) across ${jobReceipts.length} receipt(s).`);
      }
      
      // Payment Progress Analysis
      if (paymentProgress < 30 && daysElapsed > 30) {
        risks.push(`🔴 CRITICAL PAYMENT DELAY: Only ${paymentProgress.toFixed(1)}% paid (${formatCurrency(amountPaid)} of ${formatCurrency(projectValue)}) after ${daysElapsed} days.`);
        recommendations.push(`💡 URGENT: Schedule payment collection meeting with ${job.client_name}. Balance due: ${formatCurrency(balanceDue)}.`);
      } else if (paymentProgress < 50 && daysElapsed > 60) {
        risks.push(`⚠️ SLOW PAYMENT PROGRESS: ${paymentProgress.toFixed(1)}% collected. Balance due: ${formatCurrency(balanceDue)}.`);
        recommendations.push(`💡 Send payment reminder to ${job.client_name} and consider milestone-based payment schedule.`);
      } else if (paymentProgress >= 80) {
        recommendations.push(`✅ EXCELLENT PAYMENT STATUS: ${paymentProgress.toFixed(1)}% collected (${formatCurrency(amountPaid)}). Only ${formatCurrency(balanceDue)} remaining.`);
      }
      
      // Timeline Analysis (if dates available)
      if (startDate && endDate) {
        const progressPercent = projectDuration > 0 ? (daysElapsed / projectDuration) * 100 : 0;
        
        if (job.status === 'in-progress' || job.status === 'active') {
          if (daysRemaining < 0) {
            risks.push(`🔴 PROJECT OVERDUE: ${Math.abs(daysRemaining)} days past deadline. Elapsed: ${daysElapsed} days of ${projectDuration} day timeline.`);
            recommendations.push(`💡 Schedule client meeting to discuss timeline extension and any additional costs due to delays.`);
          } else if (daysRemaining < 7) {
            risks.push(`⚠️ DEADLINE APPROACHING: Only ${daysRemaining} days remaining. ${progressPercent.toFixed(1)}% of timeline elapsed.`);
            recommendations.push(`💡 Prioritize critical path tasks and consider additional resources to meet deadline.`);
          } else if (daysRemaining < 14) {
            recommendations.push(`⏰ TWO WEEKS REMAINING: ${daysRemaining} days left to complete job. Timeline progress: ${progressPercent.toFixed(1)}%.`);
          }
        }
        
        if (costPerDay > 0) {
          recommendations.push(`📊 COST EFFICIENCY: Average daily cost is ${formatCurrency(costPerDay)} over ${daysElapsed} days (${formatCurrency(avgCostPerHour)}/hour).`);
        }
      }
      
      // Worker Productivity Analysis
      if (uniqueWorkers > 0) {
        if (avgHoursPerWorker < 20) {
          recommendations.push(`💡 LOW WORKER ENGAGEMENT: Average ${avgHoursPerWorker.toFixed(1)} hours per worker. Consider consolidating team or increasing task allocation.`);
        } else if (avgHoursPerWorker > 160) {
          risks.push(`⚠️ WORKER OVERTIME RISK: Average ${avgHoursPerWorker.toFixed(1)} hours per worker. Monitor for burnout and quality issues.`);
        }
        
        recommendations.push(`👷 TEAM SIZE: ${uniqueWorkers} worker(s) assigned, totaling ${laborHours.toFixed(1)} hours at average rate of ${formatCurrency(avgRate)}/hour.`);
      }
      
      // Status-specific insights
      if (job.status === 'not-started' && startDate && startDate < today) {
        risks.push(`⚠️ DELAYED START: Job scheduled to start ${Math.floor((today - startDate) / (1000 * 60 * 60 * 24))} days ago but status is still 'Not Started'.`);
        recommendations.push(`💡 Update job status or reschedule start date to reflect current timeline.`);
      }
      
      if (job.status === 'completed') {
        if (balanceDue > 0) {
          risks.push(`⚠️ UNPAID BALANCE ON COMPLETED JOB: ${formatCurrency(balanceDue)} outstanding. Follow up with ${job.client_name} for final payment.`);
        } else {
          recommendations.push(`✅ JOB FULLY PAID: All payments received for completed project.`);
        }
        
        if (profit > 0) {
          recommendations.push(`✅ PROFITABLE COMPLETION: Final profit of ${formatCurrency(profit)} (${profitMargin.toFixed(1)}% margin). Strong project execution.`);
        } else {
          risks.push(`🔴 COMPLETED WITH LOSS: Project finished with ${formatCurrency(Math.abs(profit))} loss. Review for lessons learned.`);
        }
      }
      
      // Budget analysis
      const totalSpent = laborCost + receiptExpenses;
      const spentPercent = projectValue > 0 ? (totalSpent / projectValue) * 100 : 0;
      
      if (spentPercent > 80 && job.status !== 'completed') {
        risks.push(`⚠️ BUDGET ALERT: ${spentPercent.toFixed(1)}% of project value spent (${formatCurrency(totalSpent)}). Remaining budget: ${formatCurrency(projectValue - totalSpent)}.`);
        recommendations.push(`💡 Review remaining tasks and adjust scope if needed to protect profit margin.`);
      }
      
      // Receipt pattern analysis
      if (jobReceipts.length > 0) {
        const avgReceiptAmount = receiptExpenses / jobReceipts.length;
        const largeReceipts = jobReceipts.filter(r => r.amount > avgReceiptAmount * 2).length;
        
        if (largeReceipts > 0) {
          recommendations.push(`📋 RECEIPT ANALYSIS: ${jobReceipts.length} total receipts, ${largeReceipts} significantly above average (${formatCurrency(avgReceiptAmount)}). Review large purchases.`);
        }
      }
      
      // Overall summary
      let statusEmoji = '🔵';
      let statusText = 'In Progress';
      
      if (job.status === 'completed') {
        statusEmoji = profit > 0 ? '✅' : '🔴';
        statusText = profit > 0 ? 'Completed Successfully' : 'Completed with Loss';
      } else if (job.status === 'not-started') {
        statusEmoji = '⏸️';
        statusText = 'Not Started';
      } else if (risks.length > 3) {
        statusEmoji = '⚠️';
        statusText = 'Needs Attention';
      } else if (profitMargin > 20 && paymentProgress > 70) {
        statusEmoji = '🌟';
        statusText = 'Performing Well';
      }
      
      const summary = `${statusEmoji} ${statusText} | ${job.job_name} for ${job.client_name} | Value: ${formatCurrency(projectValue)} | Paid: ${formatCurrency(amountPaid)} (${paymentProgress.toFixed(0)}%) | Profit: ${formatCurrency(profit)} (${profitMargin.toFixed(1)}% margin) | Labor: ${laborHours.toFixed(0)}hrs (${laborPercent.toFixed(0)}%) | Materials: ${formatCurrency(receiptExpenses)} (${materialsPercent.toFixed(0)}%) | ${uniqueWorkers} worker(s) | ${jobReceipts.length} receipt(s) | ${jobTimesheets.length} timesheet(s)${daysElapsed > 0 ? ` | ${daysElapsed} days elapsed` : ''}`;
      
      return {
        success: true,
        jobId: job.id,
        jobName: job.job_name,
        summary,
        recommendations,
        risks,
        metrics: {
          projectValue,
          amountPaid,
          balanceDue,
          profit,
          profitMargin,
          laborCost,
          laborPercent,
          receiptExpenses,
          materialsPercent,
          laborHours,
          uniqueWorkers,
          avgHoursPerWorker,
          paymentProgress,
          daysElapsed,
          daysRemaining,
          costPerDay,
          avgCostPerHour
        },
        generatedAt: new Date().toISOString()
      };
    } catch (error) {
      logger.error('Error generating job insights:', { error: error.message, jobId: job?.id });
      throw new Error(`Failed to generate job insights: ${error.message}`);
    }
  }
}

module.exports = AIInsightsService;
