import Foundation

enum GherkConfig {
    case includeAll
    case include(_ includedTags: [String], _ skippedTags: [String])
}

extension GherkConfig: CustomStringConvertible {
    var description: String {
        switch self {
        case .includeAll: return "include all tests"
        case .include(let included, let skipped):
            switch (included.isEmpty, skipped.isEmpty) { 
            case (false, false): return "Not tagged as \(included) or tagged as \(skipped)"
            case (true, false): return "Tagged as \(skipped)"
            case (false, true): return "Not tagged as \(included)"
            case (true, true): return ""
            }
        }
    }
}

extension GherkConfig {
    
    enum AnnotationStatus { case included, excluded, unspecified }
    
    func annotationsStatus(_ annotations: [String]) -> AnnotationStatus {
        switch self {
        case .includeAll: return .included
        case .include(let includedTags, let skippedTags):
            if shouldBeExcluded(annotations, skippedTags) { return .excluded }
            else if shouldBeIncluded(annotations, includedTags) { return .included }
            else { return .unspecified }
        }
    }
    
    private func shouldBeIncluded(_ annotations: [String], _ tags: [String]) -> Bool {
        guard !tags.isEmpty else { return true }
        return annotations.contains { tags.contains($0) }
    }
    
    private func shouldBeExcluded(_ annotations: [String], _ tags: [String]) -> Bool {
        guard !tags.isEmpty else { return false }
        return annotations.contains { tags.contains($0) }
    }
}

class GherkinConfiguration {
    static var config: GherkConfig {
        let map = toMap(CommandLine.arguments)
        let skippedTags = map["--skip"] ?? [String]()
        let includedTags = map["--include"] ?? [String]()
        if !skippedTags.isEmpty || !includedTags.isEmpty { return .include(includedTags, skippedTags) }
        return .includeAll
    } 
}

private func toMap(_ arguments: [String]) -> [String: [String]] {
    var cleanArguments = arguments; cleanArguments.removeFirst()
    var map = [String: [String]]()
    var values = [String]()
    var key = ""
    var args = cleanArguments
    while !args.isEmpty {
        let arg = args.removeFirst()
        if arg.starts(with: "-") {
            if !key.isEmpty {
                map[key] = values
                key = ""
                values = [String]()
            }
            key = arg
        } else {
            values.append(arg)
        }
    }
    map[key] = values
    return map
}
