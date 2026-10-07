import SwiftUI
import SceneKit

// MARK: - Floating Damage Number Model
struct FloatingDamageNumber: Identifiable {
    let id = UUID()
    let value: Int
    let position: CGPoint
    let rotation: Double
    var opacity: Double = 1.0
}

// MARK: - Destruction Phase
enum DestructionPhase: String {
    case idle = ""
    case warmingUp = "WARMING UP"
    case gettingIntense = "GETTING INTENSE"
    case totalChaos = "TOTAL CHAOS"
    case maximumDestruction = "MAXIMUM DESTRUCTION"
    
    var color: Color {
        switch self {
        case .idle: return .clear
        case .warmingUp: return .yellow
        case .gettingIntense: return .orange
        case .totalChaos: return .red
        case .maximumDestruction: return .white
        }
    }
}

// MARK: - Combo Tier
enum ComboTier {
    case none
    case combo
    case rampage
    case unstoppable
    case godlike
    
    var text: String {
        switch self {
        case .none: return ""
        case .combo: return "COMBO"
        case .rampage: return "RAMPAGE"
        case .unstoppable: return "UNSTOPPABLE"
        case .godlike: return "GODLIKE"
        }
    }
    
    var color: Color {
        switch self {
        case .none: return .clear
        case .combo: return .yellow
        case .rampage: return .orange
        case .unstoppable: return .red
        case .godlike: return .white
        }
    }
    
    var glowColor: Color {
        switch self {
        case .none: return .clear
        case .combo: return .yellow.opacity(0.6)
        case .rampage: return .orange.opacity(0.7)
        case .unstoppable: return .red.opacity(0.8)
        case .godlike: return .white.opacity(0.9)
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .none: return 0
        case .combo: return 32
        case .rampage: return 38
        case .unstoppable: return 44
        case .godlike: return 52
        }
    }
}

// MARK: - Ember Particle Model
struct RageEmberParticle: Identifiable {
    let id = UUID()
    var xOffset: CGFloat
    var yOffset: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: Double
}

// MARK: - Leaf Particle Model
struct LeafParticle: Identifiable {
    let id = UUID()
    var xOffset: CGFloat
    var yOffset: CGFloat
    var rotation: Double
    var opacity: Double
}


// MARK: - Elite Destruction Room View
/// The ultimate rage room HUD experience. Features cinematic intro, screen effects,
/// tiered combo system, animated rage meter with fire particles, tactical HUD overlay,
/// destruction phase indicators, enhanced gesture recognition, and premium release flow.
struct DestructionRoomView: View {
    let onRelease: () -> Void
    
    // MARK: - Local State
    @State private var selectedTool: RageTool = .fists
    @State private var showRelease = false
    @State private var selectedSprayColor: Color = .red
    @State private var showCombo = false
    @State private var lastHitTime: Date = Date()
    @State private var hitCount: Int = 0
    
    // MARK: - Animation State
    @State private var comboScale: CGFloat = 0
    @State private var comboRotation: Double = 0
    @State private var comboOpacity: Double = 0
    @State private var previousComboTier: ComboTier = .none
    @State private var damageNumbers: [FloatingDamageNumber] = []
    @State private var rageMeterShake: CGFloat = 0
    @State private var rageMeterPulse: CGFloat = 1.0
    @State private var lastMilestone: Int = 0
    @State private var milestoneFlash: Bool = false
    @State private var emberParticles: [RageEmberParticle] = []
    @State private var leafParticles: [LeafParticle] = []
    @State private var toolSwitchAnimation: Bool = false
    @State private var previousTool: RageTool = .fists
    
    // MARK: - Destruction Phase State
    @State private var currentPhase: DestructionPhase = .idle
    @State private var showPhaseText: Bool = false
    @State private var phaseTextScale: CGFloat = 0
    @State private var phaseTextOpacity: Double = 0
    
    // MARK: - Cinematic Intro State
    @State private var introActive: Bool = true
    @State private var introTextOpacity: Double = 0
    @State private var introTextScale: CGFloat = 0.5
    @State private var hudOpacity: Double = 0
    @State private var toolSelectorOffset: CGFloat = 200
    @State private var cornerBracketOpacity: Double = 0
    @State private var scanLineOffset: CGFloat = 0
    
    // MARK: - Release Button State
    @State private var releaseButtonScale: CGFloat = 0
    @State private var releaseGlowOpacity: Double = 0
    @State private var releaseBreathScale: CGFloat = 1.0
    
    // MARK: - Gesture State
    @State private var isCharging: Bool = false
    @State private var chargeLevel: Double = 0
    @State private var chargeTimer: Timer? = nil
    
    // MARK: - Lifecycle Management
    @State private var emberTimer: Timer? = nil
    @State private var leafTimer: Timer? = nil
    @State private var viewActive: Bool = true
    
    // MARK: - Vignette & Effects
    @State private var vignetteIntensity: Double = 0.3
    @State private var borderPulseOpacity: Double = 0
    @State private var backgroundDarkness: Double = 0
    
    // MARK: - HUD Counters
    @State private var displayedHitCount: Int = 0
    @State private var hitCounterSpring: CGFloat = 1.0
    
