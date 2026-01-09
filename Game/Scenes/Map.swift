//game map creation
import SpriteKit

extension GameScene {
    
    //setup level
    func setupLevel(named levelName: String){
        guard let levelData = LevelManager.loadLevel(fileName: levelName) else { return }
        
        // 1. setup grid based on level data
        createGrid(from: levelData)
        
        // 2. initialize managers
        gridManager = GridManager(scene: self)
        obstacleManager = ObstacleManager(scene: self, gridManager: gridManager)
        unitManager = UnitManager(scene: self, gridManager: gridManager, obstacleManager: obstacleManager)
        
        // 3. spawn entites from level data
        spawnEntities(from: levelData)
        
        // 4. start unit ai
        //unitManager.movement.startAITick()
    }
    
    //create grid
    func createGrid(from levelData: LevelData) {
        
        gridNode.removeAllChildren()
        tiles = []
        
        //map the TileData array to a dict for quick lookup during generation
        let terrainMap = Dictionary(uniqueKeysWithValues: levelData.tiles.map { (TilePosition(row: $0.row, col: $0.col), $0.terrain) })
        
        for row in 0..<rows {
            var rowArray: [TileNode] = []
            for col in 0..<cols {
                let pos = TilePosition(row: row, col: col)
                        
                // Get terrain from data, default to .ground
                let terrainString = terrainMap[pos] ?? "ground"
                let terrain = TerrainType(rawValue: terrainString) ?? .ground
                        
                let tile = Tile(position: pos, terrain: terrain)
                let node = TileNode(tile: tile, size: tileSize)
                        
                node.position = node.scenePosition(tileSize: tileSize)
                node.zPosition = node.zPositionForRow(maxRow: rows - 1)
                        
                gridNode.addChild(node)
                rowArray.append(node)
            }
            tiles.append(rowArray)
        }
        
        //center the grid
        gridNode.position = CGPoint(
            x: (size.width - CGFloat(cols) * tileSize.width)/2,
            y: (size.height - CGFloat(rows) * tileSize.height)/2 + 50 // shift map up
        )
    }
    
    //get ai type
    func getAi(for type: String?) -> UnitAIBrain {
        switch type?.lowercased(){
        case "attack":
            return BasicCombatAI()
        case "objective":
            return ObjectiveRunnerAI()
        default:
            return BasicCombatAI()
        }
    }
    
    //spawn entities
    func spawnEntities(from levelData: LevelData) {
        for entity in levelData.entities {
            guard let tile = tileAt(row: entity.row, col: entity.col) else { continue }
                
            if entity.type == "Mine" {
                obstacleManager.spawnObstacle(type: entity.type, at: tile)
            } else {
                let team: Team = entity.team == "enemy" ? .enemy : .player
                unitManager.spawnUnit(type: entity.type, team: team, aiBrain: getAi(for: entity.ai), at: tile)
            }
        }
    }
}

