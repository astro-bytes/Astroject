//
//  RegistrationReport.swift
//  Astroject
//
//  Created by Porter McGary on 11/16/26.
//

import Foundation

#if canImport(os)
import os
#endif

/// Where a registration came from.
///
/// Containers record a source for every `register` and `forward` call. The `register`
/// overloads capture `#fileID` and `#line` from the call site, and an `Assembler` adds the
/// name of the assembly that is running.
public struct RegistrationSource: Sendable, Equatable, CustomStringConvertible {
    /// The name of the assembly that made the registration, or `nil` outside an assembler.
    public let assembly: String?
    /// The `#fileID` of the call that made the registration, or `nil` when it isn't known.
    public let fileID: String?
    /// The `#line` of the call that made the registration, or `nil` when it isn't known.
    public let line: UInt?
    /// The product type this registration was forwarded from, when it was made by `forward`.
    public let forwardedFrom: String?

    /// Creates a registration source.
    ///
    /// - Parameters:
    ///   - assembly: The name of the assembly that made the registration.
    ///   - fileID: The `#fileID` of the call that made the registration.
    ///   - line: The `#line` of the call that made the registration.
    ///   - forwardedFrom: The product type this registration was forwarded from.
    public init(
        assembly: String? = nil,
        fileID: String? = nil,
        line: UInt? = nil,
        forwardedFrom: String? = nil
    ) {
        self.assembly = assembly
        self.fileID = fileID
        self.line = line
        self.forwardedFrom = forwardedFrom
    }

    /// The file name and line, such as `DataAssembly.swift:12`, or `nil` when unknown.
    public var location: String? {
        guard let fileID else { return nil }
        let file = fileID.split(separator: "/").last.map(String.init) ?? fileID
        guard let line else { return file }
        return "\(file):\(line)"
    }

    /// The assembly that is running, set by `Assembler` while it calls `assemble(container:)`.
    @TaskLocal public static var currentAssembly: String?
    
    /// The outermost `register` call site, set by the `register` overloads.
    @TaskLocal public static var currentCallSite: RegistrationSource?
    
