import Darwin

/*----------------------------------------------------------------------------
                Utility Functions Called from the Main Program
-----------------------------------------------------------------------------*/

let π = M_PI

// Infix operator for raising a number to some power
infix operator^^ { associativity left precedence 180 }
func ^^(base: Double, exponent: Double) -> Double {
    return pow(base, exponent)
}

// C-style integer division for use in loops
func /(left: Int, right: Int) -> Int {
    return Int(floor(Double(left)/Double(right)))
}

func makeAllPointsAndLines() {
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
        main.allLines.append(newLines)

        // Make intersection points from the new lines
        for i in 0...(rank/2) {
            let j = rank - i
            newPoints.unionInPlace(getIntersections(
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

func generateAxiom1(rank: Int, inout _ newLines: Set<LineReference>) {
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

func generateAxiom2(rank: Int, inout _ newLines: Set<LineReference>) {
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

func generateAxiom3(rank: Int, inout _ newLines: Set<LineReference>) {
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

func generateAxiom4(rank: Int, inout _ newLines: Set<LineReference>) {
    for i in 0...(rank - 1)/2 {
        let j = rank - 1 - i
        for line  in main.allLines[i]  {
        for point in main.allPoints[j] {
            if !line.line.contains(point.point) {
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

func generateAxiom5(rank: Int, inout _ newLines: Set<LineReference>) {
    for i in 0...(rank - 1)     {
    for j in 0...(rank - 1 - i) {
        let k = rank - i - j - 1
        for point1 in main.allPoints[i] {
        for line   in main.allLines[j]  {
        for point2 in main.allPoints[k] {
            if i != k
            && point1 != point2
            && !line.line.contains(point1.point)
            && !line.line.contains(point2.point) {
                for newLine in axiom5(bring: point1.point, to: line.line,
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

func generateAxiom6(rank: Int, inout _ newLines: Set<LineReference>) {
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
                && !line1.line.contains(point1.point)
                && !line2.line.contains(point2.point)
                && !(line1.line.contains(point2.point)
                  && line2.line.contains(point1.point)) {
                    for newLine in axiom6(
                            bring: point1.point, to: line1.line,
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

func generateAxiom7(rank: Int, inout _ newLines: Set<LineReference>) {
    for i in 0...(rank - 1)     {
    for j in 0...(rank - 1 - i) {
        let k = rank - 1 - i - j
        for line1 in main.allLines[i]  {
        for point in main.allPoints[j] {
        for line2 in main.allLines[k]  {
            if i != k
            && !line1.line.contains(point.point) {
                if newLines.count + main.numLines > main.maxNumLines {
                    return
                }
                if let newLine = axiom7(bring: point.point, to: line1.line,
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

// Find the intersections lines between the lines in `lines1` and `lines2`
func getIntersections(lines1: Set<LineReference>,
                    _ lines2: Set<LineReference>,
                forRank rank: Int) -> Set<PointReference> {
    var points = Set<PointReference>()
    for line1 in lines1 {
    for line2 in lines2 {
        if let point = intersection(angleConstraint: main.minAngle,
                line1.line, line2.line) where main.paper.encloses(point) {
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
        inout into lines: Set<LineReference>, forRank rank: Int) {
    for i in 0...(rank - 1) {
        if main.allLines[i].contains(line) { return }
    }
    lines.insert(line)
}

func insert(uniquePoint point: PointReference,
        inout into points: Set<PointReference>, forRank rank: Int) {
    for i in 0...(rank - 1) {
        if main.allPoints[i].contains(point) || point.hashValue == 0 { return }
    }
    points.insert(point)
}

func matchedPoints() -> [PointReference] {
    var matched = [PointReference]()
    for rankPoints in main.allPoints {
        for point in rankPoints {
            let distanceError = (main.inputPoint - point.point).magnitude
            if distanceError <= main.maxDistanceError {
                point.distanceError = distanceError
                matched.append(point)
            }
        }
    }
    return matched
}

func matchedLines() -> [LineReference] {
    var matched = [LineReference]()
    for rankLines in main.allLines {
        for line in rankLines {
            let (shiftError, angleError) = main.inputLine - line.line
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
    for i in 1...main.maxRank {
        for point in main.allPoints[i] {
            point.label = "_"
        }
        for line in main.allLines[i] {
            line.label = "_"
        }
    }
}

func printInstructions(point point: PointReference,
                       pointLabels: [Character] = main.pointLabels,
                        lineLabels: [Character] = main.lineLabels)
        -> (pointLabels: [Character], lineLabels: [Character]) {
    if point.label != "_" {
        return (pointLabels, lineLabels)
    }
    var pointLabels = pointLabels
    var lineLabels  = lineLabels
    let line1 = point.firstLine
    let line2 = point.secondLine
    if line1.label == "_" {
        (pointLabels, lineLabels) = printInstructions(
            line: line1, pointLabels: pointLabels, lineLabels: lineLabels
        )
    }
    if line2.label == "_" {
        (pointLabels, lineLabels) = printInstructions(
            line: line2, pointLabels: pointLabels, lineLabels: lineLabels
        )
    }
    point.label = "point \(pointLabels.popLast()!)\(point.point)"
    print("The intersection between \(line1.label) and \(line2.label)"
        + " creates \(point.label).")
    return (pointLabels, lineLabels)
}

func printInstructions(line line: LineReference,
                     pointLabels: [Character] = main.pointLabels,
                      lineLabels: [Character] = main.lineLabels)
        -> (pointLabels: [Character], lineLabels: [Character]) {
    var pointLabels = pointLabels
    var lineLabels  = lineLabels
    if line.axiom == nil {
        line.label = "line \(lineLabels.popLast()!)(\(line.line))"
        return (pointLabels, lineLabels)
    }
    switch line.axiom! {
    case .A1(let point1, let point2):
        if point1.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                point: point1, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        if point2.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                point: point2, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        line.label = "line \(lineLabels.popLast()!)(\(line.line))"
        print("(A1) Fold through \(point1.label) and \(point2.label),"
            + " creating \(line.label).")
    case .A2(let point1, let point2):
        if point1.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                point: point1, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        if point2.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                point: point2, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        line.label = "line \(lineLabels.popLast()!)(\(line.line))"
        print("(A2) Fold \(point1.label) onto \(point2.label),"
            + " creating \(line.label).")
    case .A3(let line1, let line2):
        if line1.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                line: line1, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        if line2.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                line: line2, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        line.label = "line \(lineLabels.popLast()!)(\(line.line))"
        print("(A3) Fold \(line1.label) onto \(line2.label),"
            + " creating \(line.label).")
    case .A4(let point1, let line1):
        if point1.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                point: point1, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        if line1.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                line: line1, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        line.label = "line \(lineLabels.popLast()!)(\(line.line))"
        print("(A4) Fold through \(point1.label) perpendicular to"
            + " \(line1.label), creating \(line.label).")
    case .A5(let point1, let line1, let point2):
        if point1.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                point: point1, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        if line1.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                line: line1, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        if point2.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                point: point2, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        line.label = "line \(lineLabels.popLast()!)(\(line.line))"
        print("(A5) Fold \(point1.label) onto \(line1.label)"
            + " through \(point2.label), creating \(line.label).")
    case .A6(let point1, let line1, let point2, let line2):
        if point1.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                point: point1, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        if point2.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                point: point2, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        if line1.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                line: line1, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        if line2.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                line: line2, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        line.label = "line \(lineLabels.popLast()!)(\(line.line))"
        print("(A6) Simultaneously fold \(point1.label)"
            + " onto \(line1.label) and \(point2.label)"
            + " onto \(line2.label), creating \(line.label).")
    case .A7(let point1, let line1, let line2):
        if point1.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                point: point1, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        if line1.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                line: line1, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        if line2.label == "_" {
            (pointLabels, lineLabels) = printInstructions(
                line: line2, pointLabels: pointLabels, lineLabels: lineLabels
            )
        }
        line.label = "line \(lineLabels.popLast()!)(\(line.line))"
        print("(A7) Fold \(point1.label) onto \(line1.label)"
            + " perpendicular to \(line2.label), creating \(line.label)")
    }
    return (pointLabels, lineLabels)
}

// Get a list of every possible pair from the set
// Currently not used in this program
// - `ordered` is true if (p1, p2) ≠ (p2, p1)
func getPairs<T>(data: Set<T>, ordered: Bool) -> [(T, T)] {
    var pairs = [(T, T)]()
    var index = data.startIndex
    while index != data.endIndex {
        var indexNew = index.successor()
        while indexNew != data.endIndex {
            pairs.append((data[index], data[indexNew]))
            if (ordered) { pairs.append((data[indexNew], data[index])) }
            indexNew = indexNew.successor()
        }
        index = index.successor()
    }
    return pairs
}
