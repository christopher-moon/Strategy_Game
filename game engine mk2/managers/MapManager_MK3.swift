import SpriteKit
import Foundation
import GameplayKit

class MapManager {
    //this container allows scaling or moving the WHOLE map at once
    let worldNode = SKNode()
    
    //map stats
    var tileSize: CGFloat = 64.0
    var rows: Int = 0
    var cols: Int = 0
    
    //1. LOGICAL GRID
    //for "what terrain is here" or "who is standing on this tile"
    private(set) var grid: [TilePosition: Tile] = [:]
    
    //2. NAVIGATION GRAPH
    //for pathfinding, "get from A to B while avoiding walls"
    var navGraph: GKObstacleGraph<GKGraphNode2D>?
    //master list of physical shapes for Agents to "see" and avoid
    var physicalObstacles: [GKPolygonObstacle] = []

    
    //MARK: ENTITY REGISTRATION
    //register an entity to a grid tile container
    func addEntity(_ entityID: UUID, at pos: TilePosition) {
        grid[pos]?.occupants.insert(entityID)
    }

    //transfer an entity from one tile container to another
    func moveEntity(_ entityID: UUID, from oldPos: TilePosition, to newPos: TilePosition) {
        grid[oldPos]?.occupants.remove(entityID)
        grid[newPos]?.occupants.insert(entityID)
    }
    
    //remove an entity from its current tile container (e.g., on death)
    func removeEntity(_ entityID: UUID, at pos: TilePosition) {
        grid[pos]?.occupants.remove(entityID)
    }
    
    //MARK: NAVIGATION GRAPH
    //generate the navigation graph based on terrain
    func generateNavGraph() {
        navGraph = GKObstacleGraph(obstacles: physicalObstacles, bufferRadius: Float(tileSize / 4))
    }
    
    //MARK: GAME MAP
    // MARK: - MERGE LOGIC

    /// Optimized buildMap that uses merging
    func buildMap(from data: LevelData) {
        worldNode.removeAllChildren()
        grid.removeAll()
        physicalObstacles.removeAll() // Ensure list is fresh
        
        self.rows = data.rows
        self.cols = data.cols
        
        // 1. First Pass: Create Logical and Visual Tiles
        for (r, rowString) in data.layout.enumerated() {
            for (c, char) in rowString.enumerated() {
                let pos = TilePosition(row: r, col: c)
                let type = TerrainType(rawValue: String(char).uppercased()) ?? .ground
                let tile = Tile(position: pos, terrain: type)
                grid[pos] = tile
                
                let node = TileNode(tile: tile, size: tileSize)
                node.position = calculateScreenPos(pos)
                worldNode.addChild(node)
            }
        }
        
        // 2. Second Pass: Run the 2D Merging Logic
        mergeObstacles()
        
        print("Map built. Merged into \(physicalObstacles.count) physical obstacles.")
    }

    private func mergeObstacles() {
        var visited = Set<TilePosition>()
        
        for r in 0..<rows {
            for c in 0..<cols {
                let pos = TilePosition(row: r, col: c)
                
                // If it's a wall and not already part of a merged rectangle
                if let tile = grid[pos], !tile.isWalkable, !visited.contains(pos) {
                    
                    // A. Determine the maximum width of this wall segment in this row
                    var width = 0
                    while c + width < cols,
                          let t = grid[TilePosition(row: r, col: c + width)],
                          !t.isWalkable, !visited.contains(TilePosition(row: r, col: c + width)) {
                        width += 1
                    }
                    
                    // B. Determine the maximum height this width can extend downward
                    var height = 1
                    while r + height < rows {
                        var rowMatch = true
                        for dw in 0..<width {
                            let checkPos = TilePosition(row: r + height, col: c + dw)
                            if let t = grid[checkPos], t.isWalkable || visited.contains(checkPos) {
                                rowMatch = false
                                break
                            }
                        }
                        if rowMatch { height += 1 } else { break }
                    }
                    
                    // C. Mark all tiles in this rectangle as visited
                    for dh in 0..<height {
                        for dw in 0..<width {
                            visited.insert(TilePosition(row: r + dh, col: c + dw))
                        }
                    }
                    
                    // D. Create the merged obstacle
                    let mergedObstacle = createRectObstacle(row: r, col: c, width: width, height: height)
                    physicalObstacles.append(mergedObstacle)
                }
            }
        }
    }

