import Foundation

// 1. Define the Protocol (The Blueprint)
protocol UnitAIBrain {
    
    // The UnitNode is passed as an argument, allowing the brain to read the unit's state.
    // The UnitManager is passed to allow the brain to access all units, tiles, and pathfinding.
    func determineAction(for unit: UnitNode, manager: UnitManager) -> TilePosition?
    
}

//authoratative unit state handler
extension UnitAIBrain {
    
    // MARK: - Reusable: Move to Position
    func moveToward(target: TilePosition, for unit: UnitNode, manager: UnitManager) -> TilePosition? {
        
        // 1. ARRIVED
        if unit.unit.position == target {
            unit.unit.state = .idle
            unit.unit.currentPath = nil
            unit.unit.currentGoal = nil
            return nil
        }
        
        // 2. REPATHING
        let shouldRepath = unit.unit.currentGoal != target || unit.unit.needsRepath || unit.unit.currentPath == nil || unit.unit.currentPath?.isEmpty == true
        
        if shouldRepath {
            if let path = manager.pathfind(from: unit.unit.position, to: target, for: unit) {
                // Modifying the properties directly on unit.unit
                unit.unit.currentPath = Array(path.dropFirst())
                unit.unit.currentGoal = target
                unit.unit.needsRepath = false
            } else {
                unit.unit.currentPath = nil
                unit.unit.state = .idle
                return nil
            }
        }
        
        // 3. MOVING
        if let next = unit.unit.currentPath?.first {
            unit.unit.state = .moving
            return next
        }
        
        unit.unit.state = .idle
        return nil
    }
    
    // MARK: - Objective (Consistency check)
    func moveTowardNearestObjective(for unit: UnitNode, manager: UnitManager) -> TilePosition? {
        if let target = manager.findNearestObjectiveTile(from: unit.unit.position) {
            return moveToward(target: target, for: unit, manager: manager)
        }
            
        unit.unit.state = .idle
        return nil
    }
    
    // MARK: - Reusable: Attack Logic
    func attackTarget(_ target: UnitNode, for unit: UnitNode, manager: UnitManager) -> TilePosition? {
        let dist = manager.distance(from: unit.unit.position, to: target.unit.position)
        
        //if in range, stop and attack
        if dist <= unit.unit.range {
            unit.unit.state = .attacking
            unit.unit.currentGoal = target.unit.position
            unit.unit.currentPath = nil
            return nil
        }
        
        // If we are melee (range 1) and we are exactly 1 tile away,
        // but the pathfinder failed (likely because the tile is occupied),
        // we should stay put and attack instead of idling.
        if unit.unit.range == 1 && dist == 1 {
            unit.unit.state = .attacking
            return nil
        }
        
        return moveToward(target: target.unit.position, for: unit, manager: manager)
        
    }
    
    // MARK: - Reusable: Leash Logic
    func checkLeash(home: TilePosition, radius: Int, for unit: UnitNode, manager: UnitManager) -> TilePosition? {
        let dist = manager.distance(from: unit.unit.position, to: home)
        if dist > radius {
            return moveToward(target: home, for: unit, manager: manager)
        }
        return nil
    }
}
