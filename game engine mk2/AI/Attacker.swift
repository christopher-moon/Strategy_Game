class AttackerBrain: AIBrain_MK2 {
    func decide(owner: Entity_MK2, grid: Grid_MK2, entityManager: EntityManager_MK2) {
        guard let unit = owner as? Unit_MK2 else { return }

        // 1. Try to fight
        if executeCombatBehavior(unit: unit, grid: grid, entityManager: entityManager) { return }
        
        // 2. Try to capture
        if let obj = grid.findNearestObjective(from: unit.position) {
            executeMoveBehavior(unit: unit, to: obj, grid: grid)
            return
        }
        
        unit.state = .idle
    }
}
