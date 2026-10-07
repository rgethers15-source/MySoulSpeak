import SceneKit
import AVFoundation
import AudioToolbox
import UIKit

// MARK: - Material Classification
/// Defines the physical material type for each destructible object.
/// Determines particle effects, sounds, and haptic responses on impact.
enum ObjectMaterial: String {
    case metal
    case glass
    case wood
    case ceramic
    case rubber
    case flesh
    case concrete
    case plastic
    
    var particleColor: UIColor {
        switch self {
        case .metal: return UIColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0)
        case .glass: return UIColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.8)
        case .wood: return UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        case .ceramic: return UIColor(white: 0.95, alpha: 1.0)
        case .rubber: return UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        case .flesh: return UIColor(red: 0.8, green: 0.5, blue: 0.4, alpha: 1.0)
        case .concrete: return UIColor(red: 0.5, green: 0.48, blue: 0.45, alpha: 1.0)
        case .plastic: return UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)
        }
    }
    
    var secondaryColor: UIColor {
        switch self {
        case .metal: return UIColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1.0)
        case .glass: return UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.5)
        case .wood: return UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        case .ceramic: return UIColor(red: 0.9, green: 0.88, blue: 0.85, alpha: 1.0)
        case .rubber: return UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        case .flesh: return UIColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1.0)
        case .concrete: return UIColor(red: 0.4, green: 0.38, blue: 0.35, alpha: 1.0)
        case .plastic: return UIColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0)
        }
    }
    
    /// System sound IDs appropriate for this material
    var impactSounds: [UInt32] {
        switch self {
        case .metal: return [1104, 1105, 1023, 1070, 1071]
        case .glass: return [1105, 1106, 1109, 1110, 1057]
        case .wood: return [1104, 1103, 1071, 1025, 1073]
        case .ceramic: return [1105, 1106, 1109, 1110]
        case .rubber: return [1103, 1052, 1073]
        case .flesh: return [1103, 1052, 1057, 1073]
        case .concrete: return [1104, 1023, 1070, 1071]
        case .plastic: return [1103, 1104, 1052]
        }
    }
    
    /// Additional sounds for dramatic multi-sound impacts
    var secondarySounds: [UInt32] {
        switch self {
        case .metal: return [1070, 1071, 1023]
        case .glass: return [1109, 1110, 1057]
        case .wood: return [1025, 1073, 1071]
        case .ceramic: return [1106, 1110]
        case .rubber: return [1052, 1073]
        case .flesh: return [1057, 1052]
        case .concrete: return [1070, 1023]
        case .plastic: return [1052, 1103]
        }
    }
    
    var weight: Float {
        switch self {
        case .metal: return 12.0
        case .glass: return 1.5
        case .wood: return 6.0
        case .ceramic: return 1.0
        case .rubber: return 8.0
        case .flesh: return 15.0
        case .concrete: return 20.0
        case .plastic: return 3.0
        }
    }
    
    var fragility: Float {
        switch self {
        case .metal: return 0.1
        case .glass: return 1.0
        case .wood: return 0.5
        case .ceramic: return 0.9
        case .rubber: return 0.05
        case .flesh: return 0.3
        case .concrete: return 0.2
        case .plastic: return 0.4
        }
    }
}

// MARK: - Destructible Object Wrapper
/// Encapsulates a scene node with its material properties and destruction state.
struct DestructibleObject {
    let node: SCNNode
    let material: ObjectMaterial
    var hitCount: Int = 0
    var isDestroyed: Bool = false
    var originalPosition: SCNVector3
    var maxHits: Int
    
    init(node: SCNNode, material: ObjectMaterial, maxHits: Int = 5) {
        self.node = node
        self.material = material
        self.originalPosition = node.position
        self.maxHits = maxHits
    }
}

// MARK: - Physics Contact Category Masks
struct PhysicsCategory {
    static let destructible: Int = 1
    static let debris: Int = 2
    static let wall: Int = 4
    static let floor: Int = 8
    static let projectile: Int = 16
}

/// Reference type for mutable counter captured in concurrent closures
private class RampState: @unchecked Sendable {
    var step: Int = 0
}


// MARK: - Elite Rage Room Scene Manager
/// The ultimate rage room experience engine. Manages a fully destructible 3D environment
/// with physics-accurate material responses, layered particle systems, progressive
/// environmental deterioration, camera dynamics, slow-motion impacts, combo multipliers,
/// and material-aware audio/haptic feedback.
///
/// Architecture:
/// - Material-classified destructible objects with weight/momentum physics
/// - 6 distinct particle system generators (sparks, glass, dust, wood, ceramic, wall crack)
/// - Progressive room deterioration from pristine to apocalyptic (0.0 - 1.0)
/// - Combo multiplier system affecting force, particles, and visual intensity
/// - Camera shake with tool-specific intensity profiles and breathing sway
/// - Slow-motion on power hits with FOV zoom
/// - Environmental storytelling objects (fire extinguisher, hanging light, mirror)
/// - Layered haptics with aftershock patterns
/// - Multi-sound audio with pseudo-reverb and material-specific selection
@MainActor
class RageRoomSceneManager: NSObject, ObservableObject, SCNPhysicsContactDelegate {
    
    // MARK: - Public Scene Properties
    let scene = SCNScene()
    let cameraNode = SCNNode()
    
    // MARK: - Published Properties for HUD Integration
    @Published var screenFlashColor: UIColor? = nil
    @Published var screenFlashOpacity: Double = 0
    @Published var destructionLevel: Double = 0
    @Published var comboCount: Int = 0
    @Published var isSlowMotion: Bool = false
    @Published var cameraShakeOffset: CGSize = .zero
    @Published var lastHitMaterial: String = ""
    
    // MARK: - Internal State
    private var destructibleObjects: [DestructibleObject] = []
    private var debrisNodes: [SCNNode] = []
    private var sprayNodes: [SCNNode] = []
    private var crackNodes: [SCNNode] = []
    private var currentSprayColor: UIColor = .red
    private var totalHitCount: Int = 0
    private var lastHitTime: Date = Date()
    private var internalComboCount: Int = 0
    private var comboTimer: Timer?
    
    // MARK: - Lighting References
    private var mainOverheadLight: SCNNode?
    private var secondOverheadLight: SCNNode?
    private var ambientLight: SCNNode?
    private var redAccentLight1: SCNNode?
    private var redAccentLight2: SCNNode?
    private var emergencyLight: SCNNode?
    private var fluorescentLight: SCNNode?
    private var hangingLightFixture: SCNNode?
    private var hangingLightChain: SCNNode?
    
    // MARK: - Environmental Object References
    private var fireExtinguisherNode: SCNNode?
    private var mirrorNode: SCNNode?
    private var mirrorCrackLevel: Int = 0
    private var carDoorNode: SCNNode?
    private var carDoorDentCount: Int = 0
    private var sparkingPipeNode: SCNNode?
    private var sparkingPipeEmitter: SCNNode?
    
    // MARK: - Wall References
    private var backWallNode: SCNNode?
    private var leftWallNode: SCNNode?
    private var rightWallNode: SCNNode?
    private var ceilingNode: SCNNode?
    
    // MARK: - Audio
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    // MARK: - Performance Tracking
    private let maxDebrisNodes = 80
    private let maxSprayNodes = 200
    private let maxCrackNodes = 40
    
    // MARK: - Camera State
    private var baseCameraPosition = SCNVector3(0, 1.7, 5)
    private var baseCameraFOV: CGFloat = 65
    private var breathingPhase: Float = 0
    
    // MARK: - Slow Motion
    private var slowMotionTimer: Timer?
    private var slowMotionRampTimer: Timer?
    
    // MARK: - Ambient Systems
    private var dustMoteEmitter: SCNNode?
    private var floorHazeNode: SCNNode?
    private var dripTimer: Timer?
    private var flickerTimer: Timer?
    
    // MARK: - Cached Particle Images
    private lazy var cachedCircleImage8White: UIImage = createCircleImage(size: 8, color: .white)
    private lazy var cachedCircleImage6White: UIImage = createCircleImage(size: 6, color: .white)
    private lazy var cachedSoftCircleImage32: UIImage = createSoftCircleImage(size: 32)
    private lazy var cachedSoftCircleImage16: UIImage = createSoftCircleImage(size: 16)
    private lazy var cachedSoftCircleImage24: UIImage = createSoftCircleImage(size: 24)
    private lazy var cachedDiamondImage12: UIImage = createDiamondImage(size: 12)
    private lazy var cachedDiamondImage8: UIImage = createDiamondImage(size: 8)
    private lazy var cachedSplinterImage16: UIImage = createSplinterImage(size: 16)
    
    // MARK: - Destruction Tracking
    private var wallHitCounts: [String: Int] = [:]
    private var hangingLightFallen: Bool = false
    private var fireExtinguisherTriggered: Bool = false
    
    // MARK: - Setup
    
    override init() {
        super.init()
    }
    
