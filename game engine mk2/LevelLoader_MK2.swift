/*
 LevelLoader_MK2.swift:
 load level data from .json file
*/
import SpriteKit

class LevelLoader_MK2 {
    
    static func load(data: LevelData, into grid: Grid_MK2, entityManager: EntityManager_MK2, scene: GameScene_MK2) {
        // 1. Initialize the Grid dimensions
        grid.setup(rows: data.rows, cols: data.cols)
        
        // 2. Populate Tiles
        for tileData in data.tiles {
            let pos = TilePosition(row: tileData.row, col: tileData.col)
            let terrain = TerrainType(rawValue: tileData.terrain) ?? .ground
            
            // Set logic
            grid.tiles[pos.row][pos.col].terrain = terrain
            
            // Trigger Visuals for non-ground tiles
            if terrain != .ground {
                let color: UIColor = (terrain == .wall ? .black : .yellow)
                let size = scene.mapManager.tileSize
                let node = SKSpriteNode(color: color, size: CGSize(width: size - 2, height: size - 2))
                                
                // Use mapManager to get the position
                node.position = scene.mapManager.calculateScreenPos(pos)
                node.zPosition = 1
                scene.addChild(node)
            }
        }
        
        // 3. Populate Entities
        for e in data.entities {
            let pos = TilePosition(row: e.row, col: e.col)
            let team = Team(rawValue: e.team ?? "neutral") ?? .neutral
            
            // call entityFactory to spawn entities 
            EntityFactory_MK2.spawn(
                type: e.type,
                at: pos,
                team: team,
                grid: grid,
                entityManager: entityManager,
                scene: scene
            )
        }
    }
}
