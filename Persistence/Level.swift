//level struct
import Foundation

// represents a single tiless state in the JSON
struct TileData: Codable {
    let row: Int
    let col: Int
    let terrain: String // e.g., "ground", "wall", "objective"
}

// Represents a unit or obstacle to be spawned
struct EntityData: Codable {
    let type: String
    let row: Int
    let col: Int
    let team: String?
    let ai: String?
}

// The master level structure
struct LevelData: Codable {
    let name: String
    let rows: Int
    let cols: Int
    let tiles: [TileData]
    let entities: [EntityData]
}

