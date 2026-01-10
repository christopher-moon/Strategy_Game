import SpriteKit

class GameScene: SKScene {
    //map properties
    let rows = 23
    let cols = 15
    var tileSize = CGSize.zero
    let unitScale: CGFloat = 1.2
    
    var gridNode = SKNode()
    var tiles = [[TileNode]]()
    
    //managers
    var gridManager: GridManager!
    var obstacleManager: ObstacleManager!
    var unitManager: UnitManager!
    
    // "main"
    override func didMove(to view: SKView) {
        
        backgroundColor = .black
        addChild(gridNode)
        
        // Compute tile size
        let tileWidth = size.width / CGFloat(cols)
        let tileHeight = size.height / CGFloat(rows)
        let tileSide = min(tileWidth, tileHeight) * 0.95
        tileSize = CGSize(width: tileSide, height: tileSide)
        
        //load level from json file
        setupLevel(named: "testlevel")
        
        //start game
        unitManager.movement.startAITick()

    }
    
}

