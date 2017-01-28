//
//  utils.swift
//  CreasePatternAnalyzer
//
//  Copyright © 2016-2017 Kijjakarn Praditukrit. All rights reserved.
//

import Darwin

/*----------------------------------------------------------------------------
                Utility Functions Called from View Controllers
-----------------------------------------------------------------------------*/

let π = M_PI

extension Array where Element: Equatable {
    mutating func remove(elements: [Element]) {
        for element in elements {
            if let i = index(of: element) {
                remove(at: i)
            }
        }
    }
}

precedencegroup ExponentiationPrecedence {
    higherThan: MultiplicationPrecedence
    associativity: right
    assignment: false
}

// Infix operator for raising a number to some power
infix operator ^^ : ExponentiationPrecedence
func ^^(base: Double, exponent: Double) -> Double {
    return pow(base, exponent)
}

// C-style integer division for use in loops
func /(left: Int, right: Int) -> Int {
    return Int(floor(Double(left)/Double(right)))
}

func makeAllPointsAndLines() {
    // Clear old points and lines
    main.numLines = 0
    main.numPoints = 0
    main.allPoints.removeAll()
    main.allLines.removeAll()
    main.referencedPoints.removeAll()
    main.referencedLines.removeAll()
    main.diagrams.removeAll()
    main.instructions.removeAll()

    // Use paper's corners as point references and edges as line references
    main.allPoints.append(main.paper.corners)
    main.allLines.append(main.paper.edges)
    main.numPoints += main.allPoints[0].count
    main.numLines  += main.allLines[0].count
    var numPoints = 0
    var numLines  = 0
    for rank in 1...main.maxRank {
        // Variables to store lines and points generated from each axiom
        var newPoints = Set<PointReference>()
        var newLines  = Set<LineReference>()
        for axiom in main.axioms {
            if main.useAxioms[axiom - 1] {
                switch axiom {
                case 1: generateAxiom1(rank, &newLines)
                case 2: generateAxiom2(rank, &newLines)
                case 3: generateAxiom3(rank, &newLines)
                case 4: generateAxiom4(rank, &newLines)
                case 5: generateAxiom5(rank, &newLines)
                case 6: generateAxiom6(rank, &newLines)
                case 7: generateAxiom7(rank, &newLines)
                default: break
                }
            }
        }
        main.allLines.append(newLines)

        // Make intersection points from the new lines
        for i in 0...(rank/2) {
            let j = rank - i
            newPoints.formUnion(getIntersections(
                    main.allLines[i], main.allLines[j], forRank: rank
                )
            )
        }
        main.allPoints.append(newPoints)
        numPoints += newPoints.count
        numLines  += newLines.count
        main.numPoints += numPoints
        main.numLines  += numLines
        print("Rank \(rank): \(numPoints) points, \(numLines) lines")
    }
}

// Combine two or more instructions if last one is made by
// makeInstructions(point:pointLabels:), except for the last instruction in the
// main.instructions array
func coalesceInstructions() {
    for i in stride(from: main.instructions.count - 2, to: 0, by: -1) {
        if main.diagrams[i].fold == nil {
            for j in stride(from: i - 1, to: -1, by: -1) {
                if let oldFold = main.diagrams[j].fold {
                    let lines = main.diagrams[i].lines
                    if (lines[0].line == oldFold.line
                    ||  lines[1].line == oldFold.line) {
                        main.diagrams[j].points.append(
                            main.diagrams[i].points[0]
                        )
                        insertInstruction(fromIndex: i, toIndex: j)
                        main.diagrams.remove(at: i)
                        main.instructions.remove(at: i)
                        break
                    }
                }
            }
        }
    }
}

// Insert the instruction from `i` to just after the first instruction
// (sentence) already contained in `j`
func insertInstruction(fromIndex i: Int, toIndex j: Int) {
    let firstPeriod = main.instructions[j].characters.index(of: ".")!
    let insertionIndex = main.instructions[j].index(firstPeriod, offsetBy: 1)
    let insertionString = " " + main.instructions[i]
    main.instructions[j].insert(contentsOf: insertionString.characters,
                                        at: insertionIndex)
}

