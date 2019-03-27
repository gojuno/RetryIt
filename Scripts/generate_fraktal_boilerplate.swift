#!/usr/bin/env swift

import Foundation

// Templates

struct Templates: OptionSet {
    mutating func formUnion(_ other: Templates) { self = Templates(rawValue: rawValue.union(other.rawValue)) }
    mutating func formIntersection(_ other: Templates) { self = Templates(rawValue: rawValue.intersection(other.rawValue)) }
    mutating func formSymmetricDifference(_ other: Templates) { self = Templates(rawValue: rawValue.symmetricDifference(other.rawValue)) }

    let rawValue: Set<String>
    init(rawValue: Set<String>) { self.rawValue = rawValue }
    init(_ value: String) { self.init(rawValue: [value]) }
    init() { self.init(rawValue: []) }

    static let empty = Templates()
    var isEmpty: Bool { return self == .empty }
}

extension Templates {
    // V2
    static let presentableV2 = Templates("AutoPresentableV2")
    static let presentersV2 = Templates("AutoPresentersV2")
    static let anyPresentableEnumV2Constructor = Templates("AutoAnyPresentableEnumV2Constructor")
    static let anyPresentableEnumV2Declaration = Templates("AutoAnyPresentableEnumV2Declaration")
    static let mockPresentableV2 = Templates("AutoMockPresentableV2")

    static let moduleV2: Templates = [.presentableV2, .presentersV2, .anyPresentableEnumV2Constructor, .anyPresentableEnumV2Declaration]
}

// imports

struct Imports {
    let normal: [String]
    let testable: [String]

    init(normal: [String] = [], testable: [String] = []) {
        self.normal = normal
        self.testable = testable
    }

    var arguments: [String] {
        return normal.map { "import=\($0)" } + testable.map { "testableImport=\($0)"}
    }
}

// Arguments

let env = ProcessInfo.processInfo.environment as [String: String]
let arguments: [String] = CommandLine.arguments.count <= 1 ? [] : Array(CommandLine.arguments.dropFirst())

@discardableResult
func bash(_ command: String) -> Int32 {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", command]
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

// Sourcery

func sourcery(sources: String, templates: Templates, output: String, imports: Imports) {
    guard !templates.isEmpty else { return }
    let sourceryPath = "./thirdparty/sourcery/sourcery"
    let templatesArg = templates.rawValue.map { "--templates ./Scripts/fraktal_templates/\($0).swifttemplate" }.joined(separator: " ")
    let argumentsArg = imports.arguments.map { "--args \($0)" }.joined(separator: " ")
    bash("\(sourceryPath) --sources \(sources) \(templatesArg) --output \(output) \(argumentsArg)")
}

sourcery(sources: "RetryIt", templates: .moduleV2, output: "RetryIt/Generated", imports: Imports(normal: ["ReactiveSwift"]))
