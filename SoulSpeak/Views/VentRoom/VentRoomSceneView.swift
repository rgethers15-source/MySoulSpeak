import SwiftUI
import SceneKit

/// VentRoomSceneView — UIViewRepresentable wrapper for SCNView.
/// This gives us PRECISE tap coordinates for hit-testing specific objects.
/// SwiftUI's SceneView doesn't expose tap location — this does.
struct VentRoomSceneView: UIViewRepresentable {
    let sceneManager: RageRoomSceneManager
    let selectedTool: RageTool
    let onTap: (CGPoint) -> Void
    let onDoubleTap: () -> Void
    let onSwipe: (CGPoint, CGPoint) -> Void // start point, velocity
    let onPinch: (CGFloat) -> Void

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = sceneManager.scene
        scnView.pointOfView = sceneManager.cameraNode
        scnView.backgroundColor = .black
        scnView.antialiasingMode = .multisampling4X
        scnView.isJitteringEnabled = true
        scnView.allowsCameraControl = false
        scnView.showsStatistics = false

        // Tap gesture (single)
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        scnView.addGestureRecognizer(tapGesture)

        // Double tap
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scnView.addGestureRecognizer(doubleTapGesture)
        tapGesture.require(toFail: doubleTapGesture)

        // Swipe/Pan gesture (for throwing)
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        scnView.addGestureRecognizer(panGesture)

        // Pinch gesture (zoom)
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        scnView.addGestureRecognizer(pinchGesture)

        // Long press (spray paint)
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.3
        scnView.addGestureRecognizer(longPress)

        context.coordinator.scnView = scnView
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.selectedTool = selectedTool
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator (handles gestures)
    class Coordinator: NSObject {
        let parent: VentRoomSceneView
        var scnView: SCNView?
        var selectedTool: RageTool = .fists
        private var panStartPoint: CGPoint = .zero

        init(_ parent: VentRoomSceneView) {
            self.parent = parent
            self.selectedTool = parent.selectedTool
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = scnView else { return }
            let point = gesture.location(in: view)
            Task { @MainActor in
                parent.onTap(point)
                parent.sceneManager.hitObjectAt(point: point, in: view, with: selectedTool)
            }
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = scnView else { return }
            let point = gesture.location(in: view)
            Task { @MainActor in
                parent.onDoubleTap()
                for i in 0..<3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) { [self] in
                        parent.sceneManager.hitObjectAt(point: point, in: view, with: selectedTool)
                    }
                }
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = scnView else { return }

            switch gesture.state {
            case .began:
                panStartPoint = gesture.location(in: view)
            case .ended:
                let velocity = gesture.velocity(in: view)
                let endPoint = gesture.location(in: view)
                let speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)

                Task { @MainActor in
                    if speed > 500 {
                        parent.sceneManager.throwObjectAt(point: panStartPoint, in: view, velocity: velocity)
                        parent.onSwipe(panStartPoint, velocity)
                    } else {
                        parent.sceneManager.hitObjectAt(point: endPoint, in: view, with: selectedTool)
                    }
                }
            default:
                break
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            if gesture.state == .changed {
                let scale = gesture.scale
                Task { @MainActor in
                    parent.onPinch(scale)
                    parent.sceneManager.zoomCamera(scale: scale)
                }
                gesture.scale = 1.0
            }
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let view = scnView, selectedTool == .spray else { return }
            let point = gesture.location(in: view)

            switch gesture.state {
            case .began, .changed:
                let hitResults = view.hitTest(point, options: [.searchMode: SCNHitTestSearchMode.closest.rawValue])
                if let hit = hitResults.first {
                    Task { @MainActor in
                        parent.sceneManager.sprayAt(position: hit.worldCoordinates)
                    }
                }
            default:
                break
            }
        }
    }
}
