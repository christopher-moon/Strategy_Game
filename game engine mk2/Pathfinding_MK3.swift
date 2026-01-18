/* Pathfinding_MK3.swift */
import Foundation

class Pathfinding_MK3 {

    // MARK: - Absolute Linear Path (Bypasses all Physics)
    static func findAbsoluteLinearPath(from start: TilePosition, to target: TilePosition) -> [TilePosition] {
        var path: [TilePosition] = []
        var current = start
        
        // Step-by-step toward target using new instances since properties are constants
        while current != target {
            var nextCol = current.col
            var nextRow = current.row
            
            if current.col < target.col { nextCol += 1 }
            else if current.col > target.col { nextCol -= 1 }
            
            if current.row < target.row { nextRow += 1 }
            else if current.row > target.row { nextRow -= 1 }
            
            current = TilePosition(row: nextRow, col: nextCol)
            path.append(current)
        }
        return path
    }
    
    static func findPath(from start: TilePosition, to target: TilePosition, grid: Grid_MK3, canFly: Bool) -> [TilePosition] {
        var openSet = [start]
        var cameFrom: [TilePosition: TilePosition] = [:]
        var gScore: [TilePosition: Int] = [start: 0]
        var fScore: [TilePosition: Int] = [start: heuristic(start, target)]
        
        while !openSet.isEmpty {
            let current = openSet.min(by: { (fScore[$0] ?? 1000000) < (fScore[$1] ?? 1000000) })!
            
            if current == target {
                return reconstructPath(cameFrom, current)
            }
            
            openSet.removeAll { $0 == current }
            
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
    
    private static func heuristic(_ a: TilePosition, _ b: TilePosition) -> Int {
        return abs(a.col - b.col) + abs(a.row - b.row)
    }
    
    private static func reconstructPath(_ cameFrom: [TilePosition: TilePosition], _ current: TilePosition) -> [TilePosition] {
        var path = [current]
        var temp = current
        while let previous = cameFrom[temp] {
            path.append(previous)
            temp = previous
        }
        return path.reversed().dropFirst().map { $0 } // dropFirst removes 'start'
    }
}
