import UIKit
import SpriteKit
import PencilKit

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    // UI Elements
    private var skView: SKView!
    private var scene: HockeyRinkScene!
    private var canvasView: PKCanvasView!
    private var drawingToolbar: UIToolbar!
    private var modeSelector: UISegmentedControl!
    private var positionSelector: UISegmentedControl!
    private var clearButton: UIBarButtonItem!
    private var undoButton: UIBarButtonItem!
    private var modeToggle: UISegmentedControl!
    private var playButton: UIBarButtonItem!
    private var instructionLabel: UILabel!
    
    // Gesture recognizers
    private var doubleTapGesture: UITapGestureRecognizer!
    private var longPressGesture: UILongPressGestureRecognizer!
    
    // App modes
    enum AppMode {
        case placement
        case drawing
    }
    
    private var currentAppMode: AppMode = .placement {
        didSet {
            updateUIForMode()
            scene?.setMode(currentAppMode == .placement ? .placement : .drawing)
        }
    }
    
    // Player positions
    enum PlayerPosition: Int, CaseIterable {
        case rightWing = 0
        case leftWing
        case center
        case rightDefense
        case leftDefense
        case goalie
        
        var abbreviation: String {
            switch self {
            case .rightWing: return "RW"
            case .leftWing: return "LW"
            case .center: return "C"
            case .rightDefense: return "RD"
            case .leftDefense: return "LD"
            case .goalie: return "G"
            }
        }
        
        var scenePosition: HockeyRinkScene.PlayerPosition {
            switch self {
            case .rightWing: return .rightWing
            case .leftWing: return .leftWing
            case .center: return .center
            case .rightDefense: return .rightDefense
            case .leftDefense: return .leftDefense
            case .goalie: return .goalie
            }
        }
    }
    
    // Drawing modes
    enum DrawingMode: Int, CaseIterable {
        case forward = 0
        case backward
        case withPuck
        case pass
        case shoot
        case erase
        
        var title: String {
            switch self {
            case .forward: return "Forward"
            case .backward: return "Backward"
            case .withPuck: return "W/ Puck"
            case .pass: return "Pass"
            case .shoot: return "Shoot"
            case .erase: return "Erase"
            }
        }
        
        var sceneMode: HockeyRinkScene.DrawingMode {
            switch self {
            case .forward: return .forward
            case .backward: return .backward
            case .withPuck: return .withPuck
            case .pass: return .pass
            case .shoot: return .shoot
            case .erase: return .erase
            }
        }
    }
    
    private var currentMode: DrawingMode = .forward
    private var currentPosition: PlayerPosition = .center
    
    // Undo system
    enum UndoAction {
        case addedPlayer
        case addedPath
        case clearedAll
    }
    
    private var undoStack: [UndoAction] = []
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSKView()
        setupScene()
        setupPencilKit()
        setupToolbar()
        setupInstructionLabel()
        setupGestures()
        
        // Start in placement mode
        currentAppMode = .placement
        updateUIForMode()
        updateButtonStates()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update scene size if needed
        scene?.size = skView.bounds.size
    }
    
    // MARK: - Setup Methods
    
    private func setupSKView() {
        skView = SKView(frame: view.bounds)
        skView.backgroundColor = .systemBackground
        skView.showsFPS = false  // Set to true for debugging
        skView.showsNodeCount = false  // Set to true for debugging
        skView.ignoresSiblingOrder = true
        view.addSubview(skView)
        
        skView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            skView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 90),
            skView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            skView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupScene() {
        scene = HockeyRinkScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        scene.sceneDelegate = self
        skView.presentScene(scene)
    }
    
    private func setupPencilKit() {
        canvasView = PKCanvasView(frame: .zero)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        canvasView.isUserInteractionEnabled = false  // Start disabled
        view.addSubview(canvasView)
        
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: skView.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: skView.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: skView.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: skView.bottomAnchor)
        ])
        
        // Configure drawing tool with visible color for debugging
        let pencilTool = PKInkingTool(.pencil, color: .black, width: 3)
        canvasView.tool = pencilTool
    }
    
    private func setupToolbar() {
        drawingToolbar = UIToolbar(frame: .zero)
        drawingToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(drawingToolbar)
        
        // Mode toggle (Placement vs Drawing)
        modeToggle = UISegmentedControl(items: ["Place", "Draw"])
        modeToggle.selectedSegmentIndex = 0
        modeToggle.addTarget(self, action: #selector(appModeChanged), for: .valueChanged)
        
        // Drawing mode selector
        let titles = DrawingMode.allCases.map { $0.title }
        modeSelector = UISegmentedControl(items: titles)
        modeSelector.selectedSegmentIndex = 0
        modeSelector.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        
        // Position selector
        let positions = PlayerPosition.allCases.map { $0.abbreviation }
        positionSelector = UISegmentedControl(items: positions)
        positionSelector.selectedSegmentIndex = PlayerPosition.center.rawValue
        positionSelector.addTarget(self, action: #selector(positionChanged), for: .valueChanged)
        
        // Buttons
        clearButton = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearCanvas))
        undoButton = UIBarButtonItem(title: "Undo", style: .plain, target: self, action: #selector(undoLastAction))
        playButton = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(toggleAnimation))
        
        // Toolbar items
        let modeToggleItem = UIBarButtonItem(customView: modeToggle)
        let drawingModeItem = UIBarButtonItem(customView: modeSelector)
        let positionItem = UIBarButtonItem(customView: positionSelector)
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let separator1 = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        separator1.width = 10
        let separator2 = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        separator2.width = 10
        
        drawingToolbar.items = [modeToggleItem, separator1, positionItem, drawingModeItem, flexSpace, playButton, undoButton, clearButton]
        
        NSLayoutConstraint.activate([
            drawingToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            drawingToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            drawingToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            drawingToolbar.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupInstructionLabel() {
        instructionLabel = UILabel()
        instructionLabel.font = .systemFont(ofSize: 14)
        instructionLabel.textAlignment = .center
        instructionLabel.textColor = .label
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: drawingToolbar.bottomAnchor, constant: 5),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            instructionLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        updateInstructionLabel()
    }
    
    private func setupGestures() {
        // Double tap to assign puck
        doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        skView.addGestureRecognizer(doubleTapGesture)
        
        // Long press to select player in drawing mode
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.3
        longPressGesture.allowableMovement = 10
        
        if #available(iOS 13.0, *) {
            longPressGesture.allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber,
                                                   UITouch.TouchType.pencil.rawValue as NSNumber]
        }
        
        // Add to canvas view instead of SKView when in drawing mode
        canvasView.addGestureRecognizer(longPressGesture)
    }
    
    // MARK: - UI Updates
    
    private func updateUIForMode() {
        switch currentAppMode {
        case .placement:
            // Disable PencilKit, enable scene touches
            canvasView.isUserInteractionEnabled = false
            skView.isUserInteractionEnabled = true
            
            // Show position selector, hide drawing mode
            positionSelector.isHidden = false
            modeSelector.isHidden = true
            
            positionSelector.alpha = 1.0
            modeSelector.alpha = 0.3
            
            updateInstructionLabel()
            
        case .drawing:
            // Enable PencilKit for drawing
            canvasView.isUserInteractionEnabled = true
            skView.isUserInteractionEnabled = true
            
            // Hide position selector, show drawing mode
            positionSelector.isHidden = true
            modeSelector.isHidden = false
            
            positionSelector.alpha = 0.3
            modeSelector.alpha = 1.0
            
            updateInstructionLabel()
        }
    }
    
    private func updateInstructionLabel() {
        switch currentAppMode {
        case .placement:
            instructionLabel.text = "Tap to place players • Double-tap player to give puck"
        case .drawing:
            instructionLabel.text = "Long press a player to select • Draw paths"
        }
    }
    
    // MARK: - Actions
    
    @objc private func appModeChanged() {
        currentAppMode = modeToggle.selectedSegmentIndex == 0 ? .placement : .drawing
    }
    
    @objc private func modeChanged() {
        currentMode = DrawingMode(rawValue: modeSelector.selectedSegmentIndex) ?? .forward
        scene.setDrawingMode(currentMode.sceneMode)
        
        // Configure PencilKit tool
        if currentMode == .erase {
            canvasView.tool = PKEraserTool(.bitmap)
        } else {
            canvasView.tool = PKInkingTool(.pencil, color: .black, width: 3)
        }
    }
    
    @objc private func positionChanged() {
        currentPosition = PlayerPosition(rawValue: positionSelector.selectedSegmentIndex) ?? .center
        scene.setPlayerPosition(currentPosition.scenePosition)
    }
    
    @objc private func clearCanvas() {
        scene.clearAll()
        canvasView.drawing = PKDrawing()
        undoStack.removeAll()
        
        // Reset UI
        playButton.image = UIImage(systemName: "play.fill")
        updateInstructionLabel()
        updateButtonStates()
    }
    
    @objc private func undoLastAction() {
        print("Undo button pressed")
        
        // Call scene's undo method
        if scene.undoLastAction() {
            // Success - update button states
            updateButtonStates()
            
            // Haptic feedback
            let feedback = UIImpactFeedbackGenerator(style: .light)
            feedback.impactOccurred()
        }
    }
    
    @objc private func toggleAnimation() {
        scene.toggleAnimation()
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: skView)
        
        // Convert to scene coordinates
        let sceneLocation = scene.convertPoint(fromView: location)
        
        if scene.assignPuck(at: sceneLocation) {
            // Success - haptic feedback
            let feedback = UIImpactFeedbackGenerator(style: .heavy)
            feedback.impactOccurred()
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        guard currentAppMode == .drawing else { return }
        
        let location = gesture.location(in: skView)
        let sceneLocation = scene.convertPoint(fromView: location)
        
        // Debug print
        print("Long press at: \(location), scene: \(sceneLocation)")
        
        // Try to select player
        if scene.selectPlayer(at: sceneLocation) {
            // Success - haptic feedback
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.prepare()
            feedback.impactOccurred()
            
            print("Player selected!")
        } else {
            print("No player found at location")
        }
        
        // Also check for path endpoint continuation
        if let endpoint = scene.findPathEndpoint(near: sceneLocation) {
            // Handle path continuation
            let feedback = UIImpactFeedbackGenerator(style: .light)
            feedback.impactOccurred()
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractPoints(from stroke: PKStroke) -> [CGPoint] {
        var points: [CGPoint] = []
        let path = stroke.path
        
        let sampleInterval: CGFloat = 5.0
        var currentLength: CGFloat = 0
        var lastPoint: CGPoint?
        
        for i in 0..<path.count {
            let point = path[i].location
            
            if let last = lastPoint {
                let distance = hypot(point.x - last.x, point.y - last.y)
                currentLength += distance
                
                if currentLength >= sampleInterval {
                    points.append(point)
                    currentLength = 0
                    lastPoint = point
                }
            } else {
                points.append(point)
                lastPoint = point
            }
        }
        
        // Always include the last point
        if let finalPoint = path.last?.location {
            points.append(finalPoint)
        }
        
        return points
    }
}

// MARK: - PKCanvasViewDelegate

extension ViewController: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard let latestStroke = canvasView.drawing.strokes.last else { return }
        guard currentAppMode == .drawing else { return }
        
        // Extract points from stroke
        let points = extractPoints(from: latestStroke)
        
        // Debug print
        print("Drawing stroke with \(points.count) points")
        
        // Get selected player from scene
        guard let selectedPlayer = scene.selectedPlayer else {
            // No player selected
            instructionLabel.text = "Long press a player first to select them"
            canvasView.drawing = PKDrawing()
            return
        }
        
        print("Adding path for player: \(selectedPlayer.positionLabel)")
        
        // Convert points to scene coordinates
        let scenePoints = points.map { point in
            scene.convertPoint(fromView: point)
        }
        
        // Add path to scene
        scene.addPath(from: scenePoints, mode: currentMode.sceneMode, for: selectedPlayer)
        
        // Add to undo stack
        undoStack.append(.addedPath)
        
        // Update button states
        updateButtonStates()
        
        // Clear canvas for next stroke
        canvasView.drawing = PKDrawing()
    }
}

// MARK: - HockeyRinkSceneDelegate

extension ViewController: HockeyRinkSceneDelegate {
    func updateInstructions(_ text: String) {
        instructionLabel.text = text
    }
    
    func updatePlayButton(isPlaying: Bool) {
        playButton.image = UIImage(systemName: isPlaying ? "pause.fill" : "play.fill")
    }
    
    func drillAnimationComplete() {
        // Animation finished
        playButton.image = UIImage(systemName: "play.fill")
    }
    
    func updateButtonStates() {
        // Enable undo if there are players or paths
        let hasContent = !scene.playerNodes.isEmpty || !scene.allPaths.isEmpty
        undoButton.isEnabled = hasContent
        
        // Enable play if there are paths
        playButton.isEnabled = !scene.allPaths.isEmpty
        
        // Enable clear if there's content
        clearButton.isEnabled = hasContent
    }
}
