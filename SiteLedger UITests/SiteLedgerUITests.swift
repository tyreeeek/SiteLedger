//
//  SiteLedger UITests.swift
//  SiteLedger UITests
//
//  Comprehensive UI Tests for SiteLedger
//

import XCTest

final class SiteLedgerUITests: XCTestCase {
    
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        // Cleanup after each test
    }

    // MARK: - Welcome Screen Tests
    
    @MainActor
    func testWelcomeScreenExists() throws {
        // Check that the Welcome screen appears on launch (if not logged in)
        let signInButton = app.buttons["Sign In"]
        let createAccountButton = app.buttons["Create Account"]
        
        // Either we're on welcome screen or we're already logged in (dashboard)
        if signInButton.waitForExistence(timeout: 5) {
            XCTAssertTrue(signInButton.exists, "Sign In button should exist on Welcome screen")
            XCTAssertTrue(createAccountButton.exists, "Create Account button should exist on Welcome screen")
        } else {
            // Already logged in - check for Dashboard elements
            let dashboardExists = app.staticTexts["Welcome back,"].waitForExistence(timeout: 3)
            XCTAssertTrue(dashboardExists || app.tabBars.count > 0, "Should be on Dashboard if not on Welcome screen")
        }
    }
    
    @MainActor
    func testSignInButtonOpensLoginSheet() throws {
        let signInButton = app.buttons["Sign In"]
        
        if signInButton.waitForExistence(timeout: 5) {
            signInButton.tap()
            
            // Check that Login sheet appeared
            let welcomeBackText = app.staticTexts["Welcome Back"]
            XCTAssertTrue(welcomeBackText.waitForExistence(timeout: 3), "Login sheet should show 'Welcome Back' text")
        }
    }
    
    @MainActor
    func testCreateAccountButtonOpensSignupSheet() throws {
        let createAccountButton = app.buttons["Create Account"]
        
        if createAccountButton.waitForExistence(timeout: 5) {
            createAccountButton.tap()
            
            // Check that Signup sheet appeared
            let createAccountText = app.staticTexts["Create Account"]
            XCTAssertTrue(createAccountText.waitForExistence(timeout: 3), "Signup sheet should appear")
        }
    }
    
    // MARK: - Tab Bar Tests (when logged in)
    
    @MainActor
    func testTabBarNavigation() throws {
        // If logged in, test tab bar navigation
        let tabBar = app.tabBars.firstMatch
        
        if tabBar.waitForExistence(timeout: 5) {
            // Test Dashboard tab
            let dashboardTab = tabBar.buttons["Dashboard"]
            if dashboardTab.exists {
                dashboardTab.tap()
                sleep(1)
            }
            
            // Test Jobs tab
            let jobsTab = tabBar.buttons["Jobs"]
            if jobsTab.exists {
                jobsTab.tap()
                sleep(1)
            }
            
            // Test Receipts tab
            let receiptsTab = tabBar.buttons["Receipts"]
            if receiptsTab.exists {
                receiptsTab.tap()
                sleep(1)
            }
            
            // Test Documents tab
            let documentsTab = tabBar.buttons["Documents"]
            if documentsTab.exists {
                documentsTab.tap()
                sleep(1)
            }
            
            // Test More tab
            let moreTab = tabBar.buttons["More"]
            if moreTab.exists {
                moreTab.tap()
                sleep(1)
            }
        }
    }
    
    // MARK: - Launch Performance Test
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
