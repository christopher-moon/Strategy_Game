import GameplayKit

class CollisionSystem {
    weak var mapManager: MapManager?

    func update(components: [MovementComponent], deltaTime: TimeInterval) {
        let dt = Float(deltaTime)
        
        for comp in components {
            guard !comp.isPaused else { continue }
            
            // 1. Calculate Intended Step
            if let target = comp.targetPosition {
                let currentPos = comp.position
                let diff = target - currentPos
                let dist = simd_length(diff)
                
                if dist < 4.0 {
                    comp.position = target
                    comp.targetPosition = nil
                } else {
                    let direction = simd_normalize(diff)
                    let moveDistance = comp.maxSpeed * dt
                    let step = direction * moveDistance
                    
                    // 2. Resolve Obstacles & Sliding
                    resolveMovement(comp: comp, step: step)
                }
            }
            
            // 3. Apply Separation (The Magnet Nudge)
            applySeparation(for: comp, amongst: components)
            
            // 4. Final Syncs
            comp.syncOccupancy()
            comp.delegate?.agentDidUpdate?(comp)
        }
    }

    private func resolveMovement(comp: MovementComponent, step: vector_float2) {
        let currentPos = comp.position
        
        // 80% of radius allows for "tighter" sliding around corners
        let pushRadius = Float(comp.radius) * 0.8
        
        // 1. Try X movement independently
        let xStep = vector_float2(step.x, 0)
        // Calculate a test point that is 'pushRadius' ahead of the intended X position
        let xOffsetX = step.x > 0 ? pushRadius : -pushRadius
        let xTestPoint = vector_float2(currentPos.x + xStep.x + xOffsetX, currentPos.y)
        
        if !isBlocked(comp: comp, at: xTestPoint) {
            comp.position.x += xStep.x
        }
        
        // 2. Try Y movement independently
        let yStep = vector_float2(0, step.y)
        // Calculate a test point that is 'pushRadius' ahead of the intended Y position
        let yOffsetY = step.y > 0 ? pushRadius : -pushRadius
        let yTestPoint = vector_float2(comp.position.x, currentPos.y + yStep.y + yOffsetY)
        
        if !isBlocked(comp: comp, at: yTestPoint) {
            comp.position.y += yStep.y
        }
    }
    
    private func isBlocked(comp: MovementComponent, at point: vector_float2) -> Bool {
        guard let obstacles = mapManager?.physicalObstacles else { return false }
        
        for obstacle in obstacles {
                if obstacle.contains(point) {
                    return true
                }
        }
        return false
    }
    
    private func applySeparation(for comp: MovementComponent, amongst all: [MovementComponent]) {
        for other in all {
            if other === comp { continue }
            let delta = comp.position - other.position
            let dist = simd_length(delta)
            let minDist = comp.radius + other.radius
            
            if dist < minDist {
                let overlap = minDist - dist
                let pushDir = dist > 0 ? simd_normalize(delta) : vector_float2(1, 0)
                let nudge = pushDir * overlap * 0.2
                
                // --- NEW SAFETY CHECK ---
                let pushRadius = Float(comp.radius) * 0.8
                // Check a point further out in the direction the unit is being pushed
                let safetyProbe = comp.position + nudge + (pushDir * pushRadius)
                
                if !isBlocked(comp: comp, at: safetyProbe) {
                    comp.position += nudge
                }
            }
        }
    }
}
