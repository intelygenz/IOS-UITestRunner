import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(UITestRunnerTests.allTests),
    ]
}
#endif
