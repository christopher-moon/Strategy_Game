/*
 Blueprints_MK3.swift:
 entity blueprint used for reading data from json
*/
import Foundation

struct EntityBlueprint_MK3: Codable {
    let name: String
    
    // Core Physics
    let movementCost: Int?
    let isImpassable: Bool?
    let obeysReservation: Bool?
    
    // Component Data (Optional)
    let health: HealthBlueprint?
    let movement: MovementBlueprint?
    let combat: CombatBlueprint?
    let aiType: String?
}

struct HealthBlueprint: Codable {
    let hp: Int
}

struct MovementBlueprint: Codable {
    let speed: Int
    let isFlying: Bool?
    let movementType: MovementType
}

struct CombatBlueprint: Codable {
    let attack: Int
    let attackSpeed: Int
    let range: Int
    let pattern: String // "single", "aoe"
}

struct GameDataContainer_MK3: Codable {
    // Now we just have one big dictionary of "Templates"
    let templates: [String: EntityBlueprint_MK3]
}
