//
//  DiagramView.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/19/16.
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Cocoa

protocol DiagramViewDelegate: class {
    var inputPoint: PointVector { get }

    func diagramView(_: DiagramView, didUpdateBeginPoint: PointVector)
    func diagramView(_: DiagramView, didUpdateDraggedPoint: PointVector)
    func diagramView(_: DiagramView, didUpdateEndPoint: PointVector)
}

class DiagramView: NSView {
    weak var delegate: DiagramViewDelegate!

    var paperWidth:        Double!
    var paperHeight:       Double!
    var paperBottomLeft:   CGPoint!

    var paperBoundsLayer   = CALayer()
    var linesLayer         = CALayer()
    var lineLabelsLayer    = CALayer()
    var pointsLayer        = CALayer()
    var pointLabelsLayer   = CALayer()
    var arrowsLayer        = CALayer()
    var selectedPointLayer = CAShapeLayer()

    // Map each hit target to the original line
    var linesHitTargets = [(CGPath, (PointVector, PointVector))]()

    var linesUnderCursorLayer = CALayer()
    var candidatePointLayer   = CAShapeLayer()
    var candidatePoint: PointVector?

    var pointRadius: Double = 0
    var dashLength:  Double = 0
    var spaceLength: Double = 0
    var minLabelRadiusSquared: CGFloat = 0

    var diagram = Diagram()

    var minPaperDimension: Double! {
        didSet {
            updateConstants()
        }
    }

    var scale: Double = 1 {
        didSet {
            updateConstants()
        }
    }

    // Positions to try to put a label along a line
    // Used in drawLabel
    let labelPositions: [CGFloat] = [
        0.5, 0.375, 0.625, 0.25, 0.75, 0.125, 0.875, 0, 0.125,
    ]

    let fontSize: CGFloat = 14

    func updateConstants() {
        pointRadius = scale*minPaperDimension/150
        dashLength  = scale*minPaperDimension/50
        spaceLength = scale*minPaperDimension/75
        minLabelRadiusSquared = CGFloat(pow((scale*minPaperDimension/5), 2))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }

    func setUpView() {
        let newFrame = CGRect(x: frame.origin.x,
                              y: frame.origin.y,
                          width: 500,
                         height: frame.height)
        self.frame = newFrame
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(DiagramView.updatePaddingAndDrawAll(_:)),
            name: NSView.frameDidChangeNotification,
            object: nil
        )
        postsFrameChangedNotifications = true
        minPaperDimension = Double(min(main.paper.height, main.paper.width))

