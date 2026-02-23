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

/*
 import GameplayKit
 import SpriteKit

 class MovementSystem {
     
     func update(entityManager: EntityManager, mapManager: MapManager, deltaTime: TimeInterval) {
         let dt = Float(deltaTime)
         let allMovers = entityManager.allEntities.compactMap { $0.component(ofType: MovementComponent.self) }
         
         for entity in entityManager.allEntities {
             guard let moveComp = entity.component(ofType: MovementComponent.self) else { continue }
             
             // 1. Path Following
             if !moveComp.path.isEmpty {
                 let target = moveComp.path[0]
                 let diff = target - moveComp.position
                 let dist = simd_length(diff)
                 
                 // Snappy Arrival: Use a larger threshold for "reaching" a waypoint
                 // to prevent orbiting/jittering around the exact pixel.
                 if dist < 5.0 {
                     moveComp.position = target
                     let currentPoint = CGPoint(x: CGFloat(target.x), y: CGFloat(target.y))
                     entity.gridPosition = mapManager.calculateGridPos(from: currentPoint)
                     moveComp.path.removeFirst()
                 } else {
                     let direction = simd_normalize(diff)
                     moveComp.position += direction * (moveComp.speed * dt)
                 }
             }
             
             // 2. Hierarchical Separation
             if moveComp.physics {
                 applyHierarchicalSeparation(for: moveComp, amongst: allMovers, mapManager: mapManager)
             }
         }
     }
     
     private func applyHierarchicalSeparation(for comp: MovementComponent, amongst all: [MovementComponent], mapManager: MapManager) {
         for other in all {
             if other === comp || !other.physics { continue }
             
             let delta = comp.position - other.position
             let dist = simd_length(delta)
             let threshold = (comp.radius + other.radius) * 0.95 // 5% squish allowed for "organic" feel
             
             if dist < threshold && dist > 0 {
                 // 1. Calculate Hierarchy
                 let iAmMoving = !comp.path.isEmpty
                 let otherIsMoving = !other.path.isEmpty
                 
                 var myPushPercentage: Float = 0.0
                 
                 if comp.mass < other.mass {
                     // I am lighter: I take the full brunt
                     myPushPercentage = 1.0
                 } else if comp.mass > other.mass {
                     // I am heavier: I don't move at all (the other unit will move during its loop)
                     myPushPercentage = 0.0
                 } else {
                     // TIE BREAKER: Weights are equal
                     if iAmMoving && !otherIsMoving {
                         // I am moving, they are still: I give way (100%)
                         myPushPercentage = 1.0
                     } else if !iAmMoving && otherIsMoving {
                         // I am still, they are moving: They give way (0%)
                         myPushPercentage = 0.0
                     } else {
                         // Both moving or both still: Share the push (50/50)
                         myPushPercentage = 0.5
                     }
                 }
                 
                 // 2. Apply the Push
                 if myPushPercentage > 0 {
                     let overlap = threshold - dist
                     let pushDir = simd_normalize(delta)
                     let nudge = pushDir * overlap * myPushPercentage
                     
                     let potentialPos = comp.position + nudge
                     
                     // 3. WALL CHECK
                     // We check a slightly smaller radius for the wall check to allow
                     // units to "hug" the walls without getting stuck.
                     let cgPotential = CGPoint(x: CGFloat(potentialPos.x), y: CGFloat(potentialPos.y))
                     if mapManager.isWalkable(at: cgPotential) {
                         comp.position = potentialPos
                     }
                 }
             }
         }
     }
 }

 */
