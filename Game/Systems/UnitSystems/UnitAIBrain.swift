import Foundation

protocol UnitAIBrain {
    func determineAction(for unit: UnitNode, manager: UnitManager) -> TilePosition?
}

extension UnitAIBrain {
    
    // MARK: - Move to Position
    func moveToward(target: TilePosition, for unit: UnitNode, manager: UnitManager) -> TilePosition? {
        
        // 1. ARRIVED
        if unit.unit.position == target {
            unit.unit.state = .idle
            unit.unit.currentPath = nil
            unit.unit.currentGoal = nil
            return nil
        }
        
        // 2. REPATHING
        // Note: NeedsRepath logic remains the same
        let shouldRepath = unit.unit.currentGoal != target || unit.unit.needsRepath || unit.unit.currentPath == nil || unit.unit.currentPath?.isEmpty == true
        
        if shouldRepath {
            // UPDATED: Call into MovementSystem
            if let path = manager.movement.pathfind(from: unit.unit.position, to: target, for: unit) {
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
    
    // MARK: - Objective
    func moveTowardNearestObjective(for unit: UnitNode, manager: UnitManager) -> TilePosition? {
        // UPDATED: Call into MovementSystem
        if let target = manager.movement.findNearestObjectiveTile(from: unit.unit.position) {
            return moveToward(target: target, for: unit, manager: manager)
        }
        unit.unit.state = .idle
        return nil
    }
    
    // MARK: - Attack Logic
    func attackTarget(_ target: UnitNode, for unit: UnitNode, manager: UnitManager) -> TilePosition? {
        // Distance check remains on Manager
        let dist = manager.distance(from: unit.unit.position, to: target.unit.position)
        
        if dist <= unit.unit.range {
            unit.unit.state = .attacking
            unit.unit.currentGoal = target.unit.position
            unit.unit.currentPath = nil
            return nil
        }
        
        //if unit.unit.range == 1 && dist == 1 {
            //unit.unit.state = .attacking
            //return nil
        //}
        
        unit.unit.state = .moving
        
        return moveToward(target: target.unit.position, for: unit, manager: manager)
    }
}
