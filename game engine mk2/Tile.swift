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
    
    // flag to set a tile as hard unwalkable to prevent units from moving onto it
    var isWalkable: Bool { terrain != .wall }
    
    //pathfinding movement cost calculation: this will return a total cost for a tile based on terrain + entities
    var moveCost: Float {
        //for now, this just returns 1 for each tile (the base cost), but eventually, this will be based on terrain + entities
        var cost: Float = 1.0
        if terrain == .objective {
            cost = 10.0
        }
        return cost
    }
    
    init(position: TilePosition, terrain: TerrainType) {
        self.position = position
        self.terrain = terrain
    }
}
