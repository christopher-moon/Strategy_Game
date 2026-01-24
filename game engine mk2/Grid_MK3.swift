/* Grid_MK3.swift */
import Foundation

// Define GridOccupant
struct GridOccupant_MK3 {
    let id: UUID
    let movementCost: Int
    let isImpassable: Bool
    let obeysReservation: Bool
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
            obeysReservation: entity.obeysReservation,
            team: entity.team
        )
        occupants[entity.position, default: []].append(occ)
    }
    
    func removeEntity(at pos: TilePosition, id: UUID) {
        occupants[pos]?.removeAll { $0.id == id }
        if occupants[pos]?.isEmpty == true { occupants.removeValue(forKey: pos) }
    }
    
    func moveEntity(_ entity: Entity_MK3, from oldPos: TilePosition, to newPos: TilePosition) {
        guard let idx = occupants[oldPos]?.firstIndex(where: { $0.id == entity.id }) else { return }
        let data = occupants[oldPos]!.remove(at: idx)
        
        if occupants[oldPos]?.isEmpty == true { occupants.removeValue(forKey: oldPos) }
        
        occupants[newPos, default: []].append(data)
        entity.position = newPos
    }
    
    func reset() {
        occupants.removeAll()
    }
    
    // MARK: - Physics Rules (The "Laws of the Grid")
    
    func isImpassable(at pos: TilePosition) -> Bool {
        if !isValid(pos) { return true }
        if tiles[pos.row][pos.col].terrain == .wall { return true }
        return false
    }
    
    func isValid(_ pos: TilePosition) -> Bool {
        return pos.row >= 0 && pos.row < rows && pos.col >= 0 && pos.col < cols
    }
    
    func getOccupants(at pos: TilePosition) -> [GridOccupant_MK3]? {
        return occupants[pos]
    }
    
    /// Calculates the cost to enter a tile. Returns nil if strictly impassable (Walls/Bounds).
    func getMovementCost(at pos: TilePosition, canFly: Bool = false) -> Int? {
        if isImpassable(at: pos) { return nil }
        
        // Base cost
        var cost = 1
        
        if let entities = occupants[pos], !entities.isEmpty {
            // Ground units cannot walk through "Impassable" entities (like destructible walls)
            if !canFly && entities.contains(where: { $0.isImpassable }) {
                // High cost ensures pathfinding treats this as a "last resort" (i.e., attack it)
                return 1000
            }
            
            var maxCost = entities.map { $0.movementCost }.max() ?? 0
            
            // Flying units ignore high movement cost obstacles (like stones)
            if canFly && maxCost > 20 {
                maxCost = 0
            }
            cost += maxCost
        }
        
        return cost
    }
    
    /// Returns valid geometric neighbors (ignoring dynamic unit positions).
    func getNeighbors(at pos: TilePosition, canFly: Bool = false) -> [TilePosition] {
        let offsets = [(0, 1), (0, -1), (1, 0), (-1, 0)]
        return offsets.compactMap { (r, c) in
            let next = TilePosition(row: pos.row + r, col: pos.col + c)
            
            // 1. Bounds check
            guard isValid(next) else { return nil }
            
            // 2. Wall check
            if tiles[next.row][next.col].terrain == .wall && !canFly { return nil }
            
            return next
        }
    }

    func distance(_ a: TilePosition, _ b: TilePosition) -> Int {
        return abs(a.col - b.col) + abs(a.row - b.row)
    }
}

/* Grid_MK3.swift Extension */
extension Grid_MK3 {
    /// Simply finds the coordinate of the closest objective tile using basic distance math.
    /// This is extremely fast compared to Dijkstra/NavigationMap.
    func findNearestObjectivePos(from start: TilePosition) -> TilePosition? {
        var bestPos: TilePosition?
        var minDistance = Int.max
        
        for r in 0..<rows {
            for c in 0..<cols {
                let tile = tiles[r][c]
                // Check for both terrain types or zone flags
                if tile.terrain == .objective || tile.isObjectiveZone {
                    let d = distance(start, tile.position)
                    if d < minDistance {
                        minDistance = d
                        bestPos = tile.position
                    }
                }
            }
        }
        return bestPos
    }
}
