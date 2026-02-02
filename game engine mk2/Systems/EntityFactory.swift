/* EntityFactory.swift */
import GameplayKit
import SpriteKit

class EntityFactory {
    
    static func spawn(type: String, at position: TilePosition, team: Team, manager: EntityManager, mapManager: MapManager) -> Entity?{
        
        //0. get blueprint data from library
        guard let bp = Library.shared.templates[type] else { return nil }
        
        //1. create entity "skeleton"
        let entity = Entity(name: bp.name, team: team, startPos: position, startPoint: mapManager.calculateScreenPos(position))
        
        //2. inject the brain (create state machine)
        //baseline states (all entities can spawn and die)
        var states: [GKState] = [Spawning(entity: entity), Dead(entity: entity)]
        //add certain states based on Component Capabilities
        if bp.health != nil {
            states.append(Idle(entity: entity))
        }
        if bp.movement != nil {
            states.append(Moving(entity: entity))
        }
        if bp.combat != nil {
            states.append(Attacking(entity: entity))
        }
        //add states without a direct component, but specified by blueprint
        if bp.ai == "special" {
            //states.append(ExampleState(entity:entity))
        }
        //build state machine and add it to entity
        entity.stateMachine = GKStateMachine(states: states)
        //enter the machine (set starting state = spawning)
        entity.stateMachine.enter(Spawning.self)

        //4. attach components
        if let hData = bp.health {
            entity.addComponent(HealthComponent(
                hp: hData.hp,
                isStaticObstacle: hData.blocking
            ))
        }
        
        if let cData = bp.combat {
            entity.addComponent(CombatComponent(
                damage: cData.damage,
                range: cData.range,
                threatRange: cData.threatRange,
                attackSpeed: cData.attackSpeed
            ))
        }
        
        if let mData = bp.movement {

        }
        
        
        //register with entityManager
        manager.addEntity(entity)
        
        //register entity to tile container (map)
        mapManager.addEntity(entity.id, at: position)
        
        print("spawned \(type) type entity at \(position)")
        return entity
    }
}
