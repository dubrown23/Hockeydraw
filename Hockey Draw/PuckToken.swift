//
//  PuckToken.swift
//  Hockey Draw
//
//  Created by Dustin Brown on 6/12/25.
//

import UIKit

class PuckToken: UIView {
    
    // Unique identifier
    let id = UUID()
    
    // Puck properties
    var currentHolder: PlayerToken? {
        didSet {
            updatePosition()
        }
    }
    
    // Stored position as percentage of rink dimensions
    var rinkPosition: CGPoint = .zero
    
    // Puck size
    static let puckDiameter: CGFloat = 10
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPuck()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPuck()
    }
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: PuckToken.puckDiameter, height: PuckToken.puckDiameter))
    }
    
    private func setupPuck() {
        // Make it circular
        layer.cornerRadius = PuckToken.puckDiameter / 2
        clipsToBounds = true
        backgroundColor = .black
        
        // Set size
        bounds = CGRect(x: 0, y: 0, width: PuckToken.puckDiameter, height: PuckToken.puckDiameter)
        
        // No user interaction - puck follows players or paths
        isUserInteractionEnabled = false
        
        // Add border for visibility
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.white.cgColor
    }
    
    // Update puck position relative to holder
    func updatePosition() {
        guard let holder = currentHolder else { return }
        
        // Position puck to the right of the player token
        let offset: CGFloat = PlayerToken.tokenDiameter / 2 + 8
        let angle = CGFloat.pi / 4  // 45 degrees to the right
        
        let offsetX = cos(angle) * offset
        let offsetY = sin(angle) * offset
        
        center = CGPoint(
            x: holder.center.x + offsetX,
            y: holder.center.y + offsetY
        )
    }
    
    // Animate puck to a position (for passes/shots)
    func animateTo(position: CGPoint, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            self.center = position
        }) { _ in
            completion?()
        }
    }
    
    // Update position from stored percentage
    func updatePositionFromPercentage(in containerBounds: CGRect) {
        if currentHolder == nil {
            // Only update if not being held
            center = CGPoint(
                x: rinkPosition.x * containerBounds.width,
                y: rinkPosition.y * containerBounds.height
            )
        }
    }
}

// MARK: - Equatable
extension PuckToken {
    static func == (lhs: PuckToken, rhs: PuckToken) -> Bool {
        return lhs.id == rhs.id
    }
}
