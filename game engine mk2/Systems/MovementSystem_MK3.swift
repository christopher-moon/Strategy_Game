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
                    //increment wait timer because we are physically blocked
                    movement.waitTimer += 1
                    //after waiting 4 ticks for the blocker to go away
                    if movement.waitTimer >= 4 {
                        movement.waitTimer = 0
                        //clear the bad path
                        movement.currentPath.removeAll()
                        //force state out of .moving to .idle
                        entity.state = .idle
                        print("\(entity.name) is stuck, requesting re-path")
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
}
