import Foundation
import XCTest
import GherkParser

public class GherkinEngine {
    private static let parser = GherkParser()
    private static var map = [Bundle: GherkinTestRunner]()
    static func getRunner(_ bundle: Bundle) -> GherkinTestRunner {
        guard let runner = map[bundle] else {
            let newRunner = GherkinTestRunner(bundle, parser)
            map[bundle] = newRunner
            return newRunner
        }
        return runner
    }
}

public class GherkinTestRunner {
    private let config = GherkinConfiguration.config
    private let bundle: Bundle
    private let parser: GherkParser
    private var executedScenarios = [Scenario]()
    private lazy var features: [Feature] = try! parser.parse(bundle.resourceURL!)

    init(_ bundle: Bundle, _ parser: GherkParser) {
        self.bundle = bundle
        self.parser = parser
    }

    func assertMissingScenarios() throws {
        let allTests: Set<TestCaseInfo> = Set(XCTestSuite(forBundlePath: bundle.bundlePath).allTestCaseInfo)
        var expectedTests: Set<TestCaseInfo> = Set(features.flatMap{ feature in feature.scenarios.map{ scenario in TestCaseInfo(name: feature.featureDescription.camelCaseify, testName: scenario.scenarioDescription.camelCaseify) } })
        expectedTests.subtract(allTests)
        XCTAssertTrue(expectedTests.isEmpty, "There are missing scenarios: \(expectedTests)")
    }
    
    func assertScenario(_ featureName: String?, _ scenarioName: String? , _ build: @escaping (ScenarioBuilder) -> Void, _ background: @escaping (ScenarioBuilder) -> Void) throws {
        let featureId = try assertNotNil(featureName, "Feature Name must not be nil")
        let scenarioId = try assertNotNil(scenarioName, "Scenario Name must not be nil")
        let scenario = try assertExistsScenario(featureId, scenarioId)
        let backgroundScenario = try assertExistsBackground(featureId)
        executedScenarios.append(scenario)
        try assertStepsExecution(backgroundScenario, background)
        try assertStepsExecution(scenario, build)
    }
    
    private func assertExistsBackground(_ featureName: String) throws -> Scenario? { try assertExistsFeature(featureName).background }
    
    private func assertExistsScenario(_ featureName: String, _ scenarioName: String) throws -> Scenario {
        let feature = try assertExistsFeature(featureName)
        let scenario = feature.scenarios.first(where: { $0.matches(scenarioName) })
        return try assertNotNil(scenario, "Expected Scenario \(featureName) \(scenarioName)").skipIfNeeded(config, feature)
    }
    
    private func assertExistsFeature(_ featureName: String) throws -> Feature {
        let feature = features.first(where: { $0.matches(featureName) })
        return try assertNotNil(feature, "Expected Feature \(featureName)").skipIfNeeded(config)
    }
    
    private func assertStepsExecution(_ scenario: Scenario?, _ builder: (ScenarioBuilder) -> Void) throws {
        if let scenario = scenario {
            let steps = ScenarioBuilder().apply(builder)
            if steps.isEmpty { throw GherkRunnerError(message: "\(scenario.isBackground ? "Background" : "Scenario") not defined: \(scenario.scenarioDescription)")}
            try scenario.stepDescriptions.map{ step in try assertNotNil(steps.first(where: { step.matches($0) }), "Not found Step \(step.tag) \(step.name)") }
                .forEach{ try $0.action() }
        }
    }

}
private func assertNotNil<T>(_ value: T?, _ message: String) throws -> T {
    switch value {
    case .none: throw GherkRunnerError(message: message)
    case .some(let value): return value
    }
}

private extension Feature {
    func skipIfNeeded(_ config: GherkConfig) throws -> Feature {
        try XCTSkipIf(annotationsStatus(config) == .excluded, "Feature \(config)")
        return self
    }
    
    func annotationsStatus(_ config: GherkConfig) -> GherkConfig.AnnotationStatus {
        config.annotationsStatus(annotations)
    }
}

private extension Scenario {
    func skipIfNeeded(_ config: GherkConfig, _ feature: Feature) throws -> Scenario {
        try XCTSkipIf(isSkipped(config, feature), "\(config)")
        return self
    }
    
    private func isSkipped(_ config: GherkConfig, _ feature: Feature) -> Bool {
        if annotationsStatus(config) == .excluded { return true }
        else if annotationsStatus(config) == .included || feature.annotationsStatus(config) == .included { return false }
        else { return true }
    }
    
    func annotationsStatus(_ config: GherkConfig) -> GherkConfig.AnnotationStatus {
        config.annotationsStatus(annotations)
    }
}

struct GherkRunnerError: Error {
    let message: String
}

public class ScenarioBuilder {
    private var steps = [Step]()
    func build() -> [Step] { steps }
    func appendStep(_ tag: String, _ expression: String, _ action: @escaping () throws -> Void) { steps.append(Step(tag: tag, expression: expression, action: action)) }
    struct Step {
        let tag: String
        let expression: String
        let action: () throws -> Void
    }
}

private extension Step {
    func matches(_ step: ScenarioBuilder.Step) -> Bool {
        tag.lowercased() == step.tag.lowercased() && (name == step.expression)
    }
}

private extension Scenario {
    func matches(_ description: String) -> Bool {
        scenarioDescription == description || scenarioDescription.camelCaseify == description || "test\(scenarioDescription.camelCaseify)" == description
    }
}

private extension Feature {
    func matches(_ description: String) -> Bool {
        featureDescription == description || featureDescription.camelCaseify == description
    }
}

private extension ScenarioBuilder {
    func apply(_ build: (ScenarioBuilder) -> Void) -> [Step] { build(self); return self.build() }
}

public extension ScenarioBuilder {
    func given(_ expression: String, _ action: @escaping () throws -> Void) { append("Given", expression, action) }
    func when(_ expression: String, _ action: @escaping () throws -> Void) { append("When", expression, action) }
    func then(_ expression: String, _ action: @escaping () throws -> Void) { append("Then", expression, action) }
    func and(_ expression: String, _ action: @escaping () throws -> Void) { append("And", expression, action)}
    private func append(_ tag: String, _ expression: String, _ action: @escaping () throws -> Void) {
        appendStep(tag, expression, action)
    }
}

private extension String {
    func starts(with: String, ignoreCase: Bool) -> Bool {
        ignoreCase ? self.lowercased().starts(with: with.lowercased()) : starts(with: with)
    }
}

private extension XCTestSuite {
    var allTestCaseInfo: [TestCaseInfo] {
        allTests.map { $0.info }
    }
    var allTests: [XCTest] {
        var list = [XCTest]()
        var stack = tests
        while !stack.isEmpty {
            let test = stack.removeFirst()
            if let suite = test as? XCTestSuite {
                stack.append(contentsOf: suite.tests)
            } else {
                list.append(test)
            }
        }
        return list
    }
}

public extension XCTest {
    var info: TestCaseInfo {
        TestCaseInfo(name)
    }
}

public struct TestCaseInfo: Hashable, Equatable {
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

