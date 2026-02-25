import GameplayKit
import SpriteKit

enum Team: String, Codable {
    case player
    case enemy
    case neutral
}

//MARK: General Entity
class Entity: GKEntity {
    let id = UUID()
    let name: String
    var team: Team
    //what tile the entity is on (for turn-based logic)
    var gridPosition: TilePosition
    //entity brain
    var stateMachine: GKStateMachine!
    //spawn/lifetime timer
    var timer: TimeInterval
    
    init(name: String, team: Team, startPos: TilePosition, timer: TimeInterval) {
        self.name = name
        self.team = team
        self.gridPosition = startPos
        self.timer = timer
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: Entity Components

//visual component
class VisualComponent: GKComponent {
    let node: EntityNode
    
    init(node: EntityNode) {
        self.node = node
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }
}

//movement component (can move)
class MovementComponent: GKComponent {
    var speed: Float
    var radius: Float
    var mass: Float
    
    var path: [vector_float2] = []
    var physics: Bool
    var position: vector_float2

    init(speed: Float, radius: Float, mass: Float, physics: Bool, initialPosition: CGPoint){
        self.speed = speed
        self.radius = radius
        self.mass = mass
        self.physics = physics
        self.position = vector_float2(Float(initialPosition.x), Float(initialPosition.y))
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }
}

//health component (can take damage and die)
class HealthComponent: GKComponent {
    var max: Int
    var current: Int
    
    //if this is true, the tile this entity is on is treated as impassable
    var isStaticObstacle: Bool
    
    init(hp: Int, isStaticObstacle: Bool){
        self.max = hp
        self.current = hp
        self.isStaticObstacle = isStaticObstacle
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }
}

//combat component (can deal damage)
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

//movement cost component (can block/affect pathfinding)
class MovementCostComponent: GKComponent {
    let movementCost: Float
    
    init(movementCost: Float){
        self.movementCost = movementCost
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }

}
