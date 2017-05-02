//
//  References.swift
//  CreasePatternAnalyzer
//
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//
import Foundation

protocol Reference {
    var label: String { get set }
}

// A reference to a point obtained from an intersection of two lines
class PointReference: NSObject, Reference {
    let point:      PointVector!
    let firstLine:  LineReference!
    let secondLine: LineReference!

    var pointString: String {
        return point.description
    }

    var rank = 0

    var distanceError = Double.greatestFiniteMagnitude

    var label: String = "_"

    func isNotCorner() -> Bool {
        return label.characters.count == 1
    }

    override var description: String {
        if label.characters.count == 1 {
            return "point \(label)"
        }
        return label
    }

    override var hashValue: Int {
        return point.hashValue
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? PointReference {
            return point == other.point
        }
        return false
    }

    // Only used for selected points on the paper
    init(_ point: PointVector) {
        self.firstLine  = nil
        self.secondLine = nil
        self.point      = point
    }

    init(_ firstLine: LineReference, _ secondLine: LineReference,
         _ point: PointVector, _ rank: Int) {
        self.firstLine  = firstLine
        self.secondLine = secondLine
        self.point      = point
        self.rank       = rank
    }

    init(_ firstLine: LineReference, _ secondLine: LineReference,
         _ point: PointVector, label: String) {
        self.label      = label
        self.firstLine  = firstLine
        self.secondLine = secondLine
        self.point      = point
    }
}

class LineReference: NSObject, Reference {
    let line:  Line
    let axiom: Axiom?

    var rank = 0

    var shiftError = Double.greatestFiniteMagnitude
    var angleError = Double.greatestFiniteMagnitude

    var label: String = "_"

    func isNotEdge() -> Bool {
        return label.characters.count <= 1
    }

    override var hashValue: Int {
        return line.hashValue
    }

    override var description: String {
        if label.characters.count == 1 {
            return "line \(label)"
        }
        return label
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? LineReference {
            return line == other.line
        }
        return false
    }

    init(_ line: Line, label: String) {
        self.line  = line
        self.axiom = nil
        self.label = label
    }

    init(_ line: Line, _ axiom: Axiom, _ rank: Int) {
        self.line  = line
        self.axiom = axiom
        self.rank  = rank
    }
}

enum Axiom {
    case A1(PointReference, PointReference)
    case A2(PointReference, PointReference)
    case A3(LineReference,  LineReference)
    case A4(PointReference, LineReference)
    case A5(PointReference, LineReference, PointReference)
    case A6(PointReference, LineReference, PointReference, LineReference)
    case A7(PointReference, LineReference, LineReference)
}
