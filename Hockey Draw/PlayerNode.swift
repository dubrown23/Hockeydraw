//
//  PlayerNode.swift
//  Hockey Draw
//
//  Created by Assistant on 12/19/24.
//

import SpriteKit

class PlayerNode: SKShapeNode {
    
    // MARK: - Properties
    
    // Player identification
    let id = UUID()
    let positionLabel: String
    var teamColor: UIColor {
        didSet {
            updateAppearance()
        }
    }
    
    // Puck management
    var hasPuck: Bool = false {
        didSet {
            updatePuckIndicator()
        }
    }
    
    // Position tracking
    var originalPosition: CGPoint = .zero
    private(set) var isAnimating: Bool = false
    
    // Visual elements
    private let labelNode: SKLabelNode
    private let selectionRing: SKShapeNode
    private let puckIndicator: SKShapeNode
    
    // Path management
    private var assignedPaths: [PathNode] = []
    private var currentPathIndex: Int = 0
    
    // Public getter for assigned paths
    var paths: [PathNode] {
        return assignedPaths
    }
    
    // Animation completion
    private var animationCompletion: (() -> Void)?
    
    // Constants
    private static let playerRadius: CGFloat = 18  // 36pt diameter
    private static let selectionRingWidth: CGFloat = 3
    private static let puckIndicatorRadius: CGFloat = 3
    
    // MARK: - Initialization
    
    init(position: String, teamColor: UIColor = .systemRed) {
        self.positionLabel = position
        self.teamColor = teamColor
        
        // Create label
        labelNode = SKLabelNode(text: position)
        labelNode.fontSize = 11
        labelNode.fontName = "Helvetica-Bold"
        labelNode.fontColor = .white
        labelNode.verticalAlignmentMode = .center
        labelNode.horizontalAlignmentMode = .center
        
        // Create selection ring (hidden by default)
        selectionRing = SKShapeNode(circleOfRadius: PlayerNode.playerRadius + 5)
        selectionRing.strokeColor = .systemYellow
        selectionRing.lineWidth = PlayerNode.selectionRingWidth
        selectionRing.fillColor = .clear
        selectionRing.alpha = 0
        
        // Create puck indicator (small indicator on player)
        puckIndicator = SKShapeNode(circleOfRadius: PlayerNode.puckIndicatorRadius)
        puckIndicator.fillColor = .black
        puckIndicator.strokeColor = .clear
        puckIndicator.position = CGPoint(x: 0, y: PlayerNode.playerRadius - 5)
        puckIndicator.alpha = 0
        puckIndicator.isHidden = true  // Hide by default since we have actual puck object
        
        super.init()
        
        // Setup player circle
        self.path = CGPath(ellipseIn: CGRect(
            x: -PlayerNode.playerRadius,
            y: -PlayerNode.playerRadius,
            width: PlayerNode.playerRadius * 2,
            height: PlayerNode.playerRadius * 2
        ), transform: nil)
        
        // Initial appearance
        updateAppearance()
        
        // Add child nodes
        addChild(labelNode)
        addChild(selectionRing)
        addChild(puckIndicator)
        
        // Physics setup (for future collision detection if needed)
        setupPhysics()
        
        // Enable user interaction
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupPhysics() {
        // Create physics body
        physicsBody = SKPhysicsBody(circleOfRadius: PlayerNode.playerRadius)
        physicsBody?.isDynamic = false  // Players don't move from physics
        physicsBody?.categoryBitMask = PhysicsCategory.player
        physicsBody?.contactTestBitMask = PhysicsCategory.puck
        physicsBody?.collisionBitMask = 0
    }
    
    private func updateAppearance() {
        fillColor = teamColor
        strokeColor = teamColor.darker(by: 0.2) ?? teamColor
        lineWidth = 1.5
        
        // Add shadow for depth
        glowWidth = 2.0
        
        // Update label contrast
        labelNode.fontColor = teamColor.isLight ? .black : .white
    }
    
    private func updatePuckIndicator() {
        // The puck indicator is just a small visual cue that this player has possession
        // The actual puck object should be visible next to the player
        if hasPuck {
            puckIndicator.run(SKAction.fadeIn(withDuration: 0.2))
        } else {
            puckIndicator.run(SKAction.fadeOut(withDuration: 0.2))
        }
    }
    
    // MARK: - Selection
    
    func setSelected(_ selected: Bool) {
        if selected {
            selectionRing.run(SKAction.fadeIn(withDuration: 0.2))
            
            // Subtle pulse animation
            let scaleUp = SKAction.scale(to: 1.1, duration: 0.3)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.3)
            let pulse = SKAction.sequence([scaleUp, scaleDown])
            selectionRing.run(SKAction.repeatForever(pulse))
        } else {
            selectionRing.removeAllActions()
            selectionRing.run(SKAction.fadeOut(withDuration: 0.2))
        }
    }
    
