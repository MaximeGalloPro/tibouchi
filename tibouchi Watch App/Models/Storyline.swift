import Foundation

struct Storyline: Codable {
    let id: String
    let title: String
    let actionType: String
    let steps: [StoryStep]
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case actionType = "action_type"
        case steps
    }
}

struct StoryStep: Codable {
    let prompt: String
    let choices: [Choice]
}

struct Choice: Codable {
    let text: String
    let consequence: String
    let gaugeImpact: GaugeImpact
    let outcome: String
    let gainTrait: String?
    let requiredItem: String?
    
    enum CodingKeys: String, CodingKey {
        case text
        case consequence
        case gaugeImpact = "gaugeImpact"
        case outcome
        case gainTrait = "gainTrait"
        case requiredItem = "requiredItem"
    }
}

struct GaugeImpact: Codable {
    let faim: Int
    let soif: Int
    let mental: Int
} 