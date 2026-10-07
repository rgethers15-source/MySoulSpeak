import SwiftUI

/// TutorialGateView — Wraps any section view.
/// Shows tutorial on first open, then the actual content.
/// Tutorial only plays ONCE per section (persisted via AppStorage).
struct TutorialGateView<Content: View>: View {
    let tutorial: TutorialType
    let content: () -> Content
    
    @AppStorage private var hasSeenTutorial: Bool
    @State private var showTutorial: Bool
    
    init(tutorial: TutorialType, @ViewBuilder content: @escaping () -> Content) {
        self.tutorial = tutorial
        self.content = content
        let key = "hasSeenTutorial_\(tutorial.title)"
        self._hasSeenTutorial = AppStorage(wrappedValue: false, key)
        self._showTutorial = State(initialValue: !UserDefaults.standard.bool(forKey: key))
    }
    
    var body: some View {
        ZStack {
            content()
            
            if showTutorial && !hasSeenTutorial {
                TutorialView(tutorial: tutorial, onComplete: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showTutorial = false
                        hasSeenTutorial = true
                    }
                })
                .transition(.opacity)
                .zIndex(999)
            }
        }
    }
}
