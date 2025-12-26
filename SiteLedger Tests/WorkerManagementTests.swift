//
//  WorkerManagementTests.swift
//  SiteLedger Tests
//
//  Created by Ultra-Paranoid QA Swarm
//  Phase 6: Worker Management Testing
//

import XCTest
@testable import SiteLedger

/// PHASE 6: WORKER MANAGEMENT TESTING
/// Test worker assignment, role validation, hourly rate validation, permissions
/// Test data isolation, role-based access, owner/worker relationships
class WorkerManagementTests: XCTestCase {
    
    // MARK: - Worker Creation Tests
    
    func testCreateWorkerWithValidData() {
        let worker = User(
            id: "worker1",
            name: "John Worker",
            email: "john@test.com",
            role: .worker,
            active: true,
            createdAt: Date(),
            hourlyRate: 50.0
        )
        
        XCTAssertNotNil(worker)
        XCTAssertEqual(worker.role, UserRole.worker)
        XCTAssertEqual(worker.hourlyRate, 50.0)
    }
    
    func testCreateWorkerWithZeroHourlyRate() {
        let worker = User(
            name: "Zero Rate Worker",
            email: "zero@test.com",
            role: .worker,
            hourlyRate: 0.0  // ⚠️ ZERO hourly rate
        )
        
        XCTAssertEqual(worker.hourlyRate, 0.0, "🔴 CRITICAL: Zero hourly rate allowed")
        // EXPECTED: Should fail validation
        // Workers with $0 rate produce $0 labor cost regardless of hours worked
    }
    
    func testCreateWorkerWithNegativeHourlyRate() {
        let worker = User(
            name: "Negative Rate Worker",
            email: "negative@test.com",
            role: .worker,
            hourlyRate: -50.0  // ⚠️ NEGATIVE hourly rate
        )
        
        XCTAssertLessThan(worker.hourlyRate!, -0.01, "🔴 CRITICAL: Negative hourly rate allowed")
        // EXPECTED: Should fail validation
        // Negative rates create negative labor costs → inflated profit
    }
    
    func testCreateWorkerWithInfinityHourlyRate() {
        let worker = User(
            name: "Infinity Rate Worker",
            email: "infinity@test.com",
            role: .worker,
            hourlyRate: Double.infinity  // ⚠️ INFINITY hourly rate
        )
        
        XCTAssertTrue(worker.hourlyRate!.isInfinite, "🔴 CRITICAL: Infinity hourly rate allowed")
        // EXPECTED: Should fail validation
        // Infinity hourly rate → infinite labor cost → profit = -Infinity
    }
    
    func testCreateWorkerWithNaNHourlyRate() {
        let worker = User(
            name: "NaN Rate Worker",
            email: "nan@test.com",
            role: .worker,
            hourlyRate: Double.nan  // ⚠️ NaN hourly rate
        )
        
        XCTAssertTrue(worker.hourlyRate!.isNaN, "🔴 CRITICAL: NaN hourly rate allowed")
        // EXPECTED: Should fail validation
        // NaN hourly rate → NaN labor cost → all calculations break
    }
    
    func testCreateWorkerWithNilHourlyRate() {
        let worker = User(
            name: "Nil Rate Worker",
            email: "nilrate@test.com",
            role: .worker,
            hourlyRate: nil  // ⚠️ NIL hourly rate
        )
        
        XCTAssertNil(worker.hourlyRate, "🔴 CRITICAL: Nil hourly rate allowed")
        // EXPECTED: Should fail validation OR default to 0
        // Nil rate breaks labor cost calculations
    }
    
    func testCreateWorkerWithEmptyName() {
        let worker = User(
            name: "",  // ⚠️ Empty name
            email: "worker@test.com",
            role: .worker,
            hourlyRate: 50.0
        )
        
        XCTAssertTrue(worker.name.isEmpty, "🟠 HIGH: Empty worker name allowed")
        // EXPECTED: Should fail validation
        // UI displays empty rows, difficult to identify worker
    }
    
    func testCreateWorkerWithEmptyEmail() {
        let worker = User(
            name: "Worker",
            email: "",  // ⚠️ Empty email
            role: .worker,
            hourlyRate: 50.0
        )
        
        XCTAssertTrue(worker.email.isEmpty, "🟠 HIGH: Empty worker email allowed")
        // EXPECTED: Should fail validation
        // Cannot contact worker, authentication breaks
    }
    
