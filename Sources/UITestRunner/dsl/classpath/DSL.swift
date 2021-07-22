import Foundation
import XCTest

fileprivate class ScenarioNotifier {
    private static var list = [(String, String)]()
    static func notify(_ feature: String, _ scenario: String) { list.append((feature, scenario)) }
    static func get() -> [(String, String)] { list }
}

public extension GherkinTestRunner {
    
    func assertAllScenariosExecuted() throws {
        let expected = features.flatMap { feature in feature.scenarios.map { (asFeatureId(feature.path.fileName), asScenarioId($0.description) )}}
        let executed = ScenarioNotifier.get()
        let nonExecuted = expected.filter { e in executed.contains(where: { $0.0 == e.0 && $0.1 == e.1 }) }
        if !nonExecuted.isEmpty {
            throw GherkRunnerError(message: "Some scenarios where not executed \(nonExecuted)")
        }
    }
    
    func runFeature(_ featureName: String) throws {
        let featureId = asFeatureId(featureName.fileName).replacingOccurrences(of: ".feature", with: "")
        let feature = try assertFeatureExists(featureId)
        let backgroundClass: AnyFeat? = try feature.background.map { background in try anyScenarioFromName(moduleName, "\(featureId.classCamelCase)_\(background.description.classCamelCase)") }
        let scenarioMatches: [ScenarioMatch] = try feature.scenarios.map { scenario in
            let scenarioClass: AnyFeat = try anyScenarioFromName(moduleName, "\(featureId.classCamelCase)_\(scenario.description.classCamelCase)")
            return try scenarioMatch(featureId, scenario.description, scenarioClass, backgroundClass)
        }
        feature.scenarios.forEach { ScenarioNotifier.notify(featureId, $0.description) }
        try runFeature(FeatureMatch(featureId: featureId, scenarios: scenarioMatches)).skipOnFalse()
    }
    
    func runScenario(_ featureName: String, _ scenarioName: String) throws {
        let featureId = asFeatureId(featureName.fileName).replacingOccurrences(of: ".feature", with: "")
        let scenarioId = asScenarioId(scenarioName)
        let scenarioClass: AnyFeat = try anyScenarioFromName(moduleName, "\(featureId.classCamelCase)_\(scenarioId.classCamelCase)")
        let backgroundClass: AnyFeat? = try assertFeatureExists(featureId).background.map { background in try anyScenarioFromName(moduleName, "\(featureId.classCamelCase)_\(background.description.classCamelCase)") }
        let match = try scenarioMatch(featureId, scenarioId, scenarioClass, backgroundClass)
        ScenarioNotifier.notify(featureId, scenarioId)
        try runScenario(match).skipOnFalse()
    }
    
}

private func scenarioMatch(_ feature: String, _ scenario: String, _ scenarioClass: AnyFeat, _ backgroundClass: AnyFeat?) throws -> ScenarioMatch {
    let scenarioInfo = try obtainObjectInfo(of: scenarioClass)
    let backgroundInfo = try backgroundClass.map { try obtainObjectInfo(of: $0) }
    return ScenarioMatch(
        featureId: feature,
        scenarioId: scenario,
        steps: scenarioInfo.methods.map{ method in StepMatch { try $0.runIf(method.tag, method.name, method.action) }  },
        backgroundSteps: backgroundInfo.map { $0.methods.map{ method in StepMatch { try $0.runIf(method.tag, method.name, method.action) } } })
}


open class AllScenariosXCTestCase: XCTestCase {
    public var bundle: Bundle { Bundle(for: type(of: self)) }
    public var runner: GherkinTestRunner { GherkinEngine.getRunner(bundle) }
    
    public func runFeature(_ featureId: String) throws {
        try runner.runFeature(featureId)
    }
    
    public func runScenario(_ featureId: String, _ scenarioId: String) throws {
        try runner.runScenario(featureId, scenarioId)
    }
    
}
