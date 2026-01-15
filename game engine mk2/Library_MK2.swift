/*
 Library_MK2.swift:
 load specfic entity data from .json file
*/
import Foundation

class Library_MK2 {
    static let shared = Library_MK2()
    
    var units: [String: UnitBlueprint_MK2] = [:]
    var obstacles: [String: ObstacleBlueprint_MK2] = [:]
    
    private init() {
        loadJSON()
    }
    
    func loadJSON() {
        guard let url = Bundle.main.url(forResource: "GameData", withExtension: "json") else {
            print("MK2 ERROR: GameData.json not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(GameDataContainer_MK2.self, from: data)
            self.units = decoded.units
            self.obstacles = decoded.obstacles
            print("MK2 Registry Loaded: \(units.count) units, \(obstacles.count) obstacles")
        } catch {
            print("MK2 ERROR: Failed to parse JSON - \(error)")
        }
    }
}
