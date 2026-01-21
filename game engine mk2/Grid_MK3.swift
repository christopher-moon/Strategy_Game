/* Grid_MK3.swift */
import Foundation

//define GridOccupant
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
    
    //add entity as a GridOccupant to grid
    func addEntity(_ entity: Entity_MK3) {
        let occ = GridOccupant_MK3(
            id: entity.id,
            movementCost: entity.movementCost,
            isImpassable: entity.isImpassable,
            obeysReservation: entity.obeysReservation,
            team: entity.team
        )
        
        if occupants[entity.position] == nil { occupants[entity.position] = [] }
        occupants[entity.position]?.append(occ)
    }
    
    //remove entity from grid
    func removeEntity(at pos: TilePosition, id: UUID) {
        occupants[pos]?.removeAll { $0.id == id }
        if occupants[pos]?.isEmpty == true { occupants.removeValue(forKey: pos) }
    }
    
    //move entity within the grid
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
    
    //reset grid
    func reset() {
        occupants.removeAll()
    }
    
    // MARK: - Physics Queries
    
    //returns true if the tile is blocked by a wall tile or out of bounds
    func isImpassable(at pos: TilePosition) -> Bool {
        //check Map Bounds
        if pos.row < 0 || pos.row >= rows || pos.col < 0 || pos.col >= cols { return true }
        //check Terrain
        if tiles[pos.row][pos.col].terrain == .wall { return true }
        
        return false
    }
    
    //get movement cost of a specific tile, used by Pathfinding to calculate A* weights
    func getMovementCost(at pos: TilePosition, canFly: Bool = false) -> Int? {
        //impassable tiles (out of bounds or walls) have a nil cost
        if isImpassable(at: pos) { return nil }
        
        if let entities = occupants[pos] {
            // If a ground unit encounters an impassable entity, it cannot path here
            if !canFly && entities.contains(where: { $0.isImpassable }) {
                //destructable obstacles (entities with isImpassible == true + health) have a massive cost
                //this ensures the ai will only attempt to path through them as a LAST RESORT
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
    
    //return all entities on a specific tile
    func getOccupants(at pos: TilePosition) -> [GridOccupant_MK3]? {
        return occupants[pos]
    }
    
    //return movement-valid neighbors of a specific tile
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

    //return manhattan distance between two tiles
    func distance(_ a: TilePosition, _ b: TilePosition) -> Int {
        return abs(a.col - b.col) + abs(a.row - b.row)
    }
    
    func findClosestEnemy(from: TilePosition, range: Int, excludingTeam: Team, reachableMap: [TilePosition: Int]) -> UUID? {
        var bestTarget: UUID?
        var minPathCost = Int.max

        // A 'Vision' path shouldn't cost more than a reasonable distance.
        // Since ground = 1, a cost of 10000 means there is a Stone in the way.
        let visionThreshold = 1000

        for (pos, pathCost) in reachableMap {
            
            // 1. Physical distance check (Threat Range)
            if distance(from, pos) > range { continue }
            
            // 2. THE CRITICAL FIX: If the path cost is huge, it means
            // the AI had to 'path' through a Stone to find this tile.
            // We treat these tiles as invisible.
            if pathCost >= visionThreshold { continue }
            
            if let occupantsAtPos = occupants[pos] {
                for occ in occupantsAtPos {
                    if occ.team != excludingTeam && occ.team != .neutral {
                        if pathCost < minPathCost {
                            minPathCost = pathCost
                            bestTarget = occ.id
                        }
                    }
                }
            }
        }
        return bestTarget
    }

    func findNearestObjectiveNeighbor(at pos: TilePosition, canFly: Bool) -> TilePosition? {
        let neighbors = getNeighbors(at: pos, canFly: canFly)
        
        for neighbor in neighbors {
            let tile = tiles[neighbor.row][neighbor.col]
            
            // Is this neighbor tile part of the objective zone?
            if tile.terrain == .objective || tile.isObjectiveZone {
                let occupants = getOccupants(at: neighbor) ?? []
                
                // Is it physically clear?
                let isOccupied = occupants.contains { $0.obeysReservation }
                let isImpassable = occupants.contains { $0.isImpassable }
                
                if !isOccupied && !isImpassable {
                    return neighbor
                }
            }
        }
        return nil
    }
}

extension Grid_MK3 {
    
    // generates a map of all reachable tiles and their total cumulative movement cost.
    // this handles walls (impassable) and obstacles like stones (high cost).
    func getReachableMap(from start: TilePosition, canFly: Bool, respectVision: Bool = false) -> [TilePosition: Int] {
        var costs: [TilePosition: Int] = [start: 0]
        var frontier: [(pos: TilePosition, cost: Int)] = [(start, 0)]
        
        while !frontier.isEmpty {
            // Dijkstra: always expand the lowest cost tile first
            frontier.sort { $0.cost < $1.cost }
            let current = frontier.removeFirst()
            
            for neighbor in getNeighbors(at: current.pos, canFly: canFly) {
                // 1. Get the base movement cost (handles ground, walls, and stones)
                guard let stepCost = getMovementCost(at: neighbor, canFly: canFly) else { continue }
                
                // 2. Vision Toggle Logic:
                // If we respect vision, treat stones (cost 10000) as solid walls (skip them)
                if respectVision {
                    if let occupants = getOccupants(at: neighbor) {
                        let hasDestructible = occupants.contains(where: { $0.team == .neutral && $0.isImpassable })
                        if hasDestructible {
                            continue // Treat this stone as a wall: skip it
                        }
                    }
                }
                
                let totalCost = current.cost + stepCost
                
                if costs[neighbor] == nil || totalCost < costs[neighbor]! {
                    costs[neighbor] = totalCost
                    frontier.append((neighbor, totalCost))
                }
            }
        }
        return costs
    }
    
    // Optimized: Only considers tiles present in the reachableMap.
    func findBestAttackSpot(
        near target: TilePosition,
        seeker: TilePosition,
        range: Int,
        ignoringID: UUID,
        reachableMap: [TilePosition: Int] // Use the pre-calculated map
    ) -> TilePosition? {
        var bestPos: TilePosition?
        var minPathCost = Int.max

        let startRow = max(0, target.row - range)
        let endRow = min(rows - 1, target.row + range)
        let startCol = max(0, target.col - range)
        let endCol = min(cols - 1, target.col + range)

        for r in startRow...endRow {
            for c in startCol...endCol {
                let pos = TilePosition(row: r, col: c)
                
                if distance(pos, target) <= range {
                    // 1. Is it reachable? (This automatically handles walls/stones)
                    guard let pathCost = reachableMap[pos] else { continue }
                    
                    // 2. Is it unblocked by another unit?
                    let occupants = getOccupants(at: pos) ?? []
                    if occupants.contains(where: { $0.obeysReservation && $0.id != ignoringID }) { continue }
                    
                    // 3. Pick the tile with the lowest cumulative path cost
                    if pathCost < minPathCost {
                        minPathCost = pathCost
                        bestPos = pos
                    }
                }
            }
        }
        return bestPos
    }
}
