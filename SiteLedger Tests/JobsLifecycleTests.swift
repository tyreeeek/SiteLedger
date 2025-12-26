//
//  JobsLifecycleTests.swift
//  SiteLedger Tests
//
//  PHASE 3: JOBS LIFECYCLE TESTING
//  Test job creation, updates, deletions, profit calculations, state transitions
//

import XCTest
@testable import SiteLedger

final class JobsLifecycleTests: XCTestCase {
    
    var apiService: APIService!
    let testOwnerID = "test-owner-lifecycle"
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        apiService = APIService.shared
    }
    
    // MARK: - JOB CREATION TESTS
    
    func testCreateJobWithZeroProjectValue() async throws {
        let job = Job(
            ownerID: testOwnerID,
            jobName: "Zero Value Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 0,
            amountPaid: 0
        )
        
        // This should fail - $0 project value is nonsensical
        do {
            try await firestoreService.createJob(job)
            XCTFail("⚠️ ISSUE: Zero project value job created - should be rejected")
        } catch {
            // Expected
        }
    }
    
    func testCreateJobWithNegativeProjectValue() async throws {
        let job = Job(
            ownerID: testOwnerID,
            jobName: "Negative Value Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: -10000,
            amountPaid: 0
        )
        
        // Should fail
        do {
            try await firestoreService.createJob(job)
            XCTFail("⚠️ ISSUE: Negative project value job created - should be rejected")
        } catch {
            // Expected
        }
    }
    
    func testCreateJobWithInfiniteProjectValue() async throws {
        let job = Job(
            ownerID: testOwnerID,
            jobName: "Infinite Value Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: Double.infinity,
            amountPaid: 0
        )
        
        // Should fail
        do {
            try await firestoreService.createJob(job)
            XCTFail("⚠️ ISSUE: Infinite project value job created - should be rejected")
        } catch {
            // Expected
        }
    }
    
    func testCreateJobWithEmptyRequiredFields() async throws {
        let job = Job(
            ownerID: testOwnerID,
            jobName: "",  // Empty job name
            clientName: "",  // Empty client name
            address: "",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0
        )
        
        // Should fail - required fields empty
        do {
            try await firestoreService.createJob(job)
            XCTFail("⚠️ ISSUE: Job with empty jobName/clientName created - should be rejected")
        } catch {
            // Expected
        }
    }
    
    func testCreateJobWithEndDateBeforeStartDate() async throws {
        let now = Date()
        let yesterday = Date(timeIntervalSince1970: now.timeIntervalSince1970 - 86400)
        
        let job = Job(
            ownerID: testOwnerID,
            jobName: "Invalid Dates Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: now,
            endDate: yesterday,  // End before start
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0
        )
        
        // Should fail
        do {
            try await firestoreService.createJob(job)
            XCTFail("⚠️ ISSUE: Job with endDate < startDate created - should be rejected")
        } catch {
            // Expected
        }
    }
    
    func testCreateJobWithFutureStartDate() async throws {
        let futureDate = Date(timeIntervalSinceNow: 86400 * 365) // 1 year future
        
        let job = Job(
            ownerID: testOwnerID,
            jobName: "Future Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: futureDate,
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0
        )
        
        // This might be valid (scheduled jobs) but should be flagged
        do {
            try await firestoreService.createJob(job)
            print("⚠️ NOTE: Future start date allowed - consider adding warning")
        } catch {
            // If rejected, that's also acceptable
        }
    }
    
    func testCreateJobWithExtremelyLargeProjectValue() async throws {
        let job = Job(
            ownerID: testOwnerID,
            jobName: "Huge Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 999_999_999_999.99,  // Nearly 1 trillion dollars
            amountPaid: 0
        )
        
        // Should succeed but might want upper limit validation
        do {
            try await firestoreService.createJob(job)
            print("⚠️ NOTE: Extremely large project value allowed - consider max limit")
        } catch {
            print("INFO: Large project value rejected (good if intentional)")
        }
    }
    
    // MARK: - JOB UPDATE TESTS
    
    func testUpdateJobAmountPaidExceedsProjectValue() async throws {
        // First create a valid job
        var job = Job(
            ownerID: testOwnerID,
            jobName: "Overpayment Test",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0
        )
        
        try await firestoreService.createJob(job)
        guard let jobID = job.id else {
            XCTFail("Job creation failed")
            return
        }
        
        // Try to update with overpayment
        job.amountPaid = 15000  // More than project value
        
        do {
            try await firestoreService.updateJob(job)
            XCTFail("⚠️ ISSUE: Overpayment update allowed - amountPaid > projectValue")
        } catch {
            // Expected
        }
        
        // Cleanup
        try? await firestoreService.deleteJob(jobID: jobID)
    }
    
    func testUpdateJobToCompletedWithActiveTimesheets() async throws {
        // Create job
        var job = Job(
            ownerID: testOwnerID,
            jobName: "Active Timesheets Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 5000
        )
        
        try await firestoreService.createJob(job)
        guard let jobID = job.id else {
            XCTFail("Job creation failed")
            return
        }
        
        // Create an active timesheet for this job
        let timesheet = Timesheet(
            ownerID: testOwnerID,
            workerID: "worker1",
            jobID: jobID,
            clockIn: Date(),
            clockOut: nil,  // Still working
            status: .working,
            notes: "",
            createdAt: Date()
        )
        
        try await firestoreService.createTimesheet(timesheet)
        
        // Try to mark job as completed
        job.status = .completed
        
        do {
            try await firestoreService.updateJob(job)
            print("⚠️ NOTE: Job marked completed with active timesheets - consider validation")
        } catch {
            print("INFO: Job completion blocked with active timesheets (good)")
        }
        
        // Cleanup
        try? await firestoreService.deleteJob(jobID: jobID)
    }
    
    func testUpdateJobProjectValueWithExistingPayments() async throws {
        // Create job with payment
        var job = Job(
            ownerID: testOwnerID,
            jobName: "Payment Conflict Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 8000
        )
        
        try await firestoreService.createJob(job)
        guard let jobID = job.id else {
            XCTFail("Job creation failed")
            return
        }
        
        // Try to reduce project value below amount paid
        job.projectValue = 5000  // Less than amountPaid (8000)
        
        do {
            try await firestoreService.updateJob(job)
            XCTFail("⚠️ ISSUE: Project value reduced below amountPaid - creates negative balance")
        } catch {
            // Expected
        }
        
        // Cleanup
        try? await firestoreService.deleteJob(jobID: jobID)
    }
    
    // MARK: - JOB DELETION TESTS
    
    func testDeleteJobWithAttachedReceipts() async throws {
        // Create job
        let job = Job(
            ownerID: testOwnerID,
            jobName: "Receipts Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0
        )
        
        try await firestoreService.createJob(job)
        guard let jobID = job.id else {
            XCTFail("Job creation failed")
            return
        }
        
        // Create receipt for this job
        let receipt = Receipt(
            ownerID: testOwnerID,
            jobID: jobID,
            amount: 500,
            vendor: "Home Depot",
            date: Date(),
            notes: "",
            createdAt: Date(),
            aiProcessed: false
        )
        
        try await firestoreService.createReceipt(receipt)
        
        // Try to delete job
        do {
            try await firestoreService.deleteJob(jobID: jobID)
            print("⚠️ NOTE: Job deleted with attached receipts - consider cascade delete or prevent")
        } catch {
            print("INFO: Job deletion blocked with receipts (good)")
        }
    }
    
    func testDeleteJobWithTimesheets() async throws {
        // Create job
        let job = Job(
            ownerID: testOwnerID,
            jobName: "Timesheets Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0
        )
        
        try await firestoreService.createJob(job)
        guard let jobID = job.id else {
            XCTFail("Job creation failed")
            return
        }
        
        // Create timesheet for this job
        let timesheet = Timesheet(
            ownerID: testOwnerID,
            workerID: "worker1",
            jobID: jobID,
            clockIn: Date(),
            clockOut: Date(timeIntervalSinceNow: 3600),
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        try await firestoreService.createTimesheet(timesheet)
        
        // Try to delete job
        do {
            try await firestoreService.deleteJob(jobID: jobID)
            print("⚠️ NOTE: Job deleted with timesheets - labor costs will be orphaned!")
        } catch {
            print("INFO: Job deletion blocked with timesheets (good)")
        }
    }
    
    func testDeleteJobWithDocuments() async throws {
        // Create job
        let job = Job(
            ownerID: testOwnerID,
            jobName: "Documents Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0
        )
        
        try await firestoreService.createJob(job)
        guard let jobID = job.id else {
            XCTFail("Job creation failed")
            return
        }
        
        // Create document for this job
        let document = Document(
            ownerID: testOwnerID,
            jobID: jobID,
            fileURL: "https://example.com/contract.pdf",
            fileType: .pdf,
            title: "Contract"
        )
        
        try await firestoreService.createDocument(document)
        
        // Try to delete job
        do {
            try await firestoreService.deleteJob(jobID: jobID)
            print("⚠️ NOTE: Job deleted with documents - consider cascade delete or prevent")
        } catch {
            print("INFO: Job deletion blocked with documents (good)")
        }
    }
    
    // MARK: - PROFIT CALCULATION TESTS
    
    func testProfitCalculationWithZeroLaborCost() {
        let job = Job(
            ownerID: testOwnerID,
            jobName: "No Labor Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 5000
        )
        
        let profit = job.calculateProfit(laborCost: 0)
        XCTAssertEqual(profit, 10000, "Profit with zero labor should equal project value")
    }
    
    func testProfitCalculationWithHighLaborCost() {
        let job = Job(
            ownerID: testOwnerID,
            jobName: "High Labor Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 5000
        )
        
        let profit = job.calculateProfit(laborCost: 8000)
        XCTAssertEqual(profit, 2000, "Profit should be projectValue - laborCost")
    }
    
    func testProfitCalculationWithLaborExceedingValue() {
        let job = Job(
            ownerID: testOwnerID,
            jobName: "Loss Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 5000
        )
        
        let profit = job.calculateProfit(laborCost: 15000)
        XCTAssertEqual(profit, -5000, "⚠️ ISSUE: Negative profit allowed - this is a LOSS")
        
        // Should either:
        // 1. Return 0 and set a 'isLoss' flag
        // 2. Throw an error
        // 3. Rename to 'margin' and allow negatives
    }
    
    func testProfitCalculationWithNegativeLaborCost() {
        let job = Job(
            ownerID: testOwnerID,
            jobName: "Invalid Labor Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 5000
        )
        
        let profit = job.calculateProfit(laborCost: -1000)
        XCTAssertEqual(profit, 11000, "⚠️ ISSUE: Negative labor cost inflates profit")
        
        // Negative labor cost is nonsensical - should be rejected
    }
    
    func testProfitCalculationWithInfiniteLaborCost() {
        let job = Job(
            ownerID: testOwnerID,
            jobName: "Infinite Labor Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 5000
        )
        
        let profit = job.calculateProfit(laborCost: Double.infinity)
        XCTAssertEqual(profit, -Double.infinity, "⚠️ ISSUE: Infinity labor cost creates -Infinity profit")
    }
    
    func testProfitCalculationWithNaNLaborCost() {
        let job = Job(
            ownerID: testOwnerID,
            jobName: "NaN Labor Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 5000
        )
        
        let profit = job.calculateProfit(laborCost: Double.nan)
        XCTAssertTrue(profit.isNaN, "⚠️ ISSUE: NaN labor cost creates NaN profit")
    }
    
    // MARK: - STATUS TRANSITION TESTS
    
    func testStatusTransitionActiveToCompleted() async throws {
        var job = Job(
            ownerID: testOwnerID,
            jobName: "Transition Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 10000  // Fully paid
        )
        
        try await firestoreService.createJob(job)
        guard let jobID = job.id else {
            XCTFail("Job creation failed")
            return
        }
        
        // Transition to completed
        job.status = .completed
        job.endDate = Date()
        
        do {
            try await firestoreService.updateJob(job)
            print("✅ Valid transition: active → completed")
        } catch {
            XCTFail("Valid status transition should succeed")
        }
        
        // Cleanup
        try? await firestoreService.deleteJob(jobID: jobID)
    }
    
    func testStatusTransitionCompletedToActive() async throws {
        var job = Job(
            ownerID: testOwnerID,
            jobName: "Reopen Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            endDate: Date(),
            status: .completed,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 10000
        )
        
        try await firestoreService.createJob(job)
        guard let jobID = job.id else {
            XCTFail("Job creation failed")
            return
        }
        
        // Try to reopen completed job
        job.status = .active
        job.endDate = nil
        
        do {
            try await firestoreService.updateJob(job)
            print("⚠️ NOTE: Completed job reopened - consider audit trail")
        } catch {
            print("INFO: Reopening completed job blocked (good if intentional)")
        }
        
        // Cleanup
        try? await firestoreService.deleteJob(jobID: jobID)
    }
    
    func testCompletedJobWithoutEndDate() async throws {
        let job = Job(
            ownerID: testOwnerID,
            jobName: "No End Date Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            endDate: nil,  // No end date but completed?
            status: .completed,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 10000
        )
        
        do {
            try await firestoreService.createJob(job)
            print("⚠️ ISSUE: Completed job without endDate allowed")
        } catch {
            print("INFO: Completed job requires endDate (good)")
        }
    }
    
    // MARK: - WORKER ASSIGNMENT TESTS
    
    func testAssignDuplicateWorkers() async throws {
        var job = Job(
            ownerID: testOwnerID,
            jobName: "Duplicate Workers Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0,
            assignedWorkers: ["worker1", "worker1", "worker1"]  // Same worker 3 times
        )
        
        try await firestoreService.createJob(job)
        guard let jobID = job.id else {
            XCTFail("Job creation failed")
            return
        }
        
        // Check if duplicates were removed or allowed
        if let assignedWorkers = job.assignedWorkers {
            if assignedWorkers.count == 3 {
                print("⚠️ ISSUE: Duplicate worker assignments allowed")
            } else if assignedWorkers.count == 1 {
                print("✅ Duplicates auto-removed (good)")
            }
        }
        
        // Cleanup
        try? await firestoreService.deleteJob(jobID: jobID)
    }
    
    func testAssignNonExistentWorkers() async throws {
        var job = Job(
            ownerID: testOwnerID,
            jobName: "Fake Workers Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0,
            assignedWorkers: ["fake-worker-1", "fake-worker-2"]
        )
        
        try await firestoreService.createJob(job)
        guard let jobID = job.id else {
            XCTFail("Job creation failed")
            return
        }
        
        print("⚠️ NOTE: Non-existent worker IDs allowed - consider validation")
        
        // Cleanup
        try? await firestoreService.deleteJob(jobID: jobID)
    }
    
    func testUnassignAllWorkersFromActiveJob() async throws {
        var job = Job(
            ownerID: testOwnerID,
            jobName: "Unassign Job",
            clientName: "Test Client",
            address: "123 Test St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0,
            assignedWorkers: ["worker1", "worker2"]
        )
        
        try await firestoreService.createJob(job)
        guard let jobID = job.id else {
            XCTFail("Job creation failed")
            return
        }
        
        // Remove all workers
        job.assignedWorkers = []
        
        do {
            try await firestoreService.updateJob(job)
            print("⚠️ NOTE: Active job with no workers - consider warning")
        } catch {
            print("INFO: Active job requires workers (good if intentional)")
        }
        
        // Cleanup
        try? await firestoreService.deleteJob(jobID: jobID)
    }
}