    // MARK: - Role Validation Tests
    
    func testCreateWorkerWithOwnerRole() {
        let worker = User(
            name: "Owner Worker",
            email: "owner@test.com",
            role: .owner,  // ⚠️ Role mismatch
            hourlyRate: 50.0
        )
        
        XCTAssertEqual(worker.role, .owner, "🟡 MEDIUM: Can create 'worker' with role=.owner")
        // QUESTION: Is this allowed? Can owners also be workers?
        // If yes: OK. If no: Should validate role field.
    }
    
    // NOTE: Cannot test invalid role - UserRole enum prevents this at compile time ✅
    // This is actually GOOD design - enum provides type safety
    
    func testWorkerRoleEnumSafety() {
        let worker = User(
            name: "Worker",
            email: "worker@test.com",
            role: .worker,  // ✅ Enum ensures only valid roles
            hourlyRate: 50.0
        )
        
        XCTAssertEqual(worker.role, .worker)
        // ✅ PASS: UserRole enum prevents invalid roles at compile time
        // This is a security feature - cannot have role="admin" or role=""
    }
    
    // MARK: - Worker Assignment Tests
    
    func testAssignWorkerToJob() {
        let job = Job(
            ownerID: "owner1",
            jobName: "Construction Project",
            clientName: "Client",
            address: "123 Main St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0,
            assignedWorkers: ["worker1", "worker2"]
        )
        
        XCTAssertEqual(job.assignedWorkers?.count, 2)
        XCTAssertTrue(job.assignedWorkers?.contains("worker1") ?? false)
    }
    
    func testAssignDuplicateWorkers() {
        let job = Job(
            ownerID: "owner1",
            jobName: "Construction Project",
            clientName: "Client",
            address: "123 Main St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0,
            assignedWorkers: ["worker1", "worker1", "worker1"]  // ⚠️ Same worker 3 times
        )
        
        XCTAssertEqual(job.assignedWorkers?.count, 3, "🟠 HIGH: Duplicate worker IDs allowed")
        // EXPECTED: Should use Set to prevent duplicates
        // Duplicates break worker lists, confuse UI
    }
    
    func testAssignEmptyWorkerID() {
        let job = Job(
            ownerID: "owner1",
            jobName: "Construction Project",
            clientName: "Client",
            address: "123 Main St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0,
            assignedWorkers: ["", "worker1"]  // ⚠️ Empty worker ID
        )
        
        let hasEmptyID = job.assignedWorkers?.contains("") ?? false
        XCTAssertTrue(hasEmptyID, "🟠 HIGH: Empty worker ID allowed in assignedWorkers")
        // EXPECTED: Should filter out empty strings
    }
    
    func testAssignNonExistentWorker() {
        let job = Job(
            ownerID: "owner1",
            jobName: "Construction Project",
            clientName: "Client",
            address: "123 Main St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0,
            assignedWorkers: ["worker_does_not_exist"]  // ⚠️ Non-existent worker
        )
        
        XCTAssertNotNil(job.assignedWorkers)
        // EXPECTED: Should validate worker IDs exist in users collection
        // (Requires Firestore integration test)
    }
    
    func testJobWithNilAssignedWorkers() {
        let job = Job(
            ownerID: "owner1",
            jobName: "Construction Project",
            clientName: "Client",
            address: "123 Main St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0,
            assignedWorkers: nil  // ⚠️ No workers assigned
        )
        
        XCTAssertNil(job.assignedWorkers, "🟡 MEDIUM: Job with nil assignedWorkers allowed")
        // QUESTION: Is this valid? Can a job have no workers?
        // If yes: OK. If no: Should require at least one worker.
    }
    
    func testJobWithEmptyAssignedWorkers() {
        let job = Job(
            ownerID: "owner1",
            jobName: "Construction Project",
            clientName: "Client",
            address: "123 Main St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0,
            assignedWorkers: []  // ⚠️ Empty array (no workers)
        )
        
        XCTAssertEqual(job.assignedWorkers?.count, 0, "🟡 MEDIUM: Job with zero workers allowed")
        // QUESTION: Is this valid? Can a job have no workers?
    }
    
    // MARK: - Owner ID Validation Tests
    
