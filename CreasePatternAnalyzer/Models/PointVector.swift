//
//  PointVector.swift
//  CreasePatternAnalyzer
//
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Darwin

struct PointVector: Hashable, CustomStringConvertible {
    var x = 0.0
    var y = 0.0

    var magnitude: Double {
        return sqrt(magnitudeSquared())
    }

    var hashValue: Int {
        let fx = x/main.paper.width
        let fy = y/main.paper.height
        let nx = Int(floor(0.5 + fx*Double(main.numX)))
        let ny = Int(floor(0.5 + fy*Double(main.numY)))
        return 1 + nx*main.numY + ny
    }

    var description: String {
        let xx = Float(x)
        let yy = Float(y)
        return "(\(abs(xx) < main.εF ? 0 : xx), \(abs(yy) < main.εF ? 0 : yy))"
    }

    init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }

    func magnitudeSquared() -> Double {
        return x*x + y*y
    }

    func dot(_ point: PointVector) -> Double {
        return x*point.x + y*point.y
    }

    // Rotate the PointVector counterclockwise about the origin
    // angle is in radians
    func rotatedBy(_ angle: Double) -> PointVector {
        let sn = sin(angle)
        let cs = cos(angle)
        return PointVector(x*cs - y*sn, x*sn + y*cs)
    }

    // Rotate the PointVector counterclockwise about the origin
    func rotatedBy90() -> PointVector {
        return PointVector(-y, x)
    }

    func normalized() -> PointVector {
        let mag = magnitude
        return PointVector(x/mag, y/mag)
    }

    // Make PointVector close to zero equal to (0, 0)
    mutating func chop() {
        if abs(x) < main.ε { x = 0 }
        if abs(y) < main.ε { y = 0 }
    }

    func chopped() -> PointVector {
        return PointVector(abs(x) < main.ε ? 0 : x, abs(y) < main.ε ? 0 : y)
    }
}

func ==(left: PointVector, right: PointVector) -> Bool {
    return left.hashValue == right.hashValue
}

// Operator overloads for PointVector
func +(left: PointVector, right: PointVector) -> PointVector {
    return PointVector(left.x + right.x, left.y + right.y)
}
func -(left: PointVector, right: PointVector) -> PointVector {
    return PointVector(left.x - right.x, left.y - right.y)
}
func *(left: PointVector, right: PointVector) -> PointVector {
    return PointVector(left.x * right.x, left.y * right.y)
}
func /(left: PointVector, right: PointVector) -> PointVector {
    return PointVector(left.x / right.x, left.y / right.y)
}

func +(left: PointVector, distance: Double) -> PointVector {
    return PointVector(left.x + distance, left.y + distance)
}
func -(left: PointVector, distance: Double) -> PointVector {
    return PointVector(left.x - distance, left.y - distance)
}
func *(left: PointVector, distance: Double) -> PointVector {
    return PointVector(left.x * distance, left.y * distance)
}
func /(left: PointVector, distance: Double) -> PointVector {
    return PointVector(left.x / distance, left.y / distance)
}

func +=(left: inout PointVector, right: PointVector) {
    left.x = left.x + right.x
    left.y = left.y + right.y
}
func -=(left: inout PointVector, right: PointVector) {
    left.x = left.x - right.x
    left.y = left.y - right.y
}
func *=(left: inout PointVector, right: PointVector) {
    left.x = left.x * right.x
    left.y = left.y * right.y
}
func /=(left: inout PointVector, right: PointVector) {
    left.x = left.x / right.x
    left.y = left.y / right.y
}
