//
//  PuckNode.swift
//  Hockey Draw
//
//  Created by Assistant on 12/19/24.
//

import SpriteKit

class PuckNode: SKShapeNode {
    
    // MARK: - Properties
    
    // Puck identification
    let id = UUID()
    
    // Ownership tracking
    weak var holder: PlayerNode? {
        didSet {
            if holder != nil {
                removeAllActions()  // Stop any independent movement
            }
        }
    }
    
    // Position tracking
    var originalPosition: CGPoint = .zero
    private(set) var isAnimating: Bool = false
    
    // Animation state
    private var currentPath: PathNode?
    private var animationCompletion: (() -> Void)?
    
    // Visual properties
    private let innerCircle: SKShapeNode
    private var trailEmitter: SKEmitterNode?
    
    // Constants
    private static let puckRadius: CGFloat = 5
    private static let innerRadius: CGFloat = 3
    
    // Physics constants
    private static let passSpeed: CGFloat = 250.0
    private static let shotSpeed: CGFloat = 400.0
    private static let friction: CGFloat = 0.1
    
    // MARK: - Initialization
    
    override init() {
        // Create inner circle for visual depth
        innerCircle = SKShapeNode(circleOfRadius: PuckNode.innerRadius)
        innerCircle.fillColor = .darkGray
        innerCircle.strokeColor = .clear
        
        // Initialize trail emitter to nil for now
        trailEmitter = nil
        
        super.init()
        
        // Setup puck appearance
        setupAppearance()
        
        // Add child nodes
        addChild(innerCircle)
        
        // Create trail emitter after init
        setupTrailEmitter()
        
        // Physics setup
        setupPhysics()
        
        // Set name for debugging
        self.name = "puck"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupTrailEmitter() {
        // Create simple trail emitter programmatically
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark")
        emitter.particleBirthRate = 50
        emitter.particleLifetime = 0.5
        emitter.particleScale = 0.1
        emitter.particleAlpha = 0.3
        emitter.particleColor = .white
        emitter.particleColorBlendFactor = 1.0
        emitter.particleAlphaSpeed = -1.0
        emitter.emissionAngle = .pi
        emitter.particleSpeed = 20
        emitter.particleSpeedRange = 10
        emitter.targetNode = self.parent
        emitter.particleAlpha = 0  // Start hidden
        
        trailEmitter = emitter
        
        if let emitter = trailEmitter {
            addChild(emitter)
        }
    }
    
    private func setupAppearance() {
        // Outer circle (black puck)
        self.path = CGPath(ellipseIn: CGRect(
            x: -PuckNode.puckRadius,
            y: -PuckNode.puckRadius,
            width: PuckNode.puckRadius * 2,
            height: PuckNode.puckRadius * 2
        ), transform: nil)
        
        fillColor = .black
        strokeColor = .white
        lineWidth = 0.5
        
        // Add subtle shadow for depth
        glowWidth = 1.0
        
        // Z-position to appear above ice but below players
        zPosition = 5
    }
    
    private func setupPhysics() {
        // Create physics body
        physicsBody = SKPhysicsBody(circleOfRadius: PuckNode.puckRadius)
        physicsBody?.isDynamic = true
        physicsBody?.categoryBitMask = PhysicsCategory.puck
        physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.rink
        physicsBody?.collisionBitMask = PhysicsCategory.rink
        
        // Puck physics properties
        physicsBody?.mass = 0.17  // ~6 ounces in kg
        physicsBody?.friction = PuckNode.friction
        physicsBody?.restitution = 0.5  // Some bounce
        physicsBody?.linearDamping = 0.3  // Gradual slowdown
        physicsBody?.angularDamping = 0.8  // Rotation slowdown
        
        // Start with physics disabled (will enable for shots)
        physicsBody?.isDynamic = false
    }
    
    // MARK: - Movement
    
    func updatePosition() {
        // Update position relative to holder
        guard let holder = holder else { return }
        
        // Position to the side of player
        let offset: CGFloat = 26  // PlayerRadius + spacing
        let angle = CGFloat.pi / 4  // 45 degrees
        
        let targetPosition = CGPoint(
            x: holder.position.x + cos(angle) * offset,
            y: holder.position.y + sin(angle) * offset
        )
        
        // Set position directly (no animation here)
        self.position = targetPosition
    }
    
    // MARK: - Animation
    
    func animateToPlayer(_ player: PlayerNode, duration: TimeInterval = 0.3) {
        holder = player
        
        let moveAction = SKAction.move(to: player.puckPosition, duration: duration)
        moveAction.timingMode = .easeOut
        
        run(moveAction) { [weak self] in
            self?.updatePosition()
        }
    }
    
    func animateShot(along path: PathNode, completion: (() -> Void)? = nil) {
        guard let bezierPath = path.bezierPath else {
            completion?()
            return
        }
        
        // Debug print
        print("Starting shot animation")
        
        isAnimating = true
        holder = nil
        currentPath = path
        animationCompletion = completion
        
        // Make sure puck is visible
        self.alpha = 1.0
        self.isHidden = false
        
        // Disable physics for controlled animation
        physicsBody?.isDynamic = false
        
        // Show trail effect
        showTrail(true)
        
        // Calculate shot duration (faster than player movement)
        let pathLength = calculatePathLength(bezierPath)
        let duration = pathLength / PuckNode.shotSpeed
        
        // Create shot action
        let followAction = SKAction.follow(
            bezierPath.cgPath,
            asOffset: false,
            orientToPath: false,
            duration: duration
        )
        
        followAction.timingMode = .easeIn  // Accelerate into shot
        
        // Add spin
        let spinAction = SKAction.rotate(byAngle: .pi * 4, duration: duration)
        
        // Combine actions
        let shotGroup = SKAction.group([followAction, spinAction])
        
        run(shotGroup) { [weak self] in
            print("Shot animation complete")
            self?.completeShot()
        }
    }
    
    func animatePass(along path: PathNode, from player: PlayerNode) {
        guard let bezierPath = path.bezierPath else {
            return
        }
        
        // Debug print
        print("Starting pass animation from player: \(player.positionLabel)")
        
        isAnimating = true
        holder = nil
        currentPath = path
        
        // Clear the player's puck indicator immediately
        player.hasPuck = false
        
        // Make sure puck is visible and at the right starting position
        self.alpha = 1.0
        self.isHidden = false
        self.position = player.position
        
        // Disable physics for controlled pass
        physicsBody?.isDynamic = false
        
        // Calculate pass duration
        let pathLength = calculatePathLength(bezierPath)
        let duration = pathLength / PuckNode.passSpeed
        
        print("Pass animation duration: \(duration)s for path length: \(pathLength)")
        
        // Create pass action
        let followAction = SKAction.follow(
            bezierPath.cgPath,
            asOffset: false,
            orientToPath: false,
            duration: duration
        )
        
        followAction.timingMode = .easeInEaseOut
        
        // Gentle spin
        let spinAction = SKAction.rotate(byAngle: .pi * 2, duration: duration)
        
        // Combine actions
        let passGroup = SKAction.group([followAction, spinAction])
        
        // Run the animation
        let completeAction = SKAction.run { [weak self] in
            print("Pass animation action completed")
            self?.completePass()
        }
        
        let sequence = SKAction.sequence([passGroup, completeAction])
        run(sequence, withKey: "passAnimation")
    }
    
    private func completeShot() {
        // Stop any running actions
        removeAllActions()
        
        // Hide trail
        showTrail(false)
        
        // Add impact effect at end point
        if let endPoint = currentPath?.endPoint {
            createImpactEffect(at: endPoint)
            // Make sure puck stays at endpoint
            self.position = endPoint
        }
        
        // Keep puck visible at endpoint
        self.alpha = 1.0
        self.isHidden = false
        
        finishAnimation()
    }
    
    private func completePass() {
        print("CompletePass called")
        
        // Stop any running actions
        removeAllActions()
        
        // Final check for receiving player
        if let scene = self.scene as? HockeyRinkScene,
           let endPoint = currentPath?.endPoint {
            
            print("Pass ended at: \(endPoint)")
            
            // Make sure puck is at endpoint first
            self.position = endPoint
            
            // Find the closest player to receive
            var closestPlayer: PlayerNode?
            var closestDistance: CGFloat = 60 // Increased search radius
            
            for player in scene.playerNodes {
                let distance = hypot(player.position.x - endPoint.x,
                                   player.position.y - endPoint.y)
                
                print("Player \(player.positionLabel) distance: \(distance)")
                
                if distance < closestDistance {
                    closestDistance = distance
                    closestPlayer = player
                }
            }
            
            if let receiver = closestPlayer {
                print("Found receiver: \(receiver.positionLabel)")
                
                // Transfer puck ownership
                receiver.hasPuck = true
                self.holder = receiver
                
                // Animate puck to player's holding position
                let moveAction = SKAction.move(to: receiver.puckPosition, duration: 0.2)
                run(moveAction) { [weak self] in
                    self?.updatePosition()
                }
                
                // Add visual feedback
                scene.addReceiveIndicator(to: receiver)
                
                // CRITICAL: Notify scene that this player received the puck
                // This allows them to continue their animation if they were waiting
                scene.notifyPuckTransferred(to: receiver)
            } else {
                print("No receiver found - puck stays at endpoint")
                self.position = endPoint
                self.alpha = 1.0
                self.isHidden = false
            }
        }
        
        finishAnimation()
    }
    
    func runDrillAnimation() {
        // Puck animation is triggered by players
        // This method exists for consistency with PlayerNode
    }
    
    func stopAnimation() {
        removeAllActions()
        isAnimating = false
        currentPath = nil
        
        // Hide effects
        showTrail(false)
        
        // Disable physics
        physicsBody?.isDynamic = false
        
        // Make sure puck stays visible
        self.alpha = 1.0
        self.isHidden = false
    }
    
    func resetToOriginalPosition() {
        position = originalPosition
        
        // Clear holder
        holder = nil
        
        // Reset physics
        physicsBody?.velocity = .zero
        physicsBody?.angularVelocity = 0
        physicsBody?.isDynamic = false
        
        // Make sure puck is visible
        self.alpha = 1.0
        self.isHidden = false
    }
    
    private func finishAnimation() {
        isAnimating = false
        currentPath = nil
        animationCompletion?()
        animationCompletion = nil
    }
    
    // MARK: - Visual Effects
    
    private func showTrail(_ show: Bool) {
        guard let emitter = trailEmitter else { return }
        
        if show {
            emitter.particleAlpha = 0.3
            emitter.resetSimulation()
        } else {
            emitter.particleAlpha = 0
        }
    }
    
    private func createImpactEffect(at point: CGPoint) {
        // Create a simple impact visual
        let impact = SKShapeNode(circleOfRadius: 15)
        impact.position = point
        impact.fillColor = .clear
        impact.strokeColor = .white
        impact.lineWidth = 2
        impact.alpha = 0.8
        
        parent?.addChild(impact)
        
        // Animate impact
        let scaleUp = SKAction.scale(to: 2.0, duration: 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let group = SKAction.group([scaleUp, fadeOut])
        
        impact.run(group) {
            impact.removeFromParent()
        }
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
                    
                    // Simple approximation
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

// MARK: - Scene Extensions

extension HockeyRinkScene {
    
    func transferPuckToPlayer(_ player: PlayerNode) {
        guard let puck = puckNode else { return }
        
        // Debug print
        print("Transferring puck to player: \(player.positionLabel)")
        
        // Clear previous holder
        playerNodes.forEach { $0.hasPuck = false }
        
        // Set new holder
        player.hasPuck = true
        puck.holder = player
        puck.animateToPlayer(player)
        
        // Visual feedback - pulsing ring
        addReceiveIndicator(to: player)
    }
    
    func releasePuckFromPlayer(_ player: PlayerNode, along path: PathNode) {
        guard let puck = puckNode, puck.holder == player else { return }
        
        // Debug print
        print("Releasing puck from player: \(player.positionLabel) with mode: \(path.mode)")
        
        // Release from player
        player.hasPuck = false
        puck.holder = nil
        
        // Animate based on path type
        switch path.mode {
        case .shoot:
            puck.animateShot(along: path)
        case .pass:
            puck.animatePass(along: path, from: player)
        default:
            break
        }
    }
    
    func addReceiveIndicator(to player: PlayerNode) {
        // Create pulsing ring effect
        let ring = SKShapeNode(circleOfRadius: 25)
        ring.position = player.position
        ring.strokeColor = .systemGreen
        ring.lineWidth = 3
        ring.fillColor = .clear
        ring.alpha = 0
        ring.zPosition = 10
        
        addChild(ring)
        
        // Animate
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let group = SKAction.sequence([fadeIn, SKAction.group([scaleUp, fadeOut])])
        
        ring.run(group) {
            ring.removeFromParent()
        }
    }
}