    private func createRectObstacle(row: Int, col: Int, width: Int, height: Int) -> GKPolygonObstacle {
        let topLeftPos = calculateScreenPos(TilePosition(row: row, col: col))
        let bottomRightPos = calculateScreenPos(TilePosition(row: row + height - 1, col: col + width - 1))
        
        let h = Float(tileSize / 2)
        let epsilon: Float = 0.5 // Add a half-pixel overlap to seal seams
        
        let leftX = Float(topLeftPos.x) - h - epsilon
        let rightX = Float(bottomRightPos.x) + h + epsilon
        let bottomY = Float(bottomRightPos.y) - h - epsilon
        let topY = Float(topLeftPos.y) + h + epsilon
        
        let vertices = [
            vector_float2(leftX, bottomY),
            vector_float2(rightX, bottomY),
            vector_float2(rightX, topY),
            vector_float2(leftX, topY)
        ]
        
        return GKPolygonObstacle(points: vertices)
    }
    
    //fit map to screen
    func fitMapToScreen(screenSize: CGSize) {
        let mapWidth = CGFloat(cols) * tileSize
        let mapHeight = CGFloat(rows) * tileSize
        
        // 1. Calculate the scale needed to fit
        // We use a 0.9 multiplier to add a small "margin" around the edges
        let scaleX = (screenSize.width * 0.9) / mapWidth
        let scaleY = (screenSize.height * 0.9) / mapHeight
        let finalScale = min(scaleX, scaleY)
        
        // 2. Apply scale to the container
        worldNode.setScale(finalScale)
        
        // 3. Center the worldNode
        // Since tile (0,0) is bottom-left, we find the center of the scaled map
        let scaledWidth = mapWidth * finalScale
        let scaledHeight = mapHeight * finalScale
        
        worldNode.position = CGPoint(
            x: (screenSize.width - scaledWidth) / 2,
            y: (screenSize.height - scaledHeight) / 2
        )
    }


    
    //MARK: GRID TO SCREEN CONVERSION FUNCTIONS
    // Convert a TilePosition (Logic) to a CGPoint (Visual)
    func calculateScreenPos(_ pos: TilePosition) -> CGPoint {
        let halfTile = tileSize/2
        return CGPoint(
            x: (CGFloat(pos.col) * tileSize) + halfTile,
            y: (CGFloat((rows - 1) - pos.row) * tileSize) + halfTile // Accounting for inverted Y
        )
    }

    // Convert a continuous World Position (Agent) to a TilePosition (Logic)
    // Useful for checking which tile an Agent is currently "standing" on
    func calculateGridPos(from worldPos: CGPoint) -> TilePosition {
        let col = Int(floor(worldPos.x / tileSize))
        let row = (rows - 1) - Int(floor(worldPos.y / tileSize))
        return TilePosition(row: row, col: col)
    }
    
    //convert tileposition into four corner coordinates needed by GKPolygonObstacles
    func getVerticesForTile(at pos: TilePosition) -> [vector_float2] {
        let screenPos = calculateScreenPos(pos)
        let h = Float(tileSize / 2) // Half-size
        let cx = Float(screenPos.x)
        let cy = Float(screenPos.y)
        
        // Return the 4 corners of the square
        return [
            vector_float2(cx - h, cy - h), // Bottom Left
            vector_float2(cx + h, cy - h), // Bottom Right
            vector_float2(cx + h, cy + h), // Top Right
            vector_float2(cx - h, cy + h)  // Top Left
        ]
    }
}

extension GKPolygonObstacle {
    func contains(_ point: vector_float2) -> Bool {
        var inside = false
        let count = vertexCount
        var j = count - 1
        
        for i in 0..<count {
            let vi = vertex(at: i)
            let vj = vertex(at: j)
            
            // Ray casting algorithm
            if ((vi.y > point.y) != (vj.y > point.y)) &&
                (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x) {
                inside = !inside
            }
            j = i
        }
        
        return inside
    }
}
