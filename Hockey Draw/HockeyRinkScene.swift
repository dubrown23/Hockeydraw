//
//  HockeyRinkScene.swift
//  Hockey Draw
//
//  Created by Assistant on 12/19/24.
//

import SpriteKit
import PencilKit

class HockeyRinkScene: SKScene {
    
    // MARK: - Properties
    
    // Rink background
    private var rinkSprite: SKSpriteNode!
    
    // Collections
    private(set) var playerNodes: [PlayerNode] = []
    private(set) var puckNode: PuckNode?
    private var pathNodes: [PathNode] = []
    
    // Public getter for path nodes
    var allPaths: [PathNode] {
        return pathNodes
    }
    
    // Drawing state
    private(set) var selectedPlayer: PlayerNode? {
        didSet {
            // Update visual selection
            playerNodes.forEach { $0.setSelected(false) }
            selectedPlayer?.setSelected(true)
        }
    }
    
    // Mode management
    enum Mode {
        case placement
        case drawing
    }
    
    private var currentMode: Mode = .placement
    
    // Drawing modes (matching your existing enum)
    enum DrawingMode: Int {
        case forward = 0
        case backward
        case withPuck
        case pass
        case shoot
        case erase
    }
    
    private var currentDrawingMode: DrawingMode = .forward
    
    // Player positions (matching your existing enum)
    enum PlayerPosition: String {
        case rightWing = "RW"
        case leftWing = "LW"
        case center = "C"
        case rightDefense = "RD"
        case leftDefense = "LD"
        case goalie = "G"
    }
    
    private var currentPlayerPosition: PlayerPosition = .center
    
    // Animation state
    private var isAnimating = false
    private var animationQueue: [PlayerNode] = []
    private var waitingPlayers: Set<PlayerNode> = []
    
    // Delegate for UI updates
    weak var sceneDelegate: HockeyRinkSceneDelegate?
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // Setup scene
        backgroundColor = .systemBackground
        scaleMode = .resizeFill
        
        // Setup rink
        setupRink()
        
        // Setup physics
        physicsWorld.gravity = .zero
        physicsWorld.speed = 1.0
        
