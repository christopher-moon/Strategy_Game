/* AttackPatterns.swift */
import Foundation

extension AttackPattern {
    // Added spawnRequest closure to stay decoupled from SpriteKit
    func getTargets(
        attacker: Entity_MK3,
        targetID: UUID?,
        entityManager: EntityManager_MK3,
        grid: Grid_MK3,
        spawnRequest: ((String, UUID) -> Void)? = nil
    ) -> [Entity_MK3] {
        
        switch self {
        
        //single target melee hit
        case .singleTarget:
            guard let id = targetID,
                  let target = entityManager.allEntities.first(where: { $0.id == id }) else {
                return []
            }
            let isDead = target.state == .dead || (target.health?.isDead ?? false)
            return isDead ? [] : [target]
        
        //aoe
        case .aoe(let radius):
            return entityManager.allEntities.filter { victim in
                let dist = abs(attacker.position.row - victim.position.row) +
                           abs(attacker.position.col - victim.position.col)
                let isAlive = victim.state != .dead && !(victim.health?.isDead ?? false)
                let isEnemy = victim.team != attacker.team
                return dist <= radius && isAlive && isEnemy
            }
        
        //projectile
        case .projectile(let name):
            guard let id = targetID,
                  let target = entityManager.allEntities.first(where: { $0.id == id }) else {
                return []
            }
            let isDead = target.state == .dead || (target.health?.isDead ?? false)
            return isDead ? [] : [target]
        }
    }
}
