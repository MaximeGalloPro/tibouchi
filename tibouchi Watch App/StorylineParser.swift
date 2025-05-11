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
            return "L'étape \(index + 1) ne contient aucun choix."
        }
    }
}

// MARK: - Parseur principal

func parseStoryline(from jsonData: Data) throws -> Storyline {
    print("[StorylineParser] Tentative de décodage du JSON:")
    if let jsonString = String(data: jsonData, encoding: .utf8) {
        print(jsonString)
    } else {
        print("[StorylineParser] Impossible de convertir les données en String.")
    }
    let decoder = JSONDecoder()
    
    do {
        let storyline = try decoder.decode(Storyline.self, from: jsonData)
        print("[StorylineParser] Décodage réussi. Storyline: \(storyline.title)")
        
        guard !storyline.title.isEmpty else {
            print("[StorylineParser] Erreur: titre manquant.")
            throw StorylineParseError.missingKey("title")
        }
        
        let allowedActions = ["nourrir", "abreuver", "aventure", "amour"]
        guard allowedActions.contains(storyline.actionType.rawValue) else {
            print("[StorylineParser] Erreur: actionType invalide: \(storyline.actionType.rawValue)")
            throw StorylineParseError.invalidType("actionType")
        }
        
        guard !storyline.steps.isEmpty else {
            print("[StorylineParser] Erreur: aucune étape trouvée.")
            throw StorylineParseError.emptySteps
        }
        
        for (index, step) in storyline.steps.enumerated() {
            guard !step.prompt.isEmpty else {
                print("[StorylineParser] Erreur: prompt manquant à l'étape \(index + 1)")
                throw StorylineParseError.missingKey("prompt in step \(index + 1)")
            }
            guard !step.choices.isEmpty else {
                print("[StorylineParser] Erreur: aucun choix à l'étape \(index + 1)")
                throw StorylineParseError.emptyChoicesInStep(index)
            }
            for choice in step.choices {
                guard !choice.text.isEmpty else {
                    print("[StorylineParser] Erreur: texte du choix manquant à l'étape \(index + 1)")
                    throw StorylineParseError.missingKey("text in choice (step \(index + 1))")
                }
                guard !choice.consequence.isEmpty else {
                    print("[StorylineParser] Erreur: conséquence du choix manquante à l'étape \(index + 1)")
                    throw StorylineParseError.missingKey("consequence in choice (step \(index + 1))")
                }
                if (choice.gaugeImpact.faim < -10 || choice.gaugeImpact.faim > 10) ||
                   (choice.gaugeImpact.soif < -10 || choice.gaugeImpact.soif > 10) ||
                   (choice.gaugeImpact.mental < -10 || choice.gaugeImpact.mental > 10) {
                    print("[StorylineParser] Erreur: valeur de gaugeImpact hors limites à l'étape \(index + 1)")
                    throw StorylineParseError.invalidType("gaugeImpact values in choice (step \(index + 1))")
                }
            }
        }
        
        return storyline
    } catch let decodingError {
        print("[StorylineParser] Décodage JSON échoué : \(decodingError.localizedDescription)")
        throw StorylineParseError.invalidJSON
    }
}
