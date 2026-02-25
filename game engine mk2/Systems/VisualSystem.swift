import GameplayKit

class VisualSystem {
    func update(entityManager: EntityManager, mapManager: MapManager, deltaTime: TimeInterval) {
        
        for entity in entityManager.allEntities {
            guard let visualComp = entity.component(ofType: VisualComponent.self) else { continue }
            
            // 1. Always update labels, health, and state visuals
            visualComp.node.update(entity: entity, deltaTime: deltaTime)
            
            // 2. Sync position ONLY if the entity has a continuous movement component
            if let moveComp = entity.component(ofType: MovementComponent.self) {
                visualComp.node.position = CGPoint(x: CGFloat(moveComp.position.x), y: CGFloat(moveComp.position.y))
            }
        }
        
        //for tile in mapManager.grid {
            //tile.value.visualNode?.update(deltaTime: deltaTime)
        //}
    }
}
