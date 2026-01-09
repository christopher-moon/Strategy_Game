//spawn logic
import SpriteKit

class ObjectFactory {
    unowned let manager: UnitManager
    
    init(manager: UnitManager) {
        self.manager = manager
    }
    
    //spawn unit
    func spawnUnit(type: String, team: Team, aiBrain: UnitAIBrain, at tile: TileNode) {
        guard let scene = manager.scene else { return }
        
        // 1. Get the blueprint
        guard let blueprint = UnitRegistry.data[type] else {
            print("Unit \(type) does not exist!")
            return
        }
        
        // 2. Create the data model
        let newUnit = Unit(
            name: blueprint.name,
            team: team,
            ai: aiBrain,
            hp: blueprint.maxHP,
            maxHP: blueprint.maxHP,
            attack: blueprint.attack,
            range: blueprint.range,
            threatRange: blueprint.threatRange,
            attackSpeed: blueprint.attackSpeed,
            attackPattern: blueprint.attackPattern,
            movementSpeed: blueprint.movementSpeed,
            position: tile.tile.position
        )
        
        // 3. Create the Visual Node
        let unitNode = UnitNode(unit: newUnit, tileSize: scene.tileSize)
        unitNode.setVisualPosition(to: tile)
        
        // 4. Add to the scene hierarchy
        scene.gridNode.addChild(unitNode)
        
        // 5. Register
        manager.units[newUnit.id] = unitNode
        manager.gridManager.registerOccupancy(id: newUnit.id, pos: tile.tile.position)
    }
    
    //spawn obstacle
    func spawnObstacle(type: String, at tile: TileNode) {
        guard let scene = manager.scene else { return }
        guard let blueprint = ObstacleRegistry.data[type] else { return }
        
        let newObstacle = Obstacle(
            name: blueprint.name,
            type: blueprint.type,
            position: tile.tile.position,
            hp: blueprint.hp,
            blocksMovement: blueprint.blocksMovement,
            attack: blueprint.attack
        )
        
        let obstacleNode = ObstacleNode(obstacle: newObstacle, tileSize: scene.tileSize)
        obstacleNode.setVisualPosition(to: tile)
        scene.gridNode.addChild(obstacleNode)
        
        // Register in the dedicated manager
        manager.obstacleManager.obstacles[newObstacle.id] = obstacleNode
        manager.gridManager.registerOccupancy(id: newObstacle.id, pos: tile.tile.position)
    }
}
