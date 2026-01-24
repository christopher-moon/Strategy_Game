/* AIBrain_MK3.swift */
import Foundation

protocol AIBrain_MK3 {
    func decide(owner: Entity_MK3, grid: Grid_MK3, entityManager: EntityManager_MK3)
}

extension AIBrain_MK3 {
    
    // MARK: - Movement Requests
    
    /// Requests movement using the provided NavigationMap to extract a path instantly.
    func requestMove(owner: Entity_MK3, to target: TilePosition, grid: Grid_MK3, navMap: NavigationMap?) -> Bool {
        if owner.position == target { return false }
        
        // Optimization: Don't update if already heading exactly there
        if owner.state == .moving, owner.movement?.currentPath.last == target { return true }
        
        let type = owner.movement?.movementType ?? .smart
        var path: [TilePosition] = []
        
        if type == .simple {
            // Simple movers (projectiles/flying effects) move in a straight line ignoring physics
            path = calculateLinearPath(from: owner.position, to: target)
        } else {
            // Smart movers use the pre-calculated NavigationMap
            guard let map = navMap else { return false }
            path = map.getPath(to: target)
        }
        
        if !path.isEmpty {
            owner.movement?.currentPath = path
            owner.state = .moving
            return true
        }
        return false
    }
    
    // MARK: - Combat Logic
    
    func setTarget(owner: Entity_MK3, target: UUID) {
        owner.movement?.currentPath.removeAll()
        owner.combat?.currentTargetID = target
        owner.state = .attacking(targetID: target)
    }
    
    /// Uses the NavigationMap to find the closest enemy based on actual movement cost.
    func findTarget(owner: Entity_MK3, grid: Grid_MK3, navMap: NavigationMap) -> UUID? {
        guard let threatRange = owner.combat?.threatRange else { return nil }
        
        return grid.findClosestEnemy(
            from: owner.position,
            range: threatRange,
            excludingTeam: owner.team,
            navMap: navMap
        )
    }

    /// Engages a target: attacks if in range, or moves to the best attack spot if not.
    func engageTarget(owner: Entity_MK3, targetID: UUID, entityManager: EntityManager_MK3, grid: Grid_MK3, navMap: NavigationMap) -> Bool {
        
        guard let targetEntity = entityManager.allEntities.first(where: { $0.id == targetID }) else { return false }
                
        let dist = grid.distance(owner.position, targetEntity.position)
        let attackRange = owner.combat?.range ?? 1
        
        if dist <= attackRange {
            if case .attacking = owner.state { return true }
            setTarget(owner: owner, target: targetID)
            return true
        } else {
            // Use Grid's optimized lookup to find the best firing position
            if let bestSpot = grid.findBestAttackSpot(
                near: targetEntity.position,
                range: attackRange,
                ignoringID: owner.id,
                navMap: navMap
            ) {
                return requestMove(owner: owner, to: bestSpot, grid: grid, navMap: navMap)
            }
        }
        print("cant move")
        return false
    }
    
    //wait in combat
    func waitInCombat(owner: Entity_MK3){
        
    }

    // MARK: - Objective Logic
    
    func playObjectiveAStar(owner: Entity_MK3, grid: Grid_MK3) -> Bool {
            // 1. Ask the grid WHERE the nearest objective is (Fast coordinate check)
            guard let targetPos = grid.findNearestObjectivePos(from: owner.position) else {
                return false
            }
            
            // 2. Optimization: Don't recalculate if we are already moving to this specific tile
            if owner.state == .moving, owner.movement?.currentPath.last == targetPos {
                return true
            }

            // 3. Use A* to find HOW to get there (Fast directional search)
            let canFly = owner.movement?.isFlying ?? false
            let path = grid.findPath(
                from: owner.position,
                to: targetPos,
                grid: grid,
                canFly: canFly
            )
            
            if !path.isEmpty {
                owner.movement?.currentPath = path
                owner.state = .moving
                return true
            }
            
            return false
        }
    
    // MARK: - Helpers
    
    // Replaces the old Pathfinding_MK3.findAbsoluteLinearPath
    private func calculateLinearPath(from start: TilePosition, to target: TilePosition) -> [TilePosition] {
        var path: [TilePosition] = []
        var current = start
        
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
}
