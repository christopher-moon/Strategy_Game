/*
 Blueprints_MK2.swift:
 hold blueprints for Unit and Obstacle type entities
 used for loading level and game data
*/
import Foundation

struct UnitBlueprint_MK2: Codable {
    let hp: Int
    let attack: Int
    let attackSpeed: Int
    let range: Int
    let threatRange: Int
    let movementSpeed: Int
    let patternType: String
    let projectileName: String?
    let aiType: String?
}

struct ObstacleBlueprint_MK2: Codable {
    let hp: Int
    let movementCost: Int
    let attack: Int
}

struct GameDataContainer_MK2: Codable {
    let units: [String: UnitBlueprint_MK2]
    let obstacles: [String: ObstacleBlueprint_MK2]
}


