/*
 Blueprints_MK3.swift:
 entity blueprint used for reading data from json
*/
import Foundation

enum AiType: String, Codable {
    case passive    // e.g., Walls, Barrels
    case aggressive // e.g., Melee units
    case objective  // e.g., Scouts/Runners
}

struct EntityBlueprint_MK3: Codable {
    let name: String
    let timer: TimeInterval
    
    //ai type
    let ai: AiType
        
    // Component Data (Optional)
    let health: HealthBlueprint?
    let combat: CombatBlueprint?
    let movement: MovementBlueprint?
    let movementCost: MovementCostBlueprint?
}

struct HealthBlueprint: Codable {
    let hp: Int
    let blocking: Bool
}

struct CombatBlueprint: Codable {
    let damage: Int
    let range: Int
    let threatRange: Int
    let attackSpeed: Int
}

struct MovementBlueprint: Codable {
    let speed: Float
    let radius: Float
    let mass: Float
    let physics: Bool
}

struct MovementCostBlueprint: Codable {
    let movementCost: Float
}

struct GameDataContainer_MK3: Codable {
    // Now we just have one big dictionary of "Templates"
    let templates: [String: EntityBlueprint_MK3]
}