func generateAxiom1(_ rank: Int, _ newLines: inout Set<LineReference>) {
    for i in 0...(rank - 1)/2 {
        let j = rank - 1 - i
        for point1 in main.allPoints[i] {
        for point2 in main.allPoints[j] {
            if newLines.count + main.numLines > main.maxNumLines {
                return
            }
            if let newLine = axiom1(point1.point, point2.point) {
                insert(
                    uniqueLine:
                        LineReference(newLine, .A1(point1, point2), rank),
                    into: &newLines,
                    forRank: rank
                )
            }
        }}
    }
}

func generateAxiom2(_ rank: Int, _ newLines: inout Set<LineReference>) {
    for i in 0...(rank - 1)/2 {
        let j = rank - 1 - i
        for point1 in main.allPoints[i] {
        for point2 in main.allPoints[j] {
            if newLines.count + main.numLines > main.maxNumLines {
                return
            }
            if let newLine = axiom2(point1.point, point2.point) {
                insert(
                    uniqueLine:
                        LineReference(newLine, .A2(point1, point2), rank),
                    into: &newLines,
                    forRank: rank
                )
            }
        }}
    }
}

func generateAxiom3(_ rank: Int, _ newLines: inout Set<LineReference>) {
    for i in 0...(rank - 1)/2 {
        let j = rank - 1 - i
        for line1 in main.allLines[i] {
        for line2 in main.allLines[j] {
            for newLine in axiom3(line1.line, line2.line) {
                if newLines.count + main.numLines > main.maxNumLines {
                    return
                }
                insert(
                    uniqueLine: LineReference(newLine, .A3(line1, line2), rank),
                    into: &newLines,
                    forRank: rank
                )
            }
        }}
    }
}

func generateAxiom4(_ rank: Int, _ newLines: inout Set<LineReference>) {
    for i in 0...(rank - 1)/2 {
        let j = rank - 1 - i
        for line  in main.allLines[i]  {
        for point in main.allPoints[j] {
            if !line.line.contains(point: point.point) {
                if newLines.count + main.numLines > main.maxNumLines {
                    return
                }
                if let newLine =
                        axiom4(point: point.point, line: line.line) {
                    insert(
                        uniqueLine:
                            LineReference(newLine, .A4(point, line), rank),
                        into: &newLines,
                        forRank: rank
                    )
                }
            }
        }}
    }
}

func generateAxiom5(_ rank: Int, _ newLines: inout Set<LineReference>) {
    for i in 0...(rank - 1)     {
    for j in 0...(rank - 1 - i) {
        let k = rank - i - j - 1
        for point1 in main.allPoints[i] {
        for line   in main.allLines[j]  {
        for point2 in main.allPoints[k] {
            if i != k
            && point1 != point2
            && !line.line.contains(point: point1.point)
            && !line.line.contains(point: point2.point) {
                for newLine in axiom5(bring: point1.point,
                                         to: line.line,
                                    through: point2.point) {
                    if newLines.count + main.numLines > main.maxNumLines {
                        return
                    }
                    insert(
                        uniqueLine: LineReference(
                                newLine, .A5(point1, line, point2), rank),
                        into: &newLines,
                        forRank: rank
                    )
                }
            }
        }}}
    }}
}

