/* MovingHazard.swift */

import Foundation

class MovingHazardBrain: AIBrain_MK3 {
    // We store the last ID we hit to prevent "machine-gun" damage
    private var lastHitID: UUID?

    func decide(owner: Entity_MK3, grid: Grid_MK3, entityManager: EntityManager_MK3) {
        
        //spawning
        if owner.state == .spawning {
            owner.state = .idle
        }
        
        /*
        // 1. If we are currently in the pause frame, reset to idle and move on
        if case .attacking = owner.state {
            owner.state = .idle
            return
        }

        // 2. COMBAT: Check for enemies
        if let enemyID = findTarget(owner: owner, grid: grid) {
            // ONLY trigger damage if this is a NEW target
            if enemyID != lastHitID {
                print("saw hit NEW target - damaging")
                lastHitID = enemyID // Remember this target
                setTarget(owner: owner, target: enemyID)
                return
            }
        } else {
            // If no enemy is found, clear the memory so we can hit the
            // same unit again if we loop back around or it moves back into us.
            lastHitID = nil
        }
        
        // 3. MOVEMENT: Standard patrol logic
        if owner.state == .idle || owner.movement?.currentPath.isEmpty == true {
            guard !owner.patrolPoints.isEmpty else { return }
            
            let targetPos = owner.patrolPoints[owner.currentPatrolIndex]
            if owner.position == targetPos {
                owner.currentPatrolIndex = (owner.currentPatrolIndex + 1) % owner.patrolPoints.count
            }
            
            let nextDestination = owner.patrolPoints[owner.currentPatrolIndex]
            _ = requestMove(owner: owner, to: nextDestination, grid: grid)
        }
         */
    }
}
