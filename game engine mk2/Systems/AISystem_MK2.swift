/* AISystem_MK3.swift */
import Foundation

class AISystem_MK3 {
    // The queue of entities waiting for a 'decide' call
    private var thinkingQueue: [Entity_MK3] = []
    
    // How many units process per frame.
    // At 5 units/frame, 15 units are finished in 3 frames (0.05 seconds).
    private let batchSize = 5

    /// Called by GameScene when the 0.3s Logic Tick triggers
    func enqueueEntities(entityManager: EntityManager_MK3) {
        // Only enqueue entities that have a brain and aren't dead
        let eligible = entityManager.allEntities.filter { $0.ai != nil && $0.state != .dead }
        thinkingQueue.append(contentsOf: eligible)
    }

    /// Called EVERY frame (not just on the tick) to process the queue
    func update(entityManager: EntityManager_MK3, grid: Grid_MK3) {
        guard !thinkingQueue.isEmpty else { return }

        let countToProcess = min(batchSize, thinkingQueue.count)
        
        for _ in 0..<countToProcess {
            let entity = thinkingQueue.removeFirst()
            
            // Re-verify entity is still alive/valid before deciding
            if entity.state != .dead {
                entity.ai?.decide(owner: entity, grid: grid, entityManager: entityManager)
            }
        }
    }
    
    // Helper to let the GameScene know if it can move to the next phase
    var isQueueEmpty: Bool {
        return thinkingQueue.isEmpty
    }
}
