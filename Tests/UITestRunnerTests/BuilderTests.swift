import XCTest
@testable import GherkParser
@testable import UITestRunner

final class BuilderTests: XCTestCase {
    
    func testRunScenario() throws {
        let runner = try mockRunner()
        try runner.runScenario("features/LogIn.feature", "Log in") { builder in
            builder.given("I am at the Login Screen") {}
            builder.when("I input my email address") {}
            builder.and("I input my password") {}
            builder.and("I tap the Log In button") {}
            builder.then("I see the Dashboard screen") {}
        }
    }
    
    func testRunScenarioByName() throws {
        let runner = try mockRunner()
        try runner.runScenario("LogIn.feature", "Log in") { builder in
            builder.given("I am at the Login Screen") {}
            builder.when("I input my email address") {}
            builder.and("I input my password") {}
            builder.and("I tap the Log In button") {}
            builder.then("I see the Dashboard screen") {}
        }
    }
    
    func testRunScenarioByNameWithoutExtension() throws {
        let runner = try mockRunner()
        try runner.runScenario("LogIn", "Log in") { builder in
            builder.given("I am at the Login Screen") {}
            builder.when("I input my email address") {}
            builder.and("I input my password") {}
            builder.and("I tap the Log In button") {}
            builder.then("I see the Dashboard screen") {}
        }
    }
    
    func testRunScenarioUndefinedStep() throws {
        let runner = try mockRunner()
        XCTAssertThrowsError(
            try runner.runScenario("features/LogIn.feature", "Log in") { builder in
                builder.given("I am at the Login Screen") {}
                builder.when("I input my email address") {}
           //     builder.and("I input my password") {}
                builder.and("I tap the Log In button") {}
                builder.then("I see the Dashboard screen") {}
            }
        ) {
            XCTAssertTrue($0 is GherkRunnerError)
        }

    }

    static var allTests = [
        ("testRunScenario", testRunScenario),
        ("testRunScenarioByName", testRunScenarioByName),
        ("testRunScenarioByNameWithoutExtension", testRunScenarioByNameWithoutExtension),
        ("testRunScenarioUndefinedStep", testRunScenarioUndefinedStep)
    ]
}


