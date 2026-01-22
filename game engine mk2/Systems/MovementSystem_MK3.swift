/* MovementSystem_MK3.swift */
import Foundation

class MovementSystem_MK3 {
    private var reservedTiles: [TilePosition: UUID] = [:]

    func update(entityManager: EntityManager_MK3, grid: Grid_MK3) {
        reservedTiles.removeAll()
        
        //reserve current positions for all "unit type" (obeysReservation) entities
        for entity in entityManager.allEntities where entity.obeysReservation == true {
            reservedTiles[entity.position] = entity.id
        }

        //process movers (state == .moving)
        for entity in entityManager.allEntities {
            
            //check if entity is a projectile
            if let projectile = entity.projectile {
                if let target = entityManager.allEntities.first(where: { $0.id == projectile.targetID }) {
                    executeProjectileTick(entity: entity, proj: projectile, target: target, grid: grid)
                } else {
                    //target disappeared, delete projectile
                    entity.state = .dead
                }
                continue
            }
            
            //check if entity has a movement component and state == .moving
            guard let movement = entity.movement, entity.state == .moving else { continue }
            
            //handle movement speed
            movement.internalTickCounter += 1
            if movement.internalTickCounter < movement.speed { continue }
            
            //ensure the entity has a valid path to move along
            guard let nextStep = movement.currentPath.first else { continue }
            
            //if the entity is a simple mover (linear movement), it ignores collision physics
            if movement.movementType == .simple {
                executeMove(entity: entity, moveComp: movement, to: nextStep, grid: grid)
                movement.internalTickCounter = 0
                continue
            }
            
            // --- SMART PHYSICS CHECKS (Standard Units) ---
            
            //check if there is a wall tile or out of bounds area blocking movement
            if grid.isImpassable(at: nextStep) {
                movement.internalTickCounter = movement.speed
                continue
            }
            
            //check if there is a destructable obstacle (entity with isImpassible == true) blocking movement
            if let occupants = grid.getOccupants(at: nextStep) {
                //flyers can bypass obstacles
                if occupants.contains(where: { $0.isImpassable }) && !movement.isFlying {
                    movement.internalTickCounter = movement.speed
                    print("unit blocked by impassible entity, start trying to break blocker")
                    // start breaking the obstacle
                    if let stone = occupants.first(where: { $0.isImpassable }) {
                        //movement.currentPath.removeAll()
                        entity.state = .attacking(targetID: stone.id)
                    }
                    continue
                }
            }
            
            //check if there is a unit (entity with obeysReservation == true) blocking movement
            if entity.obeysReservation {
                if let reserverID = reservedTiles[nextStep], reserverID != entity.id {
                    movement.waitTimer += 1
                    
                    if movement.waitTimer >= 5 {
                        movement.waitTimer = 0
                        
                        if let blocker = entityManager.allEntities.first(where: { $0.id == reserverID }) {
                            
                            // 1. Get tile info for the blocked spot
                            let targetTile = grid.tiles[nextStep.row][nextStep.col]
                            let isObjectivePush = targetTile.terrain == .objective || targetTile.isObjectiveZone

                            // 2. Identify the blocker's situation
                            let isEnemy = blocker.team != entity.team
                            let isAttacking: Bool
                            if case .attacking = blocker.state { isAttacking = true } else { isAttacking = false }

                            // 3. THE NEW REFINED PUSH RULES:
                            // Only push if: It's an objective AND it's a teammate AND they aren't busy attacking
                            if isObjectivePush && !isEnemy && !isAttacking {
                                
                                // 4. Find a neighbor that is ALSO an objective tile and is empty
                                if let escapeTile = grid.findNearestObjectiveNeighbor(at: blocker.position, canFly: blocker.movement?.isFlying ?? false) {
                                    
                                    grid.moveEntity(blocker, from: blocker.position, to: escapeTile)
                                    
                                    reservedTiles.removeValue(forKey: nextStep)
                                    reservedTiles[escapeTile] = blocker.id
                                    
                                    blocker.movement?.currentPath.removeAll()
                                    blocker.state = .idle
                                    print("Strategic nudge: \(entity.name) swapped \(blocker.name) to a nearby objective tile.")
                                } else {
                                    entity.state = .stuck
                                }
                            } else {
                                // If not an objective zone, or blocker is an enemy/attacking: just detour
                                entity.state = .stuck
                                print("\(entity.name) is yielding to \(blocker.name) (Non-objective or busy).")
                            }
                        }
                    }
                    continue
                }
            }
            
            //if all checks pass, execute move
            executeMove(entity: entity, moveComp: movement, to: nextStep, grid: grid)
            movement.internalTickCounter = 0
            movement.waitTimer = 0
        }
    }
    
    //tile-based move
    private func executeMove(entity: Entity_MK3, moveComp: MovementComponent, to nextPos: TilePosition, grid: Grid_MK3) {
        let oldPos = entity.position
        
        entity.position = nextPos
        
        if entity.obeysReservation {
            //reservedTiles.removeValue(forKey: oldPos)
            reservedTiles[nextPos] = entity.id
        }
        
        grid.moveEntity(entity, from: oldPos, to: nextPos)
        
        if !moveComp.currentPath.isEmpty {
            moveComp.currentPath.removeFirst()
        }
        
        if nextPos.col > oldPos.col { moveComp.direction = .right }
        else if nextPos.col < oldPos.col { moveComp.direction = .left }
        
        // When path is empty, we go back to .idle so the AIBrain can pick a new target
        if moveComp.currentPath.isEmpty {
            entity.state = .idle
        }
    }
    
    //projectile (direct) move
    private func executeProjectileTick(entity: Entity_MK3, proj: ProjectileComponent, target: Entity_MK3?, grid: Grid_MK3) {
        guard let target = target else {
            entity.state = .dead
            return
        }

        
    }
}
