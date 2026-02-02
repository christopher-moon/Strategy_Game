import SpriteKit

class EntityNode: SKNode {
    let entityID: UUID
    let sprite: SKSpriteNode
    
    // Debug Labels
    private let stateLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let healthLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    init(entity: Entity, size: CGFloat) {
        self.entityID = entity.id
        let color: SKColor = (entity.team == .player) ? .cyan : .red
        self.sprite = SKSpriteNode(color: color, size: CGSize(width: size * 0.7, height: size * 0.7))
        
        super.init()
        self.addChild(sprite)
        
        // Setup State Label (Top)
        stateLabel.fontSize = 12
        stateLabel.fontColor = .white
        stateLabel.position = CGPoint(x: 0, y: (size * 0.7) / 2 + 5)
        self.addChild(stateLabel)
        
        // Setup Health Label (Bottom)
        healthLabel.fontSize = 10
        healthLabel.fontColor = .green
        healthLabel.position = CGPoint(x: 0, y: -(size * 0.7) / 2 - 12)
        self.addChild(healthLabel)
    }

    // Update with new data from systems
    func update(entity: Entity, targetPoint: CGPoint, deltaTime: TimeInterval) {
        self.position = targetPoint
        
        // 1. Update State Text
        if let currentState = entity.stateMachine?.currentState {
            // This shows the class name (e.g., "Idle", "Moving")
            stateLabel.text = "\(type(of: currentState))".uppercased()
        }
        
        // 2. Update Health Numbers
        if let health = entity.component(ofType: HealthComponent.self) {
            healthLabel.text = "\(health.current)/\(health.max)"
            
            // Optional: Color coding health
            let ratio = CGFloat(health.current) / CGFloat(health.max)
            healthLabel.fontColor = ratio < 0.3 ? .red : (ratio < 0.7 ? .yellow : .green)
        }
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
}
