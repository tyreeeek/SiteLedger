import SwiftUI
import Charts

// MARK: - Monthly Profit Trend Chart
struct MonthlyProfitTrendChart: View {
    let receipts: [Receipt]
    let timesheets: [Timesheet]
    let workers: [User]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profit Trend")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Last 6 months")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                // Legend
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(AppTheme.successColor)
                            .frame(width: 6, height: 6)
                        Text("Profit")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            
            if monthlyData.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(monthlyData) { data in
                        LineMark(
                            x: .value("Month", data.monthLabel),
                            y: .value("Profit", data.profit)
                        )
                        .foregroundStyle(AppTheme.successColor)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        AreaMark(
                            x: .value("Month", data.monthLabel),
                            y: .value("Profit", data.profit)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.successColor.opacity(0.3), AppTheme.successColor.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        PointMark(
                            x: .value("Month", data.monthLabel),
                            y: .value("Profit", data.profit)
                        )
                        .foregroundStyle(AppTheme.successColor)
                        .symbolSize(60)
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
                            if let profit = value.as(Double.self) {
                                Text("$\(Int(profit))")
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
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
            Text("No profit data yet")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    private var monthlyData: [MonthlyProfitData] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        
        var data: [MonthlyProfitData] = []
        
        // Worker rates lookup
        let workerRates: [String: Double] = Dictionary(uniqueKeysWithValues: workers.compactMap { worker in
            guard let workerID = worker.id, let rate = worker.hourlyRate else { return nil }
            return (workerID, rate)
        })
        
        // Last 6 months
        for monthsAgo in (0..<6).reversed() {
            guard let date = calendar.date(byAdding: .month, value: -monthsAgo, to: Date()) else { continue }
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            
            // Note: Receipts are documents only and do NOT affect profit
            // Profit is calculated as projectValue - laborCost
            
            // Filter timesheets for this month
            let monthTimesheets = timesheets.filter { ($0.clockIn ?? Date.distantPast) >= startOfMonth && ($0.clockIn ?? Date.distantPast) < endOfMonth }
            let laborCost = monthTimesheets.reduce(0) { total, timesheet in
                guard let hours = timesheet.hours, let rate = workerRates[timesheet.userID ?? ""] else { return total }
                return total + (hours * rate)
            }
            
            // For monthly profit, we'd need to track which jobs completed in this month
            // For now, just show labor costs as negative
            let profit = -laborCost
            
            data.append(MonthlyProfitData(
                monthLabel: dateFormatter.string(from: date),
                profit: profit
            ))
        }
        
        return data
    }
}

// MARK: - Daily Receipts Chart (Document Storage - No Income/Expense)
struct DailyReceiptsChart: View {
    let receipts: [Receipt]
    @State private var selectedDay: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Receipts by Day")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Last 30 days (document storage only)")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
            }
            
            if dailyData.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(dailyData) { data in
                        BarMark(
                            x: .value("Day", data.dayLabel),
                            y: .value("Amount", data.amount)
                        )
                        .foregroundStyle(AppTheme.primaryColor)
                        .opacity(selectedDay == nil || selectedDay == data.dayLabel ? 1.0 : 0.3)
                    }
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 5)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
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
                
                // Summary - Receipts are documents only
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(AppTheme.primaryColor)
                                .frame(width: 8, height: 8)
                            Text("Total Receipts")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Text("$\(Int(totalAmount))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Documents")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text("\(receipts.count)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.secondaryColor)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
            Text("No transaction data")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }
    
    private var dailyData: [DailyTransactionData] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        var data: [DailyTransactionData] = []
        
        // Last 30 days - Receipts are documents only
        for daysAgo in (0..<30).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let dayReceipts = receipts.filter { ($0.date ?? Date.distantPast) >= startOfDay && ($0.date ?? Date.distantPast) < endOfDay }
            let totalAmount = dayReceipts.reduce(0) { $0 + ($1.amount ?? 0) }
            
            let dayLabel = dateFormatter.string(from: date)
            
            if totalAmount > 0 {
                data.append(DailyTransactionData(dayLabel: dayLabel, amount: totalAmount, type: "Receipts"))
            }
        }
        
        return data
    }
    
    private var totalAmount: Double {
        let last30Days = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return receipts.filter { ($0.date ?? Date.distantPast) >= last30Days }.reduce(0) { $0 + ($1.amount ?? 0) }
    }
}

// MARK: - Top Categories Chart (Document Storage)
struct TopCategoriesChart: View {
    let receipts: [Receipt]
    @State private var selectedCategory: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Receipts by Category")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            if categoryData.isEmpty {
                emptyState
            } else {
                if #available(iOS 17.0, *) {
                    HStack(spacing: 20) {
                        // Donut Chart
                        Chart(categoryData) { data in
                            SectorMark(
                                angle: .value("Amount", data.amount),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .foregroundStyle(by: .value("Category", data.category))
                            .opacity(selectedCategory == nil || selectedCategory == data.category ? 1.0 : 0.3)
                        }
                        .chartAngleSelection(value: $selectedCategory)
                        .frame(height: 150)
                        
                        // Legend
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(categoryData.prefix(5)) { data in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(colorForCategory(data.category))
                                        .frame(width: 8, height: 8)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(data.category)
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textPrimary)
                                            .lineLimit(1)
                                        Text("$\(Int(data.amount))")
                                            .font(.caption2)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    .opacity(selectedCategory == nil || selectedCategory == data.category ? 1.0 : 0.5)
                                }
                                .onTapGesture {
                                    withAnimation {
                                        selectedCategory = selectedCategory == data.category ? nil : data.category
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // iOS 16 fallback - simple list
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(categoryData.prefix(5)) { data in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(colorForCategory(data.category))
                                    .frame(width: 12, height: 12)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(data.category)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text("$\(Int(data.amount))")
                                        .font(.caption2)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    .frame(height: 150)
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
            Text("No category data")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
    }
    
    private var categoryData: [CategoryData] {
        // Group by category - Receipts are documents only
        var categoryTotals: [String: Double] = [:]
        for receipt in receipts {
            // Use vendor as category for now
            let category = (receipt.vendor ?? "").isEmpty ? "Uncategorized" : (receipt.vendor ?? "Uncategorized")
            categoryTotals[category, default: 0] += (receipt.amount ?? 0)
        }
        
        // Sort by amount and take top 5
        let sortedCategories = categoryTotals.sorted { $0.value > $1.value }
        let topCategories = Array(sortedCategories.prefix(5))
        
        return topCategories.map { category, amount in
            CategoryData(category: category, amount: amount)
        }
    }
    
    private func colorForCategory(_ category: String) -> Color {
        let colors: [Color] = [
            AppTheme.primaryColor,
            AppTheme.successColor,
            AppTheme.warningColor,
            .blue,
            .purple
        ]
        let index = abs(category.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Data Models
struct MonthlyProfitData: Identifiable {
    let id = UUID()
    let monthLabel: String
    let profit: Double
}

struct DailyTransactionData: Identifiable {
    let id = UUID()
    let dayLabel: String
    let amount: Double
    let type: String
}

struct CategoryData: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
}
