/* GameScene_MK3.swift:
 Highest level logic. Now uses the Modular Component system.
*/
import SpriteKit
import GameplayKit

class GameScene_MK3: SKScene {
    var lastUpdateTime: TimeInterval = 0
    //var visualNodes: [UUID: EntityNode] = [:]
    
    //managers
    let timeManager = TimeManager()
    let mapManager = MapManager()
    let entityManager = EntityManager()
    lazy var systemManager = SystemManager(mapManager: self.mapManager)
    
    //tick-based systems
    let aiSystem = AISystem()
    //let combatSystem = CombatSystem()
    
    //helper systems
        
    override func didMove(to view: SKView) {
        //add the map's container to the scene
        self.addChild(mapManager.worldNode)
        //load the JSON (using your LevelManager)
        if let levelData = LevelManager.loadLevel(fileName: "testlevel4") {
            //build logical map from level data
            mapManager.buildMap(from: levelData)
            //generate navigation map 
            mapManager.generateNavGraph()
            //initial positioning: fit the map to the screen size
            mapManager.fitMapToScreen(screenSize: self.size)
            //spawn entities
            spawnLevelEntities(from: levelData)
        }
    }
    
    //tick + visual updates
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        //logical tick (will eventually run ai/system calls here)
        if timeManager.update(delta: deltaTime) {
            let tickDuration = timeManager.tickRate
            aiSystem.update(entityManager: entityManager, deltaTime: tickDuration)
        }
        //frame-based logic (movement and visuals)
        if timeManager.paused == false {
            systemManager.update(deltaTime: deltaTime)
        }
    }
    
    //move
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: mapManager.worldNode)
        let targetVec = vector_float2(Float(location.x), Float(location.y))
        
        // 1. Grab all entities that are capable of moving
        let movers = entityManager.allEntities.compactMap { $0.component(ofType: MovementComponent.self) }
        
        print("Commanding \(movers.count) units to move to \(location)")

        // 2. Assign the same target to everyone
        for moveComp in movers {
            // Optional: Add a tiny bit of random variance to the target
            // if you want to see them fight for slightly different spots
            moveComp.targetPosition = targetVec
        }
    }

    func spawnLevelEntities(from data: LevelData) {
        guard let entities = data.entities else { return }
        
        for entityData in entities {
            let pos = TilePosition(row: entityData.row, col: entityData.col)
            
            // Convert String team to Enum (default to enemy if missing)
            let team = Team(rawValue: entityData.team ?? "neutral") ?? .neutral
            
            if let entity = EntityFactory.spawn(type: entityData.type, at: pos, team: team, mapManager: mapManager){
                entityManager.addEntity(entity)
                systemManager.addEntity(entity)
            }
        }
    }
}
