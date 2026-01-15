/*
 Pathfinding_MK2.swift
 cost based A* pathfinder
*/
import Foundation

class Pathfinding_MK2 {
    static func findPath(from start: TilePosition, to target: TilePosition, grid: Grid_MK2) -> [TilePosition] {
        
        var openSet = [start]
        var cameFrom: [TilePosition: TilePosition] = [:]
        
        // gScore: the cost of the cheapest path from start to n currently known
        var gScore: [TilePosition: Int] = [start: 0]
        
        // fScore: gScore[n] + heuristic(n)
        var fScore: [TilePosition: Int] = [start: heuristic(start, target)]
        
        while !openSet.isEmpty {
            // Pick the node with the lowest fScore
            let current = openSet.min(by: { (fScore[$0] ?? 9999) < (fScore[$1] ?? 9999) })!
            
            if current == target {
                return reconstructPath(cameFrom, current)
            }
            
            openSet.removeAll { $0 == current }
            
            for neighbor in grid.getNeighbors(at: current) {
                // THE KEY CHANGE: Get weighted cost from the grid
                guard let stepCost = grid.getMovementCost(at: neighbor) else {
                    continue // Wall or Unit = nil (impassable)
                }
                
                let tentativeGScore = (gScore[current] ?? 9999) + stepCost
                
                if tentativeGScore < (gScore[neighbor] ?? 9999) {
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentativeGScore
                    fScore[neighbor] = tentativeGScore + heuristic(neighbor, target)
                    
                    if !openSet.contains(neighbor) {
                        openSet.append(neighbor)
                    }
                }
            }
        }
        return [] // No path found
    }
    
    // Manhattan distance heuristic
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
        return path.reversed()
    }
}
