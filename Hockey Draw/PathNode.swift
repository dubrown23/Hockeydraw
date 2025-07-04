//
//  PathNode.swift
//  Hockey Draw
//
//  Created by Dustin Brown on 6/25/25.
//


//
//  PathNode.swift
//  Hockey Draw
//
//  Created by Assistant on 12/19/24.
//

import SpriteKit

class PathNode: SKNode {
    
    // MARK: - Properties
    
    // Path data
    let mode: HockeyRinkScene.DrawingMode
    let points: [CGPoint]
    private(set) var bezierPath: UIBezierPath?
    private(set) var endPoint: CGPoint?
    
    // Visual components
    private var pathShape: SKShapeNode?
    private var arrowNode: SKShapeNode?
    
    // For complex line styles
    private var styleNodes: [SKShapeNode] = []
    
    // Constants
    private static let lineWidth: CGFloat = 2.5
    private static let arrowSize: CGFloat = 16
    private static let dashPattern: [CGFloat] = [10, 5]
    
    // MARK: - Initialization
    
    init(points: [CGPoint], mode: HockeyRinkScene.DrawingMode) {
        self.points = points
        self.mode = mode
        
        super.init()
        
        // Create smooth path
        createBezierPath()
        
        // Render path based on mode
        renderPath()
        
        // Add arrow at end
        if mode != .erase {
            addArrow()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Path Creation
    
    private func createBezierPath() {
        guard points.count > 1 else { return }
        
        // Create smooth path using Catmull-Rom splines
        bezierPath = UIBezierPath()
        bezierPath?.move(to: points[0])
        
        if points.count == 2 {
            // Simple line
            bezierPath?.addLine(to: points[1])
        } else {
            // Smooth curve through points
            for i in 0..<points.count - 1 {
                let p0 = i > 0 ? points[i - 1] : points[0]
                let p1 = points[i]
                let p2 = points[i + 1]
                let p3 = i < points.count - 2 ? points[i + 2] : points[points.count - 1]
                
                // Catmull-Rom control points
                let cp1 = CGPoint(
                    x: p1.x + (p2.x - p0.x) / 6,
                    y: p1.y + (p2.y - p0.y) / 6
                )
                
                let cp2 = CGPoint(
                    x: p2.x - (p3.x - p1.x) / 6,
                    y: p2.y - (p3.y - p1.y) / 6
                )
                
                bezierPath?.addCurve(to: p2, controlPoint1: cp1, controlPoint2: cp2)
            }
        }
        
        endPoint = points.last
    }
    
    // MARK: - Rendering
    
    private func renderPath() {
        switch mode {
        case .forward:
            renderSolidLine()
        case .backward:
            renderBackwardSkating()
        case .withPuck:
            renderSkatingWithPuck()
        case .pass:
            renderPassLine()
        case .shoot:
            renderShootLine()
        case .erase:
            break
        }
    }
    
    private func renderSolidLine() {
        guard let path = bezierPath else { return }
        
        pathShape = SKShapeNode(path: path.cgPath)
        pathShape?.strokeColor = .black
        pathShape?.lineWidth = PathNode.lineWidth
        pathShape?.lineCap = .round
        pathShape?.lineJoin = .round
        
        if let shape = pathShape {
            addChild(shape)
        }
    }
    
    private func renderBackwardSkating() {
        guard let path = bezierPath else { return }
        
        // Calculate path length and C-shape positions
        let pathLength = calculatePathLength(path)
        let cSpacing: CGFloat = 20
        let numberOfCs = Int(pathLength / cSpacing)
        
        guard numberOfCs > 0 else {
            renderSolidLine()  // Fallback for very short paths
            return
        }
        
        // Create C-shapes along path
        for i in 0...numberOfCs {
            let progress = CGFloat(i) / CGFloat(numberOfCs)
            
            if let point = pointAlongPath(at: progress),
               let angle = angleAlongPath(at: progress) {
                
                // Create C-shape
                let cShape = createCShape()
                cShape.position = point
                cShape.zRotation = angle
                
                addChild(cShape)
                styleNodes.append(cShape)
            }
        }
    }
    
    private func renderSkatingWithPuck() {
        guard let path = bezierPath else { return }
        
        // Create zigzag pattern
        let zigzagPath = createZigzagPath(from: path)
        
        pathShape = SKShapeNode(path: zigzagPath.cgPath)
        pathShape?.strokeColor = .black
        pathShape?.lineWidth = PathNode.lineWidth
        pathShape?.lineCap = .round
        pathShape?.lineJoin = .round
        
        if let shape = pathShape {
            addChild(shape)
        }
    }
    
    private func renderPassLine() {
        guard let path = bezierPath else { return }
        
        // Create dashed line using multiple segments
        let segments = createDashedSegments(from: path)
        
        for segment in segments {
            let shape = SKShapeNode(path: segment.cgPath)
            shape.strokeColor = .black
            shape.lineWidth = PathNode.lineWidth
            shape.lineCap = .round
            
            addChild(shape)
            styleNodes.append(shape)
        }
    }
    
    private func renderShootLine() {
        guard let path = bezierPath else { return }
        
        // Create two parallel lines
        let offset: CGFloat = 4
        
        // Create offset paths
        if let upperPath = createOffsetPath(from: path, offset: offset),
           let lowerPath = createOffsetPath(from: path, offset: -offset) {
            
            // Upper line
            let upperShape = SKShapeNode(path: upperPath.cgPath)
            upperShape.strokeColor = .black
            upperShape.lineWidth = PathNode.lineWidth
            upperShape.lineCap = .round
            upperShape.lineJoin = .round
            
            // Lower line
            let lowerShape = SKShapeNode(path: lowerPath.cgPath)
            lowerShape.strokeColor = .black
            lowerShape.lineWidth = PathNode.lineWidth
            lowerShape.lineCap = .round
            lowerShape.lineJoin = .round
            
            addChild(upperShape)
            addChild(lowerShape)
            
            styleNodes.append(upperShape)
            styleNodes.append(lowerShape)
        }
    }
    
    // MARK: - Style Helpers
    
    private func createCShape() -> SKShapeNode {
        let path = UIBezierPath()
        let radius: CGFloat = 5
        
        // Create C shape (partial circle)
        path.addArc(withCenter: .zero,
                   radius: radius,
                   startAngle: .pi / 2,
                   endAngle: -.pi / 2,
                   clockwise: true)
        
        let shape = SKShapeNode(path: path.cgPath)
        shape.strokeColor = .black
        shape.lineWidth = 2
        shape.lineCap = .round
        shape.fillColor = .clear
        
        return shape
    }
    
    private func createZigzagPath(from originalPath: UIBezierPath) -> UIBezierPath {
        let zigzagPath = UIBezierPath()
        let wavelength: CGFloat = 12
        let amplitude: CGFloat = 4
        
        // Sample points along path
        var currentDistance: CGFloat = 0
        let step: CGFloat = 2  // Sample every 2 points
        
        var firstPoint = true
        var progress: CGFloat = 0
        
        while progress <= 1.0 {
            if let point = pointAlongPath(at: progress),
               let angle = angleAlongPath(at: progress) {
                
                // Calculate zigzag offset
                let phase = currentDistance / wavelength * .pi * 2
                let offset = sin(phase) * amplitude
                
                // Apply perpendicular offset
                let perpAngle = angle + .pi / 2
                let zigzagPoint = CGPoint(
                    x: point.x + cos(perpAngle) * offset,
                    y: point.y + sin(perpAngle) * offset
                )
                
                if firstPoint {
                    zigzagPath.move(to: zigzagPoint)
                    firstPoint = false
                } else {
                    zigzagPath.addLine(to: zigzagPoint)
                }
                
                currentDistance += step
            }
            
            progress += 0.01  // Fine sampling
        }
        
        return zigzagPath
    }
    
    private func createDashedSegments(from path: UIBezierPath) -> [UIBezierPath] {
        var segments: [UIBezierPath] = []
        
        let dashOn = PathNode.dashPattern[0]
        let dashOff = PathNode.dashPattern[1]
        let dashCycle = dashOn + dashOff
        
        var currentDistance: CGFloat = 0
        var isDrawing = true
        var currentSegment: UIBezierPath?
        
        // Sample along path
        let totalLength = calculatePathLength(path)
        let steps = Int(totalLength / 2)  // Sample every 2 points
        
        for i in 0...steps {
            let progress = CGFloat(i) / CGFloat(steps)
            
            if let point = pointAlongPath(at: progress) {
                let segmentDistance = currentDistance.truncatingRemainder(dividingBy: dashCycle)
                
                if segmentDistance < dashOn {
                    // Should be drawing
                    if !isDrawing {
                        // Start new segment
                        currentSegment = UIBezierPath()
                        currentSegment?.move(to: point)
                        isDrawing = true
                    } else {
                        currentSegment?.addLine(to: point)
                    }
                } else {
                    // Should be gap
                    if isDrawing {
                        // End current segment
                        if let segment = currentSegment {
                            segments.append(segment)
                        }
                        currentSegment = nil
                        isDrawing = false
                    }
                }
                
                currentDistance += 2  // Match step size
            }
        }
        
        // Add final segment if needed
        if let segment = currentSegment {
            segments.append(segment)
        }
        
        return segments
    }
    
    private func createOffsetPath(from path: UIBezierPath, offset: CGFloat) -> UIBezierPath? {
        let offsetPath = UIBezierPath()
        var firstPoint = true
        
        // Sample points and create offset
        let steps = 50  // Number of samples
        
        for i in 0...steps {
            let progress = CGFloat(i) / CGFloat(steps)
            
            if let point = pointAlongPath(at: progress),
               let angle = angleAlongPath(at: progress) {
                
                // Calculate perpendicular offset
                let perpAngle = angle + .pi / 2
                let offsetPoint = CGPoint(
                    x: point.x + cos(perpAngle) * offset,
                    y: point.y + sin(perpAngle) * offset
                )
                
                if firstPoint {
                    offsetPath.move(to: offsetPoint)
                    firstPoint = false
                } else {
                    offsetPath.addLine(to: offsetPoint)
                }
            }
        }
        
        return offsetPath
    }
    
    // MARK: - Arrow
    
    private func addArrow() {
        guard let path = bezierPath,
              let endPoint = pointAlongPath(at: 1.0),
              let angle = angleAlongPath(at: 0.95) else { return }  // Use 0.95 for better angle
        
        // Create arrow shape
        let arrowPath = UIBezierPath()
        
        // Arrow points
        let tip = CGPoint.zero  // Relative to arrow position
        let leftWing = CGPoint(
            x: -PathNode.arrowSize * cos(.pi / 6),
            y: PathNode.arrowSize * sin(.pi / 6)
        )
        let rightWing = CGPoint(
            x: -PathNode.arrowSize * cos(.pi / 6),
            y: -PathNode.arrowSize * sin(.pi / 6)
        )
        let back = CGPoint(x: -PathNode.arrowSize * 0.7, y: 0)
        
        // Draw filled arrow
        arrowPath.move(to: tip)
        arrowPath.addLine(to: leftWing)
        arrowPath.addLine(to: back)
        arrowPath.addLine(to: rightWing)
        arrowPath.close()
        
        arrowNode = SKShapeNode(path: arrowPath.cgPath)
        arrowNode?.fillColor = .black
        arrowNode?.strokeColor = .black
        arrowNode?.lineWidth = 1
        arrowNode?.position = endPoint
        arrowNode?.zRotation = angle
        
        if let arrow = arrowNode {
            addChild(arrow)
        }
    }
    
    // MARK: - Path Utilities
    
    private func pointAlongPath(at progress: CGFloat) -> CGPoint? {
        guard let path = bezierPath else { return nil }
        
        // This is a simplified version - for production, use proper path length calculations
        let pathElement = path.cgPath
        var length: CGFloat = 0
        var targetLength = calculatePathLength(path) * progress
        var previousPoint: CGPoint?
        var foundPoint: CGPoint?
        
        pathElement.applyWithBlock { element in
            guard foundPoint == nil else { return }
            
            switch element.pointee.type {
            case .moveToPoint:
                previousPoint = element.pointee.points[0]
                if progress == 0 {
                    foundPoint = previousPoint
                }
                
            case .addLineToPoint:
                if let start = previousPoint {
                    let end = element.pointee.points[0]
                    let segmentLength = hypot(end.x - start.x, end.y - start.y)
                    
                    if length + segmentLength >= targetLength {
                        let t = (targetLength - length) / segmentLength
                        foundPoint = CGPoint(
                            x: start.x + t * (end.x - start.x),
                            y: start.y + t * (end.y - start.y)
                        )
                    }
                    
                    length += segmentLength
                    previousPoint = end
                }
                
            case .addCurveToPoint:
                if let start = previousPoint {
                    // Approximate curve with line segments
                    let cp1 = element.pointee.points[0]
                    let cp2 = element.pointee.points[1]
                    let end = element.pointee.points[2]
                    
                    // Sample curve
                    for i in 1...10 {
                        let t = CGFloat(i) / 10.0
                        let point = bezierPoint(start: start, cp1: cp1, cp2: cp2, end: end, t: t)
                        let stepLength = hypot(point.x - previousPoint!.x, point.y - previousPoint!.y)
                        
                        if length + stepLength >= targetLength {
                            let localT = (targetLength - length) / stepLength
                            foundPoint = CGPoint(
                                x: previousPoint!.x + localT * (point.x - previousPoint!.x),
                                y: previousPoint!.y + localT * (point.y - previousPoint!.y)
                            )
                            break
                        }
                        
                        length += stepLength
                        previousPoint = point
                    }
                }
                
            default:
                break
            }
        }
        
        return foundPoint ?? endPoint
    }
    
    private func angleAlongPath(at progress: CGFloat) -> CGFloat? {
        // Get two points close to each other to determine angle
        let p1 = pointAlongPath(at: max(0, progress - 0.01))
        let p2 = pointAlongPath(at: min(1, progress + 0.01))
        
        guard let point1 = p1, let point2 = p2 else { return nil }
        
        return atan2(point2.y - point1.y, point2.x - point1.x)
    }
    
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
                if let prev = previousPoint {
                    // Approximate curve length
                    let cp1 = element.pointee.points[0]
                    let cp2 = element.pointee.points[1]
                    let end = element.pointee.points[2]
                    
                    for i in 1...10 {
                        let t = CGFloat(i) / 10.0
                        let point = bezierPoint(start: prev, cp1: cp1, cp2: cp2, end: end, t: t)
                        length += hypot(point.x - previousPoint!.x, point.y - previousPoint!.y)
                        previousPoint = point
                    }
                }
            default:
                break
            }
        }
        
        return length
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
    
    // MARK: - Connection Support
    
    func hideArrow() {
        arrowNode?.isHidden = true
    }
    
    func showArrow() {
        arrowNode?.isHidden = false
    }
}