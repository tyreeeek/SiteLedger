//
//  DataModelFieldTests.swift
//  SiteLedger Tests
//
//  PHASE 2: ULTRA-PARANOID DATA MODEL FIELD-LEVEL VERIFICATION
//  Test EVERY field in EVERY model with extreme/invalid data
//

import XCTest
@testable import SiteLedger

final class DataModelFieldTests: XCTestCase {
    
    // MARK: - USER MODEL TESTS (9 fields)
    
    func testUserNameEdgeCases() {
        // Empty string
        let emptyName = User(name: "", email: "test@test.com")
        XCTAssertEqual(emptyName.name, "", "Empty name should be stored")
        
        // Extremely long name (10,000 characters)
        let longName = String(repeating: "A", count: 10_000)
        let longNameUser = User(name: longName, email: "test@test.com")
        XCTAssertEqual(longNameUser.name.count, 10_000, "Long name should be stored")
        
        // Unicode/emoji name
        let emojiName = "👨‍🔧 José Müller 王"
        let emojiUser = User(name: emojiName, email: "test@test.com")
        XCTAssertEqual(emojiUser.name, emojiName, "Unicode/emoji name should be preserved")
        
        // Newlines and special characters
        let specialName = "John\nDoe\t<script>alert('xss')</script>"
        let specialUser = User(name: specialName, email: "test@test.com")
        XCTAssertEqual(specialUser.name, specialName, "Special characters should be preserved")
        
        // Whitespace only
        let whitespaceUser = User(name: "   \n\t  ", email: "test@test.com")
        XCTAssertEqual(whitespaceUser.name, "   \n\t  ", "Whitespace name should be stored")
    }
    
    func testUserEmailEdgeCases() {
        // Empty email
        let emptyEmail = User(name: "John", email: "")
        XCTAssertEqual(emptyEmail.email, "", "Empty email should be stored")
        
        // Invalid format (no validation in model)
        let invalidEmail = User(name: "John", email: "not-an-email")
        XCTAssertEqual(invalidEmail.email, "not-an-email", "Invalid email format should be stored")
        
        // Extremely long email
        let longEmail = String(repeating: "a", count: 5000) + "@test.com"
        let longEmailUser = User(name: "John", email: longEmail)
        XCTAssertEqual(longEmailUser.email, longEmail, "Long email should be stored")
        
        // Unicode email
        let unicodeEmail = "josé@mañana.com"
        let unicodeUser = User(name: "John", email: unicodeEmail)
        XCTAssertEqual(unicodeUser.email, unicodeEmail, "Unicode email should be preserved")
        
        // SQL injection attempt
        let sqlEmail = "test@test.com'; DROP TABLE users; --"
        let sqlUser = User(name: "John", email: sqlEmail)
        XCTAssertEqual(sqlUser.email, sqlEmail, "SQL injection attempt should be stored as string")
    }
    
    func testUserHourlyRateEdgeCases() {
        // Zero rate
        let zeroRate = User(name: "John", email: "test@test.com", hourlyRate: 0)
        XCTAssertEqual(zeroRate.hourlyRate, 0, "Zero hourly rate should be allowed")
        
        // Negative rate (should not be allowed but model doesn't validate)
        let negativeRate = User(name: "John", email: "test@test.com", hourlyRate: -50.0)
        XCTAssertEqual(negativeRate.hourlyRate, -50.0, "⚠️ ISSUE: Negative hourly rate not blocked")
        
        // Extremely high rate
        let extremeRate = User(name: "John", email: "test@test.com", hourlyRate: 999_999_999.99)
        XCTAssertEqual(extremeRate.hourlyRate, 999_999_999.99, "Extreme hourly rate should be stored")
        
        // Fractional cents (precision test)
        let precisionRate = User(name: "John", email: "test@test.com", hourlyRate: 25.999999)
        XCTAssertEqual(precisionRate.hourlyRate, 25.999999, "Fractional precision should be preserved")
        
        // Infinity and NaN (Swift allows these in Double)
        let infinityRate = User(name: "John", email: "test@test.com", hourlyRate: Double.infinity)
        XCTAssertEqual(infinityRate.hourlyRate, Double.infinity, "⚠️ ISSUE: Infinity not blocked")
        
        let nanRate = User(name: "John", email: "test@test.com", hourlyRate: Double.nan)
        XCTAssertTrue(nanRate.hourlyRate!.isNaN, "⚠️ ISSUE: NaN not blocked")
    }
    
