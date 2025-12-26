import SwiftUI
import Charts

// MARK: - Receipts by Month Chart
// Note: Receipts are documents only and do NOT affect profit calculations
struct ReceiptsByMonthChart: View {
    let receipts: [Receipt]
    @State private var selectedPeriod: TimePeriod = .weekly
    
    enum TimePeriod: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Receipts by Period")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.menu)
            }
            
            if chartData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.textSecondary.opacity(0.5))
                    Text("No receipt data yet")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            } else {
                Chart {
                    ForEach(chartData) { data in
                        BarMark(
                            x: .value("Period", data.label),
                            y: .value("Amount", data.amount)
                        )
                        .foregroundStyle(AppTheme.primaryColor)
                        .annotation(position: .top) {
                            if data.amount > 0 {
                                Text("$\(Int(data.amount))")
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text("$\(Int(amount))")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                
                // Legend
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.primaryColor)
                        .frame(width: 8, height: 8)
                    Text("Receipt Total (Document Storage)")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
    }
    
    private var chartData: [ChartDataPoint] {
        let calendar = Calendar.current
        var dataPoints: [ChartDataPoint] = []
        
        // Group receipts by period
        let groupedReceipts: [(label: String, receipts: [Receipt])]
        
        switch selectedPeriod {
        case .daily:
            // Last 7 days
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd"
            
            groupedReceipts = (0..<7).reversed().compactMap { daysAgo in
                let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
                let dayReceipts = receipts.filter { calendar.isDate($0.date ?? Date.distantPast, inSameDayAs: date) }
                return (label: dateFormatter.string(from: date), receipts: dayReceipts)
            }
            
        case .weekly:
            // Last 4 weeks
            groupedReceipts = (0..<4).reversed().compactMap { weeksAgo in
                let startOfWeek = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: Date())!
                let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
                let weekReceipts = receipts.filter { ($0.date ?? Date.distantPast) >= startOfWeek && ($0.date ?? Date.distantPast) < endOfWeek }
                return (label: "Week \(4 - weeksAgo)", receipts: weekReceipts)
            }
            
        case .monthly:
            // Last 6 months
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM"
            
            groupedReceipts = (0..<6).reversed().compactMap { monthsAgo in
                let date = calendar.date(byAdding: .month, value: -monthsAgo, to: Date())!
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
                let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
                let monthReceipts = receipts.filter { ($0.date ?? Date.distantPast) >= startOfMonth && ($0.date ?? Date.distantPast) < endOfMonth }
                return (label: dateFormatter.string(from: date), receipts: monthReceipts)
            }
        }
        
        // Create data points for total receipts (document storage - no income/expense)
        for group in groupedReceipts {
            let total = group.receipts.reduce(0) { $0 + ($1.amount ?? 0) }
            
            if total > 0 {
                dataPoints.append(ChartDataPoint(label: group.label, amount: total, type: "Receipts"))
            }
        }
        
        return dataPoints
    }
}

// MARK: - Vendor Chart (Document Storage Only)
struct VendorReceiptsChart: View {
    let receipts: [Receipt]
    @State private var selectedVendor: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Receipts by Vendor")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            if vendorData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.textSecondary.opacity(0.5))
                    Text("No vendor data yet")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            } else {
                if #available(iOS 17.0, *) {
                    HStack(spacing: 20) {
                        // Pie Chart
                        Chart(vendorData) { data in
                            SectorMark(
                                angle: .value("Amount", data.amount),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(by: .value("Vendor", data.vendor))
                            .opacity(selectedVendor == nil || selectedVendor == data.vendor ? 1.0 : 0.3)
                        }
                        .chartAngleSelection(value: $selectedVendor)
                        .frame(height: 200)
                    
                        // Legend with percentages
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(vendorData) { data in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(colorForVendor(data.vendor))
                                        .frame(width: 8, height: 8)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(data.vendor)
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textPrimary)
                                            .lineLimit(1)
                                        Text("$\(Int(data.amount)) (\(Int(data.percentage))%)")
                                            .font(.caption2)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                                .opacity(selectedVendor == nil || selectedVendor == data.vendor ? 1.0 : 0.5)
                                .onTapGesture {
                                    withAnimation {
                                        selectedVendor = selectedVendor == data.vendor ? nil : data.vendor
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // iOS 16 fallback - simple list
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(vendorData) { data in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(colorForVendor(data.vendor))
                                    .frame(width: 12, height: 12)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(data.vendor)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text("$\(Int(data.amount)) (\(Int(data.percentage))%)")
                                        .font(.caption2)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    .frame(height: 200)
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
    }
    
    private var vendorData: [VendorDataPoint] {
        // All receipts (documents only - no income/expense filtering)
        
        // Group by vendor and sum amounts
        var vendorTotals: [String: Double] = [:]
        for receipt in receipts {
            vendorTotals[receipt.vendor ?? "Unknown", default: 0] += (receipt.amount ?? 0)
        }
        
        // Calculate total for percentages
        let total = vendorTotals.values.reduce(0, +)
        guard total > 0 else { return [] }
        
        // Sort by amount and take top 5
        let sortedVendors = vendorTotals.sorted { $0.value > $1.value }
        let topVendors = Array(sortedVendors.prefix(5))
        
        // Create data points with percentages
        var dataPoints = topVendors.map { vendor, amount in
            VendorDataPoint(
                vendor: vendor,
                amount: amount,
                percentage: (amount / total) * 100
            )
        }
        
        // Add "Other" category if there are more than 5 vendors
        if sortedVendors.count > 5 {
            let otherAmount = sortedVendors.dropFirst(5).reduce(0) { $0 + $1.value }
            dataPoints.append(VendorDataPoint(
                vendor: "Other",
                amount: otherAmount,
                percentage: (otherAmount / total) * 100
            ))
        }
        
        return dataPoints
    }
    
    private func colorForVendor(_ vendor: String) -> Color {
        let colors: [Color] = [
            AppTheme.primaryColor,
            AppTheme.successColor,
            AppTheme.warningColor,
            AppTheme.errorColor,
            .blue,
            .purple
        ]
        
        let index = abs(vendor.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Labor Cost Trend Chart
struct LaborCostTrendChart: View {
    let timesheets: [Timesheet]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Labor Cost Trend")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            if chartData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.textSecondary.opacity(0.5))
                    Text("No timesheet data yet")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
            } else {
                Chart {
                    ForEach(chartData) { data in
                        LineMark(
                            x: .value("Week", data.label),
                            y: .value("Hours", data.hours)
                        )
                        .foregroundStyle(AppTheme.primaryColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        PointMark(
                            x: .value("Week", data.label),
                            y: .value("Hours", data.hours)
                        )
                        .foregroundStyle(AppTheme.primaryColor)
                    }
                }
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text("\(Int(hours))h")
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
    }
    
    private var chartData: [LaborDataPoint] {
        let calendar = Calendar.current
        var dataPoints: [LaborDataPoint] = []
        
        // Group timesheets by week (last 4 weeks)
        for weeksAgo in (0..<4).reversed() {
            let startOfWeek = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: Date())!
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            
            let weekTimesheets = timesheets.filter { 
                ($0.clockIn ?? Date.distantPast) >= startOfWeek && ($0.clockIn ?? Date.distantPast) < endOfWeek 
            }
            
            let totalHours = weekTimesheets.reduce(0.0) { $0 + ($1.hours ?? 0) }
            
            dataPoints.append(LaborDataPoint(
                label: "Week \(4 - weeksAgo)",
                hours: totalHours
            ))
        }
        
        return dataPoints
    }
}

// MARK: - Metrics Summary Cards
struct MetricsSummaryView: View {
    let job: Job
    let receipts: [Receipt]
    let timesheets: [Timesheet]
    let workers: [User]  // Added to calculate actual labor costs
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                JobMetricCard(
                    title: "Profit",
                    value: "$\(Int(profit))",
                    icon: "dollarsign.circle.fill",
                    color: profit >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                    trend: profitTrend
                )
                
                JobMetricCard(
                    title: "Margin",
                    value: "\(Int(profitMargin))%",
                    icon: "percent",
                    color: profitMargin > 20 ? AppTheme.successColor : AppTheme.warningColor,
                    trend: nil
                )
            }
            
            HStack(spacing: 12) {
                JobMetricCard(
                    title: "Labor Hours",
                    value: "\(Int(totalHours))h",
                    icon: "clock.fill",
                    color: AppTheme.primaryColor,
                    trend: nil
                )
                
                JobMetricCard(
                    title: "Receipts",
                    value: "\(receipts.count)",
                    icon: "receipt.fill",
                    color: AppTheme.primaryColor,
                    trend: nil
                )
            }
        }
    }
    
    // Receipts are documents only - total for display purposes, does NOT affect profit
    private var totalReceiptsAmount: Double {
        receipts.reduce(0) { $0 + ($1.amount ?? 0) }
    }
    
    // Calculate actual labor cost from timesheets × worker hourly rates
    private var laborCost: Double {
        job.calculateLaborCost(timesheets: timesheets, workers: workers)
    }
    
    // Calculate receipt expenses for this job
    private var receiptExpenses: Double {
        receipts.reduce(0) { $0 + ($1.amount ?? 0) }
    }
    
    // PROFIT FORMULA: profit = projectValue - laborCost - receiptExpenses
    private var profit: Double {
        job.calculateProfit(laborCost: laborCost, receiptExpenses: receiptExpenses)
    }
    
    private var profitMargin: Double {
        guard job.projectValue > 0 else { return 0 }
        return (profit / job.projectValue) * 100
    }
    
    private var totalHours: Double {
        timesheets.reduce(0) { $0 + ($1.hours ?? 0) }
    }
    
    private var profitTrend: String? {
        // Simple trend indicator based on profit margin
        if profitMargin > 30 { return "↑" }
        if profitMargin < 10 { return "↓" }
        return nil
    }
}

struct JobMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
                if let trend = trend {
                    Text(trend)
                        .font(.title2)
                        .foregroundColor(color)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.shadowColor, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Data Models
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let amount: Double
    let type: String
}

struct VendorDataPoint: Identifiable {
    let id = UUID()
    let vendor: String
    let amount: Double
    let percentage: Double
}

struct LaborDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let hours: Double
}