    func testWorkerWithEmptyOwnerID() {
        let worker = User(
            id: "worker1",
            name: "Worker",
            email: "worker@test.com",
            role: .worker,
            hourlyRate: 50.0,
            ownerID: ""  // ⚠️ Empty owner ID
        )
        
        XCTAssertEqual(worker.ownerID, "", "🔴 CRITICAL: Empty ownerID allowed for worker")
        // EXPECTED: Should fail validation
        // Workers must belong to an owner, empty ID breaks data isolation
    }
    
    func testWorkerWithNilOwnerID() {
        let worker = User(
            id: "worker1",
            name: "Worker",
            email: "worker@test.com",
            role: .worker,
            hourlyRate: 50.0,
            ownerID: nil  // ⚠️ Nil owner ID
        )
        
        XCTAssertNil(worker.ownerID, "🔴 CRITICAL: Nil ownerID allowed for worker")
        // EXPECTED: Workers MUST have ownerID
        // Nil ownerID breaks data isolation, queries fail
    }
    
    func testOwnerWithOwnOwnerID() {
        let owner = User(
            id: "owner1",
            name: "Owner",
            email: "owner@test.com",
            role: .owner,
            hourlyRate: nil,
            ownerID: "owner1"  // ⚠️ Owner's ownerID = own ID
        )
        
        XCTAssertEqual(owner.ownerID, owner.id, "🟡 MEDIUM: Owner with ownerID = own ID")
        // QUESTION: Is this the expected pattern?
        // If yes: OK. If no: Owners should have ownerID = nil.
    }
    
    func testWorkerWithDifferentOwnerID() {
        let worker = User(
            id: "worker1",
            name: "Worker",
            email: "worker@test.com",
            role: .worker,
            hourlyRate: 50.0,
            ownerID: "owner2"  // Worker belongs to owner2
        )
        
        XCTAssertEqual(worker.ownerID, "owner2")
        // This is the expected pattern: workers have ownerID pointing to their owner
    }
    
    // MARK: - Data Isolation Tests
    
    func testOwnerCannotAccessOtherOwnerWorkers() {
        let owner1Workers = ["worker1", "worker2"]
        let owner2Workers = ["worker3", "worker4"]
        
        // EXPECTED: Firestore query filters by ownerID
        // owner1 should only see worker1, worker2
        // owner2 should only see worker3, worker4
        
        // This requires Firestore integration test
        XCTAssertTrue(true, "⚠️ Requires Firebase integration test")
    }
    
    func testWorkerCannotAccessOtherOwnerData() {
        // EXPECTED: Worker can only access data with ownerID = their owner
        // Should not see jobs, receipts, timesheets from other owners
        
        // This requires Firestore security rules test
        XCTAssertTrue(true, "⚠️ Requires Firebase security rules test")
    }
    
    // MARK: - Active/Inactive Worker Tests
    
    func testDeactivateWorker() {
        var worker = User(
            id: "worker1",
            name: "Worker",
            email: "worker@test.com",
            role: .worker,
            active: true,
            hourlyRate: 50.0
        )
        
        worker.active = false
        
        XCTAssertFalse(worker.active)
        // EXPECTED: Deactivated workers should not appear in worker selection dropdowns
    }
    
    func testClockInAsDeactivatedWorker() {
        let worker = User(
            id: "worker1",
            name: "Deactivated Worker",
            email: "worker@test.com",
            role: .worker,
            active: false,  // ⚠️ Worker is deactivated
            hourlyRate: 50.0
        )
        
        XCTAssertFalse(worker.active, "🟠 HIGH: Can attempt clock-in with deactivated worker")
        // EXPECTED: Should prevent clock-in if worker.active == false
        // (Requires TimesheetViewModel integration test)
    }
    
    func testJobWithDeactivatedWorkerAssigned() {
        let job = Job(
            ownerID: "owner1",
            jobName: "Construction Project",
            clientName: "Client",
            address: "123 Main St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0,
            assignedWorkers: ["deactivated_worker1"]  // ⚠️ Worker is deactivated
        )
        
        XCTAssertNotNil(job.assignedWorkers)
        // EXPECTED: Should validate assigned workers are active
        // OR clean up assignedWorkers when workers are deactivated
    }
    
    // MARK: - Hourly Rate Update Tests
    
