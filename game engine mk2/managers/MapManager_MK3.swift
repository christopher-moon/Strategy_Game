import SpriteKit
import Foundation
import GameplayKit

// Custom weighted path node
class WeightedNode: GKGraphNode2D {
    // Position on the logical grid (tile-coordinates)
    let gridPos: TilePosition
    // Default pathing cost
    var weight: Float = 1.0
    
    init(point: vector_float2, gridPos: TilePosition) {
        self.gridPos = gridPos
        super.init(point: point)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // A* calls this to find the cost of moving to a neighbor node
    override func cost(to node: GKGraphNode) -> Float {
        guard let targetNode = node as? WeightedNode else { return 1.0 }
        let distance = simd_distance(self.position, targetNode.position)
        return targetNode.weight * distance
    }
}

class MapManager {
    let worldNode = SKNode()
    var tileMap: SKTileMapNode!
    
    // Map Stats
    var tileSize: CGFloat = 64.0
    var tileHeight: CGFloat = 64.0
    var rows: Int = 0
    var cols: Int = 0
    
    // Logical Data
    private(set) var grid: [TilePosition: Tile] = [:]
    
    // Navigation Data (gridNodes dict is gone!)
    var weightedGraph = GKGraph()
    
    // MARK: - Tile Set Generation
    private func createTileSet() -> SKTileSet {
        // Ground
        let groundTex = SKTexture(imageNamed: "ground")
        groundTex.filteringMode = .nearest
        let groundDef = SKTileDefinition(texture: groundTex, size: CGSize(width: tileSize, height: tileHeight))
        let groundGroup = SKTileGroup(tileDefinition: groundDef)
        groundGroup.name = TerrainType.ground.rawValue // "."
        
        // Wall
        let wallTex = SKTexture(imageNamed: "wall")
        wallTex.filteringMode = .nearest
        let wallDef = SKTileDefinition(texture: wallTex, size: CGSize(width: tileSize, height: tileHeight))
        let wallGroup = SKTileGroup(tileDefinition: wallDef)
        wallGroup.name = TerrainType.wall.rawValue // "W"
        
        // Objective
        let objTex = SKTexture(imageNamed: "objective")
        objTex.filteringMode = .nearest
        let objDef = SKTileDefinition(texture: objTex, size: CGSize(width: tileSize, height: tileHeight))
        let objGroup = SKTileGroup(tileDefinition: objDef)
        objGroup.name = TerrainType.objective.rawValue // "O"
        
        return SKTileSet(tileGroups: [groundGroup, wallGroup, objGroup])
    }
    
    // MARK: - Map Building
    func buildMap(from data: LevelData) {
        worldNode.removeAllChildren()
        grid.removeAll()
        
        self.rows = data.layout.count
        self.cols = data.layout[0].count
        
        // 1. Generate the visual Tile Map
        let tileSet = createTileSet()
        tileMap = SKTileMapNode(tileSet: tileSet, columns: cols, rows: rows, tileSize: CGSize(width: tileSize, height: tileHeight))
        worldNode.addChild(tileMap)
        
        // 2. Populate Map
        for (r, rowStr) in data.layout.enumerated() {
            for (c, char) in rowStr.enumerated() {
                let pos = TilePosition(row: r, col: c)
                let terrain = TerrainType(rawValue: String(char)) ?? .ground
                
                // SKTileMapNode handles rows bottom-up (0 is bottom).
                // We invert it here so your level data array (where 0 is top) renders correctly.
                let skRow = rows - 1 - r
                
                // Set Visual Tile
                if let group = tileSet.tileGroups.first(where: { $0.name == terrain.rawValue }) {
                    tileMap.setTileGroup(group, forColumn: c, row: skRow)
                }
                
                // Generate Logical Tile with embedded screen position for its Nav Node
                let screenPos = calculateScreenPos(pos)
                let tile = Tile(position: pos, terrain: terrain, screenPos: screenPos)
                grid[pos] = tile
            }
        }
    }
    
    // MARK: - Navigation Graph
    func generateNavGraph(entityManager: EntityManager) {
        weightedGraph = GKGraph()
        var validNodes: [WeightedNode] = []
        
        // 1. Setup initial costs and collect valid Nav Nodes directly from Tiles
        for (_, tile) in grid where tile.isWalkable {
            _ = tile.calculateCost(entityManager: entityManager)
            validNodes.append(tile.navNode)
        }
        
        // 2. Connect neighbors
        for (pos, tile) in grid where tile.isWalkable {
            let neighbors = [
                TilePosition(row: pos.row + 1, col: pos.col),
                TilePosition(row: pos.row - 1, col: pos.col),
                TilePosition(row: pos.row, col: pos.col + 1),
                TilePosition(row: pos.row, col: pos.col - 1),
                // Diagonals (optional, remove if you only want 4-way movement)
                //TilePosition(row: pos.row + 1, col: pos.col + 1),
                //TilePosition(row: pos.row - 1, col: pos.col - 1),
                //TilePosition(row: pos.row + 1, col: pos.col - 1),
                //TilePosition(row: pos.row - 1, col: pos.col + 1)
            ]
            
            var connectionNodes: [WeightedNode] = []
            for nPos in neighbors {
                if let neighborTile = grid[nPos], neighborTile.isWalkable {
                    connectionNodes.append(neighborTile.navNode)
                }
            }
            
            tile.navNode.addConnections(to: connectionNodes, bidirectional: false)
        }
        
        weightedGraph.add(validNodes)
    }
    
