import XCTest

final class AbsorbMixUITests: XCTestCase {
    let app = XCUIApplication(bundleIdentifier: "com.andris73.absorbmix")
    func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    func testCompanionControlsAndScreenshots() throws {
        continueAfterFailure = false
        app.launch()
        addUIInterruptionMonitor(withDescription: "Fresh simulator notification prompt") { alert in
            for name in ["Don’t Allow", "Don't Allow", "Not Now"] {
                if alert.buttons[name].exists { alert.buttons[name].tap(); return true }
            }
            return false
        }
        let entry = app.buttons["Explore Spotify companion • experimental"]
        XCTAssertTrue(entry.waitForExistence(timeout: 40), app.debugDescription)
        capture("01-login-companion-entry")
        entry.tap()
        let headline = app.staticTexts["Your audiobook + your Spotify app"]
        if !headline.waitForExistence(timeout: 5) && entry.exists { entry.tap() }
        XCTAssertTrue(headline.waitForExistence(timeout: 20), app.debugDescription)
        capture("02-companion-off-top")
        let overlap = app.switches.firstMatch
        XCTAssertTrue(overlap.waitForExistence(timeout: 10))
        overlap.tap()
        let enabled = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "On • Spotify can keep playing with the book")).firstMatch
        XCTAssertTrue(enabled.waitForExistence(timeout: 15), app.debugDescription)
        capture("03-companion-on-top")
        app.sliders.firstMatch.adjust(toNormalizedSliderPosition: 0.4)
        capture("04-book-gain-adjusted")
        app.swipeUp()
        let unavailable = app.staticTexts["Spotify gain • unavailable (not a live level)"]
        XCTAssertTrue(unavailable.waitForExistence(timeout: 10), app.debugDescription)
        capture("05-spotify-manual-limits")
        app.swipeUp()
        capture("06-manual-test-checklist")
        XCUIDevice.shared.orientation = .landscapeLeft
        capture("07-landscape")
        XCUIDevice.shared.orientation = .portrait
    }
}
