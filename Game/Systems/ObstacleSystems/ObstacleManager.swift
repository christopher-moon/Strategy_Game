import SpriteKit
import Foundation

class ObstacleManager {
    weak var scene: GameScene?
    let gridManager: GridManager
    
    var factory: ObjectFactory? {
            return scene?.unitManager.factory
    }
    
    var obstacles: [UUID: ObstacleNode] = [:]

    init(scene: GameScene, gridManager: GridManager) {
        self.scene = scene
        self.gridManager = gridManager
    }
    
    func spawnObstacle(type: String, at tile: TileNode) {
        factory?.spawnObstacle(type: type, at: tile)
    }
    

    func obstacleAt(_ pos: TilePosition) -> ObstacleNode? {
        if let id = gridManager.entityAtTile[pos] {
            return obstacles[id]
        }
        return nil
    }

    func removeObstacle(_ obstacle: ObstacleNode) {
        //logical removal
        obstacles.removeValue(forKey: obstacle.obstacle.id)
        gridManager.clearOccupancy(at: obstacle.obstacle.position)
        //visual removal
        obstacle.die { }
    }
}
