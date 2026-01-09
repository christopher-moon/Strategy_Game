import SpriteKit

extension UnitManager {
    
    //MARK: PATHFIND
    func pathfind(from start: TilePosition, to goal: TilePosition, for movingUnit: UnitNode) -> [TilePosition]? {
        guard let scene = scene else { return nil }
        
        let pathfinder = AStarPathfinder(
            rows: scene.rows,
            cols: scene.cols,
            isWalkable: { pos in
                //guard let tile = scene.tileAt(position: pos), tile.tile.terrain != .wall else { return false }
                //return true
                if pos == goal { return true }
                return self.gridManager.isTileWalkable(pos)
            },
            cost: { pos in
                
                if pos == movingUnit.unit.position { return 1 }       // own tile, normal cost
                var baseCost = 1
                
                //for objective units
                let isMissionLocked = movingUnit.unit.isMissionLocked
                
                //occupancy costs
                if let occupant = self.unitAt(pos), occupant.unit.team != movingUnit.unit.team {
                    
                    baseCost = isMissionLocked ? 15 : 120
                } else {
                    
                    baseCost = 5 // Moderate cost for friends
                }
                    
                   // occupied tiles are expensive
                if self.reservedTiles.contains(pos) { return 3 }     // future planned tiles, medium cost
                // Bonus for following other friendly units’ recent paths
                var bonus = 0
                for unit in self.units.values {
                    guard unit.unit.id != movingUnit.unit.id else { continue }
                    guard unit.unit.team == movingUnit.unit.team else { continue }
                    if let path = unit.unit.currentPath,
                       path.contains(pos),
                       self.distance(from: unit.unit.position, to: movingUnit.unit.position) <= 3 {
                           bonus -= 2
                    }
                }
                    
                return max(1, baseCost + bonus) // don't go below 1                                       // normal                                         // normal
            }
        )

        return pathfinder.findPath(from: start, to: goal)
    }

    //MARK: START AI TICK
    // Start automatic AI updates for all units
    func startAITick(interval: TimeInterval = 0.3) {
        guard let scene = scene else { return }

        let wait = SKAction.wait(forDuration: interval)
        let update = SKAction.run { [weak self] in self?.performMovementTick() }

        scene.run(SKAction.repeatForever(SKAction.sequence([update, wait])), withKey: "unitAITick")
    }
    
    //MARK: STOP AI TICK
    func stopAITick() {
        scene?.removeAction(forKey: "unitAITick")
    }
    
    //MARK: MOVEMENT TICK
    func performMovementTick() {
        guard let scene = scene else { return }
        moveRequests.removeAll()
        // Reserve current positions to prevent collisions
        reservedTiles = Set(units.values.map { $0.unit.position })
        // Phase 1: Units submit desired next steps
        for unit in units.values {
            // cooldown check
            if unit.unit.movementCooldown > 0 {
                unit.unit.movementCooldown -= 1
                continue
            }
            // AI brain decides to move or attack
            if let next = findNextStep(for: unit) {
                moveRequests[unit.unit.id] = next
            }
        }
        // Phase 2: Resolve conflicts
        resolveMoveRequests(in: scene)
        // Phase 3: Unit Combat
        performAttackTick()
        // Phase 4: Update reserved tiles for next tick
        reservedTiles = Set(units.values.map { $0.unit.position })
    }
    
    //MARK: FIND NEXT STEP
    //dont actually move unit, only ask where it wants to go
    func findNextStep(for unit: UnitNode) -> TilePosition? {
        //updatePathForUnit(unit)
        //guard let path = unit.unit.currentPath, !path.isEmpty else { return nil }
        //let next = path[0]
        // Don't block here — conflicts are handled in resolveMoveRequests
        //return next
        // The core AI decision now determines if the unit should move or stand still
        return unit.unit.ai.determineAction(for: unit, manager: self)
    }
    
    //MARK: RESOLVE MOVE CONFLICTS
    //if two units want the same tile, resolve conflict
    //only one unit gets tile, other must repath
    func resolveMoveRequests(in scene: GameScene) {
        // Group requests by target tile
        let requestsByTile = Dictionary(grouping: moveRequests.keys) { moveRequests[$0]! }

        for (tilePos, requesters) in requestsByTile {

            // Skip if tile already reserved
            if reservedTiles.contains(tilePos) || !gridManager.isTileWalkable(tilePos) {
                for id in requesters {
                    
                    if let unit = units[id] {
                        
                        unit.unit.needsRepath = true

                        //  Check if the failed move was the final step of the current goal
                        if unit.unit.currentGoal == tilePos {
                            // If the unit's final target was the tile that just became reserved/occupied,
                            // we need to find a new objective tile immediately.
                            unit.unit.currentGoal = nil
                        }
                    }
                }
                continue
            }

            // Pick one unit to move
            let movableUnits = requesters.compactMap { units[$0] }
            guard !movableUnits.isEmpty else { continue }

            let winner = movableUnits.randomElement()!
            if let tileNode = scene.tileAt(position: tilePos) {
                commitMove(winner, to: tileNode)
                reservedTiles.insert(tilePos)
            }

            // Other units must repath
            for unit in movableUnits where unit.unit.id != winner.unit.id {
                unit.unit.needsRepath = true
            }
        }
    }
    
    //MARK: COMMIT MOVE
    //commit logical and visual movement once conflics are resolved
    func commitMove(_ unit: UnitNode, to tile: TileNode) {
        
        let ticks = unit.unit.movementSpeed
        let duration = 0.3 * Double(ticks)
        
        moveUnit(unit, to: tile, duration: duration)
        
        // After the move, set cooldown
        unit.unit.movementCooldown = ticks
    }
    
    //MARK: FIND NEAREST OBJECTIVE
    internal func findNearestObjectiveTile(from position: TilePosition) -> TilePosition? {
        // Since this method is inside UnitManager, 'self' here is the manager.
        // We pass 'self' (the UnitManager) to the Scene's function to allow occupancy checks.
        guard let scene = self.scene else { return nil }
            
        // This is where we call the Scene's function, passing the manager for context:
        return scene.findNearestObjective(from: position, unitManager: self)
        
    }
    
}
