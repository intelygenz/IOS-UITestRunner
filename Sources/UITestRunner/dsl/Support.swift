import Foundation
import GherkParser
import XCTest

extension Step {
    func runIf(_ tag: String, _ name: String, _ action: () throws -> Void) throws -> Bool {
        if match(tag, name) {
            try action()
            return true
        } else {
            return false
        }
    }
    
    func match(_ tag: String, _ name: String) -> Bool {
        return self.tag.lowercased() == tag.lowercased() && matchName(name)
    }
    
    private func matchName(_ name: String) -> Bool {
        self.name == name
            || Regex(name).matches(self.name.trimmingCharacters(in: .whitespacesAndNewlines))
            || self.name.classCamelCase == name
    }
}

extension String {
    var fileName: String {
        return URL(string: self)!.lastPathComponent
    }
}


private class Regex {
    private let pattern: String
    init(_ pattern: String) { self.pattern = pattern }
    func matches(_ str: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        return regex.firstMatch(in: str, options: [], range: NSRange(location:0, length: str.count)) != nil
    }
}

extension Bool {
    
    func skipOnFalse() throws {
        try XCTSkipIf(!self, "Skipped test")
    }
}


func asFeatureId(_ feature: String) -> String {
    return feature.hasSuffix(".feature") ? feature : "\(feature).feature"
}

func asScenarioId(_ scenario: String) -> String {
    return scenario.trimmingCharacters(in: .whitespacesAndNewlines)
}

