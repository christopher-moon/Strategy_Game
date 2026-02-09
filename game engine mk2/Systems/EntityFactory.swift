import GameplayKit
import SpriteKit

class EntityFactory {
    
    static func spawn(type: String, at position: TilePosition, team: Team, mapManager: MapManager) -> Entity? {
        
        guard let bp = Library.shared.templates[type] else { return nil }
        
        // 1. Create Entity Data
        let entity = Entity(name: bp.name, team: team, startPos: position)
        
        // Calculate starting screen position
        let startPoint = mapManager.calculateScreenPos(position)
        
        // 2. VISUALS: Create Node & VisualComponent
        let visualNode = EntityNode(entity: entity, size: mapManager.tileSize)
        
        // Important: Set the initial visual position immediately
        visualNode.position = startPoint
        
        let visualComponent = VisualComponent(node: visualNode)
        entity.addComponent(visualComponent)
                
        // Add to Scene Graph
        mapManager.worldNode.addChild(visualNode)

        // 3. MOVEMENT: Create Agent & Link to Visuals
        if let _ = bp.movement { // If blueprint has movement data
            let moveComp = MovementComponent()
            moveComp.mapManager = mapManager // Inject the dependency here
            
            // A: Set Agent's internal position to match the screen position
            // GKAgent2D uses vector_float2, not CGPoint
            moveComp.position = vector_float2(Float(startPoint.x), Float(startPoint.y))
            
            moveComp.targetPosition = nil
                        
            // B: THE MAGIC LINK
            // This tells GameplayKit: "When this Agent moves, move the VisualComponent's node too."
            moveComp.delegate = visualComponent
                        
            entity.addComponent(moveComp)
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
        
        return entity
    }
}
