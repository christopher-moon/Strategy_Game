import SpriteKit
import Foundation

struct ObjectiveRunnerAI: UnitAIBrain {
    let arrivalThreshold: Int = 3

    func determineAction(for unit: UnitNode, manager: UnitManager) -> TilePosition? {
        // UPDATED: Access movement system for objective logic
        guard let objectiveTile = manager.movement.findNearestObjectiveTile(from: unit.unit.position) else {
            unit.unit.state = .idle
            unit.unit.isMissionLocked = false
            return nil
        }
        
        let distance = manager.distance(from: unit.unit.position, to: objectiveTile)

        // 1. MISSION LOCK LOGIC
        if distance > arrivalThreshold {
            unit.unit.isMissionLocked = true
        } else if distance == 0 {
            unit.unit.isMissionLocked = false
        }

        if unit.unit.isMissionLocked {
            // Attempt to move (Using UnitAIBrain extension which calls manager.movement)
            if let nextStep = moveToward(target: objectiveTile, for: unit, manager: manager) {
                
                // CHECK FOR BLOCKERS
                if let blocker = manager.unitAt(nextStep) {
                    if blocker.unit.team != unit.unit.team {
                        return attackTarget(blocker, for: unit, manager: manager)
                    } else {
                        // Friendly block
                        unit.unit.state = .idle
                        return nil
                    }
                }
                return nextStep
                
            } else {
                // FALLBACK: Path blocked
                // UPDATED: Access combat system
                if let targetEnemy = manager.combat.findTargetedEnemy(for: unit) {
                    unit.unit.needsRepath = true
                    return attackTarget(targetEnemy, for: unit, manager: manager)
                }
            }
        }

        // 2. COMBAT ZONE LOGIC
        // UPDATED: Access combat system
        if let targetEnemy = manager.combat.findTargetedEnemy(for: unit) {
            return attackTarget(targetEnemy, for: unit, manager: manager)
        }
        
        return moveToward(target: objectiveTile, for: unit, manager: manager)
    }
    
    // Note: If you need initiatePush logic, rely on the MovementSystem
    // For now, this AI seems to just return TilePositions, so pushing (swapping)
    // might need to be a custom function in MovementSystem if you want to keep it.
}
