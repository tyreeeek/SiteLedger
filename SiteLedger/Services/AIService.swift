import Foundation
import UIKit

/// AI Service for receipt processing, anomaly detection, and alerts
/// Integrates with backend API for AI features
class AIService {
    static let shared = AIService()
    private let keyManager = APIKeyManager.shared
    
    // MARK: - API Configuration (Fetched from APIKeyManager)
    
    /// OpenRouter API key - fetched securely from Remote Config
    private var openAIApiKey: String {
        keyManager.openRouterAPIKey
    }
    
    /// OpenRouter endpoint
    private var openAIEndpoint: String {
        keyManager.openRouterEndpoint
    }
    
    /// AI model name
    private var model: String {
        keyManager.aiModelName
    }
    
    /// OCR.space API key - fetched securely from Remote Config
    private var ocrSpaceApiKey: String {
        keyManager.ocrSpaceAPIKey
    }
    
    /// OCR.space endpoint
    private var ocrSpaceEndpoint: String {
        keyManager.ocrSpaceEndpoint
    }
    
    // Allow public initialization for ViewModels
    init() {}
    
    // MARK: - Receipt Processing with OCR.space
    
    /// Process receipt image: OCR.space extracts text, then regex parses it
    /// Note: OpenRouter AI is only for insights/chat, not receipt parsing
    func processReceiptImage(_ image: UIImage) async throws -> ReceiptData {
        // Step 1: Extract text from receipt using OCR.space
        let ocrText = try await extractTextWithOCRSpace(image)
        
        // Step 2: Parse with regex (no AI needed for basic receipt data)
        let data = parseReceiptWithRegex(ocrText)
        return data
    }
    
    /// Parse receipt text using regex patterns to extract vendor, amount, date
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
    
    /// Extract text from receipt image using OCR.space API
    private func extractTextWithOCRSpace(_ image: UIImage) async throws -> String {
        // Compress image to stay under 1MB limit (OCR.space free tier limit is 1024KB)
        var imageData = image.jpegData(compressionQuality: 0.8)
        var compressionQuality: CGFloat = 0.8
        
        // Keep reducing quality until we're under 1MB (1024 * 1024 bytes)
        while let data = imageData, data.count > 1_000_000 && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = image.jpegData(compressionQuality: compressionQuality)
        }
        
        guard let finalImageData = imageData, finalImageData.count > 0 else {
            throw AIServiceError.invalidImage
        }
        
        // If still too large after max compression, resize the image
        var processedImageData = finalImageData
        if finalImageData.count > 1_000_000 {
            // Resize image to reduce file size
            let maxDimension: CGFloat = 1500
            let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            guard let resized = resizedImage,
                  let resizedData = resized.jpegData(compressionQuality: 0.7) else {
                throw AIServiceError.invalidImage
            }
            processedImageData = resizedData
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        guard let ocrURL = URL(string: ocrSpaceEndpoint) else {
            throw AIServiceError.apiError("Invalid OCR.space endpoint configuration")
        }
        var request = URLRequest(url: ocrURL)
        request.httpMethod = "POST"
        request.addValue(ocrSpaceApiKey, forHTTPHeaderField: "apikey")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"receipt.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(processedImageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add language parameter (English)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("eng\r\n".data(using: .utf8)!)
        
        // Add OCR engine (2 = advanced engine with better accuracy)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"OCREngine\"\r\n\r\n".data(using: .utf8)!)
        body.append("2\r\n".data(using: .utf8)!)
        
        // Add scale parameter for better quality
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"scale\"\r\n\r\n".data(using: .utf8)!)
        body.append("true\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.apiError("Invalid response from OCR.space")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIServiceError.apiError("OCR.space API error: \(httpResponse.statusCode)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIServiceError.parseError("Invalid JSON from OCR.space")
        }
        
        // Check for errors
        if let errorMessage = json["ErrorMessage"] as? [String], !errorMessage.isEmpty {
            throw AIServiceError.apiError("OCR.space error: \(errorMessage.joined(separator: ", "))")
        }
        
        // Extract parsed text
        guard let parsedResults = json["ParsedResults"] as? [[String: Any]],
              let firstResult = parsedResults.first,
              let parsedText = firstResult["ParsedText"] as? String else {
            throw AIServiceError.parseError("Could not extract text from OCR.space response")
        }
        
        guard !parsedText.isEmpty else {
            throw AIServiceError.parseError("OCR.space returned empty text - image may be too blurry")
        }
        
