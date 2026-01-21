class MineBrain: AIBrain_MK3 {
    
    func decide(owner: Entity_MK3, grid: Grid_MK3, entityManager: EntityManager_MK3) {
        
        // 1. SPAWNING LOGIC
        if owner.state == .spawning {
            owner.state = .disabled
            owner.combat?.currentTargetID = nil
            return
        }
        /*
        
        // 2. PRESSURE LOGIC (.disabled)
        if owner.state == .disabled {
            let currentUnit = findTarget(owner: owner, grid: grid)
            let trackedID = owner.combat?.currentTargetID

            if trackedID == nil {
                if let unit = currentUnit {
                    owner.combat?.currentTargetID = unit
                    print("Mine depressed by \(unit)")
                }
                return
            }

            if trackedID != nil {
                if currentUnit == nil {
                    print("Step-off detected. Arming.")
                    owner.state = .idle
                    owner.combat?.currentTargetID = nil
                } else if currentUnit != trackedID {
                    print("Unit swap! Triggering.")
                    owner.state = .idle
                }
                return // Important: stay in disabled until the next tick
            }
        }
        
        // 3. ARMED LOGIC (.idle)
        if owner.state == .idle {
            if let target = findTarget(owner: owner, grid: grid) {
                print("BOOM")
                // This helper sets owner.state to .attacking
                setTarget(owner: owner, target: target)
                return
            }
        }
         */

    }
}
