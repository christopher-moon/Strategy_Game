//handles ai ticking, pathing, and conflic resolution 
import SpriteKit

class MovementSystem {
    unowned let manager: UnitManager
    
    // State specific to movement
    var moveRequests: [UUID: TilePosition] = [:]
    var reservedTiles: Set<TilePosition> = []
    
    init(manager: UnitManager) {
        self.manager = manager
    }
    
    // MARK: - AI Tick Control
    func startAITick(interval: TimeInterval = 0.3) {
        guard let scene = manager.scene else { return }
        
        let wait = SKAction.wait(forDuration: interval)
        let update = SKAction.run { [weak self] in self?.performMovementTick() }
        
        scene.run(SKAction.repeatForever(SKAction.sequence([update, wait])), withKey: "unitAITick")
    }
    
    func stopAITick() {
        manager.scene?.removeAction(forKey: "unitAITick")
    }
    
    func clearReservation(for unit: UnitNode) {
        reservedTiles.remove(unit.unit.position)
    }
    
    // MARK: - Core Logic
    func performMovementTick() {
        guard let scene = manager.scene else { return }
        moveRequests.removeAll()
        
        // Reserve current positions to prevent collisions
        reservedTiles = Set(manager.units.values.map { $0.unit.position })
        
        // Phase 1: Units submit desired next steps
        for unit in manager.units.values {
            // Cooldown check
            if unit.unit.movementCooldown > 0 {
                unit.unit.movementCooldown -= 1
                continue
            }
            
            // AI Brain Check
            if let next = unit.unit.ai.determineAction(for: unit, manager: manager) {
                moveRequests[unit.unit.id] = next
            }
        }
        
        // Phase 2: Resolve conflicts
        resolveMoveRequests(in: scene)
        
        // Phase 3: Trigger Combat (Delegated to CombatSystem)
        manager.combat.performAttackTick()
        
        // Phase 4: Update reserved tiles for next tick
        reservedTiles = Set(manager.units.values.map { $0.unit.position })
    }
    
    private func resolveMoveRequests(in scene: GameScene) {
        // Group requests by target tile
        let requestsByTile = Dictionary(grouping: moveRequests.keys) { moveRequests[$0]! }

        for (tilePos, requesters) in requestsByTile {
            
            // Skip if tile already reserved or unwalkable
            // Note: Accessing GridManager via Manager
            if reservedTiles.contains(tilePos) || !manager.gridManager.isTileWalkable(tilePos) {
                failMove(requesters: requesters, target: tilePos)
                continue
            }

            // Pick one unit to move
            let movableUnits = requesters.compactMap { manager.units[$0] }
            guard !movableUnits.isEmpty else { continue }

            let winner = movableUnits.randomElement()!
            
            if let tileNode = scene.tileAt(position: tilePos) {
                commitMove(winner, to: tileNode)
                reservedTiles.insert(tilePos)
            }

            // Others fail
            let losers = requesters.filter { $0 != winner.unit.id }
            failMove(requesters: losers, target: tilePos)
        }
    }
    
    private func failMove(requesters: [UUID], target: TilePosition) {
        for id in requesters {
            if let unit = manager.units[id] {
                unit.unit.needsRepath = true
                if unit.unit.currentGoal == target {
                    unit.unit.currentGoal = nil
                }
            }
        }
    }
    
    // MARK: - Execution
    func commitMove(_ unit: UnitNode, to tile: TileNode) {
        let ticks = unit.unit.movementSpeed
        let duration = 0.3 * Double(ticks)
        
        let newPos = tile.tile.position
        let oldPos = unit.unit.position
        
        // 1. Visual Move
        unit.moveVisual(to: tile, duration: duration)
        
        // 2. Logical Move
        unit.unit.position = newPos
        
        // 3. Grid Update
        manager.gridManager.clearOccupancy(at: oldPos)
        manager.gridManager.registerOccupancy(id: unit.unit.id, pos: newPos)
        reservedTiles.remove(oldPos)
        
        // 4. Trap Interaction
        //manager.obstacleManager.handleTrapInteraction(at: newPos, unit: unit)
        
        // 5. Path Management
        if var path = unit.unit.currentPath, !path.isEmpty {
            path.removeFirst()
            unit.unit.currentPath = path
        }
        
        // 6. Cooldown
        unit.unit.movementCooldown = ticks
    }
    
    // MARK: - Pathfinding
    func pathfind(from start: TilePosition, to goal: TilePosition, for movingUnit: UnitNode) -> [TilePosition]? {
        guard let scene = manager.scene else { return nil }
        
        let pathfinder = AStarPathfinder(
            rows: scene.rows,
            cols: scene.cols,
            isWalkable: { pos in
                if pos == goal { return true }
                return self.manager.gridManager.isTileWalkable(pos)
            },
            cost: { pos in
                if pos == movingUnit.unit.position { return 1 }
                var baseCost = 1
                
                // Objective / Mission Logic
                if let occupant = self.manager.unitAt(pos), occupant.unit.team != movingUnit.unit.team {
                    baseCost = movingUnit.unit.isMissionLocked ? 15 : 120
                } else {
                    baseCost = 5
                }
                
                if self.reservedTiles.contains(pos) { return 3 }
                
                // Cooperative pathing bonus
                var bonus = 0
                for unit in self.manager.units.values {
                    guard unit.unit.id != movingUnit.unit.id, unit.unit.team == movingUnit.unit.team else { continue }
                    if let path = unit.unit.currentPath,
                       path.contains(pos),
                       self.manager.distance(from: unit.unit.position, to: movingUnit.unit.position) <= 3 {
                           bonus -= 2
                    }
                }
                
                return max(1, baseCost + bonus)
            }
        )

        return pathfinder.findPath(from: start, to: goal)
    }
    
    func findNearestObjectiveTile(from position: TilePosition) -> TilePosition? {
        return manager.scene?.findNearestObjective(from: position, unitManager: manager)
    }
}
