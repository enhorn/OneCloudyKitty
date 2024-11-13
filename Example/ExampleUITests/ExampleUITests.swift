//
//  OneExampeUITests.swift
//  OneExampeUITests
//
//  Created by Robin Enhorn on 2024-11-12.
//

import XCTest

let app = XCUIApplication()

final class OneExampeUITests: XCTestCase {
    let createdEntity = UUID()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchEnvironment["UI_TESTING"] = "true"
        app.launch()
    }

    @MainActor
    func testExample() throws {
        try app.staticTexts["State: Idle"].wait()
        try app.buttons["Add Entity"].tapWhenVisible()

        try app.staticTexts["State: Creating"].wait()
        try app.staticTexts["State: Updating property"].wait()
        try app.staticTexts["State: Updating"].wait()
        try app.staticTexts["State: Fetching entities"].wait()
        try app.staticTexts["State: Deleting"].wait()
        try app.staticTexts["State: Idle"].wait()
    }

}

extension XCUIElement {

    enum WaitError: Error {
        case timeout
    }

    @discardableResult
    func tapWhenVisible(timeout: TimeInterval = 10) throws -> Self {
        let element = try wait(for: 10)
        element.tap()
        return element
    }

    @discardableResult
    func wait(for timeout: TimeInterval = 10) throws -> Self {
        if waitForExistence(timeout: 10) {
            return self
        } else {
            throw WaitError.timeout
        }
    }

}
