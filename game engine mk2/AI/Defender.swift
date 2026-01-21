/* DefenderBrain.swift */

class DefenderBrain: AIBrain_MK3 {
    
    func decide(owner: Entity_MK3, grid: Grid_MK3, entityManager: EntityManager_MK3) {
        let canFly = owner.movement?.isFlying ?? false
        let reachableMap = grid.getReachableMap(from: owner.position, canFly: canFly)
        let threatRange = owner.combat?.threatRange ?? 1
        
        // 1. PERSISTENCE: Stick to current target if they are still a threat
        if let currentID = owner.combat?.currentTargetID {
            let targetEntity = entityManager.allEntities.first { $0.id == currentID }
            let isDead = targetEntity?.state == .dead || targetEntity == nil
            let dist = targetEntity != nil ? grid.distance(owner.position, targetEntity!.position) : Int.max
            
            // Defender logic: Only chase if they stay within a certain distance of "Home"
            // (Optional: you could add a 'leash' range here)
            if !isDead && dist <= threatRange {
                if engageTarget(owner: owner, targetID: currentID, entityManager: entityManager, grid: grid, reachableMap: reachableMap) {
                    return
                }
            } else {
                owner.combat?.currentTargetID = nil
            }
        }
        
        // 2. PRIORITY 1: Look for NEW enemies within threat range
        if let newTargetID = findTarget(owner: owner, grid: grid, reachableMap: reachableMap) {
            if engageTarget(owner: owner, targetID: newTargetID, entityManager: entityManager, grid: grid, reachableMap: reachableMap) {
                return
            }
        }
        
        // 3. PRIORITY 2: RETURN HOME (The Defender Twist)
        // If no enemies, move back to the first patrol point
        if let homeTile = owner.patrolPoints.first {
            if owner.position != homeTile {
                _ = requestMove(owner: owner, to: homeTile, grid: grid)
                return
            }
        }
        
        // 4. PRIORITY 3: IDLE at home
        owner.state = .idle
    }
}
