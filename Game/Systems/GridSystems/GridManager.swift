//map manager, handles tile occupancy
import Foundation

class GridManager {
    // The visual layer
    weak var scene: GameScene?
    // ultimate source of truth for tracking tile occupancy
    var occupiedTiles: Set<TilePosition> = []
    //maps tile to Unit or Obstacle ID
    var entityAtTile: [TilePosition: UUID] = [:]
    init(scene: GameScene) {
        self.scene = scene
    }
    
    //MARK: REGISTER OCCUPANCY
    //unit or obstacle takes a tile
    func registerOccupancy(id: UUID, pos: TilePosition) {
            occupiedTiles.insert(pos)
            entityAtTile[pos] = id
    }
    
    //MARK: CLEAR OCCUPANCY
    //free tile
    func clearOccupancy(at pos: TilePosition) {
        occupiedTiles.remove(pos)
        entityAtTile[pos] = nil
    }
    
    //MARK: CHECK IF TILE IS WALKABLE
    //return if a specific tile is a wall tile
    func isTileWalkable(_ pos: TilePosition) -> Bool {
        //walls are hard unwalkable
        guard let tile = scene?.tileAt(position: pos) else { return false }
        if tile.tile.terrain == .wall { return false }
        return !occupiedTiles.contains(pos)
    }
}
