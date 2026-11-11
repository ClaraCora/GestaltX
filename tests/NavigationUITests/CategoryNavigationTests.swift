// SPDX-License-Identifier: GPL-3.0-only
import XCTest

final class CategoryNavigationTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCategorySelectionAndSingleBackNavigation() throws {
        let fixture = FileManager.default.temporaryDirectory.appendingPathComponent("navigation.plist")
        let data = try PropertyListSerialization.data(
            fromPropertyList: ["CacheExtra": ["navigation-fixture": true]],
            format: .binary,
            options: 0
        )
        try data.write(to: fixture)
        defer { try? FileManager.default.removeItem(at: fixture) }

        let app = XCUIApplication()
        app.launchArguments = [
            "--preview-document", fixture.path, "--preview-tab", "0",
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "-GestaltX.showDisplay.v1", "YES",
            "-GestaltX.showIPad.v1", "YES",
            "-GestaltX.showAdvanced.v1", "YES",
        ]
        app.launch()
        let device = app.buttons["category-Device"]
        XCTAssertTrue(device.waitForExistence(timeout: 15))
        let loaded = NSPredicate(format: "enabled == true")
        expectation(for: loaded, evaluatedWith: device)
        waitForExpectations(timeout: 15)
        attachScreenshot(app, named: "Tools")

        // Revisit both reported destinations, then exercise every optional
        // category so a shared Form row cannot push a sibling destination.
        for category in ["Intelligence", "Device", "Intelligence", "Device", "Display", "iPad", "Advanced"] {
            let button = app.buttons["category-\(category)"]
            reveal(button, in: app)
            button.tap()
            let navigationBar = app.navigationBars[category]
            XCTAssertTrue(navigationBar.waitForExistence(timeout: 5), "Open \(category)")
            attachScreenshot(app, named: category)
            navigationBar.buttons.element(boundBy: 0).tap()
            XCTAssertTrue(button.waitForExistence(timeout: 5), "One Back returns from \(category) to Tools")
            XCTAssertTrue(button.isHittable)
            XCTAssertFalse(app.navigationBars[category].exists)
        }

        let log = app.buttons["session-log"]
        reveal(log, in: app)
        log.tap()
        let logBar = app.navigationBars["Session Log"]
        XCTAssertTrue(logBar.waitForExistence(timeout: 5))
        logBar.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(device.waitForExistence(timeout: 5))
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        if element.exists && element.isHittable { return }
        for _ in 0..<5 {
            app.swipeDown()
            if element.exists && element.isHittable { return }
        }
        for _ in 0..<5 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    private func attachScreenshot(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
