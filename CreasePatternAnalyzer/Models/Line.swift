//
//  Line.swift
//  CreasePatternAnalyzer
//
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Darwin

struct Line: Hashable, CustomStringConvertible {
    // unitNormal × distance is point on the line that is closest to the origin
    var distance: Double

    // Unit vector normal to the line
    var unitNormal: PointVector

    var hashValue: Int {
        // 0 ≤ fa ≤ 1
        var fa = (1 + atan2(unitNormal.y, unitNormal.x)/(2*π))
        let maxD = sqrt(main.paper.width^^2 + main.paper.height^^2)
        let fd = distance/maxD
        let nd = Int(floor(0.5 + fd*Double(main.numRadius)))

        // Map angle and π + angle to the same key
        if nd == 0 {
            fa = fmod(2*fa, 1)
        }
        let na = Int(floor(0.5 + fa*Double(main.numAngle)))
        return 1 + na*main.numRadius + nd
    }

    var description: String {
        if unitNormal.y == 0 {
            let intercept = Float(distance/unitNormal.x)
            if intercept == 0 || abs(intercept) < main.εF { return "x = 0" }
            if intercept <  0 { return "x = -\(-intercept)" }
            return "x = \(intercept)"
        }
        let intercept = Float(distance/unitNormal.y)
        let slope     = Float(-unitNormal.x/unitNormal.y)
        if slope == 0 {
            if intercept == 0 || abs(intercept) < main.εF { return "y = 0" }
            if intercept <  0 { return "y = -\(-intercept)" }
            return "y = \(intercept)"
        }
        if intercept == 0 || abs(intercept) < main.εF { return "y = \(slope)x" }
        if intercept <  0 { return "y = \(slope)x - \(-intercept)" }
        return "y = \(slope)x + \(intercept)"
    }

    // The two points must be distinct
    init(_ firstPoint: PointVector, _ secondPoint: PointVector) {
        unitNormal = (firstPoint - secondPoint).normalized().rotatedBy90()
        distance   = firstPoint.dot(unitNormal)
        if self.distance < 0 {
            self.distance   = -distance
            self.unitNormal = unitNormal*(-1)
        }
    }

    init(distance: Double, unitNormal: PointVector) {
        self.distance   = distance
        self.unitNormal = unitNormal
        if self.distance < 0 {
            self.distance   = -distance
            self.unitNormal = unitNormal*(-1)
        }
    }

    init(distance: Double, normal: PointVector) {
        self.distance   = distance
        self.unitNormal = normal.normalized()
        if self.distance < 0 {
            self.distance   = -distance
            self.unitNormal = unitNormal*(-1)
        }
    }

    // Given a point the line passes through and the unit normal vector
    init(point: PointVector, unitNormal: PointVector) {
        distance        = unitNormal.dot(point)
        self.unitNormal = unitNormal
        if self.distance < 0 {
            self.distance   = -distance
            self.unitNormal = unitNormal*(-1)
        }
    }

    init(point: PointVector, normal: PointVector) {
        unitNormal = normal.normalized()
        distance   = unitNormal.dot(point)
        if self.distance < 0 {
            self.distance   = -distance
            self.unitNormal = unitNormal*(-1)
        }
    }

    func y(fromX x: Double) -> Double {
        return (distance - x*unitNormal.x)/unitNormal.y
    }

    func x(fromY y: Double) -> Double {
        return (distance - y*unitNormal.y)/unitNormal.x
    }

    func reflection(ofPoint point: PointVector) -> PointVector {
        return point + unitNormal*2*(distance - point.dot(unitNormal))
    }

    func projection(ofPoint point: PointVector) -> PointVector {
        return point + unitNormal*(distance - point.dot(unitNormal))
    }

    func isParallel(toLine line: Line) -> Bool {
        return abs(unitNormal.dot(line.unitNormal.rotatedBy90())) < main.ε
    }

    func contains(point: PointVector) -> Bool {
        return distance(toPoint: point) < main.ε
    }

    func distance(toPoint point: PointVector) -> Double {
        return abs(distance - point.dot(unitNormal))
    }
}

func ==(first: Line, second: Line) -> Bool {
    return first.hashValue == second.hashValue
}

func -(first: Line, second: Line) -> (distance: Double, angle: Double) {
    return (
        abs(first.distance
          - first.unitNormal.dot(second.unitNormal)*second.distance),
        angle(first, second)
    )
}

// Return the angle in degrees between two lines
func angle(_ first: Line, _ second: Line) -> Double {
    let u1 = first.unitNormal
    let u2 = second.unitNormal
    return acos(u1.dot(u2))*(180/π)
}

// Return the intersection point between two lines
// Return nil if lines are parallel or are the same
func intersection(_ first: Line, _ second: Line) -> PointVector? {
    if first.isParallel(toLine: second) {
        return nil
    }
    let denominator = first.unitNormal.x*second.unitNormal.y
                    - first.unitNormal.y*second.unitNormal.x
    let x = (first.distance*second.unitNormal.y -
            second.distance*first.unitNormal.y)/denominator
    let y = (second.distance*first.unitNormal.x -
            first.distance*second.unitNormal.x)/denominator
    return PointVector(x, y)
}

// Return the intersection point between two lines
// Return nil if the angle between them is smaller than `angleConstraint`
// - `angleConstraint` given in degrees
func intersection(angleConstraint minAngle: Double,
        _ first: Line, _ second: Line) -> PointVector? {
    return angle(first, second) >= minAngle ? intersection(first, second) : nil
}
