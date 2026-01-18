/* Library_MK3.swift */
import Foundation

class Library_MK3 {
    static let shared = Library_MK3()
    var templates: [String: EntityBlueprint_MK3] = [:]
    
    private init() { loadJSON() }
    
    func loadJSON() {
        guard let url = Bundle.main.url(forResource: "GameData", withExtension: "json") else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(GameDataContainer_MK3.self, from: data)
            self.templates = decoded.templates
            print("MK3 Registry Loaded: \(templates.count) templates")
        } catch {
            print("MK3 JSON ERROR: \(error)")
        }
    }
}
