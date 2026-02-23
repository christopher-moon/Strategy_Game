/*
 Blueprints_MK3.swift:
 entity blueprint used for reading data from json
*/
import Foundation

struct EntityBlueprint_MK3: Codable {
    let name: String
    
    //ai type (optional)
    let ai: String?
        
    // Component Data (Optional)
    let health: HealthBlueprint?
    let combat: CombatBlueprint?
    let movement: MovementBlueprint?
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

struct GameDataContainer_MK3: Codable {
    // Now we just have one big dictionary of "Templates"
    let templates: [String: EntityBlueprint_MK3]
}
