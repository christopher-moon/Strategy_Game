/*
 MovementSystem_MK2.swift
 Handles path following and grid occupancy updates for all entities.
*/
import Foundation

class MovementSystem_MK2 {
    // Tracks who owns which tile for this specific tick
    private var reservedTiles: [TilePosition: UUID] = [:]

    func update(entityManager: EntityManager_MK2, grid: Grid_MK2) {
        // 1. Reset reservations and claim current positions
        reservedTiles.removeAll()
        
        //only reserve tile for actual units
        for entity in entityManager.allEntities {
            if entity is Unit_MK2 {
                reservedTiles[entity.position] = entity.id
            }
        }

        // 2. Process Intent
        for entity in entityManager.allEntities {
            //only move units
            guard let unit = entity as? Unit_MK2 else { continue }
            
            //only move units in the "moving" state (set by ai)
            guard case .moving = unit.state else { continue }
            
            // Handle Unit Speed (Lower speed = moves more often)
            unit.internalTickCounter += 1
            if unit.internalTickCounter < unit.speed { continue }
            
            // Do they have a path?
            guard let nextStep = unit.currentPath.first else { continue }
            
            // CONFLICT CHECK: Is the tile occupied?
            if let occupantID = reservedTiles[nextStep] {
                // If someone is there (and it's not us), we wait.
                // We do NOT clear the path. We just don't move this tick.
                if occupantID != unit.id { continue }
            }
            
            // VALIDATION: Is the tile a Wall?
            if grid.getTile(at: nextStep)?.terrain == .wall {
                unit.currentPath.removeAll() // Path is invalid
                continue
            }
            
            // SUCCESS: Execute the move
            executeMove(unit: unit, to: nextStep, grid: grid)
            unit.internalTickCounter = 0
        }
    }

    private func executeMove(unit: Unit_MK2, to nextPos: TilePosition, grid: Grid_MK2) {
        let oldPos = unit.position
        
        // Update local reservations so the next unit in the loop sees us at our new spot
        reservedTiles.removeValue(forKey: oldPos)
        reservedTiles[nextPos] = unit.id
        
        // Update Unit and Grid Data
        grid.moveUnit(unit, from: oldPos, to: nextPos)
        unit.currentPath.removeFirst()
        
        // Update Visual Direction
        if nextPos.col > oldPos.col { unit.facing = .right }
        else if nextPos.col < oldPos.col { unit.facing = .left }
    }
}
