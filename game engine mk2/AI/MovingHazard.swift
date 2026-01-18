/* PatrolBrain_MK3.swift */

class MovingHazardBrain: AIBrain_MK3 {
    func decide(owner: Entity_MK3, grid: Grid_MK3, entityManager: EntityManager_MK3) {
        // 1. Only decide on a new path if we are currently doing nothing
        guard owner.state == .idle else { return }
        
        // 2. Safety check for patrol points
        guard !owner.patrolPoints.isEmpty else { return }
        
        // 3. Move to the next patrol index
        // We increment first to ensure we aren't pathing to our current tile
        owner.currentPatrolIndex = (owner.currentPatrolIndex + 1) % owner.patrolPoints.count
        
        let target = owner.patrolPoints[owner.currentPatrolIndex]
        
        // 4. Use the Absolute Linear pathfinder
        // This ensures hazards ignore all walls/units during path generation
        let path = Pathfinding_MK3.findAbsoluteLinearPath(from: owner.position, to: target)
        
        if !path.isEmpty {
            owner.movement?.currentPath = path
            owner.state = .moving
            // print("Hazard \(owner.name) decided to move to \(target)")
        }
    }
}
