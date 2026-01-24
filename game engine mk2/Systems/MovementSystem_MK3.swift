/* MovementSystem_MK3.swift */
import Foundation

class MovementSystem_MK3 {
    private var reservedTiles: [TilePosition: UUID] = [:]

    func update(entityManager: EntityManager_MK3, grid: Grid_MK3) {
        reservedTiles.removeAll()
        
        // 1. Reserve current positions for all units
        for entity in entityManager.allEntities where entity.obeysReservation {
            reservedTiles[entity.position] = entity.id
        }

        // 2. Process Movers
        for entity in entityManager.allEntities {
            
            // Handle Projectiles
            if let projectile = entity.projectile {
                handleProjectile(entity: entity, proj: projectile, entityManager: entityManager)
                continue
            }
            
            // Handle Units
            guard let movement = entity.movement, entity.state == .moving else { continue }
            
            // Speed Gate
            movement.internalTickCounter += 1
            if movement.internalTickCounter < movement.speed { continue }
            
            // Path Validation
            guard let nextStep = movement.currentPath.first else {
                entity.state = .idle // No path left
                continue
            }
            
            // Simple Movement (No Physics)
            if movement.movementType == .simple {
                executeMove(entity: entity, moveComp: movement, to: nextStep, grid: grid)
                movement.internalTickCounter = 0
                continue
            }
            
            // --- SMART PHYSICS (Standard Units) ---
            
            // A. Check for Destructible Obstacles (Stones/Walls)
            if let occupants = grid.getOccupants(at: nextStep) {
                // If blocked by obstacle and NOT flying
                if occupants.contains(where: { $0.isImpassable }) && !movement.isFlying {
                    movement.internalTickCounter = movement.speed // Reset tick
                    
                    // Attack the obstacle if it's destructible
                    if let stone = occupants.first(where: { $0.isImpassable }) {
                        entity.state = .attacking(targetID: stone.id)
                    } else {
                        // Hard wall/boundary (shouldn't happen with correct pathfinding)
                        entity.state = .idle
                    }
                    continue
                }
            }
            
            // B. Check for Unit Collision (Teammates/Enemies)
            if entity.obeysReservation, let reserverID = reservedTiles[nextStep], reserverID != entity.id {
                handleUnitCollision(entity: entity, movement: movement, blockedBy: reserverID, nextStep: nextStep, grid: grid, entityManager: entityManager)
                continue
            }
            
            // C. Execute Valid Move
            executeMove(entity: entity, moveComp: movement, to: nextStep, grid: grid)
            movement.internalTickCounter = 0
            movement.waitTimer = 0
        }
    }
    
    // MARK: - Helper Logic
    
    private func handleUnitCollision(entity: Entity_MK3, movement: MovementComponent, blockedBy blockerID: UUID, nextStep: TilePosition, grid: Grid_MK3, entityManager: EntityManager_MK3) {
        
        movement.waitTimer += 1
        
        // Only attempt 'Push' logic after waiting a bit
        if movement.waitTimer >= 5 {
            movement.waitTimer = 0
            
            guard let blocker = entityManager.allEntities.first(where: { $0.id == blockerID }) else { return }
            
            let targetTile = grid.tiles[nextStep.row][nextStep.col]
            let isObjectivePush = targetTile.terrain == .objective || targetTile.isObjectiveZone
            let isTeammate = blocker.team == entity.team
            let isBlockerBusy = (blocker.state != .idle && blocker.state != .moving) // Approx check for attacking

            // THE PUSH RULE: Objective + Teammate + Teammate not busy
            if isObjectivePush && isTeammate && !isBlockerBusy {
                
                // Try to find a free spot for the blocker
                if let escapeTile = grid.findNearestObjectiveNeighbor(at: blocker.position, canFly: blocker.movement?.isFlying ?? false) {
                    
                    // Nudge the blocker
                    grid.moveEntity(blocker, from: blocker.position, to: escapeTile)
                    reservedTiles.removeValue(forKey: nextStep)
                    reservedTiles[escapeTile] = blocker.id
                    
                    blocker.movement?.currentPath.removeAll()
                    blocker.state = .idle
                    print("Strategic nudge: \(entity.name) swapped \(blocker.name).")
                    
                    // Original unit waits 1 tick for the reservation to clear logic next frame
                } else {
                    entity.state = .stuck
                }
            } else {
                entity.state = .stuck
                print("\(entity.name) yielded to \(blocker.name).")
            }
        }
    }
    
    private func executeMove(entity: Entity_MK3, moveComp: MovementComponent, to nextPos: TilePosition, grid: Grid_MK3) {
        let oldPos = entity.position
        
        // Update Grid
        grid.moveEntity(entity, from: oldPos, to: nextPos)
        
        // Update Reservations
        if entity.obeysReservation {
            reservedTiles[nextPos] = entity.id
        }
        
        // Update Path
        if !moveComp.currentPath.isEmpty {
            moveComp.currentPath.removeFirst()
        }
        
        // Update Facing
        if nextPos.col > oldPos.col { moveComp.direction = .right }
        else if nextPos.col < oldPos.col { moveComp.direction = .left }
        
        // Stop if done
        if moveComp.currentPath.isEmpty {
            entity.state = .idle
        }
    }
    
    private func handleProjectile(entity: Entity_MK3, proj: ProjectileComponent, entityManager: EntityManager_MK3) {
        // Simple verification that target exists
        if entityManager.allEntities.contains(where: { $0.id == proj.targetID }) {
           // Projectile visual logic usually handled here or in visual system
        } else {
            entity.state = .dead
        }
    }
}