        // Configure layers
        layer = CALayer()
        layer!.addSublayer(paperBoundsLayer)
        layer!.addSublayer(linesLayer)
        layer!.addSublayer(pointsLayer)
        layer!.addSublayer(lineLabelsLayer)
        layer!.addSublayer(pointLabelsLayer)
        layer!.addSublayer(arrowsLayer)
        layer!.addSublayer(selectedPointLayer)
        layer!.addSublayer(linesUnderCursorLayer)
        layer!.addSublayer(candidatePointLayer)
        paperBoundsLayer.actions = [
            "position": NSNull(),
            "bounds": NSNull(),
        ]
        let sublayersNullAction  = ["sublayers": NSNull()]
        linesLayer.actions       = sublayersNullAction
        lineLabelsLayer.actions  = sublayersNullAction
        pointsLayer.actions      = sublayersNullAction
        pointLabelsLayer.actions = sublayersNullAction
        arrowsLayer.actions      = sublayersNullAction
        linesUnderCursorLayer.actions = sublayersNullAction
        candidatePointLayer.actions   = sublayersNullAction
        wantsLayer = true
    }

    func drawAll() {
        drawPaperBounds()
        arrowsLayer.sublayers?.removeAll()
        drawArrows()

        // Points are drawn before lines because point label positions are
        // static, while line label positions can change
        pointsLayer.sublayers?.removeAll()
        pointLabelsLayer.sublayers?.removeAll()
        drawSelectedPoint()
        for point in diagram.points {
            draw(point: point)
        }
        linesLayer.sublayers?.removeAll()
        lineLabelsLayer.sublayers?.removeAll()
        for crease in diagram.creases {
            draw(line: crease, type: .crease)
        }
        for line in diagram.lines {
            draw(line: line, type: .line)
        }
        if let fold = diagram.fold {
            draw(line: fold, type: .fold)
        }
        linesHitTargets.removeAll(keepingCapacity: true)
        for (p1, p2) in diagram.lineSegments {
            draw(from: p1, to: p2)
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        // Configure mouse tracking area
        for trackingArea in trackingAreas {
            removeTrackingArea(trackingArea)
        }
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }

    @objc func updatePaddingAndDrawAll(_ note: Notification) {
        let height = main.paper.height
        let width = main.paper.width
        let boundsHeight = Double(bounds.height)
        let boundsWidth  = Double(bounds.width)
        let c = 2 - sqrt(3)

        if boundsHeight*(width + c*height) < boundsWidth*(height + c*width) {
            let heightScalingFactor = c/(2*(height/width + c))
            let heightPadding = boundsHeight*heightScalingFactor
            paperHeight = boundsHeight - 2*heightPadding
            paperWidth  = (width/height)*paperHeight
            paperBottomLeft = CGPoint(
                x: (boundsWidth - paperWidth)/2,
                y: heightPadding
            )
        }
        else {
            let widthScalingFactor  = c/(2*(width/height + c))
            let widthPadding = boundsWidth*widthScalingFactor
            paperWidth  = boundsWidth - 2*widthPadding
            paperHeight = (height/width)*paperWidth
            paperBottomLeft = CGPoint(
                x: widthPadding,
                y: (boundsHeight - paperHeight)/2
            )
        }

        scale = paperHeight/height

        drawAll()
    }

    func drawPaperBounds() {
        diagram.bounds = CGRect(x: Double(paperBottomLeft.x),
                                y: Double(paperBottomLeft.y),
                            width: paperWidth,
                           height: paperHeight)
        paperBoundsLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        paperBoundsLayer.bounds = CGRect(x: 0,
                                         y: 0,
                                     width: paperWidth,
                                    height: paperHeight)
        paperBoundsLayer.backgroundColor = CGColor.white
    }

    func drawArrows() {
        for arrow in diagram.arrows {
            let arrowLayer = CAShapeLayer()
            arrowsLayer.addSublayer(arrowLayer)

            let stemLayer = CAShapeLayer()
            let stem = CGMutablePath()
            stem.move(to: viewPoint(from: arrow.beginPoint))
            stem.addArc(tangent1End: viewPoint(from: arrow.controlPoint),
                        tangent2End: viewPoint(from: arrow.endPoint),
                             radius: CGFloat(scale*arrow.arcRadius))
            stemLayer.path = stem
            stemLayer.fillColor = nil
            stemLayer.strokeColor = CGColor.black

            let arrowheadLayer = CAShapeLayer()
            let arrowheadPoints = arrow.arrowheadPoints()
            let arrowhead = CGMutablePath()
            arrowhead.move(to: viewPoint(from: arrowheadPoints[0]))
            arrowhead.addLine(to: viewPoint(from: arrowheadPoints[1]))
            arrowhead.addLine(to: viewPoint(from: arrowheadPoints[2]))
            arrowhead.closeSubpath()
            arrowheadLayer.path = arrowhead
            arrowheadLayer.fillColor = CGColor.black

            let arrowtailLayer = CAShapeLayer()
            let arrowtailPoints = arrow.arrowtailPoints()
            let arrowtail = CGMutablePath()
            arrowtail.move(to: viewPoint(from: arrowtailPoints[0]))
            arrowtail.addLine(to: viewPoint(from: arrowtailPoints[1]))
            arrowtail.addLine(to: viewPoint(from: arrowtailPoints[2]))
            arrowtail.closeSubpath()
            arrowtailLayer.path = arrowtail
            arrowtailLayer.fillColor = CGColor.white
            arrowtailLayer.strokeColor = CGColor.black

            arrowLayer.addSublayer(stemLayer)
            arrowLayer.addSublayer(arrowheadLayer)
            arrowLayer.addSublayer(arrowtailLayer)
        }
    }

    func drawSelection(
      point: PointVector, in layer: CAShapeLayer, color: CGColor) {
        let point = viewPoint(from: point)
        let origin = CGPoint(
            x: CGFloat(point.x) - CGFloat(pointRadius),
            y: CGFloat(point.y) - CGFloat(pointRadius)
        )
        let dot = CGMutablePath()
        dot.addEllipse(in: CGRect(
            origin: origin,
            size: CGSize(width: 2*pointRadius, height: 2*pointRadius)
        ))
        layer.path        = dot
        layer.bounds      = bounds
        layer.position    = CGPoint(x: bounds.midX, y: bounds.midY)
        layer.lineWidth   = CGFloat(pointRadius)/2
        layer.fillColor   = nil
        layer.strokeColor = color
    }

    func drawSelectedPoint() {
        drawSelection(point: delegate.inputPoint,
                         in: selectedPointLayer,
                      color: NSColor.blue.cgColor)
    }

    func viewPoint(from point: PointVector) -> CGPoint {
        return CGPoint(x: paperBottomLeft.x + CGFloat(scale*point.x),
                       y: paperBottomLeft.y + CGFloat(scale*point.y))
    }

    func paperPoint(from point: CGPoint) -> PointVector {
        return PointVector(Double(point.x - paperBottomLeft.x)/scale,
                           Double(point.y - paperBottomLeft.y)/scale)
    }

    enum LineType {
        case fold, crease, line
    }

    func draw(point pointReference: PointReference) {
        let point = viewPoint(from: pointReference.point)
        let origin = CGPoint(
            x: point.x - CGFloat(pointRadius),
            y: point.y - CGFloat(pointRadius)
        )
        let dot = CGMutablePath()
        dot.addEllipse(in: CGRect(
            origin: origin,
            size: CGSize(width: 2*pointRadius, height: 2*pointRadius)
        ))
        let pointLayer = CAShapeLayer()
        pointsLayer.addSublayer(pointLayer)
        pointLayer.path = dot
        pointLayer.bounds = bounds
        pointLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        pointLayer.lineWidth = CGFloat(pointRadius)/2
        pointLayer.fillColor = nil
        pointLayer.strokeColor = NSColor.red.cgColor

        // Don't label paper corners
        if pointReference.isNotCorner() {
            let pointLabelLayer = CATextLayer()
            pointLabelsLayer.addSublayer(pointLabelLayer)
            pointLabelLayer.contentsScale =
                NSScreen.main!.backingScaleFactor
            pointLabelLayer.foregroundColor = NSColor.red.cgColor
            pointLabelLayer.fontSize = fontSize
            pointLabelLayer.string = pointReference.label
            let size = pointReference.label.size(withAttributes: [
                .font: NSFont.labelFont(ofSize: fontSize),
            ])
            pointLabelLayer.bounds = CGRect(origin: CGPoint.zero,
                                              size: size)
            var offsetVector = angleDivider(pointReference.firstLine.line,
                                            pointReference.secondLine.line)

            // Reverse offset direction if the label will overlap with an arrow
            for arrow in diagram.arrows {
                let arrowPoints: [PointVector]
                if arrow.beginPoint == pointReference.point {
                    arrowPoints = arrow.arrowheadPoints()
                }
                else if arrow.endPoint == pointReference.point {
                    arrowPoints = arrow.arrowtailPoints()
                }
                else {
                    break
                }
                let arrowDirection =
                    arrowPoints[2] - (arrowPoints[0] + arrowPoints[1])/2
                if offsetVector.dot(arrowDirection) < 0 {
                    offsetVector = offsetVector*(-1)
                    break
                }
            }
            pointLabelLayer.position = CGPoint(
                x: point.x + size.width*CGFloat(offsetVector.x),
                y: point.y + size.height*CGFloat(offsetVector.y)
            )
        }
    }

    // Return the line that divides the largest angle between `line1` and
    // `line2` in half. This is a variation of the axiom3 function
    func angleDivider(_ line1: Line, _ line2: Line) -> PointVector {
        let divider1 = (line1.unitNormal + line2.unitNormal).normalized()
        let divider2 = divider1.rotatedBy90()
        if abs(divider1.dot(line1.unitNormal))
         > abs(divider2.dot(line1.unitNormal)) {
            return divider1
        }
        return divider2
    }

    func draw(line lineReference: LineReference, type: LineType = .crease) {
        if let (p1, p2) = main.paper.clip(line: lineReference.line) {
            let line = CGMutablePath()
            line.move(to: viewPoint(from: p1))
            line.addLine(to: viewPoint(from: p2))
            let lineLayer = CAShapeLayer()
            linesLayer.addSublayer(lineLayer)
            lineLayer.path = line
            lineLayer.bounds = bounds
            lineLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
            switch type {
            case .fold:
                // Dashed black line
                lineLayer.lineDashPattern = [
                    NSNumber(value: dashLength),
                    NSNumber(value: spaceLength)
                ]
                lineLayer.strokeColor = CGColor.black
                drawLabel(forLine: lineReference, point1: p1, point2: p2)
            case .crease:
                // Solid gray line
                lineLayer.strokeColor = NSColor.lightGray.cgColor
            case .line:
                // Solid black line
                lineLayer.strokeColor = CGColor.black
                if lineReference.isNotEdge() {
                    drawLabel(forLine: lineReference, point1: p1, point2: p2)
                }
            }
        }
    }

    func draw(from p1: PointVector, to p2: PointVector) {
        let line = CGMutablePath()
        line.move(to: viewPoint(from: p1))
        line.addLine(to: viewPoint(from: p2))
        let lineLayer = CAShapeLayer()
        linesLayer.addSublayer(lineLayer)
        lineLayer.path = line
        lineLayer.bounds = bounds
        lineLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)

        // Create hit targets
        linesHitTargets.append((line.hitTarget, (p1, p2)))

        // Draw solid black line
        lineLayer.strokeColor = CGColor.black
    }

    func drawLabel(forLine lineReference: LineReference,
                                  point1: PointVector,
                                  point2: PointVector) {
        let lineLabelLayer = CATextLayer()
        lineLabelsLayer.addSublayer(lineLabelLayer)
        lineLabelLayer.contentsScale = NSScreen.main!.backingScaleFactor
        lineLabelLayer.foregroundColor = CGColor.black
        lineLabelLayer.fontSize = fontSize
        lineLabelLayer.string = lineReference.label
        let size = lineReference.label.size(withAttributes: [
            .font: NSFont.labelFont(ofSize: fontSize),
        ])
        lineLabelLayer.bounds = CGRect(origin: CGPoint.zero, size: size)

        // Calculate first position to try to place the label
        let offsetVector = lineReference.line.unitNormal
        let point1 = viewPoint(from: point1)
        let point2 = viewPoint(from: point2)
        let edgePoint1 = CGPoint(
            x: point1.x + size.width*CGFloat(offsetVector.x)/1.5,
            y: point1.y + size.height*CGFloat(offsetVector.y)/1.5
        )
        let edgePoint2 = CGPoint(
            x: point2.x + size.width*CGFloat(offsetVector.x)/1.5,
            y: point2.y + size.height*CGFloat(offsetVector.y)/1.5
        )
        var distances = [CGFloat]()
        var i = 0
        while i < labelPositions.count {
            lineLabelLayer.position = CGPoint.getPoint(ratio: labelPositions[i],
                                                      point1: edgePoint1,
                                                      point2: edgePoint2)
            let distance = shouldMove(labelLayer: lineLabelLayer)
            if distance <= 0 {
                break
            }
            distances.append(distance)
            i += 1
        }
        // None of the canditate positions are far enough
        // Choose one with the least distance
        if i == labelPositions.count - 1 {
            lineLabelLayer.position = CGPoint.getPoint(
                ratio: labelPositions[distances.minIndex()!],
                point1: edgePoint1,
                point2: edgePoint2
            )
        }
    }

    // Check whether the placement is too close to other labels
    // If the placement is good, return -1
    // Else return the total distance from all other labels
    func shouldMove(labelLayer lineLabelLayer: CATextLayer) -> CGFloat {
        let placement = lineLabelLayer.position
        var totalSquaredRadius: CGFloat = 0
        var shouldMove = false
        func computeDistances(inLayers labelsLayer: CALayer) {
            if labelsLayer.sublayers == nil {
                return
            }
            for labelLayer in labelsLayer.sublayers! {
                if lineLabelLayer === labelLayer {
                    continue
                }
                let labelCenter = labelLayer.position
                let squaredRadius = pow((placement.x - labelCenter.x), 2)
                                  + pow((placement.y - labelCenter.y), 2)
                if squaredRadius < minLabelRadiusSquared {
                    shouldMove = true
                }
                totalSquaredRadius += squaredRadius
            }
        }
        computeDistances(inLayers: lineLabelsLayer)
        computeDistances(inLayers: pointLabelsLayer)
        if !shouldMove {
            return -1
        }
        return totalSquaredRadius
    }

    func convert(viewPoint: inout CGPoint) {
        if viewPoint.x < diagram.bounds.minX {
            viewPoint.x = diagram.bounds.minX
        }
        else if viewPoint.x > diagram.bounds.maxX {
            viewPoint.x = diagram.bounds.maxX
        }
        if viewPoint.y < diagram.bounds.minY {
            viewPoint.y = diagram.bounds.minY
        }
        else if viewPoint.y > diagram.bounds.maxY {
            viewPoint.y = diagram.bounds.maxY
        }
    }

    // Mark: - Specify point or line on the paper

    override func mouseDown(with event: NSEvent) {
        var selectedPoint: PointVector
        if let candidatePoint = candidatePoint {
            selectedPoint = candidatePoint
        }
        else {
            var viewPoint = convert(event.locationInWindow, from: nil)
            convert(viewPoint: &viewPoint)
            selectedPoint = paperPoint(from: viewPoint)
        }
        delegate.diagramView(self, didUpdateBeginPoint: selectedPoint);
        drawSelectedPoint()
    }

    override func mouseDragged(with event: NSEvent) {
        var viewPoint = convert(event.locationInWindow, from: nil)
        convert(viewPoint: &viewPoint)
        let selectedPoint = PointVector(
            Double(viewPoint.x - paperBottomLeft.x)/scale,
            Double(viewPoint.y - paperBottomLeft.y)/scale
        )
        delegate.diagramView(self, didUpdateDraggedPoint: selectedPoint)
        drawSelectedPoint()
    }

    // Mark: - Select a line

    override func mouseMoved(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)
        candidatePoint = nil
        linesUnderCursorLayer.sublayers = []
        candidatePointLayer.path = CGMutablePath()

        var targets = [CGPath]()
        var lines   = [(PointVector, PointVector)]()
        for (target, line) in linesHitTargets {
            if target.contains(viewPoint, using: .evenOdd) {
                targets.append(target)
                lines.append(line)
            }
        }

        // Highlight the lines under the cursor
        for target in targets {
            let lineUnderCursorLayer = CAShapeLayer()
            lineUnderCursorLayer.path = target
            lineUnderCursorLayer.fillColor = NSColor.red.cgColor
            lineUnderCursorLayer.bounds = bounds
            lineUnderCursorLayer.position = CGPoint(x: bounds.midX,
                                                    y: bounds.midY)
            linesUnderCursorLayer.addSublayer(lineUnderCursorLayer)
        }

        // Find an intersection point among the lines under the cursor
        for i in 0..<targets.count {
            for j in (i + 1)..<targets.count {
                let (a1, a2) = lines[i]
                let (b1, b2) = lines[j]
                let lineA = Line(a1, a2)
                let lineB = Line(b1, b2)
                if let intersection = intersection(lineA, lineB),
                   lineA.contains(point: intersection) {
                    drawSelection(point: intersection,
                                     in: candidatePointLayer,
                                  color: NSColor.green.cgColor)
                    candidatePoint = intersection
                    return
                }
            }
        }
    }
}
