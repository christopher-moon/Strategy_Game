import SpriteKit

class UnitNode: SKNode, AnimatableEntity {
    var unit: Unit
    let baseSize: CGSize
    
    //animation entity requirements
    var entityName: String { unit.name }
    var currentState: String { unit.state.rawValue }
    //only loop idle and moving animations
    var isLooping: Bool { unit.state == .idle || unit.state == .moving }
    var visualSprite: SKSpriteNode { visual }
    var animationKey: String = ""
    
    // Components
    private let flipContainer = SKNode()
    private let shadow: SKSpriteNode
    private let visual: SKSpriteNode
    private let healthBarContainer = SKNode()
    private let healthBar = SKSpriteNode(color: .green, size: CGSize(width: 24, height: 3))

    init(unit: Unit, tileSize: CGSize) {
        self.unit = unit
        self.baseSize = tileSize
        
        // 1. set up visual character
        let unitTextures = AnimationManager.shared.getTextures(name: unit.name, state: "idle")
        self.visual = SKSpriteNode(texture: unitTextures.first) // Pull from cache
        // Fallback if cache is empty (ensures it doesn't crash but warns you)
        if unitTextures.isEmpty {
            self.visual.texture = SKTexture(imageNamed: "\(unit.name)_idle")
        }
        self.visual.size = CGSize(width: tileSize.width * 1, height: tileSize.height * 1)
        self.visual.anchorPoint = CGPoint(x: 0.5, y: 0.1)
        self.visual.zPosition = 1
        
        // 2. Setup Shadow
        // Using the team-based shadow logic from your manager
        let shadowTextures = AnimationManager.shared.getTextures(name: "\(unit.team)_shadow", state: "idle")
        self.shadow = SKSpriteNode(texture: shadowTextures.first)
        if shadowTextures.isEmpty {
                self.shadow.texture = SKTexture(imageNamed: "\(unit.name)_idle_shadow")
        }
        self.shadow.size = CGSize(width: tileSize.width, height: tileSize.height)
        self.shadow.zPosition = -1
        self.shadow.alpha = 0.5
        
        super.init()
        
        self.addChild(flipContainer) // Add container to self
        flipContainer.addChild(shadow) // Add shadow to container
        flipContainer.addChild(visual) // Add visual to container
        
        self.setupHealthBar()
        self.zPosition = 2000
        
        updateVisualState()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: UPDATE VISUAL STATE
    func updateVisualState(forcedDuration: TimeInterval? = nil) {
        // 1. hand over unit animation to animation manager
        AnimationManager.shared.updateAnimation(for: self, forcedDuration: forcedDuration)
        // 2. attack logic (return to idle after finishing attack anim
        if unit.state == .attacking{
            //remove existing "return to idle" timers to prevent overlap
            self.removeAction(forKey: "attack_cleanup")
            let textures = AnimationManager.shared.getTextures(name: entityName, state: currentState)
            let duration = forcedDuration ?? (Double(textures.count) * 0.2)
            let wait = SKAction.wait(forDuration: duration)
            let finish = SKAction.run { [weak self] in
                guard let self = self else { return }
                //only return to idle if we havent already started a new action
                if self.unit.state == .attacking {
                    self.unit.state = .idle
                    self.updateVisualState()
                }
            }
            self.run(SKAction.sequence([wait, finish]), withKey: "attack_cleanup")
        }
    }
    
    // MARK: VISUAL POSITIONING
    func setVisualPosition(to tile: TileNode) {
        self.position = tile.position
        self.unit.position = tile.tile.position
    }
    
    // MARK: VISUAL MOVEMENT
    func moveVisual(to tile: TileNode, duration: TimeInterval? = nil) {
        let moveDuration = duration ?? 0.2
        self.removeAction(forKey: "attack_cleanup") // ADD THIS: Stop the idle-return timer
        //update direction
        updateFacing(to: tile.tile.position.col)
        // 1. Define the move
        let moveAction = SKAction.move(to: tile.position, duration: moveDuration)
        // 2. Define the completion logic
        let doneAction = SKAction.run { [weak self] in
            // Use 'self' (unwrapped) because we guard below
            guard let self = self, self.unit.state != .dead else { return }
            self.unit.state = .idle
            self.updateVisualState()
        }
        // 3. Combine into a sequence
        let sequence = SKAction.sequence([moveAction, doneAction])
        unit.state = .moving
        updateVisualState(forcedDuration: moveDuration)
        // 4. Run with key so 'die()' can cancel it
        self.run(sequence, withKey: "movement")
    }

    // MARK: UI & Health
    private func setupHealthBar() {
        let bgSize = CGSize(width: 26, height: 4)
        let background = SKSpriteNode(color: .black, size: bgSize)
        healthBarContainer.position = CGPoint(x: 0, y: visual.size.height + 10)
        healthBarContainer.zPosition = 10
        healthBar.anchorPoint = CGPoint(x: 0, y: 0.5)
        healthBar.position = CGPoint(x: -bgSize.width/2 + 1, y: 0)
        addChild(healthBarContainer)
        healthBarContainer.addChild(background)
        healthBarContainer.addChild(healthBar)
        updateHealthBar()
    }

    func updateHealthBar() {
        let percent = max(0, CGFloat(unit.hp) / CGFloat(unit.maxHP))
        healthBar.size.width = 24 * percent
        healthBar.color = percent > 0.5 ? .green : (percent > 0.25 ? .yellow : .red)
    }
    
    // MARK: FLINCH & MELEE BUMP
    func playHitFlinch() {
        //visual.run(SKAction.sequence([
            //SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.05),
            //SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
        //]))
    }

    func playMeleeBump(towards targetPos: CGPoint) {
        let diff = CGPoint(x: (targetPos.x - self.position.x) * 0.3, y: (targetPos.y - self.position.y) * 0.3)
        let move = SKAction.moveBy(x: diff.x, y: diff.y, duration: 0.05)
        visual.run(SKAction.sequence([move, move.reversed()]))
    }
    
    // MARK: TETHERS
    func showTether(to target: UnitNode, effectName: String) {
        let line = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: self.convert(target.position, from: self.parent!))
        line.path = path
        line.strokeColor = .cyan
        line.lineWidth = 2
        line.alpha = 0.6
        addChild(line)
        line.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()]))
    }

    // MARK: DEATH ANIMATION
    func die(completion: @escaping () -> Void) {
        //stop all movement
        self.removeAction(forKey: "movement")
        self.removeAction(forKey: "attack_cleanup") // ADD THIS: Stop the idle-return timer
        self.visual.removeAllActions()
        self.shadow.removeAllActions()
        
        //set state to dead
        unit.state = .dead
        //trigger non-looping death animation vi animationmanager
        updateVisualState()
        
        healthBarContainer.removeFromParent()
        shadow.run(SKAction.fadeOut(withDuration: 1))
            
        let textures = AnimationManager.shared.getTextures(name: unit.name, state: "dead")
        let duration = textures.isEmpty ? 0.5 : Double(textures.count) * 0.2
            
        self.run(SKAction.sequence([
            SKAction.wait(forDuration: duration),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.run { completion() },
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: UPDATE DIRECTION
    func updateFacing(to targetCol: Int) {
        let newDirection = targetCol < unit.position.col ? "left" : "right"
        
        // Only play the bounce if the direction is actually changing
        if unit.direction != newDirection {
            unit.direction = newDirection
            
            let targetScale: CGFloat = (newDirection == "left") ? -1.0 : 1.0
            
            // --- THE JUICE ---
            // 1. Squash: Quickly shrink horizontally while slightly stretching vertically
            let squash = SKAction.group([
                SKAction.scaleX(to: targetScale * 0.5, duration: 0.05),
                SKAction.scaleY(to: 1.1, duration: 0.05)
            ])
            
            // 2. Overshoot: Stretch slightly past normal size in the new direction
            let overshoot = SKAction.group([
                SKAction.scaleX(to: targetScale * 1.1, duration: 0.07),
                SKAction.scaleY(to: 0.95, duration: 0.07)
            ])
            
            // 3. Settle: Return to normal (1.0)
            let settle = SKAction.group([
                SKAction.scaleX(to: targetScale, duration: 0.05),
                SKAction.scaleY(to: 1.0, duration: 0.05)
            ])
            
            flipContainer.run(SKAction.sequence([squash, overshoot, settle]))
        }
    }
    
}