    func testUserAssignedJobIDsEdgeCases() {
        // Empty array
        let emptyJobs = User(name: "John", email: "test@test.com", assignedJobIDs: [])
        XCTAssertEqual(emptyJobs.assignedJobIDs, [], "Empty job array should be stored")
        
        // Nil (optional field)
        let nilJobs = User(name: "John", email: "test@test.com", assignedJobIDs: nil)
        XCTAssertNil(nilJobs.assignedJobIDs, "Nil assignedJobIDs should be allowed")
        
        // Extremely large array (10,000 job IDs)
        let largeJobArray = Array(repeating: "job-id-123", count: 10_000)
        let largeJobUser = User(name: "John", email: "test@test.com", assignedJobIDs: largeJobArray)
        XCTAssertEqual(largeJobUser.assignedJobIDs?.count, 10_000, "Large job array should be stored")
        
        // Invalid job IDs (non-existent)
        let invalidJobs = User(name: "John", email: "test@test.com", assignedJobIDs: ["fake-id", "", "null"])
        XCTAssertEqual(invalidJobs.assignedJobIDs, ["fake-id", "", "null"], "Invalid job IDs should be stored")
        
        // Duplicate job IDs
        let duplicateJobs = User(name: "John", email: "test@test.com", assignedJobIDs: ["job1", "job1", "job1"])
        XCTAssertEqual(duplicateJobs.assignedJobIDs?.count, 3, "⚠️ ISSUE: Duplicate job IDs not prevented")
    }
    
    func testUserOwnerIDEdgeCases() {
        // Empty string
        let emptyOwner = User(name: "John", email: "test@test.com", ownerID: "")
        XCTAssertEqual(emptyOwner.ownerID, "", "Empty ownerID should be stored")
        
        // Nil (optional)
        let nilOwner = User(name: "John", email: "test@test.com", ownerID: nil)
        XCTAssertNil(nilOwner.ownerID, "Nil ownerID should be allowed")
        
        // Invalid/non-existent owner ID
        let fakeOwner = User(name: "John", email: "test@test.com", ownerID: "non-existent-owner-id")
        XCTAssertEqual(fakeOwner.ownerID, "non-existent-owner-id", "Invalid ownerID should be stored")
        
        // Owner role with ownerID set (role mismatch)
        let roleConflict = User(name: "John", email: "test@test.com", role: .owner, ownerID: "some-owner-id")
        XCTAssertEqual(roleConflict.role, .owner, "⚠️ ISSUE: Owner role can have ownerID (data inconsistency)")
    }
    
    func testUserActiveFieldEdgeCases() {
        // Default true
        let activeUser = User(name: "John", email: "test@test.com", active: true)
        XCTAssertTrue(activeUser.active, "Active should be true")
        
        // Inactive user
        let inactiveUser = User(name: "John", email: "test@test.com", active: false)
        XCTAssertFalse(inactiveUser.active, "Inactive should be false")
        
        // Note: Bool is safe from edge cases (only 2 values)
    }
    
    func testUserCreatedAtEdgeCases() {
        // Future date
        let futureDate = Date(timeIntervalSinceNow: 86400 * 365 * 10) // 10 years future
        let futureUser = User(name: "John", email: "test@test.com", createdAt: futureDate)
        XCTAssertEqual(futureUser.createdAt, futureDate, "⚠️ ISSUE: Future createdAt not blocked")
        
        // Very old date (before Unix epoch)
        let oldDate = Date(timeIntervalSince1970: -100_000_000)
        let oldUser = User(name: "John", email: "test@test.com", createdAt: oldDate)
        XCTAssertEqual(oldUser.createdAt, oldDate, "Old date should be stored")
        
        // Distant future (year 9999)
        let distantFuture = Date(timeIntervalSince1970: 253402300800) // Max reasonable timestamp
        let distantUser = User(name: "John", email: "test@test.com", createdAt: distantFuture)
        XCTAssertEqual(distantUser.createdAt, distantFuture, "Distant future date should be stored")
    }
    
    // MARK: - JOB MODEL TESTS (13 fields)
    