        return parsedText
    }
    
    /// Analyze text with OpenRouter AI
    private func analyzeTextWithAI(_ prompt: String) async throws -> String {
        guard let aiURL = URL(string: openAIEndpoint) else {
            throw AIServiceError.apiError("Invalid OpenRouter endpoint configuration")
        }
        var request = URLRequest(url: aiURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(openAIApiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": "You are a receipt parsing assistant. Extract structured data from receipt text and respond only with valid JSON."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 1024,
            "temperature": 0.1 // Low temperature for consistent, factual responses
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIServiceError.apiError("Failed to call OpenRouter API")
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        throw AIServiceError.parseError("Could not extract response from OpenRouter")
    }
    
    /// Parse AI response into ReceiptData
    private func parseReceiptResponse(_ response: String) throws -> ReceiptData {
        // Extract JSON from response (may be wrapped in markdown code blocks)
        let jsonString: String
        if let jsonStart = response.range(of: "{"),
           let jsonEnd = response.range(of: "}", options: .backwards) {
            jsonString = String(response[jsonStart.lowerBound..<jsonEnd.upperBound])
        } else {
            jsonString = response
        }
        
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw AIServiceError.parseError("Invalid JSON response")
        }
        
        let vendor = (json["vendor"] as? String) ?? "Unknown"
        let amount = (json["amount"] as? NSNumber)?.doubleValue ?? 0.0
        let category = (json["category"] as? String) ?? "Other"
        let confidence = (json["confidence"] as? NSNumber)?.doubleValue ?? 0.5
        let dateString = json["date"] as? String
        
        // Parse date
        let date: Date
        if let dateStr = dateString {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            date = formatter.date(from: dateStr) ?? Date()
        } else {
            date = Date()
        }
        
        return ReceiptData(
            amount: amount,
            vendor: vendor,
            category: category,
            date: date,
            confidence: confidence
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
    
    // MARK: - Document Processing (Phase 8)
    
    /// Process document image: OCR + AI analysis for contracts, invoices, estimates, etc.
    func processDocumentImage(_ image: UIImage) async throws -> DocumentProcessingResult {
        // Step 1: Extract text from document using OCR.space
        let ocrText = try await extractTextWithOCRSpace(image)
        
        // Step 2: Analyze extracted text with AI to classify and extract data
        let prompt = """
        Analyze this document text and extract information in JSON format:
        {
            "documentType": "contract|invoice|estimate|permit|receipt|photo|blueprint|other",
            "title": "descriptive title for the document",
            "extractedData": {
                "amount": "total amount if applicable",
                "date": "date in YYYY-MM-DD format",
                "clientName": "client or vendor name",
                "projectDescription": "brief description",
                "contractNumber": "contract/invoice number if present",
                "terms": "payment terms or key terms",
                "expiryDate": "expiry date if applicable"
            },
            "summary": "2-3 sentence summary of the document",
            "confidence": "confidence score 0-1",
            "flags": ["list of any issues: low_quality, missing_signature, expired, incomplete"]
        }
        
        Document text:
        \(ocrText)
        
        Guidelines:
        - Identify document type based on keywords (e.g., "Agreement", "Invoice", "Estimate", "Permit")
        - Extract all monetary amounts, dates, names, and key terms
        - Generate a clear, concise summary
        - Flag any quality issues or missing critical information
        - If a field cannot be determined, set to null or empty
        
        Respond ONLY with valid JSON, no additional text.
        """
        
        let response = try await analyzeTextWithAI(prompt)
        let result = try parseDocumentResponse(response)
        return result
    }
    
    /// Parse AI response for document analysis
    private func parseDocumentResponse(_ response: String) throws -> DocumentProcessingResult {
        // Remove markdown code blocks if present
        var jsonString = response
        if jsonString.contains("```json") {
            jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
            jsonString = jsonString.replacingOccurrences(of: "```", with: "")
        }
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = jsonString.data(using: .utf8) else {
            throw AIServiceError.parseError("Failed to convert response to data")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json = json else {
            throw AIServiceError.parseError("Invalid JSON structure")
        }
        
        // Parse document type
        let documentTypeString = json["documentType"] as? String ?? "other"
        let documentType = Document.DocumentCategory(rawValue: documentTypeString) ?? .other
        
        // Parse extracted data
        let extractedDataDict = json["extractedData"] as? [String: Any] ?? [:]
        var extractedData: [String: String] = [:]
        for (key, value) in extractedDataDict {
            if let stringValue = value as? String {
                extractedData[key] = stringValue
            } else if let numberValue = value as? NSNumber {
                extractedData[key] = numberValue.stringValue
            }
        }
        
        // Parse other fields
        let title = json["title"] as? String ?? "Untitled Document"
        let summary = json["summary"] as? String ?? ""
        let confidence = json["confidence"] as? Double ?? 0.5
        let flags = json["flags"] as? [String] ?? []
        
        return DocumentProcessingResult(
            documentType: documentType,
            title: title,
            extractedData: extractedData,
            summary: summary,
            confidence: confidence,
            flags: flags
        )
    }
    
    // MARK: - Helper Methods
    
    private func saveAlert(_ alert: Alert) async throws {
        // TODO: Save via API when alerts feature is implemented
    }
    
    // MARK: - Data Models (Public for ViewModels)
    
    struct ReceiptData {
        let amount: Double
        let vendor: String
        let category: String
        let date: Date
        let confidence: Double
    }
    
    struct DocumentData {
        let summary: String
        let extractedText: String
        let confidence: Double
    }
    
    struct DocumentProcessingResult {
        let documentType: Document.DocumentCategory
        let title: String
        let extractedData: [String: String]
        let summary: String
        let confidence: Double
        let flags: [String]
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
            return "Failed to parse AI response: \(message)"
        case .invalidCredentials:
            return "Invalid OpenAI API credentials"
        case .rateLimited:
            return "API rate limit exceeded. Please try again later."
        }
    }
}