    @StateObject private var sceneManager = RageRoomSceneManager()
    
    // MARK: - Constants
    private let sprayColors: [(Color, UIColor, String)] = [
        (.red, UIColor.red, "Red"),
        (.blue, UIColor.blue, "Blue"),
        (.green, UIColor.green, "Green"),
        (.yellow, UIColor.yellow, "Yellow"),
        (.purple, UIColor.purple, "Purple"),
        (.white, UIColor.white, "White"),
        (.orange, UIColor.orange, "Orange"),
    ]
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Layer 0: Progressive background darkening
            Color.black
                .opacity(backgroundDarkness)
                .ignoresSafeArea()
            
            // Layer 1: 3D SceneKit View with camera shake offset
            sceneKitLayer
            
            // Layer 2: Screen effects (flash, vignette, borders)
            screenEffectsLayer
            
            // Layer 3: Slow motion overlay
            slowMotionOverlay
            
            // Layer 4: Scan line ambient effect
            scanLineOverlay
            
            // Layer 5: Main HUD
            mainHUDLayer
                .opacity(hudOpacity)
            
            // Layer 6: Combo display
            comboDisplayLayer
            
            // Layer 7: Floating damage numbers
            damageNumbersLayer
            
            // Layer 8: Phase announcement
            phaseAnnouncementLayer
            
            // Layer 9: Corner tactical brackets
            cornerBracketsLayer
                .opacity(cornerBracketOpacity)
            
            // Layer 10: Cinematic intro overlay
            if introActive {
                cinematicIntroLayer
            }
        }
        .onAppear {
            sceneManager.setupRoom()
            startEmberSystem()
            startScanLineAnimation()
            playCinematicIntro()
        }
        .onDisappear {
            viewActive = false
            emberTimer?.invalidate()
            emberTimer = nil
            leafTimer?.invalidate()
            leafTimer = nil
            chargeTimer?.invalidate()
            chargeTimer = nil
        }
        .onChange(of: sceneManager.comboCount) { _, newValue in
            handleComboChange(newValue)
        }
        .onChange(of: sceneManager.destructionLevel) { _, newValue in
            handleDestructionChange(newValue)
        }
        .onChange(of: sceneManager.screenFlashOpacity) { _, newValue in
            // Screen flash is read directly from sceneManager in the overlay
        }
    }
}


// MARK: - SceneKit Layer
extension DestructionRoomView {
    private var sceneKitLayer: some View {
        VentRoomSceneView(
            sceneManager: sceneManager,
            selectedTool: selectedTool,
            onTap: { _ in
                performHit()
            },
            onDoubleTap: {
                performRapidFire()
            },
            onSwipe: { _, velocity in
                let gen = UIImpactFeedbackGenerator(style: .heavy)
                gen.impactOccurred()
            },
            onPinch: { _ in }
        )
        .ignoresSafeArea()
        .offset(x: sceneManager.cameraShakeOffset.width,
                y: sceneManager.cameraShakeOffset.height)
    }
}

