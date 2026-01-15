/*
 Grid_MK2.swift
 define grid object used in game map
 grid tracks tile, obstacle, and unit positions
*/
import Foundation

struct GridOccupant {
    let id: UUID
    let movementCost: Int
    let isImpassable: Bool
    let team: Team
}

class Grid_MK2 {
    private(set) var rows: Int = 0
    private(set) var cols: Int = 0
    
    var tiles: [[Tile]] = []
    
    // Layer 1: Persistent world hazards (Mines, Laser Gates, Flames, etc)
    private var staticOccupants: [TilePosition: [GridOccupant]] = [:]
    
    // Layer 2: Moving entities (Units)
    private var unitOccupancy: [TilePosition: GridOccupant] = [:]
    
    func setup(rows: Int, cols: Int) {
        self.rows = rows
        self.cols = cols
        tiles = (0..<rows).map { r in
            (0..<cols).map { c in
                Tile(position: TilePosition(row: r, col: c), terrain: .ground)
            }
        }
    }
    
    func createOccupant(for entity: Entity_MK2) -> GridOccupant {
        return GridOccupant(
            id: entity.id,
            movementCost: entity.movementCost,
            isImpassable: true, // Units are generally impassable to others
            team: entity.team
        )
    }

    // MARK: - Occupancy Management
    // update unit occupancy
    //single source of truth for unit movement here
    func moveUnit(_ entity: Entity_MK2, from oldPos: TilePosition, to newPos: TilePosition) {
        // 1. Remove from old
        unitOccupancy.removeValue(forKey: oldPos)
            
        // 2. Update the Entity's internal position (Centralized here!)
        entity.position = newPos
            
        // 3. Update the Grid
        unitOccupancy[newPos] = createOccupant(for: entity)
    }
    
    // register a new obstacle
    func registerStaticHazard(entity: Entity_MK2) {
        let newHazard = GridOccupant(
            id: entity.id,
            movementCost: entity.movementCost,
            isImpassable: false,
            team: entity.team
        )
            
        // Append to existing array or create a new one
        if staticOccupants[entity.position] != nil {
            staticOccupants[entity.position]?.append(newHazard)
        } else {
            staticOccupants[entity.position] = [newHazard]
        }
    }
    
    // move obstacle
    func relocateStaticHazard(id: UUID, from oldPos: TilePosition, to newPos: TilePosition) {
        // 1. Find the hazard data in the old array
        if let index = staticOccupants[oldPos]?.firstIndex(where: { $0.id == id }) {
            let hazardData = staticOccupants[oldPos]!.remove(at: index)
            
            // 2. Add it to the new position array
            if staticOccupants[newPos] == nil { staticOccupants[newPos] = [] }
            staticOccupants[newPos]?.append(hazardData)
            
            // 3. Clean up empty arrays
            if staticOccupants[oldPos]?.isEmpty == true { staticOccupants.removeValue(forKey: oldPos) }
        }
    }

    // remove a unit or obstacle from its associated occupancy list
    // remove a unit or obstacle from its associated occupancy list
    func removeOccupant(at pos: TilePosition, id: UUID? = nil) {
        if let idToRemove = id {
            // --- TARGETED REMOVAL ---
            // Only remove the specific entity if its ID matches
            
            // 1. Check Unit Layer
            if unitOccupancy[pos]?.id == idToRemove {
                unitOccupancy.removeValue(forKey: pos)
            }
            
            // 2. Check Static Hazard Layer
            // Subscript access on a dictionary of value types (Array) allows in-place mutation
            staticOccupants[pos]?.removeAll(where: { $0.id == idToRemove })
            
            // Cleanup: if the array at this tile is now empty, remove the key entirely
            if staticOccupants[pos]?.isEmpty == true {
                staticOccupants.removeValue(forKey: pos)
            }
            
        } else {
            // --- BLANKET REMOVAL ---
            // If no ID is provided, wipe everything on this tile
            unitOccupancy.removeValue(forKey: pos)
            staticOccupants.removeValue(forKey: pos)
        }
    }
    
    // MARK: - QUERIES
    func getNeighbors(at pos: TilePosition) -> [TilePosition] {
        let directions = [
            TilePosition(row: pos.row + 1, col: pos.col),
            TilePosition(row: pos.row - 1, col: pos.col),
            TilePosition(row: pos.row, col: pos.col + 1),
            TilePosition(row: pos.row, col: pos.col - 1)
        ]
        // Filter out of bounds
        return directions.filter { $0.row >= 0 && $0.row < rows && $0.col >= 0 && $0.col < cols }
    }
    
    func getTile(at pos: TilePosition) -> Tile? {
        guard pos.row >= 0 && pos.row < rows && pos.col >= 0 && pos.col < cols else { return nil }
        return tiles[pos.row][pos.col]
    }
    
