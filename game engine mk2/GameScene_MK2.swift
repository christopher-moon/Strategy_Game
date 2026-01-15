/*
 GameScene_MK2.swift:
 highest level logic and control for the game engine
 contains "main" function
*/
import SpriteKit

class GameScene_MK2: SKScene {
    var lastUpdateTime: TimeInterval = 0
    var visualNodes: [UUID: SKSpriteNode] = [:]
    
    //path visualization
    var pathDots: [SKShapeNode] = []
    
    //managers
    let timeManager = TimeManager_MK2()
    let mapManager = MapManager_MK2()
    let grid = Grid_MK2()
    let entityManager = EntityManager_MK2()
    
    //systems
    let aiSystem = AISystem_MK2()
    let movementSystem = MovementSystem_MK2()
    let combatSystem = CombatSystem_MK2()
    let hazardSystem = HazardSystem_MK2()
    
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
                
        // 1. LOGIC TICK (via TimeManager)
        if timeManager.update(delta: deltaTime) {
            //THE HOLY ORDER: EVERY TICK WILL CHECK THESE
            //ai decision + set state
            aiSystem.update(entityManager: entityManager, grid: grid)
            
            //movement
            movementSystem.update(entityManager: entityManager, grid: grid)
            
            //combat
            combatSystem.update(entityManager: entityManager, grid: grid)
            
            //hazards
            hazardSystem.update(entityManager: entityManager, grid: grid)
            
            //cleanup
            entityManager.cleanup(grid: grid, scene: self)
        }
                
        // 2. VISUAL SMOOTHING
        updateVisuals(delta: deltaTime)
    }

    func updateVisuals(delta: TimeInterval) {
        
        pathDots.forEach { $0.removeFromParent() }
        pathDots.removeAll()
        
        for entity in entityManager.allEntities {
            guard let sprite = visualNodes[entity.id] else { continue }
            
            let targetPoint = mapManager.calculateScreenPos(entity.position)
            
            // "Lerp" math: Move 10% of the remaining distance every frame
            // This makes the movement look smooth and organic
            let speed: CGFloat = 10.0
            let newX = sprite.position.x + (targetPoint.x - sprite.position.x) * speed * CGFloat(delta)
            let newY = sprite.position.y + (targetPoint.y - sprite.position.y) * speed * CGFloat(delta)
            
            sprite.position = CGPoint(x: newX, y: newY)
            
            // Inside updateVisuals, after updating the sprite position:
            if let pathUnit = entity as? Unit_MK2 {
                // You could draw small dots on currentPath tiles here
                drawPath(for: pathUnit)
            }
            
            //update direction
            if let unit = entity as? Unit_MK2 {
                sprite.xScale = (unit.facing == .right) ? 1.0 : -1.0
            }
            
            if let unit = entity as? Unit_MK2 {
                let stateChar: String
                switch unit.state {
                    case .idle: stateChar = "I"
                    case .moving: stateChar = "M"
                    case .attacking: stateChar = "A"
                    case .dead: stateChar = "X"
                    case .spawning: stateChar = "S"
                }
                // Check if label already exists as a child of the sprite
                if let label = sprite.childNode(withName: "stateLabel") as? SKLabelNode {
                    label.text = stateChar
                } else {
                    // Create the label once if it doesn't exist
                    let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
                    label.name = "stateLabel"
                    label.fontSize = 14
                    label.fontColor = .cyan
                    label.verticalAlignmentMode = .bottom
                    // Position it slightly above the sprite's head
                    label.position = CGPoint(x: 0, y: sprite.size.height / 2 + 2)
                    label.zPosition = 10
                    sprite.addChild(label)
                    label.text = stateChar
                }
            }
        }
    }
    
    private func drawPath(for unit: Unit_MK2) {
        for pos in unit.currentPath {
            let dot = SKShapeNode(circleOfRadius: 4)
            dot.fillColor = .yellow
            dot.strokeColor = .clear
            dot.alpha = 0.6
            dot.position = mapManager.calculateScreenPos(pos)
            dot.zPosition = 5 // Behind units and walls
            
            self.addChild(dot)
            pathDots.append(dot)
        }
    }
    
    //MARK: "MAIN"
    override func didMove(to view: SKView) {
        //camera
        let cameraNode = SKCameraNode()
        self.camera = cameraNode
        self.addChild(cameraNode)
        cameraNode.position = CGPoint(x: frame.midX, y: frame.midY)
        
        self.backgroundColor = .darkGray
        Library_MK2.shared.loadJSON()
        
        if let levelData = LevelManager.loadLevel(fileName: "testlevel2") {
            mapManager.setupLayout(screenSize: self.size, rows: levelData.rows, cols: levelData.cols)
            
            // --- LOAD LEVEL ---
            LevelLoader_MK2.load(
                data: levelData,
                into: self.grid,
                entityManager: self.entityManager,
                scene: self
            )
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
            
            // 1. Convert tap to Grid Coordinates
        let targetPos = mapManager.calculateGridPos(location)
            
            // 2. Tell the BRAIN what we want
        for entity in entityManager.allEntities {
            if let unit = entity as? Unit_MK2, let followerBrain = unit.ai as? FollowerBrain {
                // We update the brain's memory.
                // The AISystem will read this on the next tick and call setTarget().
                followerBrain.targetPosition = targetPos
            }
        }
    }
    
    func shakeCamera(intensity: CGFloat = 4.0, duration: TimeInterval = 0.2) {
        guard let camera = self.camera else { return }
        
        let shakeAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
            let x = CGFloat.random(in: -intensity...intensity)
            let y = CGFloat.random(in: -intensity...intensity)
            node.position = CGPoint(x: self.frame.midX + x, y: self.frame.midY + y)
        }
        
        // Reset camera to center after shake
        let reset = SKAction.move(to: CGPoint(x: frame.midX, y: frame.midY), duration: 0.05)
        camera.run(SKAction.sequence([shakeAction, reset]))
    }
}
