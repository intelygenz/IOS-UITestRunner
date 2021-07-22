import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BuilderTests.allTests),
        testCase(ClassPathTests.allTests)
    ]
}
#endif
