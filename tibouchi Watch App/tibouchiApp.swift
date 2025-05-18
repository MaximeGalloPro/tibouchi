//
//  tibouchiApp.swift
//  tibouchi Watch App
//
//  Created by maxime gallo on 10/05/2025.
//

import SwiftUI

class Pet: ObservableObject {
    @Published var isHappy: Bool = true
}

@main
struct tibouchiApp: App {
    @StateObject var pet = Pet()
    var body: some Scene {
        WindowGroup {
            CharacterView(pet: pet)
        }
    }
}
