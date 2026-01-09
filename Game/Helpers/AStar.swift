class AStarPathfinder {

    struct Node: Hashable {
        let pos: TilePosition
        let g: Int     // cost from start
        let h: Int     // heuristic
        var f: Int { g + h }
    }

    let rows: Int
    let cols: Int
    let isWalkable: (TilePosition) -> Bool
    let cost: (TilePosition) -> Int    // new

    init(rows: Int, cols: Int, isWalkable: @escaping (TilePosition) -> Bool, cost: @escaping (TilePosition) -> Int = { _ in 1 }) {
        self.rows = rows
        self.cols = cols
        self.isWalkable = isWalkable
        self.cost = cost
    }

    func neighbors(of pos: TilePosition) -> [TilePosition] {
        let deltas = [(1,0), (-1,0), (0,1), (0,-1)]
        return deltas.compactMap { d in
            let n = TilePosition(row: pos.row + d.0, col: pos.col + d.1)
            guard n.row >= 0, n.row < rows, n.col >= 0, n.col < cols else { return nil }
            guard isWalkable(n) else { return nil }
            return n
        }
    }

    func heuristic(_ a: TilePosition, _ b: TilePosition) -> Int {
        return abs(a.row - b.row) + abs(a.col - b.col)
    }

    func findPath(from start: TilePosition, to goal: TilePosition) -> [TilePosition]? {
        var open: Set<Node> = []
        var cameFrom: [TilePosition: TilePosition] = [:]

        let startNode = Node(pos: start, g: 0, h: heuristic(start, goal))
        open.insert(startNode)

        var gScore: [TilePosition: Int] = [start: 0]

        while !open.isEmpty {
            let current = open.min(by: { $0.f < $1.f })!
            open.remove(current)

            if current.pos == goal { return reconstructPath(cameFrom, current.pos) }

            for neighbor in neighbors(of: current.pos) {
                let tentativeG = current.g + cost(neighbor)  // use cost instead of 1
                if tentativeG < (gScore[neighbor] ?? Int.max) {
                    cameFrom[neighbor] = current.pos
                    gScore[neighbor] = tentativeG
                    let neighborNode = Node(pos: neighbor, g: tentativeG, h: heuristic(neighbor, goal))
                    open.insert(neighborNode)
                }
            }
        }

        return nil
    }

    private func reconstructPath(_ cameFrom: [TilePosition : TilePosition], _ current: TilePosition) -> [TilePosition] {
        var path: [TilePosition] = [current]
        var current = current
        while let prev = cameFrom[current] {
            current = prev
            path.append(current)
        }
        return path.reversed()
    }
}

