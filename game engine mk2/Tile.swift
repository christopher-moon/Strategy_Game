import Foundation

enum TerrainType: String, Codable {
    case ground = "."
    case wall = "W"
    case objective = "O"
}

struct TilePosition: Hashable, Codable {
    let row: Int
    let col: Int
}

//individual map tile
//each tile functions as a terrain + a container for entities
class Tile {
    let position: TilePosition
    var terrain: TerrainType
    
    //"container" for tracking entities on the tile
    var occupants: Set<UUID> = []
    
    // flag to set a tile as hard unwalkable to block pathfinding, not sure if i actually need this if i base pathfinding logic off of cost instead
    var isWalkable: Bool { terrain != .wall }
    
    //pathfinding movement cost calculation: this will return a total cost for a tile based on terrain + entities
    var moveCost: Int {
        //for now, this just returns 1 for each tile (the base cost), but eventually, this will be based on terrain + entities
        var cost = 1
        return cost
    }
    
    init(position: TilePosition, terrain: TerrainType) {
        self.position = position
        self.terrain = terrain
    }
}
