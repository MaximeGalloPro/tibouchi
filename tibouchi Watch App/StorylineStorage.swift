import Foundation

class StorylineStorage {
    static let shared = StorylineStorage()

    private let fileManager = FileManager.default

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func saveStoryline(_ storyline: Storyline) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]

        let data = try encoder.encode(storyline)

        let filename = "\(storyline.title.slugged())-\(storyline.id.uuidString).json"
        let fileURL = documentsURL.appendingPathComponent(filename)

        try data.write(to: fileURL, options: [.atomicWrite])
        print("✅ Storyline sauvegardée à : \(fileURL.path)")
    }
}

// Extension pour transformer un titre en slug (ex: "La Mare Suspecte" -> "la-mare-suspecte")
extension String {
    func slugged() -> String {
        self.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: "-")
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}
