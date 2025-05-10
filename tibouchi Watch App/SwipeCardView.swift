import SwiftUI

struct SwipeCardView: View {
    let question: String
    let leftPreview: String
    let rightPreview: String
    let onSwipe: (Bool) -> Void // true = droite, false = gauche
    
    @State private var dragAmount = CGSize.zero
    @State private var isDragging = false
    
    // Valeurs fixes pour éviter les calculs directs
    private let cardHeight: CGFloat = 90
    private let threshold: CGFloat = 40
    private let animationDistance: CGFloat = 200
    private let opacityThreshold: CGFloat = 80
    
    // Fonctions auxiliaires pour éviter les opérations ambiguës
    private func calculateOpacity(_ value: CGFloat) -> Double {
        let absValue = value < 0 ? -value : value
        let ratio = absValue >= opacityThreshold ? 1.0 : Double(absValue / opacityThreshold)
        return 1.0 - ratio
    }
    
    private func calculatePreviewOpacity(_ value: CGFloat) -> Double {
        let absValue = value < 0 ? -value : value
        return absValue >= opacityThreshold ? 1.0 : Double(absValue / opacityThreshold)
    }
    
    var body: some View {
        VStack {
            ZStack {
                // Carte
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 1, green: 1, blue: 1))
                    .shadow(radius: 3)
                
                VStack {
                    // Question
                    Text(question)
                        .foregroundColor(Color.black)
                        .multilineTextAlignment(.center)
                        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                        .opacity(calculateOpacity(dragAmount.width))
                    
                    // Prévisualisations gauche/droite
                    if dragAmount.width > 10 {
                        Text(rightPreview)
                            .foregroundColor(Color(red: 0, green: 0.8, blue: 0))
                            .opacity(calculatePreviewOpacity(dragAmount.width))
                    } else if dragAmount.width < -10 {
                        Text(leftPreview)
                            .foregroundColor(Color(red: 0.8, green: 0, blue: 0))
                            .opacity(calculatePreviewOpacity(-dragAmount.width))
                    }
                }
                .padding(6)
            }
            .frame(height: cardHeight)
            .offset(x: dragAmount.width, y: 0)
            .rotationEffect(Angle(degrees: Double(dragAmount.width) * 0.05))
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        isDragging = true
                        dragAmount = gesture.translation
                    }
                    .onEnded { _ in
                        isDragging = false
                        if dragAmount.width > threshold {
                            // Droite
                            withAnimation {
                                dragAmount.width = animationDistance
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onSwipe(true)
                                dragAmount = CGSize.zero
                            }
                        } else if dragAmount.width < -threshold {
                            // Gauche
                            withAnimation {
                                dragAmount.width = -animationDistance
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onSwipe(false)
                                dragAmount = CGSize.zero
                            }
                        } else {
                            // Retour
                            withAnimation {
                                dragAmount = CGSize.zero
                            }
                        }
                    }
            )
        }
        .padding(6)
    }
}
