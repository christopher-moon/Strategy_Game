/* ZManager_MK3.swift */
import CoreGraphics

struct ZManager {
    // Defined Layer Ranges
    static let terrain: CGFloat    = 0      // TileNodes
    static let shadow: CGFloat     = 1000   // Unit shadows
    static let floorHazard: CGFloat = 1500
    static let world: CGFloat      = 2000   // Units (The Y-Sorted Layer)
    static let flying: CGFloat     = 4000   // Hovering/Flying Units
    static let effect: CGFloat     = 6000   // ProjectileNodes
    static let projectile: CGFloat = 7000   // EffectNodes
    static let ui: CGFloat         = 9000   // Health bars, Labels

    // Calculates Y-sorting. Higher row index = front.
    static func forRow(_ row: Int, base: CGFloat = ZManager.world) -> CGFloat {
        // Adding the row ensures that units at row 20 appear in front of units at row 19
        return base + CGFloat(row)
    }
}
