import GameplayKit
import SpriteKit

enum Team: String, Codable {
    case player
    case enemy
    case neutral
}

class Entity: GKEntity {
    let id = UUID()
    let name: String
    var team: Team
    
    // Logical Grid Position (for turn-based logic)
    var gridPosition: TilePosition
    
    // Brain
    var stateMachine: GKStateMachine!
    
    init(name: String, team: Team, startPos: TilePosition) {
        self.name = name
        self.team = team
        self.gridPosition = startPos
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - COMPONENTS

// The bridge between logic and pixels
class VisualComponent: GKSKNodeComponent {
    
    override func agentDidUpdate(_ agent: GKAgent) {
        // 1. Cast the agent to 2D
        guard let agent2D = agent as? GKAgent2D else { return }
        
        // 2. Cast the node to your specific EntityNode class
        // We use "as?" here because 'node' is a standard SKNode
        guard let entityNode = node as? EntityNode else { return }
        
        // 3. Snap the position
        entityNode.position = CGPoint(x: CGFloat(agent2D.position.x),
                                      y: CGFloat(agent2D.position.y))
        
        // 4. Force upright rotation
        entityNode.zRotation = 0
    }
    
    // This is called every frame by the GKComponentSystem
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        // GKSKNodeComponent automatically links the node to the entity
        guard let entityNode = node as? EntityNode, let entity = self.entity as? Entity else { return }
        
         
        // Sync the labels and animations
        entityNode.update(entity: entity, deltaTime: seconds)
    }
}

class MovementComponent: GKAgent2D {
    var targetPosition: vector_float2?
    var isPaused: Bool = false
    var mapManager: MapManager? // Still needed for the occupancy sync call
    private var lastGridPos: TilePosition?

    override init() {
        super.init()
        self.radius = 26
        self.maxSpeed = 100
        self.behavior = nil
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // We keep syncOccupancy here because it updates the Entity's data
    func syncOccupancy() {
        guard let entity = self.entity as? Entity, let manager = mapManager else { return }
        let currentGridPos = manager.calculateGridPos(from: CGPoint(x: CGFloat(position.x), y: CGFloat(position.y)))
        if lastGridPos == nil { lastGridPos = entity.gridPosition }
        if currentGridPos != lastGridPos {
            manager.moveEntity(entity.id, from: lastGridPos!, to: currentGridPos)
            entity.gridPosition = currentGridPos
            lastGridPos = currentGridPos
        }
    }
}

class HealthComponent: GKComponent {
    var max: Int
    var current: Int
    var isStaticObstacle: Bool
    
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
