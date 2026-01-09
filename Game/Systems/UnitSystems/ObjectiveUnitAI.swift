import SpriteKit
import Foundation


struct ObjectiveRunnerAI: UnitAIBrain {
    let arrivalThreshold: Int = 3

    func determineAction(for unit: UnitNode, manager: UnitManager) -> TilePosition? {
        guard let objectiveTile = manager.scene?.findNearestObjective(from: unit.unit.position, unitManager: manager) else {
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
            // Attempt to move
            if let nextStep = moveToward(target: objectiveTile, for: unit, manager: manager) {
                
                // CHECK FOR BLOCKERS (Same logic as before)
                if let blocker = manager.unitAt(nextStep) {
                    if blocker.unit.team != unit.unit.team {
                        return attackTarget(blocker, for: unit, manager: manager)
                    } else {
                        // Friendly block: just wait (since we aren't swapping)
                        unit.unit.state = .idle
                        return nil
                    }
                }
                return nextStep
                
            } else {
                // --- THE FALLBACK LOGIC ---
                // moveToward returned nil (Path is physically blocked by walls/enemies)
                // We search for the nearest enemy to clear a path.
                if let targetEnemy = manager.findTargetedEnemy(for: unit) {
                    unit.unit.needsRepath = true
                    return attackTarget(targetEnemy, for: unit, manager: manager)
                }
            }
        }

        // 2. COMBAT ZONE LOGIC (When not mission locked or fallback failed)
        if let targetEnemy = manager.findTargetedEnemy(for: unit) {
            return attackTarget(targetEnemy, for: unit, manager: manager)
        }
        
        return moveToward(target: objectiveTile, for: unit, manager: manager)
    }
    
    private func initiatePush(actor: UnitNode, target: UnitNode, manager: UnitManager) -> TilePosition? {
        // Only push if the friend isn't also mission-locked (prevents infinite swapping)
        guard !target.unit.isMissionLocked else { return nil }
        
        let actorPos = actor.unit.position
        let targetPos = target.unit.position
        
        // Logically swap their positions
        actor.unit.position = targetPos
        target.unit.position = actorPos
        
        // Visual updates
        manager.moveUnit(actor, to: manager.scene!.tileAt(position: targetPos)!, duration: 0.2)
        manager.moveUnit(target, to: manager.scene!.tileAt(position: actorPos)!, duration: 0.2)
        
        return targetPos // Return the new position so the AI tick knows where we moved
    }
}
