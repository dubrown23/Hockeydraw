//
//  IceRinkView.swift
//  Hockey Draw
//
//  Created by Dustin Brown on 6/25/25.
//


//
//  IceRinkView.swift
//  Hockey Draw
//
//  Created by Assistant on 12/19/24.
//

import UIKit

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