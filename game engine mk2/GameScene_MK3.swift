/* GameScene_MK3.swift:
 Highest level logic. Now uses the Modular Component system.
*/
import SpriteKit

class GameScene_MK3: SKScene {
    var lastUpdateTime: TimeInterval = 0
    var visualNodes: [UUID: EntityNode_MK3] = [:]
    
    // Managers (Updated to MK3)
    let timeManager = TimeManager_MK3()
    let mapManager = MapManager_MK3()
    let grid = Grid_MK3()
    let entityManager = EntityManager_MK3() // Updated
    
    // Systems (These will need to be updated to handle Entity_MK3 soon)
    let aiSystem = AISystem_MK3()
    let movementSystem = MovementSystem_MK3()
    let combatSystem = CombatSystem_MK3()
    
    //MARK: DID MOVE
    override func didMove(to view: SKView) {
        setupScene()
    }

    //MARK: SETUP SCENE
    func setupScene() {
        // 1. Clear everything (Safety for level transitions)
        clearLevel()
        // 2. Setup Layout
        mapManager.setupLayout(screenSize: self.size, rows: 23, cols: 15)
        // 3. Load Level via MK3 Loader
        if let levelData = LevelManager.loadLevel(fileName: "testlevel3") {
            LevelLoader_MK3.load(
                data: levelData,
                into: grid,
                entityManager: entityManager,
                scene: self
            )
        }
    }
    
    //MARK: CLEAR LEVEL
    // THE "ANTI-LEAK" FUNCTION
    func clearLevel() {
        print("MK3: Clearing level memory...")
        
        // 1. Remove all visuals from SpriteKit
        for node in visualNodes.values {
            node.removeFromParent()
        }
        visualNodes.removeAll()
        
        // 2. Clear the logic layers
        entityManager.allEntities.removeAll()
        grid.reset() // Ensure your grid has a reset() to clear occupancy dictionaries
        
        // 3. Reset timing
        lastUpdateTime = 0
    }
    /* GameScene_MK3.swift */

    // Add a flag to track if we are waiting for the current tick's AI to finish
    var isWaitingForAI = false
    
    //MARK: UPDATE
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        if isPaused { return }
                
        // 1. THE TICK TRIGGER (Every 0.3s)
        if timeManager.update(delta: deltaTime) {
            aiSystem.enqueueEntities(entityManager: entityManager)
            isWaitingForAI = true // Lock the systems until the queue is processed
        }

        // 2. THE AI PROCESSING (Every Frame)
        aiSystem.update(entityManager: entityManager, grid: grid)
        
        // 3. THE EXECUTION GATE
        // Only run movement and combat once per tick, specifically
        // when the AI has finished its staggered thinking.
        if isWaitingForAI && aiSystem.isQueueEmpty {
            
            // Now these run exactly once every 0.3s, just a few frames
            // after the initial tick trigger.
            movementSystem.update(entityManager: entityManager, grid: grid)
            
            combatSystem.update(entityManager: entityManager, grid: grid)
            
            // Cleanup follows the movement/combat
            entityManager.cleanup(grid: grid, scene: self)
            
            // Unlock until the next 0.3s tick triggers
            isWaitingForAI = false
        }

        // 4. VISUALS (Always 60fps for smooth interpolation)
        syncVisuals(deltaTime: deltaTime)
    }
    
    //MARK: SYNC VISUALS
    private func syncVisuals(deltaTime: TimeInterval) {
        for entity in entityManager.allEntities {
            // Calculate where the entity wants to be in screen space
            let targetPoint = mapManager.calculateScreenPos(entity.position)
            
            if let node = visualNodes[entity.id] {
                //hand the data to the node. The Entity remains 100% logic-only.
                node.update(entity: entity, targetPoint: targetPoint, deltaTime: deltaTime)
            } else {
                //if it's a new entity without a visual node yet, make a node
                let newNode = EntityNode_MK3(entity: entity, size: mapManager.tileSize)
                newNode.position = targetPoint // Start it at the right spot
                self.addChild(newNode)
                visualNodes[entity.id] = newNode
            }
        }
    }
    
    func shakeCamera(intensity: CGFloat = 4.0, duration: TimeInterval = 0.2) {
        let cameraNode = self.camera ?? SKCameraNode()
        if self.camera == nil { self.camera = cameraNode; addChild(cameraNode) }
        
        let shake = SKAction.customAction(withDuration: duration) { node, time in
            node.position = CGPoint(x: CGFloat.random(in: -intensity...intensity),
                                    y: CGFloat.random(in: -intensity...intensity))
        }
        cameraNode.run(SKAction.sequence([shake, SKAction.move(to: .zero, duration: 0.05)]))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // 1. Convert Screen Point -> Grid Tile
        let targetPos = mapManager.calculateGridPos(location)
        
        // 2. Check Static Terrain (Walls/Out of bounds)
        // We pass canFly: false because warriors are ground units
        guard !grid.isImpassable(at: targetPos) else {
            print("Spawn Failed: Tile is a wall or out of bounds.")
            return
        }
        
        // 3. Check Dynamic Occupants (Other Units/Buildings)
        if let occupants = grid.getOccupants(at: targetPos) {
            let isReserved = occupants.contains { $0.obeysReservation }
            if isReserved {
                print("Spawn Failed: Tile is occupied by an entity with reservation logic.")
                return
            }
        }
        
        // 4. Spawn the Warrior
        // Note: Ensure "warrior" exists in your Library_MK3 templates
        EntityFactory_MK3.spawn(
            type: "Warrior",
            at: targetPos,
            team: .player,
            grid: grid,
            entityManager: entityManager
        )
        
        print("Spawned Warrior at \(targetPos)")
    }

    func unpause() {
        self.isPaused = false
        self.timeManager.paused = false
        self.lastUpdateTime = 0 // Reset this so deltaTime is 0 on the first frame back
    }
    
}