    func testJobProjectValueEdgeCases() {
        // Zero project value
        let zeroJob = Job(ownerID: "owner1", jobName: "Test", clientName: "Client", address: "Address", 
                          startDate: Date(), status: .active, notes: "", createdAt: Date(), 
                          projectValue: 0, amountPaid: 0)
        XCTAssertEqual(zeroJob.projectValue, 0, "Zero project value should be allowed")
        
        // Negative project value
        let negativeJob = Job(ownerID: "owner1", jobName: "Test", clientName: "Client", address: "Address", 
                              startDate: Date(), status: .active, notes: "", createdAt: Date(), 
                              projectValue: -10000, amountPaid: 0)
        XCTAssertEqual(negativeJob.projectValue, -10000, "⚠️ ISSUE: Negative project value not blocked")
        
        // Extremely large value
        let hugeJob = Job(ownerID: "owner1", jobName: "Test", clientName: "Client", address: "Address", 
                          startDate: Date(), status: .active, notes: "", createdAt: Date(), 
                          projectValue: 999_999_999_999.99, amountPaid: 0)
        XCTAssertEqual(hugeJob.projectValue, 999_999_999_999.99, "Huge project value should be stored")
        
        // Infinity
        let infinityJob = Job(ownerID: "owner1", jobName: "Test", clientName: "Client", address: "Address", 
                              startDate: Date(), status: .active, notes: "", createdAt: Date(), 
                              projectValue: Double.infinity, amountPaid: 0)
        XCTAssertEqual(infinityJob.projectValue, Double.infinity, "⚠️ ISSUE: Infinity not blocked")
        
        // NaN
        let nanJob = Job(ownerID: "owner1", jobName: "Test", clientName: "Client", address: "Address", 
                         startDate: Date(), status: .active, notes: "", createdAt: Date(), 
                         projectValue: Double.nan, amountPaid: 0)
        XCTAssertTrue(nanJob.projectValue.isNaN, "⚠️ ISSUE: NaN not blocked")
    }
    
    func testJobAmountPaidEdgeCases() {
        // Amount paid > project value (overpaid)
        let overpaidJob = Job(ownerID: "owner1", jobName: "Test", clientName: "Client", address: "Address", 
                              startDate: Date(), status: .active, notes: "", createdAt: Date(), 
                              projectValue: 10000, amountPaid: 15000)
        XCTAssertEqual(overpaidJob.amountPaid, 15000, "⚠️ ISSUE: Overpayment not validated")
        XCTAssertEqual(overpaidJob.remainingBalance, -5000, "⚠️ ISSUE: Negative balance allowed")
        
        // Negative amount paid
        let negativeJob = Job(ownerID: "owner1", jobName: "Test", clientName: "Client", address: "Address", 
                              startDate: Date(), status: .active, notes: "", createdAt: Date(), 
                              projectValue: 10000, amountPaid: -500)
        XCTAssertEqual(negativeJob.amountPaid, -500, "⚠️ ISSUE: Negative amountPaid not blocked")
    }
    
    func testJobProfitCalculationEdgeCases() {
        let job = Job(ownerID: "owner1", jobName: "Test", clientName: "Client", address: "Address", 
                      startDate: Date(), status: .active, notes: "", createdAt: Date(), 
                      projectValue: 10000, amountPaid: 5000)
        
        // Zero labor cost
        XCTAssertEqual(job.calculateProfit(laborCost: 0), 10000, "Profit with zero labor should be projectValue")
        
        // Labor cost exceeds project value
        XCTAssertEqual(job.calculateProfit(laborCost: 15000), -5000, "⚠️ ISSUE: Negative profit allowed")
        
        // Negative labor cost
        XCTAssertEqual(job.calculateProfit(laborCost: -1000), 11000, "⚠️ ISSUE: Negative labor cost inflates profit")
        
        // Infinity labor cost
        XCTAssertEqual(job.calculateProfit(laborCost: Double.infinity), -Double.infinity, "⚠️ ISSUE: Infinity labor cost creates -Infinity profit")
        
        // NaN labor cost
        XCTAssertTrue(job.calculateProfit(laborCost: Double.nan).isNaN, "⚠️ ISSUE: NaN labor cost creates NaN profit")
    }
    
