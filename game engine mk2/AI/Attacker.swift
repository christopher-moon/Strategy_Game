/* AttackerBrain.swift */

class AttackerBrain: AIBrain_MK3 {
    
    func decide(owner: Entity_MK3, grid: Grid_MK3, entityManager: EntityManager_MK3) {
        let canFly = owner.movement?.isFlying ?? false
        let threatRange = owner.combat?.threatRange ?? 1
        
        // 1. VISION SCAN: Stones are walls.
        // We use this ONLY to decide if we can "spot" a new enemy.
        let visionMap = grid.getReachableMap(from: owner.position, canFly: canFly, respectVision: true)
        
        // 2. PATH MAP: We'll create this "lazily" only if we need to move/attack
        var pathMap: [TilePosition: Int]?
        
        // 1. PERSISTENCE: If we already have a target, stay on them
        if let currentID = owner.combat?.currentTargetID {
            let targetEntity = entityManager.allEntities.first { $0.id == currentID }
            let isDead = targetEntity?.state == .dead || targetEntity == nil
            let dist = targetEntity != nil ? grid.distance(owner.position, targetEntity!.position) : Int.max
            
            if !isDead && dist <= (threatRange + 2) { // Give them a little 'leash' buffer
                // We need the pathMap here so we don't stop if they hide behind a stone
                pathMap = grid.getReachableMap(from: owner.position, canFly: canFly, respectVision: false)
                if engageTarget(owner: owner, targetID: currentID, entityManager: entityManager, grid: grid, reachableMap: pathMap!) {
                    return
                }
            } else {
                owner.combat?.currentTargetID = nil
            }
        }
        
        // 2. PRIORITY 1: NEW COMBAT (Use visionMap to see them)
        if let newTargetID = findTarget(owner: owner, grid: grid, reachableMap: visionMap) {
            // Found them with vision! Now use pathMap to move toward them
            if pathMap == nil {
                pathMap = grid.getReachableMap(from: owner.position, canFly: canFly, respectVision: false)
            }
            if engageTarget(owner: owner, targetID: newTargetID, entityManager: entityManager, grid: grid, reachableMap: pathMap!) {
                return
            }
        }
        
        // 3. PRIORITY 2: OBJECTIVE
        if pathMap == nil {
            pathMap = grid.getReachableMap(from: owner.position, canFly: canFly, respectVision: false)
        }
        if playObjective(owner: owner, grid: grid, reachableMap: pathMap!) {
            return
        }
        
        // 4. PRIORITY 3: IDLE 
        owner.state = .idle
    }
}
