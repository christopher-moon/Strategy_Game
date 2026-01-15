/*
 Obstacle_MK2.swift:
 specialize logic for Obstacle type entities
*/
import Foundation

enum ObstacleState {
    case active
    case inactive
    case broken
    case dead
    case spawning
}

class Obstacle_MK2: Entity_MK2 {
    
    //entity required fields 
    let id = UUID()
    var team: Team
    var hp: Int
    var attack: Int
    var position: TilePosition
    var movementCost: Int
    var ai: AIBrain_MK2?
    //obstacle fields
    var name: String
    var state: ObstacleState = .spawning
    
    var internalTickCounter = 0
    
    init(typeName: String, startPos: TilePosition, team: Team) {
        self.name = typeName
        self.team = team
        self.position = startPos
        
        // Note the use of .shared here
        let stats = Library_MK2.shared.obstacles[typeName] ?? Library_MK2.shared.obstacles["Mine"]!
        
        self.hp = stats.hp
        self.attack = stats.attack
        self.movementCost = stats.movementCost
    }
    
    //MARK: TAKE DAMAGE
    func takeDamage(_ amount: Int) {
        self.hp -= amount
    }
}
