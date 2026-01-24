/* AttackerBrain.swift */
import Foundation

class AttackerBrain: AIBrain_MK3 {
    
    func decide(owner: Entity_MK3, grid: Grid_MK3, entityManager: EntityManager_MK3) {
        let canFly = owner.movement?.isFlying ?? false
        let threatRange = owner.combat?.threatRange ?? 1
        
        if owner.state == .spawning {
            owner.state = .idle
        }
        
        // 1. VISION SCAN:
        // We generate a map that respects vision (treats Stones as walls).
        // This determines WHO we can see to target.
        let visionMap = grid.getNavigationMap(from: owner.position, canFly: canFly, type: .vision, maxCost: threatRange + 1)
        
        // Lazy-loaded Movement Map
        // We only generate the map that ignores vision (treats Stones as walkable obstacles)
        // if we actually decide to move. This saves performance.
        var _movementMap: NavigationMap?
        func getMovementMap(range: Int? = nil) -> NavigationMap {
            if let map = _movementMap { return map }
            let map = grid.getNavigationMap(from: owner.position, canFly: canFly, type: .movement, maxCost: range)
            _movementMap = map
            return map
        }
        
        // 2. PERSISTENCE: If we already have a target, stay on them
        if let currentID = owner.combat?.currentTargetID {
            let targetEntity = entityManager.allEntities.first { $0.id == currentID }
            let isDead = targetEntity?.state == .dead || targetEntity == nil
            let dist = targetEntity != nil ? grid.distance(owner.position, targetEntity!.position) : Int.max
            
            if !isDead && dist <= (threatRange + 2) { // 'Leash' buffer
                // We use the Movement Map to chase them (allows pathing through stones)
                if engageTarget(owner: owner, targetID: currentID, entityManager: entityManager, grid: grid, navMap: getMovementMap(range: threatRange+1)) {
                    return
                }
            } else {
                owner.combat?.currentTargetID = nil
            }
        }
        
        // 3. PRIORITY 1: NEW COMBAT
        // Use visionMap to find closest visible enemy
        if let newTargetID = findTarget(owner: owner, grid: grid, navMap: visionMap) {
            // Found one! Now use Movement Map to actually path towards them
            if engageTarget(owner: owner, targetID: newTargetID, entityManager: entityManager, grid: grid, navMap: getMovementMap(range: threatRange + 1)) {
                return
            } else {
                return
            }
        }

        // 4. PRIORITY 2: OBJECTIVE
        if playObjectiveAStar(owner: owner, grid: grid){
            return
        }
        
        // 5. PRIORITY 3: IDLE
        // This prevents flickering if the unit is waiting a few frames for the next tick.
        if owner.state != .idle {
            print("cant do anything")
            owner.state = .idle
        }
    }
}