    func testJobStringFieldsEdgeCases() {
        // Empty strings for all text fields
        let emptyJob = Job(ownerID: "", jobName: "", clientName: "", address: "", 
                           startDate: Date(), status: .active, notes: "", createdAt: Date(), 
                           projectValue: 10000, amountPaid: 0)
        XCTAssertEqual(emptyJob.ownerID, "", "⚠️ ISSUE: Empty ownerID allowed")
        XCTAssertEqual(emptyJob.jobName, "", "⚠️ ISSUE: Empty jobName allowed")
        XCTAssertEqual(emptyJob.clientName, "", "⚠️ ISSUE: Empty clientName allowed")
        
        // Extremely long strings (10,000 chars each)
        let longString = String(repeating: "A", count: 10_000)
        let longJob = Job(ownerID: longString, jobName: longString, clientName: longString, 
                          address: longString, startDate: Date(), status: .active, notes: longString, 
                          createdAt: Date(), projectValue: 10000, amountPaid: 0)
        XCTAssertEqual(longJob.jobName.count, 10_000, "Long jobName should be stored")
        
        // XSS/injection attempts
        let xssString = "<script>alert('xss')</script>"
        let xssJob = Job(ownerID: "owner1", jobName: xssString, clientName: xssString, 
                         address: xssString, startDate: Date(), status: .active, notes: xssString, 
                         createdAt: Date(), projectValue: 10000, amountPaid: 0)
        XCTAssertEqual(xssJob.jobName, xssString, "XSS string should be stored as-is")
    }
    
    func testJobDateLogicEdgeCases() {
        let now = Date()
        
        // End date before start date
        let invalidDates = Job(ownerID: "owner1", jobName: "Test", clientName: "Client", 
                               address: "Address", startDate: now, 
                               endDate: Date(timeIntervalSince1970: now.timeIntervalSince1970 - 86400), 
                               status: .active, notes: "", createdAt: Date(), 
                               projectValue: 10000, amountPaid: 0)
        XCTAssertNotNil(invalidDates.endDate, "⚠️ ISSUE: End date before start date not validated")
        
        // Start date in far future
        let futureStart = Job(ownerID: "owner1", jobName: "Test", clientName: "Client", 
                              address: "Address", 
                              startDate: Date(timeIntervalSince1970: 4102444800), // Year 2100
                              status: .active, notes: "", createdAt: Date(), 
                              projectValue: 10000, amountPaid: 0)
        XCTAssertGreaterThan(futureStart.startDate.timeIntervalSince1970, Date().timeIntervalSince1970, 
                             "⚠️ ISSUE: Future start date allowed")
    }
    
    func testJobAssignedWorkersEdgeCases() {
        // Nil workers (optional)
        let noWorkers = Job(ownerID: "owner1", jobName: "Test", clientName: "Client", 
                            address: "Address", startDate: Date(), status: .active, notes: "", 
                            createdAt: Date(), projectValue: 10000, amountPaid: 0, assignedWorkers: nil)
        XCTAssertNil(noWorkers.assignedWorkers, "Nil assignedWorkers should be allowed")
        
        // Empty array
        let emptyWorkers = Job(ownerID: "owner1", jobName: "Test", clientName: "Client", 
                               address: "Address", startDate: Date(), status: .active, notes: "", 
                               createdAt: Date(), projectValue: 10000, amountPaid: 0, assignedWorkers: [])
        XCTAssertEqual(emptyWorkers.assignedWorkers, [], "Empty workers array should be stored")
        
        // Duplicate worker IDs
        let duplicates = Job(ownerID: "owner1", jobName: "Test", clientName: "Client", 
                             address: "Address", startDate: Date(), status: .active, notes: "", 
                             createdAt: Date(), projectValue: 10000, amountPaid: 0, 
                             assignedWorkers: ["worker1", "worker1", "worker1"])
        XCTAssertEqual(duplicates.assignedWorkers?.count, 3, "⚠️ ISSUE: Duplicate workers not prevented")
        
        // Non-existent worker IDs
        let fakeWorkers = Job(ownerID: "owner1", jobName: "Test", clientName: "Client", 
                              address: "Address", startDate: Date(), status: .active, notes: "", 
                              createdAt: Date(), projectValue: 10000, amountPaid: 0, 
                              assignedWorkers: ["fake1", "fake2", ""])
        XCTAssertEqual(fakeWorkers.assignedWorkers?.count, 3, "⚠️ ISSUE: Invalid worker IDs not validated")
    }
    
