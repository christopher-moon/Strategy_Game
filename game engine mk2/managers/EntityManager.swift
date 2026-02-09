/*
 EntityManager_MK3.swift
*/

import Foundation

class EntityManager {
    //list of all entities
    var allEntities = Set<Entity>()
    
    //register a new entity
    func addEntity(_ entity: Entity) {
        allEntities.insert(entity)
    }
    
    //remove an entity
    func remove(_ entity: Entity) {
        allEntities.remove(entity)
    }
    
    //remove entities (visuals too) with 0>= health and entities specifically marked for death (state == dead)
    func cleanup(scene: GameScene_MK3) {
        
        //to be finished
 
    }
}

