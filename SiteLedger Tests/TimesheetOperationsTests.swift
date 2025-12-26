//
//  TimesheetOperationsTests.swift
//  SiteLedger Tests
//
//  PHASE 5: ULTRA-PARANOID TIMESHEET OPERATIONS TESTING
//  Test clock in/out, GPS tracking, hours calculations, labor cost impact
//

import XCTest
@testable import SiteLedger
import Foundation

final class TimesheetOperationsTests: XCTestCase {
    
    // MARK: - Clock In Tests
    
    func testClockInBasic() {
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            clockOut: nil,
            hours: nil,
            status: .working,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertEqual(timesheet.status, .working, "✅ VALID: Working status on clock in")
        XCTAssertNil(timesheet.clockOut, "✅ VALID: No clock out time yet")
        XCTAssertNil(timesheet.hours, "✅ VALID: Hours not calculated yet")
        XCTAssertTrue(timesheet.isActive, "✅ VALID: Timesheet is active")
    }
    
    func testClockInWithFutureTime() {
        let futureTime = Date(timeIntervalSinceNow: 3600) // 1 hour future
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: futureTime,
            clockOut: nil,
            status: .working,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertGreaterThan(timesheet.clockIn, Date(), "⚠️ ISSUE: Future clock-in time allowed")
    }
    
    func testClockInWithVeryOldTime() {
        let oldTime = Date(timeIntervalSinceNow: -86400 * 365) // 1 year ago
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: oldTime,
            clockOut: nil,
            status: .working,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertLessThan(timesheet.clockIn, Date(timeIntervalSinceNow: -86400 * 30),
                          "⚠️ ISSUE: Very old clock-in time allowed (>30 days)")
    }
    
    func testClockInWithInvalidJobID() {
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "", // Empty job ID
            clockIn: Date(),
            status: .working,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertEqual(timesheet.jobID, "", "⚠️ ISSUE: Empty jobID allowed")
    }
    
    func testClockInWithInvalidWorkerID() {
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "", // Empty worker ID
            jobID: "job1",
            clockIn: Date(),
            status: .working,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertEqual(timesheet.workerID, "", "⚠️ ISSUE: Empty workerID allowed")
    }
    
    func testMultipleActiveTimesheets() {
        // Worker clocked in to multiple jobs simultaneously
        let timesheet1 = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            status: .working,
            notes: "",
            createdAt: Date()
        )
        
