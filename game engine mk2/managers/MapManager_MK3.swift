/*
 MapManager_MK2.swift:
 handle global game clock
*/
import SpriteKit

class MapManager_MK3 {
    var gridOffsetX: CGFloat = 0
    var gridOffsetY: CGFloat = 0
    var tileSize: CGFloat = 0
    
    // Moves the math out of the scene
    func calculateScreenPos(_ pos: TilePosition) -> CGPoint {
        return CGPoint(
            x: gridOffsetX + (CGFloat(pos.col) * tileSize),
            y: gridOffsetY + (CGFloat(pos.row) * tileSize)
        )
    }
    
    func calculateGridPos(_ location: CGPoint) -> TilePosition {
        let col = Int(round((location.x - gridOffsetX) / tileSize))
        let row = Int(round((location.y - gridOffsetY) / tileSize))
        return TilePosition(row: row, col: col)
    }
    
    func setupLayout(screenSize: CGSize, rows: Int, cols: Int) {
        self.tileSize = min(screenSize.width / CGFloat(cols + 2), screenSize.height / CGFloat(rows + 2))
        self.gridOffsetX = (screenSize.width - (tileSize * CGFloat(cols - 1))) / 2
        self.gridOffsetY = (screenSize.height - (tileSize * CGFloat(rows - 1))) / 2
        
        //pass calculated tileSize + offsets to projectile component
        ProjectileComponent.tileSize = self.tileSize
        ProjectileComponent.offsetX = self.gridOffsetX
        ProjectileComponent.offsetY = self.gridOffsetY

    }
}