    // MARK: - RECEIPT MODEL TESTS (14 fields)
    
    func testReceiptAmountEdgeCases() {
        // Zero amount
        let zeroReceipt = Receipt(ownerID: "owner1", amount: 0, vendor: "Vendor", date: Date(), 
                                  notes: "", createdAt: Date(), aiProcessed: false)
        XCTAssertEqual(zeroReceipt.amount, 0, "Zero receipt amount should be allowed")
        
        // Negative amount
        let negativeReceipt = Receipt(ownerID: "owner1", amount: -100, vendor: "Vendor", date: Date(), 
                                      notes: "", createdAt: Date(), aiProcessed: false)
        XCTAssertEqual(negativeReceipt.amount, -100, "⚠️ ISSUE: Negative receipt amount not blocked")
        
        // Extremely large amount
        let hugeReceipt = Receipt(ownerID: "owner1", amount: 999_999_999.99, vendor: "Vendor", 
                                  date: Date(), notes: "", createdAt: Date(), aiProcessed: false)
        XCTAssertEqual(hugeReceipt.amount, 999_999_999.99, "Huge receipt amount should be stored")
        
        // Infinity
        let infinityReceipt = Receipt(ownerID: "owner1", amount: Double.infinity, vendor: "Vendor", 
                                      date: Date(), notes: "", createdAt: Date(), aiProcessed: false)
        XCTAssertEqual(infinityReceipt.amount, Double.infinity, "⚠️ ISSUE: Infinity amount not blocked")
        
        // NaN
        let nanReceipt = Receipt(ownerID: "owner1", amount: Double.nan, vendor: "Vendor", 
                                 date: Date(), notes: "", createdAt: Date(), aiProcessed: false)
        XCTAssertTrue(nanReceipt.amount.isNaN, "⚠️ ISSUE: NaN amount not blocked")
    }
    
    func testReceiptAIConfidenceEdgeCases() {
        // Confidence < 0
        let negativeConfidence = Receipt(ownerID: "owner1", amount: 100, vendor: "Vendor", 
                                         date: Date(), notes: "", createdAt: Date(), 
                                         aiProcessed: true, aiConfidence: -0.5)
        XCTAssertEqual(negativeConfidence.aiConfidence, -0.5, "⚠️ ISSUE: Negative AI confidence allowed")
        
        // Confidence > 1.0
        let highConfidence = Receipt(ownerID: "owner1", amount: 100, vendor: "Vendor", 
                                     date: Date(), notes: "", createdAt: Date(), 
                                     aiProcessed: true, aiConfidence: 2.5)
        XCTAssertEqual(highConfidence.aiConfidence, 2.5, "⚠️ ISSUE: AI confidence > 1.0 allowed")
        
        // Confidence = NaN
        let nanConfidence = Receipt(ownerID: "owner1", amount: 100, vendor: "Vendor", 
                                    date: Date(), notes: "", createdAt: Date(), 
                                    aiProcessed: true, aiConfidence: Double.nan)
        XCTAssertTrue(nanConfidence.aiConfidence!.isNaN, "⚠️ ISSUE: NaN AI confidence allowed")
        
        // aiProcessed = false but aiConfidence set
        let inconsistent = Receipt(ownerID: "owner1", amount: 100, vendor: "Vendor", 
                                   date: Date(), notes: "", createdAt: Date(), 
                                   aiProcessed: false, aiConfidence: 0.95)
        XCTAssertFalse(inconsistent.aiProcessed, "⚠️ ISSUE: AI confidence set but aiProcessed = false")
    }
    
    func testReceiptVendorFieldEdgeCases() {
        // Empty vendor
        let emptyVendor = Receipt(ownerID: "owner1", amount: 100, vendor: "", date: Date(), 
                                  notes: "", createdAt: Date(), aiProcessed: false)
        XCTAssertEqual(emptyVendor.vendor, "", "⚠️ ISSUE: Empty vendor allowed")
        
        // Extremely long vendor name
        let longVendor = String(repeating: "A", count: 10_000)
        let longVendorReceipt = Receipt(ownerID: "owner1", amount: 100, vendor: longVendor, 
                                        date: Date(), notes: "", createdAt: Date(), aiProcessed: false)
        XCTAssertEqual(longVendorReceipt.vendor.count, 10_000, "Long vendor name should be stored")
        
        // Unicode vendor
        let unicodeVendor = "José's Hardware 五金店"
        let unicodeReceipt = Receipt(ownerID: "owner1", amount: 100, vendor: unicodeVendor, 
                                     date: Date(), notes: "", createdAt: Date(), aiProcessed: false)
        XCTAssertEqual(unicodeReceipt.vendor, unicodeVendor, "Unicode vendor should be preserved")
    }
    
