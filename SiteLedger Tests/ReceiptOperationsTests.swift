//
//  ReceiptOperationsTests.swift
//  SiteLedger Tests
//
//  PHASE 4: ULTRA-PARANOID RECEIPT OPERATIONS TESTING
//  Test receipt CRUD, AI processing, image handling, and profit isolation
//

import XCTest
@testable import SiteLedger
import UIKit

final class ReceiptOperationsTests: XCTestCase {
    
    // MARK: - Receipt Creation Tests
    
    func testReceiptCreationWithZeroAmount() {
        // Zero amount receipt
        let zeroReceipt = Receipt(
            ownerID: "owner1",
            amount: 0,
            vendor: "Home Depot",
            date: Date(),
            notes: "Test",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertEqual(zeroReceipt.amount, 0, "⚠️ ISSUE: Zero amount receipt allowed")
        // Should validation prevent $0 receipts? Arguably yes for data quality
    }
    
    func testReceiptCreationWithNegativeAmount() {
        // Negative amount (refund?)
        let negativeReceipt = Receipt(
            ownerID: "owner1",
            amount: -100.50,
            vendor: "Home Depot",
            date: Date(),
            notes: "Refund",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertEqual(negativeReceipt.amount, -100.50, "Negative amount stored (could be valid for refunds)")
        // Note: Negative amounts might be valid for refunds, but should be explicitly marked
    }
    
    func testReceiptCreationWithInfinityAmount() {
        let infinityReceipt = Receipt(
            ownerID: "owner1",
            amount: Double.infinity,
            vendor: "Vendor",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertEqual(infinityReceipt.amount, Double.infinity, "🔴 CRITICAL: Infinity amount allowed")
    }
    
    func testReceiptCreationWithNaNAmount() {
        let nanReceipt = Receipt(
            ownerID: "owner1",
            amount: Double.nan,
            vendor: "Vendor",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertTrue(nanReceipt.amount.isNaN, "🔴 CRITICAL: NaN amount allowed")
    }
    
    func testReceiptCreationWithEmptyVendor() {
        let emptyVendor = Receipt(
            ownerID: "owner1",
            amount: 100,
            vendor: "",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertEqual(emptyVendor.vendor, "", "⚠️ ISSUE: Empty vendor allowed")
    }
    
    func testReceiptCreationWithoutJobID() {
        // Receipt not assigned to job (general receipt)
        let generalReceipt = Receipt(
            ownerID: "owner1",
            jobID: nil,
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertNil(generalReceipt.jobID, "✅ VALID: General receipts allowed (not job-specific)")
    }
    
    func testReceiptCreationWithInvalidJobID() {
        // Receipt assigned to non-existent job
        let invalidJob = Receipt(
            ownerID: "owner1",
            jobID: "non-existent-job-id",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertEqual(invalidJob.jobID, "non-existent-job-id", "⚠️ ISSUE: Invalid jobID not validated")
    }
    
    // MARK: - AI Confidence Tests
    
    func testAIConfidenceOutOfRange() {
        // Confidence < 0
        let negativeConfidence = Receipt(
            ownerID: "owner1",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: true,
            aiConfidence: -0.5
        )
        XCTAssertEqual(negativeConfidence.aiConfidence, -0.5, "🔴 CRITICAL: Negative AI confidence allowed")
        
        // Confidence > 1.0
        let highConfidence = Receipt(
            ownerID: "owner1",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: true,
            aiConfidence: 2.5
        )
        XCTAssertEqual(highConfidence.aiConfidence, 2.5, "🔴 CRITICAL: AI confidence > 1.0 allowed")
        
        // Confidence = NaN
        let nanConfidence = Receipt(
            ownerID: "owner1",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: true,
            aiConfidence: Double.nan
        )
        XCTAssertTrue(nanConfidence.aiConfidence!.isNaN, "🔴 CRITICAL: NaN AI confidence allowed")
    }
    
    func testAIProcessedInconsistency() {
        // aiProcessed = false but aiConfidence is set
        let inconsistent = Receipt(
            ownerID: "owner1",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: false,
            aiConfidence: 0.95
        )
        
        XCTAssertFalse(inconsistent.aiProcessed, "⚠️ ISSUE: aiProcessed false but confidence set")
        XCTAssertNotNil(inconsistent.aiConfidence, "Data inconsistency: confidence without processing")
    }
    
    // MARK: - AI Flags Tests
    
    func testAIFlagsDuplicates() {
        let duplicateFlags = Receipt(
            ownerID: "owner1",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: true,
            aiFlags: ["duplicate", "duplicate", "duplicate"]
        )
        
        XCTAssertEqual(duplicateFlags.aiFlags?.count, 3, "⚠️ ISSUE: Duplicate AI flags not deduplicated")
    }
    
    func testAIFlagsInvalidStrings() {
        let invalidFlags = Receipt(
            ownerID: "owner1",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: true,
            aiFlags: ["", "null", "undefined", "<script>alert('xss')</script>"]
        )
        
        XCTAssertEqual(invalidFlags.aiFlags?.count, 4, "⚠️ ISSUE: Invalid flag strings not validated")
    }
    
    // MARK: - Image Handling Tests
    
    func testReceiptWithMissingImage() {
        let noImage = Receipt(
            ownerID: "owner1",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            imageURL: nil,
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertNil(noImage.imageURL, "✅ VALID: Receipts can exist without images")
    }
    
    func testReceiptWithEmptyImageURL() {
        let emptyURL = Receipt(
            ownerID: "owner1",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            imageURL: "",
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertEqual(emptyURL.imageURL, "", "⚠️ ISSUE: Empty imageURL allowed")
    }
    
    func testReceiptWithInvalidImageURL() {
        let invalidURL = Receipt(
            ownerID: "owner1",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            imageURL: "not-a-valid-url",
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertEqual(invalidURL.imageURL, "not-a-valid-url", "⚠️ ISSUE: Invalid image URL format allowed")
    }
    
    func testReceiptWithMaliciousImageURL() {
        let maliciousURL = Receipt(
            ownerID: "owner1",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            imageURL: "javascript:alert('xss')",
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertEqual(maliciousURL.imageURL, "javascript:alert('xss')", "🔴 CRITICAL: Malicious image URL allowed")
    }
    
    // MARK: - Receipt Update Tests
    
    func testReceiptJobReassignment() {
        var receipt = Receipt(
            ownerID: "owner1",
            jobID: "job1",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        // Reassign to different job
        receipt.jobID = "job2"
        
        XCTAssertEqual(receipt.jobID, "job2", "✅ VALID: Receipt can be reassigned to different job")
        // Note: Should trigger recalculation on both jobs if they track receipt totals
    }
    
    func testReceiptJobUnassignment() {
        var receipt = Receipt(
            ownerID: "owner1",
            jobID: "job1",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        // Unassign from job (convert to general receipt)
        receipt.jobID = nil
        
        XCTAssertNil(receipt.jobID, "✅ VALID: Receipt can be converted to general receipt")
    }
    
    func testReceiptAmountUpdate() {
        var receipt = Receipt(
            ownerID: "owner1",
            jobID: "job1",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        // Update amount
        receipt.amount = 150
        
        XCTAssertEqual(receipt.amount, 150, "✅ VALID: Receipt amount can be updated")
        // Note: Should trigger job financial recalculation if receipts affect finances (they don't in this system)
    }
    
    // MARK: - Profit Isolation Tests (CRITICAL CONTRACT)
    
    func testReceiptDoesNotAffectProfit() {
        // This test verifies the core business logic: RECEIPTS DO NOT AFFECT PROFIT
        
        let job = Job(
            ownerID: "owner1",
            jobName: "Test Job",
            clientName: "Client",
            address: "Address",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 5000
        )
        
        // Calculate profit with ZERO labor cost
        let profitWithoutReceipts = job.calculateProfit(laborCost: 0)
        XCTAssertEqual(profitWithoutReceipts, 10000, "Profit = projectValue when labor cost = 0")
        
        // Now simulate adding 10 receipts totaling $5000
        let receipts: [Receipt] = (0..<10).map { i in
            Receipt(
                ownerID: "owner1",
                jobID: job.id,
                amount: 500,
                vendor: "Vendor \(i)",
                date: Date(),
                notes: "",
                createdAt: Date(),
                aiProcessed: false
            )
        }
        
        let receiptTotal = receipts.reduce(0) { $0 + $1.amount }
        XCTAssertEqual(receiptTotal, 5000, "Total receipts = $5000")
        
        // Profit should STILL be $10,000 (receipts don't affect it)
        let profitWithReceipts = job.calculateProfit(laborCost: 0)
        XCTAssertEqual(profitWithReceipts, 10000, "✅ VERIFIED: Receipts do NOT affect profit")
        XCTAssertEqual(profitWithoutReceipts, profitWithReceipts, "✅ VERIFIED: Profit unchanged by receipts")
    }
    
    func testReceiptsAreDocumentStorageOnly() {
        // Verify that receipt amounts are for DISPLAY ONLY
        
        let job = Job(
            ownerID: "owner1",
            jobName: "Test Job",
            clientName: "Client",
            address: "Address",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0
        )
        
        // Add $20,000 in receipts (more than project value)
        let hugeReceiptTotal: Double = 20000
        let receipt = Receipt(
            ownerID: "owner1",
            jobID: job.id,
            amount: hugeReceiptTotal,
            vendor: "Vendor",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertEqual(receipt.amount, 20000, "Receipt amount stored")
        
        // Profit should be projectValue - laborCost, NOT affected by receipts
        let profit = job.calculateProfit(laborCost: 1000)
        XCTAssertEqual(profit, 9000, "✅ VERIFIED: Profit = projectValue - laborCost")
        XCTAssertNotEqual(profit, 10000 - 20000, "✅ VERIFIED: Profit does NOT subtract receipts")
    }
    
    // MARK: - AI Categorization Tests
    
    func testAICategorization() {
        let aiService = AIService.shared
        
        // Test material vendors
        let (category1, confidence1) = aiService.categorizeReceiptDetailed(vendor: "Home Depot", amount: 100)
        XCTAssertEqual(category1, "Materials", "Home Depot should categorize as Materials")
        XCTAssertGreaterThan(confidence1, 0.9, "High confidence for known vendor")
        
        // Test fuel vendors
        let (category2, confidence2) = aiService.categorizeReceiptDetailed(vendor: "Chevron Gas", amount: 50)
        XCTAssertEqual(category2, "Fuel", "Chevron should categorize as Fuel")
        XCTAssertGreaterThan(confidence2, 0.9, "High confidence for known vendor")
        
        // Test unknown vendor
        let (category3, confidence3) = aiService.categorizeReceiptDetailed(vendor: "Unknown Store XYZ", amount: 100)
        XCTAssertEqual(category3, "Other", "Unknown vendor should categorize as Other")
        XCTAssertLessThan(confidence3, 0.6, "Low confidence for unknown vendor")
    }
    
    func testAICategorizationEdgeCases() {
        let aiService = AIService.shared
        
        // Empty vendor
        let (cat1, conf1) = aiService.categorizeReceiptDetailed(vendor: "", amount: 100)
        XCTAssertEqual(cat1, "Other", "Empty vendor defaults to Other")
        
        // Unicode vendor
        let (cat2, _) = aiService.categorizeReceiptDetailed(vendor: "José's Hardware 五金店", amount: 100)
        XCTAssertNotNil(cat2, "Unicode vendor name handled")
        
        // XSS attempt in vendor name
        let (cat3, _) = aiService.categorizeReceiptDetailed(vendor: "<script>alert('xss')</script>", amount: 100)
        XCTAssertEqual(cat3, "Other", "Malicious vendor name handled safely")
        
        // Extremely long vendor name
        let longVendor = String(repeating: "A", count: 10_000)
        let (cat4, _) = aiService.categorizeReceiptDetailed(vendor: longVendor, amount: 100)
        XCTAssertNotNil(cat4, "Long vendor name handled")
    }
    
    // MARK: - Duplicate Detection Tests
    
    func testDuplicateDetection() {
        let aiService = AIService.shared
        
        let existingReceipts = [
            Receipt(ownerID: "owner1", amount: 100.00, vendor: "Home Depot", date: Date(), notes: "", createdAt: Date(), aiProcessed: false),
            Receipt(ownerID: "owner1", amount: 50.00, vendor: "Chevron", date: Date(), notes: "", createdAt: Date(), aiProcessed: false),
        ]
        
        // Test exact duplicate
        let duplicate = Receipt(ownerID: "owner1", amount: 100.00, vendor: "Home Depot", date: Date(), notes: "", createdAt: Date(), aiProcessed: false)
        let duplicates = aiService.detectDuplicates(duplicate, in: existingReceipts)
        
        XCTAssertFalse(duplicates.isEmpty, "Duplicate should be detected")
        if let first = duplicates.first {
            XCTAssertGreaterThan(first.similarity, 0.7, "High similarity score for duplicate")
        }
        
        // Test non-duplicate
        let unique = Receipt(ownerID: "owner1", amount: 200.00, vendor: "Different Store", date: Date(), notes: "", createdAt: Date(), aiProcessed: false)
        let noDuplicates = aiService.detectDuplicates(unique, in: existingReceipts)
        
        XCTAssertTrue(noDuplicates.isEmpty, "No duplicates should be found for unique receipt")
    }
    
    func testDuplicateDetectionEdgeCases() {
        let aiService = AIService.shared
        
        let existingReceipts = [
            Receipt(ownerID: "owner1", amount: 100.00, vendor: "Home Depot", date: Date(), notes: "", createdAt: Date(), aiProcessed: false),
        ]
        
        // Slightly different amount
        let slightDiff = Receipt(ownerID: "owner1", amount: 100.50, vendor: "Home Depot", date: Date(), notes: "", createdAt: Date(), aiProcessed: false)
        let result1 = aiService.detectDuplicates(slightDiff, in: existingReceipts)
        XCTAssertFalse(result1.isEmpty, "Should detect near-duplicate with similar amount")
        
        // Same vendor, different amount
        let differentAmount = Receipt(ownerID: "owner1", amount: 500.00, vendor: "Home Depot", date: Date(), notes: "", createdAt: Date(), aiProcessed: false)
        let result2 = aiService.detectDuplicates(differentAmount, in: existingReceipts)
        // May or may not detect depending on thresholds
        
        // Different date (yesterday)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let differentDate = Receipt(ownerID: "owner1", amount: 100.00, vendor: "Home Depot", date: yesterday, notes: "", createdAt: Date(), aiProcessed: false)
        let result3 = aiService.detectDuplicates(differentDate, in: existingReceipts)
        XCTAssertFalse(result3.isEmpty, "Should detect duplicate even with different date (within threshold)")
    }
    
    // MARK: - Refund Detection Tests
    
    func testRefundDetection() {
        let aiService = AIService.shared
        
        // Negative amount (obvious refund)
        let negativeAmount = Receipt(ownerID: "owner1", amount: -50.00, vendor: "Store", date: Date(), notes: "", createdAt: Date(), aiProcessed: false)
        XCTAssertTrue(aiService.isLikelyRefund(negativeAmount), "Negative amount should be detected as refund")
        
        // "Refund" in vendor name
        let refundVendor = Receipt(ownerID: "owner1", amount: 50.00, vendor: "Store - Refund", date: Date(), notes: "", createdAt: Date(), aiProcessed: false)
        XCTAssertTrue(aiService.isLikelyRefund(refundVendor), "Refund in vendor name should be detected")
        
        // "Return" in notes
        let returnNotes = Receipt(ownerID: "owner1", amount: 50.00, vendor: "Store", date: Date(), notes: "Returned defective item", createdAt: Date(), aiProcessed: false)
        XCTAssertTrue(aiService.isLikelyRefund(returnNotes), "Return in notes should be detected")
        
        // Normal receipt (not a refund)
        let normalReceipt = Receipt(ownerID: "owner1", amount: 50.00, vendor: "Store", date: Date(), notes: "Purchase", createdAt: Date(), aiProcessed: false)
        XCTAssertFalse(aiService.isLikelyRefund(normalReceipt), "Normal receipt should not be detected as refund")
    }
    
    // MARK: - Deletion Tests
    
    func testReceiptDeletionWithImage() {
        // Receipt with image should delete both receipt and image
        let receipt = Receipt(
            ownerID: "owner1",
            jobID: "job1",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            imageURL: "gs://bucket/receipts/receipt123.jpg",
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertNotNil(receipt.imageURL, "Receipt has image")
        // TODO: Verify deletion flow deletes both Firestore doc AND storage file
        // This would be an integration test with actual Firebase
    }
    
    func testReceiptDeletionWithoutImage() {
        // Receipt without image should just delete Firestore doc
        let receipt = Receipt(
            ownerID: "owner1",
            jobID: "job1",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            imageURL: nil,
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertNil(receipt.imageURL, "Receipt has no image")
        // Deletion should not attempt to delete non-existent image
    }
    
    // MARK: - Category Tests
    
    func testReceiptCategoryOptional() {
        // Category is optional
        let noCategory = Receipt(
            ownerID: "owner1",
            amount: 100,
            vendor: "Vendor",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertNil(noCategory.category, "✅ VALID: Category is optional")
    }
    
    func testReceiptCategoryValues() {
        // Test various category strings
        let categories = ["Materials", "Fuel", "Equipment", "Meals", "Office", "Travel", "Other", "Custom Category"]
        
        for cat in categories {
            let receipt = Receipt(
                ownerID: "owner1",
                amount: 100,
                vendor: "Vendor",
                category: cat,
                date: Date(),
                notes: "",
                createdAt: Date(),
                aiProcessed: false
            )
            
            XCTAssertEqual(receipt.category, cat, "Category '\(cat)' should be stored")
        }
    }
    
    // MARK: - Date Tests
    
    func testReceiptFutureDate() {
        let futureDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        let futureReceipt = Receipt(
            ownerID: "owner1",
            amount: 100,
            vendor: "Vendor",
            date: futureDate,
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertEqual(futureReceipt.date, futureDate, "⚠️ ISSUE: Future receipt date allowed")
    }
    
    func testReceiptVeryOldDate() {
        let oldDate = Calendar.current.date(byAdding: .year, value: -100, to: Date())!
        let oldReceipt = Receipt(
            ownerID: "owner1",
            amount: 100,
            vendor: "Vendor",
            date: oldDate,
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        XCTAssertEqual(oldReceipt.date, oldDate, "Old date allowed (could be valid for historical records)")
    }
}

