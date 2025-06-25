//
//  PlayerToken.swift
//  Hockey Draw
//
//  Created by Dustin Brown on 6/12/25.
//

import UIKit

class PlayerToken: UIView {
    
    // Unique identifier for Equatable
    let id = UUID()
    
    // Token properties
    var positionLabel: String = "C" {
        didSet {
            positionTextLabel.text = positionLabel
        }
    }
    
    var teamColor: UIColor = .systemRed {
        didSet {
            backgroundColor = teamColor
        }
    }
    
    var hasPuck: Bool = false {
        didSet {
            puckIndicator.isHidden = !hasPuck
        }
    }
    
    // Stored position as percentage of rink dimensions
    var rinkPosition: CGPoint = .zero  // x and y as percentages (0.0 to 1.0)
    
    // UI elements
    private let positionTextLabel = UILabel()
    private let puckIndicator = UIView()
    
    // Gesture recognizers
    private var panGesture: UIPanGestureRecognizer!
    private var longPressGesture: UILongPressGestureRecognizer!
    private var doubleTapGesture: UITapGestureRecognizer!
    
    // Delegate for handling interactions
    weak var delegate: PlayerTokenDelegate?
    
    // Token size
    static let tokenDiameter: CGFloat = 26  // Middle of 24-28pt range
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupToken()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupToken()
    }
    
    convenience init(position: String, teamColor: UIColor = .systemRed) {
        self.init(frame: CGRect(x: 0, y: 0, width: PlayerToken.tokenDiameter, height: PlayerToken.tokenDiameter))
        self.positionLabel = position
        self.teamColor = teamColor
        positionTextLabel.text = position
        backgroundColor = teamColor
    }
    
    private func setupToken() {
        // Make it circular
        layer.cornerRadius = PlayerToken.tokenDiameter / 2
        clipsToBounds = true
        
        // Set initial size
        bounds = CGRect(x: 0, y: 0, width: PlayerToken.tokenDiameter, height: PlayerToken.tokenDiameter)
        
        // Setup position label
        positionTextLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        positionTextLabel.textColor = .white
        positionTextLabel.textAlignment = .center
        positionTextLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(positionTextLabel)
        
        // Setup puck indicator (small black dot at top)
        puckIndicator.backgroundColor = .black
        puckIndicator.layer.cornerRadius = 3
        puckIndicator.isHidden = true
        puckIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(puckIndicator)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Center the position label
            positionTextLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            positionTextLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // Puck indicator at top
            puckIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            puckIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            puckIndicator.widthAnchor.constraint(equalToConstant: 6),
            puckIndicator.heightAnchor.constraint(equalToConstant: 6)
        ])
        
        // Add gestures
        setupGestures()
        
        // Add shadow for better visibility on white ice
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 2
    }
    
    private func setupGestures() {
        // Pan gesture for dragging
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        // Long press for deletion
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        addGestureRecognizer(longPressGesture)
        
        // Double tap to toggle team color
        doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        
        let translation = gesture.translation(in: superview)
        
        switch gesture.state {
        case .changed:
            // Update position
            center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
            gesture.setTranslation(.zero, in: superview)
            
            // Update stored rink position as percentage
            updateRinkPosition()
            
            // Notify delegate
            delegate?.playerTokenDidMove(self)
            
        case .ended:
            // Ensure token stays within bounds
            constrainToBounds()
            updateRinkPosition()
            delegate?.playerTokenDidEndMoving(self)
            
        default:
            break
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            // Animate deletion
            UIView.animate(withDuration: 0.2, animations: {
                self.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.alpha = 0.5
            }) { _ in
                self.delegate?.playerTokenRequestsDelete(self)
                self.removeFromSuperview()
            }
        }
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        // Toggle between red and blue team colors
        if teamColor == .systemRed {
            teamColor = .systemBlue
        } else {
            teamColor = .systemRed
        }
        
        // Animate the color change
        UIView.animate(withDuration: 0.2) {
            self.backgroundColor = self.teamColor
        }
        
        delegate?.playerTokenDidChangeTeam(self)
    }
    
    private func constrainToBounds() {
        guard let superview = superview else { return }
        
        let halfWidth = bounds.width / 2
        let halfHeight = bounds.height / 2
        
        // Keep token fully within superview bounds
        center.x = max(halfWidth, min(superview.bounds.width - halfWidth, center.x))
        center.y = max(halfHeight, min(superview.bounds.height - halfHeight, center.y))
    }
    
    private func updateRinkPosition() {
        guard let superview = superview else { return }
        
        // Store position as percentage of superview dimensions
        rinkPosition = CGPoint(
            x: center.x / superview.bounds.width,
            y: center.y / superview.bounds.height
        )
    }
    
    // Update token position from stored percentage
    func updatePositionFromPercentage(in containerBounds: CGRect) {
        center = CGPoint(
            x: rinkPosition.x * containerBounds.width,
            y: rinkPosition.y * containerBounds.height
        )
    }
}

// MARK: - Equatable
extension PlayerToken {
    static func == (lhs: PlayerToken, rhs: PlayerToken) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Delegate Protocol
protocol PlayerTokenDelegate: AnyObject {
    func playerTokenDidMove(_ token: PlayerToken)
    func playerTokenDidEndMoving(_ token: PlayerToken)
    func playerTokenDidChangeTeam(_ token: PlayerToken)
    func playerTokenRequestsDelete(_ token: PlayerToken)
}