    func testReceiptAIFlagsEdgeCases() {
        // Empty flags array
        let emptyFlags = Receipt(ownerID: "owner1", amount: 100, vendor: "Vendor", 
                                 date: Date(), notes: "", createdAt: Date(), 
                                 aiProcessed: true, aiFlags: [])
        XCTAssertEqual(emptyFlags.aiFlags, [], "Empty AI flags array should be allowed")
        
        // Duplicate flags
        let duplicateFlags = Receipt(ownerID: "owner1", amount: 100, vendor: "Vendor", 
                                     date: Date(), notes: "", createdAt: Date(), 
                                     aiProcessed: true, aiFlags: ["duplicate", "duplicate", "duplicate"])
        XCTAssertEqual(duplicateFlags.aiFlags?.count, 3, "⚠️ ISSUE: Duplicate AI flags not prevented")
        
        // Invalid flag strings
        let invalidFlags = Receipt(ownerID: "owner1", amount: 100, vendor: "Vendor", 
                                   date: Date(), notes: "", createdAt: Date(), 
                                   aiProcessed: true, aiFlags: ["", "null", "undefined", "DROP TABLE"])
        XCTAssertEqual(invalidFlags.aiFlags?.count, 4, "⚠️ ISSUE: Invalid flag strings not validated")
    }
    
    // MARK: - TIMESHEET MODEL TESTS (12 fields)
    
    func testTimesheetHoursCalculationEdgeCases() {
        let now = Date()
        
        // Clock out before clock in (negative hours)
        let clockOut = Date(timeIntervalSince1970: now.timeIntervalSince1970 - 3600) // 1 hour ago
        let invalidTimesheet = Timesheet(ownerID: "owner1", workerID: "worker1", jobID: "job1", 
                                         clockIn: now, clockOut: clockOut, status: .completed, 
                                         notes: "", createdAt: Date())
        XCTAssertLessThan(invalidTimesheet.hoursWorked, 0, "⚠️ ISSUE: Negative hours allowed")
        
        // Extremely long shift (1000 hours)
        let longShift = Date(timeIntervalSince1970: now.timeIntervalSince1970 + 3_600_000) // 1000 hours
        let longTimesheet = Timesheet(ownerID: "owner1", workerID: "worker1", jobID: "job1", 
                                      clockIn: now, clockOut: longShift, status: .completed, 
                                      notes: "", createdAt: Date())
        XCTAssertGreaterThan(longTimesheet.hoursWorked, 999, "⚠️ ISSUE: Unrealistic long shift allowed")
        
        // Manual hours field set but doesn't match calculated
        let mismatchTimesheet = Timesheet(ownerID: "owner1", workerID: "worker1", jobID: "job1", 
                                          clockIn: now, 
                                          clockOut: Date(timeIntervalSince1970: now.timeIntervalSince1970 + 3600), 
                                          hours: 100.0, // Set to 100 but calculated is 1
                                          status: .completed, notes: "", createdAt: Date())
        XCTAssertEqual(mismatchTimesheet.hours, 100.0, "⚠️ ISSUE: Manual hours doesn't match calculated")
        XCTAssertEqual(mismatchTimesheet.hoursWorked, 1.0, "Calculated hours is 1 but manual is 100")
    }
    
    func testTimesheetStatusEdgeCases() {
        // Completed status but no clock out
        let incompleteStopped = Timesheet(ownerID: "owner1", workerID: "worker1", jobID: "job1", 
                                          clockIn: Date(), clockOut: nil, status: .completed, 
                                          notes: "", createdAt: Date())
        XCTAssertNil(incompleteStopped.clockOut, "⚠️ ISSUE: Completed status without clockOut")
        
        // Working status with clock out set
        let workingComplete = Timesheet(ownerID: "owner1", workerID: "worker1", jobID: "job1", 
                                        clockIn: Date(), clockOut: Date(), status: .working, 
                                        notes: "", createdAt: Date())
        XCTAssertNotNil(workingComplete.clockOut, "⚠️ ISSUE: Working status with clockOut set")
    }
    
