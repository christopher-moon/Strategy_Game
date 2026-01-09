//handle all z layering
import CoreGraphics

struct ZManager {
    // Defined Layer Ranges (Spaced out for flexibility)
    static let terrain: CGFloat    = 0      // TileNodes
    static let shadow: CGFloat     = 1000   // Unit shadows (behind units)
    static let world: CGFloat      = 2000   // Units & Obstacles (The Y-Sorted Layer)
    static let flying: CGFloat     = 4000   // Hovering/Flying Units
    static let effect: CGFloat = 6000   // ProjectileNodes
    static let projectile: CGFloat     = 7000   // EffectNodes
    static let ui: CGFloat         = 9000   // Health bars

    //authoratative y layering
    static func forRow(_ row: Int, base: CGFloat = ZManager.world) -> CGFloat {
        return base + CGFloat(row)
    }
    
    /*
    static func forRow(_ row: Int, isFlying: Bool = false, isSelected: Bool = false) -> CGFloat {
            // 1. Choose the base floor
            let base = isFlying ? ZManager.flying : ZManager.world
            
            // 2. Add selection boost if needed
            let boost = isSelected ? ZManager.selectionBoost : 0
            
            // 3. Combine with Row for Y-Sorting
            return base + CGFloat(row) + boost
    }
    */
}
