import AstrojectCore
import AstrojectSync

let container = SyncContainer()

try container.register(Logger.self) {
    ConsoleLogger()
}
.asSingleton()

try container.register(TelemetryService.self) { resolver in
    let logger = try resolver.resolve(Logger.self)
    return DeepSpaceTelemetry(logger: logger)
}

try container.register(RocketEngine.self, name: "ion") {
    IonEngine()
}
.asTransient()

try container.register(RocketEngine.self, name: "fusion") {
    FusionEngine()
}
.asTransient()

try container.register(MissionPlanner.self) {
    DefaultMissionPlanner()
}

try container.register(MissionControl.self) { resolver in
    let telemetry = try resolver.resolve(TelemetryService.self)
    let planner = try resolver.resolve( MissionPlanner.self)
    let logger = try resolver.resolve(Logger.self)
    
    return MissionControl(
        telemetry: telemetry,
        planner: planner,
        logger: logger
    )
}
.asSingleton()
