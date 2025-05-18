import SwiftUI

struct CharacterView: View {
    @ObservedObject var pet: Pet
    @State private var showSwipeCard = false

    var body: some View {
        ZStack {
            // Corps
            Circle()
                .fill(Color.blue)
                .frame(width: 150, height: 150)
            
            // Yeux
            HStack(spacing: 30) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .fill(Color.black)
                            .frame(width: pet.isHappy ? 15 : 10, height: pet.isHappy ? 15 : 10)
                    )
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .fill(Color.black)
                            .frame(width: pet.isHappy ? 15 : 10, height: pet.isHappy ? 15 : 10)
                    )
            }
            
            // Bouche (qui change selon l'état)
            if pet.isHappy {
                Path { path in
                    path.move(to: CGPoint(x: 50, y: 100))
                    path.addQuadCurve(to: CGPoint(x: 100, y: 100), control: CGPoint(x: 75, y: 125))
                }
                .stroke(Color.black, lineWidth: 3)
            } else {
                Path { path in
                    path.move(to: CGPoint(x: 50, y: 100))
                    path.addQuadCurve(to: CGPoint(x: 100, y: 100), control: CGPoint(x: 75, y: 85))
                }
                .stroke(Color.black, lineWidth: 3)
            }

            // Bouton flottant en bas
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showSwipeCard = true
                    }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.accentColor)
                            .shadow(radius: 2)
                    }
                    .padding(.bottom, 8)
                    .padding(.trailing, 8)
                }
            }
        }
        .fullScreenCover(isPresented: $showSwipeCard) {
            // Remplace par la vraie initialisation de SwipeCardView avec une storyline réelle
            ContentView()
        }
    }
} 