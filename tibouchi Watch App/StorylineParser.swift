import Foundation

// MARK: - Erreurs personnalisées

enum StorylineParseError: Error, LocalizedError {
    case invalidJSON
    case missingKey(String)
    case invalidType(String)
    case emptySteps
    case emptyChoicesInStep(Int)

    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Le JSON est invalide ou ne peut pas être décodé."
        case .missingKey(let key):
            return "Clé manquante ou valeur nulle pour la clé : \(key)."
        case .invalidType(let key):
            return "Type invalide pour la clé : \(key)."
        case .emptySteps:
            return "Aucune étape trouvée dans la storyline."
        case .emptyChoicesInStep(let index):
            return "L’étape \(index + 1) ne contient aucun choix."
        }
    }
}

// MARK: - Parseur principal

func parseStoryline(from jsonData: Data) throws -> Storyline {
    let decoder = JSONDecoder()
    
    do {
        let storyline = try decoder.decode(Storyline.self, from: jsonData)
        
        guard !storyline.title.isEmpty else {
            throw StorylineParseError.missingKey("title")
        }
        
        let allowedActions = ["nourrir", "abreuver", "aventure", "amour"]
        guard allowedActions.contains(storyline.actionType.rawValue) else {
            throw StorylineParseError.invalidType("actionType")
        }
        
        guard !storyline.steps.isEmpty else {
            throw StorylineParseError.emptySteps
        }
        
        for (index, step) in storyline.steps.enumerated() {
            guard !step.prompt.isEmpty else {
                throw StorylineParseError.missingKey("prompt in step \(index + 1)")
            }
            guard !step.choices.isEmpty else {
                throw StorylineParseError.emptyChoicesInStep(index)
            }
            for choice in step.choices {
                guard !choice.text.isEmpty else {
                    throw StorylineParseError.missingKey("text in choice (step \(index + 1))")
                }
                guard !choice.consequence.isEmpty else {
                    throw StorylineParseError.missingKey("consequence in choice (step \(index + 1))")
                }
                if (choice.gaugeImpact.faim < -10 || choice.gaugeImpact.faim > 10) ||
                   (choice.gaugeImpact.soif < -10 || choice.gaugeImpact.soif > 10) ||
                   (choice.gaugeImpact.mental < -10 || choice.gaugeImpact.mental > 10) {
                    throw StorylineParseError.invalidType("gaugeImpact values in choice (step \(index + 1))")
                }
            }
        }
        
        return storyline
    } catch let decodingError {
        print("Décodage JSON échoué : \(decodingError.localizedDescription)")
        throw StorylineParseError.invalidJSON
    }
}
