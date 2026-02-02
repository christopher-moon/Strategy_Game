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
    
    //systems
    let aiSystem = AISystem()
    //let movementSystem = MovementSystem() // Instantiate the system
        
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
            //will likely use GKComponentSystems for ai and combat
            //call the update functions for the component systems here
            let tickDuration = timeManager.tickRate
            aiSystem.update(entityManager: entityManager, deltaTime: tickDuration)
        }
        
        //continous movement (update movement agents)
        //movementSystem.update( deltaTime: deltaTime)
        

    }
    
    //move
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: mapManager.worldNode)
        let gridPos = mapManager.calculateGridPos(from: location)
        
        print("moving to \(gridPos)")
            
        if let playerUnit = entityManager.allEntities.first(where: { $0.team == .player }) {
            //movementSystem.orderMove(for: playerUnit, to: gridPos)
        }
    }

    func spawnLevelEntities(from data: LevelData) {
        guard let entities = data.entities else { return }
        
        for entityData in entities {
            let pos = TilePosition(row: entityData.row, col: entityData.col)
            
            // Convert String team to Enum (default to enemy if missing)
            let team = Team(rawValue: entityData.team ?? "neutral") ?? .neutral
            
            let entity = EntityFactory.spawn(type: entityData.type,
                                    at: pos,
                                    team: team,
                                    manager: entityManager,
                                    mapManager: mapManager
            )
        }
    }
}
