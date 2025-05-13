import SwiftUI

struct SwipeCardView: View {
    let storyline: Storyline
    let currentStep: Int
    let onSwipe: (Choice) -> Void
    
    @State private var dragAmount = CGSize.zero
    @State private var isDragging = false
    
    // Valeurs fixes pour éviter les calculs directs
    private let threshold: CGFloat = 40
    private let animationDistance: CGFloat = 200
    private let opacityThreshold: CGFloat = 40
    
    // Fonctions auxiliaires pour éviter les opérations ambiguës
    private func calculateOpacity(_ value: CGFloat) -> Double {
        let absValue = value < 0 ? -value : value
        let ratio = absValue >= opacityThreshold ? 1.0 : Double(absValue / opacityThreshold)
        return max(1.0 - ratio, 0.4)
    }
    
    private func calculatePreviewOpacity(_ value: CGFloat) -> Double {
        let absValue = value < 0 ? -value : value
        return absValue >= opacityThreshold ? 1.0 : Double(absValue / opacityThreshold)
    }
    
    private var currentStepData: StoryStep? {
        guard currentStep < storyline.steps.count else { return nil }
        return storyline.steps[currentStep]
    }
    
    var body: some View {
        VStack {
            ZStack {
                // Carte
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 1, green: 1, blue: 1))
                    .shadow(radius: 3)
                
                VStack {
                    // Question toujours visible en haut
                    if let step = currentStepData {
                        Text(step.prompt)
                            .font(.system(size: 9))
                            .foregroundColor(Color.black)
                            .multilineTextAlignment(.center)
                            .padding(EdgeInsets(top: 3, leading: 3, bottom: 3, trailing: 3))
                            .padding(.top, 12)
                            .opacity(calculateOpacity(dragAmount.width))
                        
                        Spacer(minLength: 2)
                        // Prévisualisation du choix, toujours au même endroit
                        Group {
                            if dragAmount.width > 10 {
                                Text(step.choices[1].text)
                                    .font(.system(size: 9))
                                    .foregroundColor(.black)
                                    .opacity(calculatePreviewOpacity(dragAmount.width))
                                    .padding(.bottom, 6)
                            } else if dragAmount.width < -10 {
                                Text(step.choices[0].text)
                                    .font(.system(size: 9))
                                    .foregroundColor(.black)
                                    .opacity(calculatePreviewOpacity(-dragAmount.width))
                                    .padding(.bottom, 6)
                            } else {
                                Text(" ")
                                    .font(.system(size: 9))
                                    .opacity(0)
                                    .padding(.bottom, 6)
                            }
                        }
                    }
                }
                .padding(6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        if let step = currentStepData {
                            if dragAmount.width > threshold {
                                // Droite
                                withAnimation {
                                    dragAmount.width = animationDistance
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    onSwipe(step.choices[1])
                                    dragAmount = CGSize.zero
                                }
                            } else if dragAmount.width < -threshold {
                                // Gauche
                                withAnimation {
                                    dragAmount.width = -animationDistance
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    onSwipe(step.choices[0])
                                    dragAmount = CGSize.zero
                                }
                            } else {
                                // Retour
                                withAnimation {
                                    dragAmount = CGSize.zero
                                }
                            }
                        }
                    }
            )
        }
        .padding(6)
    }
}
