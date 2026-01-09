//handle ALL entity animations
import SpriteKit

//animatable entity protocol
protocol AnimatableEntity: SKNode {
    var entityName: String { get }
    var currentState: String { get }
    var isLooping: Bool { get }
    var visualSprite: SKSpriteNode { get }
    var animationKey: String { get set }
}

//animation manager
class AnimationManager{
    static let shared = AnimationManager()
    
    private var textureCache: [String: [SKTexture]] = [:]
    
    //MARK: UPDATE ANIMATION
    func updateAnimation(for entity: AnimatableEntity, forcedDuration: TimeInterval? = nil){
        let stateKey = entity.currentState
        let newKey = "\(entity.entityName)_\(stateKey)"
        
        // 1. prevent restaring looping animations if they are already playing
        if entity.isLooping && entity.animationKey == newKey{ return }
        
        // 2. update animation tracking key
        entity.animationKey = newKey
                
        // 3. get textures
        let textures = getTextures(name: entity.entityName, state: stateKey)
        entity.visualSprite.removeAllActions()
        
        if textures.isEmpty{
            entity.visualSprite.texture = SKTexture(imageNamed: newKey)
            return
        }
        
        // 4. calculate frame timing
        let tpf = forcedDuration != nil ? (forcedDuration! / Double(textures.count)) : 0.3
        let anim = SKAction.animate(with: textures, timePerFrame: tpf)
        
        // 5. run animation
        if entity.isLooping{
            entity.visualSprite.run(SKAction.repeatForever(anim))
        }else{
            entity.visualSprite.run(anim)
        }
    }
    
    //MARK: GET/CACHE TEXTURES
    func getTextures(name: String, state: String) -> [SKTexture] {
        let key = "\(name)_\(state)"
                
        // 1. Check Cache
        if let cached = textureCache[key] {
            return cached
        }
                
        // 2. Load from Atlas
        // SpriteKit looks for folders named "Warrior_idle.atlas"
        let atlas = SKTextureAtlas(named: key)
                
        // Ensure textures are ordered correctly (0, 1, 2...)
        let sortedNames = atlas.textureNames.sorted()
        let textures = sortedNames.map {
            let tex = atlas.textureNamed($0)
            tex.filteringMode = .nearest
            return tex
            
        }
                
        // 3. Store in Cache (if not empty)
        if !textures.isEmpty {
            textureCache[key] = textures
        }
                
        return textures
    }
    
    //MARK: ONE SHOT ANIMATIONS
    func playOneShot(name: String, on node: SKNode, duration: TimeInterval = 0.5, completion: (() -> Void)? = nil) {
        let textures = getTextures(name: name, state: "effect") // Assumes folder "Explosion_effect.atlas"
        if textures.isEmpty { return }
        
        let tpf = duration / Double(textures.count)
        let anim = SKAction.animate(with: textures, timePerFrame: tpf)
        
        node.run(anim) {
            completion?()
        }
    }
    
    //MARK: PRELOAD TEXTURES
    func preloadTextures(names: [String], states: [String]) {
        for name in names {
            for state in states {
                _ = getTextures(name: name, state: state)
            }
        }
    }
    
}
