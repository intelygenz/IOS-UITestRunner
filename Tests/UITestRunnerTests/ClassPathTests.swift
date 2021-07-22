import XCTest
@testable import GherkParser
@testable import UITestRunner

final class ClassPathTests: XCTestCase {
    
    func testRunScenario() throws {
        let runner = try mockRunner()
        try runner.runScenario("features/LogIn.feature", "Log in") 
    }
    
    func testRunScenarioByName() throws {
        let runner = try mockRunner()
        try runner.runScenario("LogIn.feature", "Log in")

    }
    
    func testRunScenarioByNameWithoutExtension() throws {
        let runner = try mockRunner()
        try runner.runScenario("LogIn", "Log in")
    }
    
    func testRunScenarioUndefinedStep() throws {
        let runner = try mockRunner()
        XCTAssertThrowsError(
            try runner.runScenario("features/LogIn.feature", "Attempt to log in with an invalid password")
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


