//combat logic
import SpriteKit

class CombatSystem {
    unowned let manager: UnitManager
    
    init(manager: UnitManager) {
        self.manager = manager
    }
    
    // MARK: - Main Combat Loop
    func performAttackTick() {
        for attacker in manager.units.values {
            // Aura is unique (happens every tick), so we keep it separate or make it a "PassiveStrategy" later
            if case .aura(let radius, let effect, let isTethered) = attacker.unit.attackPattern {
                executeAuraAttack(attacker: attacker, radius: radius, effectName: effect, isTethered: isTethered)
            }
            
            guard attacker.unit.state == .attacking else { continue }

            // 1. Validation (is target still there and in range)
            guard let target = findTargetedEnemy(for: attacker) else {
                attacker.unit.movementCooldown = 0
                attacker.unit.state = .idle
                attacker.updateVisualState()
                continue
            }
            
            // check distance, make sure not out of range
            let currentDist = manager.distance(from: attacker.unit.position, to: target.unit.position)
            if currentDist > attacker.unit.range {
                // The target is too far! Stop attacking and try to move instead.
                attacker.unit.state = .idle
                attacker.updateVisualState()
                continue
            }

            // 2. Wind-up
            if attacker.unit.movementCooldown == 0 {
                attacker.unit.movementCooldown = attacker.unit.attackSpeed
                let totalDuration = Double(attacker.unit.attackSpeed) * 0.3
                attacker.updateVisualState(forcedDuration: totalDuration)
                attacker.updateFacing(to: target.unit.position.col)
                
                if attacker.unit.attackSpeed > 1 { continue }
            }

            // 3. Trigger Hit
            if attacker.unit.movementCooldown == 1 {
                executeAttack(attacker: attacker, target: target)
            }
        }
    }
    
    // MARK: - Execute Attack (Refactored)
    private func executeAttack(attacker: UnitNode, target: UnitNode) {
        // Factory logic: Convert Enum Data -> Strategy Object
        let strategy: AttackStrategy?
        
        switch attacker.unit.attackPattern {
        case .melee:
            strategy = MeleeStrategy()
        case .projectile(let rounds, let name, let smoke):
            strategy = ProjectileStrategy(rounds: rounds, name: name, smokeTrail: smoke)
        case .blast(let radius, let proj, let smoke, let ff):
            strategy = BlastStrategy(radius: radius, projectileName: proj, smokeTrail: smoke, friendlyFire: ff)
        case .tether(let effect):
            strategy = TetherStrategy(effectName: effect)
        default:
            strategy = nil
        }
        
        strategy?.execute(attacker: attacker, target: target, system: self)
    }
    
    // MARK: - Targeting & Damage (Public API for Strategies)
    
    func findTargetedEnemy(for unit: UnitNode) -> UnitNode? {
        if let currentID = unit.unit.currentTargetID,
           let existingTarget = manager.units[currentID] {
            let dist = manager.distance(from: unit.unit.position, to: existingTarget.unit.position)
            if dist <= unit.unit.threatRange && existingTarget.unit.hp > 0 {
                return existingTarget
            }
        }
        
        let threatCandidates = manager.units.values.filter { enemyUnit in
            guard enemyUnit.unit.team != unit.unit.team else { return false }
            let dist = manager.distance(from: unit.unit.position, to: enemyUnit.unit.position)
            return dist <= unit.unit.threatRange
        }
        
        let newTarget = threatCandidates.min { u1, u2 in
            let dist1 = manager.distance(from: unit.unit.position, to: u1.unit.position)
            let dist2 = manager.distance(from: unit.unit.position, to: u2.unit.position)
            return dist1 < dist2
        }
        
        unit.unit.currentTargetID = newTarget?.unit.id
        return newTarget
    }
    
    func applyDamage(to targetID: UUID, amount: Int) {
        guard let node = manager.units[targetID] else { return }
        
        node.unit.hp -= amount
        node.updateHealthBar()
        
        let hit = EffectNode(effectName: "impact", position: node.position, tileSize: manager.scene!.tileSize)
        node.parent?.addChild(hit)
        
        if node.unit.hp <= 0 {
            handleUnitDeath(node)
        } else {
            node.playHitFlinch()
        }
    }
    
    private func handleUnitDeath(_ node: UnitNode) {
        manager.removeUnit(node)
    }
    
    // MARK: - Helpers for Strategies
    
    func executeAoE(at pos: TilePosition, radius: Int, damage: Int, team: Team, friendlyFire: Bool) {
        for r in (pos.row - radius)...(pos.row + radius) {
            for c in (pos.col - radius)...(pos.col + radius) {
                if let targetNode = manager.unitAt(TilePosition(row: r, col: c)) {
                    if friendlyFire || targetNode.unit.team != team {
                        applyDamage(to: targetNode.unit.id, amount: damage)
                    }
                }
            }
        }
    }
    
    // Keep Aura internal as it's handled in the tick loop
    private func executeAuraAttack(attacker: UnitNode, radius: Int, effectName: String, isTethered: Bool) {
        let targets = enemiesInRange(at: attacker.unit.position, radius: radius, team: attacker.unit.team)
        for target in targets {
            applyDamage(to: target.unit.id, amount: attacker.unit.attack)
            if isTethered {
                attacker.showTether(to: target, effectName: effectName)
            }
        }
    }
    
    private func enemiesInRange(at pos: TilePosition, radius: Int, team: Team) -> [UnitNode] {
        var targets: [UnitNode] = []
        for r in (pos.row - radius)...(pos.row + radius) {
            for c in (pos.col - radius)...(pos.col + radius) {
                if let target = manager.unitAt(TilePosition(row: r, col: c)), target.unit.team != team {
                    targets.append(target)
                }
            }
        }
        return targets
    }
    
    func fireProjectile(name: String, smokeTrail: Bool, from: UnitNode, to: UnitNode, completion: @escaping () -> Void) {
        guard let scene = manager.scene else { return }
        let projectile = ProjectileNode(projectileName: name, smokeTrail: smokeTrail, tileSize: scene.tileSize)
        projectile.position = from.position
        from.parent?.addChild(projectile)
        projectile.launch(towards: to, completion: completion)
    }
}
