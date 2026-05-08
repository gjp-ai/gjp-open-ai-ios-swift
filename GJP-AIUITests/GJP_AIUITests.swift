//
//  GJP_AIUITests.swift
//  GJP-AIUITests
//
//  Created by GJP AI on 7/5/26.
//

import XCTest

final class GJP_AIUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testPrimaryTabNavigationExists() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Websites"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Q&A"].exists)
        XCTAssertTrue(app.tabBars.buttons["Articles"].exists)
        XCTAssertTrue(app.tabBars.buttons["Images"].exists)
        XCTAssertTrue(app.tabBars.buttons["Videos"].exists)

        app.tabBars.buttons["Articles"].tap()
        XCTAssertTrue(app.navigationBars["Articles"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
