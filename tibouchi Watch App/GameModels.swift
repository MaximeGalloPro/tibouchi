import Foundation

// MARK: - Core Enums

enum ActionType: String, Codable {
    case nourrir
    case abreuver
    case aventure
    case amour
}

enum GaugeType: String, Codable {
    case faim
    case soif
    case mental
}

enum CharacterType: String, Codable {
    case tibouchi
    case tibizou
    case ptibou
}

enum Outcome: Codable {
    case survive
    case die(reason: String)
    case returnHome
    case nextStep
}

// MARK: - Core Gameplay Structs

/// État des jauges d'un personnage
struct GaugeState: Codable {
    var faim: Int
    var soif: Int
    var mental: Int
}

/// Trait ou compétence spéciale gagnée
struct Trait: Codable {
    let id: String
    let name: String
    let description: String
}

/// Objet achetable ou trouvé
struct Item: Codable {
    let id: String
    let name: String
    let description: String
    let protectsAgainst: String
}

// MARK: - État d'un personnage (Tibouchi, Tibizou, Ptibou)

struct CharacterState: Codable {
    let type: CharacterType
    var isAlive: Bool
    var gauges: GaugeState
    var traits: [Trait]
    var inventory: [Item]
}

// MARK: - Storyline Structs

/// Conséquence d'un choix
struct Choice: Codable {
    let text: String
    let consequence: String
    let gaugeImpact: GaugeState
    let outcome: Outcome
    let gainTrait: Trait?
    let requiredItem: String? // ID d’objet nécessaire pour survivre à un danger
}

/// Une étape d'une storyline
struct StoryStep: Codable {
    let prompt: String
    let choices: [Choice]
}

/// Une storyline complète associée à une action
struct Storyline: Codable {
    let id: UUID
    let title: String
    let actionType: ActionType
    let steps: [StoryStep]
}

// MARK: - État global du jeu

struct GameState: Codable {
    var characters: [CharacterState]
    var coins: Int
    var daysSurvived: Int
}
