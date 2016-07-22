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

extension ReferenceFinder {
    func makeAllPointsAndLines() {
        // Use paper's corners as point references and edges as line references
        allPoints.append(paper.corners)
        for point in allPoints[0] {
            print(point.label)
        }
        allLines.append(paper.edges)
        var numPoints = 0
        var numLines  = 0
        for rank in 1...maxRank {
            // Variables to store lines and points generated from each axiom
            var newPoints = Set<PointReference>()
            var newLines  = Set<LineReference>()
            for axiom in axioms {
                switch axiom {
                case 1: newLines.unionInPlace(generateAxiom1(rank))
                case 2: newLines.unionInPlace(generateAxiom2(rank))
                case 3: newLines.unionInPlace(generateAxiom3(rank))
                case 4: newLines.unionInPlace(generateAxiom4(rank))
                case 5: newLines.unionInPlace(generateAxiom5(rank))
                case 6: newLines.unionInPlace(generateAxiom6(rank))
                case 7: newLines.unionInPlace(generateAxiom7(rank))
                default: break
                }
            }
            allLines.append(newLines)

            // Make intersection points from the new lines
            for i in 0...(rank/2) {
                let j = rank - i
                newPoints.unionInPlace(
                    getIntersections(allLines[i], allLines[j], forRank: rank)
                )
            }
            allPoints.append(newPoints)
            numPoints += newPoints.count
            numLines  += newLines.count
            print("Rank \(rank): \(numPoints) points, \(numLines) lines")
        }
    }

    func generateAxiom1(rank: Int) -> Set<LineReference> {
        var newLines = Set<LineReference>()
        for i in 0...(rank - 1)/2 {
            let j = rank - 1 - i
            for point1 in allPoints[i] {
            for point2 in allPoints[j] {
                if let newLine = axiom1(point1.point, point2.point) {
                    insert(
                        uniqueLine: LineReference(newLine, .A1(point1, point2)),
                        into: &newLines,
                        forRank: rank
                    )
                }
            }}
        }
        return newLines
    }

    func generateAxiom2(rank: Int) -> Set<LineReference> {
        var newLines = Set<LineReference>()
        for i in 0...(rank - 1)/2 {
            let j = rank - 1 - i
            for point1 in allPoints[i] {
            for point2 in allPoints[j] {
                if let newLine = axiom2(point1.point, point2.point) {
                    insert(
                        uniqueLine: LineReference(newLine, .A2(point1, point2)),
                        into: &newLines,
                        forRank: rank
                    )
                }
            }}
        }
        return newLines
    }

    func generateAxiom3(rank: Int) -> Set<LineReference> {
        var newLines = Set<LineReference>()
        for i in 0...(rank - 1)/2 {
            let j = rank - 1 - i
            for line1 in allLines[i] {
            for line2 in allLines[j] {
                for newLine in axiom3(line1.line, line2.line) {
                    insert(
                        uniqueLine: LineReference(newLine, .A3(line1, line2)),
                        into: &newLines,
                        forRank: rank
                    )
                }
            }}
        }
        return newLines
    }

    func generateAxiom4(rank: Int) -> Set<LineReference> {
        var newLines = Set<LineReference>()
        for i in 0...(rank - 1)/2 {
            let j = rank - 1 - i
            for line  in allLines[i]  {
            for point in allPoints[j] {
                if !line.line.contains(point.point) {
                    if let newLine =
                            axiom4(point: point.point, line: line.line) {
                        insert(
                            uniqueLine: LineReference(
                                newLine,
                                .A4(point, line)
                            ),
                            into: &newLines,
                            forRank: rank
                        )
                    }
                }
            }}
        }
        return newLines
    }

    func generateAxiom5(rank: Int) -> Set<LineReference> {
        var newLines = Set<LineReference>()
        for i in 0...(rank - 1)     {
        for j in 0...(rank - 1 - i) {
            let k = rank - i - j - 1
            for point1 in allPoints[i] {
            for line   in allLines[j]  {
            for point2 in allPoints[k] {
                if i != k
                && point1 != point2
                && !line.line.contains(point1.point)
                && !line.line.contains(point2.point) {
                    for newLine in axiom5(bring: point1.point, to: line.line,
                                        through: point2.point) {
                        insert(
                            uniqueLine: LineReference(
                                newLine,
                                .A5(point1, line, point2)
                            ),
                            into: &newLines,
                            forRank: rank
                        )
                    }
                }
            }}}
        }}
        return newLines
    }

