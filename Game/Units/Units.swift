import Foundation
import CoreGraphics

enum Team { case player, enemy }
//enum UnitRole { case melee, objective }

enum UnitState: String {
    case idle = "idle"
    case moving = "moving"
    case attacking = "attacking"
    case dead = "dead"
}

struct Unit {
    //indentifiers
    var id = UUID()
    var name: String
    var team: Team
    //var role: UnitRole
    //ai module
    var ai: UnitAIBrain
    //stats
    var hp: Int
    var maxHP: Int
    var attack: Int
    var range: Int
    var threatRange: Int
    //attackcooldown in ticks
    var attackSpeed: Int
    //attack type
    var attackPattern: AttackPattern
    //fast (1), medium (2), or slow (3)
    var movementSpeed: Int
    var movementCooldown: Int = 0
    //logical tile position
    var position: TilePosition
    //pathing helpers
    var currentGoal: TilePosition? = nil
    var currentPath: [TilePosition]? = nil
    var needsRepath: Bool = false
    var currentTargetID: UUID?
    //state
    var state: UnitState = .idle
    //mission lock
    var isMissionLocked: Bool = false
    //direction
    var direction: String = "right"
}

