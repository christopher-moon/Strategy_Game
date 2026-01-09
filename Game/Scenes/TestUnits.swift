//spawn units for testing purposes
import SpriteKit

extension GameScene {
    
    func tileAt(row: Int, col: Int) -> TileNode? {
        guard row >= 0 && row < rows && col >= 0 && col < cols else { return nil }
        return tiles[row][col]
    }
    
    func tileAt(position: TilePosition) -> TileNode? {
        return tileAt(row: position.row, col: position.col)
    }
        
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let nodesAtPoint = nodes(at: location)
            
        if let tile = nodesAtPoint.first(where: { $0 is TileNode }) as? TileNode {
            let pos = tile.tile.position
            if gridManager.occupiedTiles.contains(pos) {
                return // Stop the function here
            }
            
            unitManager.spawnUnit(type: "Warrior", team: .player, aiBrain: BasicCombatAI(), at: tile)
            
        }
    }
    
    func findNearestObjective(from position: TilePosition, unitManager: UnitManager) -> TilePosition? {
        var nearest: TilePosition?
        var shortestDistance = Int.max

        for row in tiles {
            for tileNode in row {
                let candidatePosition = tileNode.tile.position
                
                // 1. Check if the tile is an objective
                if tileNode.tile.terrain == .objective || tileNode.tile.isObjectiveZone {
                    
                    // 2. CHECK: Is the objective tile available?
                    // the tiles that are NOT occupied or the tile the unit is currently standing on are available.
                    
                    let isCurrentTile = candidatePosition == position
                    
                    if (!gridManager.occupiedTiles.contains(candidatePosition) || isCurrentTile) {
                        
                        // 3. Calculate distance (Manhattan distance)
                        let dist = abs(candidatePosition.row - position.row)
                                 + abs(candidatePosition.col - position.col)
                        
                        // 4. Update the nearest available objective
                        if dist < shortestDistance {
                            shortestDistance = dist
                            nearest = candidatePosition
                        }
                    }
                }
            }
        }

        return nearest
    }
    
}

