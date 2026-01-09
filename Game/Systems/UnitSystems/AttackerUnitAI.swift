import SpriteKit
import Foundation

struct BasicCombatAI: UnitAIBrain {

    func determineAction(for unit: UnitNode, manager: UnitManager) -> TilePosition? {
        // Priority 1: Engage Threats
        // UPDATED: Call into CombatSystem
        if let targetEnemy = manager.combat.findTargetedEnemy(for: unit) {
            return attackTarget(targetEnemy, for: unit, manager: manager)
        }
        // Priority 2: Move to Objective
        return moveTowardNearestObjective(for: unit, manager: manager)
    }
}