// MARK: - Screen Effects Layer
extension DestructionRoomView {
    private var screenEffectsLayer: some View {
        ZStack {
            // Full screen flash
            if let flashColor = sceneManager.screenFlashColor {
                Color(flashColor)
                    .opacity(sceneManager.screenFlashOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .animation(.easeOut(duration: 0.15), value: sceneManager.screenFlashOpacity)
            }
            
            // Vignette overlay - darkens edges, intensifies with destruction
            RadialGradient(
                gradient: Gradient(colors: [
                    .clear,
                    .clear,
                    Color.black.opacity(vignetteIntensity)
                ]),
                center: .center,
                startRadius: 150,
                endRadius: 450
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            // Red pulse border on high combos
            RoundedRectangle(cornerRadius: 0)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.red.opacity(borderPulseOpacity),
                            Color.orange.opacity(borderPulseOpacity * 0.7),
                            Color.red.opacity(borderPulseOpacity)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            // Charge indicator overlay
            if isCharging {
                chargeOverlay
            }
        }
    }
    
    private var chargeOverlay: some View {
        ZStack {
            // Radial charge ring
            Circle()
                .trim(from: 0, to: CGFloat(chargeLevel))
                .stroke(
                    AngularGradient(
                        colors: [.orange, .red, .yellow, .orange],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .shadow(color: .orange.opacity(0.8), radius: 8)
            
            Text("CHARGING")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(.orange)
                .offset(y: 50)
        }
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Slow Motion Overlay
extension DestructionRoomView {
    private var slowMotionOverlay: some View {
        ZStack {
            if sceneManager.isSlowMotion {
                // Blue tint
                Color.blue.opacity(0.08)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                // Motion lines - horizontal streaks
                ForEach(0..<8, id: \.self) { i in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.15), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .offset(y: CGFloat(i) * 100 - 350)
                        .offset(x: CGFloat.random(in: -50...50))
                }
                
                // Corner time indicator
                VStack {
                    HStack {
                        Spacer()
                        Text("SLOW-MO")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.cyan.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.cyan.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.trailing, 60)
                            .padding(.top, 100)
                    }
                    Spacer()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: sceneManager.isSlowMotion)
    }
}

// MARK: - Scan Line Overlay
extension DestructionRoomView {
    private var scanLineOverlay: some View {
        GeometryReader { geo in
            VStack(spacing: 3) {
                ForEach(0..<Int(geo.size.height / 3), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.012))
                        .frame(height: 1)
                }
            }
            .offset(y: scanLineOffset)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}


// MARK: - Main HUD Layer
extension DestructionRoomView {
    private var mainHUDLayer: some View {
        VStack(spacing: 0) {
            // Top HUD bar
            topHUDBar
                .padding(.top, 60)
            
            Spacer()
            
            // Instruction text (fades after first hit)
            if hitCount == 0 && !introActive {
                instructionText
            }
            
            // Spray color picker
            if selectedTool == .spray {
                sprayColorPicker
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            
            // Tool selector
            toolSelector
                .offset(y: toolSelectorOffset)
            
            // Release button
            if showRelease {
                releaseButton
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.3).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
    }
    
    // MARK: - Top HUD Bar
    private var topHUDBar: some View {
        HStack(alignment: .top, spacing: 12) {
            // Rage meter (left)
            rageMeter
            
            Spacer()
            
            // Hit counter + destruction % (right)
            VStack(alignment: .trailing, spacing: 6) {
                hitCounter
                destructionPercentage
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Rage Meter (Fire-shaped)
    private var rageMeter: some View {
        HStack(spacing: 10) {
            // Flame meter container
            ZStack(alignment: .bottom) {
                // Outer flame shape (background)
                flameMeterShape
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 28, height: 100)
                    .overlay(
                        flameMeterShape
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                
                // Fire fill (animated gradient)
                flameMeterShape
                    .fill(
                        LinearGradient(
                            colors: fireFillColors,
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 28, height: 100 * CGFloat(sceneManager.destructionLevel))
                    .shadow(color: .orange.opacity(0.6), radius: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: sceneManager.destructionLevel)
                
                // Milestone burst flash
                if milestoneFlash {
                    flameMeterShape
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 28, height: 100)
                        .transition(.opacity)
                }
                
                // Ember particles rising from meter
                ForEach(emberParticles) { ember in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.yellow, .orange, .red.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: ember.size
                            )
                        )
                        .frame(width: ember.size, height: ember.size)
                        .offset(x: ember.xOffset, y: ember.yOffset)
                        .opacity(ember.opacity)
                }
            }
            .frame(width: 28, height: 100)
            .offset(x: rageMeterShake)
            .scaleEffect(rageMeterPulse)
            .animation(.spring(response: 0.1, dampingFraction: 0.3), value: rageMeterShake)
            
            // Rage text + percentage
            VStack(alignment: .leading, spacing: 4) {
                Text("RAGE")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.orange)
                
                Text("\(Int(sceneManager.destructionLevel * 100))%")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(rageTextColor)
                    .shadow(color: rageTextColor.opacity(0.5), radius: 4)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: sceneManager.destructionLevel)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [.orange.opacity(0.3), .red.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private var fireFillColors: [Color] {
        let level = sceneManager.destructionLevel
        if level >= 0.75 {
            return [Color(red: 0.8, green: 0, blue: 0), .red, .orange, .yellow, .white]
        } else if level >= 0.5 {
            return [Color(red: 0.6, green: 0, blue: 0), .red, .orange, .yellow]
        } else {
            return [Color(red: 0.4, green: 0.1, blue: 0), .orange, .yellow]
        }
    }
    
    private var rageTextColor: Color {
        let level = sceneManager.destructionLevel
        if level >= 0.75 { return .red }
        else if level >= 0.5 { return .orange }
        else { return .yellow }
    }
    
    private var flameMeterShape: some Shape {
        RoundedRectangle(cornerRadius: 8)
    }
    
    // MARK: - Hit Counter (Mechanical feel)
    private var hitCounter: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 11))
                .foregroundColor(.yellow)
            
            Text("\(hitCount)")
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(.white)
                .scaleEffect(y: hitCounterSpring)
                .animation(.spring(response: 0.15, dampingFraction: 0.4), value: hitCounterSpring)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.2), value: hitCount)
            
            Text("HITS")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Destruction Percentage
    private var destructionPercentage: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(destructionDotColor)
                .frame(width: 6, height: 6)
                .shadow(color: destructionDotColor, radius: 3)
            
            Text("DMG")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
            
            Text("\(Int(sceneManager.destructionLevel * 100))%")
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: sceneManager.destructionLevel)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.6))
        )
    }
    
    private var destructionDotColor: Color {
        let level = sceneManager.destructionLevel
        if level >= 0.75 { return .red }
        else if level >= 0.5 { return .orange }
        else if level >= 0.25 { return .yellow }
        else { return .green }
    }
}


// MARK: - Tool Selector
extension DestructionRoomView {
    private var toolSelector: some View {
        HStack(spacing: 14) {
            ForEach(RageTool.allCases, id: \.self) { tool in
                Button(action: {
                    switchTool(to: tool)
                }) {
                    VStack(spacing: 5) {
                        ZStack {
                            // Pulsing glow ring for selected tool
                            if selectedTool == tool {
                                Circle()
                                    .stroke(
                                        AngularGradient(
                                            colors: [tool.color, tool.color.opacity(0.3), tool.color],
                                            center: .center
                                        ),
                                        lineWidth: 3
                                    )
                                    .frame(width: 56, height: 56)
                                    .shadow(color: tool.color.opacity(0.6), radius: 8)
                                    .scaleEffect(toolSwitchAnimation && selectedTool == tool ? 1.2 : 1.0)
                                    .opacity(sceneManager.isSlowMotion ? 0.5 : 1.0)
                            }
                            
                            // Tool circle background
                            Circle()
                                .fill(
                                    selectedTool == tool
                                    ? tool.color.opacity(0.35)
                                    : Color.black.opacity(0.6)
                                )
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selectedTool == tool
                                            ? tool.color.opacity(0.8)
                                            : Color.white.opacity(0.15),
                                            lineWidth: selectedTool == tool ? 2 : 1
                                        )
                                )
                            
                            // Tool icon
                            Image(systemName: tool.icon)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(
                                    selectedTool == tool ? .white : .white.opacity(0.5)
                                )
                                .scaleEffect(selectedTool == tool ? 1.1 : 0.9)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTool)
                        }
                        
                        // Tool name
                        Text(tool.rawValue)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(
                                selectedTool == tool ? tool.color : .white.opacity(0.4)
                            )
                        
                        // Power indicator dots
                        HStack(spacing: 2) {
                            ForEach(0..<toolPowerLevel(tool), id: \.self) { _ in
                                Circle()
                                    .fill(tool.color.opacity(selectedTool == tool ? 0.9 : 0.4))
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
        )
        .padding(.bottom, 16)
        .opacity(sceneManager.isSlowMotion ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: sceneManager.isSlowMotion)
    }
    
    private func toolPowerLevel(_ tool: RageTool) -> Int {
        switch tool {
        case .fists: return 2
        case .sledgehammer: return 5
        case .bat: return 4
        case .throwPlates: return 3
        case .spray: return 1
        }
    }
}

// MARK: - Combo Display Layer
extension DestructionRoomView {
    private var comboDisplayLayer: some View {
        ZStack {
            if showCombo && sceneManager.comboCount >= 3 {
                let tier = currentComboTier
                
                VStack(spacing: 4) {
                    // Combo multiplier
                    Text("\(sceneManager.comboCount)x")
                        .font(.system(size: tier.fontSize * 0.6, weight: .black, design: .monospaced))
                        .foregroundColor(tier.color.opacity(0.8))
                    
                    // Tier text
                    Text(tier.text)
                        .font(.system(size: tier.fontSize, weight: .black, design: .rounded))
                        .foregroundColor(tier.color)
                        .shadow(color: tier.glowColor, radius: 12)
                        .shadow(color: tier.glowColor, radius: 24)
                        .overlay(
                            Text(tier.text)
                                .font(.system(size: tier.fontSize, weight: .black, design: .rounded))
                                .foregroundColor(.white.opacity(tier == .godlike ? 0.4 : 0.1))
                                .blur(radius: 2)
                        )
                }
                .scaleEffect(comboScale)
                .rotationEffect(.degrees(comboRotation))
                .opacity(comboOpacity)
                .offset(y: -40)
            }
        }
        .allowsHitTesting(false)
    }
    
    private var currentComboTier: ComboTier {
        let count = sceneManager.comboCount
        if count >= 15 { return .godlike }
        else if count >= 10 { return .unstoppable }
        else if count >= 5 { return .rampage }
        else if count >= 3 { return .combo }
        else { return .none }
    }
}

// MARK: - Damage Numbers Layer
extension DestructionRoomView {
    private var damageNumbersLayer: some View {
        ZStack {
            ForEach(damageNumbers) { number in
                Text("+\(number.value)")
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .orange, radius: 4)
                    .rotationEffect(.degrees(number.rotation))
                    .opacity(number.opacity)
                    .position(number.position)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Phase Announcement Layer
extension DestructionRoomView {
    private var phaseAnnouncementLayer: some View {
        ZStack {
            if showPhaseText {
                VStack(spacing: 8) {
                    // Phase divider line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, currentPhase.color, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 200, height: 2)
                    
                    // Phase text
                    Text(currentPhase.rawValue)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(currentPhase.color)
                        .shadow(color: currentPhase.color.opacity(0.8), radius: 12)
                        .shadow(color: currentPhase.color.opacity(0.4), radius: 24)
                    
                    // Phase divider line bottom
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, currentPhase.color, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 200, height: 2)
                }
                .scaleEffect(phaseTextScale)
                .opacity(phaseTextOpacity)
            }
        }
        .allowsHitTesting(false)
    }
}


// MARK: - Corner Brackets (Tactical HUD)
extension DestructionRoomView {
    private var cornerBracketsLayer: some View {
        GeometryReader { geo in
            let bracketSize: CGFloat = 30
            let bracketWeight: CGFloat = 2
            let padding: CGFloat = 16
            let color = bracketColor
            
            // Top-left bracket
            Path { path in
                path.move(to: CGPoint(x: padding, y: padding + bracketSize))
                path.addLine(to: CGPoint(x: padding, y: padding))
                path.addLine(to: CGPoint(x: padding + bracketSize, y: padding))
            }
            .stroke(color, lineWidth: bracketWeight)
            
            // Top-right bracket
            Path { path in
                path.move(to: CGPoint(x: geo.size.width - padding - bracketSize, y: padding))
                path.addLine(to: CGPoint(x: geo.size.width - padding, y: padding))
                path.addLine(to: CGPoint(x: geo.size.width - padding, y: padding + bracketSize))
            }
            .stroke(color, lineWidth: bracketWeight)
            
            // Bottom-left bracket
            Path { path in
                path.move(to: CGPoint(x: padding, y: geo.size.height - padding - bracketSize))
                path.addLine(to: CGPoint(x: padding, y: geo.size.height - padding))
                path.addLine(to: CGPoint(x: padding + bracketSize, y: geo.size.height - padding))
            }
            .stroke(color, lineWidth: bracketWeight)
            
            // Bottom-right bracket
            Path { path in
                path.move(to: CGPoint(x: geo.size.width - padding - bracketSize, y: geo.size.height - padding))
                path.addLine(to: CGPoint(x: geo.size.width - padding, y: geo.size.height - padding))
                path.addLine(to: CGPoint(x: geo.size.width - padding, y: geo.size.height - padding - bracketSize))
            }
            .stroke(color, lineWidth: bracketWeight)
            
            // Center crosshair (subtle)
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            
            Path { path in
                path.move(to: CGPoint(x: cx - 8, y: cy))
                path.addLine(to: CGPoint(x: cx - 3, y: cy))
                path.move(to: CGPoint(x: cx + 3, y: cy))
                path.addLine(to: CGPoint(x: cx + 8, y: cy))
                path.move(to: CGPoint(x: cx, y: cy - 8))
                path.addLine(to: CGPoint(x: cx, y: cy - 3))
                path.move(to: CGPoint(x: cx, y: cy + 3))
                path.addLine(to: CGPoint(x: cx, y: cy + 8))
            }
            .stroke(Color.white.opacity(0.25), lineWidth: 1)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    private var bracketColor: Color {
        let level = sceneManager.destructionLevel
        if level >= 0.75 { return .red.opacity(0.6) }
        else if level >= 0.5 { return .orange.opacity(0.5) }
        else { return .white.opacity(0.3) }
    }
}

// MARK: - Cinematic Intro Layer
extension DestructionRoomView {
    private var cinematicIntroLayer: some View {
        ZStack {
            // Dark overlay that fades out
            Color.black
                .opacity(introActive ? 0.6 : 0)
                .ignoresSafeArea()
            
            // "DESTROY EVERYTHING" text
            VStack(spacing: 12) {
                Text("DESTROY")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .red.opacity(0.8), radius: 12)
                
                Text("EVERYTHING")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.red)
                    .shadow(color: .red.opacity(0.8), radius: 20)
                    .shadow(color: .orange.opacity(0.4), radius: 40)
            }
            .scaleEffect(introTextScale)
            .opacity(introTextOpacity)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Instruction Text
extension DestructionRoomView {
    private var instructionText: some View {
        VStack(spacing: 6) {
            Text("TAP to smash \u{2022} SWIPE to throw")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
            
            Text("HOLD to charge \u{2022} DOUBLE-TAP for rapid fire")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .padding(.bottom, 10)
    }
}

// MARK: - Release Button
extension DestructionRoomView {
    private var releaseButton: some View {
        ZStack {
            // Floating leaf particles around button
            ForEach(leafParticles) { leaf in
                Image(systemName: "leaf.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.green.opacity(leaf.opacity))
                    .rotationEffect(.degrees(leaf.rotation))
                    .offset(x: leaf.xOffset, y: leaf.yOffset)
            }
            
            // Green glow pulse
            Capsule()
                .fill(Color.green.opacity(releaseGlowOpacity * 0.3))
                .frame(width: 240, height: 60)
                .blur(radius: 12)
            
            // Main button
            Button(action: onRelease) {
                HStack(spacing: 10) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 20))
                        .symbolEffect(.pulse)
                    
                    Text("Release & Let Go")
                        .font(.system(size: 18, weight: .bold, design: .serif))
                }
                .foregroundColor(.white)
                .padding(.vertical, 18)
                .padding(.horizontal, 40)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.15, green: 0.7, blue: 0.4),
                                    Color(red: 0.1, green: 0.55, blue: 0.3),
                                    Color(red: 0.08, green: 0.45, blue: 0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.green.opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: Color.green.opacity(0.5), radius: 16, y: 4)
                )
            }
            .scaleEffect(releaseButtonScale * releaseBreathScale)
        }
        .padding(.bottom, 10)
        .onAppear {
            animateReleaseButton()
            startLeafParticles()
        }
    }
}


// MARK: - Spray Color Picker
extension DestructionRoomView {
    private var sprayColorPicker: some View {
        HStack(spacing: 10) {
            ForEach(Array(sprayColors.enumerated()), id: \.offset) { index, colorInfo in
                Button(action: {
                    selectedSprayColor = colorInfo.0
                    sceneManager.setSprayColor(colorInfo.1)
                }) {
                    Circle()
                        .fill(colorInfo.0)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(
                                    selectedSprayColor == colorInfo.0 ? Color.white : Color.clear,
                                    lineWidth: 2.5
                                )
                        )
                        .shadow(color: colorInfo.0.opacity(selectedSprayColor == colorInfo.0 ? 0.8 : 0), radius: 6)
                        .scaleEffect(selectedSprayColor == colorInfo.0 ? 1.15 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: selectedSprayColor)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.bottom, 8)
    }
}

// MARK: - Actions
extension DestructionRoomView {
    private func performHit() {
        guard !introActive else { return }
        
        sceneManager.hitObject(with: selectedTool)
        hitCount += 1
        
        // Mechanical hit counter spring
        hitCounterSpring = 1.3
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            hitCounterSpring = 1.0
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        
        // Rage meter shake on hit
        rageMeterShake = CGFloat.random(in: -3...3)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            rageMeterShake = 0
        }
        
        // Spawn floating damage number
        spawnDamageNumber(value: damageValue(for: selectedTool))
        
        // Check release threshold using sceneManager's destruction level
        if sceneManager.destructionLevel >= 0.6 && !showRelease {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showRelease = true
            }
        }
        
        // Combo display is driven by sceneManager.comboCount via onChange handler
        lastHitTime = Date()
    }
    
    private func performRapidFire() {
        guard !introActive else { return }
        
        // Double-tap = 3 rapid hits
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) { [self] in
                sceneManager.hitObject(with: selectedTool)
                hitCount += 1
                
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
                spawnDamageNumber(value: damageValue(for: selectedTool))
            }
        }
        
        // Rage meter rapid shake
        rageMeterShake = 5
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            rageMeterShake = 0
        }
        
        // Hit counter spring
        hitCounterSpring = 1.5
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            hitCounterSpring = 1.0
        }
        
        // Check release
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [self] in
            if sceneManager.destructionLevel >= 0.6 && !showRelease {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showRelease = true
                }
            }
        }
    }
    
    private func performSwipe(_ value: DragGesture.Value) {
        guard !introActive else { return }
        
        // Calculate velocity magnitude for force scaling
        let velocity = sqrt(
            value.predictedEndTranslation.width * value.predictedEndTranslation.width +
            value.predictedEndTranslation.height * value.predictedEndTranslation.height
        )
        
        // Scale translation by velocity (faster swipe = more power)
        let scaleFactor = min(velocity / 200, 3.0)
        let scaledTranslation = CGSize(
            width: value.translation.width * scaleFactor,
            height: value.translation.height * scaleFactor
        )
        
        sceneManager.swipeAction(translation: scaledTranslation, tool: selectedTool)
        sceneManager.endSwipe(tool: selectedTool)
        hitCount += 1
        
        // Larger damage number for fast swipes
        let swipeDamage = Int(scaleFactor * Double(damageValue(for: selectedTool)))
        spawnDamageNumber(value: swipeDamage)
        
        // Haptic proportional to force
        if scaleFactor > 2.0 {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred(intensity: 1.0)
        } else {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
        
        // Check release
        if sceneManager.destructionLevel >= 0.6 && !showRelease {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showRelease = true
            }
        }
    }
    
    private func startCharging() {
        guard !introActive else { return }
        isCharging = true
        chargeLevel = 0
        
        // Animate charge over 1 second
        withAnimation(.linear(duration: 1.0)) {
            chargeLevel = 1.0
        }
        
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.warning)
    }
    
    private func performChargedAttack() {
        guard isCharging else { return }
        isCharging = false
        
        // 3x power hit if fully charged
        let powerMultiplier = chargeLevel >= 0.9 ? 3 : (chargeLevel >= 0.5 ? 2 : 1)
        
        for _ in 0..<powerMultiplier {
            sceneManager.hitObject(with: selectedTool)
            hitCount += 1
        }
        
        // Big damage number
        spawnDamageNumber(value: damageValue(for: selectedTool) * powerMultiplier)
        
        // Heavy haptic
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred(intensity: 1.0)
        
        if powerMultiplier >= 3 {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
        
        // Dramatic rage meter shake for charged hit
        rageMeterShake = CGFloat(powerMultiplier) * 4
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            rageMeterShake = 0
        }
        
        chargeLevel = 0
        
        // Check release
        if sceneManager.destructionLevel >= 0.6 && !showRelease {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showRelease = true
            }
        }
    }
    
    private func switchTool(to tool: RageTool) {
        guard tool != selectedTool else { return }
        previousTool = selectedTool
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            selectedTool = tool
            toolSwitchAnimation = true
        }
        
        // Whoosh haptic
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // Reset switch animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            withAnimation(.easeOut(duration: 0.2)) {
                toolSwitchAnimation = false
            }
        }
        
        if tool == .spray {
            sceneManager.setSprayColor(UIColor.red)
        }
    }
    
    private func damageValue(for tool: RageTool) -> Int {
        switch tool {
        case .fists: return Int.random(in: 8...15)
        case .sledgehammer: return Int.random(in: 25...40)
        case .bat: return Int.random(in: 18...30)
        case .throwPlates: return Int.random(in: 12...22)
        case .spray: return Int.random(in: 3...8)
        }
    }
}


