//
//  ReferenceFinder.swift
//  CreasePatternAnalyzer
//
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

class ReferenceFinder {
    var ε = 1e-8
    var εF: Float = 1e-8

    var maxRank   = 6
    let axioms    = [3, 2, 7, 6, 5, 4, 1]
    var useAxioms = [true, true, true, true, true, true, true]
    var paper     = Rectangle(bottomLeft: PointVector(0, 0),
                                topRight: PointVector(1, 1))

    let pointLabels = Array("LKJIHGFEDCBA")
    let lineLabels  = Array("ZYXWVUTSRQPO")

    // Number of horizontal partitions
    var numX = 5000

    // Number of vertical partitions
    var numY = 5000

    // Number of radial partitions
    var numRadius = 5000

    // Number of angle partitions
    var numAngle  = 5000

    // Minimum angle in degree between lines to define an intersection
    var minAngle  = 5.0

    // Number of points generated so far
    var numPoints = 0

    // Number of lines generated so far
    var numLines = 0

    // Maximum number of points to generate
    var maxNumPoints = 50000

    // Maximum number of lines to generate
    var maxNumLines  = 50000

    // Maximum number of matches to display
    var maxNumMatches = 15

    // Maximum aspect ratio of a triangular or quadrilateral flap
    var maxAspectRatio = 10.0

    // Maximum acceptable angle error in degrees of a line to desired line
    var maxAngleError = 2.0

    // Maximum acceptable shift distance of a line to desired line
    var maxShiftError = 0.08

    // Maximum acceptable distance of a point to desired point
    var maxDistanceError = 0.05

    // Array containing sets of points, one set for each rank
    var allPoints = [Set<PointReference>]()

    // Array containing sets of lines, one set for each rank
    var allLines  = [Set<LineReference>]()

    var shouldStopInitialization = false

    static var singleton = ReferenceFinder()

    var diagrams     = [Diagram]()
    var instructions = [String]()
    var referencedPoints = Set<PointReference>()
    var referencedLines  = Set<LineReference>()

    var detectedLines = [Line]()

    private init() {}

    func useAxiom(_ axiom: Int) -> Bool {
        return useAxioms[axiom - 1]
    }
}
