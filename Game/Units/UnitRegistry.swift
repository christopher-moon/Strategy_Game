//registry of all different unit types

//unit attack patterns
enum AttackPattern {
    //single target, adjacent
    case melee
    //single target, ranged
    case projectile(rounds: Int, name: String, smokeTrail: Bool)
    //AOE centered on target/impact tile
    case blast(radius: Int, projectileName: String?, smokeTrail: Bool, friendlyFire: Bool)
    //constant damage aura centered around unit
    case aura(radius: Int, effectName: String, isTethered: Bool)
    //single target laser
    case tether(effectName: String)
    //AOE melee attack centered around unit
    //case cleave(radius: Int, friendlyFire: Bool)
    //case strike(
}

//basic unit blueprint
struct UnitBlueprint {
    let name: String
    let maxHP: Int
    let attack: Int
    let attackSpeed: Int
    let range: Int
    let threatRange: Int
    let movementSpeed: Int
    let attackPattern: AttackPattern
    // Add any other specific unit data here
}

//unit registry
struct UnitRegistry {
    static let data: [String: UnitBlueprint] = [
        
        //warrior
        "Warrior": UnitBlueprint(
            name: "Warrior",
            maxHP: 10,
            attack: 3,
            attackSpeed: 5,
            range: 1,
            threatRange: 8,
            movementSpeed: 2,
            attackPattern: .melee
        ),
        
        //archer
        "Archer": UnitBlueprint(
            name: "Archer",
            maxHP: 10,
            attack: 1,
            attackSpeed: 5,
            range: 6,
            threatRange: 8,
            movementSpeed: 2,
            attackPattern: .projectile(rounds: 1, name: "bullet", smokeTrail: true)
        ),
        
        //mage
        "Mage": UnitBlueprint(
            name: "Mage",
            maxHP: 5,
            attack: 2,
            attackSpeed: 5,
            range: 6,
            threatRange: 8,
            movementSpeed: 3,
            attackPattern: .tether(effectName: "goosey")
            //attackPattern: .blast(radius: 1, projectileName: "fireball", friendlyFire: false)
        ),
        
        //archer
        "Demon": UnitBlueprint(
            name: "Demon",
            maxHP: 20,
            attack: 1,
            attackSpeed: 5,
            range: 1,
            threatRange: 8,
            movementSpeed: 3,
            attackPattern: .aura(radius: 2, effectName: "laser", isTethered: true)
        )
        
    ]
    
}