    // MARK: - Path Management
    
    func addPath(_ path: PathNode) {
        assignedPaths.append(path)
    }
    
    func clearPaths() {
        assignedPaths.removeAll()
        currentPathIndex = 0
    }
    
    var puckPosition: CGPoint {
        // Position where puck should be when held
        return CGPoint(x: position.x + PlayerNode.playerRadius + 8,
                      y: position.y + PlayerNode.playerRadius / 2)
    }
    
    func findPathEndpoint(near location: CGPoint) -> Int? {
        // Check if location is near any path endpoint
        for (index, path) in assignedPaths.enumerated() {
            if let endpoint = path.endPoint {
                let distance = hypot(location.x - endpoint.x, location.y - endpoint.y)
                if distance < 30 {  // Within 30 points
                    return index
                }
            }
        }
        return nil
    }
    
    // MARK: - Animation
    
    func animateAppearance() {
        // Store original position
        originalPosition = position
        
        // Appearance animation
        setScale(0.1)
        alpha = 0
        
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.3)
        scaleAction.timingMode = .easeOut
        
        let fadeAction = SKAction.fadeIn(withDuration: 0.3)
        
        let group = SKAction.group([scaleAction, fadeAction])
        run(group)
    }
    
    func animatePuckReceive() {
        // Visual feedback when receiving puck
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        
        run(sequence)
    }
    
    func runDrillAnimation(completion: @escaping () -> Void) {
        guard !assignedPaths.isEmpty else {
            completion()
            return
        }
        
        isAnimating = true
        animationCompletion = completion
        currentPathIndex = 0
        
        print("Starting drill animation for player: \(positionLabel) with \(assignedPaths.count) paths")
        
        // Start animating first path
        animateNextPath()
    }
    
    private func animateNextPath() {
        guard currentPathIndex < assignedPaths.count else {
            // All paths complete
            finishAnimation()
            return
        }
        
        let path = assignedPaths[currentPathIndex]
        print("Animating path \(currentPathIndex + 1) of \(assignedPaths.count) for player \(positionLabel), mode: \(path.mode)")
        
        // Check if this is a pass or shoot path
        switch path.mode {
        case .pass, .shoot:
            // Player stays in place, only release puck
            print("Player \(positionLabel) executing \(path.mode)")
            handlePathStart(path)
            
            // For pass, we need to wait for the puck animation to complete
            // before moving to the next path
            if path.mode == .pass {
                // Wait for a reasonable pass duration
                let pathLength = calculatePathLength(path.bezierPath ?? UIBezierPath())
                let passDuration = pathLength / 250.0 // Match PuckNode.passSpeed
                
                let waitAction = SKAction.wait(forDuration: passDuration + 0.5) // Extra time for completion
                run(waitAction) { [weak self] in
                    print("Pass animation should be complete, moving to next path")
                    self?.currentPathIndex += 1
                    self?.animateNextPath()
                }
            } else {
                // For shoot, just wait a moment for visual effect
                let waitAction = SKAction.wait(forDuration: 0.3)
                run(waitAction) { [weak self] in
                    self?.currentPathIndex += 1
                    self?.animateNextPath()
                }
            }
            return
            
        default:
            // For other movement types (forward, backward, withPuck), move the player
            break
        }
        
        // Create follow action for movement paths only
        guard let bezierPath = path.bezierPath else {
            print("No bezier path for path!")
            currentPathIndex += 1
            animateNextPath()
            return
        }
        
        // Calculate duration based on path length
        let pathLength = calculatePathLength(bezierPath)
        var duration = pathLength / 150.0  // Base speed
        
        // Adjust speed based on movement type
        switch path.mode {
        case .backward:
            duration *= 1.2  // Slower backward skating
        case .withPuck:
            duration *= 1.1  // Slightly slower with puck
        default:
            break
        }
        
        print("Moving player \(positionLabel) along path, duration: \(duration)")
        
        // Create follow action
        let followAction = SKAction.follow(
            bezierPath.cgPath,
            asOffset: false,
            orientToPath: false,
            duration: duration
        )
        
        followAction.timingMode = .easeInEaseOut
        
        // Handle path-specific logic
        handlePathStart(path)
        
        // Run animation
        let completionAction = SKAction.run { [weak self] in
            print("Movement complete for player \(self?.positionLabel ?? "")")
            self?.handlePathComplete(path)
            self?.currentPathIndex += 1
            self?.animateNextPath()
        }
        
        let sequence = SKAction.sequence([followAction, completionAction])
        run(sequence, withKey: "pathAnimation")
    }
    
    private func handlePathStart(_ path: PathNode) {
        // Handle mode-specific actions at path start
        switch path.mode {
        case .withPuck:
            // Player should have puck
            if !hasPuck {
                print("Player \(positionLabel) needs puck for 'with puck' movement")
                if let rinkScene = self.scene as? HockeyRinkScene {
                    rinkScene.transferPuckToPlayer(self)
                }
            }
        case .pass, .shoot:
            // Release puck at start - puck will animate independently
            if hasPuck {
                print("Player \(positionLabel) releasing puck for \(path.mode)")
                if let rinkScene = self.scene as? HockeyRinkScene {
                    rinkScene.releasePuckFromPlayer(self, along: path)
                }
            } else {
                print("WARNING: Player \(positionLabel) trying to \(path.mode) without puck!")
            }
        default:
            break
        }
    }
    
    private func handlePathComplete(_ path: PathNode) {
        // Handle mode-specific actions at path end
        print("Path complete for player \(positionLabel), mode: \(path.mode)")
    }
    
    func stopAnimation() {
        removeAllActions()
        isAnimating = false
        currentPathIndex = 0
    }
    
    func resetToOriginalPosition() {
        position = originalPosition
    }
    
    private func finishAnimation() {
        isAnimating = false
        animationCompletion?()
        animationCompletion = nil
    }
    
    // MARK: - Utilities
    
    private func calculatePathLength(_ path: UIBezierPath) -> CGFloat {
        var length: CGFloat = 0
        var previousPoint: CGPoint?
        
        path.cgPath.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                previousPoint = element.pointee.points[0]
            case .addLineToPoint:
                if let prev = previousPoint {
                    let current = element.pointee.points[0]
                    length += hypot(current.x - prev.x, current.y - prev.y)
                    previousPoint = current
                }
            case .addCurveToPoint:
                // Approximate curve length
                if let prev = previousPoint {
                    let cp1 = element.pointee.points[0]
                    let cp2 = element.pointee.points[1]
                    let end = element.pointee.points[2]
                    
                    // Simple approximation using control points
                    length += hypot(cp1.x - prev.x, cp1.y - prev.y)
                    length += hypot(cp2.x - cp1.x, cp2.y - cp1.y)
                    length += hypot(end.x - cp2.x, end.y - cp2.y)
                    
                    previousPoint = end
                }
            default:
                break
            }
        }
        
        return length
    }
}

// MARK: - Physics Categories

struct PhysicsCategory {
    static let player: UInt32 = 0x1 << 0
    static let puck: UInt32 = 0x1 << 1
    static let rink: UInt32 = 0x1 << 2
}

// MARK: - UIColor Extension

extension UIColor {
    var isLight: Bool {
        var brightness: CGFloat = 0
        getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)
        return brightness > 0.5
    }
    
    func darker(by percentage: CGFloat) -> UIColor? {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return UIColor(hue: hue,
                          saturation: saturation,
                          brightness: brightness * (1 - percentage),
                          alpha: alpha)
        }
        return nil
    }
}
