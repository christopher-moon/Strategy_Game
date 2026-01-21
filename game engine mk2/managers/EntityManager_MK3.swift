/*
 EntityManager_MK3.swift
*/
import Foundation

class EntityManager_MK3 {
    var allEntities: [Entity_MK3] = []
    
    func addEntity(_ entity: Entity_MK3) {
        allEntities.append(entity)
    }
    
    func cleanup(grid: Grid_MK3, scene: GameScene_MK3) {
        // We iterate backwards to safely remove from the array while looping
        for i in (0..<allEntities.count).reversed() {
            let e = allEntities[i]
            
            // The "Source of Truth" for removal
            let shouldRemove = (e.state == .dead) ||
                               (e.health?.isDead ?? false) ||
                               (e.lifecycle?.ticksRemaining ?? 1) <= 0
            
            if shouldRemove {
                // 1. Remove from Spatial Grid
                grid.removeEntity(at: e.position, id: e.id)
                
                // 2. Remove Visuals
                if let node = scene.visualNodes[e.id] {
                    node.removeFromParent()
                    scene.visualNodes.removeValue(forKey: e.id)
                }
                
                // 3. Remove from Master List
                allEntities.remove(at: i)
                
                print("EntityManager: Cleaned up \(e.id) (State: \(e.state))")
            }
        }
    }
}
