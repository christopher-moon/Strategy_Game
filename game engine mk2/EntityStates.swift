import GameplayKit

// MARK: - Base State
class EntityState: GKState {
    unowned let entity: Entity
    unowned let entityManager: EntityManager
    unowned let mapManager: MapManager
    
    // Inject the managers so the brain can read the game state
    init(entity: Entity, entityManager: EntityManager, mapManager: MapManager) {
        self.entity = entity
        self.entityManager = entityManager
        self.mapManager = mapManager
        super.init()
    }
}

// MARK: - Spawning
class Spawning: EntityState {
    var elapsed: TimeInterval = 0
    var duration: TimeInterval = 1.0// Adjust spawn time

    override func update(deltaTime ticks: TimeInterval) {
        duration = entity.timer
        elapsed += ticks
        if elapsed >= duration {
            if stateMachine?.state(forClass: Idle.self) != nil {
                stateMachine?.enter(Idle.self)
            } else {
                stateMachine?.enter(Dead.self)
            }
        }
    }
}

// MARK: - Idle (The "Thinking" State)
class Idle: EntityState {
    override func update(deltaTime ticks: TimeInterval) {
        guard let moveComp = entity.component(ofType: MovementComponent.self) else { return }
        
        // 1. Find the nearest objective TILE using the new MapManager function
        if let targetTilePos = mapManager.findNearestObjective(from: moveComp.position) {
            
            // Optional: If we are already standing on the objective, do nothing
            if entity.gridPosition == targetTilePos {
                return
            }
            
            // 2. Ask MapManager for a path to the objective tile
            let newPath = mapManager.findPath(from: entity.gridPosition, to: targetTilePos)
            
            // 3. If a valid path exists, assign it and transition to Moving
            if !newPath.isEmpty {
                moveComp.path = newPath
                stateMachine?.enter(Moving.self)
            }
        }
    }
}

// MARK: - Moving (The "Action" State)
class Moving: EntityState {
    override func update(deltaTime ticks: TimeInterval) {
        guard let moveComp = entity.component(ofType: MovementComponent.self) else { return }
        
        // If the path is empty, we have arrived at our destination (or got stuck).
        // Transition back to Idle to reassess the situation.
        if moveComp.path.isEmpty {
            stateMachine?.enter(Idle.self)
        }
    }
}

class Attacking: EntityState { }
class Dead: EntityState { }
