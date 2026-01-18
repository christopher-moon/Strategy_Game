/* Grid_MK3.swift */
import Foundation

struct GridOccupant_MK3 {
    let id: UUID
    let movementCost: Int
    let isImpassable: Bool
    let team: Team
}

class Grid_MK3 {
    private(set) var rows: Int = 0
    private(set) var cols: Int = 0
    var tiles: [[Tile]] = []
    
    // THE UNIFIED LIST: Tracks everything (Units, Walls, Mines, Smoke)
    private var occupants: [TilePosition: [GridOccupant_MK3]] = [:]
    
    func setup(rows: Int, cols: Int) {
        self.rows = rows
        self.cols = cols
        tiles = (0..<rows).map { r in
            (0..<cols).map { c in
                Tile(position: TilePosition(row: r, col: c), terrain: .ground)
            }
        }
    }
    
    // MARK: - Core Management
    
    func addEntity(_ entity: Entity_MK3) {
        let occ = GridOccupant_MK3(
            id: entity.id,
            movementCost: entity.movementCost,
            isImpassable: entity.isImpassable,
            team: entity.team
        )
        
        if occupants[entity.position] == nil { occupants[entity.position] = [] }
        occupants[entity.position]?.append(occ)
    }
    
    func removeEntity(at pos: TilePosition, id: UUID) {
        occupants[pos]?.removeAll { $0.id == id }
        if occupants[pos]?.isEmpty == true { occupants.removeValue(forKey: pos) }
    }
    
    func moveEntity(_ entity: Entity_MK3, from oldPos: TilePosition, to newPos: TilePosition) {
        // 1. Find our data in the old tile
        guard let idx = occupants[oldPos]?.firstIndex(where: { $0.id == entity.id }) else { return }
        let data = occupants[oldPos]!.remove(at: idx)
        
        // 2. Clean up old tile
        if occupants[oldPos]?.isEmpty == true { occupants.removeValue(forKey: oldPos) }
        
        // 3. Move data to new tile
        if occupants[newPos] == nil { occupants[newPos] = [] }
        occupants[newPos]?.append(data)
        
        // 4. Update Entity
        entity.position = newPos
    }
    
    func reset() {
        occupants.removeAll()
    }
    
    // MARK: - Physics Queries
    
    // Returns true if the tile is physically blocked by a wall or unit
    func isImpassable(at pos: TilePosition, canFly: Bool = false) -> Bool {
        // 1. Check Map Bounds
        if pos.row < 0 || pos.row >= rows || pos.col < 0 || pos.col >= cols { return true }
        
        // 2. Check Terrain
        if tiles[pos.row][pos.col].terrain == .wall { return !canFly }
        
        return false
    }
    
    // Used by Pathfinding to calculate A* weights
    func getMovementCost(at pos: TilePosition, canFly: Bool = false) -> Int? {
        if isImpassable(at: pos, canFly: canFly) { return nil }
        
        if let entities = occupants[pos] {
            // If a ground unit encounters an impassable entity, it cannot path here
            if !canFly && entities.contains(where: { $0.isImpassable }) {
                //the ai will only path to an impassible entity if absoluetly no other path exists 
                return 10000
            }
        }
        
        // Base cost
        var cost = 1
        
        // add highest entity cost
        if let entities = occupants[pos], !entities.isEmpty {
            var maxCost = entities.map { $0.movementCost }.max() ?? 0
            //if the unit is a flying unit, it should treat obstacle type entities (which have high movement costs) as free tiles since it can just fly over them safely
            if canFly && (maxCost > 20) {
                maxCost = 0
            }
            cost += maxCost
        }
        
        return cost
    }
    
    // Helper for AI
    func getOccupants(at pos: TilePosition) -> [GridOccupant_MK3]? {
        return occupants[pos]
    }
    
    func getNeighbors(at pos: TilePosition, canFly: Bool = false) -> [TilePosition] {
        let potential = [
            TilePosition(row: pos.row + 1, col: pos.col),
            TilePosition(row: pos.row - 1, col: pos.col),
            TilePosition(row: pos.row, col: pos.col + 1),
            TilePosition(row: pos.row, col: pos.col - 1)
        ]
        return potential.filter { p in
                // 1. Always block out-of-bounds
                if p.row < 0 || p.row >= rows || p.col < 0 || p.col >= cols { return false }
                
                // 2. Always block terrain Walls (unless flying)
                if tiles[p.row][p.col].terrain == .wall && !canFly { return false }
                
                // 3. Allow entities (like Stones) to be considered neighbors
                // This lets the pathfinder see the 10000 cost and decide to go there
                return true
            }
    }
}
