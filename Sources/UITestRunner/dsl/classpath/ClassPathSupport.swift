import Foundation

typealias AnyFeat = Feat.Type

open class Feat: NSObject {
    private var name: String { String(describing: self) }
    
    open var feature: String {
        var f = String(name.split(separator: "_").first!)
        f = f.firstIndex(of: ".").map { String(f.suffix(from: $0).dropFirst()) } ?? f
        return f.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    open var scenario: String {
        var s = String(name.split(separator: "_").last!).humanReadableString
        s = s.lastIndex(of: ":").map { String(s.prefix(upTo: $0) ) } ?? s
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public required override init() {}
}

func anyScenarioFromName(_ moduleName: String, _ className: String) throws -> AnyFeat {
    let moduleClassName = moduleName.isEmpty ? className : "\(moduleName).\(className)"
    guard let anyclass: AnyClass = NSClassFromString(moduleClassName) else { throw GherkRunnerError(message: "Could not recover class from \(moduleClassName)") }
    return anyclass as! AnyFeat
}

func obtainObjectInfo(of anyScenario: AnyFeat) throws -> AnyFeatInfo {
    guard let info = performObtainObjectInfo(anyScenario) else { throw GherkRunnerError(message: "Could not recover class info from \(anyScenario)") }
    return info
}

struct AnyFeatInfo {
    let feature: String
    let scenario: String
    let methods: [MethodInfo]
}

struct MethodInfo {
    let tag: String
    let name: String
    let action: () throws -> Void
}

private func performObtainObjectInfo(_ anyScenario: AnyFeat) -> AnyFeatInfo? {
    let instance = anyScenario.init()

    let feature = instance.feature
    let scenario = instance.scenario
    guard let methodNames = methodNames(anyScenario) else { return nil }
    let methods = methodNames.compactMap { stepComponents(methodName: $0) }.map{ (tag, name, methodName) -> MethodInfo in

        return MethodInfo(tag: tag, name: name) {
            var error: NSError? = nil
            var pointer: AutoreleasingUnsafeMutablePointer<NSError?>? = AutoreleasingUnsafeMutablePointer<NSError?>(&error)
            defer { pointer = nil }
            let selector = NSSelectorFromString(methodName)
            let imp = instance.method(for: selector)
            unsafeBitCast(imp, to:(@convention(c)(Any?,Selector,OpaquePointer)->Void).self)(instance, selector, OpaquePointer(pointer!))
            if let error = pointer?.pointee { throw error }
            
        }
        
    }
    return AnyFeatInfo(feature: feature, scenario: scenario, methods: methods)
}


private func methodNames(_ anyFeat: AnyFeat) -> [String]? {
    var methodCount: UInt32 = 0
    guard let methodList = class_copyMethodList(anyFeat, &methodCount) else { return nil }
    return (0..<Int(methodCount)).compactMap { String(cString: sel_getName(method_getName(methodList[$0])), encoding: String.Encoding.utf8) }
}

private func stepComponents(methodName: String) -> (String, String, String)? {
    let components = methodName.split(separator: "_").map{ String($0) }
    guard components.count == 2 else { return nil }
    let tag = components.first!
    let method = components.last!.replacingOccurrences(of: "AndReturnError", with: "").replacingOccurrences(of: ":", with: "")
    return (tag, method, methodName)
}