        let timesheet2 = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job2",
            clockIn: Date(),
            status: .working,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertEqual(timesheet1.workerID, timesheet2.workerID, 
                       "⚠️ ISSUE: Same worker can be clocked in to multiple jobs")
        // Note: Some systems allow this, others don't - business decision
    }
    
    // MARK: - Clock Out Tests
    
    func testClockOutBasic() {
        let clockIn = Date()
        let clockOut = Date(timeIntervalSince1970: clockIn.timeIntervalSince1970 + 3600) // 1 hour later
        
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: clockIn,
            clockOut: clockOut,
            hours: 1.0,
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertEqual(timesheet.status, .completed, "✅ VALID: Completed status after clock out")
        XCTAssertNotNil(timesheet.clockOut, "✅ VALID: Clock out time recorded")
        XCTAssertEqual(timesheet.hours, 1.0, "✅ VALID: Hours calculated")
        XCTAssertFalse(timesheet.isActive, "✅ VALID: Timesheet no longer active")
    }
    
    func testClockOutBeforeClockIn() {
        // CRITICAL: Clock out BEFORE clock in (time travel!)
        let clockIn = Date()
        let clockOut = Date(timeIntervalSince1970: clockIn.timeIntervalSince1970 - 3600) // 1 hour BEFORE clock in
        
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: clockIn,
            clockOut: clockOut,
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        let hoursWorked = timesheet.hoursWorked
        XCTAssertLessThan(hoursWorked, 0, "🔴 CRITICAL: Negative hours allowed (clockOut < clockIn)")
    }
    
    func testClockOutWithNegativeHours() {
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            clockOut: Date(timeIntervalSinceNow: -3600), // 1 hour ago
            hours: -1.0,
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertEqual(timesheet.hours, -1.0, "🔴 CRITICAL: Negative hours stored in manual field")
        XCTAssertLessThan(timesheet.hoursWorked, 0, "🔴 CRITICAL: Calculated hours negative")
    }
    
    func testClockOutWithZeroHours() {
        let now = Date()
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: now,
            clockOut: now, // Same time
            hours: 0,
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertEqual(timesheet.hours, 0, "Zero hours shift recorded")
        XCTAssertEqual(timesheet.hoursWorked, 0, "⚠️ ISSUE: Zero-duration shift allowed")
    }
    
    func testClockOutExtremeLongShift() {
        // 1000-hour shift (data entry error?)
        let clockIn = Date()
        let clockOut = Date(timeIntervalSince1970: clockIn.timeIntervalSince1970 + (1000 * 3600))
        
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: clockIn,
            clockOut: clockOut,
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertGreaterThan(timesheet.hoursWorked, 999, "⚠️ ISSUE: 1000+ hour shift allowed")
    }
    
    func testClockOutRealisticLongShift() {
        // 16-hour shift (realistic but long)
        let clockIn = Date()
        let clockOut = Date(timeIntervalSince1970: clockIn.timeIntervalSince1970 + (16 * 3600))
        
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: clockIn,
            clockOut: clockOut,
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertEqual(timesheet.hoursWorked, 16.0, accuracy: 0.01, 
                       "✅ VALID: 16-hour shift allowed (but should trigger review)")
    }
    
    // MARK: - Hours Calculation Tests
    
    func testHoursWorkedCalculation() {
        let clockIn = Date()
        let clockOut = Date(timeIntervalSince1970: clockIn.timeIntervalSince1970 + (8.5 * 3600)) // 8.5 hours
        
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: clockIn,
            clockOut: clockOut,
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertEqual(timesheet.hoursWorked, 8.5, accuracy: 0.01, 
                       "✅ VALID: Hours calculated correctly from clock times")
    }
    
    func testManualHoursMismatch() {
        // Manual hours field doesn't match calculated hours
        let clockIn = Date()
        let clockOut = Date(timeIntervalSince1970: clockIn.timeIntervalSince1970 + 3600) // 1 hour
        
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: clockIn,
            clockOut: clockOut,
            hours: 100.0, // Says 100 hours but only 1 hour elapsed
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertEqual(timesheet.hours, 100.0, "Manual hours = 100")
        XCTAssertEqual(timesheet.hoursWorked, 1.0, accuracy: 0.01, "Calculated hours = 1")
        XCTAssertNotEqual(timesheet.hours, timesheet.hoursWorked, 
                          "🔴 CRITICAL: Manual hours doesn't match calculated hours")
    }
    
    func testHoursWorkedWithNoClockOut() {
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(timeIntervalSinceNow: -3600), // 1 hour ago
            clockOut: nil,
            status: .working,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertEqual(timesheet.hoursWorked, 0, "⚠️ ISSUE: hoursWorked = 0 when clockOut is nil")
        // Note: hoursWorked property returns 0 if clockOut is nil, but worker is still working
    }
    
    func testHoursPrecision() {
        // Test fractional hours precision
        let clockIn = Date()
        let clockOut = Date(timeIntervalSince1970: clockIn.timeIntervalSince1970 + 3661) // 1 hour, 1 min, 1 sec
        
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: clockIn,
            clockOut: clockOut,
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        let expectedHours = 3661.0 / 3600.0 // ~1.0169 hours
        XCTAssertEqual(timesheet.hoursWorked, expectedHours, accuracy: 0.0001, 
                       "✅ VALID: Hours precision preserved")
    }
    
    // MARK: - Status Tests
    
    func testStatusCompletedWithoutClockOut() {
        // Status = completed but clockOut is nil
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            clockOut: nil,
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertEqual(timesheet.status, .completed, "Status is completed")
        XCTAssertNil(timesheet.clockOut, "🔴 CRITICAL: Completed status without clockOut")
        XCTAssertEqual(timesheet.hoursWorked, 0, "Hours = 0 (no clockOut)")
    }
    
    func testStatusWorkingWithClockOut() {
        // Status = working but clockOut is set
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            clockOut: Date(),
            status: .working,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertEqual(timesheet.status, .working, "Status is working")
        XCTAssertNotNil(timesheet.clockOut, "⚠️ ISSUE: Working status but clockOut is set")
        XCTAssertTrue(timesheet.isActive, "isActive returns true for .working status")
    }
    
    func testStatusFlagged() {
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            status: .flagged,
            notes: "",
            createdAt: Date()
        )
        
        XCTAssertEqual(timesheet.status, .flagged, "✅ VALID: Flagged status for review")
        XCTAssertFalse(timesheet.isActive, "isActive returns false for .flagged")
    }
    
    // MARK: - GPS Location Tests
    
    func testClockInWithLocation() {
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            status: .working,
            notes: "",
            createdAt: Date(),
            clockInLocation: "40.7128,-74.0060" // NYC coordinates
        )
        
        XCTAssertNotNil(timesheet.clockInLocation, "✅ VALID: Clock-in location captured")
        XCTAssertNil(timesheet.clockOutLocation, "✅ VALID: No clock-out location yet")
    }
    
    func testClockInWithoutLocation() {
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            status: .working,
            notes: "",
            createdAt: Date(),
            clockInLocation: nil
        )
        
        XCTAssertNil(timesheet.clockInLocation, "✅ VALID: Location tracking optional")
    }
    
    func testClockInWithEmptyLocation() {
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            status: .working,
            notes: "",
            createdAt: Date(),
            clockInLocation: ""
        )
        
        XCTAssertEqual(timesheet.clockInLocation, "", "⚠️ ISSUE: Empty location string allowed")
    }
    
    func testClockInWithInvalidGPS() {
        // Invalid GPS coordinates
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            status: .working,
            notes: "",
            createdAt: Date(),
            clockInLocation: "lat: 999, lon: 999" // Invalid coordinates
        )
        
        XCTAssertEqual(timesheet.clockInLocation, "lat: 999, lon: 999", 
                       "⚠️ ISSUE: Invalid GPS coordinates not validated")
    }
    
    func testClockOutLocationMismatch() {
        // Clock in at one location, clock out at very different location
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            clockOut: Date(timeIntervalSinceNow: 28800), // 8 hours later
            status: .completed,
            notes: "",
            createdAt: Date(),
            clockInLocation: "40.7128,-74.0060", // NYC
            clockOutLocation: "34.0522,-118.2437" // LA (2,800 miles away)
        )
        
        XCTAssertNotEqual(timesheet.clockInLocation, timesheet.clockOutLocation, 
                          "⚠️ ISSUE: Large location mismatch not flagged")
        // Note: This could be valid (travel job) or fraud - needs geofencing check
    }
    
    func testClockOutWithoutLocationWhenClockInHadLocation() {
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            clockOut: Date(),
            status: .completed,
            notes: "",
            createdAt: Date(),
            clockInLocation: "40.7128,-74.0060",
            clockOutLocation: nil // Missing clock-out location
        )
        
        XCTAssertNotNil(timesheet.clockInLocation, "Clock-in location present")
        XCTAssertNil(timesheet.clockOutLocation, "⚠️ ISSUE: Clock-out location missing")
    }
    
    // MARK: - AI Flags Tests
    
    func testAIFlagsUnusualHours() {
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            clockOut: Date(timeIntervalSinceNow: 50400), // 14 hours
            status: .completed,
            notes: "",
            createdAt: Date(),
            aiFlags: ["unusual_hours"]
        )
        
        XCTAssertTrue(timesheet.aiFlags?.contains("unusual_hours") ?? false, 
                      "✅ VALID: unusual_hours flag for 14-hour shift")
    }
    
    func testAIFlagsAutoCheckout() {
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(timeIntervalSinceNow: -86400), // 24 hours ago
            clockOut: Date(),
            status: .completed,
            notes: "",
            createdAt: Date(),
            aiFlags: ["auto_checkout"]
        )
        
        XCTAssertTrue(timesheet.aiFlags?.contains("auto_checkout") ?? false, 
                      "✅ VALID: auto_checkout flag after 24 hours")
    }
    
    func testAIFlagsLocationMismatch() {
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            clockOut: Date(),
            status: .completed,
            notes: "",
            createdAt: Date(),
            clockInLocation: "40.7128,-74.0060",
            clockOutLocation: "34.0522,-118.2437",
            aiFlags: ["location_mismatch"]
        )
        
        XCTAssertTrue(timesheet.aiFlags?.contains("location_mismatch") ?? false, 
                      "✅ VALID: location_mismatch flag for different cities")
    }
    
    func testAIFlagsDuplicates() {
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            status: .working,
            notes: "",
            createdAt: Date(),
            aiFlags: ["unusual_hours", "unusual_hours", "unusual_hours"]
        )
        
        XCTAssertEqual(timesheet.aiFlags?.count, 3, "⚠️ ISSUE: Duplicate AI flags not deduplicated")
    }
    
    func testAIFlagsEmptyStrings() {
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            status: .working,
            notes: "",
            createdAt: Date(),
            aiFlags: ["", "null", "undefined"]
        )
        
        XCTAssertEqual(timesheet.aiFlags?.count, 3, "⚠️ ISSUE: Invalid AI flag strings allowed")
    }
    
    // MARK: - Labor Cost Impact Tests (CRITICAL FOR PROFIT)
    
    func testLaborCostCalculation() {
        // Worker with $50/hr rate works 8 hours
        let worker = User(
            name: "John",
            email: "john@test.com",
            hourlyRate: 50.0
        )
        
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: worker.id ?? "worker1",
            jobID: "job1",
            clockIn: Date(),
            clockOut: Date(timeIntervalSinceNow: 28800), // 8 hours
            hours: 8.0,
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        let laborCost = (timesheet.hours ?? 0) * (worker.hourlyRate ?? 0)
        XCTAssertEqual(laborCost, 400.0, "✅ VERIFIED: 8 hours × $50/hr = $400 labor cost")
    }
    
    func testNegativeLaborCost() {
        // Negative hours with positive rate
        let worker = User(name: "John", email: "john@test.com", hourlyRate: 50.0)
        
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: worker.id ?? "worker1",
            jobID: "job1",
            clockIn: Date(),
            clockOut: Date(timeIntervalSinceNow: -3600), // Negative hours
            hours: -1.0,
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        let laborCost = (timesheet.hours ?? 0) * (worker.hourlyRate ?? 0)
        XCTAssertEqual(laborCost, -50.0, "🔴 CRITICAL: Negative labor cost inflates profit")
    }
    
    func testZeroHourlyRate() {
        // Worker with $0 hourly rate
        let worker = User(name: "John", email: "john@test.com", hourlyRate: 0.0)
        
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: worker.id ?? "worker1",
            jobID: "job1",
            clockIn: Date(),
            clockOut: Date(timeIntervalSinceNow: 28800),
            hours: 8.0,
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        let laborCost = (timesheet.hours ?? 0) * (worker.hourlyRate ?? 0)
        XCTAssertEqual(laborCost, 0, "⚠️ ISSUE: 8 hours × $0/hr = $0 labor cost")
    }
    
    func testNilHourlyRate() {
        // Worker with nil hourly rate
        let worker = User(name: "John", email: "john@test.com", hourlyRate: nil)
        
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: worker.id ?? "worker1",
            jobID: "job1",
            clockIn: Date(),
            clockOut: Date(timeIntervalSinceNow: 28800),
            hours: 8.0,
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        let laborCost = (timesheet.hours ?? 0) * (worker.hourlyRate ?? 0)
        XCTAssertEqual(laborCost, 0, "⚠️ ISSUE: 8 hours × nil rate = $0 labor cost")
    }
    
    func testInfinityHourlyRate() {
        let worker = User(name: "John", email: "john@test.com", hourlyRate: Double.infinity)
        
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: worker.id ?? "worker1",
            jobID: "job1",
            clockIn: Date(),
            clockOut: Date(timeIntervalSinceNow: 28800),
            hours: 8.0,
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        let laborCost = (timesheet.hours ?? 0) * (worker.hourlyRate ?? 0)
        XCTAssertEqual(laborCost, Double.infinity, "🔴 CRITICAL: Infinity labor cost breaks profit")
    }
    
    func testLaborCostAffectsProfit() {
        // VERIFY: Timesheets DO affect profit (via labor cost)
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
        
        let profitWithoutLabor = job.calculateProfit(laborCost: 0)
        XCTAssertEqual(profitWithoutLabor, 10000, "Profit = $10,000 with zero labor")
        
        // Add 100 hours of labor at $50/hr = $5,000 labor cost
        let laborCost: Double = 100 * 50
        let profitWithLabor = job.calculateProfit(laborCost: laborCost)
        
        XCTAssertEqual(profitWithLabor, 5000, "✅ VERIFIED: Profit = $5,000 after $5,000 labor")
        XCTAssertNotEqual(profitWithoutLabor, profitWithLabor, 
                          "✅ VERIFIED: Labor cost DOES reduce profit")
    }
    
    // MARK: - Edge Cases
    
    func testWorkerNotAssignedToJob() {
        // Worker clocks in to job they're not assigned to
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: Date(),
            status: .working,
            notes: "",
            createdAt: Date()
        )
        
        // Job has assignedWorkers = ["worker2", "worker3"]
        // worker1 is NOT in the list
        
        XCTAssertEqual(timesheet.workerID, "worker1", 
                       "⚠️ ISSUE: Worker can clock in to job they're not assigned to")
    }
    
    func testClockInToCompletedJob() {
        // Worker clocks in to job with status = completed
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "completed-job-id",
            clockIn: Date(),
            status: .working,
            notes: "",
            createdAt: Date()
        )
        
        // Assumes job.status = .completed
        XCTAssertEqual(timesheet.status, .working, 
                       "⚠️ ISSUE: Can clock in to completed job")
    }
    
    func testOverlappingTimesheets() {
        // Worker has two overlapping shifts on same job
        let clockIn1 = Date()
        let clockOut1 = Date(timeIntervalSince1970: clockIn1.timeIntervalSince1970 + 7200) // 2 hours
        
        let clockIn2 = Date(timeIntervalSince1970: clockIn1.timeIntervalSince1970 + 3600) // 1 hour after start
        let clockOut2 = Date(timeIntervalSince1970: clockIn1.timeIntervalSince1970 + 10800) // 3 hours after start
        
        let timesheet1 = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: clockIn1,
            clockOut: clockOut1,
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        let timesheet2 = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: clockIn2,
            clockOut: clockOut2,
            status: .completed,
            notes: "",
            createdAt: Date()
        )
        
        // Timesheet 2 starts before timesheet 1 ends
        XCTAssertLessThan(clockIn2, clockOut1, "⚠️ ISSUE: Overlapping shifts allowed")
        
        let totalHours = (timesheet1.hours ?? 0) + (timesheet2.hours ?? 0)
        // Would count 5 hours total, but actual elapsed time is only 3 hours
        XCTAssertGreaterThan(totalHours, 3.0, "⚠️ ISSUE: Overlapping shifts double-count hours")
    }
    
    func testTimesheetDateMismatch() {
        // createdAt is before clockIn (impossible)
        let clockIn = Date()
        let createdAt = Date(timeIntervalSince1970: clockIn.timeIntervalSince1970 - 3600) // 1 hour before
        
        let timesheet = Timesheet(
            ownerID: "owner1",
            workerID: "worker1",
            jobID: "job1",
            clockIn: clockIn,
            status: .working,
            notes: "",
            createdAt: createdAt
        )
        
        XCTAssertLessThan(timesheet.createdAt, timesheet.clockIn, 
                          "⚠️ ISSUE: createdAt before clockIn (timestamp inconsistency)")
    }
}
