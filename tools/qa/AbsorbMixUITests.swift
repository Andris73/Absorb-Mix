import XCTest

final class AbsorbMixUITests: XCTestCase {
    let app = XCUIApplication(bundleIdentifier: "com.andris73.absorbmix")
    func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    func wait(_ predicate: @escaping () -> Bool, timeout: TimeInterval = 15) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in predicate() }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed, app.debugDescription)
    }
    func show(_ element: XCUIElement) {
        for _ in 0..<4 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        wait { element.exists && element.isHittable }
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
        wait { overlap.exists && overlap.isEnabled && overlap.isHittable }
        overlap.tap()
        let enabled = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "On • Spotify can keep playing with the book")).firstMatch
        XCTAssertTrue(enabled.waitForExistence(timeout: 15), app.debugDescription)
        capture("03-companion-on-top")
        let gain = app.descendants(matching: .any).matching(identifier: "companion.bookGain").firstMatch
        show(gain)
        XCTAssertEqual(gain.value as? String, "100%")
        let start = gain.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        // Derive the gesture from the identified audiobook control, never from
        // an arbitrary percentage-valued element (Spotify has one too).
        let target = start.withOffset(CGVector(dx: -120, dy: 0))
        start.press(forDuration: 0.1, thenDragTo: target)
        wait { (gain.value as? String)?.hasSuffix("%") == true && gain.value as? String != "100%" }
        let savedGain = try XCTUnwrap(gain.value as? String)
        capture("04-book-gain-adjusted")
        let unavailable = app.staticTexts["Spotify gain • unavailable (not a live level)"]
        show(unavailable)
        XCTAssertTrue(unavailable.waitForExistence(timeout: 10), app.debugDescription)
        capture("05-spotify-manual-limits")
        show(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Sleep timer controls the book only")).firstMatch)
        capture("06-manual-test-checklist")
        XCUIDevice.shared.orientation = .landscapeLeft
        wait { self.app.frame.width > self.app.frame.height }
        capture("07-landscape")
        XCUIDevice.shared.orientation = .portrait
        wait { self.app.frame.height > self.app.frame.width }
        app.terminate()
        app.launch()
        XCTAssertTrue(entry.waitForExistence(timeout: 30))
        entry.tap()
        if !enabled.waitForExistence(timeout: 5) && entry.exists { entry.tap() }
        XCTAssertTrue(enabled.waitForExistence(timeout: 15), app.debugDescription)
        show(gain)
        wait { gain.value as? String == savedGain }
        XCTAssertEqual(gain.value as? String, savedGain)
        capture("08-native-settings-restored-after-relaunch")
    }
}
