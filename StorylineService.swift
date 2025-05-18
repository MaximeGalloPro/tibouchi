import Foundation

public class StorylineService {
    static let shared = StorylineService()
    
    private init() {}
    
    func loadStoryline(from filename: String) -> Storyline? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("Could not find file: \(filename).json")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(Storyline.self, from: data)
        } catch {
            print("Error loading storyline: \(error)")
            return nil
        }
    }
    
    func loadAllStorylines() -> [Storyline] {
        guard let bundlePath = Bundle.main.resourcePath else { return [] }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
            let jsonFiles = files.filter { $0.hasSuffix(".json") }
            
            return jsonFiles.compactMap { filename in
                let name = (filename as NSString).deletingPathExtension
                return loadStoryline(from: name)
            }
        } catch {
            print("Error loading storylines: \(error)")
            return []
        }
    }
} 
