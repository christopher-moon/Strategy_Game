//level manager
import Foundation

class LevelManager {
    
    //load level data from .json
    static func loadLevel(fileName: String) -> LevelData? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Level file not found")
            return nil
        }
        return try? JSONDecoder().decode(LevelData.self, from: data)
    }
    
}


