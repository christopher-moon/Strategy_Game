import SpriteKit
import GameplayKit

class EntityNode: SKNode {
    let entityID: UUID
    let sprite: SKSpriteNode
    private let stateLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let healthLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    init(entity: Entity, size: CGFloat) {
        self.entityID = entity.id
        let color: SKColor = (entity.team == .player) ? .cyan : .red
        self.sprite = SKSpriteNode(color: color, size: CGSize(width: size * 0.7, height: size * 0.7))
        
        super.init()
        self.addChild(sprite)
        
        // Setup labels (Top & Bottom)
        stateLabel.fontSize = 12
        stateLabel.position = CGPoint(x: 0, y: (size * 0.7) / 2 + 5)
        self.addChild(stateLabel)
        
        healthLabel.fontSize = 10
        healthLabel.position = CGPoint(x: 0, y: -(size * 0.7) / 2 - 12)
        self.addChild(healthLabel)
    }

    func update(entity: Entity, deltaTime: TimeInterval) {
        // 1. Labels
        if let currentState = entity.stateMachine?.currentState {
            stateLabel.text = "\(type(of: currentState))".uppercased()
        }
        
        if let health = entity.component(ofType: HealthComponent.self) {
            healthLabel.text = "\(health.current)/\(health.max)"
            let ratio = CGFloat(health.current) / CGFloat(health.max)
            healthLabel.fontColor = ratio < 0.3 ? .red : (ratio < 0.7 ? .yellow : .green)
        }
        
        // 2. Future: State-based animations (e.g., if entity.stateMachine.currentState is Attacking)
        // triggerAnimation("attack")
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
}