        // Enable user interaction
        isUserInteractionEnabled = true
    }
    
    // MARK: - Setup
    
    private func setupRink() {
        // Create rink sprite from IceRinkView
        let rinkSize = CGSize(width: size.width - 60, height: size.height - 120)
        
        // Render IceRinkView to texture
        let rinkView = IceRinkView(frame: CGRect(origin: .zero, size: rinkSize))
        rinkView.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: rinkSize)
        let rinkImage = renderer.image { context in
            rinkView.layer.render(in: context.cgContext)
        }
        
        let texture = SKTexture(image: rinkImage)
        rinkSprite = SKSpriteNode(texture: texture)
        rinkSprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
        rinkSprite.zPosition = -1
        
        addChild(rinkSprite)
    }
    
    // MARK: - Public Methods
    
    func setMode(_ mode: Mode) {
        currentMode = mode
        
        // Update UI feedback
        switch mode {
        case .placement:
            selectedPlayer = nil
            sceneDelegate?.updateInstructions("Tap to place players • Double-tap player to give puck")
        case .drawing:
            sceneDelegate?.updateInstructions("Long press a player to select • Draw paths")
        }
    }
    
    func setDrawingMode(_ mode: DrawingMode) {
        currentDrawingMode = mode
    }
    
    func setPlayerPosition(_ position: PlayerPosition) {
        currentPlayerPosition = position
    }
    
    func clearAll() {
        // Stop animations
        stopAnimation()
        
        // Remove all nodes
        playerNodes.forEach { $0.removeFromParent() }
        playerNodes.removeAll()
        
        puckNode?.removeFromParent()
        puckNode = nil
        
        pathNodes.forEach { $0.removeFromParent() }
        pathNodes.removeAll()
        
        selectedPlayer = nil
    }
    
    func undoLastAction() -> Bool {
        // Stop any running animations first
        if isAnimating {
            stopAnimation()
        }
        
        // Try to remove the last path first
        if let lastPath = pathNodes.last {
            print("Undoing last path")
            
            // Remove from scene
            lastPath.removeFromParent()
            pathNodes.removeLast()
            
            // Find which player had this path and remove it
            for player in playerNodes {
                if player.paths.contains(where: { $0 === lastPath }) {
                    // Rebuild player's paths without the removed one
                    let remainingPaths = player.paths.filter { $0 !== lastPath }
                    player.clearPaths()
                    for path in remainingPaths {
                        player.addPath(path)
                    }
                    break
                }
            }
            
            return true
        }
        
        // If no paths, try to remove the last player
        if let lastPlayer = playerNodes.last {
            print("Undoing last player: \(lastPlayer.positionLabel)")
            
            // Remove any paths belonging to this player
            let pathsToRemove = pathNodes.filter { path in
                if let firstPoint = path.points.first {
                    let distance = hypot(lastPlayer.position.x - firstPoint.x,
                                       lastPlayer.position.y - firstPoint.y)
                    return distance < 50
                }
                return false
            }
            
            for path in pathsToRemove {
                path.removeFromParent()
                if let index = pathNodes.firstIndex(of: path) {
                    pathNodes.remove(at: index)
                }
            }
            
            // If this player had the puck, reset it
            if lastPlayer.hasPuck {
                lastPlayer.hasPuck = false
                if let puck = puckNode {
                    puck.holder = nil
                    puck.position = puck.originalPosition
                }
            }
            
            // Remove the player
            lastPlayer.removeFromParent()
            playerNodes.removeLast()
            
            // Update button states
            sceneDelegate?.updateButtonStates()
            
            return true
        }
        
        // Update button states even if nothing was undone
        sceneDelegate?.updateButtonStates()
        
        return false
    }
    
    private func findPlayerForPath(_ path: PathNode) -> PlayerNode? {
        // Find which player owns this path based on starting position
        guard let firstPoint = path.points.first else { return nil }
        
        let searchRadius: CGFloat = 50
        for player in playerNodes {
            let distance = hypot(player.position.x - firstPoint.x,
                               player.position.y - firstPoint.y)
            if distance < searchRadius {
                return player
            }
        }
        return nil
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        switch currentMode {
        case .placement:
            handlePlacementTouch(at: location)
        case .drawing:
            handleDrawingTouch(at: location)
        }
    }
    
    private func handlePlacementTouch(at location: CGPoint) {
        // Create new player at touch location
        let player = PlayerNode(position: currentPlayerPosition.rawValue, teamColor: .systemRed)
        player.position = location
        player.originalPosition = location
        
        addChild(player)
        playerNodes.append(player)
        
        // Notify delegate to update button states
        sceneDelegate?.updateButtonStates()
        
        // Create puck if needed
        if puckNode == nil {
            let puck = PuckNode()
            puck.position = CGPoint(x: size.width / 2, y: size.height / 2)
            puck.originalPosition = puck.position
            addChild(puck)
            puckNode = puck
        }
        
        // Animate appearance
        player.animateAppearance()
    }
    
    private func handleDrawingTouch(at location: CGPoint) {
        // Long press handled by gesture recognizer
        // This is for quick selection fallback
    }
    
    // MARK: - Path Creation
    
    func addPath(from points: [CGPoint], mode: DrawingMode, for player: PlayerNode?) {
        guard let player = player else { return }
        
        // Create path node
        let pathNode = PathNode(points: points, mode: mode)
        pathNode.zPosition = 1
        addChild(pathNode)
        pathNodes.append(pathNode)
        
        // Associate with player
        player.addPath(pathNode)
        
        // Update button states
        sceneDelegate?.updateButtonStates()
        
        // Handle puck logic
        switch mode {
        case .withPuck:
            // Give puck to player if they don't have it
            if let puck = puckNode, puck.holder != player {
                transferPuck(to: player)
            }
        case .pass, .shoot:
            // Will handle during animation
            break
        default:
            break
        }
    }
    
    // MARK: - Selection
    
    func selectPlayer(at location: CGPoint) -> Bool {
        // Find player at location
        let nodes = nodes(at: location)
        
        for node in nodes {
            if let player = node as? PlayerNode {
                selectedPlayer = player
                sceneDelegate?.updateInstructions("Draw path for \(player.positionLabel)")
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                return true
            }
        }
        
        // No player found
        selectedPlayer = nil
        return false
    }
    
    func assignPuck(at location: CGPoint) -> Bool {
        // Find player at location
        let nodes = nodes(at: location)
        
        for node in nodes {
            if let player = node as? PlayerNode {
                transferPuck(to: player)
                return true
            }
        }
        
        return false
    }
    
    private func transferPuck(to player: PlayerNode) {
        guard let puck = puckNode else { return }
        
        // Remove from current holder
        playerNodes.forEach { $0.hasPuck = false }
        
        // Give to new player
        player.hasPuck = true
        puck.holder = player
        
        // Animate puck to player
        let moveAction = SKAction.move(to: player.puckPosition, duration: 0.2)
        puck.run(moveAction)
        
        // Visual feedback
        player.animatePuckReceive()
        
        sceneDelegate?.updateInstructions("\(player.positionLabel) now has the puck")
    }
    
    // MARK: - Animation
    
    func startAnimation() {
        guard !isAnimating else { return }
        
        // Always reset positions first to ensure clean state
        resetPositions()
        
        isAnimating = true
        sceneDelegate?.updatePlayButton(isPlaying: true)
        
        print("Starting drill animation sequence")
        
        // Clear any previous animation state
        animationQueue.removeAll()
        waitingPlayers.removeAll()
        
        // Build animation dependency graph
        buildAnimationQueue()
        
        // Start the animation sequence
        processAnimationQueue()
    }
    
    private func buildAnimationQueue() {
        animationQueue.removeAll()
        waitingPlayers.removeAll()
        
        // First, find players who can start immediately (have puck or don't need it)
        var processedPlayers: Set<PlayerNode> = []
        
        // Start with the player who currently has the puck
        if let puckHolder = playerNodes.first(where: { $0.hasPuck }) {
            animationQueue.append(puckHolder)
            processedPlayers.insert(puckHolder)
            print("Starting with puck holder: \(puckHolder.positionLabel)")
        }
        
        // Now process other players based on dependencies
        for player in playerNodes {
            guard !processedPlayers.contains(player) else { continue }
            
            // Check if this player needs to wait for a pass
            let needsToWaitForPass = player.paths.contains { path in
                // If player has a "with puck" path but doesn't have puck, they need to wait
                return path.mode == .withPuck && !player.hasPuck
            }
            
            if !needsToWaitForPass {
                // This player can animate now or doesn't need the puck
                animationQueue.append(player)
                processedPlayers.insert(player)
                print("Added to queue: \(player.positionLabel) (no puck dependency)")
            } else {
                // This player needs to wait for a pass
                waitingPlayers.insert(player)
                print("Player \(player.positionLabel) waiting for puck")
            }
        }
    }
    
    private func processAnimationQueue() {
        guard !animationQueue.isEmpty else {
            // Check if there are waiting players that can now animate
            if !waitingPlayers.isEmpty {
                // Find any waiting player that now has the puck
                if let readyPlayer = waitingPlayers.first(where: { $0.hasPuck }) {
                    waitingPlayers.remove(readyPlayer)
                    animationQueue.append(readyPlayer)
                    print("Waiting player \(readyPlayer.positionLabel) now ready (has puck)")
                    processAnimationQueue()
                    return
                }
            }
            
            // No more animations to process
            checkAnimationComplete()
            return
        }
        
        let player = animationQueue.removeFirst()
        print("Processing animation for player: \(player.positionLabel)")
        
        player.runDrillAnimation { [weak self] in
            print("Player \(player.positionLabel) completed animation")
            
            // After this player completes, check if any waiting players can now go
            self?.checkWaitingPlayers()
            
            // Continue processing queue
            self?.processAnimationQueue()
        }
    }
    
    private func checkWaitingPlayers() {
        // Check if any waiting players now have the puck and can animate
        let readyPlayers = waitingPlayers.filter { $0.hasPuck }
        
        for player in readyPlayers {
            waitingPlayers.remove(player)
            animationQueue.insert(player, at: 0) // Add to front of queue for immediate processing
            print("Player \(player.positionLabel) no longer waiting (received puck)")
        }
    }
    
    func stopAnimation() {
        guard isAnimating else { return }
        
        isAnimating = false
        sceneDelegate?.updatePlayButton(isPlaying: false)
        
        // Stop all animations
        playerNodes.forEach { $0.stopAnimation() }
        puckNode?.stopAnimation()
        
        // Clear animation queue
        animationQueue.removeAll()
        waitingPlayers.removeAll()
        
        // Reset positions
        resetPositions()
    }
    
    func toggleAnimation() {
        if isAnimating {
            stopAnimation()
        } else {
            // Start fresh animation
            startAnimation()
        }
    }
    
    private func checkAnimationComplete() {
        let allComplete = playerNodes.allSatisfy { !$0.isAnimating }
        
        if allComplete && animationQueue.isEmpty && waitingPlayers.isEmpty {
            print("All animations complete")
            stopAnimation()
        }
    }
    
    private func resetPositions() {
        print("Resetting positions for all players and puck")
        
        // Reset players to original positions
        for player in playerNodes {
            player.resetToOriginalPosition()
        }
        
        // Reset puck to original position
        puckNode?.resetToOriginalPosition()
        
        // CRITICAL: Reset puck ownership to original state
        // Clear all hasPuck flags first
        for player in playerNodes {
            player.hasPuck = false
        }
        
        // Find who originally had the puck (before any animations)
        // This is typically the first player with a pass or shoot path, or with a "withPuck" path
        var originalPuckHolder: PlayerNode?
        
        for player in playerNodes {
            for path in player.paths {
                if path.mode == .pass || path.mode == .shoot || path.mode == .withPuck {
                    originalPuckHolder = player
                    break
                }
            }
            if originalPuckHolder != nil { break }
        }
        
        // Give puck back to original holder
        if let holder = originalPuckHolder, let puck = puckNode {
            print("Restoring puck to original holder: \(holder.positionLabel)")
            holder.hasPuck = true
            puck.holder = holder
            puck.position = holder.puckPosition
            puck.updatePosition()
        } else if let puck = puckNode {
            // No original holder - reset puck to center
            print("No original puck holder found, resetting to center")
            puck.holder = nil
            puck.position = puck.originalPosition
        }
    }
    
    // MARK: - Path Connection
    
    func findPathEndpoint(near location: CGPoint) -> (player: PlayerNode, pathIndex: Int)? {
        for player in playerNodes {
            if let endpoint = player.findPathEndpoint(near: location) {
                return (player, endpoint)
            }
        }
        return nil
    }
    
    // MARK: - Puck Transfer Notification
    
    func notifyPuckTransferred(to player: PlayerNode) {
        print("Puck transferred to \(player.positionLabel), checking waiting players")
        
        // Check if this player was waiting and hasn't started animating yet
        if waitingPlayers.contains(player) && !player.isAnimating {
            waitingPlayers.remove(player)
            // Add to front of queue for immediate processing
            animationQueue.insert(player, at: 0)
            print("Player \(player.positionLabel) moved from waiting to queue")
        }
    }
    
    // MARK: - Core Data Support
    
    func saveToCoreDrill(_ drill: Drill) {
        // Save current state to Core Data
        // This maintains compatibility with your existing data model
        
        for player in playerNodes {
            // Create DrillObject
            // Set position, team color, hasPuck, etc.
        }
        
        for path in pathNodes {
            // Create DrillPath
            // Store path data, mode, timing, etc.
        }
    }
    
    func loadFromCoreDrill(_ drill: Drill) {
        // Clear existing
        clearAll()
        
        // Load players and paths from Core Data
        // Recreate the drill setup
    }
}

// MARK: - Scene Delegate Protocol

protocol HockeyRinkSceneDelegate: AnyObject {
    func updateInstructions(_ text: String)
    func updatePlayButton(isPlaying: Bool)
    func drillAnimationComplete()
    func updateButtonStates()
}
