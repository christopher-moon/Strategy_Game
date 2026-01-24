/* Pathfinding_MK3.swift */
import Foundation

enum NavigationType {
    case vision    //for "can I see the enemy?" (ignores unit/passable entity costs)
    case movement  // for "how do I get there?" (respects high costs)
}

// A Result struct that holds the "Map" of the world from a specific unit's perspective.
// It replaces the need to run A* later.
struct NavigationMap {
    let costs: [TilePosition: Int]
    let parents: [TilePosition: TilePosition]
    
    // Instantly reconstructs the path to any tile in the map
    func getPath(to target: TilePosition) -> [TilePosition] {
        var path: [TilePosition] = []
        var current = target
        
        while let parent = parents[current] {
            path.append(current)
            current = parent
        }
        return path.reversed()
    }
    
    // Helper: checks if a tile is reachable within a specific movement budget
    func isReachable(_ pos: TilePosition, budget: Int = Int.max) -> Bool {
        guard let cost = costs[pos] else { return false }
        return cost <= budget
    }
}

// Logic Extension
extension Grid_MK3 {
    
    // MARK: - Navigation Map Generation (Dijkstra)
    
    /// Generates a complete map of reachable tiles, their costs, and the paths to get there.
    func getNavigationMap(from start: TilePosition, canFly: Bool, type: NavigationType, maxCost: Int? = nil) -> NavigationMap {
            var costs: [TilePosition: Int] = [start: 0]
            var parents: [TilePosition: TilePosition] = [:]
            var frontier: [(pos: TilePosition, cost: Int)] = [(start, 0)]
            
            while !frontier.isEmpty {
                frontier.sort { $0.cost < $1.cost }
                let current = frontier.removeFirst()
                
                // PERFORMANCE SAVER: If we've reached our max search depth, stop!
                if let max = maxCost, current.cost >= max { continue }
                
                for neighbor in getNeighbors(at: current.pos, canFly: canFly) {
                    // Determine step cost based on mode
                    let stepCost: Int
                    
                    if type == .vision {
                        // In Vision mode, anything we can physically stand on costs 1.
                        // Only things that block vision (Stones) stay high/impassable.
                        let moveCost = getMovementCost(at: neighbor, canFly: canFly) ?? 1000
                        stepCost = (moveCost >= 1000) ? 1000 : 1
                    } else {
                        // In Movement mode, use your tactical weights (20, 200, etc.)
                        stepCost = getMovementCost(at: neighbor, canFly: canFly) ?? 1000
                    }
                    
                    let newCost = current.cost + stepCost
                    if newCost < (costs[neighbor] ?? Int.max) {
                        costs[neighbor] = newCost
                        parents[neighbor] = current.pos
                        frontier.append((neighbor, newCost))
                    }
                }
            }
            return NavigationMap(costs: costs, parents: parents)
        }
    
    // MARK: - Tactical Queries
    
    /// Uses the NavigationMap to find the closest enemy.
    func findClosestEnemy(from start: TilePosition, range: Int, excludingTeam: Team, navMap: NavigationMap) -> UUID? {
        var bestTarget: UUID?
        var minPathCost = Int.max

        // The NavigationMap already contains only tiles that are physically reachable/visible.
        for (pos, cost) in navMap.costs {
            
            // NEW RULE: If the 'visual' distance (path cost) exceeds our threat range,
            // we cannot see or interact with the target.
            if cost > range { continue }
            
            if let occupantsAtPos = getOccupants(at: pos) {
                for occ in occupantsAtPos {
                    if occ.team != excludingTeam && occ.team != .neutral {
                        // We pick the enemy that is 'closest' in terms of movement/vision cost
                        if cost < minPathCost {
                            minPathCost = cost
                            bestTarget = occ.id
                        }
                    }
                }
            }
        }
        return bestTarget
    }
    