    func setupRoom() {
        scene.background.contents = UIColor(red: 0.06, green: 0.05, blue: 0.04, alpha: 1)
        scene.physicsWorld.gravity = SCNVector3(0, -9.8, 0)
        scene.physicsWorld.speed = 1.0
        scene.physicsWorld.contactDelegate = self
        
        setupCamera()
        setupLighting()
        buildRoom()
        addCeilingBeams()
        addExposedPipes()
        addDummy()
        addTires()
        addTable()
        addDiningSet()
        addBottles()
        addTV()
        addMoreTVs()
        addPlates()
        addPictureFrames()
        addCarDoorPanel()
        addMirrorPanel()
        addFireExtinguisher()
        addToolbox()
        addCinderBlocks()
        addCRTMonitor()
        addWoodenCrate()
        addHangingLightFixture()
        setupAmbientSystems()
        startBreathingSway()
        startBackgroundMusic()
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera() {
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 100
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.fieldOfView = baseCameraFOV
        cameraNode.camera?.wantsHDR = true
        cameraNode.camera?.bloomIntensity = 0.3
        cameraNode.camera?.bloomThreshold = 0.8
        cameraNode.camera?.motionBlurIntensity = 0.1
        cameraNode.position = baseCameraPosition
        cameraNode.look(at: SCNVector3(0, 1.2, 0))
        scene.rootNode.addChildNode(cameraNode)
    }
    
    // MARK: - Breathing Camera Sway
    
    private func startBreathingSway() {
        let base = baseCameraPosition
        let breatheAction = SCNAction.customAction(duration: 4.0) { node, elapsed in
            let phase = Float(elapsed) / 4.0 * Float.pi * 2
            let swayX = sinf(phase) * 0.008
            let swayY = cosf(phase * 0.7) * 0.005
            node.position = SCNVector3(
                base.x + swayX,
                base.y + swayY,
                base.z
            )
        }
        let repeatBreathe = SCNAction.repeatForever(breatheAction)
        cameraNode.runAction(repeatBreathe, forKey: "breathing")
    }
    
    // MARK: - Lighting Setup (Industrial Mood)
    
    private func setupLighting() {
        // Main overhead industrial spot (warm, slightly dim)
        let overhead = SCNNode()
        overhead.light = SCNLight()
        overhead.light?.type = .spot
        overhead.light?.color = UIColor(red: 1.0, green: 0.9, blue: 0.75, alpha: 1)
        overhead.light?.intensity = 1200
        overhead.light?.spotInnerAngle = 40
        overhead.light?.spotOuterAngle = 80
        overhead.light?.castsShadow = true
        overhead.light?.shadowRadius = 6
        overhead.light?.shadowSampleCount = 4
        overhead.position = SCNVector3(0, 4.0, 2)
        overhead.look(at: SCNVector3(0, 0, 0))
        overhead.name = "light_main_overhead"
        scene.rootNode.addChildNode(overhead)
        mainOverheadLight = overhead
        
        // Second overhead spot (back of room)
        let overhead2 = SCNNode()
        overhead2.light = SCNLight()
        overhead2.light?.type = .spot
        overhead2.light?.color = UIColor(red: 1.0, green: 0.85, blue: 0.7, alpha: 1)
        overhead2.light?.intensity = 800
        overhead2.light?.spotInnerAngle = 35
        overhead2.light?.spotOuterAngle = 70
        overhead2.light?.castsShadow = true
        overhead2.position = SCNVector3(0, 4.0, -2)
        overhead2.look(at: SCNVector3(0, 0, -2))
        overhead2.name = "light_second_overhead"
        scene.rootNode.addChildNode(overhead2)
        secondOverheadLight = overhead2
        
        // Dim ambient fill
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = UIColor(red: 0.25, green: 0.2, blue: 0.18, alpha: 1)
        ambient.light?.intensity = 400
        ambient.name = "light_ambient"
        scene.rootNode.addChildNode(ambient)
        ambientLight = ambient
        
        // Red accent light (left ceiling)
        let red1 = SCNNode()
        red1.light = SCNLight()
        red1.light?.type = .omni
        red1.light?.color = UIColor(red: 1.0, green: 0.05, blue: 0.02, alpha: 1)
        red1.light?.intensity = 600
        red1.light?.attenuationStartDistance = 1.0
        red1.light?.attenuationEndDistance = 6.0
        red1.position = SCNVector3(-2, 3.8, -1)
        red1.name = "light_red_1"
        scene.rootNode.addChildNode(red1)
        redAccentLight1 = red1
        
        // Red accent light (right ceiling)
        let red2 = SCNNode()
        red2.light = SCNLight()
        red2.light?.type = .omni
        red2.light?.color = UIColor(red: 1.0, green: 0.08, blue: 0.02, alpha: 1)
        red2.light?.intensity = 500
        red2.light?.attenuationStartDistance = 1.0
        red2.light?.attenuationEndDistance = 6.0
        red2.position = SCNVector3(2, 3.8, -1)
        red2.name = "light_red_2"
        scene.rootNode.addChildNode(red2)
        redAccentLight2 = red2
        
        // Red back wall accent
        let redBack = SCNNode()
        redBack.light = SCNLight()
        redBack.light?.type = .spot
        redBack.light?.color = UIColor(red: 1.0, green: 0.1, blue: 0.05, alpha: 1)
        redBack.light?.intensity = 400
        redBack.light?.spotInnerAngle = 20
        redBack.light?.spotOuterAngle = 50
        redBack.position = SCNVector3(0, 3.5, 0)
        redBack.look(at: SCNVector3(0, 1.5, -4))
        scene.rootNode.addChildNode(redBack)
        
        // Fluorescent light (will flicker)
        let fluoro = SCNNode()
        fluoro.light = SCNLight()
        fluoro.light?.type = .omni
        fluoro.light?.color = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1)
        fluoro.light?.intensity = 300
        fluoro.light?.attenuationStartDistance = 0.5
        fluoro.light?.attenuationEndDistance = 4.0
        fluoro.position = SCNVector3(2.5, 3.9, 1.5)
        fluoro.name = "light_fluorescent"
        scene.rootNode.addChildNode(fluoro)
        fluorescentLight = fluoro
        
        // Emergency light (off initially, activates at high destruction)
        let emergency = SCNNode()
        emergency.light = SCNLight()
        emergency.light?.type = .omni
        emergency.light?.color = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1)
        emergency.light?.intensity = 0
        emergency.light?.attenuationStartDistance = 1.0
        emergency.light?.attenuationEndDistance = 8.0
        emergency.position = SCNVector3(0, 3.5, 3)
        emergency.name = "light_emergency"
        scene.rootNode.addChildNode(emergency)
        emergencyLight = emergency
    }
    
    // MARK: - Build Room Structure
    
    private func buildRoom() {
        let roomWidth: Float = 8.0
        let roomDepth: Float = 9.0
        let wallHeight: Float = 4.5
        
        // Floor - dark stained concrete
        let floor = SCNFloor()
        floor.reflectivity = 0.05
        let floorNode = SCNNode(geometry: floor)
        let floorMat = SCNMaterial()
        floorMat.diffuse.contents = UIColor(red: 0.18, green: 0.16, blue: 0.15, alpha: 1)
        floorMat.roughness.contents = 0.95
        floor.materials = [floorMat]
        floorNode.physicsBody = SCNPhysicsBody.static()
        floorNode.physicsBody?.categoryBitMask = PhysicsCategory.floor
        floorNode.physicsBody?.contactTestBitMask = PhysicsCategory.debris | PhysicsCategory.destructible
        floorNode.name = "floor"
        scene.rootNode.addChildNode(floorNode)
        
        // Scattered floor debris (pre-existing grime)
        for _ in 0..<15 {
            let chunk = SCNBox(
                width: CGFloat.random(in: 0.04...0.12),
                height: CGFloat.random(in: 0.02...0.05),
                length: CGFloat.random(in: 0.04...0.10),
                chamferRadius: 0
            )
            let mat = SCNMaterial()
            mat.diffuse.contents = UIColor(
                red: CGFloat.random(in: 0.2...0.4),
                green: CGFloat.random(in: 0.18...0.35),
                blue: CGFloat.random(in: 0.16...0.3),
                alpha: 1
            )
            mat.roughness.contents = 0.9
            chunk.materials = [mat]
            let node = SCNNode(geometry: chunk)
            node.position = SCNVector3(
                Float.random(in: -3...3),
                0.02,
                Float.random(in: -3.5...3)
            )
            node.eulerAngles.y = Float.random(in: 0...(Float.pi * 2))
            scene.rootNode.addChildNode(node)
        }
        
        // Concrete wall materials
        let concreteMat = SCNMaterial()
        concreteMat.diffuse.contents = UIColor(red: 0.38, green: 0.36, blue: 0.34, alpha: 1)
        concreteMat.roughness.contents = 0.92
        
        let darkConcreteMat = SCNMaterial()
        darkConcreteMat.diffuse.contents = UIColor(red: 0.28, green: 0.26, blue: 0.25, alpha: 1)
        darkConcreteMat.roughness.contents = 0.95
        
        // Back wall
        let backWall = SCNBox(width: CGFloat(roomWidth), height: CGFloat(wallHeight), length: 0.25, chamferRadius: 0)
        backWall.materials = [concreteMat]
        let backNode = SCNNode(geometry: backWall)
        backNode.position = SCNVector3(0, wallHeight / 2, -roomDepth / 2)
        backNode.physicsBody = SCNPhysicsBody.static()
        backNode.physicsBody?.categoryBitMask = PhysicsCategory.wall
        backNode.physicsBody?.contactTestBitMask = PhysicsCategory.destructible | PhysicsCategory.debris
        backNode.name = "wall_back"
        scene.rootNode.addChildNode(backNode)
        self.backWallNode = backNode
        
        // Concrete panel lines on back wall
        for i in 0..<4 {
            let line = SCNBox(width: CGFloat(roomWidth), height: 0.02, length: 0.01, chamferRadius: 0)
            let lineMat = SCNMaterial()
            lineMat.diffuse.contents = UIColor(red: 0.22, green: 0.2, blue: 0.19, alpha: 1)
            line.materials = [lineMat]
            let lineNode = SCNNode(geometry: line)
            lineNode.position = SCNVector3(0, Float(i + 1) * 1.0, -roomDepth / 2 + 0.14)
            scene.rootNode.addChildNode(lineNode)
        }
        
        // Left wall
        let leftWall = SCNBox(width: 0.25, height: CGFloat(wallHeight), length: CGFloat(roomDepth), chamferRadius: 0)
        leftWall.materials = [darkConcreteMat]
        let leftNode = SCNNode(geometry: leftWall)
        leftNode.position = SCNVector3(-roomWidth / 2, wallHeight / 2, 0)
        leftNode.physicsBody = SCNPhysicsBody.static()
        leftNode.physicsBody?.categoryBitMask = PhysicsCategory.wall
        leftNode.name = "wall_left"
        scene.rootNode.addChildNode(leftNode)
        self.leftWallNode = leftNode
        
        // Right wall
        let rightWall = SCNBox(width: 0.25, height: CGFloat(wallHeight), length: CGFloat(roomDepth), chamferRadius: 0)
        rightWall.materials = [concreteMat]
        let rightNode = SCNNode(geometry: rightWall)
        rightNode.position = SCNVector3(roomWidth / 2, wallHeight / 2, 0)
        rightNode.physicsBody = SCNPhysicsBody.static()
        rightNode.physicsBody?.categoryBitMask = PhysicsCategory.wall
        rightNode.name = "wall_right"
        scene.rootNode.addChildNode(rightNode)
        self.rightWallNode = rightNode
        
        // Ceiling
        let ceiling = SCNBox(width: CGFloat(roomWidth), height: 0.2, length: CGFloat(roomDepth), chamferRadius: 0)
        let ceilingMat = SCNMaterial()
        ceilingMat.diffuse.contents = UIColor(red: 0.12, green: 0.11, blue: 0.1, alpha: 1)
        ceilingMat.roughness.contents = 0.95
        ceiling.materials = [ceilingMat]
        let cNode = SCNNode(geometry: ceiling)
        cNode.position = SCNVector3(0, wallHeight, 0)
        cNode.name = "ceiling"
        scene.rootNode.addChildNode(cNode)
        self.ceilingNode = cNode
        
        // Red hazard stripes on back wall
        let redStripeMat = SCNMaterial()
        redStripeMat.diffuse.contents = UIColor(red: 0.8, green: 0.08, blue: 0.08, alpha: 1)
        redStripeMat.roughness.contents = 0.6
        
        for xPos: Float in [-2.5, 0, 2.5] {
            let stripe = SCNBox(width: 1.8, height: 0.12, length: 0.02, chamferRadius: 0)
            stripe.materials = [redStripeMat]
            let stripeNode = SCNNode(geometry: stripe)
            stripeNode.position = SCNVector3(xPos, 2.8, -roomDepth / 2 + 0.15)
            scene.rootNode.addChildNode(stripeNode)
        }
        
        // Vertical accent stripes on side walls
        for x: Float in [-roomWidth / 2 + 0.15, roomWidth / 2 - 0.15] {
            let stripe = SCNBox(width: 0.02, height: CGFloat(wallHeight), length: 0.12, chamferRadius: 0)
            stripe.materials = [redStripeMat]
            let stripeNode = SCNNode(geometry: stripe)
            stripeNode.position = SCNVector3(x, wallHeight / 2, -2)
            scene.rootNode.addChildNode(stripeNode)
        }
    }
    
    // MARK: - Ceiling Beams
    
    private func addCeilingBeams() {
        let beamMat = SCNMaterial()
        beamMat.diffuse.contents = UIColor(red: 0.2, green: 0.18, blue: 0.16, alpha: 1)
        beamMat.metalness.contents = 0.6
        beamMat.roughness.contents = 0.7
        
        for z: Float in stride(from: -3.5, through: 3.0, by: 2.0) {
            let beam = SCNBox(width: 7.5, height: 0.25, length: 0.15, chamferRadius: 0)
            beam.materials = [beamMat]
            let beamNode = SCNNode(geometry: beam)
            beamNode.position = SCNVector3(0, 4.2, z)
            beamNode.name = "beam"
            scene.rootNode.addChildNode(beamNode)
            
            let flange = SCNBox(width: 7.5, height: 0.04, length: 0.3, chamferRadius: 0)
            flange.materials = [beamMat]
            let flangeNode = SCNNode(geometry: flange)
            flangeNode.position = SCNVector3(0, 4.08, z)
            scene.rootNode.addChildNode(flangeNode)
        }
    }
    
    // MARK: - Exposed Pipes
    
    private func addExposedPipes() {
        let pipeMat = SCNMaterial()
        pipeMat.diffuse.contents = UIColor(red: 0.35, green: 0.32, blue: 0.3, alpha: 1)
        pipeMat.metalness.contents = 0.8
        pipeMat.roughness.contents = 0.4
        
        let rustMat = SCNMaterial()
        rustMat.diffuse.contents = UIColor(red: 0.45, green: 0.25, blue: 0.12, alpha: 1)
        rustMat.metalness.contents = 0.5
        rustMat.roughness.contents = 0.85
        
        // Horizontal pipes along left ceiling
        for z: Float in stride(from: -3.0, through: 2.0, by: 2.5) {
            let pipe = SCNCylinder(radius: 0.04, height: 7.0)
            pipe.materials = [pipeMat]
            let pipeNode = SCNNode(geometry: pipe)
            pipeNode.position = SCNVector3(-3.5, 3.7, z)
            pipeNode.eulerAngles.z = Float.pi / 2
            pipeNode.name = "pipe_horizontal"
            scene.rootNode.addChildNode(pipeNode)
        }
        
        // Vertical pipe on right wall (will spark at high destruction)
        let vertPipe = SCNCylinder(radius: 0.05, height: 4.0)
        vertPipe.materials = [rustMat]
        let vertNode = SCNNode(geometry: vertPipe)
        vertNode.position = SCNVector3(3.7, 2.0, -2.5)
        vertNode.name = "pipe_vertical_spark"
        scene.rootNode.addChildNode(vertNode)
        sparkingPipeNode = vertNode
        
        // Elbow joint
        let joint = SCNSphere(radius: 0.07)
        joint.materials = [rustMat]
        let jointNode = SCNNode(geometry: joint)
        jointNode.position = SCNVector3(3.7, 3.7, -2.5)
        scene.rootNode.addChildNode(jointNode)
        
        // Horizontal extension from joint
        let hPipe = SCNCylinder(radius: 0.05, height: 3.0)
        hPipe.materials = [rustMat]
        let hPipeNode = SCNNode(geometry: hPipe)
        hPipeNode.position = SCNVector3(3.7, 3.7, -1.0)
        hPipeNode.eulerAngles.x = Float.pi / 2
        scene.rootNode.addChildNode(hPipeNode)
    }
    
    // MARK: - Ragdoll Dummy
    
    private func addDummy() {
        let skinMat = SCNMaterial()
        skinMat.diffuse.contents = UIColor(red: 0.85, green: 0.7, blue: 0.6, alpha: 1)
        skinMat.roughness.contents = 0.7
        
        // Torso
        let torso = SCNCylinder(radius: 0.25, height: 0.8)
        torso.materials = [skinMat]
        let torsoNode = SCNNode(geometry: torso)
        torsoNode.position = SCNVector3(0, 1.4, -2.5)
        torsoNode.physicsBody = SCNPhysicsBody.dynamic()
        torsoNode.physicsBody?.mass = 20
        torsoNode.physicsBody?.damping = 0.7
        torsoNode.physicsBody?.angularDamping = 0.8
        torsoNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
        torsoNode.physicsBody?.contactTestBitMask = PhysicsCategory.wall | PhysicsCategory.floor
        torsoNode.name = "dummy_torso"
        scene.rootNode.addChildNode(torsoNode)
        destructibleObjects.append(DestructibleObject(node: torsoNode, material: .flesh, maxHits: 15))
        
        // Head
        let head = SCNSphere(radius: 0.18)
        head.materials = [skinMat]
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 2.0, -2.5)
        headNode.physicsBody = SCNPhysicsBody.dynamic()
        headNode.physicsBody?.mass = 5
        headNode.physicsBody?.damping = 0.5
        headNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
        headNode.name = "dummy_head"
        scene.rootNode.addChildNode(headNode)
        destructibleObjects.append(DestructibleObject(node: headNode, material: .flesh, maxHits: 10))
        
        // Arms
        for xOffset: Float in [-0.4, 0.4] {
            let arm = SCNCylinder(radius: 0.08, height: 0.6)
            arm.materials = [skinMat]
            let armNode = SCNNode(geometry: arm)
            armNode.position = SCNVector3(xOffset, 1.4, -2.5)
            armNode.eulerAngles.z = xOffset > 0 ? -0.3 : 0.3
            armNode.physicsBody = SCNPhysicsBody.dynamic()
            armNode.physicsBody?.mass = 3
            armNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
            armNode.name = "dummy_arm"
            scene.rootNode.addChildNode(armNode)
            destructibleObjects.append(DestructibleObject(node: armNode, material: .flesh, maxHits: 8))
        }
        
        // Stand pole
        let pole = SCNCylinder(radius: 0.05, height: 1.2)
        let metalMat = SCNMaterial()
        metalMat.diffuse.contents = UIColor.darkGray
        metalMat.metalness.contents = 0.8
        pole.materials = [metalMat]
        let poleNode = SCNNode(geometry: pole)
        poleNode.position = SCNVector3(0, 0.6, -2.5)
        poleNode.physicsBody = SCNPhysicsBody.static()
        scene.rootNode.addChildNode(poleNode)
        
        // Base
        let base = SCNCylinder(radius: 0.35, height: 0.05)
        base.materials = [metalMat]
        let baseNode = SCNNode(geometry: base)
        baseNode.position = SCNVector3(0, 0.025, -2.5)
        baseNode.physicsBody = SCNPhysicsBody.static()
        scene.rootNode.addChildNode(baseNode)
    }
    
    // MARK: - Tires
    
    private func addTires() {
        let tireMat = SCNMaterial()
        tireMat.diffuse.contents = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        tireMat.roughness.contents = 0.95
        
        for i in 0..<3 {
            let tire = SCNTorus(ringRadius: 0.35, pipeRadius: 0.12)
            tire.materials = [tireMat]
            let tireNode = SCNNode(geometry: tire)
            tireNode.position = SCNVector3(-2.5, 0.35 + Float(i) * 0.3, -2.0)
            tireNode.eulerAngles.x = Float.pi / 2
            tireNode.physicsBody = SCNPhysicsBody.dynamic()
            tireNode.physicsBody?.mass = 8
            tireNode.physicsBody?.friction = 0.8
            tireNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
            tireNode.name = "tire_\(i)"
            scene.rootNode.addChildNode(tireNode)
            destructibleObjects.append(DestructibleObject(node: tireNode, material: .rubber, maxHits: 20))
        }
    }
    
    // MARK: - Table
    
    private func addTable() {
        let woodMat = SCNMaterial()
        woodMat.diffuse.contents = UIColor(red: 0.3, green: 0.2, blue: 0.12, alpha: 1)
        woodMat.roughness.contents = 0.8
        
        let legMat = SCNMaterial()
        legMat.diffuse.contents = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        legMat.metalness.contents = 0.7
        
        // Main table
        let tableTop = SCNBox(width: 1.8, height: 0.06, length: 0.8, chamferRadius: 0.01)
        tableTop.materials = [woodMat]
        let tableNode = SCNNode(geometry: tableTop)
        tableNode.position = SCNVector3(2.5, 0.85, -1.5)
        tableNode.physicsBody = SCNPhysicsBody.dynamic()
        tableNode.physicsBody?.mass = 15
        tableNode.physicsBody?.friction = 0.6
        tableNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
        tableNode.name = "table"
        scene.rootNode.addChildNode(tableNode)
        destructibleObjects.append(DestructibleObject(node: tableNode, material: .wood, maxHits: 8))
        
        // Table legs
        for (x, z) in [(-0.7, -0.3), (0.7, -0.3), (-0.7, 0.3), (0.7, 0.3)] as [(Float, Float)] {
            let leg = SCNCylinder(radius: 0.03, height: 0.85)
            leg.materials = [legMat]
            let legNode = SCNNode(geometry: leg)
            legNode.position = SCNVector3(2.5 + x, 0.425, -1.5 + z)
            legNode.physicsBody = SCNPhysicsBody.dynamic()
            legNode.physicsBody?.mass = 2
            legNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
            legNode.name = "table_leg"
            scene.rootNode.addChildNode(legNode)
            destructibleObjects.append(DestructibleObject(node: legNode, material: .metal, maxHits: 12))
        }
        
        // Smaller back table
        let darkWoodMat = SCNMaterial()
        darkWoodMat.diffuse.contents = UIColor(red: 0.22, green: 0.14, blue: 0.08, alpha: 1)
        darkWoodMat.roughness.contents = 0.85
        let table2Top = SCNBox(width: 1.2, height: 0.05, length: 0.6, chamferRadius: 0.01)
        table2Top.materials = [darkWoodMat]
        let table2Node = SCNNode(geometry: table2Top)
        table2Node.position = SCNVector3(-2.5, 0.75, -3.0)
        table2Node.physicsBody = SCNPhysicsBody.dynamic()
        table2Node.physicsBody?.mass = 10
        table2Node.physicsBody?.friction = 0.5
        table2Node.physicsBody?.categoryBitMask = PhysicsCategory.destructible
        table2Node.name = "table_small"
        scene.rootNode.addChildNode(table2Node)
        destructibleObjects.append(DestructibleObject(node: table2Node, material: .wood, maxHits: 6))
        
        for (x, z) in [(-0.5, -0.25), (0.5, -0.25), (-0.5, 0.25), (0.5, 0.25)] as [(Float, Float)] {
            let leg = SCNCylinder(radius: 0.025, height: 0.75)
            leg.materials = [legMat]
            let legNode = SCNNode(geometry: leg)
            legNode.position = SCNVector3(-2.5 + x, 0.375, -3.0 + z)
            legNode.physicsBody = SCNPhysicsBody.dynamic()
            legNode.physicsBody?.mass = 1.5
            legNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
            legNode.name = "table_leg"
            scene.rootNode.addChildNode(legNode)
            destructibleObjects.append(DestructibleObject(node: legNode, material: .metal, maxHits: 12))
        }
    }
    
    // MARK: - Dining Set
    
    private func addDiningSet() {
        let woodMat = SCNMaterial()
        woodMat.diffuse.contents = UIColor(red: 0.35, green: 0.22, blue: 0.1, alpha: 1)
        woodMat.roughness.contents = 0.8
        
        let legMat = SCNMaterial()
        legMat.diffuse.contents = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        legMat.metalness.contents = 0.7
        
        // Dining table
        let diningTop = SCNBox(width: 1.4, height: 0.05, length: 1.4, chamferRadius: 0.02)
        diningTop.materials = [woodMat]
        let diningNode = SCNNode(geometry: diningTop)
        diningNode.position = SCNVector3(-1.0, 0.8, 0.5)
        diningNode.physicsBody = SCNPhysicsBody.dynamic()
        diningNode.physicsBody?.mass = 18
        diningNode.physicsBody?.friction = 0.5
        diningNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
        diningNode.name = "dining_table"
        scene.rootNode.addChildNode(diningNode)
        destructibleObjects.append(DestructibleObject(node: diningNode, material: .wood, maxHits: 10))
        
        for (x, z) in [(-0.55, -0.55), (0.55, -0.55), (-0.55, 0.55), (0.55, 0.55)] as [(Float, Float)] {
            let leg = SCNCylinder(radius: 0.035, height: 0.78)
            leg.materials = [legMat]
            let legNode = SCNNode(geometry: leg)
            legNode.position = SCNVector3(-1.0 + x, 0.39, 0.5 + z)
            legNode.physicsBody = SCNPhysicsBody.dynamic()
            legNode.physicsBody?.mass = 2.5
            legNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
            legNode.name = "dining_leg"
            scene.rootNode.addChildNode(legNode)
            destructibleObjects.append(DestructibleObject(node: legNode, material: .metal, maxHits: 12))
        }
        
        // 4 Chairs
        let chairPositions: [(Float, Float)] = [(-1.0, -0.5), (-1.0, 1.5), (-2.0, 0.5), (0.0, 0.5)]
        let chairRotations: [Float] = [0, Float.pi, Float.pi / 2, -Float.pi / 2]
        
        for (i, (cx, cz)) in chairPositions.enumerated() {
            addChair(at: SCNVector3(cx, 0, cz), rotation: chairRotations[i], index: i, woodMat: woodMat, legMat: legMat)
        }
    }
    
    private func addChair(at position: SCNVector3, rotation: Float, index: Int, woodMat: SCNMaterial, legMat: SCNMaterial) {
        let seat = SCNBox(width: 0.4, height: 0.04, length: 0.4, chamferRadius: 0.01)
        seat.materials = [woodMat]
        let seatNode = SCNNode(geometry: seat)
        seatNode.position = SCNVector3(position.x, 0.48, position.z)
        seatNode.eulerAngles.y = rotation
        seatNode.physicsBody = SCNPhysicsBody.dynamic()
        seatNode.physicsBody?.mass = 4
        seatNode.physicsBody?.friction = 0.4
        seatNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
        seatNode.name = "chair_\(index)"
        scene.rootNode.addChildNode(seatNode)
        destructibleObjects.append(DestructibleObject(node: seatNode, material: .wood, maxHits: 6))
        
        let back = SCNBox(width: 0.4, height: 0.45, length: 0.03, chamferRadius: 0.005)
        back.materials = [woodMat]
        let backNode = SCNNode(geometry: back)
        backNode.position = SCNVector3(position.x, 0.72, position.z - 0.18)
        backNode.eulerAngles.y = rotation
        backNode.physicsBody = SCNPhysicsBody.dynamic()
        backNode.physicsBody?.mass = 2
        backNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
        backNode.name = "chair_back_\(index)"
        scene.rootNode.addChildNode(backNode)
        destructibleObjects.append(DestructibleObject(node: backNode, material: .wood, maxHits: 5))
        
        for (lx, lz) in [(-0.15, -0.15), (0.15, -0.15), (-0.15, 0.15), (0.15, 0.15)] as [(Float, Float)] {
            let leg = SCNCylinder(radius: 0.02, height: 0.46)
            leg.materials = [legMat]
            let legNode = SCNNode(geometry: leg)
            legNode.position = SCNVector3(position.x + lx, 0.23, position.z + lz)
            legNode.physicsBody = SCNPhysicsBody.dynamic()
            legNode.physicsBody?.mass = 0.8
            legNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
            legNode.name = "chair_leg_\(index)"
            scene.rootNode.addChildNode(legNode)
            destructibleObjects.append(DestructibleObject(node: legNode, material: .metal, maxHits: 15))
        }
    }
    
    // MARK: - Bottles
    
    private func addBottles() {
        let glassMat = SCNMaterial()
        glassMat.diffuse.contents = UIColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 0.7)
        glassMat.transparency = 0.6
        glassMat.roughness.contents = 0.1
        
        for i in 0..<4 {
            let bottle = SCNCylinder(radius: 0.04, height: 0.25)
            bottle.materials = [glassMat]
            let bottleNode = SCNNode(geometry: bottle)
            bottleNode.position = SCNVector3(2.0 + Float(i) * 0.3, 1.0, -1.5)
            bottleNode.physicsBody = SCNPhysicsBody.dynamic()
            bottleNode.physicsBody?.mass = 0.8
            bottleNode.physicsBody?.friction = 0.3
            bottleNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
            bottleNode.physicsBody?.contactTestBitMask = PhysicsCategory.wall | PhysicsCategory.floor
            bottleNode.name = "bottle_\(i)"
            scene.rootNode.addChildNode(bottleNode)
            destructibleObjects.append(DestructibleObject(node: bottleNode, material: .glass, maxHits: 2))
        }
        
        // Brown bottles on dining table
        let brownGlassMat = SCNMaterial()
        brownGlassMat.diffuse.contents = UIColor(red: 0.35, green: 0.2, blue: 0.05, alpha: 0.8)
        brownGlassMat.transparency = 0.7
        
        for i in 0..<3 {
            let bottle = SCNCylinder(radius: 0.035, height: 0.22)
            bottle.materials = [brownGlassMat]
            let node = SCNNode(geometry: bottle)
            node.position = SCNVector3(-1.0 + Float(i) * 0.25 - 0.25, 0.94, 0.5)
            node.physicsBody = SCNPhysicsBody.dynamic()
            node.physicsBody?.mass = 0.6
            node.physicsBody?.friction = 0.3
            node.physicsBody?.categoryBitMask = PhysicsCategory.destructible
            node.physicsBody?.contactTestBitMask = PhysicsCategory.wall | PhysicsCategory.floor
            node.name = "bottle_dining_\(i)"
            scene.rootNode.addChildNode(node)
            destructibleObjects.append(DestructibleObject(node: node, material: .glass, maxHits: 2))
        }
    }
    
    // MARK: - TV / Monitor
    
    private func addTV() {
        let tvMat = SCNMaterial()
        tvMat.diffuse.contents = UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1)
        tvMat.roughness.contents = 0.3
        
        let screenMat = SCNMaterial()
        screenMat.diffuse.contents = UIColor(red: 0.05, green: 0.1, blue: 0.2, alpha: 1)
        screenMat.roughness.contents = 0.05
        screenMat.emission.contents = UIColor(red: 0.0, green: 0.05, blue: 0.1, alpha: 1)
        
        let tv = SCNBox(width: 0.8, height: 0.5, length: 0.08, chamferRadius: 0.01)
        tv.materials = [screenMat, tvMat, tvMat, tvMat, tvMat, tvMat]
        let tvNode = SCNNode(geometry: tv)
        tvNode.position = SCNVector3(-2.0, 1.5, -3.5)
        tvNode.physicsBody = SCNPhysicsBody.dynamic()
        tvNode.physicsBody?.mass = 8
        tvNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
        tvNode.physicsBody?.contactTestBitMask = PhysicsCategory.wall | PhysicsCategory.floor
        tvNode.name = "tv"
        scene.rootNode.addChildNode(tvNode)
        destructibleObjects.append(DestructibleObject(node: tvNode, material: .glass, maxHits: 4))
        
        // TV stand
        let standMat = SCNMaterial()
        standMat.diffuse.contents = UIColor.darkGray
        standMat.metalness.contents = 0.8
        let stand = SCNCylinder(radius: 0.04, height: 0.5)
        stand.materials = [standMat]
        let standNode = SCNNode(geometry: stand)
        standNode.position = SCNVector3(-2.0, 1.0, -3.5)
        standNode.physicsBody = SCNPhysicsBody.static()
        scene.rootNode.addChildNode(standNode)
    }
    
    // MARK: - Additional TVs (wall-mounted, multiple)

    private func addMoreTVs() {
        let tvPositions: [(SCNVector3, SCNVector3)] = [
            // Right wall TV (large, flat-screen)
            (SCNVector3(3.7, 2.0, -1.0), SCNVector3(0, -Float.pi / 2, 0)),
            // Back wall TV (center, large)
            (SCNVector3(0, 2.5, -4.3), SCNVector3(0, 0, 0)),
            // Left wall TV (smaller)
            (SCNVector3(-3.7, 1.8, 1.0), SCNVector3(0, Float.pi / 2, 0)),
        ]

        for (i, (pos, rot)) in tvPositions.enumerated() {
            let width: CGFloat = i == 1 ? 1.2 : 0.9
            let height: CGFloat = i == 1 ? 0.7 : 0.55

            let screenMat = SCNMaterial()
            screenMat.diffuse.contents = UIColor(red: 0.02, green: 0.05, blue: 0.1, alpha: 1)
            screenMat.emission.contents = UIColor(red: 0.0, green: 0.03, blue: 0.08, alpha: 1)
            screenMat.roughness.contents = 0.02

            let bezelMat = SCNMaterial()
            bezelMat.diffuse.contents = UIColor(red: 0.08, green: 0.08, blue: 0.1, alpha: 1)
            bezelMat.metalness.contents = 0.7
            bezelMat.roughness.contents = 0.3

            let tv = SCNBox(width: width, height: height, length: 0.05, chamferRadius: 0.005)
            tv.materials = [screenMat, bezelMat, bezelMat, bezelMat, bezelMat, bezelMat]

            let tvNode = SCNNode(geometry: tv)
            tvNode.position = pos
            tvNode.eulerAngles = rot
            tvNode.physicsBody = SCNPhysicsBody.dynamic()
            tvNode.physicsBody?.mass = 10
            tvNode.physicsBody?.isAffectedByGravity = false // Wall-mounted initially
            tvNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
            tvNode.physicsBody?.contactTestBitMask = PhysicsCategory.wall | PhysicsCategory.floor
            tvNode.name = "wall_tv_\(i)"
            scene.rootNode.addChildNode(tvNode)
            destructibleObjects.append(DestructibleObject(node: tvNode, material: .glass, maxHits: 3))
        }
    }

    // MARK: - Plates
    
    private func addPlates() {
        for i in 0..<6 {
            let plate = SCNCylinder(radius: 0.13, height: 0.015)
            let plateMat = SCNMaterial()
            plateMat.diffuse.contents = UIColor.white
            plateMat.roughness.contents = 0.15
            plate.materials = [plateMat]
            let node = SCNNode(geometry: plate)
            node.position = SCNVector3(2.5 + Float(i % 3) * 0.3 - 0.3, 0.92 + Float(i / 3) * 0.02, -1.5)
            node.physicsBody = SCNPhysicsBody.dynamic()
            node.physicsBody?.mass = 0.4
            node.physicsBody?.friction = 0.2
            node.physicsBody?.categoryBitMask = PhysicsCategory.destructible
            node.physicsBody?.contactTestBitMask = PhysicsCategory.wall | PhysicsCategory.floor
            node.name = "plate_\(i)"
            scene.rootNode.addChildNode(node)
            destructibleObjects.append(DestructibleObject(node: node, material: .ceramic, maxHits: 1))
        }
        
        // Dining table plates
        for i in 0..<4 {
            let plate = SCNCylinder(radius: 0.12, height: 0.012)
            let plateMat = SCNMaterial()
            plateMat.diffuse.contents = UIColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1)
            plateMat.roughness.contents = 0.12
            plate.materials = [plateMat]
            let node = SCNNode(geometry: plate)
            let angle = Float(i) * (Float.pi / 2)
            node.position = SCNVector3(
                -1.0 + cosf(angle) * 0.4,
                0.86,
                0.5 + sinf(angle) * 0.4
            )
            node.physicsBody = SCNPhysicsBody.dynamic()
            node.physicsBody?.mass = 0.35
            node.physicsBody?.friction = 0.2
            node.physicsBody?.categoryBitMask = PhysicsCategory.destructible
            node.physicsBody?.contactTestBitMask = PhysicsCategory.wall | PhysicsCategory.floor
            node.name = "dining_plate_\(i)"
            scene.rootNode.addChildNode(node)
            destructibleObjects.append(DestructibleObject(node: node, material: .ceramic, maxHits: 1))
        }
    }
    
    // MARK: - Picture Frames
    
    private func addPictureFrames() {
        let frameMat = SCNMaterial()
        frameMat.diffuse.contents = UIColor(red: 0.2, green: 0.15, blue: 0.08, alpha: 1)
        frameMat.roughness.contents = 0.7
        
        let pictureColors: [UIColor] = [
            UIColor(red: 0.3, green: 0.4, blue: 0.6, alpha: 1),
            UIColor(red: 0.6, green: 0.3, blue: 0.2, alpha: 1),
            UIColor(red: 0.2, green: 0.5, blue: 0.3, alpha: 1),
            UIColor(red: 0.5, green: 0.2, blue: 0.4, alpha: 1),
            UIColor(red: 0.7, green: 0.6, blue: 0.3, alpha: 1),
            UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1),
        ]
        
        let roomDepth: Float = 9.0
        let backWallZ: Float = -roomDepth / 2 + 0.14
        let backFrameData: [(Float, Float, CGFloat, CGFloat)] = [
            (-2.0, 2.2, 0.7, 0.5),
            (0.0, 2.0, 0.9, 0.6),
            (2.0, 2.3, 0.6, 0.45),
        ]
        
        for (i, (x, y, w, h)) in backFrameData.enumerated() {
            addFrame(position: SCNVector3(x, y, backWallZ), size: (w, h), rotation: SCNVector3(0, 0, 0), color: pictureColors[i], frameMat: frameMat, name: "frame_back_\(i)")
        }
        
        // Left wall frames
        let leftWallX: Float = -3.85
        addFrame(position: SCNVector3(leftWallX, 1.8, 0.6), size: (0.5, 0.5), rotation: SCNVector3(0, Float.pi / 2, 0), color: pictureColors[3], frameMat: frameMat, name: "frame_left_0")
        addFrame(position: SCNVector3(leftWallX, 2.2, -1.5), size: (0.65, 0.5), rotation: SCNVector3(0, Float.pi / 2, 0), color: pictureColors[4], frameMat: frameMat, name: "frame_left_1")
        
        // Right wall frame
        addFrame(position: SCNVector3(3.85, 2.0, -1.0), size: (0.8, 0.55), rotation: SCNVector3(0, -Float.pi / 2, 0), color: pictureColors[5], frameMat: frameMat, name: "frame_right_0")
    }
    
    private func addFrame(position: SCNVector3, size: (CGFloat, CGFloat), rotation: SCNVector3, color: UIColor, frameMat: SCNMaterial, name: String) {
        let (w, h) = size
        let frameNode = SCNNode()
        frameNode.position = position
        frameNode.eulerAngles = rotation
        frameNode.name = name
        
        // Canvas
        let canvas = SCNBox(width: w - 0.06, height: h - 0.06, length: 0.02, chamferRadius: 0)
        let canvasMat = SCNMaterial()
        canvasMat.diffuse.contents = color
        canvasMat.roughness.contents = 0.5
        canvas.materials = [canvasMat]
        let canvasNode = SCNNode(geometry: canvas)
        frameNode.addChildNode(canvasNode)
        
        // Frame borders
        let topBorder = SCNBox(width: w, height: 0.04, length: 0.04, chamferRadius: 0)
        topBorder.materials = [frameMat]
        let topNode = SCNNode(geometry: topBorder)
        topNode.position = SCNVector3(0, Float(h / 2), 0.01)
        frameNode.addChildNode(topNode)
        
        let bottomNode = SCNNode(geometry: topBorder)
        bottomNode.position = SCNVector3(0, Float(-h / 2), 0.01)
        frameNode.addChildNode(bottomNode)
        
        let sideBorder = SCNBox(width: 0.04, height: h, length: 0.04, chamferRadius: 0)
        sideBorder.materials = [frameMat]
        let leftBorderNode = SCNNode(geometry: sideBorder)
        leftBorderNode.position = SCNVector3(Float(-w / 2), 0, 0.01)
        frameNode.addChildNode(leftBorderNode)
        
        let rightBorderNode = SCNNode(geometry: sideBorder)
        rightBorderNode.position = SCNVector3(Float(w / 2), 0, 0.01)
        frameNode.addChildNode(rightBorderNode)
        
        frameNode.physicsBody = SCNPhysicsBody.dynamic()
        frameNode.physicsBody?.mass = 3
        frameNode.physicsBody?.friction = 0.4
        frameNode.physicsBody?.damping = 0.3
        frameNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
        
        scene.rootNode.addChildNode(frameNode)
        destructibleObjects.append(DestructibleObject(node: frameNode, material: .wood, maxHits: 4))
    }
    
    // MARK: - Car Door Panel (New Environmental Object)
    
    private func addCarDoorPanel() {
        let metalMat = SCNMaterial()
        metalMat.diffuse.contents = UIColor(red: 0.3, green: 0.35, blue: 0.4, alpha: 1)
        metalMat.metalness.contents = 0.85
        metalMat.roughness.contents = 0.3
        
        // Flat car door leaning against right wall
        let door = SCNBox(width: 0.9, height: 1.2, length: 0.05, chamferRadius: 0.01)
        door.materials = [metalMat]
        let doorNode = SCNNode(geometry: door)
        doorNode.position = SCNVector3(3.6, 0.7, 0.5)
        doorNode.eulerAngles = SCNVector3(0, -0.15, -0.05)
        doorNode.physicsBody = SCNPhysicsBody.dynamic()
        doorNode.physicsBody?.mass = 25
        doorNode.physicsBody?.friction = 0.7
        doorNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
        doorNode.name = "car_door"
        scene.rootNode.addChildNode(doorNode)
        destructibleObjects.append(DestructibleObject(node: doorNode, material: .metal, maxHits: 20))
        carDoorNode = doorNode
        
        // Door handle
        let handleMat = SCNMaterial()
        handleMat.diffuse.contents = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        handleMat.metalness.contents = 0.9
        let handle = SCNBox(width: 0.15, height: 0.03, length: 0.04, chamferRadius: 0.01)
        handle.materials = [handleMat]
        let handleNode = SCNNode(geometry: handle)
        handleNode.position = SCNVector3(0.2, 0.1, 0.04)
        doorNode.addChildNode(handleNode)
    }
    
    // MARK: - Mirror / Glass Panel
    
    private func addMirrorPanel() {
        let mirrorMat = SCNMaterial()
        mirrorMat.diffuse.contents = UIColor(red: 0.85, green: 0.88, blue: 0.9, alpha: 1)
        mirrorMat.metalness.contents = 0.95
        mirrorMat.roughness.contents = 0.02
        mirrorMat.reflective.contents = UIColor(red: 0.6, green: 0.65, blue: 0.7, alpha: 1)
        
        let mirror = SCNBox(width: 0.8, height: 1.0, length: 0.02, chamferRadius: 0)
        mirror.materials = [mirrorMat]
        let node = SCNNode(geometry: mirror)
        node.position = SCNVector3(-3.8, 1.8, 1.0)
        node.eulerAngles.y = Float.pi / 2
        node.physicsBody = SCNPhysicsBody.dynamic()
        node.physicsBody?.mass = 5
        node.physicsBody?.friction = 0.3
        node.physicsBody?.categoryBitMask = PhysicsCategory.destructible
        node.name = "mirror"
        scene.rootNode.addChildNode(node)
        destructibleObjects.append(DestructibleObject(node: node, material: .glass, maxHits: 3))
        mirrorNode = node
        
        // Mirror frame
        let frameMat = SCNMaterial()
        frameMat.diffuse.contents = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        frameMat.metalness.contents = 0.7
        
        let topFrame = SCNBox(width: 0.84, height: 0.03, length: 0.03, chamferRadius: 0)
        topFrame.materials = [frameMat]
        let topFrameNode = SCNNode(geometry: topFrame)
        topFrameNode.position = SCNVector3(0, 0.5, 0.015)
        node.addChildNode(topFrameNode)
        
        let bottomFrameNode = SCNNode(geometry: topFrame)
        bottomFrameNode.position = SCNVector3(0, -0.5, 0.015)
        node.addChildNode(bottomFrameNode)
    }
    
    // MARK: - Fire Extinguisher
    
    private func addFireExtinguisher() {
        let redMat = SCNMaterial()
        redMat.diffuse.contents = UIColor(red: 0.85, green: 0.1, blue: 0.05, alpha: 1)
        redMat.metalness.contents = 0.6
        redMat.roughness.contents = 0.3
        
        // Cylinder body
        let body = SCNCylinder(radius: 0.08, height: 0.45)
        body.materials = [redMat]
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(3.2, 0.3, -3.5)
        bodyNode.physicsBody = SCNPhysicsBody.dynamic()
        bodyNode.physicsBody?.mass = 6
        bodyNode.physicsBody?.friction = 0.5
        bodyNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
        bodyNode.name = "fire_extinguisher"
        scene.rootNode.addChildNode(bodyNode)
        destructibleObjects.append(DestructibleObject(node: bodyNode, material: .metal, maxHits: 5))
        fireExtinguisherNode = bodyNode
        
        // Nozzle/handle on top
        let nozzleMat = SCNMaterial()
        nozzleMat.diffuse.contents = UIColor.darkGray
        nozzleMat.metalness.contents = 0.8
        let nozzle = SCNCylinder(radius: 0.02, height: 0.08)
        nozzle.materials = [nozzleMat]
        let nozzleNode = SCNNode(geometry: nozzle)
        nozzleNode.position = SCNVector3(0, 0.26, 0)
        bodyNode.addChildNode(nozzleNode)
        
        // Handle
        let handle = SCNBox(width: 0.06, height: 0.02, length: 0.04, chamferRadius: 0.005)
        handle.materials = [nozzleMat]
        let handleNode = SCNNode(geometry: handle)
        handleNode.position = SCNVector3(0.04, 0.22, 0)
        bodyNode.addChildNode(handleNode)
    }
    
    // MARK: - Toolbox
    
    private func addToolbox() {
        let toolboxMat = SCNMaterial()
        toolboxMat.diffuse.contents = UIColor(red: 0.15, green: 0.2, blue: 0.35, alpha: 1)
        toolboxMat.metalness.contents = 0.7
        toolboxMat.roughness.contents = 0.4
        
        let toolbox = SCNBox(width: 0.5, height: 0.25, length: 0.25, chamferRadius: 0.01)
        toolbox.materials = [toolboxMat]
        let toolboxNode = SCNNode(geometry: toolbox)
        toolboxNode.position = SCNVector3(1.5, 0.15, 2.0)
        toolboxNode.physicsBody = SCNPhysicsBody.dynamic()
        toolboxNode.physicsBody?.mass = 8
        toolboxNode.physicsBody?.friction = 0.6
        toolboxNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
        toolboxNode.name = "toolbox"
        scene.rootNode.addChildNode(toolboxNode)
        destructibleObjects.append(DestructibleObject(node: toolboxNode, material: .metal, maxHits: 10))
        
        // Handle on top
        let handleMat = SCNMaterial()
        handleMat.diffuse.contents = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
        handleMat.metalness.contents = 0.8
        let handle = SCNBox(width: 0.3, height: 0.02, length: 0.02, chamferRadius: 0.005)
        handle.materials = [handleMat]
        let handleNode = SCNNode(geometry: handle)
        handleNode.position = SCNVector3(0, 0.14, 0)
        toolboxNode.addChildNode(handleNode)
    }
    
    // MARK: - Cinder Blocks
    
    private func addCinderBlocks() {
        let cinderMat = SCNMaterial()
        cinderMat.diffuse.contents = UIColor(red: 0.55, green: 0.53, blue: 0.5, alpha: 1)
        cinderMat.roughness.contents = 0.95
        
        // Stack of cinder blocks near back-right
        for row in 0..<3 {
            for col in 0..<2 {
                let block = SCNBox(width: 0.4, height: 0.2, length: 0.2, chamferRadius: 0)
                block.materials = [cinderMat]
                let blockNode = SCNNode(geometry: block)
                blockNode.position = SCNVector3(
                    2.8 + Float(col) * 0.42,
                    0.12 + Float(row) * 0.22,
                    -3.2
                )
                // Slight random rotation for realism
                blockNode.eulerAngles.y = Float.random(in: -0.03...0.03)
                blockNode.physicsBody = SCNPhysicsBody.dynamic()
                blockNode.physicsBody?.mass = 12
                blockNode.physicsBody?.friction = 0.8
                blockNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
                blockNode.physicsBody?.contactTestBitMask = PhysicsCategory.floor | PhysicsCategory.wall
                blockNode.name = "cinder_block_\(row)_\(col)"
                scene.rootNode.addChildNode(blockNode)
                destructibleObjects.append(DestructibleObject(node: blockNode, material: .concrete, maxHits: 8))
            }
        }
    }
    
    // MARK: - CRT Monitor
    
    private func addCRTMonitor() {
        let crtMat = SCNMaterial()
        crtMat.diffuse.contents = UIColor(red: 0.75, green: 0.72, blue: 0.6, alpha: 1)
        crtMat.roughness.contents = 0.7
        
        let screenMat = SCNMaterial()
        screenMat.diffuse.contents = UIColor(red: 0.05, green: 0.08, blue: 0.05, alpha: 1)
        screenMat.emission.contents = UIColor(red: 0.0, green: 0.03, blue: 0.0, alpha: 1)
        screenMat.roughness.contents = 0.05
        
        // Boxy CRT body
        let crtBody = SCNBox(width: 0.4, height: 0.35, length: 0.4, chamferRadius: 0.02)
        crtBody.materials = [screenMat, crtMat, crtMat, crtMat, crtMat, crtMat]
        let crtNode = SCNNode(geometry: crtBody)
        crtNode.position = SCNVector3(-2.5, 0.93, -3.0)
        crtNode.physicsBody = SCNPhysicsBody.dynamic()
        crtNode.physicsBody?.mass = 12
        crtNode.physicsBody?.friction = 0.5
        crtNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
        crtNode.physicsBody?.contactTestBitMask = PhysicsCategory.floor | PhysicsCategory.wall
        crtNode.name = "crt_monitor"
        scene.rootNode.addChildNode(crtNode)
        destructibleObjects.append(DestructibleObject(node: crtNode, material: .glass, maxHits: 3))
    }
    
    // MARK: - Wooden Crate
    
    private func addWoodenCrate() {
        let crateMat = SCNMaterial()
        crateMat.diffuse.contents = UIColor(red: 0.55, green: 0.4, blue: 0.22, alpha: 1)
        crateMat.roughness.contents = 0.9
        
        let crate = SCNBox(width: 0.6, height: 0.5, length: 0.5, chamferRadius: 0)
        crate.materials = [crateMat]
        let crateNode = SCNNode(geometry: crate)
        crateNode.position = SCNVector3(1.0, 0.3, -3.0)
        crateNode.eulerAngles.y = 0.2
        crateNode.physicsBody = SCNPhysicsBody.dynamic()
        crateNode.physicsBody?.mass = 10
        crateNode.physicsBody?.friction = 0.6
        crateNode.physicsBody?.categoryBitMask = PhysicsCategory.destructible
        crateNode.name = "wooden_crate"
        scene.rootNode.addChildNode(crateNode)
        destructibleObjects.append(DestructibleObject(node: crateNode, material: .wood, maxHits: 4))
        
        // Plank detail lines on crate
        let plankMat = SCNMaterial()
        plankMat.diffuse.contents = UIColor(red: 0.4, green: 0.28, blue: 0.15, alpha: 1)
        for i in 0..<3 {
            let plank = SCNBox(width: 0.58, height: 0.01, length: 0.01, chamferRadius: 0)
            plank.materials = [plankMat]
            let plankNode = SCNNode(geometry: plank)
            plankNode.position = SCNVector3(0, -0.15 + Float(i) * 0.15, 0.26)
            crateNode.addChildNode(plankNode)
        }
    }
    
    // MARK: - Hanging Light Fixture
    
    private func addHangingLightFixture() {
        // Chain from ceiling
        let chainMat = SCNMaterial()
        chainMat.diffuse.contents = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
        chainMat.metalness.contents = 0.8
        
        let chain = SCNCylinder(radius: 0.01, height: 0.8)
        chain.materials = [chainMat]
        let chainNode = SCNNode(geometry: chain)
        chainNode.position = SCNVector3(1.5, 3.9, -1.0)
        chainNode.name = "hanging_chain"
        scene.rootNode.addChildNode(chainNode)
        hangingLightChain = chainNode
        
        // Light fixture (industrial metal cone)
        let fixtureMat = SCNMaterial()
        fixtureMat.diffuse.contents = UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1)
        fixtureMat.metalness.contents = 0.7
        
        let fixture = SCNCone(topRadius: 0.02, bottomRadius: 0.2, height: 0.15)
        fixture.materials = [fixtureMat]
        let fixtureNode = SCNNode(geometry: fixture)
        fixtureNode.position = SCNVector3(1.5, 3.45, -1.0)
        fixtureNode.name = "hanging_light"
        
        // Attach a light to the fixture
        let fixtureLight = SCNLight()
        fixtureLight.type = .spot
        fixtureLight.color = UIColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1)
        fixtureLight.intensity = 500
        fixtureLight.spotInnerAngle = 30
        fixtureLight.spotOuterAngle = 60
        fixtureLight.castsShadow = true
        fixtureNode.light = fixtureLight
        
        scene.rootNode.addChildNode(fixtureNode)
        hangingLightFixture = fixtureNode
        
        // Start pendulum swing at medium destruction
        let swing = SCNAction.sequence([
            SCNAction.rotateBy(x: 0, y: 0, z: 0.05, duration: 1.0),
            SCNAction.rotateBy(x: 0, y: 0, z: -0.1, duration: 2.0),
            SCNAction.rotateBy(x: 0, y: 0, z: 0.05, duration: 1.0),
        ])
        fixtureNode.runAction(SCNAction.repeatForever(swing), forKey: "pendulum")
    }
    
    // MARK: - Ambient Systems
    
    private func setupAmbientSystems() {
        setupDustMotes()
        setupFloorHaze()
        startFluorescentFlicker()
        startAmbientDrips()
    }
    
    /// Dust motes floating in light beams
    private func setupDustMotes() {
        let dustSystem = SCNParticleSystem()
        dustSystem.particleSize = 0.008
        dustSystem.particleSizeVariation = 0.004
        dustSystem.birthRate = 15
        dustSystem.emissionDuration = CGFloat.greatestFiniteMagnitude
        dustSystem.particleLifeSpan = 12.0
        dustSystem.particleLifeSpanVariation = 4.0
        dustSystem.spreadingAngle = 180
        dustSystem.particleVelocity = 0.02
        dustSystem.particleVelocityVariation = 0.01
        dustSystem.particleColor = UIColor(white: 0.9, alpha: 0.4)
        dustSystem.particleColorVariation = SCNVector4(0, 0, 0, 0.2)
        dustSystem.blendMode = .additive
        dustSystem.isAffectedByGravity = false
        dustSystem.isAffectedByPhysicsFields = false
        dustSystem.particleImage = cachedCircleImage8White
        
        let emitter = SCNNode()
        emitter.position = SCNVector3(0, 2.5, 0)
        emitter.addParticleSystem(dustSystem)
        emitter.name = "dust_mote_emitter"
        scene.rootNode.addChildNode(emitter)
        dustMoteEmitter = emitter
    }
    
    /// Low-lying floor haze for atmosphere
    private func setupFloorHaze() {
        let haze = SCNPlane(width: 7.0, height: 8.0)
        let hazeMat = SCNMaterial()
        hazeMat.diffuse.contents = UIColor(white: 0.5, alpha: 0.08)
        hazeMat.emission.contents = UIColor(white: 0.3, alpha: 0.05)
        hazeMat.isDoubleSided = true
        hazeMat.writesToDepthBuffer = false
        hazeMat.readsFromDepthBuffer = true
        haze.materials = [hazeMat]
        let hazeNode = SCNNode(geometry: haze)
        hazeNode.position = SCNVector3(0, 0.05, 0)
        hazeNode.eulerAngles.x = -Float.pi / 2
        hazeNode.name = "floor_haze"
        hazeNode.opacity = 0.6
        scene.rootNode.addChildNode(hazeNode)
        floorHazeNode = hazeNode
        
        // Animate subtle movement
        let drift = SCNAction.sequence([
            SCNAction.moveBy(x: 0.1, y: 0, z: 0.05, duration: 5.0),
            SCNAction.moveBy(x: -0.1, y: 0, z: -0.05, duration: 5.0),
        ])
        hazeNode.runAction(SCNAction.repeatForever(drift))
    }
    
    /// Fluorescent light flicker effect
    private func startFluorescentFlicker() {
        guard let fluorescent = fluorescentLight else { return }
        
        let flickerSequence = SCNAction.sequence([
            SCNAction.customAction(duration: 0.05) { node, _ in
                node.light?.intensity = CGFloat.random(in: 100...400)
            },
            SCNAction.wait(duration: Double.random(in: 3.0...8.0)),
            SCNAction.customAction(duration: 0.03) { node, _ in
                node.light?.intensity = 50
            },
            SCNAction.wait(duration: 0.05),
            SCNAction.customAction(duration: 0.03) { node, _ in
                node.light?.intensity = 350
            },
            SCNAction.wait(duration: 0.08),
            SCNAction.customAction(duration: 0.03) { node, _ in
                node.light?.intensity = 80
            },
            SCNAction.wait(duration: 0.04),
            SCNAction.customAction(duration: 0.03) { node, _ in
                node.light?.intensity = 300
            },
        ])
        fluorescent.runAction(SCNAction.repeatForever(flickerSequence), forKey: "flicker")
    }
    
    /// Ambient drip sounds at random intervals
    private func startAmbientDrips() {
        scheduleDrip()
    }
    
    private func scheduleDrip() {
        let delay = Double.random(in: 8.0...20.0)
        dripTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // Subtle drip sound
                let dripSounds: [UInt32] = [1104, 1100, 1054]
                AudioServicesPlaySystemSound(SystemSoundID(dripSounds.randomElement() ?? 1104))
                self.scheduleDrip()
            }
        }
    }
    
    // MARK: - Background Music
    
    private func startBackgroundMusic() {
        AudioPlayerService.shared.playBackgroundMusic(fileName: "rock_instrumental")
    }
    
    // MARK: - ============================================================
    // MARK: - PUBLIC API (Called by DestructionRoomView)
    // MARK: - ============================================================
    
    // MARK: - Hit Object (Tap)
    
    func hitObject(with tool: RageTool) {
        guard tool != .spray else { return }
        hitObjectAtRandom(with: tool)
    }

    /// NEW: Hit a specific object at a screen point (tap-to-destroy)
    func hitObjectAt(point: CGPoint, in scnView: SCNView, with tool: RageTool) {
        guard tool != .spray else { return }

        // SceneKit hit test — find what the user actually tapped
        let hitResults = scnView.hitTest(point, options: [
            .searchMode: SCNHitTestSearchMode.closest.rawValue,
            .ignoreHiddenNodes: true
        ])

        // Find the first destructible object in hit results
        for result in hitResults {
            var node: SCNNode? = result.node
            // Walk up the node tree to find our destructible wrapper
            while let current = node {
                if let index = destructibleObjects.firstIndex(where: { $0.node == current && !$0.isDestroyed }) {
                    // Found a destructible object — hit it!
                    applyHitToObject(at: index, with: tool, hitPoint: result.worldCoordinates)
                    return
                }
                node = current.parent
            }
        }

        // If no specific object hit, fall back to nearest object
        hitObjectAtRandom(with: tool)
    }

    /// Hit a specific object by index
    private func applyHitToObject(at index: Int, with tool: RageTool, hitPoint: SCNVector3) {
        updateCombo()
        totalHitCount += 1

        let target = destructibleObjects[index]
        lastHitMaterial = target.material.rawValue

        let toolMultiplier = toolForceMultiplier(tool)
        let comboMultiplier = calculateComboForceMultiplier()
        let materialResistance = target.material.weight / 10.0
        let effectiveForce = toolMultiplier * comboMultiplier / max(materialResistance, 0.5)

        // Direction away from camera for more natural physics
        let directionFromCamera = SCNVector3(
            target.node.position.x - cameraNode.position.x,
            1.5,
            target.node.position.z - cameraNode.position.z
        )
        let normalized = SCNVector3(
            directionFromCamera.x / max(1, abs(directionFromCamera.x) + abs(directionFromCamera.z)) * effectiveForce,
            directionFromCamera.y * effectiveForce,
            directionFromCamera.z / max(1, abs(directionFromCamera.x) + abs(directionFromCamera.z)) * effectiveForce
        )

        target.node.physicsBody?.applyForce(normalized, asImpulse: true)
        target.node.physicsBody?.applyTorque(SCNVector4(
            Float.random(in: -1...1),
            Float.random(in: -1...1),
            Float.random(in: -1...1),
            effectiveForce * 3
        ), asImpulse: true)

        // Spawn particles at hit point
        spawnMaterialParticles(at: hitPoint, material: target.material, intensity: effectiveForce)

        // Haptic + sound
        triggerLayeredHaptic(tool: tool, material: target.material)
        playMaterialSound(material: target.material, tool: tool, intensity: effectiveForce)

        // Camera shake
        let shakeIntensity = cameraShakeIntensity(for: tool)
        triggerCameraShake(intensity: shakeIntensity * comboMultiplier)

        // Screen flash
        triggerScreenFlash(color: flashColorForMaterial(target.material), intensity: Double(effectiveForce * 0.15))

        // Slow motion check
        if shouldTriggerSlowMotion(tool: tool) {
            activateSlowMotion()
        }

        // Update hit count and check destruction
        destructibleObjects[index].hitCount += 1

        // Enable gravity on wall-mounted objects after first hit (TVs fall off wall)
        if target.node.physicsBody?.isAffectedByGravity == false {
            target.node.physicsBody?.isAffectedByGravity = true
        }

        if destructibleObjects[index].hitCount >= destructibleObjects[index].maxHits {
            destroyObject(at: index)
        }

        // Update destruction level
        let destroyed = destructibleObjects.filter { $0.isDestroyed }.count
        destructionLevel = Double(destroyed) / Double(max(1, destructibleObjects.count))
        updateRoomDeterioration()
    }

    /// Throw an object (swipe gesture)
    func throwObjectAt(point: CGPoint, in scnView: SCNView, velocity: CGPoint) {
        let hitResults = scnView.hitTest(point, options: [
            .searchMode: SCNHitTestSearchMode.closest.rawValue
        ])

        for result in hitResults {
            var node: SCNNode? = result.node
            while let current = node {
                if let index = destructibleObjects.firstIndex(where: { $0.node == current && !$0.isDestroyed }) {
                    let throwForce = SCNVector3(
                        Float(velocity.x) * 0.02,
                        Float(-velocity.y) * 0.02 + 3.0,
                        -8.0
                    )
                    destructibleObjects[index].node.physicsBody?.applyForce(throwForce, asImpulse: true)
                    destructibleObjects[index].node.physicsBody?.applyTorque(
                        SCNVector4(Float.random(in: -1...1), 1, Float.random(in: -1...1), 20),
                        asImpulse: true
                    )

                    let gen = UIImpactFeedbackGenerator(style: .medium)
                    gen.impactOccurred(intensity: 0.8)

                    updateCombo()
                    totalHitCount += 1
                    return
                }
                node = current.parent
            }
        }
    }

    // MARK: - Zoom Control

    @Published var cameraZoom: CGFloat = 60 // FOV

    func zoomCamera(scale: CGFloat) {
        let newFOV = max(30, min(90, cameraZoom / scale))
        cameraZoom = newFOV
        cameraNode.camera?.fieldOfView = newFOV
    }

    func resetZoom() {
        cameraZoom = baseCameraFOV
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        cameraNode.camera?.fieldOfView = baseCameraFOV
        SCNTransaction.commit()
    }

    /// Original random targeting (fallback)
    private func hitObjectAtRandom(with tool: RageTool) {
        
        // Update combo
        updateCombo()
        totalHitCount += 1
        
        // Select target using material-aware targeting
        guard let targetIndex = selectTarget() else { return }
        var target = destructibleObjects[targetIndex]
        
        // Update published material feedback
        lastHitMaterial = target.material.rawValue
        
        // Calculate force based on tool, material weight, and combo
        let toolMultiplier = toolForceMultiplier(tool)
        let comboMultiplier = calculateComboForceMultiplier()
        let materialResistance = target.material.weight / 10.0
        let effectiveForce = toolMultiplier * comboMultiplier / max(materialResistance, 0.5)
        
        // Apply physics force with angular momentum
        let force = SCNVector3(
            Float.random(in: -3...3) * effectiveForce,
            Float.random(in: 2...5) * effectiveForce,
            Float.random(in: -3...2) * effectiveForce
        )
        target.node.physicsBody?.applyForce(force, asImpulse: true)
        
        // Apply angular velocity for realistic tumbling
        let torque = SCNVector4(
            Float.random(in: -1...1),
            Float.random(in: -1...1),
            Float.random(in: -1...1),
            Float.random(in: -6...6) * effectiveForce
        )
        target.node.physicsBody?.applyTorque(torque, asImpulse: true)
        
        // Track hits on this object
        target.hitCount += 1
        destructibleObjects[targetIndex] = target
        
        // Spawn material-specific particles
        spawnMaterialParticles(at: target.node.position, material: target.material, intensity: effectiveForce)
        
        // Spawn debris for heavy tools
        if tool == .sledgehammer || tool == .bat || internalComboCount >= 5 {
            spawnPhysicsDebris(at: target.node.position, material: target.material, count: min(Int(effectiveForce * 4), 15))
        }
        
        // Camera shake
        triggerCameraShake(intensity: cameraShakeIntensity(for: tool))
        
        // Slow-motion on power hits
        if shouldTriggerSlowMotion(tool: tool) {
            activateSlowMotion()
        }
        
        // Screen flash for big hits
        if tool == .sledgehammer || internalComboCount >= 10 {
            triggerScreenFlash(color: flashColorForMaterial(target.material), intensity: Double(effectiveForce) * 0.3)
        }
        
        // Update destruction level
        let destructionIncrease = Double(effectiveForce) * 0.02 * Double(target.material.fragility)
        destructionLevel = min(1.0, destructionLevel + destructionIncrease)
        updateRoomDeterioration()
        
        // Handle special objects
        handleSpecialObjectHit(target: target, tool: tool)
        
        // Audio with material awareness
        playMaterialSound(material: target.material, tool: tool, intensity: effectiveForce)
        
        // Haptics
        triggerLayeredHaptic(tool: tool, material: target.material)
        
        // Check if object should be destroyed
        if target.hitCount >= target.maxHits && !target.isDestroyed {
            destroyObject(at: targetIndex)
        }
    }
    
    // MARK: - Swipe Action
    
    func swipeAction(translation: CGSize, tool: RageTool) {
        if tool == .spray {
            let wallZ: Float = -4.3
            let x = Float(translation.width) * 0.004
            let y = 1.8 + Float(-translation.height) * 0.003
            let clampedX = max(-3.0, min(3.0, x))
            let clampedY = max(0.5, min(3.8, y))
            spawnSprayMark(at: SCNVector3(clampedX, clampedY, wallZ))
        }
    }
    
    // MARK: - Set Spray Color
    
    func setSprayColor(_ color: UIColor) {
        currentSprayColor = color
    }
    
    // MARK: - End Swipe
    
    func endSwipe(tool: RageTool) {
        if tool == .throwPlates {
            updateCombo()
            totalHitCount += 1
            
            // Find a throwable object
            if let throwableIndex = destructibleObjects.firstIndex(where: {
                !$0.isDestroyed && (
                    $0.node.name?.contains("plate") == true ||
                    $0.node.name?.contains("bottle") == true ||
                    $0.node.name?.contains("chair") == true
                )
            }) {
                let target = destructibleObjects[throwableIndex]
                lastHitMaterial = target.material.rawValue
                
                let throwForce = SCNVector3(
                    Float.random(in: -4...4),
                    Float.random(in: 2...5),
                    Float.random(in: (-12)...(-6))
                )
                target.node.physicsBody?.applyForce(throwForce, asImpulse: true)
                target.node.physicsBody?.applyTorque(SCNVector4(1, 0.5, 0, 15), asImpulse: true)
                
                // Spawn particles on throw
                spawnMaterialParticles(at: target.node.position, material: target.material, intensity: 2.0)
                triggerCameraShake(intensity: 0.3)
                playMaterialSound(material: target.material, tool: tool, intensity: 2.0)
                triggerLayeredHaptic(tool: tool, material: target.material)
                
                destructionLevel = min(1.0, destructionLevel + 0.03)
                updateRoomDeterioration()
            }
        } else if tool != .spray {
            hitObject(with: tool)
        }
    }
    
    // MARK: - ============================================================
    // MARK: - TARGETING SYSTEM
    // MARK: - ============================================================
    
    /// Select the nearest non-destroyed object in the camera's forward cone.
    /// Falls back to a random valid target if none are in the forward cone.
    private func selectTarget() -> Int? {
        let activeObjects = destructibleObjects.enumerated().filter { !$0.element.isDestroyed }
        guard !activeObjects.isEmpty else { return nil }
        
        // Camera forward direction
        let cameraForward = cameraNode.simdWorldFront
        let cameraPos = cameraNode.simdWorldPosition
        
        // Score each object by distance and alignment with camera forward
        var bestIndex: Int? = nil
        var bestScore: Float = -Float.greatestFiniteMagnitude
        
        for (index, obj) in activeObjects {
            let objPos = obj.node.simdWorldPosition
            let toObj = objPos - cameraPos
            let distance = simd_length(toObj)
            let direction = simd_normalize(toObj)
            
            // Dot product: 1 = directly ahead, 0 = perpendicular, -1 = behind
            let alignment = simd_dot(direction, cameraForward)
            
            // Only consider objects in front of camera (alignment > 0.2 = roughly 78 degree cone)
            guard alignment > 0.2 else { continue }
            
            // Score favors close objects that are well-aligned with camera
            let score = alignment * 2.0 - distance * 0.3
            if score > bestScore {
                bestScore = score
                bestIndex = index
            }
        }
        
        // Fallback to random if no good target in cone
        if bestIndex == nil {
            bestIndex = activeObjects.randomElement()?.offset
        }
        
        return bestIndex
    }
    
    // MARK: - ============================================================
    // MARK: - COMBO SYSTEM
    // MARK: - ============================================================
    
    private func updateCombo() {
        let now = Date()
        if now.timeIntervalSince(lastHitTime) < 1.2 {
            internalComboCount += 1
        } else {
            internalComboCount = 1
        }
        lastHitTime = now
        comboCount = internalComboCount
        
        // Combo milestone haptics
        if internalComboCount == 5 || internalComboCount == 10 || internalComboCount == 15 {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(internalComboCount >= 10 ? .success : .warning)
        }
        
        // Reset combo after timeout
        comboTimer?.invalidate()
        comboTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.internalComboCount = 0
                self?.comboCount = 0
            }
        }
    }
    
    private func calculateComboForceMultiplier() -> Float {
        switch internalComboCount {
        case 0...2: return 1.0
        case 3...5: return 1.3
        case 6...9: return 1.6
        case 10...14: return 2.0
        default: return 2.5  // 15+
        }
    }
    
    private func toolForceMultiplier(_ tool: RageTool) -> Float {
        switch tool {
        case .sledgehammer: return 4.5
        case .bat: return 3.2
        case .throwPlates: return 2.5
        case .fists: return 2.0
        case .spray: return 0
        }
    }
    
    // MARK: - ============================================================
    // MARK: - PARTICLE SYSTEMS (All Programmatic SCNParticleSystem)
    // MARK: - ============================================================
    
    private func spawnMaterialParticles(at position: SCNVector3, material: ObjectMaterial, intensity: Float) {
        switch material {
        case .metal:
            emitSparks(at: position, intensity: intensity)
        case .glass:
            emitGlassShards(at: position, intensity: intensity)
        case .wood:
            emitWoodSplinters(at: position, intensity: intensity)
        case .ceramic:
            emitCeramicFragments(at: position, intensity: intensity)
        case .concrete:
            emitWallCrackDust(at: position, intensity: intensity)
        case .rubber:
            emitDustCloud(at: position, intensity: intensity * 0.5)
        case .flesh:
            emitDustCloud(at: position, intensity: intensity * 0.7)
        case .plastic:
            emitPlasticChips(at: position, intensity: intensity)
        }
        
        // Heavy tools always produce dust clouds
        if intensity > 3.0 {
            emitDustCloud(at: position, intensity: intensity * 0.4)
        }
    }
    
    /// SPARKS - Bright orange/yellow points spraying on metal hits
    private func emitSparks(at position: SCNVector3, intensity: Float) {
        let sparks = SCNParticleSystem()
        sparks.particleSize = 0.015
        sparks.particleSizeVariation = 0.008
        sparks.birthRate = CGFloat(min(80, 30 * intensity))
        sparks.emissionDuration = 0.15
        sparks.particleLifeSpan = 0.6
        sparks.particleLifeSpanVariation = 0.3
        sparks.spreadingAngle = 120
        sparks.particleVelocity = CGFloat(3.0 * intensity)
        sparks.particleVelocityVariation = CGFloat(1.5 * intensity)
        sparks.particleColor = UIColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0)
        sparks.particleColorVariation = SCNVector4(0, 0.3, 0.2, 0)
        sparks.blendMode = .additive
        sparks.isAffectedByGravity = true
        sparks.acceleration = SCNVector3(0, -6, 0)
        sparks.particleImage = cachedCircleImage8White
        sparks.emitterShape = SCNSphere(radius: 0.05)
        
        // Color animation: bright yellow to orange to dark red
        let colorAnim = CAKeyframeAnimation(keyPath: "color")
        colorAnim.values = [
            UIColor(red: 1.0, green: 1.0, blue: 0.6, alpha: 1.0),
            UIColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 0.9),
            UIColor(red: 0.8, green: 0.2, blue: 0.0, alpha: 0.0),
        ]
        colorAnim.keyTimes = [0, 0.4, 1.0]
        colorAnim.duration = 0.6
        let colorController = SCNParticlePropertyController(animation: colorAnim)
        sparks.propertyControllers = [.color: colorController]
        
        let emitterNode = SCNNode()
        emitterNode.position = position
        emitterNode.addParticleSystem(sparks)
        scene.rootNode.addChildNode(emitterNode)
        
        // Auto-remove emitter after particles die
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            emitterNode.removeFromParentNode()
        }
    }
    
    /// GLASS SHARDS - Translucent angular particles scattering
    private func emitGlassShards(at position: SCNVector3, intensity: Float) {
        let shards = SCNParticleSystem()
        shards.particleSize = 0.025
        shards.particleSizeVariation = 0.015
        shards.birthRate = CGFloat(min(60, 25 * intensity))
        shards.emissionDuration = 0.1
        shards.particleLifeSpan = 1.5
        shards.particleLifeSpanVariation = 0.5
        shards.spreadingAngle = 150
        shards.particleVelocity = CGFloat(4.0 * intensity)
        shards.particleVelocityVariation = CGFloat(2.0 * intensity)
        shards.particleColor = UIColor(red: 0.7, green: 0.85, blue: 0.95, alpha: 0.7)
        shards.particleColorVariation = SCNVector4(0.1, 0.1, 0.05, 0.2)
        shards.blendMode = .alpha
        shards.isAffectedByGravity = true
        shards.acceleration = SCNVector3(0, -8, 0)
        shards.particleAngularVelocity = CGFloat(Float.pi * 4)
        shards.particleAngularVelocityVariation = CGFloat(Float.pi * 2)
        shards.particleImage = cachedDiamondImage12
        shards.emitterShape = SCNSphere(radius: 0.08)
        
        // Fade out
        let opacityAnim = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnim.values = [1.0, 0.8, 0.0]
        opacityAnim.keyTimes = [0, 0.7, 1.0]
        opacityAnim.duration = 1.5
        let opacityController = SCNParticlePropertyController(animation: opacityAnim)
        shards.propertyControllers = [.opacity: opacityController]
        
        let emitterNode = SCNNode()
        emitterNode.position = position
        emitterNode.addParticleSystem(shards)
        scene.rootNode.addChildNode(emitterNode)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            emitterNode.removeFromParentNode()
        }
    }
    
    /// DUST CLOUDS - Soft grey billowing particles for heavy impacts
    private func emitDustCloud(at position: SCNVector3, intensity: Float) {
        let dust = SCNParticleSystem()
        dust.particleSize = 0.12
        dust.particleSizeVariation = 0.06
        dust.birthRate = CGFloat(min(40, 15 * intensity))
        dust.emissionDuration = 0.3
        dust.particleLifeSpan = 2.5
        dust.particleLifeSpanVariation = 1.0
        dust.spreadingAngle = 160
        dust.particleVelocity = CGFloat(1.0 * intensity)
        dust.particleVelocityVariation = CGFloat(0.5 * intensity)
        dust.particleColor = UIColor(red: 0.5, green: 0.48, blue: 0.45, alpha: 0.5)
        dust.particleColorVariation = SCNVector4(0.05, 0.05, 0.05, 0.1)
        dust.blendMode = .alpha
        dust.isAffectedByGravity = false
        dust.particleImage = cachedSoftCircleImage32
        dust.emitterShape = SCNSphere(radius: 0.15)
        
        // Grow and fade
        let sizeAnim = CAKeyframeAnimation(keyPath: "size")
        sizeAnim.values = [0.06, 0.15, 0.2]
        sizeAnim.keyTimes = [0, 0.5, 1.0]
        sizeAnim.duration = 2.5
        let sizeController = SCNParticlePropertyController(animation: sizeAnim)
        
        let opacityAnim = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnim.values = [0.6, 0.3, 0.0]
        opacityAnim.keyTimes = [0, 0.6, 1.0]
        opacityAnim.duration = 2.5
        let opacityController = SCNParticlePropertyController(animation: opacityAnim)
        
        dust.propertyControllers = [.size: sizeController, .opacity: opacityController]
        
        let emitterNode = SCNNode()
        emitterNode.position = position
        emitterNode.addParticleSystem(dust)
        scene.rootNode.addChildNode(emitterNode)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            emitterNode.removeFromParentNode()
        }
    }
    
    /// WOOD SPLINTERS - Brown elongated particles on wood hits
    private func emitWoodSplinters(at position: SCNVector3, intensity: Float) {
        let splinters = SCNParticleSystem()
        splinters.particleSize = 0.03
        splinters.particleSizeVariation = 0.015
        splinters.birthRate = CGFloat(min(50, 20 * intensity))
        splinters.emissionDuration = 0.12
        splinters.particleLifeSpan = 1.2
        splinters.particleLifeSpanVariation = 0.4
        splinters.spreadingAngle = 130
        splinters.particleVelocity = CGFloat(3.0 * intensity)
        splinters.particleVelocityVariation = CGFloat(1.5 * intensity)
        splinters.particleColor = UIColor(red: 0.55, green: 0.35, blue: 0.15, alpha: 1.0)
        splinters.particleColorVariation = SCNVector4(0.1, 0.1, 0.05, 0)
        splinters.blendMode = .alpha
        splinters.isAffectedByGravity = true
        splinters.acceleration = SCNVector3(0, -7, 0)
        splinters.particleAngularVelocity = CGFloat(Float.pi * 6)
        splinters.particleAngularVelocityVariation = CGFloat(Float.pi * 3)
        splinters.particleImage = cachedSplinterImage16
        splinters.emitterShape = SCNSphere(radius: 0.06)
        
        let emitterNode = SCNNode()
        emitterNode.position = position
        emitterNode.addParticleSystem(splinters)
        scene.rootNode.addChildNode(emitterNode)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            emitterNode.removeFromParentNode()
        }
    }
    
    /// CERAMIC FRAGMENTS - White small particles on plate/ceramic hits
    private func emitCeramicFragments(at position: SCNVector3, intensity: Float) {
        let fragments = SCNParticleSystem()
        fragments.particleSize = 0.02
        fragments.particleSizeVariation = 0.01
        fragments.birthRate = CGFloat(min(70, 30 * intensity))
        fragments.emissionDuration = 0.08
        fragments.particleLifeSpan = 1.0
        fragments.particleLifeSpanVariation = 0.3
        fragments.spreadingAngle = 160
        fragments.particleVelocity = CGFloat(5.0 * intensity)
        fragments.particleVelocityVariation = CGFloat(2.5 * intensity)
        fragments.particleColor = UIColor(red: 0.95, green: 0.93, blue: 0.9, alpha: 1.0)
        fragments.particleColorVariation = SCNVector4(0.05, 0.03, 0.02, 0)
        fragments.blendMode = .alpha
        fragments.isAffectedByGravity = true
        fragments.acceleration = SCNVector3(0, -9, 0)
        fragments.particleAngularVelocity = CGFloat(Float.pi * 8)
        fragments.particleAngularVelocityVariation = CGFloat(Float.pi * 4)
        fragments.particleImage = cachedDiamondImage8
        fragments.emitterShape = SCNSphere(radius: 0.05)
        
        let emitterNode = SCNNode()
        emitterNode.position = position
        emitterNode.addParticleSystem(fragments)
        scene.rootNode.addChildNode(emitterNode)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            emitterNode.removeFromParentNode()
        }
    }
    
    /// WALL CRACK DUST - Fine particles for concrete/wall hits
    private func emitWallCrackDust(at position: SCNVector3, intensity: Float) {
        let crackDust = SCNParticleSystem()
        crackDust.particleSize = 0.04
        crackDust.particleSizeVariation = 0.02
        crackDust.birthRate = CGFloat(min(35, 15 * intensity))
        crackDust.emissionDuration = 0.2
        crackDust.particleLifeSpan = 2.0
        crackDust.particleLifeSpanVariation = 0.8
        crackDust.spreadingAngle = 90
        crackDust.particleVelocity = CGFloat(0.8 * intensity)
        crackDust.particleVelocityVariation = CGFloat(0.4 * intensity)
        crackDust.particleColor = UIColor(red: 0.55, green: 0.52, blue: 0.48, alpha: 0.6)
        crackDust.particleColorVariation = SCNVector4(0.05, 0.05, 0.05, 0.1)
        crackDust.blendMode = .alpha
        crackDust.isAffectedByGravity = true
        crackDust.acceleration = SCNVector3(0, -2, 0)
        crackDust.particleImage = cachedSoftCircleImage16
        crackDust.emitterShape = SCNSphere(radius: 0.1)
        
        let emitterNode = SCNNode()
        emitterNode.position = position
        emitterNode.addParticleSystem(crackDust)
        scene.rootNode.addChildNode(emitterNode)
        
        // Also spawn crack overlays on nearby walls
        spawnWallCrack(near: position)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            emitterNode.removeFromParentNode()
        }
    }
    
    /// PLASTIC CHIPS - Small dark particles
    private func emitPlasticChips(at position: SCNVector3, intensity: Float) {
        let chips = SCNParticleSystem()
        chips.particleSize = 0.015
        chips.particleSizeVariation = 0.008
        chips.birthRate = CGFloat(min(40, 18 * intensity))
        chips.emissionDuration = 0.1
        chips.particleLifeSpan = 0.8
        chips.particleLifeSpanVariation = 0.3
        chips.spreadingAngle = 140
        chips.particleVelocity = CGFloat(2.5 * intensity)
        chips.particleVelocityVariation = CGFloat(1.2 * intensity)
        chips.particleColor = UIColor(red: 0.25, green: 0.25, blue: 0.3, alpha: 1.0)
        chips.particleColorVariation = SCNVector4(0.05, 0.05, 0.05, 0)
        chips.blendMode = .alpha
        chips.isAffectedByGravity = true
        chips.acceleration = SCNVector3(0, -8, 0)
        chips.particleImage = cachedCircleImage6White
        
        let emitterNode = SCNNode()
        emitterNode.position = position
        emitterNode.addParticleSystem(chips)
        scene.rootNode.addChildNode(emitterNode)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            emitterNode.removeFromParentNode()
        }
    }
    
    /// Fire extinguisher spray effect - white particles streaming
    private func emitFireExtinguisherSpray(at position: SCNVector3) {
        let spray = SCNParticleSystem()
        spray.particleSize = 0.08
        spray.particleSizeVariation = 0.04
        spray.birthRate = 100
        spray.emissionDuration = 3.0
        spray.particleLifeSpan = 1.5
        spray.particleLifeSpanVariation = 0.5
        spray.spreadingAngle = 25
        spray.particleVelocity = 5.0
        spray.particleVelocityVariation = 1.5
        spray.particleColor = UIColor(white: 0.95, alpha: 0.8)
        spray.particleColorVariation = SCNVector4(0, 0, 0, 0.2)
        spray.blendMode = .alpha
        spray.isAffectedByGravity = true
        spray.acceleration = SCNVector3(0, -2, 0)
        spray.particleImage = cachedSoftCircleImage24
        spray.emitterShape = SCNSphere(radius: 0.03)
        
        let sizeAnim = CAKeyframeAnimation(keyPath: "size")
        sizeAnim.values = [0.04, 0.12, 0.18]
        sizeAnim.keyTimes = [0, 0.5, 1.0]
        sizeAnim.duration = 1.5
        let sizeController = SCNParticlePropertyController(animation: sizeAnim)
        
        let opacityAnim = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnim.values = [0.9, 0.5, 0.0]
        opacityAnim.keyTimes = [0, 0.6, 1.0]
        opacityAnim.duration = 1.5
        let opacityController = SCNParticlePropertyController(animation: opacityAnim)
        
        spray.propertyControllers = [.size: sizeController, .opacity: opacityController]
        
        let emitterNode = SCNNode()
        emitterNode.position = position
        emitterNode.eulerAngles = SCNVector3(-Float.pi / 4, 0, 0)
        emitterNode.addParticleSystem(spray)
        scene.rootNode.addChildNode(emitterNode)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            emitterNode.removeFromParentNode()
        }
    }
    
    // MARK: - ============================================================
    // MARK: - CAMERA SHAKE SYSTEM
    // MARK: - ============================================================
    
    private func cameraShakeIntensity(for tool: RageTool) -> Float {
        var base: Float
        switch tool {
        case .sledgehammer: base = 1.0
        case .bat: base = 0.6
        case .fists: base = 0.3
        case .throwPlates: base = 0.4
        case .spray: base = 0.0
        }
        
        // Combo amplification
        if internalComboCount >= 15 {
            base *= 1.5
        } else if internalComboCount >= 10 {
            base *= 1.2
        }
        
        return base
    }
    
    private func triggerCameraShake(intensity: Float) {
        guard intensity > 0 else { return }
        
        // Remove any current breathing to avoid conflict
        cameraNode.removeAction(forKey: "shake")
        
        let duration: TimeInterval = TimeInterval(0.3 + intensity * 0.15)
        let shakeCount = Int(4 + intensity * 3)
        
        var actions: [SCNAction] = []
        for i in 0..<shakeCount {
            let decay = 1.0 - (Float(i) / Float(shakeCount))
            let offsetX = Float.random(in: -0.03...0.03) * intensity * decay
            let offsetY = Float.random(in: -0.02...0.02) * intensity * decay
            
            let moveAction = SCNAction.moveBy(
                x: CGFloat(offsetX),
                y: CGFloat(offsetY),
                z: 0,
                duration: duration / Double(shakeCount)
            )
            moveAction.timingMode = .easeOut
            actions.append(moveAction)
        }
        
        // Return to base position
        let returnAction = SCNAction.move(to: baseCameraPosition, duration: 0.1)
        returnAction.timingMode = .easeInEaseOut
        actions.append(returnAction)
        
        let sequence = SCNAction.sequence(actions)
        cameraNode.runAction(sequence, forKey: "shake")
        
        // Update published offset for SwiftUI layer
        let shakeX = CGFloat(Float.random(in: -2...2) * intensity)
        let shakeY = CGFloat(Float.random(in: -1.5...1.5) * intensity)
        cameraShakeOffset = CGSize(width: shakeX, height: shakeY)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.cameraShakeOffset = .zero
        }
    }
    
    // MARK: - ============================================================
    // MARK: - SLOW-MOTION SYSTEM
    // MARK: - ============================================================
    
    private func shouldTriggerSlowMotion(tool: RageTool) -> Bool {
        if isSlowMotion { return false }
        
        switch tool {
        case .sledgehammer where internalComboCount >= 3: return true
        case .bat where internalComboCount >= 5: return true
        case _ where internalComboCount >= 10: return true
        default: return false
        }
    }
    
    private func activateSlowMotion() {
        guard !isSlowMotion else { return }
        isSlowMotion = true
        
        // Reduce physics speed
        scene.physicsWorld.speed = 0.3
        
        // Zoom FOV slightly for dramatic effect
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        cameraNode.camera?.fieldOfView = baseCameraFOV - 5
        SCNTransaction.commit()
        
        // Ramp back to normal after 0.8 seconds
        slowMotionTimer?.invalidate()
        slowMotionTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.rampUpFromSlowMotion()
            }
        }
    }
    
    private func rampUpFromSlowMotion() {
        // Gradual ramp back to 1.0 over 0.3s
        let rampState = RampState()
        let totalSteps = 6
        slowMotionRampTimer?.invalidate()
        slowMotionRampTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                rampState.step += 1
                let progress = Float(rampState.step) / Float(totalSteps)
                self.scene.physicsWorld.speed = CGFloat(0.3 + 0.7 * progress)
                
                if rampState.step >= totalSteps {
                    self.slowMotionRampTimer?.invalidate()
                    self.slowMotionRampTimer = nil
                    self.scene.physicsWorld.speed = 1.0
                    self.isSlowMotion = false
                    
                    // Restore FOV
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.2
                    self.cameraNode.camera?.fieldOfView = self.baseCameraFOV
                    SCNTransaction.commit()
                }
            }
        }
    }
    
    // MARK: - ============================================================
    // MARK: - SCREEN FLASH SYSTEM
    // MARK: - ============================================================
    
    private func flashColorForMaterial(_ material: ObjectMaterial) -> UIColor {
        switch material {
        case .metal: return UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1)
        case .glass: return UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1)
        case .ceramic: return UIColor.white
        case .wood: return UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1)
        default: return UIColor(red: 1.0, green: 0.9, blue: 0.8, alpha: 1)
        }
    }
    
    private func triggerScreenFlash(color: UIColor, intensity: Double) {
        screenFlashColor = color
        screenFlashOpacity = min(0.6, intensity)
        
        // Fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.screenFlashOpacity = (self?.screenFlashOpacity ?? 0) * 0.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.screenFlashOpacity = 0
            self?.screenFlashColor = nil
        }
    }
    
    // MARK: - ============================================================
    // MARK: - PROGRESSIVE ROOM DETERIORATION
    // MARK: - ============================================================
    
    private func updateRoomDeterioration() {
        let level = destructionLevel
        
        // Phase 1: 0-25% - Occasional flickers, small cracks
        if level > 0.05 {
            updatePhase1Deterioration(level: level)
        }
        
        // Phase 2: 25-50% - Pendulum light, more cracks, scattered debris
        if level > 0.25 {
            updatePhase2Deterioration(level: level)
        }
        
        // Phase 3: 50-75% - Red lights intensify, sparking pipe, ceiling dust
        if level > 0.50 {
            updatePhase3Deterioration(level: level)
        }
        
        // Phase 4: 75-100% - Emergency red, strobing, heavy smoke, DESTROYED
        if level > 0.75 {
            updatePhase4Deterioration(level: level)
        }
    }
    
    private func updatePhase1Deterioration(level: Double) {
        // Increase flicker frequency
        let flickerIntensity = CGFloat(200 + level * 300)
        mainOverheadLight?.light?.intensity = flickerIntensity > 0 ? 1200 - flickerIntensity * 0.3 : 1200
    }
    
    private func updatePhase2Deterioration(level: Double) {
        // Dim main lights
        let dimFactor = CGFloat(1.0 - (level - 0.25) * 0.8)
        mainOverheadLight?.light?.intensity = 1200 * dimFactor
        secondOverheadLight?.light?.intensity = 800 * dimFactor
        
        // Increase red lights
        let redIntensity = CGFloat(600 + (level - 0.25) * 800)
        redAccentLight1?.light?.intensity = redIntensity
        redAccentLight2?.light?.intensity = redIntensity * 0.85
        
        // Auto-spawn floor debris
        if Int.random(in: 0...10) == 0 {
            spawnAutoDebris()
        }
    }
    
    private func updatePhase3Deterioration(level: Double) {
        // Activate sparking pipe
        if sparkingPipeEmitter == nil {
            activateSparkingPipe()
        }
        
        // Ceiling dust falls
        if Int.random(in: 0...5) == 0 {
            let dustPos = SCNVector3(
                Float.random(in: -3...3),
                4.2,
                Float.random(in: -3...3)
            )
            emitDustCloud(at: dustPos, intensity: 0.5)
        }
        
        // Further dim ambient
        ambientLight?.light?.intensity = CGFloat(400 * (1.0 - (level - 0.5) * 1.5))
    }
    
    private func updatePhase4Deterioration(level: Double) {
        // Emergency red light activates
        let emergencyIntensity = CGFloat((level - 0.75) * 4.0 * 1000)
        emergencyLight?.light?.intensity = emergencyIntensity
        
        // Strobe effect
        if hangingLightFixture?.action(forKey: "strobe") == nil {
            let strobe = SCNAction.sequence([
                SCNAction.customAction(duration: 0.05) { [weak self] _, _ in
                    DispatchQueue.main.async {
                        self?.mainOverheadLight?.light?.intensity = 1200
                    }
                },
                SCNAction.wait(duration: 0.1),
                SCNAction.customAction(duration: 0.05) { [weak self] _, _ in
                    DispatchQueue.main.async {
                        self?.mainOverheadLight?.light?.intensity = 100
                    }
                },
                SCNAction.wait(duration: Double.random(in: 0.3...0.8)),
            ])
            hangingLightFixture?.runAction(SCNAction.repeatForever(strobe), forKey: "strobe")
        }
        
        // Drop hanging light at very high destruction
        if level > 0.9 && !hangingLightFallen {
            dropHangingLight()
        }
        
        // Heavy smoke/dust atmosphere
        if Int.random(in: 0...3) == 0 {
            let smokePos = SCNVector3(
                Float.random(in: -3...3),
                Float.random(in: 0.5...2.5),
                Float.random(in: -3...3)
            )
            emitDustCloud(at: smokePos, intensity: 0.3)
        }
    }
    
    private func activateSparkingPipe() {
        guard let pipeNode = sparkingPipeNode else { return }
        
        let sparkSystem = SCNParticleSystem()
        sparkSystem.particleSize = 0.01
        sparkSystem.particleSizeVariation = 0.005
        sparkSystem.birthRate = 20
        sparkSystem.emissionDuration = CGFloat.greatestFiniteMagnitude
        sparkSystem.particleLifeSpan = 0.4
        sparkSystem.particleLifeSpanVariation = 0.2
        sparkSystem.spreadingAngle = 60
        sparkSystem.particleVelocity = 2.0
        sparkSystem.particleVelocityVariation = 1.0
        sparkSystem.particleColor = UIColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0)
        sparkSystem.blendMode = .additive
        sparkSystem.isAffectedByGravity = true
        sparkSystem.acceleration = SCNVector3(0, -5, 0)
        sparkSystem.particleImage = cachedCircleImage6White
        
        let emitter = SCNNode()
        emitter.position = SCNVector3(pipeNode.position.x, pipeNode.position.y + 1.5, pipeNode.position.z)
        emitter.addParticleSystem(sparkSystem)
        scene.rootNode.addChildNode(emitter)
        sparkingPipeEmitter = emitter
    }
    
    private func dropHangingLight() {
        hangingLightFallen = true
        guard let fixture = hangingLightFixture else { return }
        
        fixture.removeAllActions()
        fixture.physicsBody = SCNPhysicsBody.dynamic()
        fixture.physicsBody?.mass = 3
        fixture.physicsBody?.categoryBitMask = PhysicsCategory.debris
        
        // Chain breaks visual
        hangingLightChain?.removeFromParentNode()
        
        // Sparks from where it detached
        emitSparks(at: SCNVector3(fixture.position.x, 4.0, fixture.position.z), intensity: 3.0)
        
        // Kill the fixture light
        fixture.light?.intensity = 0
        
        triggerCameraShake(intensity: 0.8)
        triggerScreenFlash(color: .white, intensity: 0.5)
    }
    
    private func spawnAutoDebris() {
        guard debrisNodes.count < maxDebrisNodes else { return }
        
        let size = CGFloat.random(in: 0.03...0.08)
        let debris = SCNBox(width: size, height: size * 0.5, length: size * 0.7, chamferRadius: 0)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(
            red: CGFloat.random(in: 0.3...0.5),
            green: CGFloat.random(in: 0.28...0.45),
            blue: CGFloat.random(in: 0.25...0.4),
            alpha: 1
        )
        mat.roughness.contents = 0.9
        debris.materials = [mat]
        
        let node = SCNNode(geometry: debris)
        node.position = SCNVector3(
            Float.random(in: -3...3),
            Float.random(in: 3.0...4.0),
            Float.random(in: -3...2)
        )
        node.physicsBody = SCNPhysicsBody.dynamic()
        node.physicsBody?.mass = 0.1
        node.physicsBody?.categoryBitMask = PhysicsCategory.debris
        scene.rootNode.addChildNode(node)
        debrisNodes.append(node)
    }
    
    // MARK: - ============================================================
    // MARK: - WALL CRACKS
    // MARK: - ============================================================
    
    private func spawnWallCrack(near position: SCNVector3) {
        guard crackNodes.count < maxCrackNodes else { return }
        
        // Determine which wall is closest
        let wallZ: Float = -4.35
        let leftX: Float = -3.85
        let rightX: Float = 3.85
        
        var crackPos = position
        var crackRotation = SCNVector3(0, 0, 0)
        
        if abs(position.z - wallZ) < 1.5 {
            crackPos.z = wallZ + 0.01
        } else if abs(position.x - leftX) < 1.5 {
            crackPos.x = leftX + 0.01
            crackRotation.y = Float.pi / 2
        } else if abs(position.x - rightX) < 1.5 {
            crackPos.x = rightX - 0.01
            crackRotation.y = -Float.pi / 2
        } else {
            crackPos.z = wallZ + 0.01
        }
        
        // Crack overlay (thin dark line pattern)
        let crackWidth = CGFloat.random(in: 0.2...0.6)
        let crackHeight = CGFloat.random(in: 0.15...0.4)
        let crack = SCNPlane(width: crackWidth, height: crackHeight)
        let crackMat = SCNMaterial()
        crackMat.diffuse.contents = UIColor(red: 0.1, green: 0.08, blue: 0.06, alpha: CGFloat.random(in: 0.4...0.8))
        crackMat.isDoubleSided = true
        crackMat.writesToDepthBuffer = false
        crack.materials = [crackMat]
        
        let crackNode = SCNNode(geometry: crack)
        crackNode.position = crackPos
        crackNode.eulerAngles = crackRotation
        crackNode.eulerAngles.z = Float.random(in: -0.5...0.5)
        scene.rootNode.addChildNode(crackNode)
        crackNodes.append(crackNode)
    }
    
    // MARK: - ============================================================
    // MARK: - PHYSICS DEBRIS SYSTEM
    // MARK: - ============================================================
    
    private func spawnPhysicsDebris(at position: SCNVector3, material: ObjectMaterial, count: Int) {
        // Clean up old debris if over limit
        cleanupDebrisIfNeeded()
        
        let actualCount = min(count, maxDebrisNodes - debrisNodes.count)
        guard actualCount > 0 else { return }
        
        for _ in 0..<actualCount {
            let size = CGFloat.random(in: 0.02...0.08)
            let debris: SCNGeometry
            
            switch material {
            case .glass, .ceramic:
                debris = SCNBox(width: size, height: size * 0.3, length: size * 0.8, chamferRadius: 0)
            case .wood:
                debris = SCNBox(width: size * 0.3, height: size, length: size * 0.4, chamferRadius: 0)
            case .metal:
                debris = SCNBox(width: size, height: size * 0.2, length: size * 0.6, chamferRadius: size * 0.1)
            default:
                debris = Bool.random() ?
                    SCNBox(width: size, height: size * 0.6, length: size * 0.8, chamferRadius: 0) as SCNGeometry :
                    SCNSphere(radius: size * 0.4) as SCNGeometry
            }
            
            let debrisMat = SCNMaterial()
            debrisMat.diffuse.contents = material.particleColor
            debrisMat.roughness.contents = 0.8
            debris.materials = [debrisMat]
            
            let node = SCNNode(geometry: debris)
            node.position = SCNVector3(
                position.x + Float.random(in: -0.3...0.3),
                position.y + Float.random(in: 0...0.4),
                position.z + Float.random(in: -0.3...0.3)
            )
            node.physicsBody = SCNPhysicsBody.dynamic()
            node.physicsBody?.mass = CGFloat(0.02 + Float.random(in: 0...0.05))
            node.physicsBody?.categoryBitMask = PhysicsCategory.debris
            
            let force = SCNVector3(
                Float.random(in: -3...3),
                Float.random(in: 2...5),
                Float.random(in: -3...3)
            )
            node.physicsBody?.applyForce(force, asImpulse: true)
            node.physicsBody?.applyTorque(SCNVector4(
                Float.random(in: -1...1),
                Float.random(in: -1...1),
                Float.random(in: -1...1),
                Float.random(in: -10...10)
            ), asImpulse: true)
            
            scene.rootNode.addChildNode(node)
            debrisNodes.append(node)
            
            // Auto-remove after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 6.0...10.0)) { [weak node] in
                node?.removeFromParentNode()
            }
        }
    }
    
    private func cleanupDebrisIfNeeded() {
        if debrisNodes.count > maxDebrisNodes - 10 {
            let removeCount = min(20, debrisNodes.count)
            for i in 0..<removeCount {
                debrisNodes[i].removeFromParentNode()
            }
            debrisNodes.removeFirst(removeCount)
        }
    }
    
    // MARK: - ============================================================
    // MARK: - OBJECT DESTRUCTION
    // MARK: - ============================================================
    
    private func destroyObject(at index: Int) {
        guard index < destructibleObjects.count else { return }
        var obj = destructibleObjects[index]
        guard !obj.isDestroyed else { return }
        
        obj.isDestroyed = true
        destructibleObjects[index] = obj
        
        let position = obj.node.position
        let material = obj.material
        
        // Big particle burst on destruction
        spawnMaterialParticles(at: position, material: material, intensity: 5.0)
        spawnPhysicsDebris(at: position, material: material, count: 12)
        
        // Screen flash
        triggerScreenFlash(color: flashColorForMaterial(material), intensity: 0.4)
        triggerCameraShake(intensity: 0.7)
        
        // Extra dramatic sound
        playDestructionSound(material: material)
        
        // Fade out and remove the original node
        let fadeOut = SCNAction.sequence([
            SCNAction.scale(to: 0.3, duration: 0.2),
            SCNAction.fadeOut(duration: 0.15),
            SCNAction.removeFromParentNode()
        ])
        obj.node.runAction(fadeOut)
    }
    
    // MARK: - ============================================================
    // MARK: - SPECIAL OBJECT INTERACTIONS
    // MARK: - ============================================================
    
    private func handleSpecialObjectHit(target: DestructibleObject, tool: RageTool) {
        // Car door dent effect
        if target.node.name == "car_door", let door = carDoorNode {
            carDoorDentCount += 1
            // Darken material progressively to simulate dents
            if let geometry = door.geometry, let material = geometry.firstMaterial {
                let dentDarkness = CGFloat(min(Float(carDoorDentCount) * 0.04, 0.5))
                material.diffuse.contents = UIColor(
                    red: 0.3 - dentDarkness,
                    green: 0.35 - dentDarkness,
                    blue: 0.4 - dentDarkness,
                    alpha: 1
                )
            }
        }
        
        // Mirror crack effect
        if target.node.name == "mirror", let mirror = mirrorNode {
            mirrorCrackLevel += 1
            if mirrorCrackLevel <= 3 {
                // Add crack overlay on mirror surface
                let crack = SCNPlane(width: 0.6, height: 0.8)
                let crackMat = SCNMaterial()
                crackMat.diffuse.contents = UIColor(white: 0.3, alpha: CGFloat(mirrorCrackLevel) * 0.25)
                crackMat.isDoubleSided = true
                crackMat.writesToDepthBuffer = false
                crack.materials = [crackMat]
                let crackNode = SCNNode(geometry: crack)
                crackNode.position = SCNVector3(0, 0, 0.015)
                crackNode.eulerAngles.z = Float.random(in: -0.3...0.3)
                mirror.addChildNode(crackNode)
            }
            if mirrorCrackLevel >= 3 {
                // Shatter effect
                emitGlassShards(at: mirror.position, intensity: 5.0)
            }
        }
        
        // Fire extinguisher spray
        if target.node.name == "fire_extinguisher" && !fireExtinguisherTriggered {
            if target.hitCount >= 3 || tool == .sledgehammer {
                fireExtinguisherTriggered = true
                emitFireExtinguisherSpray(at: target.node.position)
                // Apply reactive force to the extinguisher (jet propulsion)
                target.node.physicsBody?.applyForce(SCNVector3(0, 8, 5), asImpulse: true)
                target.node.physicsBody?.applyTorque(SCNVector4(1, 0, 0, 20), asImpulse: true)
            }
        }
        
        // Wooden crate breaks into planks
        if target.node.name == "wooden_crate" && target.hitCount >= target.maxHits - 1 {
            spawnCratePlanks(at: target.node.position)
        }
    }
    
    private func spawnCratePlanks(at position: SCNVector3) {
        let plankMat = SCNMaterial()
        plankMat.diffuse.contents = UIColor(red: 0.5, green: 0.35, blue: 0.18, alpha: 1)
        plankMat.roughness.contents = 0.9
        
        for _ in 0..<5 {
            let plank = SCNBox(width: 0.5, height: 0.03, length: 0.1, chamferRadius: 0)
            plank.materials = [plankMat]
            let plankNode = SCNNode(geometry: plank)
            plankNode.position = SCNVector3(
                position.x + Float.random(in: -0.2...0.2),
                position.y + Float.random(in: 0...0.3),
                position.z + Float.random(in: -0.2...0.2)
            )
            plankNode.physicsBody = SCNPhysicsBody.dynamic()
            plankNode.physicsBody?.mass = 0.5
            plankNode.physicsBody?.categoryBitMask = PhysicsCategory.debris
            plankNode.physicsBody?.applyForce(SCNVector3(
                Float.random(in: -3...3),
                Float.random(in: 2...4),
                Float.random(in: -3...3)
            ), asImpulse: true)
            plankNode.physicsBody?.applyTorque(SCNVector4(
                Float.random(in: -1...1),
                Float.random(in: -1...1),
                Float.random(in: -1...1),
                Float.random(in: -8...8)
            ), asImpulse: true)
            scene.rootNode.addChildNode(plankNode)
            debrisNodes.append(plankNode)
        }
    }
    
    // MARK: - ============================================================
    // MARK: - AUDIO SYSTEM (Material-Aware with Pseudo-Reverb)
    // MARK: - ============================================================
    
    private func playMaterialSound(material: ObjectMaterial, tool: RageTool, intensity: Float) {
        // Try to load custom sound file first
        let soundName = tool.soundFile
        if let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = Float.random(in: 0.7...1.0)
                player.rate = Float.random(in: 0.9...1.1)
                player.play()
                audioPlayers[soundName] = player
                return
            } catch {
                // Fall through to system sounds
            }
        }
        
        // Material-specific system sound selection
        let primarySounds = material.impactSounds
        let primaryID = primarySounds.randomElement() ?? 1104
        AudioServicesPlaySystemSound(SystemSoundID(primaryID))
        
        // Pseudo-reverb: play secondary sound with slight delay at lower perceived volume
        if intensity > 2.0 || tool == .sledgehammer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                let secondaryID = material.secondarySounds.randomElement() ?? primaryID
                AudioServicesPlaySystemSound(SystemSoundID(secondaryID))
            }
        }
        
        // Multi-sound on big hits (impact + scatter)
        if intensity > 3.5 || internalComboCount >= 10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                let scatterSounds: [UInt32] = [1109, 1110, 1057, 1073]
                let scatterID = scatterSounds.randomElement() ?? 1109
                AudioServicesPlaySystemSound(SystemSoundID(scatterID))
            }
        }
        
        // Low rumble on sledgehammer (deeper sound IDs)
        if tool == .sledgehammer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                let rumbleSounds: [UInt32] = [1070, 1071, 1023]
                AudioServicesPlaySystemSound(SystemSoundID(rumbleSounds.randomElement() ?? 1070))
            }
        }
    }
    
    private func playDestructionSound(material: ObjectMaterial) {
        // Triple-layered destruction sound
        let primaryID = material.impactSounds.randomElement() ?? 1104
        AudioServicesPlaySystemSound(SystemSoundID(primaryID))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            let secondaryID = material.secondarySounds.randomElement() ?? 1109
            AudioServicesPlaySystemSound(SystemSoundID(secondaryID))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
            let crumbleSounds: [UInt32] = [1073, 1071, 1070]
            AudioServicesPlaySystemSound(SystemSoundID(crumbleSounds.randomElement() ?? 1073))
        }
    }
    
    // MARK: - ============================================================
    // MARK: - HAPTIC SYSTEM (Layered with Aftershock)
    // MARK: - ============================================================
    
    private func triggerLayeredHaptic(tool: RageTool, material: ObjectMaterial) {
        switch tool {
        case .sledgehammer:
            // Heavy primary impact
            let heavyGen = UIImpactFeedbackGenerator(style: .heavy)
            heavyGen.impactOccurred(intensity: 1.0)
            // Medium aftershock 50ms later
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let medGen = UIImpactFeedbackGenerator(style: .medium)
                medGen.impactOccurred(intensity: 0.7)
            }
            // Subtle third pulse for resonance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                let lightGen = UIImpactFeedbackGenerator(style: .light)
                lightGen.impactOccurred(intensity: 0.3)
            }
            
        case .bat:
            // Heavy crack
            let heavyGen = UIImpactFeedbackGenerator(style: .heavy)
            heavyGen.impactOccurred(intensity: 0.9)
            // Softer follow-through
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                let medGen = UIImpactFeedbackGenerator(style: .medium)
                medGen.impactOccurred(intensity: 0.5)
            }
            
        case .fists:
            // Medium punch
            let medGen = UIImpactFeedbackGenerator(style: .medium)
            medGen.impactOccurred(intensity: 0.8)
            // Light skin-slap
            if material == .flesh {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                    let lightGen = UIImpactFeedbackGenerator(style: .light)
                    lightGen.impactOccurred(intensity: 0.4)
                }
            }
            
        case .throwPlates:
            // Light toss feeling
            let lightGen = UIImpactFeedbackGenerator(style: .light)
            lightGen.impactOccurred(intensity: 0.6)
            // Shatter tinkle on glass/ceramic
            if material == .glass || material == .ceramic {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    let softGen = UIImpactFeedbackGenerator(style: .soft)
                    softGen.impactOccurred(intensity: 0.4)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    let softGen2 = UIImpactFeedbackGenerator(style: .soft)
                    softGen2.impactOccurred(intensity: 0.2)
                }
            }
            
        case .spray:
            // Subtle spray feeling
            let softGen = UIImpactFeedbackGenerator(style: .soft)
            softGen.impactOccurred(intensity: 0.3)
        }
    }
    
    // MARK: - ============================================================
    // MARK: - SPRAY PAINT SYSTEM
    // MARK: - ============================================================
    
    /// Public spray method for UIViewRepresentable hit-test spray
    func sprayAt(position: SCNVector3) {
        spawnSprayMark(at: position)
        // Haptic for spray
        let gen = UIImpactFeedbackGenerator(style: .soft)
        gen.impactOccurred(intensity: 0.2)
    }

    private func spawnSprayMark(at position: SCNVector3) {
        let size = CGFloat.random(in: 0.06...0.14)
        let sprayDot = SCNPlane(width: size, height: size)
        let dotMat = SCNMaterial()
        dotMat.diffuse.contents = currentSprayColor
        dotMat.emission.contents = currentSprayColor.withAlphaComponent(0.3)
        dotMat.transparent.contents = UIColor(white: 1, alpha: 0.85)
        dotMat.isDoubleSided = true
        dotMat.writesToDepthBuffer = true
        sprayDot.materials = [dotMat]
        sprayDot.cornerRadius = size / 2
        
        let node = SCNNode(geometry: sprayDot)
        node.position = position
        node.name = "spray_mark"
        scene.rootNode.addChildNode(node)
        sprayNodes.append(node)
        
        // Spray hiss sound (occasional)
        if Int.random(in: 0...3) == 0 {
            let hissSounds: [UInt32] = [1100, 1101, 1054]
            AudioServicesPlaySystemSound(SystemSoundID(hissSounds.randomElement() ?? 1100))
        }
        
        // Limit spray marks for performance
        if sprayNodes.count > maxSprayNodes {
            let removeCount = 50
            for i in 0..<removeCount {
                sprayNodes[i].removeFromParentNode()
            }
            sprayNodes.removeFirst(removeCount)
        }
    }
    
    // MARK: - ============================================================
    // MARK: - PHYSICS CONTACT DELEGATE
    // MARK: - ============================================================
    
    nonisolated func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        // Get collision force (approximated by impulse)
        let impulse = contact.collisionImpulse
        guard impulse > 1.0 else { return }
        
        let contactPoint = contact.contactPoint
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        Task { @MainActor [weak self] in
            guard let self else { return }
            let position = SCNVector3(
                contactPoint.x,
                contactPoint.y,
                contactPoint.z
            )
            
            // Determine material of colliding objects
            var material: ObjectMaterial = .concrete
            if let obj = self.destructibleObjects.first(where: { $0.node == nodeA || $0.node == nodeB }) {
                material = obj.material
            }
            
            // Spawn collision particles based on force
            if impulse > 3.0 {
                self.spawnMaterialParticles(at: position, material: material, intensity: Float(impulse) * 0.3)
            }
            
            // Play collision sound for significant impacts
            if impulse > 5.0 {
                let soundID = material.impactSounds.randomElement() ?? 1104
                AudioServicesPlaySystemSound(SystemSoundID(soundID))
                
                // Light haptic for ambient collisions
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred(intensity: min(CGFloat(impulse) * 0.1, 0.5))
            }
        }
    }
    
    // MARK: - ============================================================
    // MARK: - PARTICLE IMAGE GENERATORS (Programmatic)
    // MARK: - ============================================================
    
    /// Creates a simple filled circle image for particle textures
    private func createCircleImage(size: Int, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            color.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
    }
    
    /// Creates a soft-edged circle for dust/smoke particles
    private func createSoftCircleImage(size: Int) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = CGFloat(size) / 2.0
            
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(white: 1, alpha: 0.8).cgColor,
                    UIColor(white: 1, alpha: 0.3).cgColor,
                    UIColor(white: 1, alpha: 0.0).cgColor,
                ] as CFArray,
                locations: [0.0, 0.5, 1.0]
            )
            
            if let gradient = gradient {
                ctx.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center, startRadius: 0,
                    endCenter: center, endRadius: radius,
                    options: []
                )
            }
        }
    }
    
    /// Creates a diamond/angular shape for glass shard particles
    private func createDiamondImage(size: Int) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            let s = CGFloat(size)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: s / 2, y: 0))
            path.addLine(to: CGPoint(x: s * 0.8, y: s / 2))
            path.addLine(to: CGPoint(x: s / 2, y: s))
            path.addLine(to: CGPoint(x: s * 0.2, y: s / 2))
            path.close()
            
            UIColor(white: 1, alpha: 0.9).setFill()
            path.fill()
        }
    }
    
    /// Creates an elongated splinter shape for wood particles
    private func createSplinterImage(size: Int) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size / 3))
        return renderer.image { ctx in
            let w = CGFloat(size)
            let h = CGFloat(size / 3)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: h / 2))
            path.addLine(to: CGPoint(x: w * 0.3, y: 0))
            path.addLine(to: CGPoint(x: w, y: h * 0.3))
            path.addLine(to: CGPoint(x: w * 0.7, y: h))
            path.close()
            
            UIColor(white: 1, alpha: 0.9).setFill()
            path.fill()
        }
    }
}
