import SpriteKit

extension UnitManager {
    // MARK: FIND CLOSEST ENEMY
    //Finds the closest enemy within the unit's threat range (Tile-Based)
    func findTargetedEnemy(for unit: UnitNode) -> UnitNode? {
        // check if current target is still valid
        if let currentID = unit.unit.currentTargetID,
            let existingTarget = units[currentID] {
                
            let dist = distance(from: unit.unit.position, to: existingTarget.unit.position)
                
            // If they are still in threat range and alive, keep them!
            if dist <= unit.unit.threatRange && existingTarget.unit.hp > 0 {
                return existingTarget
            }
        }
        // filter out non-enemies and enemies outside threat range
        let threatCandidates = units.values.filter { enemyUnit in
            guard enemyUnit.unit.team != unit.unit.team else { return false } // Must be an enemy
            let dist = distance(from: unit.unit.position, to: enemyUnit.unit.position)
            return dist <= unit.unit.threatRange // Must be within threat range
        }
        // find the closest one (shortest Manhattan Distance)
        let newTarget = threatCandidates.min { u1, u2 in
            let dist1 = distance(from: unit.unit.position, to: u1.unit.position)
            let dist2 = distance(from: unit.unit.position, to: u2.unit.position)
            return dist1 < dist2
        }
        //save new target
        unit.unit.currentTargetID = newTarget?.unit.id
        return newTarget
    }
    
    // MARK: APPLY DAMAGE
    //apply damage to a target unit
    func applyDamage(to targetID: UUID, amount: Int) {
        guard let node = units[targetID] else { return }
        //apply damage to unit and update health bar
        node.unit.hp -= amount
        node.updateHealthBar()
        
        //spawnhit effect
        let hit = EffectNode(effectName: "impact", position: node.position, tileSize: scene!.tileSize)
        node.parent?.addChild(hit)
        
        //check if unit was defeated
        if node.unit.hp <= 0 {
            handleUnitDeath(node)
        } else {
            node.playHitFlinch()
        }
    }
    
    //MARK: HANDLE UNIT DEATH
    //delete the logical unit and free the occupied tile
    private func handleUnitDeath(_ node: UnitNode) {
        let id = node.unit.id
        //delete logical unit immediately
        units.removeValue(forKey: id)
        //call visual death effect
        node.die{}
        //free tile
        gridManager.clearOccupancy(at: node.unit.position)
        //occupiedTiles.remove(node.unit.position)
        // Notify other units to stop targeting this position
        for other in units.values where other.unit.currentGoal == node.unit.position {
            other.unit.currentGoal = nil
            other.unit.state = .idle
            other.unit.needsRepath = true
            other.updateVisualState()
        }
    }
    
    //MARK: ATTACK TICK
    //handle attack logic for all units in "attacking" state
    func performAttackTick() {
        for attacker in units.values {
            // Aura attacks happen every tick regardless of state
            if case .aura(let radius, let effect, let isTethered) = attacker.unit.attackPattern {
                executeAuraAttack(attacker: attacker, radius: radius, effectName: effect, isTethered: isTethered)
            }
            
            guard attacker.unit.state == .attacking else { continue }

            // 1. VALIDATION: Is the target still there and in range?
            // If the target died or moved, reset the wind-up.
            guard let target = findTargetedEnemy(for: attacker) else {
                attacker.unit.movementCooldown = 0 // Reset cooldown so they can react immediately to new targets
                attacker.unit.state = .idle
                attacker.updateVisualState()
                continue
            }

            // 2. START THE WIND-UP: If cooldown is 0, start the animation and set the timer
            if attacker.unit.movementCooldown == 0 {
                attacker.unit.movementCooldown = attacker.unit.attackSpeed
                        
                let totalDuration = Double(attacker.unit.attackSpeed) * 0.3
                attacker.updateVisualState(forcedDuration: totalDuration)
                attacker.updateFacing(to: target.unit.position.col)
                        
                // Note: We do NOT call executeAttack here.
                continue
            }

            // 3. TRIGGER THE HIT: If cooldown is 1, it will be 0 next tick.
            // This is the end of the wind-up.
            if attacker.unit.movementCooldown == 1 {
                executeAttack(attacker: attacker, target: target)
                // After executeAttack, the cooldown will naturally hit 0 in the next MoveTick,
                // allowing the cycle to repeat.
            }
        }
    }
    
