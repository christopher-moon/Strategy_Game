/* GameScene_MK3.swift */
import SpriteKit
import GameplayKit

class GameScene_MK3: SKScene {
    var lastUpdateTime: TimeInterval = 0
    
    //managers
    let timeManager = TimeManager()
    let mapManager = MapManager()
    let entityManager = EntityManager()
    
    //systems
    let aiSystem = AISystem()
    let movementSystem = MovementSystem()
    let visualSystem = VisualSystem()
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .gray // Makes it easier to see the map boundaries
        
        //add the map's container to the scene
        self.addChild(mapManager.worldNode)
        
        if let levelData = LevelManager.loadLevel(fileName: "testlevel2") {
            mapManager.buildMap(from: levelData)
            mapManager.generateNavGraph()
            mapManager.fitMapToScreen(screenSize: self.size)
            spawnLevelEntities(from: levelData)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        if timeManager.update(delta: deltaTime) {
            let tickDuration = timeManager.tickRate
            aiSystem.update(entityManager: entityManager, deltaTime: tickDuration)
        }
        
        movementSystem.update(entityManager: entityManager, mapManager: mapManager, deltaTime: deltaTime)
        visualSystem.update(entityManager: entityManager, deltaTime: deltaTime)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            
            // Get touch location relative to the map container
            let location = touch.location(in: mapManager.worldNode)
            
            // Convert screen touch to logical grid position
            let targetGridPos = mapManager.calculateGridPos(from: location)
            
            // Ensure the tapped tile is actually on the map
            guard mapManager.grid[targetGridPos] != nil else { return }
            
            // For testing: Command ALL player entities to move to the tapped location
        for entity in entityManager.allEntities where (entity.team == .player || entity.team == .enemy) {
                commandEntityToMove(entity: entity, targetGridPos: targetGridPos)
            }
        }

    func commandEntityToMove(entity: Entity, targetGridPos: TilePosition) {
        guard let moveComp = entity.component(ofType: MovementComponent.self) else { return }
        
        // Ask MapManager for the path
        let newPath = mapManager.findPath(from: entity.gridPosition, to: targetGridPos)
        
        if newPath.isEmpty {
            print("No valid path found for \(entity.name)")
            return
        }
        
        // Simply assign it
        moveComp.path = newPath
    }

    func spawnLevelEntities(from data: LevelData) {
        guard let entities = data.entities else { return }
        
        for entityData in entities {
            let pos = TilePosition(row: entityData.row, col: entityData.col)
            let team = Team(rawValue: entityData.team ?? "neutral") ?? .neutral
            
            if let entity = EntityFactory.spawn(type: entityData.type, at: pos, team: team, mapManager: mapManager, entityManager: entityManager){
                //entityManager.addEntity(entity)
            }
        }
    }
}
