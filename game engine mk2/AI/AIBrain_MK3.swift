/*
 AIBrain_MK2.swift
 define ai brain protocol
*/

protocol AIBrain_MK3 {
    func decide(owner: Entity_MK3, grid: Grid_MK3, entityManager: EntityManager_MK3)
}

/*
extension AIBrain_MK2 {
    
    // ACTION: The "All-in-One" Combat Behavior
    // This is the SINGLE location for state authority regarding combat.
    func executeCombatBehavior(unit: Unit_MK2, grid: Grid_MK2, entityManager: EntityManager_MK2) -> Bool {
        
        // 1. Math: Find the target (Persistence + Scanning)
        let target = getOrFindTarget(unit: unit, grid: grid, entityManager: entityManager)
        guard let enemy = target else { return false }
        
        unit.currentTarget = enemy.id
        let dist = grid.distance(unit.position, enemy.position)

        // 2. Logic: The "Stand Your Ground" Rule
        if dist <= unit.range {
            unit.state = .attacking(target: enemy)
        } else {
            // 3. Action: Smart Move
            let bestTile = grid.findTileInRange(target: enemy.position,
                                                range: unit.range,
                                                from: unit.position) ?? enemy.position
            
            // Re-use your clean move logic
            executeMoveBehavior(unit: unit, to: bestTile, grid: grid)
        }
        return true
    }

    // ACTION: Clean Movement
    func executeMoveBehavior(unit: Unit_MK2, to point: TilePosition, grid: Grid_MK2) {
        // 1. ARRIVAL CHECK
        if unit.position == point {
            unit.state = .idle
            unit.currentPath.removeAll()
            return
        }

        // 2. COMMITMENT CHECK
        // If we already have a path and the destination hasn't changed, STAY ON IT.
        if let existingDestination = unit.currentPath.last, existingDestination == point {
            unit.state = .moving
            return // Do not call setTarget! This preserves the current path.
        }

        // 3. NEW PATH (Only if destination changed or path is empty)
        unit.state = .moving
        unit.setTarget(target: point, grid: grid)
    }
    
    // HELPER: Private math for target persistence
    private func getOrFindTarget(unit: Unit_MK2, grid: Grid_MK2, entityManager: EntityManager_MK2) -> Unit_MK2? {
        if let id = unit.currentTarget,
           let existing = entityManager.allEntities.first(where: { $0.id == id }) as? Unit_MK2,
           existing.hp > 0, grid.distance(unit.position, existing.position) <= unit.threatRange {
            return existing
        }
        return scanForEnemies(unit: unit, grid: grid, entityManager: entityManager, range: unit.threatRange)
    }
    
    // scan for enemies
    func scanForEnemies(unit: Unit_MK2, grid: Grid_MK2, entityManager: EntityManager_MK2, range: Int) -> Unit_MK2? {
        // We call the grid query you just wrote!
        return grid.findNearestUnit(
            to: unit.position,
            maxRange: range,
            excludingTeam: unit.team,
            allEntities: entityManager.allEntities
        )
    }
}

*/
