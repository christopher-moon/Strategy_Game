import GameplayKit

class MovementSystem {
    private let componentSystem = GKComponentSystem(componentClass: MovementComponent.self)

    func addComponent(foundIn entity: Entity) {
        componentSystem.addComponent(foundIn: entity)
    }

    func update(deltaTime: TimeInterval) {
        componentSystem.update(deltaTime: deltaTime)
    }


}
