import Foundation
import SpriteKit

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
        //entity must be removed from map manager, entity list, and system manager
 
    }
}

//who and where
extension EntityManager {
    //return the entity associated with an id
    //func getEntity(id: UUID) -> Entity {
        
    //}
    
    
    // Find the nearest entity of a specific team
    func findNearestEntity(from origin: vector_float2, onTeam team: Team, ignoring: UUID? = nil) -> Entity? {
        var nearest: Entity? = nil
        var nearestDist = Float.infinity
        
        for entity in allEntities {
            if entity.team != team || entity.id == ignoring { continue }
            guard let moveComp = entity.component(ofType: MovementComponent.self) else { continue }
            
            let dist = simd_distance(origin, moveComp.position)
            if dist < nearestDist {
                nearestDist = dist
                nearest = entity
            }
        }
        return nearest
    }
    
    // Get all entities within a certain radius (useful for AoE or Saws)
    func findEntities(inRange range: Float, from origin: vector_float2, onTeam team: Team? = nil) -> [Entity] {
        return allEntities.filter { entity in
            if let team = team, entity.team != team { return false }
            guard let moveComp = entity.component(ofType: MovementComponent.self) else { return false }
            return simd_distance(origin, moveComp.position) <= range
        }
    }
}

