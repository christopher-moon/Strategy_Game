/* CombatSystem_MK3.swift */
import Foundation

class CombatSystem_MK3 {
    
    func update(entityManager: EntityManager_MK3, grid: Grid_MK3) {
        for entity in entityManager.allEntities {
            
            //check if entity has a combat component
            guard let combat = entity.combat else { continue }
            
            //check if state == .attacking
            if case .attacking(let targetID) = entity.state {
                
                //handle attack windup
                combat.internalAttackCounter += 1
                
                //if attack wind-up is complete
                if combat.internalAttackCounter >= combat.attackSpeed {
                    
                    //get attack targets
                    //if target died mid-windup, this returns []
                    let victims = combat.attackPattern.getTargets(attacker: entity, targetID: targetID, entityManager: entityManager, grid: grid)
                    
                    //execute attack on all found targets
                    if !victims.isEmpty {
                        
                        //apply damage to target
                        applyDamage(from: entity, to: victims)
                        
                        // --- post-hit logic: check if combat is over ---
                        
                        //if selfDestruct == true
                        if combat.selfDestruct{
                            entity.state = .dead
                            entity.health?.current = 0
                        
                        //check if target is gone
                        }else if shouldStopAttacking(targetID: targetID, entityManager: entityManager) {
                            entity.state = .idle
                        }
                        //else, target is still alive and valid, stay in .combat state!
                        // print("Target still standing, swinging again...")
                    
                    //if target vanished/died during wind-up, stop combat
                    } else {
                        entity.state = .idle
                    }
                    
                    //reset attack wind-up after a successful attack
                    combat.internalAttackCounter = 0
                }
            } else {
                //reset attack wind-up if we moved or went idle
                combat.internalAttackCounter = 0
            }
        }
    }
    
    private func applyDamage(from attacker: Entity_MK3, to victims: [Entity_MK3]) {
        let damage = attacker.combat?.attack ?? 0
        for victim in victims {
            victim.health?.takeDamage(damage)
            
            // Mark dead immediately for this frame's logic
            if victim.health?.isDead == true {
                victim.state = .dead
                print("\(attacker.name) destroyed \(victim.name)!")
            }
        }
    }
    
    //helper to check if the specific primary target is dead
    private func shouldStopAttacking(targetID: UUID?, entityManager: EntityManager_MK3) -> Bool {
        // If we don't have a specific ID (e.g. some AoE attacks), never stop based on ID
        guard let id = targetID else { return false }
        
        let target = entityManager.allEntities.first(where: { $0.id == id })
        let isDead = target == nil || target?.state == .dead || (target?.health?.isDead ?? false)
        
        return isDead
    }

    // NEW Helper Function
    private func spawnProjectile(from: Entity_MK3, to: Entity_MK3, entityManager: EntityManager_MK3) {
        // 1. Create a generic projectile entity (Not on the grid!)
        let arrow = Entity_MK3(name: "Arrow", team: from.team, position: from.position)
        
        // 2. We use a placeholder screen pos (System will update this immediately)
        arrow.projectile = ProjectileComponent(
            targetID: to.id,
            screenPosition: .zero, // System will sync this to the attacker's node
            speed: 450.0,
            damage: from.combat?.attack ?? 1
        )
        
        entityManager.addEntity(arrow)
    }
}
