/*
 HazardSystem_MK2.swift
 Handles interactions between Units and Obstacles
*/
/*
import Foundation

class HazardSystem_MK2 {
    func update(entityManager: EntityManager_MK2, grid: Grid_MK2) {
        for entity in entityManager.allEntities {
            
            // SCENARIO 1: Entity is a Unit. Check if it's standing on any Hazards.
            if let unit = entity as? Unit_MK2 {
                if let hazards = grid.getHazards(at: unit.position) {
                    for hazardData in hazards {
                        if hazardData.team != unit.team {
                            if let hazardEntity = entityManager.allEntities.first(where: { $0.id == hazardData.id }) {
                                trigger(hazard: hazardEntity, victim: unit)
                            }
                        }
                    }
                }
            }
            
            // SCENARIO 2: Entity is a Moving Hazard. Check if it's standing on any Units.
            if let obstacle = entity as? Obstacle_MK2 {
                if let occupant = grid.getUnit(at: obstacle.position) {
                    if let unit = entityManager.allEntities.first(where: { $0.id == occupant.id }) as? Unit_MK2 {
                        if unit.team != obstacle.team {
                            trigger(hazard: obstacle, victim: unit)
                        }
                    }
                }
            }
        }
    }
    
    private func trigger(hazard: Entity_MK2, victim: Unit_MK2) {
        victim.takeDamage(hazard.attack)
        if hazard.movementCost > 100 {
            hazard.hp = 0 // Mine explodes
        }
    }
}
*/
