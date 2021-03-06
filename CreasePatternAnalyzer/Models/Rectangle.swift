//
//  Rectangle.swift
//  CreasePatternAnalyzer
//
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

struct Rectangle {
    var bottomLeft: PointVector
    var topRight: PointVector

    var width: Double {
        return topRight.x - bottomLeft.x
    }

    var leftLine:   Line! = nil
    var bottomLine: Line! = nil
    var rightLine:  Line! = nil
    var topLine:    Line! = nil

    var leftReference:   LineReference! = nil
    var rightReference:  LineReference! = nil
    var topReference:    LineReference! = nil
    var bottomReference: LineReference! = nil

    var bottomLeftReference:  PointReference! = nil
    var bottomRightReference: PointReference! = nil
    var topLeftReference:     PointReference! = nil
    var topRightReference:    PointReference! = nil

    var height: Double {
        return topRight.y - bottomLeft.y
    }

    // Always ≥ 1
    var aspectRatio: Double {
        if width <= height { return height/width }
        return width/height
    }

    var corners: Set<PointReference> {
        return [
            bottomLeftReference, bottomRightReference,
            topLeftReference, topRightReference,
        ]
    }

    var edges: Set<LineReference> {
        return [leftReference, bottomReference, rightReference, topReference]
    }

    init(point: PointVector) {
        bottomLeft = point
        topRight   = point
    }

    // Perform no check on the validity of the rectangle
    init(bottomLeft: PointVector, topRight: PointVector) {
        self.bottomLeft = bottomLeft
        self.topRight   = topRight

        leftLine   = Line(distance: bottomLeft.x, unitNormal: PointVector(1, 0))
        bottomLine = Line(distance: bottomLeft.y, unitNormal: PointVector(0, 1))
        rightLine  = Line(distance: topRight.x,   unitNormal: PointVector(1, 0))
        topLine    = Line(distance: topRight.y,   unitNormal: PointVector(0, 1))

        leftReference   = LineReference(leftLine,   label: "the left edge")
        bottomReference = LineReference(bottomLine, label: "the bottom edge")
        rightReference  = LineReference(rightLine,  label: "the right edge")
        topReference    = LineReference(topLine,    label: "the top edge")

        bottomLeftReference = PointReference(
            leftReference,
            bottomReference,
            PointVector(bottomLeft.x, bottomLeft.y),
            label: "the bottom left corner"
        )
        topLeftReference = PointReference(
            leftReference,
            topReference,
            PointVector(bottomLeft.x, topRight.y),
            label: "the top left corner"
        )
        topRightReference = PointReference(
            rightReference,
            topReference,
            PointVector(topRight.x, topRight.y),
            label: "the top right corner"
        )
        bottomRightReference = PointReference(
            rightReference,
            bottomReference,
            PointVector(topRight.x, bottomLeft.y),
            label: "the bottom right corner"
        )
    }

    init(width: Double, height: Double) {
        self.init(bottomLeft: PointVector(0, 0),
                    topRight: PointVector(width, height))
    }

    // True if point is contained in the ractangle
    func encloses(point: PointVector) -> Bool {
        return bottomLeft.x - main.ε <= point.x
            && point.x <= topRight.x + main.ε
            && bottomLeft.y - main.ε <= point.y
            && point.y <= topRight.y + main.ε
    }

    func encloses(x: Double) -> Bool {
        return bottomLeft.x <= x && x <= topRight.x
    }

    func encloses(y: Double) -> Bool {
        return bottomLeft.y <= y && y <= topRight.y
    }

    // Stretch the coordinates so that the rectangle encloses the point
    func including(point: PointVector) -> Rectangle {
        var rectangle = self
        if bottomLeft.x > point.x { rectangle.bottomLeft.x = point.x }
        if bottomLeft.y > point.y { rectangle.bottomLeft.y = point.y }
        if topRight.x   < point.x { rectangle.topRight.x   = point.x }
        if topRight.y   < point.y { rectangle.topRight.y   = point.y }
        return rectangle
    }

    // Return the points of intersection between `line` and this rectangle
    func clip(line: Line) -> (PointVector, PointVector)? {
        var intersections = Set<PointVector>()
        if let leftIn = intersection(line, leftLine),
               bottomLeft.y <= leftIn.y && leftIn.y <= topRight.y {
            intersections.insert(leftIn)
        }
        if let rightIn = intersection(line, rightLine),
               bottomLeft.y <= rightIn.y && rightIn.y <= topRight.y {
            intersections.insert(rightIn)
        }
        if let bottomIn = intersection(line, bottomLine),
               bottomLeft.x <= bottomIn.x && bottomIn.x <= topRight.x {
            intersections.insert(bottomIn)
        }
        if let topIn = intersection(line, topLine),
               bottomLeft.x <= topIn.x && topIn.x <= topRight.x {
            intersections.insert(topIn)
        }
        if intersections.count < 2 { return nil }
        return (intersections.removeFirst(), intersections.removeFirst())
    }

    // Return true if either of the two portions of rectangle divided by `line`
    // qualifies as a skinny flap.
    // - Skinny: triangle or rectangle whose aspect ratio rises above a maximum
    func makesSkinnyFlap(line: Line) -> Bool {
        guard let (p1, p2) = clip(line: line) else {
            return true
        }
        let bisectorNormal = line.unitNormal.rotatedBy90()
        let bisector = Line(distance: ((p1 + p2)/2).dot(bisectorNormal),
                          unitNormal: bisectorNormal)

        // Intersections of bisector and this rectangle
        guard let (b1, b2) = clip(line: bisector) else {
            return true
        }
        if abs(getBoundingBox(p1, p2, b1).aspectRatio) > main.maxAspectRatio ||
           abs(getBoundingBox(p1, p2, b2).aspectRatio) > main.maxAspectRatio
        {
            return true
        }
        return false
    }

    func contains(line: Line) -> Bool {
        return !makesSkinnyFlap(line: line)
    }

    // Return a Rectangle that encloses all of the points passed as parameters.
    func getBoundingBox(_ p1: PointVector, _ p2: PointVector) -> Rectangle {
        return Rectangle(point: p1).including(point: p2)
    }

    // Return a Rectangle that encloses all of the points passed as parameters.
    func getBoundingBox(_ p1: PointVector, _ p2: PointVector, _ p3: PointVector)
            -> Rectangle {
        return Rectangle(point: p1).including(point: p2).including(point: p3)
    }
}
