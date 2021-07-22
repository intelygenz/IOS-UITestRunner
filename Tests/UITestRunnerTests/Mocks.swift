import XCTest
@testable import GherkParser
@testable import UITestRunner


func mockRunner() throws -> GherkinTestRunner {
    return GherkinTestRunner(Bundle(for: MockGherkinParser.self), "UITestRunnerTests", MockGherkinParser())
}

private class MockGherkinParser: GherkinParser {
    func parse(_ url: URL) throws -> [Feature] {
        [Feature(path: "features/LogIn.feature",
                 annotations: [],
                 description: "Log In",
                 scenarios: [
                    Scenario(
                        featurePath: "features/LogIn.feature",
                        annotations: [],
                        description: "Log in",
                        stepDescriptions: [
                            Step(tag: "Given", name: "I am at the Login Screen"),
                            Step(tag: "When", name: "I input my email address"),
                            Step(tag: "And", name: "I input my password"),
                            Step(tag: "And", name: "I tap the Log In button"),
                            Step(tag: "Then", name: "I see the Dashboard screen")
                        ],
                        index: 0,
                        isBackground: false
                    ),
                    Scenario(
                        featurePath: "features/LogIn.feature",
                        annotations: [],
                        description: "Attempt to log in with an invalid password",
                        stepDescriptions: [
                            Step(tag: "Given", name: "I am at the Login Screen"),
                            Step(tag: "When", name: "I input my email address"),
                            Step(tag: "And", name: "I input the password \"bad_password\""),
                            Step(tag: "And", name: "I tap the Log In button"),
                            Step(tag: "Then", name: "I see an alert view with the message 'Sorry, your email or password is invalid'")
                        ],
                        index: 0,
                        isBackground: false
                    ),
                    
                 
                 ], background: Scenario(
                    featurePath: "features/LogIn.feature",
                    annotations: [],
                    description: "some preconditions",
                    stepDescriptions: [
                        Step(tag: "Given", name: "I am at the App"),
                        Step(tag: "And", name: "There is internet")
                    ],
                    index: 0,
                    isBackground: true))
        
        ]
    }
    
    
}
