import AstrojectCore
import AstrojectSync

struct Rocket {
    func go() {
        print("Pointy End Up. Flamed End Down.")
    }
}

protocol Vehicle: AnyObject {
    func go()
}

class Car: Vehicle {
    var wheels: [Wheel]
    
    var _gas: Int = 0
    var gas: Int {
        set { _gas = min(100, max(0, newValue)) }
        get { _gas }
    }
    
    init(_ gas: Int = 50, wheels: [Wheel]) {
        self.gas = gas
        self.wheels = wheels
    }
    
    func go() {
        if gas > 0 {
            print("Moving along")
        } else {
            print("Out of Gas")
        }
    }
}

struct Wheel {
    var pressure: Bool = true
    var rim: Bool = true
    var tire: Bool = true
}

// Registration types can be a protocol, class, or struct. Enums can be used as well but it's not recommended.

struct VehicleAssembly: Assembly {
    func assemble(container: any Container) throws {
        try container.register(Rocket.self) {
            Rocket()
        }
        
        try container.register(Car.self, argumentType: Int.self) { resolver, gas in
            let wheel = try resolver.resolve(Wheel.self)
            return Car(gas, wheels: Array(repeating: wheel, count: 4))
        }
        .implements(Vehicle.self, in: container)
        .asWeak()
    }
}

let assembler = Assembler()
