import Foundation
import UIKit
import Vision

/// Native iOS OCR service using Apple's Vision framework
/// Provides fast, accurate, offline receipt text recognition
class VisionOCRService {
    static let shared = VisionOCRService()
    
    private init() {}
    
    /// Extract text from receipt image using Apple Vision framework
    /// - Parameter image: The receipt image to process
    /// - Returns: Extracted text as a single string
    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.visionError(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                // Combine all recognized text with line breaks
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                if recognizedText.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    print("📄 Vision OCR extracted \(recognizedText.count) characters, \(observations.count) lines")
                    continuation.resume(returning: recognizedText)
                }
            }
            
            // Configure for accurate text recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]
            
            // Perform the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.visionError(error.localizedDescription))
            }
        }
    }
    
    /// Parse receipt text to extract structured data
    /// - Parameter text: Raw OCR text
    /// - Returns: Parsed receipt data
    func parseReceiptText(_ text: String) -> ReceiptData {
        print("🔍 Parsing receipt text (\(text.count) chars)")
        
        let vendor = extractVendor(from: text)
        let amount = extractAmount(from: text)
        let date = extractDate(from: text)
        let category = suggestCategory(from: text)
        
        print("✅ Parsed: vendor=\(vendor), amount=\(amount), date=\(date), category=\(category)")
        
        return ReceiptData(
            amount: amount,
            vendor: vendor,
            category: category,
            date: date,
            confidence: 0.92 // Vision framework typically has high confidence
        )
    }
    
    // MARK: - Text Extraction Helpers
    
    private func extractVendor(from text: String) -> String {
        let lines = text.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }
        
        // Common vendor patterns (case-insensitive)
        let knownVendors = [
            "walmart", "target", "home depot", "lowe's", "lowes", "marshalls", "marshall's",
            "tj maxx", "tjmaxx", "costco", "sam's club", "kroger", "safeway", "publix",
            "whole foods", "trader joe's", "best buy", "staples", "office depot",
            "cvs", "walgreens", "rite aid", "shell", "exxon", "chevron"
        ]
        
        // Check first few lines for known vendors
        for line in lines.prefix(5) {
            let lowerLine = line.lowercased()
            for vendor in knownVendors {
                if lowerLine.contains(vendor) {
                    // Return the actual line (with proper capitalization) if it's reasonable length
                    if line.count <= 50 {
                        return line
                    }
                    // Otherwise return the matched vendor name
                    return vendor.capitalized
                }
            }
        }
        
        // Fallback: use first non-empty, non-numeric line
        if let firstLine = lines.first(where: { !$0.isEmpty && !$0.allSatisfy({ $0.isNumber || $0 == " " }) }) {
            return String(firstLine.prefix(50))
        }
        
        return "Unknown Vendor"
    }
    
    private func extractAmount(from text: String) -> Double {
        let lines = text.split(separator: "\n").map { String($0) }
        
        // STRATEGY 1: Look for "Total" line (most reliable)
        let totalPatterns: [(String, NSRegularExpression?)] = [
            ("total", try? NSRegularExpression(pattern: "(?i)total.*?\\$?\\s*(\\d{1,6}[.,]\\d{2})", options: [])),
            ("grand total", try? NSRegularExpression(pattern: "(?i)grand\\s*total.*?\\$?\\s*(\\d{1,6}[.,]\\d{2})", options: [])),
            ("amount due", try? NSRegularExpression(pattern: "(?i)amount\\s*due.*?\\$?\\s*(\\d{1,6}[.,]\\d{2})", options: [])),
            ("balance", try? NSRegularExpression(pattern: "(?i)balance.*?\\$?\\s*(\\d{1,6}[.,]\\d{2})", options: []))
        ]
        
        for (patternName, regex) in totalPatterns {
            guard let regex = regex else { continue }
            
            // Check each line for total patterns
            for line in lines {
                let range = NSRange(line.startIndex..., in: line)
                if let match = regex.firstMatch(in: line, options: [], range: range),
                   match.numberOfRanges > 1,
                   let amountRange = Range(match.range(at: 1), in: line) {
                    let amountStr = String(line[amountRange]).replacingOccurrences(of: ",", with: "")
                    if let amount = Double(amountStr), amount > 0 {
                        print("💰 Found amount via '\(patternName)' pattern: \(amount) in line: '\(line)'")
                        return amount
                    }
                }
            }
        }
        
        // STRATEGY 2: Find all dollar amounts and return the LARGEST (usually the total)
        print("⚠️ No 'total' keyword found, using largest amount fallback")
        
        let amountPattern = try? NSRegularExpression(pattern: "\\$?\\s*(\\d{1,6}[.,]\\d{2})\\b", options: [])
        var allAmounts: [Double] = []
        
        for line in lines {
            let range = NSRange(line.startIndex..., in: line)
            if let pattern = amountPattern {
                let matches = pattern.matches(in: line, options: [], range: range)
                for match in matches {
                    if match.numberOfRanges > 1,
                       let amountRange = Range(match.range(at: 1), in: line) {
                        let amountStr = String(line[amountRange]).replacingOccurrences(of: ",", with: "")
                        if let amount = Double(amountStr), amount > 0.01 && amount < 100000 {
                            allAmounts.append(amount)
                        }
                    }
                }
            }
        }
        
        if !allAmounts.isEmpty {
            let largestAmount = allAmounts.max() ?? 0
            print("💰 Found \(allAmounts.count) amounts, largest: \(largestAmount)")
            return largestAmount
        }
        
        print("❌ No valid amounts found in receipt")
        return 0.0
    }
    
    private func extractDate(from text: String) -> Date {
        let datePatterns = [
            try? NSRegularExpression(pattern: "(\\d{1,2})[-/](\\d{1,2})[-/](\\d{2,4})", options: []),
            try? NSRegularExpression(pattern: "(\\d{4})[-/](\\d{1,2})[-/](\\d{1,2})", options: []),
            try? NSRegularExpression(pattern: "(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\\w*\\s+(\\d{1,2}),?\\s+(\\d{4})", options: .caseInsensitive)
        ]
        
        for pattern in datePatterns {
            guard let regex = pattern else { continue }
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range),
               let matchRange = Range(match.range, in: text) {
                let dateStr = String(text[matchRange])
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yyyy"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                
                if let date = formatter.date(from: dateStr) {
                    return date
                }
                
                // Try other formats
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: dateStr) {
                    return date
                }
            }
        }
        
        return Date() // Default to today
    }
    
    private func suggestCategory(from text: String) -> String {
        let lowerText = text.lowercased()
        
        let categories: [String: [String]] = [
            "materials": ["hardware", "lumber", "building", "supply", "depot", "lowes", "home depot", "construction"],
            "equipment": ["tools", "equipment", "rental", "machinery", "tractor"],
            "fuel": ["gas", "fuel", "diesel", "shell", "exxon", "chevron", "petrol", "station"],
            "subcontractors": ["contractor", "subcontractor", "labor", "plumbing", "electric", "hvac"]
        ]
        
        for (category, keywords) in categories {
            if keywords.contains(where: { lowerText.contains($0) }) {
                return category
            }
        }
        
        return "misc"
    }
}

// MARK: - Error Types

enum OCRError: LocalizedError {
    case invalidImage
    case visionError(String)
    case noTextFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .visionError(let message):
            return "Vision framework error: \(message)"
        case .noTextFound:
            return "No text found in image"
        }
    }
}
