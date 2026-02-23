import GameplayKit
import SpriteKit

class EntityFactory {
    
    static func spawn(type: String, at position: TilePosition, team: Team, mapManager: MapManager, entityManager: EntityManager) -> Entity? {
        
        guard let bp = Library.shared.templates[type] else { return nil }
        
        // 1. Create Entity Data
        let entity = Entity(name: bp.name, team: team, startPos: position)
        
        // Calculate starting screen position
        let startPoint = mapManager.calculateScreenPos(position)
        
        // 2. VISUALS: Create Node & VisualComponent
        let visualNode = EntityNode(entity: entity, size: mapManager.tileSize)
        
        // Important: Set the initial visual position immediately
        visualNode.position = startPoint
        
        entity.addComponent(VisualComponent(node: visualNode))
                
        // Add to Scene Graph
        mapManager.worldNode.addChild(visualNode)

        // 3. MOVEMENT: Create Agent & Link to Visuals
        if let mData = bp.movement {
            entity.addComponent(MovementComponent(speed: mData.speed, radius: mData.radius, mass: mData.mass, physics: mData.physics, initialPosition: startPoint))
        }
        
        // 4. Other Components
        if let hData = bp.health {
            entity.addComponent(HealthComponent(hp: hData.hp, isStaticObstacle: hData.blocking))
        }
        
        if let cData = bp.combat {
            entity.addComponent(CombatComponent(damage: cData.damage, range: cData.range, threatRange: cData.threatRange, attackSpeed: cData.attackSpeed))
        }
        
        // 5. State Machine
        var states: [GKState] = [Spawning(entity: entity), Dead(entity: entity)]
        if bp.health != nil { states.append(Idle(entity: entity)) }
        if bp.movement != nil { states.append(Moving(entity: entity)) }
        if bp.combat != nil { states.append(Attacking(entity: entity)) }
        
        entity.stateMachine = GKStateMachine(states: states)
        entity.stateMachine.enter(Spawning.self)
        
        // 6. Register
        mapManager.addEntity(entity.id, at: position)
        entityManager.addEntity(entity)
        
        return entity
    }
}
