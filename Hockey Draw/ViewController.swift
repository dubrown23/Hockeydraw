import UIKit
import PencilKit

class ViewController: UIViewController {
    
    private var iceRinkView: IceRinkView!
    private var tokenContainerView: UIView!
    private var canvasView: PKCanvasView!
    private var drawingToolbar: UIToolbar!
    private var modeSelector: UISegmentedControl!
    private var positionSelector: UISegmentedControl!
    private var clearButton: UIBarButtonItem!
    private var undoButton: UIBarButtonItem!  // NEW: Undo last action
    private var modeToggle: UISegmentedControl!  // NEW: Toggle between placement and drawing
    
    // Token management
    private var playerTokens: [PlayerToken] = []
    private var puckToken: PuckToken?
    private var currentPosition: PlayerPosition = .center
    
    // Undo system
    enum UndoAction {
        case addedToken(PlayerToken)
        case addedPath(HockeyPath)
        case movedToken(token: PlayerToken, fromPosition: CGPoint)
        case deletedToken(token: PlayerToken, position: CGPoint, index: Int)
        case changedTeamColor(token: PlayerToken, fromColor: UIColor)
    }
    
    private var undoStack: [UndoAction] = []
    
    // App modes
    enum AppMode {
        case placement
        case drawing
    }
    
