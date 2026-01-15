/*
 EntityManager_MK2.swift
 handles "life" and "death" of entities
*/
import Foundation

class EntityManager_MK2 {
    var allEntities: [Entity_MK2] = []
    
    func addEntity(_ entity: Entity_MK2) {
        allEntities.append(entity)
    }
    
    func cleanup(grid: Grid_MK2, scene: GameScene_MK2) {
        let deadEntities = allEntities.filter { $0.hp <= 0 }
            
        for entity in deadEntities {
            if entity.movementCost == 200{
                scene.shakeCamera()
            }
            // This now clears both Unit and Static layers for that position
            grid.removeOccupant(at: entity.position, id: entity.id)
            
            // visual sprite removal
            if let sprite = scene.visualNodes[entity.id] {
                sprite.removeFromParent() // Physical removal from the scene
                scene.visualNodes.removeValue(forKey: entity.id) // Clear from dictionary
                print("Visual node for \(entity.id) removed.")
            }
            
            print("Entity \(entity.id) cleaned up.")
        }
            
        allEntities.removeAll { $0.hp <= 0 }
    }
}