    func testTimesheetLocationFieldsEdgeCases() {
        // Empty location strings
        let emptyLocation = Timesheet(ownerID: "owner1", workerID: "worker1", jobID: "job1", 
                                      clockIn: Date(), status: .completed, notes: "", createdAt: Date(), 
                                      clockInLocation: "", clockOutLocation: "")
        XCTAssertEqual(emptyLocation.clockInLocation, "", "Empty location should be allowed")
        
        // Invalid GPS coordinates
        let invalidGPS = "lat: 999, lon: 999"
        let badGPS = Timesheet(ownerID: "owner1", workerID: "worker1", jobID: "job1", 
                               clockIn: Date(), status: .completed, notes: "", createdAt: Date(), 
                               clockInLocation: invalidGPS)
        XCTAssertEqual(badGPS.clockInLocation, invalidGPS, "⚠️ ISSUE: Invalid GPS coordinates not validated")
        
        // Clock in location set but clock out location nil
        let partialLocation = Timesheet(ownerID: "owner1", workerID: "worker1", jobID: "job1", 
                                        clockIn: Date(), clockOut: Date(), status: .completed, 
                                        notes: "", createdAt: Date(), 
                                        clockInLocation: "12.34, 56.78", clockOutLocation: nil)
        XCTAssertNil(partialLocation.clockOutLocation, "⚠️ ISSUE: Clock in location but no clock out location")
    }
    
    func testTimesheetAIFlagsEdgeCases() {
        // Empty AI flags
        let emptyFlags = Timesheet(ownerID: "owner1", workerID: "worker1", jobID: "job1", 
                                   clockIn: Date(), status: .completed, notes: "", createdAt: Date(), 
                                   aiFlags: [])
        XCTAssertEqual(emptyFlags.aiFlags, [], "Empty AI flags should be allowed")
        
        // Invalid flag strings
        let invalidFlags = Timesheet(ownerID: "owner1", workerID: "worker1", jobID: "job1", 
                                     clockIn: Date(), status: .completed, notes: "", createdAt: Date(), 
                                     aiFlags: ["", "INVALID", "12345"])
        XCTAssertEqual(invalidFlags.aiFlags?.count, 3, "⚠️ ISSUE: Invalid AI flag strings not validated")
    }
    
    // MARK: - DOCUMENT MODEL TESTS (11 fields)
    
    func testDocumentFileURLEdgeCases() {
        // Empty URL
        let emptyURL = Document(ownerID: "owner1", fileURL: "", fileType: .pdf, title: "Doc")
        XCTAssertEqual(emptyURL.fileURL, "", "⚠️ ISSUE: Empty fileURL allowed")
        
        // Invalid URL format
        let invalidURL = Document(ownerID: "owner1", fileURL: "not-a-url", fileType: .pdf, title: "Doc")
        XCTAssertEqual(invalidURL.fileURL, "not-a-url", "⚠️ ISSUE: Invalid URL format allowed")
        
        // Extremely long URL
        let longURL = "https://example.com/" + String(repeating: "a", count: 10_000)
        let longURLDoc = Document(ownerID: "owner1", fileURL: longURL, fileType: .pdf, title: "Doc")
        XCTAssertEqual(longURLDoc.fileURL.count, longURL.count, "Long URL should be stored")
        
        // Malicious URL
        let maliciousURL = "javascript:alert('xss')"
        let maliciousDoc = Document(ownerID: "owner1", fileURL: maliciousURL, fileType: .pdf, title: "Doc")
        XCTAssertEqual(maliciousDoc.fileURL, maliciousURL, "⚠️ ISSUE: Malicious URL not blocked")
    }
    
