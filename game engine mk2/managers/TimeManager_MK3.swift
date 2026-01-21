/*
 TimeManager_MK2.swift:
 handle global game clock
*/
import Foundation

class TimeManager_MK3 {
    var paused: Bool = false
    private var tickCounter: TimeInterval = 0
    let tickRate: TimeInterval = 0.3
    
    // This function returns 'true' only when a logical tick should occur
    func update(delta: TimeInterval) -> Bool {
        //check if paused
        if paused { return false }
    
        tickCounter += delta
        if tickCounter >= tickRate {
            tickCounter = 0
            return true
        }
        return false
    }
}