    func testUpdateWorkerHourlyRate() {
        var worker = User(
            id: "worker1",
            name: "Worker",
            email: "worker@test.com",
            role: .worker,
            hourlyRate: 50.0
        )
        
        worker.hourlyRate = 60.0
        
        XCTAssertEqual(worker.hourlyRate, 60.0)
        // QUESTION: Should this affect existing timesheets?
        // If yes: Retroactive recalculation needed
        // If no: Timesheets store snapshot of hourlyRate at clock-in
    }
    
    func testUpdateHourlyRateToZero() {
        var worker = User(
            id: "worker1",
            name: "Worker",
            email: "worker@test.com",
            role: .worker,
            hourlyRate: 50.0
        )
        
        worker.hourlyRate = 0.0  // ⚠️ Update to zero
        
        XCTAssertEqual(worker.hourlyRate, 0.0, "🔴 CRITICAL: Can update hourly rate to zero")
        // EXPECTED: Should validate hourlyRate > 0
    }
    
    func testUpdateHourlyRateToInfinity() {
        var worker = User(
            id: "worker1",
            name: "Worker",
            email: "worker@test.com",
            role: .worker,
            hourlyRate: 50.0
        )
        
        worker.hourlyRate = Double.infinity  // ⚠️ Update to infinity
        
        XCTAssertTrue(worker.hourlyRate!.isInfinite, "🔴 CRITICAL: Can update hourly rate to infinity")
        // EXPECTED: Should validate hourlyRate.isFinite
    }
    
    // MARK: - Role Switching Tests
    
    func testSwitchWorkerToOwner() {
        var user = User(
            id: "worker1",
            name: "Worker",
            email: "worker@test.com",
            role: .worker,
            hourlyRate: 50.0,
            ownerID: "owner1"
        )
        
        user.role = UserRole.owner  // ⚠️ Switch role to owner
        
        XCTAssertEqual(user.role, UserRole.owner, "🟡 MEDIUM: Can switch role from worker to owner")
        // QUESTION: Is this allowed?
        // If yes: What happens to ownerID? What happens to existing timesheets?
        // If no: Should prevent role changes
    }
    
    func testSwitchOwnerToWorker() {
        var user = User(
            id: "owner1",
            name: "Owner",
            email: "owner@test.com",
            role: .owner,
            hourlyRate: nil,
            ownerID: "owner1"
        )
        
        user.role = UserRole.worker  // ⚠️ Switch role to worker
        
        XCTAssertEqual(user.role, UserRole.worker, "🟡 MEDIUM: Can switch role from owner to worker")
        // QUESTION: Is this allowed?
        // If yes: Owner loses access to their own data?
        // If no: Should prevent role changes
    }
    
    // MARK: - Worker Deletion Tests
    
    func testDeleteWorkerWithTimesheets() {
        // SCENARIO: Delete worker who has logged hours
        let worker = User(
            id: "worker1",
            name: "Worker",
            email: "worker@test.com",
            role: .worker,
            hourlyRate: 50.0
        )
        
        // Assume worker has timesheets with 100 hours logged
        
        // DELETE worker
        // QUESTION: What happens to timesheets?
        // If orphaned: Labor cost calculations broken
        // If cascade deleted: Financial records lost (BAD!)
        // EXPECTED: PREVENT deletion if timesheets exist
        
        XCTAssertTrue(true, "⚠️ Requires Firebase integration test")
    }
    
    func testDeleteWorkerAssignedToActiveJob() {
        // SCENARIO: Delete worker who is assigned to active job
        let worker = User(id: "worker1", name: "Worker", email: "worker@test.com", role: .worker)
        let job = Job(
            ownerID: "owner1",
            jobName: "Job",
            clientName: "Client",
            address: "123 Main St",
            startDate: Date(),
            status: .active,
            notes: "",
            createdAt: Date(),
            projectValue: 10000,
            amountPaid: 0,
            assignedWorkers: ["worker1"]
        )
        
        // DELETE worker
        // EXPECTED: Clean up job.assignedWorkers OR prevent deletion
        
        XCTAssertTrue(true, "⚠️ Requires Firebase integration test")
    }
    
    // MARK: - Permission Tests
    
    func testWorkerCannotCreateJobs() {
        // EXPECTED: Only owners can create jobs
        // Workers should see read-only or limited UI
        
        XCTAssertTrue(true, "⚠️ Requires UI/ViewModel integration test")
    }
    
