import Foundation
import UIKit

// MARK: - Shared Data Models

/// Receipt data extracted from OCR processing
struct ReceiptData {
    let amount: Double
    let vendor: String
    let category: String
    let date: Date
    let confidence: Double
}

/// AI Service for receipt processing, anomaly detection, and alerts
/// Now uses Apple Vision OCR (local, accurate) with backend fallback
class AIService {
    static let shared = AIService()
    
    // Allow public initialization for ViewModels
    init() {}
    
    // MARK: - Receipt Processing with Local Vision OCR
    
    /// Process receipt image using Apple Vision framework (local, fast, accurate)
    /// Falls back to backend OCR if local processing fails
    func processReceiptImage(_ image: UIImage) async throws -> ReceiptData {
        print("🔍 Processing receipt image with Apple Vision OCR (local)")
        
        do {
            // Try local Vision OCR first (faster and more accurate)
            let text = try await VisionOCRService.shared.extractText(from: image)
            print("✅ Vision OCR extracted text (\(text.count) chars)")
            
            let result = VisionOCRService.shared.parseReceiptText(text)
            print("✅ Parsed receipt: vendor=\(result.vendor), amount=\(result.amount)")
            
            // Upload image to backend for storage (but don't wait for OCR)
            Task {
                do {
                    let imageUrl = try await uploadReceiptImage(image)
                    print("✅ Image uploaded to backend: \(imageUrl)")
                } catch {
                    print("⚠️ Failed to upload image to backend (non-critical): \(error)")
                }
            }
            
            return result
            
        } catch {
            print("⚠️ Local Vision OCR failed: \(error.localizedDescription)")
            print("🔄 Falling back to backend OCR...")
            
            // Fallback to backend OCR
            let imageUrl = try await uploadReceiptImage(image)
            print("✅ Image uploaded: \(imageUrl)")
            return try await processReceiptImageURL(imageUrl)
        }
    }
    
    /// Upload receipt image to backend and return the URL
    private func uploadReceiptImage(_ image: UIImage) async throws -> String {
        print("📤 Uploading image to backend...")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to JPEG")
            throw AIServiceError.invalidImage
        }
        
        print("📦 Image data size: \(imageData.count) bytes")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        let endpoint = "\(APIService.shared.apiBaseURL)/upload/receipt"
        guard let url = URL(string: endpoint) else {
            print("❌ Invalid upload URL: \(endpoint)")
            throw AIServiceError.apiError("Invalid backend URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Add auth token
        if let token = UserDefaults.standard.string(forKey: "api_access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Auth token added to upload request")
        } else {
            print("⚠️ No auth token found for upload")
        }
        
        // Build multipart form data
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"receipt.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("📤 Sending upload request to: \(endpoint)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type from upload")
            throw AIServiceError.apiError("Invalid response from backend")
        }
        
