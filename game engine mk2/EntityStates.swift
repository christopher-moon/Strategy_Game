import GameplayKit

//define general entity state class
class EntityState: GKState {
    unowned let entity: Entity
    init(entity: Entity) { self.entity = entity; super.init() }
}

//entity added to game
class Spawning: EntityState {
    
    var elapsed: TimeInterval = 0
    let duration: TimeInterval = 3.0 // Adjust this for how long spawning takes

    override func update(deltaTime ticks: TimeInterval) {
        elapsed += ticks
        if elapsed >= duration {
            // Check if the entity's brain actually has an Idle state before entering
            if stateMachine?.state(forClass: Idle.self) != nil {
                stateMachine?.enter(Idle.self)
            } else {
                // If it's an effect (no health/idle), move to Dead
                stateMachine?.enter(Dead.self)
            }
        }
    }
}

//unit type entity standing still
class Idle: EntityState {

}

//unit type entity moving
class Moving: EntityState {

}

//unit type entity attacking
class Attacking: EntityState {
    
}

//dead
class Dead: EntityState {
    
}
