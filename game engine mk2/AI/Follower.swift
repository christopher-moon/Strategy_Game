/*
 Follower.swift
 follower ai brain: most basic ai that has to be manually moved
*/
/*
class FollowerBrain: AIBrain_MK2 {
    var targetPosition: TilePosition?
    private var lastProcessedTarget: TilePosition?

    func decide(owner: Entity_MK2, grid: Grid_MK2, entityManager: EntityManager_MK2) {
        guard let unit = owner as? Unit_MK2 else { return }
        
        // 1. If we have a target, use the extension to handle movement/state logic
        if let target = targetPosition {
            
            // This replaces your manual setTarget and state = .moving calls
            //performMoveAction(unit: unit, point: target, grid: grid)
            
            // 2. Arrival Logic: If the extension moved us to the point (or we are there)
            // we clear the memory so we don't keep re-calculating the same path
            if unit.position == target {
                unit.state = .idle
                targetPosition = nil
                lastProcessedTarget = nil
            }
        }
    }
}
*/