    // MARK: - Tile Weight
    func syncTileWeight(at pos: TilePosition, entityManager: EntityManager) {
        guard let tile = grid[pos] else { return }
        _ = tile.calculateCost(entityManager: entityManager)
        // calculateCost now auto-updates tile.navNode.weight under the hood
    }

    // MARK: - Occupancy Updates
    func addEntity(_ entityID: UUID, at pos: TilePosition, entityManager: EntityManager) {
        grid[pos]?.occupants.insert(entityID)
        syncTileWeight(at: pos, entityManager: entityManager)
    }
    
    func removeEntity(_ entityID: UUID, at pos: TilePosition, entityManager: EntityManager) {
        grid[pos]?.occupants.remove(entityID)
        syncTileWeight(at: pos, entityManager: entityManager)
    }

    func moveEntity(_ entityID: UUID, from oldPos: TilePosition, to newPos: TilePosition, entityManager: EntityManager) {
        grid[oldPos]?.occupants.remove(entityID)
        syncTileWeight(at: oldPos, entityManager: entityManager)
        
        grid[newPos]?.occupants.insert(entityID)
        syncTileWeight(at: newPos, entityManager: entityManager)
    }
    
    //MARK: MISC
    func findPath(from start: TilePosition, to end: TilePosition) -> [vector_float2] {
        // 1. Pull the nodes directly from the Tile
        guard let startTile = grid[start], startTile.isWalkable,
              let endTile = grid[end], endTile.isWalkable else {
            return []
        }
        
        // 2. Run A* on the Weighted Graph
        let nodes = weightedGraph.findPath(from: startTile.navNode, to: endTile.navNode) as? [WeightedNode] ?? []
        
        // 3. Convert nodes to screen waypoints
        var path = nodes.map { node in
            let screenPos = calculateScreenPos(node.gridPos)
            return vector_float2(Float(screenPos.x), Float(screenPos.y))
        }
        
        // 4. Optimization: If the entity is already on the first node, remove it
        if !path.isEmpty {
            path.removeFirst()
        }
        
        return path
    }
}

// MARK: - Top-Down Math Utilities
extension MapManager {
    
    func calculateScreenPos(_ pos: TilePosition) -> CGPoint {
        guard let tileMap = tileMap else { return .zero }
        // Convert top-down logical row to SKTileMapNode's bottom-up row
        let skRow = rows - 1 - pos.row
        return tileMap.centerOfTile(atColumn: pos.col, row: skRow)
    }
    
    func calculateGridPos(from worldPos: CGPoint) -> TilePosition {
        guard let tileMap = tileMap else { return TilePosition(row: 0, col: 0) }
        let col = tileMap.tileColumnIndex(fromPosition: worldPos)
        let skRow = tileMap.tileRowIndex(fromPosition: worldPos)
        
        // Convert SKTileMapNode's bottom-up row back to top-down logical row
        let row = rows - 1 - skRow
        
        // Clamp to prevent out of bounds crashes on edge clicks
        return TilePosition(row: max(0, min(rows - 1, row)), col: max(0, min(cols - 1, col)))
    }
    
    func fitMapToScreen(screenSize: CGSize) {
        guard let tileMap = tileMap else { return }
        
        let mapWidth = tileMap.mapSize.width
        let mapHeight = tileMap.mapSize.height
        
        // Determine the scale needed to fit 90% of the screen
        let scaleX = (screenSize.width * 0.9) / mapWidth
        let scaleY = (screenSize.height * 0.9) / mapHeight
        let finalScale = min(scaleX, scaleY)
        
        worldNode.setScale(finalScale)
        
        // SKTileMapNode natively places its origin at the absolute center of the map.
        // Therefore, we just center the worldNode in the view. Easy!
        worldNode.position = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
    }
}

extension MapManager {
    func findNearestObjective(from currentPosition: vector_float2) -> TilePosition? {
        var nearestPos: TilePosition? = nil
        var shortestDistance = Float.infinity
        
        for (pos, tile) in grid where tile.terrain == .objective {
            let screenPos = calculateScreenPos(pos)
            let tileWorldPos = vector_float2(Float(screenPos.x), Float(screenPos.y))
            
            let dist = simd_distance(currentPosition, tileWorldPos)
            if dist < shortestDistance {
                shortestDistance = dist
                nearestPos = pos
            }
        }
        
        return nearestPos
    }
}
