//registry of all different obstacle types

//basic obstacle blueprint
struct ObstacleBlueprint {
    let name: String
    let type: ObstacleType
    let hp: Int
    let blocksMovement: Bool
    let attack: Int
}

//obstacle registry
struct ObstacleRegistry {
    static let data: [String: ObstacleBlueprint] = [
        
        "Fence": ObstacleBlueprint(
            name: "Fence",
            type: .fence,
            hp: 20,
            blocksMovement: true,
            attack: 0
        ),
        
        "Mine": ObstacleBlueprint(
            name: "Mine",
            type: .mine,
            hp: 1,
            blocksMovement: false,
            attack: 15
        ),
        
        "Generator": ObstacleBlueprint(
            name: "Generator",
            type: .generator,
            hp: 10,
            blocksMovement: true,
            attack: 0
        )
        
    ]
    
}