func generateAxiom6(_ rank: Int, _ newLines: inout Set<LineReference>) {
    for sumP in 0...(rank - 1)        {   // Sum of ranks of the two points
    for sumL in 0...(rank - 1 - sumP) {   // Sum of ranks of the two lines
    for i    in 0...(sumP/2)          {
        let j = sumP - i
        for k in 0...sumL       {
        for l in 0...(sumL - k) {
            for point1 in main.allPoints[i] {
            for point2 in main.allPoints[j] {
            for line1  in main.allLines[k]  {
            for line2  in main.allLines[l]  {
                if point1 != point2
                && line1  != line2
                && !line1.line.contains(point: point1.point)
                && !line2.line.contains(point: point2.point)
                && !(line1.line.contains(point: point2.point)
                  && line2.line.contains(point: point1.point)) {
                    for newLine in axiom6(bring: point1.point, to: line1.line,
                                            and: point2.point, on: line2.line) {
                        if newLines.count + main.numLines
                        > main.maxNumLines {
                            return
                        }
                        insert(
                            uniqueLine: LineReference(newLine,
                                    .A6(point1, line1, point2, line2), rank),
                            into: &newLines,
                            forRank: rank
                        )
                    }
                }
            }}}}
        }}
    }}}
}

func generateAxiom7(_ rank: Int, _ newLines: inout Set<LineReference>) {
    for i in 0...(rank - 1)     {
    for j in 0...(rank - 1 - i) {
        let k = rank - 1 - i - j
        for line1 in main.allLines[i]  {
        for point in main.allPoints[j] {
        for line2 in main.allLines[k]  {
            if i != k
            && !line1.line.contains(point: point.point) {
                if newLines.count + main.numLines > main.maxNumLines {
                    return
                }
                if let newLine = axiom7(bring: point.point,
                                           to: line1.line,
                                        along: line2.line) {
                    insert(
                        uniqueLine: LineReference(
                                newLine, .A7(point, line1, line2), rank),
                        into: &newLines,
                        forRank: rank
                    )
                }
            }
        }}}
    }}
}

// Find the intersections between the lines in `lines1` and `lines2`
func getIntersections(_ lines1: Set<LineReference>,
                      _ lines2: Set<LineReference>,
                forRank rank: Int) -> Set<PointReference> {
    var points = Set<PointReference>()
    for line1 in lines1 {
    for line2 in lines2 {
        if let point = intersection(angleConstraint: main.minAngle,
                                    line1.line,
                                    line2.line),
           main.paper.encloses(point: point) {
            insert(
                uniquePoint: PointReference(line1, line2, point, rank),
                into: &points,
                forRank: rank
            )
        }
    }}
    return points
}

func insert(uniqueLine line: LineReference,
                 into lines: inout Set<LineReference>,
               forRank rank: Int) {
    for i in 0...(rank - 1) {
        if main.allLines[i].contains(line) {
            return
        }
    }
    lines.insert(line)
}

func insert(uniquePoint point: PointReference,
                  into points: inout Set<PointReference>,
                 forRank rank: Int) {
    for i in 0...(rank - 1) {
        if main.allPoints[i].contains(point) || point.hashValue == 0 {
            return
        }
    }
    points.insert(point)
}

func matchedPoints(for inputPoint: PointVector) -> [PointReference] {
    var matched = [PointReference]()
    for rankPoints in main.allPoints {
        for point in rankPoints {
            let distanceError = (inputPoint - point.point).magnitude
            if distanceError <= main.maxDistanceError {
                point.distanceError = distanceError
                matched.append(point)
            }
        }
    }
    return matched
}

func matchedLines(for inputLine: Line) -> [LineReference] {
    var matched = [LineReference]()
    for rankLines in main.allLines {
        for line in rankLines {
            let (shiftError, angleError) = inputLine - line.line
            if shiftError <= main.maxShiftError
            && angleError <= main.maxAngleError {
                line.angleError = angleError
                line.shiftError = shiftError
                matched.append(line)
            }
        }
    }
    return matched
}

func clearInstructions() {
    for referencedPoint in main.referencedPoints {
        referencedPoint.label = "_"
    }
    for referencedLine in main.referencedLines {
        referencedLine.label = "_"
    }
    main.referencedPoints.removeAll()
    main.referencedLines.removeAll()
    main.instructions.removeAll()
    main.diagrams.removeAll()
}

