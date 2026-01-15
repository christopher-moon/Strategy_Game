/*
 Entity_MK2.swift:
 define entity protocol
 entities are general, dynamic game pieces
*/
import Foundation

enum Team: String, Codable {
    case player, enemy, neutral
}

//all entities must have these things
protocol Entity_MK2: AnyObject {
    var id: UUID { get }
    var team: Team { get }
    var hp: Int { get set }
    var attack: Int { get } // Add this!
    var position: TilePosition { get set }
    var movementCost: Int { get }
    var ai: AIBrain_MK2? { get set }
    
    //common take damage function
    func takeDamage(_ amount: Int)
    
}
