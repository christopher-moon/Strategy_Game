import Foundation
import GameplayKit

enum TerrainType: String, Codable {
    case ground = "."
    case wall = "W"
    case objective = "O"
}

struct TilePosition: Hashable, Codable {
    let row: Int
    let col: Int
}

// Individual map tile
// Each tile functions as terrain, a container for entities, and a navigation node
class Tile {
    let position: TilePosition
    var terrain: TerrainType
    
    // Occupants
    var occupants: Set<UUID> = []
    
    // Nav node (Moved completely into the Tile)
    let navNode: WeightedNode
    
    // Flag to set a tile as a wall, to avoid adding to pathfinding graph
    var isWalkable: Bool { terrain != .wall }
    var cost: Float
    
    // Calculate movement cost of tile and auto-sync to nav node
    func calculateCost(entityManager: EntityManager) -> Float {
        // Default cost
        cost = 1.0
        
        // Terrain costs
        if terrain == .objective {
            cost = 10.0
        }
        
        // Entity costs
        for entityID in occupants {
            if let entity = entityManager.getEntity(by: entityID),
                let costComp = entity.component(ofType: MovementCostComponent.self) {
                    cost += costComp.movementCost
            }
        }
        
        // Sync calculated cost to the navigation node
        navNode.weight = cost
        
        return cost
    }
    
    init(position: TilePosition, terrain: TerrainType, screenPos: CGPoint) {
        self.position = position
        self.terrain = terrain
        self.cost = 1.0
        
        // Initialize the nav node exactly where the tile is
        self.navNode = WeightedNode(point: vector_float2(Float(screenPos.x), Float(screenPos.y)), gridPos: position)
    }
}
