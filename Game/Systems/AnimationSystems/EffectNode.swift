import SpriteKit

class EffectNode: SKNode, AnimatableEntity {
    
    //animation entity requirements
    let entityName: String
    var currentState: String = "play"
    var isLooping: Bool = false
    var animationKey: String = ""
    let visualSprite = SKSpriteNode()

    init(effectName: String, position: CGPoint, tileSize: CGSize) {
        //set size
        self.visualSprite.size = CGSize(width: tileSize.width, height: tileSize.height)
        self.visualSprite.anchorPoint = CGPoint(x: 0.5, y: 0.1) 
        
        self.entityName = effectName
        super.init()
        self.position = position
        self.addChild(visualSprite)
        
        self.zPosition = ZManager.effect
        
        let playDuration: TimeInterval = 0.2
        
        AnimationManager.shared.updateAnimation(for: self, forcedDuration: playDuration)
        
        // Auto-remove non-looping effects
        self.run(SKAction.sequence([
            SKAction.wait(forDuration: playDuration),
            SKAction.removeFromParent()
        ]))
    }
    required init?(coder: NSCoder) { fatalError() }
}
