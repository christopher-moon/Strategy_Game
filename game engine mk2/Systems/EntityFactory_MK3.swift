/* EntityFactory_MK3.swift */
import SpriteKit

class EntityFactory_MK3 {
    
    static func spawn(type: String, at pos: TilePosition, team: Team, patrol: [TilePosition]? = nil, grid: Grid_MK3, entityManager: EntityManager_MK3, scene: GameScene_MK3){
        // 1. Get the Blueprint
        guard let bp = Library_MK3.shared.templates[type] else { return }
        
        // 2. Create the "Skeleton"
        let entity = Entity_MK3(name: bp.name, team: team, position: pos)
        
        // 3. Configure Physics
        entity.movementCost = bp.movementCost ?? 20
        entity.isImpassable = bp.isImpassable ?? true
        entity.obeysReservation = bp.obeysReservation ?? false
        
        // 4. Attach Components (The Assembly Line)
        if let hData = bp.health {
            entity.health = HealthComponent(hp: hData.hp)
        }
        
        if let mData = bp.movement {
            entity.movement = MovementComponent(speed: mData.speed, isFlying: mData.isFlying ?? false, movementType: mData.movementType)
        }
        
        if let cData = bp.combat {
            entity.combat = CombatComponent(
                attack: cData.attack,
                attackSpeed: cData.attackSpeed,
                range: cData.range,
                threatRange: cData.threatRange ?? 0,
                pattern: resolvePattern(cData.pattern),
                selfDestruct: cData.selfDestruct ?? false
            )
        }
        
        if let aiName = bp.aiType {
            entity.ai = resolveBrain(type: aiName)
        }
        
        if let patrolData = patrol {
            entity.patrolPoints = patrolData
        }
        
        // 5. Link Visuals
        let visualNode = EntityNode_MK3(entity: entity, size: scene.mapManager.tileSize)
        visualNode.position = scene.mapManager.calculateScreenPos(pos)
        scene.addChild(visualNode)
        scene.visualNodes[entity.id] = visualNode
        
        // 6. Register with Grid & Manager
        entityManager.addEntity(entity)
        
        grid.addEntity(entity)
        
    }
    
    private static func resolvePattern(_ str: String) -> AttackPattern {
        switch str {
        case "aoe": return .aoe(radius: 1)
        default: return .singleTarget
        }
    }
    
    private static func resolveBrain(type: String) -> AIBrain_MK3 {
        // Your existing brain resolution logic here...
        switch type {
        case "attacker":
            return AttackerBrain()
        case "defender":
            return DefenderBrain()
        case "movingHazard":
            return MovingHazardBrain()
        case "mine":
            return MineBrain()
        default:
            return AttackerBrain()
        }
    }
    
}
