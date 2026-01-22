/* EntityFactory_MK3.swift */
import SpriteKit

class EntityFactory_MK3 {
    
    //spawns a logical entity (no visuals)
    static func spawn(type: String, at pos: TilePosition, team: Team, patrol: [TilePosition]? = nil, grid: Grid_MK3, entityManager: EntityManager_MK3){
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
        
        if let pData = bp.projectile {
            entity.projectile = ProjectileComponent(
                targetID: pData.targetID,
                screenPosition: pData.screenPosition,
                speed: pData.speed,
                damage: pData.damage
            )
        }
        
        if let aiName = bp.aiType {
            entity.ai = resolveBrain(type: aiName)
        }
        
        if let patrolData = patrol {
            entity.patrolPoints = patrolData
        }
        
        
        // 5. Register with Grid & Manager
        entityManager.addEntity(entity)
        
        grid.addEntity(entity)
        
    }
    
    //resolve attack pattern
    static func resolvePattern(_ patternString: String) -> AttackPattern {
        // 1. Handle cases like "aoe:2"
        if patternString.contains("aoe:") {
            let parts = patternString.components(separatedBy: ":")
            if parts.count > 1, let radius = Int(parts[1]) {
                return .aoe(radius: radius)
            }
        }
        
        // 2. Handle cases like "projectile:Arrow"
        if patternString.contains("projectile:") {
            let parts = patternString.components(separatedBy: ":")
            if parts.count > 1 {
                let projectileName = parts[1]
                return .projectile(name: projectileName)
            }
        }
        
        // 3. Simple cases
        switch patternString.lowercased() {
        case "single", "singletarget":
            return .singleTarget
        default:
            print("Warning: Unknown pattern '\(patternString)', defaulting to singleTarget")
            return .singleTarget
        }
    }
    
    //resolve ai brain type
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