    public var description: String {
        [assembly, location, forwardedFrom.map { "forwarded from \($0)" }]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

// MARK: - Capturing sources

public extension RegistrationSource {
    /// The source for a registration being made right now.
    ///
    /// Container implementations call this from their `register` and `forward` requirements.
    static var current: RegistrationSource {
        let callSite = currentCallSite
        return RegistrationSource(
            assembly: currentAssembly,
            fileID: callSite?.fileID,
            line: callSite?.line
        )
    }

    /// Runs `body` with `fileID` and `line` as the call site of the registration it makes.
    ///
    /// When a call site is already set, it is kept, so a `register` overload that calls
    /// another one reports the caller's location rather than its own.
    ///
    /// - Parameters:
    ///   - fileID: The `#fileID` of the call site.
    ///   - line: The `#line` of the call site.
    ///   - body: The registration to run.
    /// - Returns: What `body` returns.
    static func withCallSite<T>(
        fileID: String,
        line: UInt,
        _ body: () throws -> T
    ) rethrows -> T {
        guard currentCallSite == nil else { return try body() }
        return try $currentCallSite.withValue(RegistrationSource(fileID: fileID, line: line)) {
            try body()
        }
    }
}

// MARK: - Report

/// Every registration a container has received, grouped by key, in the order they were made.
///
/// Registration is last one wins, so the last registration for each key is the one the
/// container resolves. Use the report to see which keys were registered more than once,
/// and where each registration came from.
///
/// ```swift
/// let report = container.registrationReport()
/// for entry in report.overridden {
///     print(entry.title, entry.winner)
/// }
/// ```
public struct RegistrationReport: Sendable, CustomStringConvertible {
    /// One key and every registration made for it.
    public struct Entry: Sendable {
        /// The key the registrations were made for.
        public let key: RegistrationKey
        /// Every registration made for the key, oldest first.
        public let sources: [RegistrationSource]

        /// The registration the container resolves, which is the last one made.
        public var winner: RegistrationSource { sources[sources.count - 1] }

        /// Whether the key was registered more than once.
        public var isOverridden: Bool { sources.count > 1 }

        /// The key's product type, followed by its name and argument type when it has them.
        public var title: String {
            var title = String(describing: key.productType)
            var details: [String] = []
            if let name = key.name {
                details.append("name: \"\(name)\"")
            }
            if key.argumentType != Empty.self {
                details.append("argument: \(String(describing: key.argumentType))")
            }
            if !details.isEmpty {
                title += " (\(details.joined(separator: ", ")))"
            }
            return title
        }
    }

    /// Every registered key, in the order each key was first registered.
    public let entries: [Entry]

    /// Creates a report from its entries.
    ///
    /// - Parameter entries: Every registered key, in the order each key was first registered.
    public init(entries: [Entry] = []) {
        self.entries = entries
    }

    /// The keys that were registered more than once.
    public var overridden: [Entry] { entries.filter(\.isOverridden) }

    /// The full report, listing every key.
    public var description: String { formatted(onlyOverridden: false) }

    /// Formats the report as a tree, one key per block, marking the registration that wins.
    ///
    /// ```text
    /// Astroject: 42 keys registered, 1 overridden
    /// PuzzleRepositoryProtocol
    ///   ├─ DataAssembly        DataAssembly.swift:12
    ///   └─ TestMocksAssembly   TestMocksAssembly.swift:4   ← wins
    /// ```
    ///
    /// - Parameter onlyOverridden: When `true`, lists only keys that were registered more
    ///   than once. Defaults to `true`.
    /// - Returns: The formatted report.
    public func formatted(onlyOverridden: Bool = true) -> String {
        let shown = onlyOverridden ? overridden : entries
        var lines = ["Astroject: \(entries.count) keys registered, \(overridden.count) overridden"]

        let assemblyWidth = shown
            .flatMap(\.sources)
            .map { ($0.assembly ?? "-").count }
            .max() ?? 0
        let locationWidth = shown
            .flatMap(\.sources)
            .map { Self.location(of: $0).count }
            .max() ?? 0

        for entry in shown {
            lines.append(entry.title)
            for (index, source) in entry.sources.enumerated() {
                let isLast = index == entry.sources.count - 1
                let branch = isLast ? "└─" : "├─"
                let assembly = Self.pad(source.assembly ?? "-", to: assemblyWidth)
                let location = Self.location(of: source)
                if isLast, entry.isOverridden {
                    lines.append("  \(branch) \(assembly)   \(Self.pad(location, to: locationWidth))   ← wins")
                } else {
                    lines.append(Self.trimTrailing("  \(branch) \(assembly)   \(location)"))
                }
            }
        }
        return lines.joined(separator: "\n")
    }

    private static func location(of source: RegistrationSource) -> String {
        if let forwardedFrom = source.forwardedFrom {
            return "forwarded from \(forwardedFrom)"
        }
        return source.location ?? "unknown location"
    }

    private static func pad(_ text: String, to width: Int) -> String {
        text.count >= width ? text : text + String(repeating: " ", count: width - text.count)
    }

    private static func trimTrailing(_ text: String) -> String {
        var text = text
        while text.last == " " { text.removeLast() }
        return text
    }
}

// MARK: - Recorder

/// Records every registration a container receives, so the container can build a `RegistrationReport`.
///
/// Container implementations call `record(_:source:)` from their `register` and `forward`
/// requirements, and `reset()` from `clear()`. It is safe to use from any thread.
public final class RegistrationRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var order: [RegistrationKey] = []
    private var sources: [RegistrationKey: [RegistrationSource]] = [:]

    /// Creates an empty recorder.
    public init() {}

    /// Records a registration for `key`.
    ///
    /// - Parameters:
    ///   - key: The key that was registered.
    ///   - source: Where the registration came from. Defaults to `RegistrationSource.current`.
    public func record(_ key: RegistrationKey, source: RegistrationSource = .current) {
        lock.lock()
        defer { lock.unlock() }
        if sources[key] == nil {
            order.append(key)
        }
        sources[key, default: []].append(source)
    }

    /// Removes every recorded registration.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        order.removeAll()
        sources.removeAll()
    }

    /// A report of every recorded registration.
    public func report() -> RegistrationReport {
        lock.lock()
        defer { lock.unlock() }
        return RegistrationReport(entries: order.map { key in
            RegistrationReport.Entry(key: key, sources: sources[key] ?? [])
        })
    }
}

// MARK: - Logging

public extension RegistrationReport {
    /// Writes the report of overridden keys to the console through `os.Logger`,
    /// with the subsystem `Astroject`.
    ///
    /// - Parameter onlyOverridden: When `true`, lists only keys that were registered more
    ///   than once. Defaults to `true`.
    func log(onlyOverridden: Bool = true) {
        let text = formatted(onlyOverridden: onlyOverridden)
        #if canImport(os)
        Logger(subsystem: "Astroject", category: "Registration").notice("\(text, privacy: .public)")
        #else
        print(text)
        #endif
    }
}
