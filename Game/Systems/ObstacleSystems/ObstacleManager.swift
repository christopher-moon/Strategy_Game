//centralized manager for all logical obstacle information
import SpriteKit

class ObstacleManager {
    
    weak var scene: GameScene?
    let gridManager: GridManager
    
    //track obstacles
    var obstacles: [UUID: ObstacleNode] = [:]
    
    init(scene: GameScene, gridManager: GridManager) {
        self.scene = scene
        self.gridManager = gridManager
    }
    
    //MARK: SPAWN OBSTACLE
    func spawnObstacle(type: String, at tile: TileNode){
        // 1. get the blueprint
        guard let blueprint = ObstacleRegistry.data[type] else {
            print("obstacle \(type) does not exist!")
            return
        }
        // 2. create the obstacle using the blueprint data
        let newObstacle = Obstacle(
            name: blueprint.name,
            type: blueprint.type,
            position: tile.tile.position,
            hp: blueprint.hp,
            blocksMovement: blueprint.blocksMovement,
            attack: blueprint.attack
        )
        // 3. create visual node
        let obstacleNode = ObstacleNode(obstacle: newObstacle, tileSize: scene!.tileSize)
        obstacleNode.setVisualPosition(to: tile)
        // 4. add to scene
        scene?.gridNode.addChild(obstacleNode)
        // 5. add to list of obstacles
        obstacles[newObstacle.id] = obstacleNode
        // 6. regesiter obstacle with gridManager using its unique ID
        gridManager.registerOccupancy(id: newObstacle.id, pos: tile.tile.position)
    }
    
    //MARK: REMOVE OBSTACLE
    func removeObstacle(_ obstacle: ObstacleNode){
        obstacles.removeValue(forKey: obstacle.obstacle.id)
        gridManager.clearOccupancy(at: obstacle.obstacle.position)
        obstacle.removeFromParent()
    }
}

