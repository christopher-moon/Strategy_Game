import GameplayKit
import SpriteKit

class EntityFactory {
    
    //MARK: Spawn Entity
    static func spawn(type: String, at position: TilePosition, team: Team, mapManager: MapManager, entityManager: EntityManager) -> Entity? {
        
        guard let bp = Library.shared.templates[type] else { return nil }
        
        // 1. Create Entity Data
        let entity = Entity(name: bp.name, team: team, startPos: position, timer: bp.timer)
        // convert tile position to initial screen position
        let startPoint = mapManager.calculateScreenPos(position)
        
        // 2. Add Components
        let visualNode = EntityNode(entity: entity, size: mapManager.tileSize, position: startPoint)
        entity.addComponent(VisualComponent(node: visualNode))
        // Add to Scene Graph
        mapManager.worldNode.addChild(visualNode)

        if let mData = bp.movement {
            entity.addComponent(MovementComponent(speed: mData.speed, radius: mData.radius, mass: mData.mass, physics: mData.physics, initialPosition: startPoint))
        }
        if let hData = bp.health {
            entity.addComponent(HealthComponent(hp: hData.hp, isStaticObstacle: hData.blocking))
        }
        if let cData = bp.combat {
            entity.addComponent(CombatComponent(damage: cData.damage, range: cData.range, threatRange: cData.threatRange, attackSpeed: cData.attackSpeed))
        }
        if let pData = bp.movementCost {
            entity.addComponent(MovementCostComponent(movementCost: pData.movementCost))
        }
        
        // 3. State Machine
        
        //default states (all entities have these)
        var states: [GKState] = [Spawning(entity: entity, entityManager: entityManager, mapManager: mapManager), Dead(entity: entity, entityManager: entityManager, mapManager: mapManager)]
        
        
            switch bp.ai {
            case .aggressive:
                states.append(Idle(entity: entity, entityManager: entityManager, mapManager: mapManager))
                states.append(Moving(entity: entity, entityManager: entityManager, mapManager: mapManager))
                states.append(Attacking(entity: entity, entityManager: entityManager, mapManager: mapManager))
            case .objective:
                states.append(Idle(entity: entity, entityManager: entityManager, mapManager: mapManager))
                states.append(Moving(entity: entity, entityManager: entityManager, mapManager: mapManager))
                states.append(Attacking(entity: entity, entityManager: entityManager, mapManager: mapManager))
            case .passive:
                states.append(Idle(entity: entity, entityManager: entityManager, mapManager: mapManager))
                states.append(Moving(entity: entity, entityManager: entityManager, mapManager: mapManager))
                states.append(Attacking(entity: entity, entityManager: entityManager, mapManager: mapManager))
            }
        
        /*
        //health component: idle state
        if bp.health != nil { states.append(Idle(entity: entity, entityManager: entityManager, mapManager: mapManager)) }
        //movement component: moving state
        if bp.movement != nil { states.append(Moving(entity: entity, entityManager: entityManager, mapManager: mapManager)) }
        //combat component: attacking state
        if bp.combat != nil { states.append(Attacking(entity: entity, entityManager: entityManager, mapManager: mapManager)) }
        */
        
        //set state machine
        entity.stateMachine = GKStateMachine(states: states)
        //start in spawning state
        entity.stateMachine.enter(Spawning.self)
        
        // 4. Register with map and entity managers
        mapManager.addEntity(entity.id, at: position, entityManager: entityManager)
        entityManager.addEntity(entity)
        
        return entity
    }
}
