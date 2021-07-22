import Foundation
import XCTest
import GherkParser

public class GherkinEngine {
    private static let parser = GherkParser()
    private static var map = [Bundle: GherkinTestRunner]()
    public static func getRunner(_ bundle: Bundle) -> GherkinTestRunner {
        guard let runner = map[bundle] else {
            let newRunner = GherkinTestRunner(bundle, bundle.infoDictionary!["CFBundleName"] as! String, parser)
            map[bundle] = newRunner
            return newRunner
        }
        return runner
    }
}

public protocol GherkinParser {
    func parse(_ url: URL) throws -> [Feature]
}

extension GherkParser: GherkinParser {}


public struct FeatureMatch {
    public let featureId: String
    public let scenarios: [ScenarioMatch]
    public init(featureId: String, scenarios: [ScenarioMatch]) {
        self.featureId = featureId
        self.scenarios = scenarios
    }
}

public struct ScenarioMatch {
    public let featureId: String
    public let scenarioId: String
    public let steps: [StepMatch]
    public let backgroundSteps: [StepMatch]?
    public init(featureId: String, scenarioId: String, steps: [StepMatch], backgroundSteps: [StepMatch]?) {
        self.featureId = featureId
        self.scenarioId = scenarioId
        self.steps = steps
        self.backgroundSteps = backgroundSteps
    }
}

public struct StepMatch {
    public let execute: (Step) throws -> Bool
    public init(execute: @escaping (Step) throws -> Bool) {
        self.execute = execute
    }
}

public class GherkinTestRunner {
    private let bundle: Bundle
    let moduleName: String
    private let config = GherkinConfiguration.config
    private let parser: GherkinParser
    private var executedScenarios = [Scenario]()
    lazy var features: [Feature] = try! parser.parse(bundle.resourceURL!)

    public init(_ bundle: Bundle, _ moduleName: String, _ parser: GherkinParser) {
        self.bundle = bundle
        self.moduleName = moduleName
        self.parser = parser
    }
    
    public func assertFeatureExists(_ featureId: String) throws -> Feature {
        let feature = features.first(where: { $0.matches(featureId) })
        return try assertNotNil(feature, "Expected Feature \(featureId)")
    }
    
    public func assertScenarioExists(_ featureId: String, _ scenarioId: String) throws -> Scenario {
        let feature = try assertFeatureExists(featureId)
        let scenario = feature.scenarios.first(where: { $0.matches(scenarioId) })
        return try assertNotNil(scenario, "Expected Scenario \(featureId) \(scenarioId)")
    }
    
    public func background(_ featureId: String) throws -> Scenario? { try assertFeatureExists(featureId).background }
    
    public func runFeature(_ featureMatch: FeatureMatch) throws -> Bool {
        let feature = try assertFeatureExists(featureMatch.featureId)
        guard !shouldBeIgnored(feature) else { return false }
        try featureMatch.scenarios.forEach{ _ = try runScenario($0) }
        return true
    }
    
    public func runScenario(_ scenarioMatch: ScenarioMatch) throws -> Bool {
        let feature = try assertFeatureExists(scenarioMatch.featureId)
        let scenario = try assertScenarioExists(scenarioMatch.featureId, scenarioMatch.scenarioId)
        guard !shouldBeIgnored(feature) && !shouldBeIgnored(scenario) else { return false }
        if let background = feature.background, let stepMatches = scenarioMatch.backgroundSteps {
            try runSteps(background, stepMatches)
        }
        try runSteps(scenario, scenarioMatch.steps)
        return true
    }
    
    private func runSteps(_ scenario: Scenario, _ steps: [StepMatch]) throws {
        if !scenario.stepDescriptions.isEmpty && steps.isEmpty { throw GherkRunnerError(message: "\(scenario.isBackground ? "Background" : "Scenario") not defined: \(scenario.description)")}
        try scenario.stepDescriptions.forEach{ definedStep in
            _ = try assertNotNil(steps.first(where: { try $0.execute(definedStep) }), "Not found Step:\(scenario.isBackground ? " (background)" : "") \(definedStep.tag) \(definedStep.name)")
        }
    }
    
    private func shouldBeIgnored(_ feature: Feature) -> Bool {
        config.annotationsStatus(feature.annotations) == .excluded
    }
    
    private func shouldBeIgnored(_ scenario: Scenario) -> Bool {
        config.annotationsStatus(scenario.annotations) == .excluded
    }

}

private func assertNotNil<T>(_ value: T?, _ message: String) throws -> T {
    switch value {
    case .none: throw GherkRunnerError(message: message)
    case .some(let value): return value
    }
}


struct GherkRunnerError: Error {
    let message: String
}


private extension Scenario {
    func matches(_ id: String) -> Bool {
        description == id || description.methodCamelCase == id || description.methodCamelCase == id.methodCamelCase || "test\(description.classCamelCase)" == id
    }
}

private extension Feature {
    func matches(_ id: String) -> Bool {
        description == id || description.classCamelCase == id || path == id || path.hasSuffix(id)
    }
}

