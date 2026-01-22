/* EntityNode_MK3.swift */
import SpriteKit

class EntityNode_MK3: SKNode {
    let entityID: UUID
    private let sprite: SKSpriteNode
    private let healthBar: SKShapeNode
    private let debugLabel: SKLabelNode
    
    init(entity: Entity_MK3, size: CGFloat) {
        self.entityID = entity.id
        
        // Setup Sprite
        let texture = SKTexture(imageNamed: entity.name.lowercased())
        self.sprite = SKSpriteNode(texture: texture, color: .gray, size: CGSize(width: size, height: size))
        if texture.size() == .zero { self.sprite.colorBlendFactor = 1.0 }
        
        // Setup Health Bar
        self.healthBar = SKShapeNode(rectOf: CGSize(width: 30, height: 4))
        self.healthBar.fillColor = .green
        self.healthBar.position = CGPoint(x: 0, y: size/2 + 5)
        
        // Setup Debug State Label
        self.debugLabel = SKLabelNode(fontNamed: "Courier-Bold")
        self.debugLabel.fontSize = 7
        self.debugLabel.position = CGPoint(x: 0, y: -size/2 - 12)
        
        // Set color based on team
        switch entity.team {
        case .player:
            self.debugLabel.fontColor = .cyan
        case .enemy:
            self.debugLabel.fontColor = .systemRed
        case .neutral:
            self.debugLabel.fontColor = .lightGray
        }
        
        // Set internal UI elements to the UI layer
        // This ensures health bars stay above all units even if the node itself is at a lower Z
        self.healthBar.zPosition = ZManager.ui
        self.debugLabel.zPosition = ZManager.ui
            
        // The sprite itself lives at the relative 0 of this node
        self.sprite.zPosition = 0
        
        super.init()
        addChild(sprite)
        addChild(healthBar)
        addChild(debugLabel)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // --- YOUR LERP LOGIC LIVES HERE NOW ---
    func update(entity: Entity_MK3, targetPoint: CGPoint, deltaTime: TimeInterval) {

        if let proj = entity.projectile {
           
            
        } else {
            // 1. Move logic (The Lerp)
            // Your exact math: Move 10% of remaining distance * speed * delta
            let speed: CGFloat = 10.0
            let newX = self.position.x + (targetPoint.x - self.position.x) * speed * CGFloat(deltaTime)
            let newY = self.position.y + (targetPoint.y - self.position.y) * speed * CGFloat(deltaTime)
            self.position = CGPoint(x: newX, y: newY)
            
            // 2. Flip logic
            if let moveComp = entity.movement {
                sprite.xScale = (moveComp.direction == .right) ? 1.0 : -1.0
            }
            
        }
        
        
        // Apply Global Y-Sorting
        // Determine the correct base
        var base = ZManager.world
            
        if entity.projectile != nil {
            base = ZManager.projectile // Uses the highest layer (7000)
        } else if entity.movement?.isFlying == true {
            base = ZManager.flying
        } else if entity.movement == nil {
            base = ZManager.floorHazard
        }

        self.zPosition = ZManager.forRow(entity.position.row, base: base)
        
        // 3. Health logic
        if let health = entity.health {
            healthBar.isHidden = false // Ensure it's visible if health exists
            
            // Use the exact property names from your HealthComponent (current vs max)
            let pct = CGFloat(health.current) / CGFloat(health.max)
            
            // Clamp the scale so it doesn't go negative or weirdly wide
            healthBar.xScale = max(0, min(1.0, pct))
            
            healthBar.fillColor = pct > 0.5 ? .green : (pct > 0.2 ? .yellow : .red)
        } else {
            // This is the critical line!
            // If the logical entity has no health component, the visual node hides the bar.
            healthBar.isHidden = true
        }
        
        // 4. Debug logic
        debugLabel.text = "\(entity.state)".split(separator: "(").first?.uppercased() ?? "IDLE"
    }
}