// MARK: - State Change Handlers
extension DestructionRoomView {
    private func handleComboChange(_ newCombo: Int) {
        guard newCombo >= 3 else {
            if newCombo == 0 {
                withAnimation(.easeOut(duration: 0.3)) {
                    showCombo = false
                    comboOpacity = 0
                }
            }
            return
        }
        
        let tier = currentComboTier
        showCombo = true
        
        // Spring scale animation: pop from 0 to 1.5 then settle at 1.0
        comboScale = 0
        comboRotation = Double.random(in: -8...8)
        
        withAnimation(.spring(response: 0.25, dampingFraction: 0.4, blendDuration: 0.1)) {
            comboScale = 1.5
            comboOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                comboScale = 1.0
            }
        }
        
        // Border pulse on combos
        withAnimation(.easeIn(duration: 0.1)) {
            borderPulseOpacity = tier == .godlike ? 0.8 : (tier == .unstoppable ? 0.5 : 0.3)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [self] in
            withAnimation(.easeOut(duration: 0.6)) {
                borderPulseOpacity = 0
            }
        }
        
        // Haptic notification for tier changes
        let newTier = currentComboTier
        if newTier != previousComboTier {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
            previousComboTier = newTier
            
            // GODLIKE gets a full white flash
            if newTier == .godlike {
                withAnimation(.easeIn(duration: 0.05)) {
                    borderPulseOpacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
                    withAnimation(.easeOut(duration: 0.8)) {
                        borderPulseOpacity = 0
                    }
                }
            }
        }
    }
    
    private func handleDestructionChange(_ newLevel: Double) {
        // Vignette intensifies with destruction
        vignetteIntensity = 0.3 + (newLevel * 0.5)
        
        // Background darkening
        backgroundDarkness = newLevel * 0.15
        
        // Milestone checks at 25% intervals
        let milestone = Int(newLevel * 4)
        if milestone > lastMilestone {
            lastMilestone = milestone
            triggerMilestoneEffect(milestone: milestone)
        }
        
        // Full rage meter pulse
        if newLevel >= 1.0 {
            startFullRagePulse()
        }
        
        // Release button check
        if newLevel >= 0.6 && !showRelease {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showRelease = true
            }
        }
    }
    
    private func triggerMilestoneEffect(milestone: Int) {
        // Milestone flash on rage meter
        withAnimation(.easeIn(duration: 0.1)) {
            milestoneFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            withAnimation(.easeOut(duration: 0.4)) {
                milestoneFlash = false
            }
        }
        
        // Phase text announcements
        switch milestone {
        case 1:
            showPhaseAnnouncement(.warmingUp)
        case 2:
            showPhaseAnnouncement(.gettingIntense)
        case 3:
            showPhaseAnnouncement(.totalChaos)
        case 4:
            showPhaseAnnouncement(.maximumDestruction)
        default:
            break
        }
        
        // Haptic burst
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(milestone >= 3 ? .error : .warning)
        
        // Rage meter shake burst
        rageMeterShake = CGFloat(milestone) * 3
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            rageMeterShake = 0
        }
    }
    
    private func showPhaseAnnouncement(_ phase: DestructionPhase) {
        currentPhase = phase
        showPhaseText = true
        phaseTextScale = 0.3
        phaseTextOpacity = 0
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            phaseTextScale = 1.1
            phaseTextOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                phaseTextScale = 1.0
            }
        }
        
        // Fade out after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [self] in
            withAnimation(.easeOut(duration: 0.5)) {
                phaseTextOpacity = 0
                phaseTextScale = 0.8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                showPhaseText = false
            }
        }
    }
    
    private func startFullRagePulse() {
        // Continuous pulse when meter is full
        withAnimation(
            .easeInOut(duration: 0.6)
            .repeatForever(autoreverses: true)
        ) {
            rageMeterPulse = 1.08
        }
    }
}


