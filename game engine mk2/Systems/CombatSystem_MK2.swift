/*
 CombatSystem_MK2.swift
 Handles health reduction and attack timing
*/
class CombatSystem_MK2 {
    func update(entityManager: EntityManager_MK2, grid: Grid_MK2) {
        for entity in entityManager.allEntities {
            guard let unit = entity as? Unit_MK2 else { continue }
            
            // 1. GUARD: Only process units that want to attack
            // We use 'if case let' to "unpack" the target from the state
            if case .attacking(let target) = unit.state {
                handleAttack(attacker: unit, target: target)
            }
        }
    }

    private func handleAttack(attacker: Unit_MK2, target: Entity_MK2) {
        // 2. CHECK: Is the target still alive?
        guard target.hp > 0 else {
            attacker.state = .idle // Target died, stop attacking
            return
        }

        // 3. TIMING: Different attack speeds
        attacker.internalAttackCounter += 1
        if attacker.internalAttackCounter >= attacker.attackSpeed {
            
            // 4. EXECUTION: Deal damage
            target.takeDamage(attacker.attack)
            attacker.internalAttackCounter = 0
            
            print("\(attacker.id) hit \(target.id) for \(attacker.attack) damage!")
        }
    }
}
