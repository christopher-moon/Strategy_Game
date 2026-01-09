import SpriteKit
import Foundation

// 2. Concrete AI Implementations
struct BasicCombatAI: UnitAIBrain {

    func determineAction(for unit: UnitNode, manager: UnitManager) -> TilePosition? {
        // Priority 1: Engage Threats
        if let targetEnemy = manager.findTargetedEnemy(for: unit) {
            //if unit.unit.state != .attacking {
                //let alert = EffectNode(effectName: "alert", position: unit.position, tileSize: unit.baseSize)
                //unit.parent?.addChild(alert)
            //}
            return attackTarget(targetEnemy, for: unit, manager: manager)
        }
        // Priority 2: Move to Objective (Handles Arrival/Idle internally)
        return moveTowardNearestObjective(for: unit, manager: manager)
    }
}