// MARK: - Animation Systems
extension DestructionRoomView {
    private func spawnDamageNumber(value: Int) {
        let screenCenter = CGPoint(
            x: CGFloat.random(in: 140...260),
            y: CGFloat.random(in: 300...450)
        )
        
        var number = FloatingDamageNumber(
            value: value,
            position: screenCenter,
            rotation: Double.random(in: -15...15)
        )
        
        damageNumbers.append(number)
        let numberId = number.id
        
        // Animate upward and fade
        withAnimation(.easeOut(duration: 1.2)) {
            if let index = damageNumbers.firstIndex(where: { $0.id == numberId }) {
                damageNumbers[index].opacity = 0
            }
        }
        
        // Remove after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { [self] in
            damageNumbers.removeAll { $0.id == numberId }
        }
    }
    
    private func startEmberSystem() {
        // Generate ember particles continuously - store timer for cleanup
        emberTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [self, weak sceneManager] _ in
            guard let sceneManager = sceneManager else { return }
            guard sceneManager.destructionLevel > 0.1 else { return }
            
            let particleCount = Int(sceneManager.destructionLevel * 3) + 1
            
            for _ in 0..<particleCount {
                let ember = RageEmberParticle(
                    xOffset: CGFloat.random(in: -10...10),
                    yOffset: 0,
                    size: CGFloat.random(in: 3...7),
                    opacity: Double.random(in: 0.6...1.0),
                    speed: Double.random(in: 1.0...2.5)
                )
                
                withAnimation(.none) {
                    emberParticles.append(ember)
                }
                
                let emberId = ember.id
                
                // Animate upward
                withAnimation(.easeOut(duration: ember.speed)) {
                    if let index = emberParticles.firstIndex(where: { $0.id == emberId }) {
                        emberParticles[index].yOffset = CGFloat.random(in: -40 ... -20)
                        emberParticles[index].xOffset += CGFloat.random(in: -8...8)
                        emberParticles[index].opacity = 0
                    }
                }
                
                // Remove
                DispatchQueue.main.asyncAfter(deadline: .now() + ember.speed + 0.1) { [self] in
                    emberParticles.removeAll { $0.id == emberId }
                }
            }
        }
    }
    
    private func startLeafParticles() {
        leafTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [self] _ in
            let leaf = LeafParticle(
                xOffset: CGFloat.random(in: -60...60),
                yOffset: CGFloat.random(in: -20...20),
                rotation: Double.random(in: 0...360),
                opacity: Double.random(in: 0.4...0.8)
            )
            
            withAnimation(.none) {
                leafParticles.append(leaf)
            }
            
            let leafId = leaf.id
            
            // Float and fade
            withAnimation(.easeInOut(duration: 2.5)) {
                if let index = leafParticles.firstIndex(where: { $0.id == leafId }) {
                    leafParticles[index].yOffset -= 30
                    leafParticles[index].xOffset += CGFloat.random(in: -15...15)
                    leafParticles[index].rotation += Double.random(in: 30...90)
                    leafParticles[index].opacity = 0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [self] in
                leafParticles.removeAll { $0.id == leafId }
            }
        }
    }
    
    private func startScanLineAnimation() {
        // Slow downward scroll of scan lines
        withAnimation(
            .linear(duration: 8.0)
            .repeatForever(autoreverses: false)
        ) {
            scanLineOffset = 100
        }
    }
    
    private func animateReleaseButton() {
        // Dramatic spring entry
        releaseButtonScale = 0
        withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
            releaseButtonScale = 1.0
        }
        
        // Green glow pulse
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            releaseGlowOpacity = 1.0
        }
        
        // Breathing text scale
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            releaseBreathScale = 1.04
        }
    }
    
    private func playCinematicIntro() {
        // Sequence: dark -> text appears -> text fades -> HUD slides in
        // Each stage checks viewActive to prevent firing after dismissal
        
        // Step 1: After brief pause, show text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            guard self.viewActive else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                introTextOpacity = 1.0
                introTextScale = 1.0
            }
        }
        
        // Step 2: Text holds then begins to fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [self] in
            guard self.viewActive else { return }
            withAnimation(.easeOut(duration: 0.5)) {
                introTextOpacity = 0
                introTextScale = 1.3
            }
        }
        
        // Step 3: HUD elements fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) { [self] in
            guard self.viewActive else { return }
            withAnimation(.easeOut(duration: 0.4)) {
                hudOpacity = 1.0
            }
        }
        
        // Step 4: Tool selector slides up
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [self] in
            guard self.viewActive else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                toolSelectorOffset = 0
            }
        }
        
        // Step 5: Corner brackets fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { [self] in
            guard self.viewActive else { return }
            withAnimation(.easeOut(duration: 0.6)) {
                cornerBracketOpacity = 1.0
            }
        }
        
        // Step 6: Intro complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { [self] in
            guard self.viewActive else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                introActive = false
            }
        }
    }
}


// MARK: - Rage Tool Enum
enum RageTool: String, CaseIterable {
    case fists = "Fists"
    case sledgehammer = "Sledge"
    case bat = "Bat"
    case throwPlates = "Throw"
    case spray = "Spray"

    var icon: String {
        switch self {
        case .fists: return "hand.raised.fill"
        case .sledgehammer: return "hammer.fill"
        case .bat: return "figure.baseball"
        case .throwPlates: return "circle.slash"
        case .spray: return "paintbrush.fill"
        }
    }

    var color: Color {
        switch self {
        case .fists: return .red
        case .sledgehammer: return .orange
        case .bat: return .purple
        case .throwPlates: return .cyan
        case .spray: return .green
        }
    }

    var soundFile: String {
        switch self {
        case .fists: return "punch_impact"
        case .sledgehammer: return "sledgehammer_hit"
        case .bat: return "wood_break"
        case .throwPlates: return "plate_shatter"
        case .spray: return "spray_sound"
        }
    }
}

