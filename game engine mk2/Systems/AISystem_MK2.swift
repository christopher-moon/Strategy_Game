/*
 AISystem_MK2.swift:
 call ai brain decide
*/
class AISystem_MK2 {
    func update(entityManager: EntityManager_MK2, grid: Grid_MK2) {
        for entity in entityManager.allEntities {
            if let unit = entity as? Unit_MK2, let brain = unit.ai {
                // Brain analyzes the grid and sets unit.currentPath or unit.state
                brain.decide(owner: unit, grid: grid, entityManager: entityManager)
            }
        }
    }
}