    func testDocumentTitleEdgeCases() {
        // Empty title
        let emptyTitle = Document(ownerID: "owner1", fileURL: "https://example.com/file.pdf", 
                                  fileType: .pdf, title: "")
        XCTAssertEqual(emptyTitle.title, "", "⚠️ ISSUE: Empty title allowed")
        
        // Extremely long title
        let longTitle = String(repeating: "A", count: 10_000)
        let longTitleDoc = Document(ownerID: "owner1", fileURL: "https://example.com/file.pdf", 
                                    fileType: .pdf, title: longTitle)
        XCTAssertEqual(longTitleDoc.title.count, 10_000, "Long title should be stored")
        
        // Unicode/emoji title
        let emojiTitle = "📄 Contract 中文 Español"
        let emojiDoc = Document(ownerID: "owner1", fileURL: "https://example.com/file.pdf", 
                                fileType: .pdf, title: emojiTitle)
        XCTAssertEqual(emojiDoc.title, emojiTitle, "Unicode/emoji title should be preserved")
    }
    
    func testDocumentAIExtractedDataEdgeCases() {
        // Empty dictionary
        let emptyData = Document(ownerID: "owner1", fileURL: "https://example.com/file.pdf", 
                                 fileType: .pdf, title: "Doc", aiExtractedData: [:])
        XCTAssertEqual(emptyData.aiExtractedData, [:], "Empty AI extracted data should be allowed")
        
        // Extremely large dictionary (1000 key-value pairs)
        var largeData: [String: String] = [:]
        for i in 0..<1000 {
            largeData["key\(i)"] = "value\(i)"
        }
        let largeDataDoc = Document(ownerID: "owner1", fileURL: "https://example.com/file.pdf", 
                                    fileType: .pdf, title: "Doc", aiExtractedData: largeData)
        XCTAssertEqual(largeDataDoc.aiExtractedData?.count, 1000, "Large AI extracted data should be stored")
        
        // Invalid keys/values
        let invalidData = ["": "empty key", "key": "", "<script>": "xss"]
        let invalidDoc = Document(ownerID: "owner1", fileURL: "https://example.com/file.pdf", 
                                  fileType: .pdf, title: "Doc", aiExtractedData: invalidData)
        XCTAssertEqual(invalidDoc.aiExtractedData?.count, 3, "⚠️ ISSUE: Invalid AI data keys not validated")
    }
    
    func testDocumentAIConfidenceEdgeCases() {
        // Confidence < 0
        let negativeConfidence = Document(ownerID: "owner1", fileURL: "https://example.com/file.pdf", 
                                          fileType: .pdf, title: "Doc", aiConfidence: -0.5)
        XCTAssertEqual(negativeConfidence.aiConfidence, -0.5, "⚠️ ISSUE: Negative AI confidence allowed")
        
        // Confidence > 1.0
        let highConfidence = Document(ownerID: "owner1", fileURL: "https://example.com/file.pdf", 
                                      fileType: .pdf, title: "Doc", aiConfidence: 2.0)
        XCTAssertEqual(highConfidence.aiConfidence, 2.0, "⚠️ ISSUE: AI confidence > 1.0 allowed")
        
        // Confidence = NaN
        let nanConfidence = Document(ownerID: "owner1", fileURL: "https://example.com/file.pdf", 
                                     fileType: .pdf, title: "Doc", aiConfidence: Double.nan)
        XCTAssertTrue(nanConfidence.aiConfidence!.isNaN, "⚠️ ISSUE: NaN AI confidence allowed")
    }
    
    func testDocumentAIFlagsEdgeCases() {
        // Empty flags
        let emptyFlags = Document(ownerID: "owner1", fileURL: "https://example.com/file.pdf", 
                                  fileType: .pdf, title: "Doc", aiFlags: [])
        XCTAssertEqual(emptyFlags.aiFlags, [], "Empty AI flags should be allowed")
        
        // Duplicate flags
        let duplicateFlags = Document(ownerID: "owner1", fileURL: "https://example.com/file.pdf", 
                                      fileType: .pdf, title: "Doc", 
                                      aiFlags: ["low_quality", "low_quality", "low_quality"])
        XCTAssertEqual(duplicateFlags.aiFlags?.count, 3, "⚠️ ISSUE: Duplicate AI flags not prevented")
        
        // Invalid flag strings
        let invalidFlags = Document(ownerID: "owner1", fileURL: "https://example.com/file.pdf", 
                                    fileType: .pdf, title: "Doc", aiFlags: ["", "null", "12345"])
        XCTAssertEqual(invalidFlags.aiFlags?.count, 3, "⚠️ ISSUE: Invalid AI flag strings not validated")
    }
}

