
/*
func performAttackTick() {
    for attacker in units.values {
        // Aura attacks happen every tick regardless of state
        if case .aura(let radius, let effect, let isTethered) = attacker.unit.attackPattern {
            executeAuraAttack(attacker: attacker, radius: radius, effectName: effect, isTethered: isTethered)
        }
        //check unit's state + cooldown before attacking
        guard attacker.unit.state == .attacking, attacker.unit.movementCooldown <= 0 else { continue }
        
        let totalAttackDuration = Double(attacker.unit.attackSpeed) * 0.3
        
        attacker.updateVisualState(forcedDuration: totalAttackDuration)
        
        //find attack target and execute attack
        if let target = findTargetedEnemy(for: attacker) {
            executeAttack(attacker: attacker, target: target)
            attacker.unit.movementCooldown = attacker.unit.attackSpeed
        }
    }
}
*/