    /// Finds the best tile to stand on to attack a specific target.
    /// Optimized to use the NavigationMap so we only pick reachable tiles.
    func findBestAttackSpot(
        near target: TilePosition,
        range: Int,
        ignoringID: UUID,
        navMap: NavigationMap
    ) -> TilePosition? {
        
        var bestPos: TilePosition?
        var minPathCost = Int.max
        
        // Fallback tracking
        var fallbackPos: TilePosition?
        var minDistanceToTarget = Int.max
        var fallbackPathCost = Int.max

        // 1. COST-AWARE FALLBACK
        for (pos, pathCost) in navMap.costs {
            // Skip occupied tiles
            let occupants = getOccupants(at: pos) ?? []
            if occupants.contains(where: { $0.obeysReservation && $0.id != ignoringID }) { continue }

            let dist = distance(pos, target)

            // Comparison Logic:
            // Is this tile closer than our current best?
            // OR is it the same distance but a cheaper path?
            if dist < minDistanceToTarget || (dist == minDistanceToTarget && pathCost < fallbackPathCost) {
                minDistanceToTarget = dist
                fallbackPathCost = pathCost
                fallbackPos = pos
            }
        }

        // 2. IDEAL SEARCH (Your existing logic)
        let startRow = max(0, target.row - range)
        let endRow = min(rows - 1, target.row + range)
        let startCol = max(0, target.col - range)
        let endCol = min(cols - 1, target.col + range)

        for r in startRow...endRow {
            for c in startCol...endCol {
                let pos = TilePosition(row: r, col: c)
                if distance(pos, target) > range { continue }
                guard let pathCost = navMap.costs[pos] else { continue }
                
                let occupants = getOccupants(at: pos) ?? []
                if occupants.contains(where: { $0.obeysReservation && $0.id != ignoringID }) { continue }
                
                if pathCost < minPathCost {
                    minPathCost = pathCost
                    bestPos = pos
                }
            }
        }
        
        return bestPos ?? fallbackPos
    }
    
    /// Finds a neighbor tile for "Pushing" logic (Objective tiles only).
    func findNearestObjectiveNeighbor(at pos: TilePosition, canFly: Bool) -> TilePosition? {
        let neighbors = getNeighbors(at: pos, canFly: canFly)
        
        for neighbor in neighbors {
            let tile = tiles[neighbor.row][neighbor.col]
            if tile.terrain == .objective || tile.isObjectiveZone {
                let occupants = getOccupants(at: neighbor) ?? []
                let isBlocked = occupants.contains { $0.obeysReservation || $0.isImpassable }
                
                if !isBlocked { return neighbor }
            }
        }
        return nil
    }
    
    //A*
    func findPath(from start: TilePosition, to target: TilePosition, grid: Grid_MK3, canFly: Bool) -> [TilePosition] {
        var openSet = [start]
        var cameFrom: [TilePosition: TilePosition] = [:]
        var gScore: [TilePosition: Int] = [start: 0]
        var fScore: [TilePosition: Int] = [start: heuristic(start, target)]
        
        while !openSet.isEmpty {
            // IMPROVED: Sort once per loop or use a more efficient data structure
            openSet.sort { (fScore[$0] ?? 1000000) < (fScore[$1] ?? 1000000) }
            let current = openSet.removeFirst()
                    
            if current == target {
                return reconstructPath(cameFrom, current)
            }
                    
            for neighbor in grid.getNeighbors(at: current, canFly: canFly) {
                // Uses the new unified cost function
                guard let stepCost = grid.getMovementCost(at: neighbor, canFly: canFly) else { continue }
                
                let tentativeGScore = (gScore[current] ?? 1000000) + stepCost
                
                if tentativeGScore < (gScore[neighbor] ?? 1000000) {
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentativeGScore
                    fScore[neighbor] = tentativeGScore + heuristic(neighbor, target)
                    if !openSet.contains(neighbor) { openSet.append(neighbor) }
                }
            }
        }
        return []
    }
    
    func heuristic(_ a: TilePosition, _ b: TilePosition) -> Int {
        return abs(a.col - b.col) + abs(a.row - b.row)
    }
    
    func reconstructPath(_ cameFrom: [TilePosition: TilePosition], _ current: TilePosition) -> [TilePosition] {
        var path = [current]
        var temp = current
        while let previous = cameFrom[temp] {
            path.append(previous)
            temp = previous
        }
        return path.reversed().dropFirst().map { $0 } // dropFirst removes 'start'
    }
}