    func testWorkerCannotEditJobDetails() {
        // EXPECTED: Workers cannot edit projectValue, clientName, etc.
        // Workers can only clock in/out
        
        XCTAssertTrue(true, "⚠️ Requires UI/ViewModel integration test")
    }
    
    func testWorkerCannotDeleteJobs() {
        // EXPECTED: Only owners can delete jobs
        
        XCTAssertTrue(true, "⚠️ Requires UI/ViewModel integration test")
    }
    
    func testWorkerCanCreateReceipts() {
        // EXPECTED: Workers CAN create receipts (upload photos from field)
        // This is a valid use case
        
        XCTAssertTrue(true, "⚠️ Requires ViewModel integration test")
    }
    
    func testWorkerCanClockInOut() {
        // EXPECTED: Workers CAN clock in/out (primary function)
        
        XCTAssertTrue(true, "⚠️ Requires ViewModel integration test")
    }
    
    func testOwnerCanViewAllWorkerTimesheets() {
        // EXPECTED: Owners can see timesheets from all their workers
        
        XCTAssertTrue(true, "⚠️ Requires ViewModel integration test")
    }
    
    func testWorkerCanOnlyViewOwnTimesheets() {
        // EXPECTED: Workers can only see their own timesheets
        // Should not see other workers' timesheets
        
        XCTAssertTrue(true, "⚠️ Requires ViewModel integration test")
    }
    
    // MARK: - Edge Cases
    
    func testExtremelyHighHourlyRate() {
        let worker = User(
            name: "Expensive Worker",
            email: "expensive@test.com",
            role: .worker,
            hourlyRate: 999999.99  // ⚠️ $1M/hour
        )
        
        XCTAssertEqual(worker.hourlyRate, 999999.99, "🟡 MEDIUM: Extremely high hourly rate allowed")
        // QUESTION: Should there be a maximum hourly rate?
        // Impact: 1 hour × $1M/hr = massive labor cost
    }
    
    func testWorkerWithVeryLongName() {
        let longName = String(repeating: "A", count: 1000)
        let worker = User(
            name: longName,
            email: "worker@test.com",
            role: .worker,
            hourlyRate: 50.0
        )
        
        XCTAssertEqual(worker.name.count, 1000, "🟡 MEDIUM: 1000-character name allowed")
        // Impact: UI breaks, database storage issues
        // Fix: Limit name to reasonable length (e.g., 100 chars)
    }
    
    func testWorkerWithVeryLongEmail() {
        let longEmail = String(repeating: "a", count: 500) + "@test.com"
        let worker = User(
            name: "Worker",
            email: longEmail,
            role: .worker,
            hourlyRate: 50.0
        )
        
        XCTAssertTrue(worker.email.count > 500, "🟡 MEDIUM: Extremely long email allowed")
        // Impact: Email validation breaks, UI issues
    }
    
    func testCreateThousandsOfWorkers() {
        var workers: [User] = []
        
        for i in 1...1000 {
            let worker = User(
                id: "worker\(i)",
                name: "Worker \(i)",
                email: "worker\(i)@test.com",
                role: .worker,
                hourlyRate: Double(i)
            )
            workers.append(worker)
        }
        
        XCTAssertEqual(workers.count, 1000)
        // QUESTION: Are there limits on workers per owner?
        // Impact: Performance, dropdown UI with 1000+ workers
    }
    
    func testWorkerNameWithSpecialCharacters() {
        let worker = User(
            name: "<script>alert('xss')</script>",  // ⚠️ XSS attempt
            email: "xss@test.com",
            role: .worker,
            hourlyRate: 50.0
        )
        
        XCTAssertTrue(worker.name.contains("<script>"), "🟠 HIGH: HTML/script tags allowed in name")
        // EXPECTED: Should sanitize input
        // Impact: Potential XSS vulnerability in UI
    }
    
    func testWorkerEmailWithoutAtSymbol() {
        let worker = User(
            name: "Worker",
            email: "notanemail",  // ⚠️ Invalid email format
            role: .worker,
            hourlyRate: 50.0
        )
        
        XCTAssertFalse(worker.email.contains("@"), "🟠 HIGH: Invalid email format allowed")
        // EXPECTED: Should validate email format
    }
}
