/* Entity_MK2.swift */
import Foundation

// MARK: - Enums & Data Types

enum Team: String, Codable {
    case player
    case enemy
    case neutral
}

enum Direction: String {
    case left
    case right
}

enum MovementType: String, Codable {
    case simple //linear, no costs
    case smart  //cost based A*
}

// Unified State Machine
enum EntityState: Equatable {
    case spawning   // Initializing/Animation
    case idle       // Ready for action
    case stuck      // path blocked by unit
    case alerted    // spotted enemy
    case moving     // Transitioning between tiles
    case attacking(targetID: UUID?) // Actively engaging
    case disabled   // Stunned or inactive trap
    case dead       // Marked for cleanup
}

// Defines how damage is applied (Supports your Aura, Beam, Blast requirements)
enum AttackPattern {
    case singleTarget       // single target melee hit
    case aoe(radius: Int) // bombs, explosions, etc
    case projectile(name: String)
}

// MARK: - The Container

class Entity_MK3 {
    // 1. Identity
    let id = UUID()
    var name: String
    var team: Team
    var position: TilePosition
    
    // The "Brain" of the entity state
    var state: EntityState = .spawning
    
    // 2. Grid Physics (Base Layer)
    var movementCost: Int = 5
    var isImpassable: Bool = false
    var obeysReservation: Bool = false
    
    var patrolPoints: [TilePosition] = []
    var currentPatrolIndex: Int = 0

    
    // 3. Components (The "Modules")
    var health: HealthComponent?         // Damageable
    var movement: MovementComponent?     // Mobile
    var combat: CombatComponent?         // Offensive
    var projectile: ProjectileComponent? // Projectiles
    var status: StatusComponent?         // Buffs/Debuffs (NEW)
    var lifecycle: LifecycleComponent?   // Temporary (Projectiles/Effects)
    var ai: AIBrain_MK3?                 // Intelligence

    init(name: String, team: Team, position: TilePosition) {
        self.name = name
        self.team = team
        self.position = position
    }
}

// MARK: - Components

class HealthComponent {
    var current: Int
    var max: Int
    
    var isDead: Bool { return current <= 0 }
    
    init(hp: Int) {
        self.current = hp
        self.max = hp
    }
    
    func takeDamage(_ amount: Int) {
        current -= amount
    }
}

class MovementComponent {
    var speed: Int
    var internalTickCounter: Int = 0
    var currentPath: [TilePosition] = []
    var isFlying: Bool
    var direction: Direction = .right
    var movementType: MovementType
    var waitTimer: Int = 0
    
    init(speed: Int, isFlying: Bool = false, movementType: MovementType) {
        self.speed = speed
        self.isFlying = isFlying
        self.movementType = movementType
    }
}

class CombatComponent {
    // Stats
    var attack: Int
    var attackSpeed: Int
    var threatRange: Int
    var range: Int
    
    // NEW: Defines "How" it hits (Beam, Blast, etc)
    var attackPattern: AttackPattern
    
    // State Tracking
    var internalAttackCounter: Int = 0
    var currentTargetID: UUID?
    
    //track if entity should destroy itself after attacking
    var selfDestruct: Bool = false
    
    init(attack: Int, attackSpeed: Int, range: Int, threatRange: Int = 1, pattern: AttackPattern = .singleTarget, selfDestruct: Bool) {
        self.attack = attack
        self.attackSpeed = attackSpeed
        self.range = range
        self.threatRange = threatRange
        self.attackPattern = pattern
        self.selfDestruct = selfDestruct
    }
}

// NEW: Handles Stuns, Poisons, Slows
class StatusComponent {
    struct ActiveEffect {
        let name: String
        var duration: Int
        let strength: Int // e.g., damage per tick or slow amount
    }
    
    var effects: [ActiveEffect] = []
    var isStunned: Bool = false
    
    // You can add logic here or in a StatusSystem
    func addEffect(_ effect: ActiveEffect) {
        effects.append(effect)
    }
}

class LifecycleComponent {
    var ticksRemaining: Int
    // Useful for visuals: "Play this animation when I die"
    var deathAnimation: String?
    
    init(ticks: Int, deathAnim: String? = nil) {
        self.ticksRemaining = ticks
        self.deathAnimation = deathAnim
    }
}

class ProjectileComponent {
    var targetID: UUID
    var screenPosition: CGPoint
    var speed: CGFloat // Points per second
    var damage: Int
    
    var velocity: CGPoint = .zero 
    
    static var tileSize: CGFloat = 64.0
    static var offsetX: CGFloat = 0 // Add these
    static var offsetY: CGFloat = 0
    
    init(targetID: UUID, screenPosition: CGPoint, speed: CGFloat = 400.0, damage: Int) {
        self.targetID = targetID
        self.screenPosition = screenPosition
        self.speed = speed
        self.damage = damage
    }

    // Helper: Logic calculates virtual pixels using the active scale
    static func getLogicalScreenPos(for pos: TilePosition) -> CGPoint {
        return CGPoint(
            x: offsetX + (CGFloat(pos.col) * tileSize),
            y: offsetY + (CGFloat(pos.row) * tileSize)
        )
    }

    static func getTilePos(for screenPos: CGPoint) -> TilePosition {
        return TilePosition(
            row: Int(round(screenPos.y / tileSize)),
            col: Int(round(screenPos.x / tileSize))
        )
    }

}
