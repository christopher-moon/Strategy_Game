//centralized manager for all logical unit information (movement, spawning, deleting, etc)
import SpriteKit
import Foundation

class UnitManager {
    
    // Dependencies
    weak var scene: GameScene?
    let gridManager: GridManager
    let obstacleManager: ObstacleManager
    
    // Source of Truth
    var units: [UUID: UnitNode] = [:]
    
    // Sub-Systems (Composition)
    lazy var factory = ObjectFactory(manager: self)
    lazy var movement = MovementSystem(manager: self)
    lazy var combat = CombatSystem(manager: self)
    
    init(scene: GameScene, gridManager: GridManager, obstacleManager: ObstacleManager) {
        self.scene = scene
        self.gridManager = gridManager
        self.obstacleManager = obstacleManager
    }
    
    // MARK: - Lifecycle Proxy
    func spawnUnit(type: String, team: Team, aiBrain: UnitAIBrain = BasicCombatAI(), at tile: TileNode) {
        factory.spawnUnit(type: type, team: team, aiBrain: aiBrain, at: tile)
    }
    
    func removeUnit(_ unit: UnitNode) {
        // logical removal
        units.removeValue(forKey: unit.unit.id)
        gridManager.clearOccupancy(at: unit.unit.position)
        movement.clearReservation(for: unit)
        
        //visual removal
        unit.die { }
    }
    
    // MARK: - Update Loop
    // Call this from Scene.update
    func update(deltaTime: TimeInterval) {
        // You can put per-frame logic here if needed,
        // currently your ticks are handled via Actions in MovementSystem
    }

    // MARK: - Shared Utilities (Public API)
    
    // Find distance between two tiles (Manhattan)
    func distance(from a: TilePosition, to b: TilePosition) -> Int {
        return abs(a.row - b.row) + abs(a.col - b.col)
    }
    
    // Return the specific unit standing on a tile
    func unitAt(_ pos: TilePosition) -> UnitNode? {
        if let id = gridManager.entityAtTile[pos] {
            return units[id]
        }
        return nil
    }
    
    func isTileOccupied(_ tile: TileNode) -> Bool {
        return gridManager.occupiedTiles.contains(tile.tile.position)
    }
}
