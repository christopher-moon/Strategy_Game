import SpriteKit
import Foundation
import GameplayKit

// A custom node that allows A* to respect terrain costs
class WeightedNode: GKGraphNode2D {
    let gridPos: TilePosition
    var weight: Float = 1.0
    
    init(point: vector_float2, gridPos: TilePosition) {
        self.gridPos = gridPos
        super.init(point: point)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    // A* calls this to find the cost of moving to a neighbor node
    override func cost(to node: GKGraphNode) -> Float {
        guard let targetNode = node as? WeightedNode else { return 1.0 }
        return targetNode.weight
    }
}

class MapManager {
    let worldNode = SKNode()
    
    // Map Stats
    var tileSize: CGFloat = 64.0
    var tileHeight: CGFloat = 32.0
    var rows: Int = 0
    var cols: Int = 0
    
    // Logical Data
    private(set) var grid: [TilePosition: Tile] = [:]
    
    // Navigation Data
    var weightedGraph = GKGraph()
    var gridNodes: [TilePosition: WeightedNode] = [:]
    
    // MARK: - Map Building
    func buildMap(from data: LevelData) {
            worldNode.removeAllChildren()
            grid.removeAll()
            
            self.rows = data.layout.count
            self.cols = data.layout[0].count
            
            for (r, rowStr) in data.layout.enumerated() {
                for (c, char) in rowStr.enumerated() {
                    let pos = TilePosition(row: r, col: c)
                    let terrain = TerrainType(rawValue: String(char)) ?? .ground
                    let tile = Tile(position: pos, terrain: terrain)
                    
                    grid[pos] = tile
                    
                    let node = TileNode(tile: tile, width: tileSize, height: tileHeight)
                    node.position = calculateScreenPos(pos)
                    
                    // --- FIX: Z-POSITION MATH ---
                    // We use 2000 as a ceiling. Things further "down" the screen (lower Y)
                    // get a higher Z-index so they appear in front of things behind them.
                    if tile.terrain == .wall {
                        node.zPosition = 2000 - node.position.y
                    } else {
                        // Ground tiles sit at a lower layer (e.g., base 1000)
                        // so entities (base 2000) always walk "on" them.
                        node.zPosition = 1000 - node.position.y
                    }
                    
                    worldNode.addChild(node)
                }
            }
        }
    
    // MARK: - Navigation Graph
    func generateNavGraph() {
            weightedGraph = GKGraph()
            gridNodes.removeAll()
            
            // 1. Create nodes ONLY for walkable tiles
            for (pos, tile) in grid where tile.isWalkable {
                let screenPos = calculateScreenPos(pos)
                let node = WeightedNode(point: vector_float2(Float(screenPos.x), Float(screenPos.y)), gridPos: pos)
                
                // Sync current terrain cost to the node
                node.weight = tile.moveCost
                gridNodes[pos] = node
            }
            
            // 2. Connect neighbors
            for (pos, node) in gridNodes {
                let neighbors = [
                    TilePosition(row: pos.row + 1, col: pos.col),
                    TilePosition(row: pos.row - 1, col: pos.col),
                    TilePosition(row: pos.row, col: pos.col + 1),
                    TilePosition(row: pos.row, col: pos.col - 1),
                    // Diagonals
                    TilePosition(row: pos.row + 1, col: pos.col + 1),
                    TilePosition(row: pos.row - 1, col: pos.col - 1),
                    TilePosition(row: pos.row + 1, col: pos.col - 1),
                    TilePosition(row: pos.row - 1, col: pos.col + 1)
                ]
                
                for nPos in neighbors {
                    if let neighborNode = gridNodes[nPos] {
                        node.addConnections(to: [neighborNode], bidirectional: false)
                    }
                }
            }
            weightedGraph.add(Array(gridNodes.values))
        }

    // MARK: - Occupancy Updates
    func addEntity(_ entityID: UUID, at pos: TilePosition) {
        grid[pos]?.occupants.insert(entityID)
    }

    func moveEntity(_ entityID: UUID, from oldPos: TilePosition, to newPos: TilePosition) {
        grid[oldPos]?.occupants.remove(entityID)
        grid[newPos]?.occupants.insert(entityID)
    }
    
    /// Returns a path of screen positions (waypoints) from one grid tile to another
        func findPath(from start: TilePosition, to end: TilePosition) -> [vector_float2] {
            // 1. Validate that nodes exist in our graph
            guard let startNode = gridNodes[start],
                  let endNode = gridNodes[end] else {
                return []
            }
            
            // 2. Run A* on the Weighted Graph
            let nodes = weightedGraph.findPath(from: startNode, to: endNode) as? [WeightedNode] ?? []
            
            // 3. Convert nodes to screen waypoints
            // We use .map to cleanly transform the array
            var path = nodes.map { node in
                let screenPos = calculateScreenPos(node.gridPos)
                return vector_float2(Float(screenPos.x), Float(screenPos.y))
            }
            
            // 4. Optimization: If the entity is already on the first node, remove it
            // so they don't "stutter" at their current position before moving.
            if !path.isEmpty {
                path.removeFirst()
            }
            
            return path
        }
}

// MARK: - Isometric & Math Utilities
extension MapManager {
    
    func calculateScreenPos(_ pos: TilePosition) -> CGPoint {
        // Isometric Conversion:
        // x = (col - row) * (width / 2)
        // y = (col + row) * (-height / 2)
        let x = CGFloat(pos.col - pos.row) * (tileSize / 2)
        let y = CGFloat(pos.col + pos.row) * (tileHeight / -2)
        return CGPoint(x: x, y: y)
    }
    
    func calculateGridPos(from worldPos: CGPoint) -> TilePosition {
        let halfW = tileSize / 2
        let halfH = tileHeight / 2
        
        let adjX = worldPos.x / halfW
        let adjY = worldPos.y / -halfH
        
        let col = Int(round((adjX + adjY) / 2))
        let row = Int(round((adjY - adjX) / 2))
        
        return TilePosition(row: row, col: col)
    }
    
    func fitMapToScreen(screenSize: CGSize) {
        let mapWidth = CGFloat(cols + rows) * (tileSize / 2)
        let mapHeight = CGFloat(cols + rows) * (tileHeight / 2)
        
        let scaleX = (screenSize.width * 0.9) / mapWidth
        let scaleY = (screenSize.height * 0.9) / mapHeight
        let finalScale = min(scaleX, scaleY)
        
        worldNode.setScale(finalScale)
        worldNode.position = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2 + (mapHeight * finalScale / 4))
    }
}
