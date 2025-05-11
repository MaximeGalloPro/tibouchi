import Foundation

class OpenAIService {
    static let shared = OpenAIService()
    
    private var apiKey: String {
        // TODO: Remplacer par votre clé API OpenAI
        // Pour le développement, vous pouvez utiliser une clé de test
        // En production, utilisez un système de configuration sécurisé
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "YOUR_API_KEY"
    }
    
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    private init() {}
    
    func generateStoryline(with prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let messages: [[String: String]] = [
            ["role": "system", "content": "Tu es un créateur d'histoires pour Tibouchi. Réponds uniquement avec le JSON de la storyline, sans aucun autre texte."],
            ["role": "user", "content": prompt]
        ]
        
        let payload: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "temperature": 0.8
        ]
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Réponse HTTP invalide"])))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Erreur HTTP: \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "OpenAIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Aucune donnée reçue"])))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let choices = json?["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "OpenAIService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Format de réponse invalide"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
