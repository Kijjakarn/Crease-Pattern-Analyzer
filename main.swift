/*----------------------------------------------------------------------------
                                Main Program
-----------------------------------------------------------------------------*/

var main = ReferenceFinder.singleton
main.makeAllPointsAndLines()
main.inputPoint = PointVector(0, 1/5)
var matchedPoints = main.matchedPoints()
print("There are \(matchedPoints.count) matched points")
matchedPoints.sortInPlace { $0.distanceError < $1.distanceError }

print("\nTo get \(main.inputPoint),")
printInstructions(point: matchedPoints[0])
clearInstructions()

/* let line = axiom3(Line(PointVector(0, 1), PointVector(1, 1)),
    Line(PointVector(1, 0), PointVector(1, 1)))
print(line) */
