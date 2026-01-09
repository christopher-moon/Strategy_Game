//centralized manager for all logical unit information (movement, spawning, deleting, etc)
import SpriteKit
import Foundation

class UnitManager {
    
    weak var scene: GameScene?
    let gridManager: GridManager
    let obstacleManager: ObstacleManager
    
    var units: [UUID: UnitNode] = [:]
    //var occupiedTiles: Set<TilePosition> = []
    var moveRequests: [UUID: TilePosition] = [:]
    var reservedTiles: Set<TilePosition> = []
    
    init(scene: GameScene, gridManager: GridManager, obstacleManager: ObstacleManager) {
        self.scene = scene
        self.gridManager = gridManager
        self.obstacleManager = obstacleManager
    }
    
    // MARK: SPAWN UNIT
    func spawnUnit(type: String, team: Team, aiBrain: UnitAIBrain = BasicCombatAI(), at tile: TileNode){
        // 1. get the blueprint
        guard let blueprint = UnitRegistry.data[type] else {
            print("unit \(type) does not exist!")
            return
        }
        // 2. create the unit using the blueprint data
        let newUnit = Unit(
            name: blueprint.name,
            team: team,
            ai: aiBrain,
            hp: blueprint.maxHP,
            maxHP: blueprint.maxHP,
            attack: blueprint.attack,
            range: blueprint.range,
            threatRange: blueprint.threatRange,
            attackSpeed: blueprint.attackSpeed,
            attackPattern: blueprint.attackPattern,
            movementSpeed: blueprint.movementSpeed,
            position: tile.tile.position
        )
        // 3. create the Visual Node
        let unitNode = UnitNode(unit: newUnit, tileSize: scene!.tileSize)
        
        unitNode.setVisualPosition(to: tile)
        // 4. Add to the scene hierarchy
        scene?.gridNode.addChild(unitNode)
        // 5. add to list of units
        units[newUnit.id] = unitNode
        // 6. Register unit with GridManager using its unique ID
        gridManager.registerOccupancy(id: newUnit.id, pos: tile.tile.position)
    }
    
    // MARK: REMOVE UNIT
    func removeUnit(_ unit: UnitNode) {
        units.removeValue(forKey: unit.unit.id)
        //occupiedTiles.remove(unit.unit.position)
        gridManager.clearOccupancy(at: unit.unit.position)
        unit.removeFromParent()
    }
    
    // MARK: MOVE UNIT
    func moveUnit(_ unit: UnitNode, to tile: TileNode, duration: TimeInterval? = nil) {
        let newPos = tile.tile.position
        let oldPos = unit.unit.position
                
        // 1. VISUAL MOVE
        unit.moveVisual(to: tile, duration: duration)
        
        // 2. LOGICAL MOVE (authoritative)
        unit.unit.position = newPos
        
        // 3. UPDATE OCCUPANCY
        gridManager.clearOccupancy(at: oldPos)
        gridManager.registerOccupancy(id: unit.unit.id, pos: newPos)
        //occupiedTiles.remove(oldPos)
        //occupiedTiles.insert(newPos)
        reservedTiles.remove(oldPos)
        
        // 4. CHECK FOR TRAPS
        //obstacleManager.handleTrapInteraction(at: newPos, unit: unit)
        
        // 4. REMOVE FIRST STEP FROM PATH
        if var path = unit.unit.currentPath, !path.isEmpty {
            path.removeFirst()
            unit.unit.currentPath = path
        }
    }
    
    // MARK: UTILITY FUNCTIONS
    //check tile occupancy
    func isTileOccupied(_ tile: TileNode) -> Bool {
        return gridManager.occupiedTiles.contains(tile.tile.position)
        //return occupiedTiles.contains(tile.tile.position)
    }
    
    //find distance between two tiles
    func distance(from a: TilePosition, to b: TilePosition) -> Int {
        return abs(a.row - b.row) + abs(a.col - b.col) // Manhattan distance
    }
    
    //return the specific unit standing on a tile
    func unitAt(_ pos: TilePosition) -> UnitNode? {
        if let id = gridManager.entityAtTile[pos] {
            return units[id]
        }
        return nil
    }
}

