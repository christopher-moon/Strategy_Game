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
        // Filter once and keep the list
        let deadIndices = allEntities.indices.filter { i in
            let e = allEntities[i]
            return (e.health?.isDead ?? false) || (e.lifecycle?.ticksRemaining ?? 1) <= 0 || e.state == .dead
        }
        
        for index in deadIndices.reversed() {
            let entity = allEntities[index]
            grid.removeEntity(at: entity.position, id: entity.id)
            if let node = scene.visualNodes[entity.id] {
                node.removeFromParent()
                scene.visualNodes.removeValue(forKey: entity.id)
            }
            allEntities.remove(at: index)
        }
    }
}
