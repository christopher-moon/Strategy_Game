//tile struct (contains numerical info)

//different types of tiles
enum TerrainType: String, Codable{
    case ground
    case wall
    case objective
}

//store tile position
struct TilePosition: Hashable, Codable {
    let row: Int
    let col: Int
}

//tile (terrain and position)
struct Tile: Codable {
    let position: TilePosition
    var terrain: TerrainType
    var isObjectiveZone: Bool = false
}