    //MARK: EXECUTE ATTACK
    //execute unit's specific attack pattern
    private func executeAttack(attacker: UnitNode, target: UnitNode) {
        //face the attacker
        //attacker.updateFacing(to: target.unit.position.col)
        let pattern = attacker.unit.attackPattern
        switch pattern {
        case .melee:
            attacker.playMeleeBump(towards: target.position)
            applyDamage(to: target.unit.id, amount: attacker.unit.attack)
                
        case .projectile(let rounds, let projName, let smokeTrail):
            let delay = SKAction.wait(forDuration: 0.15) // Time between rounds
                
            let fireRound = SKAction.run { [weak self] in
                self?.fireProjectile(name: projName, smokeTrail: smokeTrail, from: attacker, to: target) {
                    self?.applyDamage(to: target.unit.id, amount: attacker.unit.attack)
                }
            }
                
            // Create a sequence: [Fire, Wait, Fire, Wait...]
            let sequence = SKAction.repeat(SKAction.sequence([fireRound, delay]), count: rounds)
            attacker.run(sequence)

        case .blast(let radius, let projName, let smokeTrail, let ff):
            if let proj = projName {
                fireProjectile(name: proj, smokeTrail: smokeTrail, from: attacker, to: target) { [weak self] in
                    self?.executeAoE(at: target.unit.position, radius: radius, damage: attacker.unit.attack, team: attacker.unit.team, friendlyFire: ff)
                }
            } else {
                executeAoE(at: target.unit.position, radius: radius, damage: attacker.unit.attack, team: attacker.unit.team, friendlyFire: ff)
            }
                
        case .tether(let effect):
            attacker.showTether(to: target, effectName: effect)
            applyDamage(to: target.unit.id, amount: attacker.unit.attack)
                
        default: break
        }
    }

    //MARK: EXECUTE AOE
    //aoe attack function
    private func executeAoE(at pos: TilePosition, radius: Int, damage: Int, team: Team, friendlyFire: Bool) {
        // Find all tiles in radius
        for r in (pos.row - radius)...(pos.row + radius) {
            for c in (pos.col - radius)...(pos.col + radius) {
                if let targetNode = unitAt(TilePosition(row: r, col: c)), targetNode.unit.team != team {
                    if friendlyFire || targetNode.unit.team != team {
                        applyDamage(to: targetNode.unit.id, amount: damage)
                    }
                }
            }
        }
        // Visual for explosion
        //scene?.playExplosionEffect(at: pos, radius: radius)
    }
    
    //MARK: FIND ALL ENEMIES IN RANGE
    // Helper to find all enemies in a square radius
    private func enemiesInRange(at pos: TilePosition, radius: Int, team: Team) -> [UnitNode] {
        var targets: [UnitNode] = []
        for r in (pos.row - radius)...(pos.row + radius) {
            for c in (pos.col - radius)...(pos.col + radius) {
                if let target = unitAt(TilePosition(row: r, col: c)), target.unit.team != team {
                    targets.append(target)
                }
            }
        }
        return targets
    }
    
    //MARK: EXECUTE AURA ATTACK
    //aura attack function
    private func executeAuraAttack(attacker: UnitNode, radius: Int, effectName: String, isTethered: Bool) {
        let targets = enemiesInRange(at: attacker.unit.position, radius: radius, team: attacker.unit.team)
            
        for target in targets {
            // 1. Apply Damage (Centralized)
            applyDamage(to: target.unit.id, amount: attacker.unit.attack)
                
            // 2. Visual Tethers
            if isTethered {
                attacker.showTether(to: target, effectName: effectName)
            }
        }
            
        // Optional: Play a general "aura pulse" effect around the attacker
        if !targets.isEmpty {
            //scene?.playAuraPulse(at: attacker.unit.position, radius: radius)
        }
    }
    
    //MARK: FIRE PROJECTILE
    //create + fire projectilenode for ranged attacks
    private func fireProjectile(name: String, smokeTrail: Bool, from: UnitNode, to: UnitNode, completion: @escaping () -> Void) {
        let projectile = ProjectileNode(projectileName: name, smokeTrail: true, tileSize: scene!.tileSize)
        projectile.position = from.position
        from.parent?.addChild(projectile)
        projectile.launch(towards: to, completion: completion)
    }
    
}
