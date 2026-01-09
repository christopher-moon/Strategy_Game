import SpriteKit

class TileNode: SKSpriteNode {
    
    var tile: Tile
    
    init(tile: Tile, size: CGSize) {
        
        self.tile = tile
        
        let textureName: String
        switch tile.terrain {
        case .ground: textureName = "tile_ground"
        case .wall: textureName = "tile_wall"
        case .objective: textureName = "tile_grass" // placeholder
        }
        
        let texture = SKTexture(imageNamed: textureName)
        super.init(texture: texture, color: .white, size: size)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    //update tile appearance
    func updateAppearance() {
        let textureName: String
        switch tile.terrain {
        case .ground: textureName = "tile_ground"
        case .wall: textureName = "tile_wall"
        case .objective: textureName = "tile_grass"
        }
        self.texture = SKTexture(imageNamed: textureName)
    }
    
    func zPositionForRow(maxRow: Int) -> CGFloat {
        500 + CGFloat(maxRow - tile.position.row)
    }
    
    //convert in game tile position to actual pixels on the screen
    func scenePosition(tileSize: CGSize) -> CGPoint {
        let x = CGFloat(tile.position.col) * tileSize.width + tileSize.width / 2
        let y = CGFloat(tile.position.row) * tileSize.height
        return CGPoint(x: x, y: y)
    }
}