        print("📥 Upload response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Upload error response: \(responseString)")
            }
            throw AIServiceError.apiError("Image upload failed: \(httpResponse.statusCode)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let imageURL = json["url"] as? String else {
            print("❌ Failed to parse upload response")
            throw AIServiceError.parseError("Invalid upload response")
        }
        
        print("✅ Image uploaded successfully: \(imageURL)")
        return imageURL
    }
    
    /// Process receipt image from URL using backend OCR
    func processReceiptImageURL(_ imageUrl: String) async throws -> ReceiptData {
        print("🔍 Starting OCR for image: \(imageUrl)")
        
        // Call backend OCR endpoint
        let endpoint = "\(APIService.shared.apiBaseURL)/receipts/ocr"
        guard let url = URL(string: endpoint) else {
            print("❌ Invalid backend URL: \(endpoint)")
            throw AIServiceError.apiError("Invalid backend URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = UserDefaults.standard.string(forKey: "api_access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Auth token added to request")
        } else {
            print("⚠️ No auth token found")
        }
        
        let payload: [String: Any] = ["imageUrl": imageUrl]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("📤 Sending OCR request to: \(endpoint)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw AIServiceError.apiError("Invalid response from backend")
        }
        
        print("📥 OCR response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Backend OCR error response: \(responseString)")
            }
            throw AIServiceError.apiError("Backend OCR error: \(httpResponse.statusCode)")
        }
        
        // Parse JSON response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse JSON response")
            throw AIServiceError.parseError("Invalid JSON response")
        }
        
        print("📦 OCR response JSON: \(json)")
        
        guard let success = json["success"] as? Bool, success else {
            let errorMsg = (json["error"] as? String) ?? "Unknown error"
            print("❌ OCR failed: \(errorMsg)")
            throw AIServiceError.parseError("OCR failed: \(errorMsg)")
        }
        
        guard let ocrData = json["data"] as? [String: Any] else {
            print("❌ No data in OCR response")
            throw AIServiceError.parseError("No data in OCR response")
        }
        
        // Parse backend response
        let vendor = (ocrData["vendor"] as? String) ?? "Unknown"
        let amount = (ocrData["amount"] as? Double) ?? (ocrData["amount"] as? NSNumber)?.doubleValue ?? 0.0
        let category = (ocrData["category"] as? String) ?? "Other"
        let confidence = (ocrData["confidence"] as? Double) ?? (ocrData["confidence"] as? NSNumber)?.doubleValue ?? 0.5
        
        print("✅ Parsed OCR data - Vendor: '\(vendor)', Amount: \(amount), Category: '\(category)', Confidence: \(confidence)")
        
        // Parse date
        let date: Date
        if let dateString = ocrData["date"] as? String {
            let formatter = ISO8601DateFormatter()
            date = formatter.date(from: dateString) ?? Date()
            print("📅 Parsed date: \(date) from string: \(dateString)")
        } else {
            date = Date()
            print("⚠️ No date in response, using current date")
        }
        
        let result = ReceiptData(
            amount: amount,
            vendor: vendor,
            category: category,
            date: date,
            confidence: confidence
        )
        
        print("✅ OCR complete - returning result")
        return result
    }
    
    // MARK: - Utility Methods for Receipt Analysis
    // MARK: - Utility Methods for Receipt Analysis
    
    /// Parse receipt text using regex patterns to extract vendor, amount, date
    /// Note: This is kept for backward compatibility but not actively used since backend handles OCR
    private func parseReceiptWithRegex(_ text: String) -> ReceiptData {
        var amount: Double = 0.0
        var vendor: String = "Unknown"
        var date: Date = Date()
        
        // Strategy: Find the LARGEST dollar amount - this is almost always the total
        // Receipts list items first, then subtotal, tax, and finally the TOTAL (largest)
        let allAmountsPattern = "\\$([0-9]+\\.[0-9]{2})"
        if let regex = try? NSRegularExpression(pattern: allAmountsPattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            var largestAmount: Double = 0
            for match in matches {
                if let range = Range(match.range(at: 1), in: text) {
                    let amountStr = String(text[range])
                    if let parsedAmount = Double(amountStr), parsedAmount > largestAmount {
                        largestAmount = parsedAmount
                    }
                }
            }
            if largestAmount > 0 {
                amount = largestAmount
            }
        }
        
        // Fallback: Try to find amount on same line as "Total" if no $ amounts found
        if amount == 0 {
            let totalPattern = "(?i)\\btotal\\b[^0-9\\n]*([0-9]+\\.[0-9]{2})"
            if let regex = try? NSRegularExpression(pattern: totalPattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let amountStr = String(text[range])
                if let parsedAmount = Double(amountStr), parsedAmount > 0 {
                    amount = parsedAmount
                }
            }
        }
        
        // Extract vendor - use first line (store name is usually at top)
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if let firstLine = lines.first {
            let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
            if !trimmed.contains("$") && trimmed.count > 2 {
                vendor = trimmed
            }
        }
        
        // Extract date - common formats
        let datePatterns = [
            "([0-9]{1,2}/[0-9]{1,2}/[0-9]{2,4})",
            "([0-9]{1,2}-[0-9]{1,2}-[0-9]{2,4})"
        ]
        
        let dateFormatters = [
            "MM/dd/yyyy", "M/d/yyyy", "MM/dd/yy", "M/d/yy",
            "MM-dd-yyyy", "M-d-yyyy", "MM-dd-yy", "M-d-yy"
        ]
        
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let dateStr = String(text[range])
                for format in dateFormatters {
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    formatter.locale = Locale(identifier: "en_US")
                    if let parsedDate = formatter.date(from: dateStr) {
                        date = parsedDate
                        break
                    }
                }
                break
            }
        }
        
        // Calculate confidence based on what was extracted
        var extractionConfidence: Double = 0.5 // Base confidence for OCR working
        
        if amount > 0 {
            extractionConfidence += 0.25 // Found amount
        }
        if vendor != "Unknown" && !vendor.isEmpty {
            extractionConfidence += 0.15 // Found vendor
        }
        if date != Date() { // If date was changed from default
            extractionConfidence += 0.10 // Found date
        }
        
        // Cap at 95% since regex isn't as accurate as AI
        let finalConfidence = min(extractionConfidence, 0.95)
        
        // Auto-categorize based on vendor
        let (category, _) = categorizeReceiptDetailed(vendor: vendor, amount: amount)
        
        return ReceiptData(
            amount: amount,
            vendor: vendor,
            category: category,
            date: date,
            confidence: finalConfidence
        )
    }
    
    /// Auto-categorize receipt based on vendor and amount (returns category and confidence)
    func categorizeReceiptDetailed(vendor: String, amount: Double) -> (category: String, confidence: Double) {
        let vendor = vendor.lowercased()
        
        // Category patterns with confidence scores
        let patterns: [(keywords: [String], category: String, confidence: Double)] = [
            (["home depot", "lowes", "lumber", "hardware", "builder"], "Materials", 0.95),
            (["gas", "fuel", "chevron", "shell", "mobile", "exxon"], "Fuel", 0.95),
            (["tool", "equipment", "supply", "compressor", "saw"], "Equipment", 0.90),
            (["food", "restaurant", "cafe", "lunch", "coffee"], "Meals", 0.90),
            (["office", "staples", "ink", "paper", "printer"], "Office", 0.85),
            (["hotel", "motel", "airbnb", "lodging"], "Travel", 0.90),
            (["uber", "taxi", "lyft", "parking"], "Transportation", 0.85),
            (["phone", "internet", "utility", "electric"], "Utilities", 0.85),
            (["insurance", "permit", "license"], "Professional", 0.90),
        ]
        
        for pattern in patterns {
            let matched = pattern.keywords.contains { keyword in
                vendor.contains(keyword)
            }
            if matched {
                return (pattern.category, pattern.confidence)
            }
        }
        
        // Default category
        return ("Other", 0.5)
    }
    
    /// Auto-categorize receipt based on vendor (returns just category for backward compatibility)
    func categorizeReceipt(vendor: String, amount: Double) -> String {
        return categorizeReceiptDetailed(vendor: vendor, amount: amount).category
    }
    
    /// Check for receipt anomalies and generate flags
    func analyzeReceipt(_ receipt: Receipt, allReceipts: [Receipt]) -> [String] {
        var flags: [String] = []
        
        let receiptAmount = receipt.amount ?? 0
        let receiptVendor = receipt.vendor ?? ""
        let receiptCategory = receipt.category ?? ""
        let receiptDate = receipt.date ?? Date()
        let receiptNotes = receipt.notes ?? ""
        
        // Check for duplicate
        let duplicates = allReceipts.filter {
            $0.id != receipt.id &&
            ($0.vendor ?? "") == receiptVendor &&
            abs(($0.amount ?? 0) - receiptAmount) < 1.0 &&
            Calendar.current.isDate($0.date ?? Date(), inSameDayAs: receiptDate)
        }
        
        if !duplicates.isEmpty {
            flags.append("possible_duplicate")
        }
        
        // Check for unusual amount
        let similarReceipts = allReceipts.filter { ($0.category ?? "") == receiptCategory }
        if !similarReceipts.isEmpty {
            let avgAmount = similarReceipts.compactMap { $0.amount }.reduce(0, +) / Double(similarReceipts.count)
            if receiptAmount > avgAmount * 3 {
                flags.append("unusually_high")
            }
        }
        
        // Check for missing info
        if receiptVendor.isEmpty || receiptVendor == "Unknown" {
            flags.append("missing_vendor")
        }
        
        // Check for potential refund
        if receiptAmount < 0 || receiptVendor.lowercased().contains("refund") || receiptNotes.lowercased().contains("refund") {
            flags.append("possible_refund")
        }
        
        return flags
    }
    
    // MARK: - Duplicate Detection
    
    /// Detect potential duplicate receipts with detailed similarity scoring
    /// Returns array of tuples: (duplicateReceipt, similarityScore)
    func detectDuplicates(_ receipt: Receipt, in allReceipts: [Receipt]) -> [(receipt: Receipt, similarity: Double)] {
        var duplicates: [(receipt: Receipt, similarity: Double)] = []
        
        let receiptVendor = (receipt.vendor ?? "").lowercased()
        let receiptAmount = receipt.amount ?? 0
        let receiptDate = receipt.date ?? Date()
        let receiptCategory = receipt.category ?? ""
        
        for existingReceipt in allReceipts {
            // Skip self-comparison (only if both have IDs and they match)
            if let receiptId = receipt.id, let existingId = existingReceipt.id, receiptId == existingId {
                continue
            }
            
            let existingVendor = (existingReceipt.vendor ?? "").lowercased()
            let existingAmount = existingReceipt.amount ?? 0
            let existingDate = existingReceipt.date ?? Date()
            let existingCategory = existingReceipt.category ?? ""
            
            var similarityScore: Double = 0.0
            
            // Vendor match (40% weight)
            if receiptVendor == existingVendor {
                similarityScore += 0.4
            } else if receiptVendor.contains(existingVendor) || existingVendor.contains(receiptVendor) {
                similarityScore += 0.2
            }
            
            // Amount match (30% weight)
            let amountDiff = abs(receiptAmount - existingAmount)
            if amountDiff < 0.01 {
                similarityScore += 0.3
            } else if amountDiff < 1.0 {
                similarityScore += 0.2
            } else if amountDiff < 5.0 {
                similarityScore += 0.1
            }
            
            // Date match (20% weight)
            let daysDiff = abs(Calendar.current.dateComponents([.day], from: receiptDate, to: existingDate).day ?? 999)
            if daysDiff == 0 {
                similarityScore += 0.2
            } else if daysDiff == 1 {
                similarityScore += 0.1
            } else if daysDiff <= 3 {
                similarityScore += 0.05
            }
            
            // Category match (10% weight)
            if receiptCategory == existingCategory {
                similarityScore += 0.1
            }
            
            // Flag as duplicate if similarity > 70%
            if similarityScore >= 0.7 {
                duplicates.append((existingReceipt, similarityScore))
            }
        }
        
        // Sort by similarity descending
        return duplicates.sorted { $0.similarity > $1.similarity }
    }
    
    /// Check if receipt is likely a refund
    func isLikelyRefund(_ receipt: Receipt) -> Bool {
        let amount = receipt.amount ?? 0
        let vendor = receipt.vendor ?? ""
        let notes = receipt.notes ?? ""
        
        // Negative amount
        if amount < 0 {
            return true
        }
        
        // Keywords in vendor or notes
        let refundKeywords = ["refund", "return", "credit", "reversal", "reimburse"]
        let textToCheck = (vendor + " " + notes).lowercased()
        
        return refundKeywords.contains { textToCheck.contains($0) }
    }
    
    /// Generate detailed duplicate alert message
    func generateDuplicateAlertMessage(for receipt: Receipt, duplicates: [(receipt: Receipt, similarity: Double)]) -> String {
        let topDuplicate = duplicates.first!
        let similarityPercent = Int(topDuplicate.similarity * 100)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let dupAmount = topDuplicate.receipt.amount ?? 0
        let dupVendor = topDuplicate.receipt.vendor ?? "Unknown"
        let dupDate = topDuplicate.receipt.date ?? Date()
        
        let message = """
        This receipt appears \(similarityPercent)% similar to an existing receipt:
        
        Original: $\(String(format: "%.2f", dupAmount)) at \(dupVendor)
        Date: \(dateFormatter.string(from: dupDate))
        
        If this is not a duplicate, you can proceed. Otherwise, consider editing or deleting one.
        """
        
        return message
    }
    
    // MARK: - Alert Generation
    
    /// Generate budget alerts for jobs based on labor cost vs project value
    /// Note: Receipts are documents only and do NOT affect profit/budget calculations
    func generateBudgetAlerts(for job: Job, timesheets: [Timesheet], workers: [User]) async throws {
        let jobTimesheets = timesheets.filter { $0.jobID == job.id }
        
        // Calculate labor cost from timesheets
        var laborCost: Double = 0
        for timesheet in jobTimesheets {
            if let hours = timesheet.hours,
               let worker = workers.first(where: { $0.id == timesheet.workerID }),
               let hourlyRate = worker.hourlyRate {
                laborCost += hours * hourlyRate
            }
        }
        
        // NEW PROFIT FORMULA: profit = projectValue - laborCost
        let profit = job.projectValue - laborCost
        let laborRatio = job.projectValue > 0 ? laborCost / job.projectValue : 0
        
        // Alert if labor cost exceeds project value
        if laborRatio > 1.0 {
            let alert = Alert(
                ownerID: job.ownerID,
                jobID: job.id,
                type: .budget,
                severity: .critical,
                title: "Labor Cost Exceeded Budget",
                message: "Job '\(job.jobName)' labor cost exceeds project value by \(Int((laborRatio - 1.0) * 100))%",
                actionURL: "siteledger://job/\(job.id ?? "")",
                read: false,
                createdAt: Date()
            )
            
            try await saveAlert(alert)
        }
        // Alert if approaching budget
        else if laborRatio > 0.85 {
            let alert = Alert(
                ownerID: job.ownerID,
                jobID: job.id,
                type: .budget,
                severity: .warning,
                title: "Approaching Labor Budget Limit",
                message: "Job '\(job.jobName)' labor cost has used \(Int(laborRatio * 100))% of project value",
                actionURL: "siteledger://job/\(job.id ?? "")",
                read: false,
                createdAt: Date()
            )
            
            try await saveAlert(alert)
        }
        
        // Alert if profit margin is low
        let profitMargin = job.projectValue > 0 ? profit / job.projectValue : 0
        if profitMargin < 0.1 && profit > 0 {
            let alert = Alert(
                ownerID: job.ownerID,
                jobID: job.id,
                type: .budget,
                severity: .warning,
                title: "Low Profit Margin",
                message: "Job '\(job.jobName)' has a profit margin of only \(Int(profitMargin * 100))%",
                actionURL: "siteledger://job/\(job.id ?? "")",
                read: false,
                createdAt: Date()
            )
            
            try await saveAlert(alert)
        }
    }
    
    /// Generate payment reminders
    func generatePaymentAlerts(for job: Job) async throws {
        let remainingBalance = job.projectValue - job.amountPaid
        let paymentRatio = job.amountPaid / job.projectValue
        
        // Alert if client owes money on completed job
        if job.status == .completed && remainingBalance > 0 {
            let alert = Alert(
                ownerID: job.ownerID,
                jobID: job.id,
                type: .payment,
                severity: .warning,
                title: "Payment Due",
                message: "Client owes $\(String(format: "%.2f", remainingBalance)) for completed job '\(job.jobName)'",
                actionURL: "siteledger://job/\(job.id ?? "")",
                read: false,
                createdAt: Date()
            )
            
            try await saveAlert(alert)
        }
        // Alert if payment is significantly behind
        else if paymentRatio < 0.5 && job.status == .active {
            let alert = Alert(
                ownerID: job.ownerID,
                jobID: job.id,
                type: .payment,
                severity: .info,
                title: "Request Progress Payment",
                message: "Consider requesting a progress payment for job '\(job.jobName)'",
                actionURL: "siteledger://job/\(job.id ?? "")",
                read: false,
                createdAt: Date()
            )
            
            try await saveAlert(alert)
        }
    }
    
    /// Generate timesheet alerts
    func generateTimesheetAlerts(for timesheet: Timesheet, job: Job) async throws {
        var flags: [String] = []
        
        let ownerID = timesheet.ownerID ?? ""
        let jobID = timesheet.jobID
        let timesheetID = timesheet.id ?? ""
        let clockIn = timesheet.clockIn ?? Date()
        
        // Check for unusually long shifts
        if let hours = timesheet.hours, hours > 12 {
            flags.append("unusually_long_shift")
            
            let alert = Alert(
                ownerID: ownerID,
                jobID: jobID,
                type: .timesheet,
                severity: .warning,
                title: "Long Work Shift",
                message: "Worker logged \(Int(hours)) hours on job '\(job.jobName)'",
                actionURL: "siteledger://timesheet/\(timesheetID)",
                read: false,
                createdAt: Date()
            )
            
            try await saveAlert(alert)
        }
        
        // Check if worker forgot to clock out (shift > 14 hours and still working)
        if timesheet.status == "working" {
            let hoursSinceClockIn = Date().timeIntervalSince(clockIn) / 3600.0
            if hoursSinceClockIn > 14 {
                flags.append("forgot_clock_out")
                
                let alert = Alert(
                    ownerID: ownerID,
                    jobID: jobID,
                    type: .timesheet,
                    severity: .warning,
                    title: "Possible Missed Clock Out",
                    message: "Worker may have forgotten to clock out \(Int(hoursSinceClockIn)) hours ago",
                    actionURL: "siteledger://timesheet/\(timesheetID)",
                    read: false,
                    createdAt: Date()
                )
                
                try await saveAlert(alert)
            }
        }
        
        // Update timesheet with AI flags
        if !flags.isEmpty {
            // TODO: Update via API when needed
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveAlert(_ alert: Alert) async throws {
        // TODO: Save via API when alerts feature is implemented
    }
    
    // MARK: - Document Processing (Stub - Not Implemented)
    // These are placeholder structs for backward compatibility
    // Document processing feature is not yet implemented with backend API
    
    struct DocumentData {
        let summary: String
        let extractedText: String
        let confidence: Double
    }
    
    struct DocumentProcessingResult {
        let documentType: String
        let title: String
        let extractedData: [String: String]
        let summary: String
        let confidence: Double
        let flags: [String]
    }
    
    /// Document processing not yet implemented with backend API
    func processDocumentImage(_ image: UIImage) async throws -> DocumentProcessingResult {
        throw AIServiceError.apiError("Document processing feature not yet implemented")
    }
}

// MARK: - Error Handling

enum AIServiceError: LocalizedError {
    case invalidImage
    case apiError(String)
    case parseError(String)
    case invalidCredentials
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .apiError(let message):
            return message
        case .parseError(let message):
            return "Failed to parse response: \(message)"
        case .invalidCredentials:
            return "Invalid API credentials"
        case .rateLimited:
            return "API rate limit exceeded. Please try again later."
        }
    }
}
