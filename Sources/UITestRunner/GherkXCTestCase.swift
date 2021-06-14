
import Foundation
import ObjectiveC
import XCTest
import GherkParser

open class GherkXCTestCase: XCTestCase {
    public var bundle: Bundle { Bundle(for: type(of: self)) }
    public var runner: GherkinTestRunner { GherkinEngine.getRunner(bundle) }
}

open class MissingScenariosXCTestCase: GherkXCTestCase {
    public func assertMissingScenarios() throws { try runner.assertMissingScenarios() }
}

open class ScenarioXCTestCase: GherkXCTestCase {
    open var feature: String? { nil }
    open var scenario: String? { nil }
    open func background(_ builder: ScenarioBuilder) {}
    public func run(_ build: @escaping (ScenarioBuilder) -> Void) throws { try runner.assertScenario(feature!, scenario!, build) { self.background($0) } }
    
    open override func setUp() { continueAfterFailure = false }
}

open class FeatureXCTestCase: GherkXCTestCase {
    open var feature: String? { info.name }
    open func background(_ builder: ScenarioBuilder) {}
    public func scenario(_ scenario: String, _ build: @escaping (ScenarioBuilder) -> Void) throws { try runner.assertScenario(feature!, scenario, build) { self.background($0) } }
    public func scenario(_ build: @escaping (ScenarioBuilder) -> Void) throws { try scenario(info.testName, build) }
    
    open override func setUp() { continueAfterFailure = false }
}
