import SpriteKit

class TileNode: SKSpriteNode {
    let tile: Tile
    
    init(tile: Tile, size: CGFloat) {
        self.tile = tile
        
        // Map the JSON character to a color/texture
        let color: SKColor = {
            switch tile.terrain {
            case .wall: return .darkGray
            case .objective: return .systemOrange
            case .ground: return .lightGray
            }
        }()
        
        // We subtract 1 from size to create a tiny "grid gap" visual
        super.init(texture: nil, color: color, size: CGSize(width: size-2, height: size-2))
        
        // Using .zero anchor makes grid positioning math much easier
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.name = "Tile_\(tile.position.col)_\(tile.position.row)"
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
}
