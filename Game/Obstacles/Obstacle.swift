//obstacle struct
import Foundation

enum ObstacleType {
    case laserWall, electricWall, mine, fence, generator
}

enum ObstacleState: String {
    case active = "active"
    case inactive = "inactive"
    case broken = "broken"
}


struct Obstacle {
    var id = UUID()
    var name: String
    let type: ObstacleType
    var position: TilePosition
    var isDestroyed: Bool = false
    
    // State-specific variables
    var state: ObstacleState = .active
    var hp: Int? // Only for Fence/Generator
    var ownerID: UUID? // For linking Walls to Generators
    
    var blocksMovement: Bool
    var attack: Int?
    
    //var direction: String = "vertical"
}

