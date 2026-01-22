/* LevelLoader_MK3.swift */
import SpriteKit

class LevelLoader_MK3 {
    
    static func load(data: LevelData, into grid: Grid_MK3, entityManager: EntityManager_MK3, scene: GameScene_MK3) {
        // 1. Initialize the Grid dimensions
        grid.setup(rows: data.rows, cols: data.cols)
        
        // 2. Priority: Use Visual Layout if it exists
        if let layout = data.layout {
            parseVisualLayout(layout, into: grid, entityManager: entityManager, scene: scene)
        }
        // 3. Fallback: Use coordinate-based arrays (legacy support)
        
        loadLegacyData(data, into: grid, entityManager: entityManager, scene: scene)
        
    }
    
    private static func parseVisualLayout(_ layout: [String], into grid: Grid_MK3, entityManager: EntityManager_MK3, scene: GameScene_MK3) {
        for (r, rowString) in layout.enumerated() {
            if r >= grid.rows { break }
            
            // Turn string into array of characters for safe iteration
            let characters = Array(rowString)
            
            for (c, char) in characters.enumerated() {
                if c >= grid.cols { break }
                let pos = TilePosition(row: r, col: c)
                
                switch char {
                case "W": // Wall Terrain
                    grid.tiles[pos.row][pos.col].terrain = .wall
                    visualizeTerrain(.wall, at: pos, scene: scene)
                    
                case "O": // Objective Terrain
                    grid.tiles[pos.row][pos.col].terrain = .objective
                    visualizeTerrain(.objective, at: pos, scene: scene)
                    
                case "S": // Stone Entity (Neutral)
                    EntityFactory_MK3.spawn(type: "Stone", at: pos, team: .neutral, patrol: nil, grid: grid, entityManager: entityManager)
                    
                case "M": // Mine
                    EntityFactory_MK3.spawn(type: "Mine", at: pos, team: .neutral, patrol: nil, grid: grid, entityManager: entityManager)
                    
                default:
                    // Everything else (like ".") stays as .ground terrain
                    grid.tiles[pos.row][pos.col].terrain = .ground
                }
            }
        }
    }

    // This replaces your original loops to handle the optionality
    private static func loadLegacyData(_ data: LevelData, into grid: Grid_MK3, entityManager: EntityManager_MK3, scene: GameScene_MK3) {
        // Load Tiles if the array exists
        if let tiles = data.tiles {
            for tileData in tiles {
                let pos = TilePosition(row: tileData.row, col: tileData.col)
                let terrain = TerrainType(rawValue: tileData.terrain) ?? .ground
                grid.tiles[pos.row][pos.col].terrain = terrain
                if terrain != .ground { visualizeTerrain(terrain, at: pos, scene: scene) }
            }
        }
        
        // Load Entities if the array exists
        if let entities = data.entities {
            for e in entities {
                let pos = TilePosition(row: e.row, col: e.col)
                let team = Team(rawValue: e.team ?? "neutral") ?? .neutral
                EntityFactory_MK3.spawn(type: e.type, at: pos, team: team, patrol: e.patrol, grid: grid, entityManager: entityManager)
            }
        }
    }

    // Helper function to keep visual logic consistent with your old code
    private static func visualizeTerrain(_ terrain: TerrainType, at pos: TilePosition, scene: GameScene_MK3) {
        let color: UIColor = (terrain == .wall ? .black : .yellow)
        let size = scene.mapManager.tileSize
        let node = SKSpriteNode(color: color, size: CGSize(width: size - 2, height: size - 2))
        
        node.position = scene.mapManager.calculateScreenPos(pos)
        node.zPosition = 1
        scene.addChild(node)
    }
}
