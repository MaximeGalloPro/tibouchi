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
    let outcome: String
    let gainTrait: Trait?
    let requiredItem: String? // ID d'objet nécessaire pour survivre à un danger
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let idString = try container.decode(String.self, forKey: .id)
        print("📝 Tentative de décodage de l'ID: '\(idString)'")
        
        if let uuid = UUID(uuidString: idString) {
            print("✅ UUID valide créé: \(uuid)")
            id = uuid
        } else {
            print("❌ Échec de la création de l'UUID à partir de: '\(idString)'")
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid UUID string: '\(idString)'")
        }
        title = try container.decode(String.self, forKey: .title)
        actionType = try container.decode(ActionType.self, forKey: .actionType)
        steps = try container.decode([StoryStep].self, forKey: .steps)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case actionType = "action_type"
        case steps
    }
}

// MARK: - État global du jeu

struct GameState: Codable {
    var characters: [CharacterState]
    var coins: Int
    var daysSurvived: Int
}
