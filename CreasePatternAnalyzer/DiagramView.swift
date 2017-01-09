//
//  DiagramView.swift
//  CreasePatternAnalyzer
//
//  Created by Kijjakarn Praditukrit on 11/19/16.
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Cocoa

protocol DiagramViewDelegate: class {
    func update(beginPoint: PointVector)
    func update(draggedPoint: PointVector)
    func update(endPoint: PointVector)
}

class DiagramView: NSView {
    weak var delegate: DiagramViewDelegate!

    var scale:             Double!
    var padding:           Double!
    var paperWidth:        Double!
    var paperHeight:       Double!
    var paperBottomLeft:   NSPoint!

    // var paperBoundsLayer = CALayer()

    var pointRadius: CGFloat {
        return CGFloat(scale*minPaperDimension/150.0)
    }

    var dashLength: CGFloat {
        return CGFloat(scale*minPaperDimension/50.0)
    }

    var spaceLength: CGFloat {
        return CGFloat(scale*minPaperDimension/75.0)
    }

    var minPaperDimension: Double {
        return Double(min(main.paper.height, main.paper.width))
    }

    var diagram = Diagram()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupView()
    }

    func setupView() {
        let newFrame = NSRect(x: frame.origin.x,
                              y: frame.origin.y,
                          width: 500,
                         height: frame.height)
        self.frame = newFrame
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(DiagramView.updatePadding(_:)),
            name: NSNotification.Name.NSViewFrameDidChange,
            object: nil
        )
        postsFrameChangedNotifications = true
        // minPaperDimension = Double(min(main.paper.height, main.paper.width))
        // layer = CALayer()
        // layer!.addSublayer(paperBoundsLayer)
    }

    override func draw(_ dirtyRect: NSRect) {
        // wantsLayer = true
        NSColor.controlColor.set()
        NSBezierPath.fill(bounds)
        drawPaperBounds()
        for crease in diagram.creases {
            draw(line: crease, type: .crease)
        }
        for line in diagram.lines {
            draw(line: line, type: .line)
        }
        if let fold = diagram.fold {
            draw(line: fold, type: .fold)
        }
        NSColor.black.set()
        NSBezierPath.stroke(diagram.bounds)
        drawArrows()
        drawSelectedPoint()
        drawPoints()
    }

    @objc func updatePadding(_ note: Notification) {
        padding = Double(min(frame.size.width/6.0, frame.size.height/6.0))
    }

    func drawPaperBounds() {
        NSColor.white.set()
        scale = min(Double(bounds.width)/main.paper.width   - 2*padding,
                    Double(bounds.height)/main.paper.height - 2*padding)
        paperWidth  = scale*main.paper.width
        paperHeight = scale*main.paper.height

        if Double(bounds.width)  - paperWidth
         > Double(bounds.height) - paperHeight {
            paperBottomLeft = NSPoint(
                x: (Double(bounds.width) - paperWidth)/2.0,
                y: Double(bounds.height) - paperHeight - (padding as Double)
            )
        }
        else {
            paperBottomLeft = NSPoint(
                x: Double(bounds.width) - paperWidth - (padding as Double),
                y: (Double(bounds.height) - paperHeight)/2.0
            )
        }
        diagram.bounds = NSRect(x: Double(paperBottomLeft.x),
                                y: Double(paperBottomLeft.y),
                            width: paperWidth,
                           height: paperHeight)
        // minPaperDimension = Double(min(main.paper.height, main.paper.width))
        /* paperBoundsLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        paperBoundsLayer.bounds = NSRect(x: 0.0,
                                         y: 0.0,
                                     width: paperWidth,
                                    height: paperHeight)
        paperBoundsLayer.backgroundColor = CGColor.white */
        NSBezierPath.fill(diagram.bounds)
    }

    func drawArrows() {
        for arrow in diagram.arrows {
            let stem = NSBezierPath()
            stem.move(to: viewPoint(from: arrow.beginPoint))
            stem.appendArc(from: viewPoint(from: arrow.controlPoint),
                             to: viewPoint(from: arrow.endPoint),
                         radius: CGFloat(scale*arrow.arcRadius))
            NSColor.black.set()
            stem.stroke()
            let arrowheadPoints = arrow.arrowheadPoints()
            let arrowhead = NSBezierPath()
            arrowhead.move(to: viewPoint(from: arrowheadPoints[0]))
            arrowhead.line(to: viewPoint(from: arrowheadPoints[1]))
            arrowhead.line(to: viewPoint(from: arrowheadPoints[2]))
            arrowhead.fill()
            let arrowtailPoints = arrow.arrowtailPoints()
            let arrowtail = NSBezierPath()
            arrowtail.move(to: viewPoint(from: arrowtailPoints[0]))
            arrowtail.line(to: viewPoint(from: arrowtailPoints[1]))
            arrowtail.line(to: viewPoint(from: arrowtailPoints[2]))
            arrowtail.line(to: viewPoint(from: arrowtailPoints[0]))
            NSColor.white.set()
            arrowtail.fill()
            NSColor.black.set()
            arrowtail.stroke()
        }
    }

    enum PointType {
        case selected, folded
    }

    func drawPoints() {
        for point in diagram.points {
            draw(point: point)
        }
    }

    func drawSelectedPoint() {
        let pointVC = (delegate as! MainSplitViewController).pointVC!
        draw(point: PointReference(PointVector(pointVC.x, pointVC.y)),
              type: .selected)
    }

    func viewPoint(from point: PointVector) -> NSPoint {
        return NSPoint(x: paperBottomLeft.x + CGFloat(scale*point.x),
                       y: paperBottomLeft.y + CGFloat(scale*point.y))
    }

    func paperPoint(from point: NSPoint) -> PointVector {
        return PointVector(Double(point.x - paperBottomLeft.x)/scale,
                           Double(point.y - paperBottomLeft.y)/scale)
    }

    enum LineType {
        case fold, crease, line
    }

    func draw(point pointReference: PointReference, type: PointType = .folded) {
        let point = viewPoint(from: pointReference.point)
        let origin = NSPoint(
            x: point.x - pointRadius,
            y: point.y - pointRadius
        )
        let dot = NSBezierPath(ovalIn: NSRect(
            origin: origin,
            size: NSSize(width: 2*pointRadius, height: 2*pointRadius)
        ))
        dot.lineWidth = pointRadius/2.0
        switch type {
        case .folded:
            let labelString = pointReference.label

            // Don't label paper corners
            if labelString.characters.count == 1 {
                let label = NSAttributedString(
                    string: labelString,
                    attributes: [
                        NSForegroundColorAttributeName: NSColor.red,
                        NSFontAttributeName: NSFont.boldSystemFont(ofSize: 18),
                        NSStrokeColorAttributeName: NSColor.white,
                        NSStrokeWidthAttributeName: NSNumber(value: -3.0),
                    ]
                )
                label.draw(at: point)
            }
            NSColor.red.set()
        case .selected:
            NSColor.blue.set()
        }
        dot.stroke()
    }

    func draw(line lineReference: LineReference, type: LineType = .crease) {
        if let (p1, p2) = main.paper.clip(line: lineReference.line) {
            let line = NSBezierPath()
            line.move(to: viewPoint(from: p1))
            line.line(to: viewPoint(from: p2))
            let labelString = lineReference.label
            let label: NSAttributedString
            if labelString.characters.count == 1 {
                label = NSAttributedString(
                    string: labelString,
                    attributes: [
                        NSFontAttributeName: NSFont.boldSystemFont(ofSize: 18),
                        NSStrokeColorAttributeName: NSColor.white,
                        NSStrokeWidthAttributeName: NSNumber(value: -3.0),
                    ]
                )
            }
            else {
                label = NSAttributedString(string: "")
            }
            switch type {
            case .fold:
                // The line is a fold, draw dashed black line
                let pattern: [CGFloat] = [dashLength, spaceLength]
                line.setLineDash(pattern, count: 2, phase: 0)
                NSColor.black.set()
                line.stroke()

                label.draw(at: viewPoint(from: (p1 + p2)/2))
            case .crease:
                // The line is just a crease. Draw solid gray line
                NSColor.lightGray.set()
                line.stroke()
            case .line:
                // The line must be unambiguously shown
                // Draw thick solid black line
                line.lineWidth = 1.0
                NSColor.black.set()
                line.stroke()

                label.draw(at: viewPoint(from: (p1 + p2)/2))
            }
        }
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
        var viewPoint = convert(event.locationInWindow, from: nil)
        convert(viewPoint: &viewPoint)
        let selectedPoint = paperPoint(from: viewPoint)
        needsDisplay = true
        delegate.update(beginPoint: selectedPoint)
    }

    override func mouseDragged(with event: NSEvent) {
        var viewPoint = convert(event.locationInWindow, from: nil)
        convert(viewPoint: &viewPoint)
        let selectedPoint = PointVector(
            Double(viewPoint.x - paperBottomLeft.x)/scale,
            Double(viewPoint.y - paperBottomLeft.y)/scale
        )
        needsDisplay = true
        delegate.update(draggedPoint: selectedPoint)
    }
}
