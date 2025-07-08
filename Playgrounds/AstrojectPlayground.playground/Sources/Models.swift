//
//  Models.swift
//
//
//  Created by Porter McGary on 6/29/25.
//

import Foundation

public protocol Logger {
    func log(_ message: String)
}

public protocol TelemetryService {
    func transmit(data: String)
}

public protocol RocketEngine {
    var thrust: Int { get }
    func ignite()
}

public protocol MissionPlanner {
    func planMission(to destination: Planet) -> MissionPlan
}

public struct MissionPlan {
    let destination: Planet
    let crewCount: Int
    let launchDate: Date
}

public struct Astronaut {
    let name: String
    let specialty: Specialty
}

public enum Specialty {
    case pilot, engineer, scientist
}

public enum Planet: String {
    case mars = "Mars"
    case europa = "Europa"
    case titan = "Titan"
}

public enum EngineType {
    case ion, chemical, fusion
}

public final class ConsoleLogger: Logger {
    public init() {}
    
    public func log(_ message: String) {
        print("[LOG] \(message)")
    }
}

public final class DeepSpaceTelemetry: TelemetryService {
    private let logger: Logger
    
    public init(logger: Logger) {
        self.logger = logger
    }
    
    public func transmit(data: String) {
        logger.log("Transmitting: \(data)")
    }
}

public final class IonEngine: RocketEngine {
    public let thrust: Int
    
    public init(thrust: Int = 100) {
        self.thrust = thrust
    }
    
    public func ignite() {
        print("Ion engine ignited with \(thrust) thrust!")
    }
}

public final class FusionEngine: RocketEngine {
    public let thrust: Int
    
    public init(thrust: Int = 1000) {
        self.thrust = thrust
    }
    
    public func ignite() {
        print("Fusion engine roars with \(thrust) thrust!")
    }
}

public final class DefaultMissionPlanner: MissionPlanner {
    public init() {}
    
    public func planMission(to destination: Planet) -> MissionPlan {
        MissionPlan(destination: destination, crewCount: 4, launchDate: .now)
    }
}

public final class MockLogger: Logger {
    public func log(_ message: String) {
        // do nothing
    }
}

public final class MockTelemetryService: TelemetryService {
    public func transmit(data: String) {
        print("Mock transmit: \(data)")
    }
}

public final class MissionControl {
    private let telemetry: TelemetryService
    private let planner: MissionPlanner
    private let logger: Logger
    
    public init(telemetry: TelemetryService, planner: MissionPlanner, logger: Logger) {
        self.telemetry = telemetry
        self.planner = planner
        self.logger = logger
    }
    
    func launch(to planet: Planet) {
        let plan = planner.planMission(to: planet)
        logger.log("Mission planned to \(planet.rawValue) with \(plan.crewCount) astronauts.")
        telemetry.transmit(data: "Launching to \(planet.rawValue) at \(plan.launchDate)")
    }
}

/// | Astroject Feature   | Demo Component                                          |
/// | ------------------- | ------------------------------------------------------- |
/// | Singleton           | `Logger`, `TelemetryService`                            |
/// | Prototype           | `RocketEngine`                                          |
/// | Graph               | `MissionControl` → `TelemetryService` → `Logger`        |
/// | Named Registrations | Multiple `RocketEngine` variants                        |
/// | Post-init Hook      | Logger printing after resolution                        |
/// | Arguments           | Registering `Astronaut(name:)` or `Rocket(engineType:)` |
/// | Mock Swapping       | Replace `TelemetryService` in test                      |
/// | Weak Scope          | Disposable `TemporaryCommsLink` object                  |
/// | Circular Detection  | (If desired) `Planner` → `MissionControl` → `Planner`   |
