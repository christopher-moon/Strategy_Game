import GameplayKit
import SpriteKit

enum Team: String, Codable {
    case player
    case enemy
    case neutral
}

class Entity: GKEntity {
    //general stats
    let id = UUID()
    let name: String
    var team: Team
    //logical position
    var gridPosition: TilePosition
    //visual position is now accessed dynamically via the component
    //var visualPosition: CGPoint {
        //return self.component(ofType: GKSKNodeComponent.self)?.node.position ?? .zero
    //}
    //state machine ("brain")
    var stateMachine: GKStateMachine!
    
    init(name: String, team: Team, startPos: TilePosition, startPoint: CGPoint) {
        self.name = name
        self.team = team
        self.gridPosition = startPos
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }
}

//MARK: COMPONENTS
class VisualComponent: GKSKNodeComponent {
 
}

class HealthComponent: GKComponent {
    var max: Int
    var current: Int
    //true if entity is a physical blocker that can be bumped into
    var isStaticObstacle: Bool
    
    //initializer would be below (takes only max hp)
    init(hp: Int, isStaticObstacle: Bool){
        self.max = hp
        self.current = hp
        self.isStaticObstacle = isStaticObstacle
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }
}

class CombatComponent: GKComponent {
    var damage: Int
    var range: Int
    var threatRange: Int
    var attackSpeed: Int
    
    init(damage: Int, range: Int, threatRange: Int, attackSpeed: Int){
        self.damage = damage
        self.range = range
        self.threatRange = threatRange
        self.attackSpeed = attackSpeed
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }
}

class MovementComponent: GKAgent2D {
    override init() {
        super.init()
        self.radius = 30
        self.maxSpeed = 100
        self.maxAcceleration = 50
    }
    required init?(coder: NSCoder) { fatalError() }
}
