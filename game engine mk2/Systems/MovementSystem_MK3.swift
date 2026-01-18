/* MovementSystem_MK3.swift */
import Foundation

class MovementSystem_MK3 {
    private var reservedTiles: [TilePosition: UUID] = [:]

    func update(entityManager: EntityManager_MK3, grid: Grid_MK3) {
        reservedTiles.removeAll()
        
        // 1. Reserve current positions for all "unit type" (obeysReservation) entities
        for entity in entityManager.allEntities where entity.obeysReservation == true {
            reservedTiles[entity.position] = entity.id
        }

        // 2. Process Movers
        for entity in entityManager.allEntities {
            // MovementSystem only cares if you are ALREADY in the .moving state
            guard let movement = entity.movement, entity.state == .moving else { continue }
            
            // Handle Movement Speed
            movement.internalTickCounter += 1
            if movement.internalTickCounter < movement.speed { continue }
            
            // Do they have a path?
            guard let nextStep = movement.currentPath.first else { continue }
            
            // --- SIMPLE OVERRIDE (Hazards/Projectiles) ---
            if movement.movementType == .simple {
                executeMove(entity: entity, moveComp: movement, to: nextStep, grid: grid)
                movement.internalTickCounter = 0
                continue
            }
            
            // --- SMART PHYSICS CHECKS (Standard Units) ---
            
            // A. Grid/Wall Check
            if grid.isImpassable(at: nextStep, canFly: movement.isFlying) {
                movement.internalTickCounter = movement.speed
                continue
            }
            
            // B. Occupant/Impassable Check
            if let occupants = grid.getOccupants(at: nextStep) {
                if occupants.contains(where: { $0.isImpassable }) && !movement.isFlying {
                    movement.internalTickCounter = movement.speed
                    print("unit blocked by impassible stone, start trying to break stone")
                    // If your combat system needs a specific target ID:
                    if let stone = occupants.first(where: { $0.isImpassable }) {
                        entity.state = .attacking(targetID: stone.id)
                    }
                    //entity.state = .attacking(stone)
                    continue
                }
            }
            
            // C. Reservation Check
            if entity.obeysReservation {
                if let reserverID = reservedTiles[nextStep], reserverID != entity.id {
                    // Increment wait timer because we are physically blocked
                    movement.waitTimer += 1
                                
                    if movement.waitTimer >= 4 { // "I've waited long enough"
                        movement.waitTimer = 0
                        movement.currentPath.removeAll() // Clear the bad path
                        entity.state = .idle // Force the Brain to find a new way
                        print("\(entity.name) is stuck, requesting re-path")
                    }
                    continue
                }
            }
            
            // --- EXECUTE MOVE ---
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
