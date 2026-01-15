/*
 EntityFactory_MK2.swift
 handles spawing entities and links them to screen
*/
import SpriteKit

class EntityFactory_MK2 {
    
    private static func createLogic(type: String, pos: TilePosition, team: Team) -> Entity_MK2? {
        if Library_MK2.shared.units[type] != nil {
            return Unit_MK2(typeName: type, startPos: pos, team: team)
        } else if Library_MK2.shared.obstacles[type] != nil {
            // Ensure Obstacle_MK2 takes 'team' in its init!
            return Obstacle_MK2(typeName: type, startPos: pos, team: team)
        }
        return nil
    }
    
    static func spawn(type: String, at pos: TilePosition, team: Team, grid: Grid_MK2, entityManager: EntityManager_MK2, scene: GameScene_MK2) {
        guard let entity = createLogic(type: type, pos: pos, team: team) else { return }
        
        let sprite = createSprite(for: entity, team: team, size: scene.mapManager.tileSize)
        sprite.position = scene.mapManager.calculateScreenPos(pos)
        
        scene.addChild(sprite)
        scene.visualNodes[entity.id] = sprite
        entityManager.addEntity(entity)
        
        // --- NEW LAYERED REGISTRATION ---
        if let unit = entity as? Unit_MK2 {
            // Units go into the dynamic movement layer
            let occupant = grid.createOccupant(for: unit)
            grid.moveUnit(unit, from: pos, to: pos)
        } else {
            // Obstacles/Mines/Laser Gates go into the static hazard layer
            grid.registerStaticHazard(entity: entity)
        }
    }

    private static func createSprite(for entity: Entity_MK2, team: Team, size: CGFloat) -> SKSpriteNode {
        let color: UIColor = (team == .enemy ? .red : (team == .player ? .blue : .lightGray))
        return SKSpriteNode(color: color, size: CGSize(width: size * 0.8, height: size * 0.8))
    }
}