    private var currentAppMode: AppMode = .placement {
        didSet {
            updateUIForMode()
            // Update drawing view's selected token reference
            customDrawingView.selectedToken = nil
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
    }
    
    // Hockey path structure
    struct HockeyPath {
        let path: UIBezierPath
        let mode: DrawingMode
        weak var token: PlayerToken?  // Token that follows this path
    }
    
    private var currentMode: DrawingMode = .forward
    private var hockeyPaths: [HockeyPath] = []
    private var customDrawingView: CustomDrawingView!
    
    // Token selection for path drawing
    private var selectedToken: PlayerToken? {
        didSet {
            // Update visual selection state
            playerTokens.forEach { $0.layer.borderWidth = 0 }
            selectedToken?.layer.borderWidth = 3
            selectedToken?.layer.borderColor = UIColor.systemYellow.cgColor
            
            // Update drawing view
            customDrawingView.selectedToken = selectedToken
            customDrawingView.setNeedsDisplay()
            
            // Update instruction label
            if currentAppMode == .drawing {
                if selectedToken != nil {
                    instructionLabel.text = "Draw path for \(selectedToken!.positionLabel) - Long press another player to switch"
                } else {
                    instructionLabel.text = "Long press a player to select, then draw their path"
                }
            }
        }
    }
    
    // Animation properties
    private var isAnimating = false
    private var animationTimer: Timer?
    private var animationProgress: CGFloat = 0.0
    private var playButton: UIBarButtonItem!
    
    // Instruction label
    private var instructionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupIceRink()
        setupTokenContainer()
        setupCustomDrawingView()
        setupPencilKit()
        setupToolbar()
        setupInstructionLabel()
        setupTapGesture()
        
        // Long press for selecting tokens
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressForSelection(_:)))
        longPressGesture.minimumPressDuration = 0.3
        longPressGesture.allowableMovement = 10  // Allow slight movement
        
        // Enable both finger and pencil
        if #available(iOS 13.0, *) {
            longPressGesture.allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber,
                                                   UITouch.TouchType.pencil.rawValue as NSNumber]
        }
        
        canvasView.addGestureRecognizer(longPressGesture)
        
        // Triple tap to assign puck to a player
        let tripleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTripleTap(_:)))
        tripleTapGesture.numberOfTapsRequired = 3
        tokenContainerView.addGestureRecognizer(tripleTapGesture)
        
        // Start in placement mode
        currentAppMode = .placement
        updateUIForMode()
    }
    
    @objc private func handleLongPressForSelection(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        guard currentAppMode == .drawing else { return }
        
        let location = gesture.location(in: tokenContainerView)
        
        // Find token at location
        for token in playerTokens.reversed() {
            if token.frame.contains(location) {
                selectedToken = token
                
                // Haptic feedback
                let feedback = UIImpactFeedbackGenerator(style: .medium)
                feedback.prepare()
                feedback.impactOccurred()
                
                return
            }
        }
        
        // If no token found, deselect
        selectedToken = nil
    }
    
    private func setupIceRink() {
        iceRinkView = IceRinkView(frame: view.bounds)
        iceRinkView.backgroundColor = UIColor.systemBackground
        view.addSubview(iceRinkView)
        
        iceRinkView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iceRinkView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 90),
            iceRinkView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            iceRinkView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            iceRinkView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTokenContainer() {
        tokenContainerView = UIView(frame: .zero)
        tokenContainerView.backgroundColor = .clear
        tokenContainerView.isUserInteractionEnabled = true
        view.addSubview(tokenContainerView)
        
        tokenContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tokenContainerView.topAnchor.constraint(equalTo: iceRinkView.topAnchor),
            tokenContainerView.leadingAnchor.constraint(equalTo: iceRinkView.leadingAnchor),
            tokenContainerView.trailingAnchor.constraint(equalTo: iceRinkView.trailingAnchor),
            tokenContainerView.bottomAnchor.constraint(equalTo: iceRinkView.bottomAnchor)
        ])
    }
    
    private func setupCustomDrawingView() {
        customDrawingView = CustomDrawingView(frame: .zero)
        customDrawingView.backgroundColor = .clear
        customDrawingView.isOpaque = false
        customDrawingView.isUserInteractionEnabled = false
        view.addSubview(customDrawingView)
        
        customDrawingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customDrawingView.topAnchor.constraint(equalTo: iceRinkView.topAnchor),
            customDrawingView.leadingAnchor.constraint(equalTo: iceRinkView.leadingAnchor),
            customDrawingView.trailingAnchor.constraint(equalTo: iceRinkView.trailingAnchor),
            customDrawingView.bottomAnchor.constraint(equalTo: iceRinkView.bottomAnchor)
        ])
    }
    
    private func setupPencilKit() {
        canvasView = PKCanvasView(frame: .zero)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        view.addSubview(canvasView)
        
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: iceRinkView.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: iceRinkView.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: iceRinkView.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: iceRinkView.bottomAnchor)
        ])
        
        let pencilTool = PKInkingTool(.pencil, color: .black, width: 3)
        canvasView.tool = pencilTool
    }
    
    private func setupToolbar() {
        drawingToolbar = UIToolbar(frame: .zero)
        drawingToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(drawingToolbar)
        
        // Mode toggle (Placement vs Drawing)
        modeToggle = UISegmentedControl(items: ["Place", "Draw"])
        modeToggle.selectedSegmentIndex = 0  // Start with placement
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
        
        clearButton = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearCanvas))
        undoButton = UIBarButtonItem(title: "Undo", style: .plain, target: self, action: #selector(undoLastAction))
        playButton = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(toggleAnimation))
        
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
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleRinkTap(_:)))
        tapGesture.cancelsTouchesInView = false  // Allow other touches to pass through
        tokenContainerView.addGestureRecognizer(tapGesture)
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
    
    private func updateInstructionLabel() {
        switch currentAppMode {
        case .placement:
            instructionLabel.text = "Tap to place players • Triple-tap player to give puck"
        case .drawing:
            if selectedToken != nil {
                instructionLabel.text = "Draw path for \(selectedToken!.positionLabel) • Long press another player to switch"
            } else {
                instructionLabel.text = "Long press a player to select • Triple-tap to give puck"
            }
        }
    }
    
    @objc private func appModeChanged() {
        currentAppMode = modeToggle.selectedSegmentIndex == 0 ? .placement : .drawing
    }
    
    private func updateUIForMode() {
        switch currentAppMode {
        case .placement:
            // Enable token placement, disable drawing
            canvasView.isUserInteractionEnabled = false
            tokenContainerView.isUserInteractionEnabled = true
            
            // Show position selector, hide drawing mode selector
            positionSelector.isHidden = false
            modeSelector.isHidden = true
            
            // Visual feedback
            positionSelector.alpha = 1.0
            modeSelector.alpha = 0.3
            
            // Update instruction
            updateInstructionLabel()
            
        case .drawing:
            // Enable drawing
            canvasView.isUserInteractionEnabled = true
            tokenContainerView.isUserInteractionEnabled = true
            
            // Hide position selector, show drawing mode selector
            positionSelector.isHidden = true
            modeSelector.isHidden = false
            
            // Visual feedback
            positionSelector.alpha = 0.3
            modeSelector.alpha = 1.0
            
            // Clear any selection when switching modes
            selectedToken = nil
            
            // Update instruction
            updateInstructionLabel()
        }
    }
    
    @objc private func handleRinkTap(_ gesture: UITapGestureRecognizer) {
        // Only handle taps in placement mode
        guard currentAppMode == .placement else { return }
        
        let location = gesture.location(in: tokenContainerView)
        
        // Create new token at tap location
        let token = PlayerToken(position: currentPosition.abbreviation, teamColor: .systemRed)
        token.center = location
        token.delegate = self
        
        // Update the token's stored position percentage
        token.rinkPosition = CGPoint(
            x: location.x / tokenContainerView.bounds.width,
            y: location.y / tokenContainerView.bounds.height
        )
        
        tokenContainerView.addSubview(token)
        playerTokens.append(token)
        
        // Add to undo stack
        undoStack.append(.addedToken(token))
        
        // Animate token appearance
        token.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            token.transform = .identity
        })
        
        // Create puck if this is the first token and no puck exists
        if puckToken == nil {
            let puck = PuckToken()
            tokenContainerView.addSubview(puck)
            puckToken = puck
            
            // Place puck at center of rink initially (not with any player)
            puck.center = CGPoint(x: tokenContainerView.bounds.width / 2,
                                 y: tokenContainerView.bounds.height / 2)
            puck.rinkPosition = CGPoint(x: 0.5, y: 0.5)
        }
    }
    
    @objc private func modeChanged() {
        currentMode = DrawingMode(rawValue: modeSelector.selectedSegmentIndex) ?? .forward
        
        if currentMode == .erase {
            canvasView.tool = PKEraserTool(.bitmap)
        } else {
            canvasView.tool = PKInkingTool(.pencil, color: .black, width: 3)
        }
    }
    
    @objc private func positionChanged() {
        currentPosition = PlayerPosition(rawValue: positionSelector.selectedSegmentIndex) ?? .center
    }
    
    @objc private func clearCanvas() {
        // Clear drawings
        canvasView.drawing = PKDrawing()
        hockeyPaths.removeAll()
        customDrawingView.paths = []
        customDrawingView.setNeedsDisplay()
        
        // Clear tokens
        playerTokens.forEach { $0.removeFromSuperview() }
        playerTokens.removeAll()
        
        // Clear puck
        puckToken?.removeFromSuperview()
        puckToken = nil
        
        // Clear undo stack
        undoStack.removeAll()
        
        // Reset animation
        stopAnimation()
        selectedToken = nil
    }
    
    @objc private func undoLastAction() {
        guard let lastAction = undoStack.popLast() else { return }
        
        switch lastAction {
        case .addedToken(let token):
            // Remove the token that was added
            if let index = playerTokens.firstIndex(of: token) {
                playerTokens.remove(at: index)
            }
            UIView.animate(withDuration: 0.2, animations: {
                token.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                token.alpha = 0
            }) { _ in
                token.removeFromSuperview()
            }
            
        case .addedPath(let path):
            // Remove the last path that was added
            if let index = hockeyPaths.firstIndex(where: { $0.path === path.path }) {
                hockeyPaths.remove(at: index)
                customDrawingView.paths = hockeyPaths
                customDrawingView.setNeedsDisplay()
            }
            
        case .movedToken(let token, let fromPosition):
            // Move token back to previous position
            UIView.animate(withDuration: 0.2) {
                token.center = fromPosition
            }
            token.rinkPosition = CGPoint(
                x: fromPosition.x / tokenContainerView.bounds.width,
                y: fromPosition.y / tokenContainerView.bounds.height
            )
            
        case .deletedToken(let token, let position, let index):
            // Restore deleted token
            token.center = position
            token.alpha = 1.0
            token.transform = .identity
            tokenContainerView.addSubview(token)
            playerTokens.insert(token, at: min(index, playerTokens.count))
            
        case .changedTeamColor(let token, let fromColor):
            // Revert team color change
            UIView.animate(withDuration: 0.2) {
                token.teamColor = fromColor
            }
        }
    }
    
    // Handle device rotation
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update token positions based on new bounds
        for token in playerTokens {
            token.updatePositionFromPercentage(in: tokenContainerView.bounds)
        }
    }
    
    // Smooth path using Catmull-Rom spline interpolation with Douglas-Peucker simplification
    private func smoothPath(_ points: [CGPoint]) -> UIBezierPath {
        guard points.count > 2 else {
            let path = UIBezierPath()
            if points.count > 0 {
                path.move(to: points[0])
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            return path
        }
        
        // First, simplify the path using Douglas-Peucker algorithm to remove noise
        let simplifiedPoints = douglasPeucker(points: points, epsilon: 3.0)
        
        // If we have very few points after simplification, just return a simple path
        guard simplifiedPoints.count > 3 else {
            let path = UIBezierPath()
            path.move(to: simplifiedPoints[0])
            for point in simplifiedPoints.dropFirst() {
                path.addLine(to: point)
            }
            return path
        }
        
        let path = UIBezierPath()
        path.move(to: simplifiedPoints[0])
        
        // Use Catmull-Rom spline for smooth curves
        for i in 0..<simplifiedPoints.count - 1 {
            let p0 = simplifiedPoints[max(0, i - 1)]
            let p1 = simplifiedPoints[i]
            let p2 = simplifiedPoints[min(simplifiedPoints.count - 1, i + 1)]
            let p3 = simplifiedPoints[min(simplifiedPoints.count - 1, i + 2)]
            
            if i == 0 {
                continue
            }
            
            // Calculate control points with higher tension for smoother curves
            let tension: CGFloat = 0.3  // Lower tension = smoother curves
            let cp1x = p1.x + (p2.x - p0.x) / 6 * tension
            let cp1y = p1.y + (p2.y - p0.y) / 6 * tension
            let cp2x = p2.x - (p3.x - p1.x) / 6 * tension
            let cp2y = p2.y - (p3.y - p1.y) / 6 * tension
            
            let cp1 = CGPoint(x: cp1x, y: cp1y)
            let cp2 = CGPoint(x: cp2x, y: cp2y)
            
            path.addCurve(to: p2, controlPoint1: cp1, controlPoint2: cp2)
        }
        
        return path
    }
    
    // Douglas-Peucker algorithm for path simplification
    private func douglasPeucker(points: [CGPoint], epsilon: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }
        
        // Find the point with the maximum distance from the line between start and end
        var maxDistance: CGFloat = 0
        var maxIndex = 0
        
        let start = points.first!
        let end = points.last!
        
        for i in 1..<points.count - 1 {
            let distance = perpendicularDistance(point: points[i], lineStart: start, lineEnd: end)
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }
        
        // If max distance is greater than epsilon, recursively simplify
        if maxDistance > epsilon {
            // Recursive simplification
            let firstPart = douglasPeucker(points: Array(points[0...maxIndex]), epsilon: epsilon)
            let secondPart = douglasPeucker(points: Array(points[maxIndex..<points.count]), epsilon: epsilon)
            
            // Combine results (avoiding duplicate middle point)
            var result = firstPart
            result.append(contentsOf: secondPart.dropFirst())
            return result
        } else {
            // If all points are close enough to the line, just keep endpoints
            return [start, end]
        }
    }
    
    // Calculate perpendicular distance from point to line
    @objc private func handleTripleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: tokenContainerView)
        
        // Find token at location
        for token in playerTokens.reversed() {
            if token.frame.contains(location) {
                // Give puck to this player
                if let puck = puckToken {
                    playerTokens.forEach { $0.hasPuck = false }
                    token.hasPuck = true
                    puck.currentHolder = token
                    puck.updatePosition()
                    
                    // Visual feedback
                    UIView.animate(withDuration: 0.2) {
                        token.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                    } completion: { _ in
                        UIView.animate(withDuration: 0.2) {
                            token.transform = .identity
                        }
                    }
                    
                    // Update instruction
                    instructionLabel.text = "\(token.positionLabel) now has the puck"
                    
                    // Haptic feedback
                    let feedback = UIImpactFeedbackGenerator(style: .medium)
                    feedback.impactOccurred()
                }
                
                return
            }
        }
    }
    
    private func perpendicularDistance(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        
        if dx == 0 && dy == 0 {
            // Start and end are the same point
            return hypot(point.x - lineStart.x, point.y - lineStart.y)
        }
        
        let normalLength = hypot(dx, dy)
        let distance = abs(dy * point.x - dx * point.y + lineEnd.x * lineStart.y - lineEnd.y * lineStart.x) / normalLength
        
        return distance
    }
    
    // MARK: - Animation Methods
    @objc private func toggleAnimation() {
        if isAnimating {
            stopAnimation()
        } else {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        guard !hockeyPaths.isEmpty else { return }
        
        isAnimating = true
        animationProgress = 0.0
        playButton.image = UIImage(systemName: "pause.fill")
        
        // Store original positions
        for token in playerTokens {
            token.layer.removeAllAnimations()
        }
        
        // Start animation timer
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func stopAnimation() {
        isAnimating = false
        animationTimer?.invalidate()
        animationTimer = nil
        playButton.image = UIImage(systemName: "play.fill")
        
        // Reset tokens to original positions
        for token in playerTokens {
            token.updatePositionFromPercentage(in: tokenContainerView.bounds)
        }
    }
    
    private func updateAnimation() {
        animationProgress += 0.005  // Adjust speed as needed
        
        if animationProgress >= 1.0 {
            stopAnimation()
            return
        }
        
        // Track which paths are complete for puck transfer
        var completedPaths: Set<Int> = []
        
        // Animate each token along its path
        for (index, path) in hockeyPaths.enumerated() {
            guard let token = path.token else { continue }
            
            // Get point along path at current progress
            if let point = pointAlongPath(path.path, at: animationProgress) {
                token.center = point
                
                // Move puck with player if they have it
                if token.hasPuck, let puck = puckToken {
                    puck.updatePosition()
                }
                
                // Check if this is a puck-related path
                switch path.mode {
                case .withPuck:
                    // Player should have puck while skating with it
                    if !token.hasPuck, let puck = puckToken {
                        playerTokens.forEach { $0.hasPuck = false }
                        token.hasPuck = true
                        puck.currentHolder = token
                    }
                case .pass, .shoot:
                    // Animate puck along the path
                    if token.hasPuck, let puck = puckToken, let puckPoint = pointAlongPath(path.path, at: animationProgress) {
                        // Release puck at start of pass/shoot
                        if animationProgress < 0.1 {
                            token.hasPuck = false
                            puck.currentHolder = nil
                        }
                        
                        // Move puck along path
                        puck.center = puckPoint
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func pointAlongPath(_ path: UIBezierPath, at progress: CGFloat) -> CGPoint? {
        guard progress >= 0 && progress <= 1 else { return nil }
        
        // This is a simplified version - for production, use path length calculations
        var points: [CGPoint] = []
        
        path.cgPath.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                points.append(element.pointee.points[0])
            case .addLineToPoint:
                points.append(element.pointee.points[0])
            case .addCurveToPoint:
                // Sample curve
                let start = points.last ?? element.pointee.points[0]
                let cp1 = element.pointee.points[0]
                let cp2 = element.pointee.points[1]
                let end = element.pointee.points[2]
                
                for i in 1...10 {
                    let t = CGFloat(i) / 10.0
                    let point = bezierPoint(start: start, cp1: cp1, cp2: cp2, end: end, t: t)
                    points.append(point)
                }
            default:
                break
            }
        }
        
        guard !points.isEmpty else { return nil }
        
        let totalPoints = points.count
        let targetIndex = Int(CGFloat(totalPoints - 1) * progress)
        
        return points[min(targetIndex, totalPoints - 1)]
    }
    
    private func bezierPoint(start: CGPoint, cp1: CGPoint, cp2: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
        let mt = 1 - t
        let mt2 = mt * mt
        let mt3 = mt2 * mt
        let t2 = t * t
        let t3 = t2 * t
        
        let x = mt3 * start.x + 3 * mt2 * t * cp1.x + 3 * mt * t2 * cp2.x + t3 * end.x
        let y = mt3 * start.y + 3 * mt2 * t * cp1.y + 3 * mt * t2 * cp2.y + t3 * end.y
        
        return CGPoint(x: x, y: y)
    }
    
    // Get the end point of a path
    private func getEndPoint(of path: UIBezierPath) -> CGPoint? {
        var endPoint: CGPoint?
        
        path.cgPath.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                endPoint = element.pointee.points[0]
            case .addLineToPoint:
                endPoint = element.pointee.points[0]
            case .addCurveToPoint:
                endPoint = element.pointee.points[2]  // End point is the third point
            default:
                break
            }
        }
        
        return endPoint
    }
}

// MARK: - PlayerTokenDelegate
extension ViewController: PlayerTokenDelegate {
    func playerTokenDidMove(_ token: PlayerToken) {
        // Move puck with player if they have it
        if token.hasPuck, let puck = puckToken {
            puck.updatePosition()
        }
    }
    
    func playerTokenDidEndMoving(_ token: PlayerToken) {
        // Update puck position
        if token.hasPuck, let puck = puckToken {
            puck.updatePosition()
        }
    }
    
    func playerTokenDidChangeTeam(_ token: PlayerToken) {
        // Track team color change for undo
        let previousColor: UIColor = token.teamColor == .systemBlue ? .systemRed : .systemBlue
        undoStack.append(.changedTeamColor(token: token, fromColor: previousColor))
    }
    
    func playerTokenRequestsDelete(_ token: PlayerToken) {
        // Track deletion for undo
        if let index = playerTokens.firstIndex(of: token) {
            undoStack.append(.deletedToken(token: token, position: token.center, index: index))
            playerTokens.remove(at: index)
            
            // If deleted player had puck, drop it at their location
            if token.hasPuck, let puck = puckToken {
                token.hasPuck = false
                puck.currentHolder = nil
                puck.rinkPosition = CGPoint(
                    x: token.center.x / tokenContainerView.bounds.width,
                    y: token.center.y / tokenContainerView.bounds.height
                )
            }
        }
    }
}

// MARK: - PKCanvasViewDelegate
extension ViewController: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard let latestStroke = canvasView.drawing.strokes.last else { return }
        
        // Only process if we're in drawing mode
        guard currentAppMode == .drawing else { return }
        
        // Extract points from stroke
        var points: [CGPoint] = []
        let strokePath = latestStroke.path
        
        // Sample points at regular intervals for consistency
        let sampleInterval: CGFloat = 5.0
        var currentLength: CGFloat = 0
        var lastPoint: CGPoint?
        
        for i in 0..<strokePath.count {
            let point = strokePath[i].location
            
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
        if let finalPoint = strokePath.last?.location {
            points.append(finalPoint)
        }
        
        // Create smoothed path
        let smoothedPath = smoothPath(points)
        
        // Create hockey path
        let hockeyPath = HockeyPath(path: smoothedPath, mode: currentMode, token: selectedToken)
        hockeyPaths.append(hockeyPath)
        
        // Store original position for selected token (for animation)
        if let token = selectedToken {
            token.tag = hockeyPaths.count - 1  // Store path index in tag
            
            // Handle puck logic based on drawing mode
            switch currentMode {
            case .withPuck:
                // Give puck to this player if they don't have it
                if !token.hasPuck, let puck = puckToken {
                    // Remove puck from current holder
                    playerTokens.forEach { $0.hasPuck = false }
                    
                    // Give to selected token
                    token.hasPuck = true
                    puck.currentHolder = token
                }
            case .pass, .shoot:
                // Release puck from player if they have it
                if token.hasPuck, let puck = puckToken {
                    token.hasPuck = false
                    puck.currentHolder = nil
                    
                    // Position puck at end of path
                    if let endPoint = getEndPoint(of: smoothedPath) {
                        puck.animateTo(position: endPoint)
                        puck.rinkPosition = CGPoint(
                            x: endPoint.x / tokenContainerView.bounds.width,
                            y: endPoint.y / tokenContainerView.bounds.height
                        )
                    }
                }
            default:
                break
            }
        }
        
        // Add to undo stack
        undoStack.append(.addedPath(hockeyPath))
        
        // Update drawing
        customDrawingView.paths = hockeyPaths
        customDrawingView.setNeedsDisplay()
        
        // Clear PencilKit canvas
        canvasView.drawing = PKDrawing()
    }
}

// MARK: - Custom Drawing View
class CustomDrawingView: UIView {
    var paths: [ViewController.HockeyPath] = []
    var selectedToken: PlayerToken?  // To highlight selected token's paths
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Set up context for consistent rendering
        setupContextForConsistency(context)
        
        for hockeyPath in paths {
            drawHockeyPath(hockeyPath, in: context)
        }
    }
    
    private func setupContextForConsistency(_ context: CGContext) {
        // Precise rendering settings
        context.setLineCap(.round)       // Rounded line ends for smoother appearance
        context.setLineJoin(.round)      // Rounded corners
        context.setMiterLimit(10.0)      // Allow sharp angles
        context.setShouldAntialias(true) // Keep antialiasing for smooth curves
        context.setAllowsAntialiasing(true)
        context.interpolationQuality = .high
        
        // Ensure consistent stroke rendering
        context.setStrokeColor(UIColor.black.cgColor)
    }
    
    private func drawHockeyPath(_ hockeyPath: ViewController.HockeyPath, in context: CGContext) {
        let path = hockeyPath.path
        
        // Save context state
        context.saveGState()
        
        // Highlight path if it belongs to selected token
        if let token = hockeyPath.token, token == selectedToken {
            context.setAlpha(1.0)
            context.setLineWidth(4.0)  // Thicker line for selected
        } else if selectedToken != nil {
            context.setAlpha(0.3)  // Dim other paths when one is selected
        }
        
        switch hockeyPath.mode {
        case .forward:
            drawSolidLine(path: path, in: context)
        case .backward:
            drawBackwardSkating(path: path, in: context)
        case .withPuck:
            drawSkatingWithPuck(path: path, in: context)
        case .pass:
            drawPassLine(path: path, in: context)
        case .shoot:
            drawShootLine(path: path, in: context)
        case .erase:
            break
        }
        
        // Restore context state
        context.restoreGState()
        
        // Add arrow at end
        if hockeyPath.mode != .erase {
            drawArrow(on: path, in: context)
        }
    }
    
    private func drawSolidLine(path: UIBezierPath, in context: CGContext) {
        context.setLineWidth(2.5)
        context.addPath(path.cgPath)
        context.strokePath()
    }
    
    // Helper function to get points along a path
    private func samplePath(_ path: UIBezierPath, every interval: CGFloat) -> [(point: CGPoint, angle: CGFloat)] {
        var samples: [(point: CGPoint, angle: CGFloat)] = []
        var previousPoint: CGPoint?
        var currentLength: CGFloat = 0
        var targetLength: CGFloat = 0
        
        path.cgPath.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                previousPoint = element.pointee.points[0]
                
            case .addLineToPoint:
                guard let start = previousPoint else { return }
                let end = element.pointee.points[0]
                let segmentLength = hypot(end.x - start.x, end.y - start.y)
                
                // Sample points along this segment
                while targetLength <= currentLength + segmentLength {
                    let t = (targetLength - currentLength) / segmentLength
                    let point = CGPoint(
                        x: start.x + t * (end.x - start.x),
                        y: start.y + t * (end.y - start.y)
                    )
                    let angle = atan2(end.y - start.y, end.x - start.x)
                    samples.append((point, angle))
                    targetLength += interval
                }
                
                currentLength += segmentLength
                previousPoint = end
                
            case .addCurveToPoint:
                // Handle curve sampling
                guard let start = previousPoint else { return }
                let cp1 = element.pointee.points[0]
                let cp2 = element.pointee.points[1]
                let end = element.pointee.points[2]
                
                // Sample the curve
                let steps = 10
                var lastSampledPoint = start
                
                for i in 0...steps {
                    let t = CGFloat(i) / CGFloat(steps)
                    let point = bezierPoint(start: start, cp1: cp1, cp2: cp2, end: end, t: t)
                    
                    // Calculate tangent angle
                    let dt = 0.01
                    let nextT = min(1.0, t + dt)
                    let nextPoint = bezierPoint(start: start, cp1: cp1, cp2: cp2, end: end, t: nextT)
                    let angle = atan2(nextPoint.y - point.y, nextPoint.x - point.x)
                    
                    if i > 0 {
                        let distance = hypot(point.x - lastSampledPoint.x, point.y - lastSampledPoint.y)
                        currentLength += distance
                        
                        if currentLength >= targetLength {
                            samples.append((point, angle))
                            targetLength += interval
                            lastSampledPoint = point
                        }
                    } else if samples.isEmpty && targetLength == 0 {
                        // Add the first point if we haven't sampled anything yet
                        samples.append((point, angle))
                        lastSampledPoint = point
                        targetLength += interval
                    }
                }
                
                previousPoint = end
                
            default:
                break
            }
        }
        
        return samples
    }
    
    private func bezierPoint(start: CGPoint, cp1: CGPoint, cp2: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
        let mt = 1 - t
        let mt2 = mt * mt
        let mt3 = mt2 * mt
        let t2 = t * t
        let t3 = t2 * t
        
        let x = mt3 * start.x + 3 * mt2 * t * cp1.x + 3 * mt * t2 * cp2.x + t3 * end.x
        let y = mt3 * start.y + 3 * mt2 * t * cp1.y + 3 * mt * t2 * cp2.y + t3 * end.y
        
        return CGPoint(x: x, y: y)
    }
    
    private func drawBackwardSkating(path: UIBezierPath, in context: CGContext) {
        context.setLineWidth(2.0)
        
        // Get all points along the smoothed path
        var pathPoints: [CGPoint] = []
        var totalLength: CGFloat = 0
        
        path.cgPath.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                pathPoints.append(element.pointee.points[0])
            case .addLineToPoint:
                if let lastPoint = pathPoints.last {
                    let newPoint = element.pointee.points[0]
                    totalLength += hypot(newPoint.x - lastPoint.x, newPoint.y - lastPoint.y)
                    pathPoints.append(newPoint)
                }
            case .addCurveToPoint:
                if let start = pathPoints.last {
                    let cp1 = element.pointee.points[0]
                    let cp2 = element.pointee.points[1]
                    let end = element.pointee.points[2]
                    
                    // Sample curve points
                    for i in 1...10 {
                        let t = CGFloat(i) / 10.0
                        let point = bezierPoint(start: start, cp1: cp1, cp2: cp2, end: end, t: t)
                        if let lastPoint = pathPoints.last {
                            totalLength += hypot(point.x - lastPoint.x, point.y - lastPoint.y)
                        }
                        pathPoints.append(point)
                    }
                }
            default:
                break
            }
        }
        
        guard pathPoints.count > 1 else { return }
        
        // Calculate exact spacing for C-shapes
        let cSpacing: CGFloat = 20  // Fixed spacing between C-shapes
        let numberOfCs = Int(totalLength / cSpacing)
        
        guard numberOfCs > 0 else { return }
        
        // Place C-shapes at exact intervals along the path
        var currentDistance: CGFloat = 0
        var currentIndex = 0
        
        for cIndex in 0...numberOfCs {
            let targetDistance = CGFloat(cIndex) * cSpacing
            
            // Find the position along the path for this C-shape
            while currentIndex < pathPoints.count - 1 {
                let start = pathPoints[currentIndex]
                let end = pathPoints[currentIndex + 1]
                let segmentLength = hypot(end.x - start.x, end.y - start.y)
                
                if currentDistance + segmentLength >= targetDistance {
                    // Interpolate position
                    let t = (targetDistance - currentDistance) / segmentLength
                    let position = CGPoint(
                        x: start.x + t * (end.x - start.x),
                        y: start.y + t * (end.y - start.y)
                    )
                    let angle = atan2(end.y - start.y, end.x - start.x)
                    
                    // Draw C-shape at this position
                    context.saveGState()
                    context.translateBy(x: position.x, y: position.y)
                    context.rotate(by: angle)
                    
                    let cRadius: CGFloat = 5
                    context.beginPath()
                    context.addArc(center: CGPoint.zero,
                                  radius: cRadius,
                                  startAngle: .pi/2,      // Start at bottom
                                  endAngle: -.pi/2,       // End at top
                                  clockwise: true)
                    
                    context.strokePath()
                    context.restoreGState()
                    
                    break
                }
                
                currentDistance += segmentLength
                currentIndex += 1
            }
            
            if currentIndex >= pathPoints.count - 1 {
                break
            }
        }
    }
    
    private func drawSkatingWithPuck(path: UIBezierPath, in context: CGContext) {
        context.setLineWidth(2.5)
        
        // Get the smoothed path points
        var pathPoints: [CGPoint] = []
        path.cgPath.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                pathPoints.append(element.pointee.points[0])
            case .addLineToPoint:
                pathPoints.append(element.pointee.points[0])
            case .addCurveToPoint:
                // Sample curve points
                let end = element.pointee.points[2]
                pathPoints.append(end)
            default:
                break
            }
        }
        
        guard pathPoints.count > 1 else { return }
        
        // Create a mathematically consistent zigzag along the path
        let zigzagPath = UIBezierPath()
        let wavelength: CGFloat = 12  // Distance between peaks
        let amplitude: CGFloat = 4     // Height of zigzag
        
        var currentDistance: CGFloat = 0
        zigzagPath.move(to: pathPoints[0])
        
        // Walk along the path and create uniform zigzag
        for i in 1..<pathPoints.count {
            let start = pathPoints[i-1]
            let end = pathPoints[i]
            let segmentLength = hypot(end.x - start.x, end.y - start.y)
            let angle = atan2(end.y - start.y, end.x - start.x)
            let perpAngle = angle + .pi/2
            
            // Number of zigzag points in this segment
            let steps = Int(segmentLength / 3) + 1
            
            for step in 1...steps {
                let t = CGFloat(step) / CGFloat(steps)
                let basePoint = CGPoint(
                    x: start.x + t * (end.x - start.x),
                    y: start.y + t * (end.y - start.y)
                )
                
                currentDistance += segmentLength / CGFloat(steps)
                
                // Calculate zigzag offset using sine wave
                let phase = currentDistance / wavelength * .pi * 2
                let offset = sin(phase) * amplitude
                
                let zigzagPoint = CGPoint(
                    x: basePoint.x + cos(perpAngle) * offset,
                    y: basePoint.y + sin(perpAngle) * offset
                )
                
                zigzagPath.addLine(to: zigzagPoint)
            }
        }
        
        context.addPath(zigzagPath.cgPath)
        context.strokePath()
    }
    
    private func drawPassLine(path: UIBezierPath, in context: CGContext) {
        context.setLineWidth(2.0)
        
        // Simple dashed line
        let dashPattern: [CGFloat] = [8, 4]
        context.setLineDash(phase: 0, lengths: dashPattern)
        
        context.addPath(path.cgPath)
        context.strokePath()
        
        // Reset dash
        context.setLineDash(phase: 0, lengths: [])
    }
    
    private func drawShootLine(path: UIBezierPath, in context: CGContext) {
        context.setLineWidth(2.0)
        
        // Get the smoothed path points for consistent parallel lines
        var pathPoints: [CGPoint] = []
        var angles: [CGFloat] = []
        
        path.cgPath.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                pathPoints.append(element.pointee.points[0])
            case .addLineToPoint:
                let start = pathPoints.last ?? element.pointee.points[0]
                let end = element.pointee.points[0]
                pathPoints.append(end)
                let angle = atan2(end.y - start.y, end.x - start.x)
                angles.append(angle)
            case .addCurveToPoint:
                // For curves, sample a few points
                if let start = pathPoints.last {
                    let cp1 = element.pointee.points[0]
                    let cp2 = element.pointee.points[1]
                    let end = element.pointee.points[2]
                    
                    // Sample curve at a few points
                    for i in 1...5 {
                        let t = CGFloat(i) / 5.0
                        let point = bezierPoint(start: start, cp1: cp1, cp2: cp2, end: end, t: t)
                        pathPoints.append(point)
                        
                        // Calculate angle at this point
                        let dt = 0.01
                        let prevT = max(0, t - dt)
                        let prevPoint = bezierPoint(start: start, cp1: cp1, cp2: cp2, end: end, t: prevT)
                        let angle = atan2(point.y - prevPoint.y, point.x - prevPoint.x)
                        angles.append(angle)
                    }
                }
            default:
                break
            }
        }
        
        guard pathPoints.count > 1 else {
            // Fallback to simple line
            context.addPath(path.cgPath)
            context.strokePath()
            return
        }
        
        // Create two perfectly parallel paths
        let offset: CGFloat = 3.0
        let path1 = UIBezierPath()
        let path2 = UIBezierPath()
        
        // Calculate perpendicular offsets for each point
        for (index, point) in pathPoints.enumerated() {
            let angle: CGFloat
            if index < angles.count {
                angle = angles[index]
            } else if index > 0 && index - 1 < angles.count {
                angle = angles[index - 1]
            } else {
                angle = 0
            }
            
            let perpAngle = angle + .pi/2
            let offsetX = cos(perpAngle) * offset
            let offsetY = sin(perpAngle) * offset
            
            let point1 = CGPoint(x: point.x + offsetX, y: point.y + offsetY)
            let point2 = CGPoint(x: point.x - offsetX, y: point.y - offsetY)
            
            if index == 0 {
                path1.move(to: point1)
                path2.move(to: point2)
            } else {
                path1.addLine(to: point1)
                path2.addLine(to: point2)
            }
        }
        
        // Draw both lines
        context.addPath(path1.cgPath)
        context.strokePath()
        context.addPath(path2.cgPath)
        context.strokePath()
    }
    
    private func drawArrow(on path: UIBezierPath, in context: CGContext) {
        guard !path.isEmpty else { return }
        
        // Get the last few points to determine final direction
        var lastPoints: [CGPoint] = []
        var secondLastPoint: CGPoint?
        
        path.cgPath.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                lastPoints = [element.pointee.points[0]]
            case .addLineToPoint:
                secondLastPoint = lastPoints.last
                lastPoints.append(element.pointee.points[0])
                // Keep only last few points
                if lastPoints.count > 10 {
                    lastPoints.removeFirst()
                }
            case .addCurveToPoint:
                // For curves, sample the end portion
                let end = element.pointee.points[2]
                lastPoints.append(end)
                if lastPoints.count > 10 {
                    lastPoints.removeFirst()
                }
            default:
                break
            }
        }
        
        // Get end point and calculate direction from last segment
        guard let endPoint = lastPoints.last,
              lastPoints.count >= 2 else { return }
        
        // Use the last few points to get a better direction
        let lookbackIndex = max(0, lastPoints.count - 5)
        let referencePoint = lastPoints[lookbackIndex]
        
        let dx = endPoint.x - referencePoint.x
        let dy = endPoint.y - referencePoint.y
        let direction = atan2(dy, dx)
        
        // Create filled arrowhead
        context.setFillColor(UIColor.black.cgColor)
        
        let arrowLength: CGFloat = 16  // Increased size
        let arrowWidth: CGFloat = 10   // Width of the arrowhead
        
        // Calculate arrowhead points
        let arrowTip = endPoint
        
        // Left wing of arrow
        let leftWingAngle = direction + .pi - .pi/5  // 36 degree angle
        let leftWing = CGPoint(
            x: endPoint.x + cos(leftWingAngle) * arrowLength,
            y: endPoint.y + sin(leftWingAngle) * arrowLength
        )
        
        // Right wing of arrow
        let rightWingAngle = direction + .pi + .pi/5  // 36 degree angle
        let rightWing = CGPoint(
            x: endPoint.x + cos(rightWingAngle) * arrowLength,
            y: endPoint.y + sin(rightWingAngle) * arrowLength
        )
        
        // Back center of arrow (for filled triangle)
        let backCenter = CGPoint(
            x: endPoint.x + cos(direction + .pi) * (arrowLength * 0.7),
            y: endPoint.y + sin(direction + .pi) * (arrowLength * 0.7)
        )
        
        // Draw filled arrowhead
        context.beginPath()
        context.move(to: arrowTip)
        context.addLine(to: leftWing)
        context.addLine(to: backCenter)
        context.addLine(to: rightWing)
        context.closePath()
        context.fillPath()
        
        // Optional: Add outline for definition
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.0)
        context.beginPath()
        context.move(to: arrowTip)
        context.addLine(to: leftWing)
        context.addLine(to: backCenter)
        context.addLine(to: rightWing)
        context.closePath()
        context.strokePath()
    }
}

