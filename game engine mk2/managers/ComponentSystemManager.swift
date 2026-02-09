import GameplayKit

class SystemManager {
    
    weak var mapManager: MapManager?
    // 1. The Master List of frame-based Component Systems
    // This allows you to add new systems in one single place.
    private let collisionSystem = CollisionSystem()
    private let visualSystem = GKComponentSystem(componentClass: VisualComponent.self)
    private let moveComponents = GKComponentSystem(componentClass: MovementComponent.self)
    
    init(mapManager: MapManager) {
            self.mapManager = mapManager
    }
    
    // 2. Automated Registration
    func addEntity(_ entity: Entity) {
        moveComponents.addComponent(foundIn: entity)
        visualSystem.addComponent(foundIn: entity)
    }
    
    func removeEntity(_ entity: Entity) {
        moveComponents.removeComponent(foundIn: entity)
        visualSystem.removeComponent(foundIn: entity)
    }
    
    // 3. Unified Update
    func update(deltaTime: TimeInterval) {
        
        collisionSystem.mapManager = mapManager
        
        // 1. Run the heavy math system
        collisionSystem.update(components: moveComponents.components as! [MovementComponent], deltaTime: deltaTime)
                
        // 2. Run the visual update (Labels/Health Bars)
        visualSystem.update(deltaTime: deltaTime)
    }
}
