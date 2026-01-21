/*
 AIBrain_MK2.swift
 define ai brain protocol
*/

import Foundation

protocol AIBrain_MK3 {
    func decide(owner: Entity_MK3, grid: Grid_MK3, entityManager: EntityManager_MK3)
}

extension AIBrain_MK3 {
    
    //request movement (set a target/path for movementSystem + set state to .moving)
    func requestMove(owner: Entity_MK3, to target: TilePosition, grid: Grid_MK3) -> Bool {
        //if the target is the current position, dont move
        if owner.position == target {
            return false
        }
        //optimization: Don't repath if already heading there
        if owner.state == .moving, owner.movement?.currentPath.last == target { return true }
        //check if entity is a smart mover (A*) or simple mover (Linear)
        let type = owner.movement?.movementType ?? .smart
        //check if entity can fly
        let canFly = owner.movement?.isFlying ?? false
        //find path to target using pathfinder
        let path: [TilePosition]
        if type == .simple {
            path = Pathfinding_MK3.findAbsoluteLinearPath(from: owner.position, to: target)
        } else {
            path = Pathfinding_MK3.findPath(from: owner.position, to: target, grid: grid, canFly: canFly)
        }
        //if pathfinding returned a valid path, set entity's path and set state to .moving (this will trigger movementSystem to start moving the entity along the path during the movement phase)
        if !path.isEmpty {
            owner.movement?.currentPath = path
            owner.state = .moving
            return true
        }
        return false
    }
    
    //set target (pass a target for combatSystem + set state to .attacking)
    func setTarget(owner: Entity_MK3, target: UUID){
        //clear path, preventing all movement
        owner.movement?.currentPath.removeAll()
        //set current target
        owner.combat?.currentTargetID = target
        //set state to .attacking and pass target (this will trigger combatSystem during the combat phase)
        owner.state = .attacking(targetID: target)
    }
    
    //find target (find closest enemy in threat range, nil if no enemies within threat range)
    func findTarget(owner: Entity_MK3, grid: Grid_MK3, reachableMap: [TilePosition: Int]) -> UUID? {
        //only search if the unit actually has combat capabilities
        guard let threatRange = owner.combat?.threatRange else { return nil }
        //use grid to find closest enemy
        return grid.findClosestEnemy(from: owner.position, range: threatRange, excludingTeam: owner.team, reachableMap: reachableMap)
    }
    
    //findNearestObjective (returns nearest, cheapest free objective tile)
    func findNearestObjective(owner: Entity_MK3, grid: Grid_MK3, reachableMap: [TilePosition: Int]) -> TilePosition? {
        
        var bestObjective: TilePosition?
        var minPathCost = Int.max
            
        // We only iterate over tiles that Dijkstra confirmed are reachable
        for (pos, pathCost) in reachableMap {
            
            let tile = grid.tiles[pos.row][pos.col]
                
            if tile.terrain == .objective || tile.isObjectiveZone {
                let occupants = grid.getOccupants(at: pos) ?? []
                    
                //we can still try to take tiles from enemies, but not teammates
                let isReserved = occupants.contains { ($0.obeysReservation && $0.team == owner.team) && $0.id != owner.id}
                    
                if !isReserved {
                    // Prioritize objectives based on total path cost (distance + obstacles)
                    if pathCost < minPathCost {
                        minPathCost = pathCost
                        bestObjective = pos
                    }
                }
            }
        }
        return bestObjective
    }

    //engageTarget (attempt to engage target in threat range)
    func engageTarget(owner: Entity_MK3, targetID: UUID, entityManager: EntityManager_MK3, grid: Grid_MK3, reachableMap: [TilePosition: Int]) -> Bool {
        
        //ensure target still exists
        guard let targetEntity = entityManager.allEntities.first(where: { $0.id == targetID }) else { return false }
                
        let dist = grid.distance(owner.position, targetEntity.position)
        let attackRange = owner.combat?.range ?? 1
        
        //if in attack range
        if dist <= attackRange {
            
            //if not already attacking
            if case .attacking = owner.state { return true }
                // mark for attacking
                setTarget(owner: owner, target: targetID)
                return true
        
        //if not in range
        } else {
            //use reachableMap to find the nearest, reachable spot within attack range
            if let bestSpot = grid.findBestAttackSpot(near: targetEntity.position, seeker: owner.position, range: attackRange, ignoringID: owner.id, reachableMap: reachableMap) {
                // mark for moving into attack range
                return requestMove(owner: owner, to: bestSpot, grid: grid)
            }
        }
        //unable to engage target at all
        return false
    }

    //playObjective (move towards nearest valid objective tile)
    func playObjective(owner: Entity_MK3, grid: Grid_MK3, reachableMap: [TilePosition: Int]) -> Bool {
        guard let objPos = findNearestObjective(owner: owner, grid: grid, reachableMap: reachableMap) else {
            return false
        }
        return requestMove(owner: owner, to: objPos, grid: grid)
    }
}


