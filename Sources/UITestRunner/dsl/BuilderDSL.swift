import Foundation
import XCTest

public class ScenarioBuilder {
    fileprivate var steps = [StepMatch]()
    func append(_ step: StepMatch) { steps.append(step) }
}

public extension ScenarioBuilder {
    func given(_ expression: String, _ action: @escaping () throws -> Void) { append(StepMatch { try $0.runIf("Given", expression, action)} ) }  
    func when(_ expression: String, _ action: @escaping () throws -> Void) { append(StepMatch { try $0.runIf("When", expression, action)} ) }
    func then(_ expression: String, _ action: @escaping () throws -> Void) { append(StepMatch { try $0.runIf("Then", expression, action)} ) }
    func and(_ expression: String, _ action: @escaping () throws -> Void) { append(StepMatch { try $0.runIf("And", expression, action)} ) }
}


public extension GherkinTestRunner {
    
    func runScenario(_ feature: String, _ scenario: String, _ builder: @escaping (ScenarioBuilder) -> Void, _ background: ((ScenarioBuilder) -> Void)? = nil) throws {
        let scenarioMatch = ScenarioMatch(featureId: asFeatureId(feature.fileName), scenarioId: asScenarioId(scenario), steps: scenarioBuilder(builder)!, backgroundSteps: scenarioBuilder(background))
        try self.runScenario(scenarioMatch).skipOnFalse()
    }
    
    private func scenarioBuilder(_ builder: ((ScenarioBuilder) -> Void)?) -> [StepMatch]? {
        guard let builder = builder else { return nil }
        let scenario = ScenarioBuilder()
        builder(scenario)
        return scenario.steps
    }
    
}


open class GherkXCTestCase: XCTestCase {
    public var bundle: Bundle { Bundle(for: type(of: self)) }
    public var runner: GherkinTestRunner { GherkinEngine.getRunner(bundle) }
}

open class ScenarioXCTestCase: GherkXCTestCase {
    open var feature: String? { nil }
    open var scenario: String? { nil }
    open func background(_ builder: ScenarioBuilder) {}
    public func run(_ build: @escaping (ScenarioBuilder) -> Void) throws {
        try runner.runScenario(feature!, scenario!, build) { self.background($0) }
    }
    
    open override func setUp() { continueAfterFailure = false }
}

open class FeatureXCTestCase: GherkXCTestCase {
    open var feature: String? { info.name }
    open func background(_ builder: ScenarioBuilder) {}
    public func scenario(_ scenario: String, _ build: @escaping (ScenarioBuilder) -> Void) throws {
        try runner.runScenario(feature!, scenario, build) { self.background($0) }
        
    }
    public func scenario(_ build: @escaping (ScenarioBuilder) -> Void) throws {
        try scenario(info.testName, build)
    }
    
    open override func setUp() { continueAfterFailure = false }
}


private extension XCTest {
    var info: TestCaseInfo { TestCaseInfo(name) }
}

private struct TestCaseInfo: Hashable, Equatable {
    public let name: String
    public let testName: String
    
    init(_ fullName: String) {
        let cleanFullName = fullName.trimmingCharacters(in: ["-", "[", "]"])
        name = String(cleanFullName.split(separator: " ")[0])
        testName = String(cleanFullName.split(separator: " ")[1]).replacingOccurrences(of: "test", with: "")
    }
    
    init(name: String, testName: String) {
        self.name = name
        self.testName = testName
    }
}
