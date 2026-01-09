import SpriteKit

class ProjectileNode: SKNode, AnimatableEntity {
    
    //animation entity requirements
    let entityName: String
    var currentState: String = "flight"
    var isLooping: Bool = true
    var animationKey: String = ""
    let visualSprite = SKSpriteNode()
    
    private var hasImpacted = false
    private var trail = false
    private var lastTrailPosition: CGPoint = .zero
    private let trailGap: CGFloat = 15.0 // Adjust this! Higher = fewer smoke clouds.
    
    init(projectileName: String, smokeTrail: Bool, tileSize: CGSize) {
        // Set a base size so the textures have a frame to draw into
        self.visualSprite.size = CGSize(width: tileSize.width, height: tileSize.height)
        self.visualSprite.anchorPoint = CGPoint(x: 0.5, y: 0.1) // Center it
        
        self.entityName = projectileName
        self.trail = smokeTrail
        super.init()
        
        self.addChild(visualSprite)
        self.zPosition = ZManager.projectile
        
        updateVisualState()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    //MARK: UPDATE VISUAL STATE
    func updateVisualState(){
        AnimationManager.shared.updateAnimation(for: self, forcedDuration: 0.3)
    }
   
    //MARK: LAUNCH FUNCTION
    func launch(towards target: SKNode, completion: @escaping () -> Void) {
        
        self.lastTrailPosition = self.position
        let checkInterval = 0.02 // High frequency update
        
        let trackAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak self, weak target] in
                guard let self = self, let target = target, !self.hasImpacted else {
                    // If target dies mid-flight, just remove projectile
                    self?.removeFromParent()
                    return
                }
                
                // Calculate distance to target
                let dx = target.position.x - self.position.x
                let dy = target.position.y - self.position.y
                let distance = sqrt(dx*dx + dy*dy)
                
                // If close enough, "impact"
                if distance < 10 {
                    self.hasImpacted = true
                    self.removeAllActions()
                    completion()
                    self.removeFromParent()
                } else {
                    // Move a small step toward the current target position
                    let speed: CGFloat = 150.0 // Points per second
                    let velocityX = (dx / distance) * speed * CGFloat(checkInterval)
                    let velocityY = (dy / distance) * speed * CGFloat(checkInterval)
                    self.position = CGPoint(x: self.position.x + velocityX,
                                            y: self.position.y + velocityY)
                    
                    // Optional: Update rotation to face the target
                    //self.zRotation = atan2(dy, dx)
                    
                    //smoke trail logic
                    if self.trail {
                        let distSinceLastSmoke = hypot(self.position.x - lastTrailPosition.x, self.position.y - lastTrailPosition.y)
                        if distSinceLastSmoke >= trailGap {
                            let smoke = EffectNode(effectName: "smoke1", position: self.position, tileSize: self.visualSprite.size)
                            self.parent?.addChild(smoke)
                            self.lastTrailPosition = self.position // Reset the anchor
                        }
                    }
                }
            },
            SKAction.wait(forDuration: checkInterval)
        ]))
        
        run(trackAction)
    }
}
