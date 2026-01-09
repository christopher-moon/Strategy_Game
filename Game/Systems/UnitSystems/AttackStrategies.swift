import SpriteKit

protocol AttackStrategy {
    func execute(attacker: UnitNode, target: UnitNode, system: CombatSystem)
}

// MARK: - Melee
struct MeleeStrategy: AttackStrategy {
    func execute(attacker: UnitNode, target: UnitNode, system: CombatSystem) {
        attacker.playMeleeBump(towards: target.position)
        system.applyDamage(to: target.unit.id, amount: attacker.unit.attack)
    }
}

// MARK: - Projectile
struct ProjectileStrategy: AttackStrategy {
    let rounds: Int
    let name: String
    let smokeTrail: Bool
    
    func execute(attacker: UnitNode, target: UnitNode, system: CombatSystem) {
        let delay = SKAction.wait(forDuration: 0.15)
        
        let fireRound = SKAction.run { [weak attacker, weak system] in
            // Use a unique name like 'strongSystem' to stop shadowing ambiguity
            guard let strongAttacker = attacker,
                  let strongSystem = system else { return }
            
            strongSystem.fireProjectile(name: name, smokeTrail: smokeTrail, from: strongAttacker, to: target) {
                // Now we use the unique name inside the nested closure too
                strongSystem.applyDamage(to: target.unit.id, amount: strongAttacker.unit.attack)
            }
        }
        
        let sequence = SKAction.sequence([fireRound, delay])
        attacker.run(SKAction.repeat(sequence, count: rounds))
    }
}

// MARK: - Blast (AoE)
struct BlastStrategy: AttackStrategy {
    let radius: Int
    let projectileName: String?
    let smokeTrail: Bool
    let friendlyFire: Bool
    
    func execute(attacker: UnitNode, target: UnitNode, system: CombatSystem) {
        if let proj = projectileName {
            system.fireProjectile(name: proj, smokeTrail: smokeTrail, from: attacker, to: target) { [weak system, weak attacker] in
                // Using unique names here clears the 'Ghost Error'
                guard let strongSystem = system,
                      let strongAttacker = attacker else { return }
                
                strongSystem.executeAoE(
                    at: target.unit.position,
                    radius: radius,
                    damage: strongAttacker.unit.attack,
                    team: strongAttacker.unit.team,
                    friendlyFire: friendlyFire
                )
            }
        } else {
            // No closure here, so no issue
            system.executeAoE(at: target.unit.position, radius: radius, damage: attacker.unit.attack, team: attacker.unit.team, friendlyFire: friendlyFire)
        }
    }
}

// MARK: - Tether
struct TetherStrategy: AttackStrategy {
    let effectName: String
    
    func execute(attacker: UnitNode, target: UnitNode, system: CombatSystem) {
        attacker.showTether(to: target, effectName: effectName)
        system.applyDamage(to: target.unit.id, amount: attacker.unit.attack)
    }
}
