/* AttackPatterns.swift */
import Foundation

extension AttackPattern {
    func getTargets(attacker: Entity_MK3, targetID: UUID?, entityManager: EntityManager_MK3, grid: Grid_MK3) -> [Entity_MK3] {
        switch self {
        case .singleTarget:
            guard let id = targetID,
                  let target = entityManager.allEntities.first(where: { $0.id == id }) else {
                return []
            }
            
            // Validation: Only return the target if it is NOT dead
            let isDead = target.state == .dead || (target.health?.isDead ?? false)
            return isDead ? [] : [target]
            
        case .aoe(let radius):
            return entityManager.allEntities.filter { victim in
                // Standard Manhattan distance check
                let dist = abs(attacker.position.row - victim.position.row) +
                           abs(attacker.position.col - victim.position.col)
                
                let isAlive = victim.state != .dead && !(victim.health?.isDead ?? false)
                let isEnemy = victim.team != attacker.team
                
                return dist <= radius && isAlive && isEnemy
            }
        }
    }
}
