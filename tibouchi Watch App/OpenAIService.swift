import Foundation

class OpenAIService {
    static let shared = OpenAIService()
    private let apiKey = "TON_API_KEY"
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    func generateStoryline(with prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let messages: [[String: String]] = [
            ["role": "system", "content": "Tu es un créateur d'histoires pour Tibouchi."],
            ["role": "user", "content": prompt]
        ]
        
        let payload: [String: Any] = [
            "model": "gpt-4",
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
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1)))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let choices = json?["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "InvalidResponse", code: -2)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
