import Foundation

class AISystem {
    func update(entityManager: EntityManager, deltaTime: TimeInterval) {
        
        //for all entities
        for entity in entityManager.allEntities {
            
            //"pump" state machine
            entity.stateMachine.update(deltaTime: deltaTime)
            
        }
    }
}
