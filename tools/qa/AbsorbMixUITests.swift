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
        let gain = app.descendants(matching: .any).matching(NSPredicate(format: "value == %@", "100%")).firstMatch
        XCTAssertTrue(gain.waitForExistence(timeout: 10), app.debugDescription)
        // Flutter adjustable semantics can be Other, not UISlider. Drag the real thumb.
        let start = gain.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let target = app.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: start.screenPoint.y / app.frame.height))
        start.press(forDuration: 0.1, thenDragTo: target)
        let adjusted = app.descendants(matching: .any).matching(NSPredicate(format: "value ENDSWITH %@ AND value != %@", "%", "100%")).firstMatch
        XCTAssertTrue(adjusted.waitForExistence(timeout: 10), app.debugDescription)
        let savedGain = adjusted.value as? String
        XCTAssertNotNil(savedGain)
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
        app.terminate()
        app.launch()
        XCTAssertTrue(entry.waitForExistence(timeout: 30))
        entry.tap()
        XCTAssertTrue(enabled.waitForExistence(timeout: 15), app.debugDescription)
        let restored = app.descendants(matching: .any).matching(NSPredicate(format: "value == %@", savedGain ?? "invalid")).firstMatch
        XCTAssertTrue(restored.waitForExistence(timeout: 10), app.debugDescription)
        capture("08-native-settings-restored-after-relaunch")
    }
}
