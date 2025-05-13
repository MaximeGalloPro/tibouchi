//
//  ContentView.swift
//  tibouchi Watch App
//
//  Created by maxime gallo on 10/05/2025.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var currentStep = 0
    @State private var storyline: Storyline?
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let storyline = storyline {
                SwipeCardView(
                    storyline: storyline,
                    currentStep: currentStep,
                    onSwipe: { choice in
                        print("Choix sélectionné : \(choice.text)")
                        currentStep += 1
                    }
                )
            } else {
                Text("Aucune storyline disponible")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            // Récupérer l'URL du dossier "outputs" dans le bundle
            if let outputsURL = Bundle.main.url(forResource: "outputs", withExtension: nil) {
                let fileManager = FileManager.default
                if let files = try? fileManager.contentsOfDirectory(at: outputsURL, includingPropertiesForKeys: nil) {
                    // Filtrer les fichiers JSON
                    let jsonFiles = files.filter { $0.pathExtension == "json" }
                    if let firstJSON = jsonFiles.first {
                        // Enlever l'extension et le chemin pour obtenir le nom du fichier sans extension
                        let filename = firstJSON.deletingPathExtension().lastPathComponent
                        if let loadedStoryline = StorylineService.shared.loadStoryline(from: "outputs/\(filename)") {
                            storyline = loadedStoryline
                            print("📚 Storyline chargée : \(filename)")
                        } else {
                            print("⚠️ Impossible de charger la storyline : \(filename)")
                        }
                    } else {
                        print("⚠️ Aucun fichier JSON trouvé dans outputs")
                    }
                }
            }
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
