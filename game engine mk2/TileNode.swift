import SpriteKit

class TileNode: SKSpriteNode {
    let tile: Tile
    private let costLable = SKLabelNode(fontNamed: "AvenirNext-Bold")

    init(tile: Tile, width: CGFloat, height: CGFloat) {
        self.tile = tile
        
        // 1. Determine which texture to use
        let textureName: String = {
            switch tile.terrain {
            case .wall: return "wall"
            case .objective: return "ground"
            case .ground: return "objective"
            }
        }()
        
        let tex = SKTexture(imageNamed: textureName)
        
        // 2. CRISP PIXELS: This prevents the 32x32 texture from looking blurry
        // when stretched to 64 points.
        tex.filteringMode = .nearest
        
        // 3. Size the sprite to the 'Width x Height' diamond dimensions
        super.init(texture: tex, color: .white, size: CGSize(width: width, height: width))
        
        // Use center anchoring for isometric math consistency
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.name = "Tile_\(tile.position.col)_\(tile.position.row)"
        
        // Setup labels (Top & Bottom)
        costLable.fontSize = 12
        costLable.position = CGPoint(x: 0, y: 0)
        self.addChild(costLable)
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    func update(deltaTime: TimeInterval){
        costLable.text = "\(tile.cost)"
    }
}
