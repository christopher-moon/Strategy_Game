/* AISystem_MK3.swift */

class AISystem_MK3 {
    func update(entityManager: EntityManager_MK3, grid: Grid_MK3) {
        for entity in entityManager.allEntities {
            // Ensure the entity has a brain to think with
            // (Assumes you added 'var ai: AIBrain_MK3?' to your Entity or Unit class)
            if let brain = entity.ai {
                brain.decide(owner: entity, grid: grid, entityManager: entityManager)
            }
        }
    }
}