    func generateAxiom6(rank: Int) -> Set<LineReference> {
        var newLines = Set<LineReference>()
        for sumP in 0...(rank - 1)        {   // Sum of ranks of the two points
        for sumL in 0...(rank - 1 - sumP) {   // Sum of ranks of the two lines
        for i    in 0...(sumP/2)          {
            let j = sumP - i
            for k in 0...sumL       {
            for l in 0...(sumL - k) {
                for point1 in allPoints[i] {
                for point2 in allPoints[j] {
                for line1  in allLines[k]  {
                for line2  in allLines[l]  {
                    if point1 != point2
                    && line1  != line2
                    && !line1.line.contains(point1.point)
                    && !line2.line.contains(point2.point)
                    && !(line1.line.contains(point2.point)
                      && line2.line.contains(point1.point)) {
                        for newLine in axiom6(
                                bring: point1.point, to: line1.line,
                                and: point2.point, on: line2.line) {
                            insert(
                                uniqueLine: LineReference(
                                    newLine,
                                    .A6(point1, line1, point2, line2)
                                ),
                                into: &newLines,
                                forRank: rank
                            )
                        }
                    }
                }}}}
            }}
        }}}
        return newLines
    }

    func generateAxiom7(rank: Int) -> Set<LineReference> {
        var newLines = Set<LineReference>()
        for i in 0...(rank - 1)     {
        for j in 0...(rank - 1 - i) {
            let k = rank - 1 - i - j
            for line1 in allLines[i]  {
            for point in allPoints[j] {
            for line2 in allLines[k]  {
                if i != k
                && !line1.line.contains(point.point) {
                    if let newLine = axiom7(bring: point.point, to: line1.line,
                                            along: line2.line) {
                        insert(
                            uniqueLine: LineReference(
                                    newLine,
                                    .A7(point, line1, line2)
                                ),
                            into: &newLines,
                            forRank: rank
                        )
                    }
                }
            }}}
        }}
        return newLines
    }

    // Find the intersections lines between the lines in `lines1` and `lines2`
    func getIntersections(lines1: Set<LineReference>,
                        _ lines2: Set<LineReference>,
                    forRank rank: Int) -> Set<PointReference> {
        var points = Set<PointReference>()
        for line1 in lines1 {
        for line2 in lines2 {
            if let point = intersection(angleConstraint: minAngle,
                    line1.line, line2.line) where paper.encloses(point) {
                insert(
                    uniquePoint: PointReference(line1, line2, point),
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
            if allLines[i].contains(line) { return }
        }
        lines.insert(line)
    }

    func insert(uniquePoint point: PointReference,
            inout into points: Set<PointReference>, forRank rank: Int) {
        for i in 0...(rank - 1) {
            if allPoints[i].contains(point) || point.hashValue == 0 { return }
        }
        points.insert(point)
    }

    func matchedPoints() -> [PointReference] {
        var matched = [PointReference]()
        for rankPoints in allPoints {
            for point in rankPoints {
                let err = (inputPoint - point.point).magnitude
                if err <= maxDistanceError {
                    point.distanceError = err
                    matched.append((point))
                }
            }
        }
        return matched
    }
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
        return (pointLabels: pointLabels, lineLabels: lineLabels)
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
    return (pointLabels: pointLabels, lineLabels: lineLabels)
}

func printInstructions(line line: LineReference,
                     pointLabels: [Character] = main.pointLabels,
                      lineLabels: [Character] = main.lineLabels)
        -> (pointLabels: [Character], lineLabels: [Character]) {
    var pointLabels = pointLabels
    var lineLabels  = lineLabels
    if line.axiom == nil {
        line.label = "line \(lineLabels.popLast()!)(\(line.line))"
        return (pointLabels: pointLabels, lineLabels: lineLabels)
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
            + "perpendicular to \(line2.label).")
    }
    return (pointLabels: pointLabels, lineLabels: lineLabels)
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