// MARK: - Ice Rink View (unchanged)
class IceRinkView: UIView {
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawHockeyRink(in: rect)
    }
    
    private func drawHockeyRink(in rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // NHL rink: 200ft x 85ft (exact 2.35:1 ratio)
        let margin: CGFloat = 30
        let availableWidth = rect.width - (margin * 2)
        let availableHeight = rect.height - (margin * 2)
        
        // Calculate rink size maintaining EXACT NHL proportions
        let nhlRatio: CGFloat = 200.0 / 85.0  // 2.35:1
        var rinkWidth: CGFloat
        var rinkHeight: CGFloat
        
        if availableWidth / availableHeight > nhlRatio {
            // Height is limiting - use full height
            rinkHeight = availableHeight
            rinkWidth = rinkHeight * nhlRatio
        } else {
            // Width is limiting - use full width
            rinkWidth = availableWidth
            rinkHeight = rinkWidth / nhlRatio
        }
        
        // Center the rink on screen
        let rinkRect = CGRect(
            x: (rect.width - rinkWidth) / 2,
            y: (rect.height - rinkHeight) / 2,
            width: rinkWidth,
            height: rinkHeight
        )
        
        // White ice surface with rounded corners
        context.setFillColor(UIColor.white.cgColor)
        let cornerRadius: CGFloat = rinkHeight * 0.15  // Small corner radius
        let rinkPath = UIBezierPath(roundedRect: rinkRect, cornerRadius: cornerRadius)
        context.addPath(rinkPath.cgPath)
        context.fillPath()
        
        // Center line (RED) - thick line ALL THE WAY ACROSS
        let centerX = rinkRect.midX
        context.setStrokeColor(UIColor.systemRed.cgColor)
        context.setLineWidth(6.0)
        context.move(to: CGPoint(x: centerX, y: rinkRect.minY))
        context.addLine(to: CGPoint(x: centerX, y: rinkRect.maxY))
        context.strokePath()
        
        // Goal lines (RED) - EXACTLY 11ft from ends
        let goalLineDistance = rinkWidth * (11.0 / 200.0)  // Exact NHL measurement
        context.setStrokeColor(UIColor.systemRed.cgColor)
        context.setLineWidth(3.0)
        
        // Left goal line
        let leftGoalX = rinkRect.minX + goalLineDistance
        context.move(to: CGPoint(x: leftGoalX, y: rinkRect.minY))
        context.addLine(to: CGPoint(x: leftGoalX, y: rinkRect.maxY))
        context.strokePath()
        
        // Right goal line
        let rightGoalX = rinkRect.maxX - goalLineDistance
        context.move(to: CGPoint(x: rightGoalX, y: rinkRect.minY))
        context.addLine(to: CGPoint(x: rightGoalX, y: rinkRect.maxY))
        context.strokePath()
        
        // Blue lines (BLUE) - EXACTLY 75ft from ends
        let blueLineDistance = rinkWidth * (75.0 / 200.0)  // Exact NHL measurement
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(6.0)
        
        // Left blue line
        let leftBlueX = rinkRect.minX + blueLineDistance
        context.move(to: CGPoint(x: leftBlueX, y: rinkRect.minY))
        context.addLine(to: CGPoint(x: leftBlueX, y: rinkRect.maxY))
        context.strokePath()
        
        // Right blue line
        let rightBlueX = rinkRect.maxX - blueLineDistance
        context.move(to: CGPoint(x: rightBlueX, y: rinkRect.minY))
        context.addLine(to: CGPoint(x: rightBlueX, y: rinkRect.maxY))
        context.strokePath()
        
        // Center circle (BLUE) - EXACTLY 15ft radius
        let centerCircleRadius = rinkHeight * (15.0 / 85.0)  // Exact NHL measurement
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(2.0)
        let centerCircle = CGRect(
            x: centerX - centerCircleRadius,
            y: rinkRect.midY - centerCircleRadius,
            width: centerCircleRadius * 2,
            height: centerCircleRadius * 2
        )
        context.strokeEllipse(in: centerCircle)
        
        // Center face-off dot
        drawDot(context: context, center: CGPoint(x: centerX, y: rinkRect.midY))
        
        // Face-off circles (RED) - EXACTLY 15ft radius, 22ft from goal line, 22ft from center
        let faceOffRadius = rinkHeight * (15.0 / 85.0)      // 15ft radius
        let faceOffFromGoal = rinkWidth * (22.0 / 200.0)    // 22ft from goal line
        let faceOffFromCenter = rinkHeight * (22.0 / 85.0)  // 22ft from center line
        
        // Left zone face-off circles - positioned EXACTLY per NHL specs
        let leftFaceOffX = leftGoalX + faceOffFromGoal
        drawSmallCircle(context: context, center: CGPoint(x: leftFaceOffX, y: rinkRect.midY - faceOffFromCenter), radius: faceOffRadius)
        drawSmallCircle(context: context, center: CGPoint(x: leftFaceOffX, y: rinkRect.midY + faceOffFromCenter), radius: faceOffRadius)
        
        // Right zone face-off circles
        let rightFaceOffX = rightGoalX - faceOffFromGoal
        drawSmallCircle(context: context, center: CGPoint(x: rightFaceOffX, y: rinkRect.midY - faceOffFromCenter), radius: faceOffRadius)
        drawSmallCircle(context: context, center: CGPoint(x: rightFaceOffX, y: rinkRect.midY + faceOffFromCenter), radius: faceOffRadius)
        
        // Neutral zone dots (RED) - positioned between blue lines
        let neutralDotFromBlue = rinkWidth * (5.0 / 200.0)  // 5ft from blue line
        let neutralX1 = leftBlueX + neutralDotFromBlue
        let neutralX2 = rightBlueX - neutralDotFromBlue
        
        drawDot(context: context, center: CGPoint(x: neutralX1, y: rinkRect.midY - faceOffFromCenter))
        drawDot(context: context, center: CGPoint(x: neutralX1, y: rinkRect.midY + faceOffFromCenter))
        drawDot(context: context, center: CGPoint(x: neutralX2, y: rinkRect.midY - faceOffFromCenter))
        drawDot(context: context, center: CGPoint(x: neutralX2, y: rinkRect.midY + faceOffFromCenter))
        
        // Goals (RED) - EXACTLY 6ft wide x 4ft deep
        let goalWidth = rinkHeight * (6.0 / 85.0)   // 6ft wide
        let goalDepth = rinkWidth * (4.0 / 200.0)   // 4ft deep
        context.setStrokeColor(UIColor.systemRed.cgColor)
        context.setLineWidth(2.0)
        
        // Left goal
        let leftGoal = CGRect(
            x: leftGoalX - goalDepth,
            y: rinkRect.midY - goalWidth/2,
            width: goalDepth,
            height: goalWidth
        )
        context.stroke(leftGoal)
        
        // Right goal
        let rightGoal = CGRect(
            x: rightGoalX,
            y: rinkRect.midY - goalWidth/2,
            width: goalDepth,
            height: goalWidth
        )
        context.stroke(rightGoal)
        
        // Goal creases (BLUE) - SIMPLE half circles on the GOAL SIDE of goal line
        let creaseRadius = rinkHeight * (6.0 / 85.0)  // 6ft radius
        context.setFillColor(UIColor.systemBlue.withAlphaComponent(0.3).cgColor)
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(2.0)
        
        // Left crease - half circle on the LEFT side of goal line (toward goal/boards)
        let leftCreasePath = UIBezierPath()
        leftCreasePath.addArc(withCenter: CGPoint(x: leftGoalX, y: rinkRect.midY),
                             radius: creaseRadius,
                             startAngle: CGFloat.pi/2,    // Bottom
                             endAngle: -CGFloat.pi/2,     // Top
                             clockwise: false)            // Left half circle
        leftCreasePath.close()
        context.addPath(leftCreasePath.cgPath)
        context.fillPath()
        context.strokePath()
        
        // Right crease - half circle on the RIGHT side of goal line (toward goal/boards)
        let rightCreasePath = UIBezierPath()
        rightCreasePath.addArc(withCenter: CGPoint(x: rightGoalX, y: rinkRect.midY),
                              radius: creaseRadius,
                              startAngle: -CGFloat.pi/2,   // Top
                              endAngle: CGFloat.pi/2,      // Bottom
                              clockwise: false)            // Right half circle
        rightCreasePath.close()
        context.addPath(rightCreasePath.cgPath)
        context.fillPath()
        context.strokePath()
        
        // DRAW BOARD LINE LAST - so it's on top of all other lines
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(3.0)
        context.addPath(rinkPath.cgPath)
        context.strokePath()
    }
    
    private func drawDot(context: CGContext, center: CGPoint) {
        let dotRadius: CGFloat = 8
        let dot = CGRect(
            x: center.x - dotRadius,
            y: center.y - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        )
        context.setFillColor(UIColor.systemRed.cgColor)
        context.fillEllipse(in: dot)
    }
    
    private func drawSmallCircle(context: CGContext, center: CGPoint, radius: CGFloat) {
        context.setStrokeColor(UIColor.systemRed.cgColor)
        context.setLineWidth(1.5)
        let circle = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        context.strokeEllipse(in: circle)
        
        // Face-off dot in center
        drawDot(context: context, center: center)
    }
}
