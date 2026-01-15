/*
 TimeManager_MK2.swift:
 handle global game clock
*/
import Foundation

class TimeManager_MK2 {
    private var tickCounter: TimeInterval = 0
    let tickRate: TimeInterval = 0.3
    
    // This function returns 'true' only when a logical tick should occur
    func update(delta: TimeInterval) -> Bool {
        tickCounter += delta
        if tickCounter >= tickRate {
            tickCounter = 0
            return true
        }
        return false
    }
}
