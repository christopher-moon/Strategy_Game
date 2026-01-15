/*
 Unit_MK2.swift:
 specialize logic for Unit type entities
*/
import Foundation

enum Facing { case left, right }

enum UnitState {
    case idle
    case moving
    case attacking(target: Entity_MK2)
    case dead
    case spawning
}

class Unit_MK2: Entity_MK2 {
    //entity required fields 
    let id = UUID()
    var team: Team
    var hp: Int
    var attack: Int
    var position: TilePosition
    var movementCost: Int
    var ai: AIBrain_MK2?
    //unit fields
    var name: String
    var speed: Int
    var attackSpeed: Int
    var range: Int
    var threatRange: Int
    var facing: Facing = .right
    var state: UnitState = .idle
    var currentTarget: UUID?
    
    var currentPath: [TilePosition] = []
    
    var internalTickCounter = 0
    var internalAttackCounter = 0
    
    init(typeName: String, startPos: TilePosition, team: Team) {
        self.name = typeName
        self.team = team
        self.position = startPos
        
        // Note the use of .shared here
        let stats = Library_MK2.shared.units[typeName] ?? Library_MK2.shared.units["Warrior"]!
        
        self.hp = stats.hp
        self.speed = stats.movementSpeed
        self.attack = stats.attack
        self.range = stats.range
        self.threatRange = stats.threatRange
        self.movementCost = 20
        self.ai = Unit_MK2.resolveBrain(type: stats.aiType)
        self.attackSpeed = stats.attackSpeed
    }
    
    // Helper Factory to convert String -> Class
    private static func resolveBrain(type: String?) -> AIBrain_MK2 {
        switch type {
        case "follower":
            return FollowerBrain()
        case "attacker":
            return AttackerBrain()
        //case "objective":
            //return ObjectiveRunnerBrain()
        // Future cases:
        // case "Aggressive": return AggressiveBrain()
        // case "Healer": return HealerBrain()
        default:
            return FollowerBrain() // Default fallback if missing or misspelled
        }
    }

    //MARK: TAKE DAMAGE
    func takeDamage(_ amount: Int) {
        self.hp -= amount
    }
    
    func setTarget(target: TilePosition, grid: Grid_MK2) {
        self.currentPath = Pathfinding_MK2.findPath(from: self.position, to: target, grid: grid)
        // Remove the first element because it's the tile we are currently standing on
        if !currentPath.isEmpty { currentPath.removeFirst() }
    }
}