    func getMovementCost(at pos: TilePosition) -> Int? {
        guard pos.row >= 0, pos.row < rows, pos.col >= 0, pos.col < cols else { return nil }
        
        // 1. Terrain Check (Walls are fully impassable and return nil)
        if tiles[pos.row][pos.col].terrain == .wall { return nil }
        
        //base cost for empty tile
        var totalCost = 1
        
        // 2. Unit Check (soft block)
        if unitOccupancy[pos] != nil {
            // units are high costs to A* will try to avoid them.
            // if it cant find a cheap enough path, it will path through and movmentSystem will handle the idling.
            totalCost += unitOccupancy[pos]?.movementCost ?? 20
        }
        
        // 3. Static Hazard Check
        if let hazards = staticOccupants[pos] {
            //if there is a hazard with impassable tag, treat as a wall (will be used for destructable walls in the future)
            if hazards.contains(where: { $0.isImpassable }) { return nil }
            //else, cost is the highest hazard movement cost on the tile
            totalCost += hazards.map { $0.movementCost }.max() ?? 0
        }
            
        return totalCost
    }
    
    /// Specifically returns the hazard data at a position for interaction resolution
    func getHazards(at pos: TilePosition) -> [GridOccupant]? {
        return staticOccupants[pos]
    }
    
    func getUnit(at pos: TilePosition) -> GridOccupant? {
        return unitOccupancy[pos]
    }
    
    func findNearestUnit(to center: TilePosition, maxRange: Int, excludingTeam: Team, allEntities: [Entity_MK2]) -> Unit_MK2? {
        var closestUnit: Unit_MK2?
        var minDistance = Int.max
        
        // 1. Iterate through all units currently registered on the grid
        for (pos, occupant) in unitOccupancy {
            
            // 2. Filter by Team: Only look at teams that aren't the caller's team
            guard occupant.team != excludingTeam else { continue }
            
            // 3. Filter by Distance: Use your Manhattan distance function
            let dist = distance(center, pos)
            
            // 4. Check if it's within the specified range and closer than what we've found
            if dist <= maxRange && dist < minDistance {
                
                // 5. Logic Check: Find the actual Unit object in the master list
                if let entity = allEntities.first(where: { $0.id == occupant.id }),
                   let unit = entity as? Unit_MK2 {
                    minDistance = dist
                    closestUnit = unit
                }
            }
        }
        
        return closestUnit
    }
    
    func distance(_ pos1: TilePosition, _ pos2: TilePosition) -> Int {
        // Manhattan distance: Total number of tiles to move (No Diagonals)
        return abs(pos1.col - pos2.col) + abs(pos1.row - pos2.row)
    }
    
    func findNearestObjective(from pos: TilePosition) -> TilePosition? {
        var closestPos: TilePosition?
        var minDistance = Int.max // Start with the highest possible number
        
        // 1. Loop through the rows and columns of your 2D grid
        for r in 0..<rows {
            for c in 0..<cols {
                let tile = tiles[r][c]
                
                // 2. Check if this specific tile is marked as an objective
                if tile.terrain == .objective || tile.isObjectiveZone {
                    
                    // 3. REUSE YOUR FUNCTION: Calculate distance
                    let dist = distance(pos, tile.position)
                    
                    // 4. If this is the closest one we've seen so far, save it
                    if dist < minDistance {
                        minDistance = dist
                        closestPos = tile.position
                    }
                }
            }
        }
        
        return closestPos
    }
    // Add to Grid_MK2.swift
    func findTileInRange(target: TilePosition, range: Int, from currentPos: TilePosition) -> TilePosition? {
        var bestTile: TilePosition?
        var minDistance = Int.max

        // Scan the area around the target
        for r in (target.row - range)...(target.row + range) {
            for c in (target.col - range)...(target.col + range) {
                let candidate = TilePosition(row: r, col: c)
                
                // 1. Check Grid Boundaries
                guard candidate.row >= 0, candidate.row < rows,
                      candidate.col >= 0, candidate.col < cols else { continue }
                
                // 2. Check Range (Manhattan distance)
                if distance(candidate, target) <= range {
                    
                    // 3. Check Walkability & Occupancy
                    let tile = tiles[candidate.row][candidate.col]
                    let occupant = getUnit(at: candidate)
                    
                    // Tile is valid if it's not a wall AND (it's empty OR it's where we already are)
                    if tile.terrain != .wall && (occupant == nil || occupant?.id == unitOccupancy[currentPos]?.id) {
                        
                        // 4. Find the tile closest to our current position
                        let distToMe = distance(candidate, currentPos)
                        if distToMe < minDistance {
                            minDistance = distToMe
                            bestTile = candidate
                        }
                    }
                }
            }
        }
        return bestTile
    }
}
