import SpriteKit

class ObstacleNode: SKNode, AnimatableEntity {
    var obstacle: Obstacle
    let baseSize: CGSize
    
    //animation entity requirements
    var entityName: String { obstacle.name }
    var currentState: String { obstacle.state.rawValue }
    var visualSprite: SKSpriteNode { visual }
    var animationKey: String = ""
    //obstacles always loop animations
    var isLooping: Bool = true
    
    private let visual: SKSpriteNode
    
    init(obstacle: Obstacle, tileSize: CGSize){
        self.obstacle = obstacle
        self.baseSize = tileSize
        
        // 1. Get the texture from your cache/manager instead of imageNamed:
        // We grab the first frame of the current state's animation
        let textures = AnimationManager.shared.getTextures(name: obstacle.name, state: obstacle.state.rawValue)
            
        // 2. Initialize with the cached texture (or a fallback)
        if let firstFrame = textures.first {
            self.visual = SKSpriteNode(texture: firstFrame)
        } else {
            // Fallback to imageNamed ONLY if the atlas/cache fails
            self.visual = SKSpriteNode(imageNamed: "\(obstacle.name)_\(obstacle.state.rawValue)")
        }
        
        //setup visual
        //self.visual = SKSpriteNode(imageNamed: "\(obstacle.name)_\(obstacle.state.rawValue)")
        self.visual.size = CGSize(width: tileSize.width, height: tileSize.height)
        self.visual.zPosition = 1
        
        super.init()
        
        self.addChild(visual)
        
        // Use ZManager instead of hardcoded 2100
        self.zPosition = ZManager.forRow(obstacle.position.row)
        
        updateVisualState()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    //MARK: UPDATE VISUAL STATE
    func updateVisualState(forcedDuration: TimeInterval? = nil){
        AnimationManager.shared.updateAnimation(for: self, forcedDuration: forcedDuration)
    }
    
    //MARK: VISUAL POSITIONING
    func setVisualPosition(to tile: TileNode){
        self.position = tile.position
        self.obstacle.position = tile.tile.position
        // Update Z when position is set manually
        self.zPosition = ZManager.forRow(tile.tile.position.row)
    }
}
