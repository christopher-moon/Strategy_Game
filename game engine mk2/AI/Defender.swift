/* DefenderBrain.swift */
import Foundation

class DefenderBrain: AIBrain_MK3 {
    
    func decide(owner: Entity_MK3, grid: Grid_MK3, entityManager: EntityManager_MK3) {
        let canFly = owner.movement?.isFlying ?? false
        let threatRange = owner.combat?.threatRange ?? 1
        
        // 1. VISION SCAN:
        // Identify enemies visible to the unit (stones block vision)
        let visionMap = grid.getNavigationMap(from: owner.position, canFly: canFly, type: .vision, maxCost: threatRange + 1)
        
        // Lazy-loaded Movement Map
        // Only generate the physics map (ignoring vision blockers) if we actually need to move.
        var _movementMap: NavigationMap?
        func getMovementMap(range: Int? = nil) -> NavigationMap {
            if let map = _movementMap { return map }
            let map = grid.getNavigationMap(from: owner.position, canFly: canFly, type: .movement, maxCost: range)
            _movementMap = map
            return map
        }
        
        // 2. PERSISTENCE: Stick to current target if they are still a threat
        if let currentID = owner.combat?.currentTargetID {
            let targetEntity = entityManager.allEntities.first { $0.id == currentID }
            let isDead = targetEntity?.state == .dead || targetEntity == nil
            let dist = targetEntity != nil ? grid.distance(owner.position, targetEntity!.position) : Int.max
            
            // Defender Logic: Only chase if they are within immediate threat range
            if !isDead && dist <= threatRange {
                // Use Movement Map to engage (allows pathing around obstacles)
                if engageTarget(owner: owner, targetID: currentID, entityManager: entityManager, grid: grid, navMap: getMovementMap(range: threatRange + 1)) {
                    return
                }
            } else {
                owner.combat?.currentTargetID = nil
            }
        }
        
        // 3. PRIORITY 1: Look for NEW enemies
        // Use Vision Map to find valid targets
        if let newTargetID = findTarget(owner: owner, grid: grid, navMap: visionMap) {
            if engageTarget(owner: owner, targetID: newTargetID, entityManager: entityManager, grid: grid, navMap: getMovementMap(range: threatRange)) {
                return
            } else {
                return
            }
        }
        
        // 4. PRIORITY 2: RETURN HOME (The Defender Twist)
        // If no enemies are present, return to the first patrol point
        if let homeTile = owner.patrolPoints.first {
            if owner.position != homeTile {
                // Use Movement Map to find the path home
                _ = requestMove(owner: owner, to: homeTile, grid: grid, navMap: getMovementMap())
                return
            }
        }
        
        // 5. PRIORITY 3: IDLE at home
        owner.state = .idle
    }
}