func makeInstructions(for reference: Reference) {
    var stack = [(reference, false)]
    var pointLabels = main.pointLabels
    var lineLabels  = main.lineLabels

    while !stack.isEmpty {
        let (reference, ready) = stack.popLast()!
        if ready {
            if reference is PointReference {
                main.referencedPoints.insert(reference as! PointReference)
            }
            else {
                main.referencedLines.insert(reference as! LineReference)
            }
        }
        if let point = reference as? PointReference {
            // If already made, ignore. This also includes corners
            if main.referencedPoints.contains(point) && !ready
            || !point.isNotCorner() {
                continue
            }
            let line1 = point.firstLine!
            let line2 = point.secondLine!

            // Don't make instruction for corners
            if !ready {
                stack.append((reference, true))
                if line1.label == "_" {
                    stack.append((line1, false))
                }
                if line2.label == "_" {
                    stack.append((line2, false))
                }
                continue
            }
            // The instruction is ready to be made
            point.label = "\(pointLabels.popLast()!)"

            var diagram: Diagram
            if let oldDiagram = main.diagrams.last {
                diagram = oldDiagram
            }
            else {
                diagram = Diagram()
            }
            diagram.arrows.removeAll()

            // Make old fold a crease
            if let oldFold = diagram.fold {
                diagram.creases.append(oldFold)
            }
            // Delete old fold
            diagram.fold   = nil
            diagram.lines  = [line1, line2]
            diagram.points = [point]

            main.diagrams.append(diagram)
            main.instructions.append("The intersection between \(line1) "
                + "and \(line2) creates \(point).")
            continue
        }
        else {
            // reference is LineReference
            let line = reference as! LineReference

            // If already made, ignore
            if main.referencedLines.contains(line) && !ready {
                continue
            }
            var instruction: String
            var arrows = [Arrow]()
            var points = [PointReference]()
            var lines = [LineReference]()

            if line.axiom == nil {
                line.label = "\(lineLabels.popLast()!)"
                continue
            }
            switch line.axiom! {
            case .A1(let point1, let point2):
                if !ready {
                    stack.append((reference, true))
                    if point1.label == "_" {
                        stack.append((point1, false))
                    }
                    if point2.label == "_" {
                        stack.append((point2, false))
                    }
                    continue
                }
                line.label = "\(lineLabels.popLast()!)"
                instruction = "(A1) Fold through \(point1) and \(point2), "
                            + "creating \(line)."

                // Make arrows
                let arrowLine = Line(point: (point1.point + point2.point)/2,
                                    normal:  point1.point - point2.point)
                let arrow: Arrow
                let (edgePoint1, edgePoint2) = main.paper.clip(line: arrowLine)!
                if line.line.distance(toPoint: edgePoint1)
                 < line.line.distance(toPoint: edgePoint2) {
                    arrow = Arrow(
                        beginPoint: edgePoint1,
                        endPoint: line.line.reflection(ofPoint: edgePoint1)
                    )
                }
                else {
                    arrow = Arrow(
                        beginPoint: edgePoint2,
                        endPoint: line.line.reflection(ofPoint: edgePoint2)
                    )
                }
                arrows.append(arrow)

                // Make points
                points.append(point1)
                points.append(point2)

            case .A2(let point1, let point2):
                if !ready {
                    stack.append((reference, true))
                    if point1.label == "_" {
                        stack.append((point1, false))
                    }
                    if point2.label == "_" {
                        stack.append((point2, false))
                    }
                    continue
                }
                line.label = "\(lineLabels.popLast()!)"
                instruction = "(A2) Fold \(point1) onto \(point2), "
                            + "creating \(line)."

                // Make arrows
                arrows.append(Arrow(beginPoint: point1.point,
                                      endPoint: point2.point))

                // Make points
                points.append(point1)
                points.append(point2)

            case .A3(let line1, let line2):
                if !ready {
                    stack.append((reference, true))
                    if line1.label == "_" {
                        stack.append((line1, false))
                    }
                    if line2.label == "_" {
                        stack.append((line2, false))
                    }
                    continue
                }
                line.label = "\(lineLabels.popLast()!)"
                instruction = "(A3) Fold \(line1) onto \(line2), creating "
                            + "\(line)."

                // Make arrows
                let (edgePoint11, edgePoint12) =
                    main.paper.clip(line: line1.line)!
                let (edgePoint21, edgePoint22) =
                    main.paper.clip(line: line2.line)!
                let reflection11 = line.line.reflection(ofPoint: edgePoint11)
                let reflection12 = line.line.reflection(ofPoint: edgePoint12)
                let reflection21 = line.line.reflection(ofPoint: edgePoint21)
                let reflection22 = line.line.reflection(ofPoint: edgePoint22)
                var validPoints1 = [(PointVector, PointVector)]()
                var validPoints2 = [(PointVector, PointVector)]()
                if main.paper.encloses(point: reflection11) {
                    validPoints1.append((edgePoint11, reflection11))
                }
                if main.paper.encloses(point: reflection12) {
                    validPoints1.append((edgePoint12, reflection12))
                }
                if main.paper.encloses(point: reflection21) {
                    validPoints2.append((edgePoint21, reflection21))
                }
                if main.paper.encloses(point: reflection22) {
                    validPoints2.append((edgePoint22, reflection22))
                }
                let midpoint: PointVector

                // If line1's reflections are all valid
                // This means line1 lies completely in line2
                if validPoints1.count == 2 {
                    midpoint = (edgePoint11 + edgePoint12)/2
                }
                // If line2's reflections are all valid
                // This means line2 lies completely in line1
                else if validPoints2.count == 2 {
                    midpoint = (edgePoint21 + edgePoint22)/2
                }
                // Else only one of line1's reflections is valid and only one of
                // line2's reflections is valid
                // This means some part of line1 and line2 overlap
                else {
                    midpoint = (validPoints1[0].0 + validPoints2[0].1)/2
                }
                arrows.append(Arrow(
                    beginPoint: midpoint,
                    endPoint: line.line.reflection(ofPoint: midpoint)
                ))

                // Make lines
                lines.append(line1)
                lines.append(line2)

            case .A4(let point1, let line1):
                if !ready {
                    stack.append((reference, true))
                    if point1.label == "_" {
                        stack.append((point1, false))
                    }
                    if line1.label == "_" {
                        stack.append((line1, false))
                    }
                    continue
                }
                line.label = "\(lineLabels.popLast()!)"
                instruction = "(A4) Fold through \(point1) perpendicular to "
                            + "\(line1), creating \(line)."

                // Make arrows
                let (edgePoint1, edgePoint2) =
                    main.paper.clip(line: line1.line)!
                let arrow: Arrow
                if line.line.distance(toPoint: edgePoint1)
                 < line.line.distance(toPoint: edgePoint2) {
                    arrow = Arrow(
                        beginPoint: edgePoint1,
                        endPoint: line.line.reflection(ofPoint: edgePoint1)
                    )
                }
                else {
                    arrow = Arrow(
                        beginPoint: edgePoint2,
                        endPoint: line.line.reflection(ofPoint: edgePoint2)
                    )
                }
                arrows.append(arrow)

                // Make point
                points.append(point1)

                // Make line
                lines.append(line1)

            case .A5(let point1, let line1, let point2):
                if !ready {
                    stack.append((reference, true))
                    if point1.label == "_" {
                        stack.append((point1, false))
                    }
                    if line1.label == "_" {
                        stack.append((line1, false))
                    }
                    if point2.label == "_" {
                        stack.append((point2, false))
                    }
                    continue
                }
                line.label = "\(lineLabels.popLast()!)"
                instruction = "(A5) Fold \(point1) onto \(line1) through "
                            + "\(point2), creating \(line)."

                // Make arrows
                let arrow = Arrow(
                    beginPoint: point1.point,
                    endPoint: line.line.reflection(ofPoint: point1.point)
                )
                arrows.append(arrow)

                // Make points
                points.append(point1)
                points.append(point2)

                // Make line
                lines.append(line1)

            case .A6(let point1, let line1, let point2, let line2):
                if !ready {
                    stack.append((reference, true))
                    if point1.label == "_" {
                        stack.append((point1, false))
                    }
                    if line1.label == "_" {
                        stack.append((line1, false))
                    }
                    if point2.label == "_" {
                        stack.append((point2, false))
                    }
                    if line2.label == "_" {
                        stack.append((line2, false))
                    }
                    continue
                }
                line.label = "\(lineLabels.popLast()!)"
                instruction = "(A6) Simultaneously fold \(point1) onto "
                            + "\(line1) and \(point2) onto \(line2), "
                            + "creating \(line)."

                // Make arrows
                let arrow1 = Arrow(
                    beginPoint: point1.point,
                    endPoint: line.line.reflection(ofPoint: point1.point)
                )
                let arrow2: Arrow

                // If the two points are on the same side of the line
                if (line.line.distance - point1.point.dot(line.line.unitNormal))
                 * (line.line.distance - point2.point.dot(line.line.unitNormal))
                  > 0 {
                    arrow2 = Arrow(
                        beginPoint: point2.point,
                        endPoint:
                            line.line.reflection(ofPoint: point2.point)
                    )
                }
                else {
                    arrow2 = Arrow(
                        beginPoint:
                            line.line.reflection(ofPoint: point2.point),
                        endPoint: point2.point
                    )
                }
                arrows.append(arrow1)
                arrows.append(arrow2)

                // Make points
                points.append(point1)
                points.append(point2)

                // Make lines
                lines.append(line1)
                lines.append(line2)

            case .A7(let point1, let line1, let line2):
                if !ready {
                    stack.append((reference, true))
                    if point1.label == "_" {
                        stack.append((point1, false))
                    }
                    if line1.label == "_" {
                        stack.append((line1, false))
                    }
                    if line2.label == "_" {
                        stack.append((line2, false))
                    }
                    continue
                }
                line.label = "\(lineLabels.popLast()!)"
                instruction = "(A7) Fold \(point1) onto \(line1) perpendicular"
                            + " to \(line2), creating \(line)"

                // Make arrows
                let arrow = Arrow(
                    beginPoint: point1.point,
                    endPoint: line.line.reflection(ofPoint: point1.point)
                )
                arrows.append(arrow)

                // Make points
                points.append(point1)

                // Make lines
                lines.append(line1)
                lines.append(line2)
            }
            var diagram: Diagram
            if let oldDiagram = main.diagrams.last {
                diagram = oldDiagram
                for oldLine in oldDiagram.lines {
                    if oldLine.isNotEdge() {
                        diagram.creases.append(oldLine)
                    }
                }
            }
            else {
                diagram = Diagram()
            }
            diagram.arrows = arrows
            diagram.points = points
            diagram.lines  = lines

            diagram.creases.remove(elements: lines)

            // Make old fold a crease
            if let oldFold = diagram.fold {
                diagram.creases.append(oldFold)
            }
            // Update new fold
            diagram.fold = line

            main.diagrams.append(diagram)
            main.instructions.append(instruction)
        }
    }
}

// Get a list of every possible pair from the set
// Currently not used in this program
// - `ordered` is true if (p1, p2) ≠ (p2, p1)
func getPairs<T>(data: Set<T>, ordered: Bool) -> [(T, T)] {
    var pairs = [(T, T)]()
    var index = data.startIndex
    while index != data.endIndex {
        var indexNew = data.index(after: index)
        while indexNew != data.endIndex {
            pairs.append((data[index], data[indexNew]))
            if ordered {
                pairs.append((data[indexNew], data[index]))
            }
            indexNew = data.index(after: indexNew)
        }
        index = data.index(after: index)
    }
    return pairs
}
